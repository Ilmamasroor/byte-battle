import 'dart:async';
import 'package:byte_battle/core/voice/bit_voice.dart';
import 'package:byte_battle/core/voice/sound_cues.dart';
import 'package:byte_battle/features/learning/viz3d/engine/narration_controller.dart';
import 'package:byte_battle/features/learning/viz3d/engine/playback_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A speech engine the test drives by hand. Like a real TTS engine, [stop] ends the utterance in flight, so a
/// cancelled sentence completes (and must be ignored by whoever was waiting on it).
class ControlledEngine implements SpeechEngine, VolumeControl {
  final spoken = <String>[];
  final rates = <double>[];
  final volumes = <double>[];
  int stops = 0;
  bool autoFinish = false;
  Object? failWith;
  Completer<void>? _current;

  bool get inFlight => _current != null && !_current!.isCompleted;

  @override
  Future<void> speak(String text, {required double rate, required double pitch, String? voice}) async {
    if (failWith != null) throw failWith!;
    spoken.add(text);
    rates.add(rate);
    if (autoFinish) return;
    final c = _current = Completer<void>();
    await c.future;
  }

  void finishCurrent() {
    final c = _current;
    _current = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  @override
  Future<void> stop() async {
    stops++;
    finishCurrent();
  }

  @override
  Future<List<String>> voices() async => const [];

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);
}

class FakeSound implements SoundEngine {
  final played = <SoundCue>[];
  bool fail = false;
  @override
  bool get supported => true;
  @override
  Future<void> play(SoundCue cue) async {
    if (fail) throw StateError('no audio device');
    played.add(cue);
  }
}

void main() {
  late ControlledEngine engine;
  late VizPlaybackController playback;
  late NarrationController narration;
  late FakeSound sound;

  Future<void> settle(WidgetTester t, [Duration d = Duration.zero]) async {
    await t.pump(d);
    await t.pump();
  }

  void build({int length = 5, SoundCue? Function(int)? cue, Duration maxWait = const Duration(seconds: 25)}) {
    playback = VizPlaybackController(length: length);
    sound = FakeSound();
    narration = NarrationController(
      playback: playback,
      textAt: (p) => 'event $p',
      cueAt: cue,
      cues: SoundCues(engine: sound),
      maxWait: maxWait,
    );
  }

  /// Every test ends by disposing, inside the test body: the binding checks for pending timers before any tearDown runs.
  void tw(String name, Future<void> Function(WidgetTester t) body) => testWidgets(name, (t) async {
        await body(t);
        narration.dispose();
        playback.dispose();
      });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    engine = ControlledEngine();
    BitVoice.instance
      ..debugReset()
      ..engine = engine
      ..enabled = true
      ..available = true
      ..sfxEnabled = false
      ..volume = 1.0
      ..speed = 1.0;
  });

  group('while playing', () {
    tw('speaks the event on screen, then waits for it to finish before moving on', (t) async {
      build();
      playback.play();
      await settle(t);
      expect(engine.spoken, ['event 0']);
      expect(narration.speakingAt, 0);

      await settle(t, const Duration(seconds: 3)); // far longer than the normal dwell, inside the engine-silence fallback
      expect(playback.position, 0, reason: 'a long narration is heard in full, not cut off by the timer');

      engine.finishCurrent();
      await settle(t);
      expect(playback.position, 1);
      expect(engine.spoken, ['event 0', 'event 1']);
      expect(narration.speakingAt, 1);
    });

    tw('a short narration does not make the step wait longer than the normal dwell', (t) async {
      engine.autoFinish = true;
      build();
      playback.play();
      await settle(t);
      expect(playback.position, 0);
      await settle(t, const Duration(milliseconds: 1160));
      expect(playback.position, 1);
      await settle(t, const Duration(milliseconds: 1160));
      expect(playback.position, 2);
      expect(engine.spoken, ['event 0', 'event 1', 'event 2']);
    });

    tw('every event is spoken once, in order, through to the end', (t) async {
      engine.autoFinish = true;
      build(length: 4);
      playback.play();
      for (var i = 0; i < 6; i++) {
        await settle(t, const Duration(milliseconds: 1200));
      }
      expect(playback.position, 3);
      expect(playback.playing, isFalse);
      expect(engine.spoken, ['event 0', 'event 1', 'event 2', 'event 3']);
    });

    tw('seeking cancels the old sentence; only the new event is spoken and the old finish cannot move playback', (t) async {
      build();
      playback.play();
      await settle(t);
      expect(narration.speakingAt, 0);

      playback.seek(3);
      await settle(t);
      expect(engine.spoken, ['event 0', 'event 3']);
      expect(narration.speakingAt, 3);

      // The cancelled sentence's completion arrives late. It must not clear the new speech or advance playback.
      await settle(t, const Duration(seconds: 3)); // well past the dwell, inside the engine-silence fallback
      expect(playback.position, 3);
      expect(narration.speakingAt, 3);
      expect(engine.inFlight, isTrue);
    });

    tw('there is never more than one sentence in flight', (t) async {
      build();
      playback.play();
      await settle(t);
      var inFlightMax = 0;
      for (final p in [2, 4, 1, 3]) {
        playback.seek(p);
        await settle(t);
        inFlightMax = inFlightMax < (engine.inFlight ? 1 : 0) ? 1 : inFlightMax;
        expect(narration.speakingAt, p);
      }
      expect(inFlightMax, 1);
      expect(engine.spoken.last, 'event 3');
    });

    tw('pausing cancels the speech, and playing again restarts that event from its beginning', (t) async {
      build();
      playback.play();
      await settle(t);
      playback.pause();
      await settle(t);
      expect(narration.speakingAt, isNull);
      expect(engine.inFlight, isFalse);
      playback.play();
      await settle(t);
      expect(engine.spoken, ['event 0', 'event 0']);
      expect(playback.position, 0);
    });

    tw('changing the speed applies to the next event, with the sentence in flight left alone', (t) async {
      build();
      playback.play();
      await settle(t);
      playback.setSpeed(2);
      await settle(t);
      expect(engine.spoken, ['event 0']);
      engine.finishCurrent();
      await settle(t, const Duration(milliseconds: 600)); // the dwell at 2x
      expect(engine.spoken, ['event 0', 'event 1']);
      expect(engine.rates, [0.5, 0.6], reason: 'speech only speeds up (x1.2) when playback is at 2x; it never slows with playback');
    });

    tw('a narration that never reports completion is stopped after the cap, so it cannot talk over the next event', (t) async {
      build(maxWait: const Duration(seconds: 3));
      playback.play();
      await settle(t);
      await settle(t, const Duration(milliseconds: 1160));
      expect(playback.position, 0);
      await settle(t, const Duration(seconds: 3));
      expect(playback.position, 1);
      expect(engine.spoken, ['event 0', 'event 1']);
      expect(engine.stops, greaterThanOrEqualTo(2));
    });
  });

  group('while paused', () {
    tw('stepping and seeking are silent and cancel anything in flight', (t) async {
      build();
      narration.hear();
      await settle(t);
      expect(narration.speakingAt, 0);

      playback.next();
      await settle(t);
      expect(narration.speakingAt, isNull);
      expect(engine.inFlight, isFalse);
      playback.seek(3);
      playback.previous();
      await settle(t);
      expect(engine.spoken, ['event 0'], reason: 'moving around never speaks on its own');
    });

    tw('"hear this step" speaks exactly the event on screen', (t) async {
      build();
      playback.seek(2);
      narration.hear();
      await settle(t);
      expect(engine.spoken, ['event 2']);
      playback.previous();
      narration.hear();
      await settle(t);
      expect(engine.spoken, ['event 2', 'event 1']);
    });

    tw('replay speaks the current event again', (t) async {
      build();
      playback.seek(2);
      playback.replay();
      await settle(t);
      expect(engine.spoken, ['event 2']);
    });

    tw('restarting the lesson or switching variant (a new timeline) silences it', (t) async {
      build();
      narration.hear();
      await settle(t);
      playback.configure(7);
      await settle(t);
      expect(narration.speakingAt, isNull);
      expect(engine.inFlight, isFalse);
      expect(engine.spoken, ['event 0']);
    });
  });

  group('when audio is off or broken', () {
    tw('muting mid-sentence stops it and playback carries on by the timer', (t) async {
      build();
      playback.play();
      await settle(t);
      await BitVoice.instance.configure(enabled: false);
      await settle(t);
      expect(narration.speakingAt, isNull);
      expect(engine.inFlight, isFalse);
      await settle(t, const Duration(milliseconds: 1160));
      expect(playback.position, 1);
      expect(engine.spoken, ['event 0'], reason: 'nothing is spoken while muted');
    });

    tw('an engine failure never blocks the visualization', (t) async {
      engine.failWith = StateError('no tts');
      build();
      playback.play();
      await settle(t);
      expect(BitVoice.instance.available, isFalse);
      expect(narration.canSpeak, isFalse);
      await settle(t, const Duration(milliseconds: 1160));
      expect(playback.position, 1);
      await settle(t, const Duration(milliseconds: 1160));
      expect(playback.position, 2);
    });

    tw('a muted or unavailable voice leaves the text for every position available to the caption', (t) async {
      BitVoice.instance.enabled = false;
      build();
      for (var p = 0; p < 5; p++) {
        expect(narration.textAt(p), 'event $p');
      }
      narration.hear();
      await settle(t);
      expect(engine.spoken, isEmpty);
    });
  });

  group('volume', () {
    tw('the learner\'s volume reaches the engine before each sentence', (t) async {
      BitVoice.instance.volume = 0.4;
      build();
      narration.hear();
      await settle(t);
      expect(engine.volumes, [0.4]);
    });
  });

  group('sound cues', () {
    tw('play for the events that carry the lesson, only while sound cues are on', (t) async {
      engine.autoFinish = true;
      build(cue: (p) => p == 1 ? SoundCue.write : (p == 3 ? SoundCue.lost : null));
      BitVoice.instance.sfxEnabled = true;
      playback.play();
      for (var i = 0; i < 5; i++) {
        await settle(t, const Duration(milliseconds: 1200));
      }
      expect(sound.played, [SoundCue.write, SoundCue.lost]);
    });

    tw('are silent when switched off, and when the learner moves around by hand', (t) async {
      engine.autoFinish = true;
      build(cue: (p) => SoundCue.write);
      playback.play();
      for (var i = 0; i < 3; i++) {
        await settle(t, const Duration(milliseconds: 1200));
      }
      expect(sound.played, isEmpty, reason: 'sound cues are off by default');
      BitVoice.instance.sfxEnabled = true;
      playback.pause();
      playback.seek(2);
      playback.next();
      await settle(t);
      expect(sound.played, isEmpty);
    });

    tw('a sound that cannot play does not stop the narration or the lesson', (t) async {
      engine.autoFinish = true;
      build(cue: (p) => SoundCue.lost);
      BitVoice.instance.sfxEnabled = true;
      sound.fail = true;
      playback.play();
      await settle(t, const Duration(milliseconds: 1200));
      await settle(t);
      expect(playback.position, 1);
      expect(engine.spoken, ['event 0', 'event 1']);
    });
  });

  tw('disposing releases the gate and stops speech', (t) async {
    build();
    playback.play();
    await settle(t);
    narration.dispose();
    expect(playback.advanceGate, isNull);
    expect(engine.inFlight, isFalse);
  });
}
