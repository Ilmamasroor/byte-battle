import 'dart:async';
import 'package:byte_battle/core/voice/bit_voice.dart';
import 'package:byte_battle/features/learning/viz3d/engine/narration_controller.dart';
import 'package:byte_battle/features/learning/viz3d/engine/playback_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A speech engine that behaves like the browser's: it reports start, completion and cancellation as events (a
/// cancelled sentence reports an "interrupted" error), it silently drops or garbles a sentence handed to it while
/// another is still being spoken (counted in [overlaps]), and every failure mode of a real engine can be switched on.
class LifecycleEngine implements SpeechEngine, VolumeControl, SpeechLifecycle {
  void Function(SpeechEvent)? _cb;
  @override
  set onEvent(void Function(SpeechEvent)? callback) => _cb = callback;

  final spoken = <String>[];
  final rates = <double>[];
  int stops = 0;
  int overlaps = 0; // a sentence handed over while another was still being spoken
  bool speaking = false;
  bool confirmStop = true; // report the cancel after stop(), as browsers do (later, not instantly)
  bool autoRun = false; // start and complete each sentence by itself
  bool emitStart = true; // false: an engine that never says it started
  Object? failWith;

  void emit(SpeechEvent e) => _cb?.call(e);
  void start() => emit(const SpeechEvent(SpeechEventKind.started));
  void complete() {
    speaking = false;
    emit(const SpeechEvent(SpeechEventKind.completed));
  }

  @override
  Future<void> speak(String text, {required double rate, required double pitch, String? voice}) async {
    if (failWith != null) throw failWith!;
    if (speaking) overlaps++;
    speaking = true;
    spoken.add(text);
    rates.add(rate);
    if (autoRun) {
      Timer(Duration.zero, () {
        if (emitStart) start();
        Timer(const Duration(milliseconds: 300), complete);
      });
    }
  }

  @override
  Future<void> stop() async {
    stops++;
    if (speaking && confirmStop) {
      speaking = false;
      Timer(const Duration(milliseconds: 20), () => emit(const SpeechEvent(SpeechEventKind.error, 'interrupted')));
    }
  }

  @override
  Future<List<String>> voices() async => const [];

  @override
  Future<void> setVolume(double volume) async {}
}

/// Short waits so the failure paths run in a few hundred milliseconds of test time.
class FastTiming extends SpeechTiming {
  FastTiming() : super(startTimeout: const Duration(milliseconds: 200), quietTimeout: const Duration(milliseconds: 50));
  @override
  Duration completionFallback(int chars, double rate) => const Duration(milliseconds: 400);
}

void main() {
  late LifecycleEngine engine;
  final voice = BitVoice.instance;

  Future<void> tick(WidgetTester t, [Duration d = const Duration(milliseconds: 5)]) async {
    await t.pump(d);
    await t.pump();
  }

  /// Every test ends by stopping speech inside its body, which cancels the pipeline's timers.
  void tw(String name, Future<void> Function(WidgetTester t) body) => testWidgets(name, (t) async {
        await body(t);
        await voice.stop();
        await tick(t, const Duration(milliseconds: 100));
      });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    engine = LifecycleEngine();
    voice
      ..debugReset()
      ..engine = engine
      ..timing = FastTiming()
      ..enabled = true
      ..available = true
      ..speed = BitVoice.normal
      ..volume = 1.0;
  });

  group('one utterance, from request to completion', () {
    tw('goes starting, speaking, completed, with the platform rate for the learner\'s speed', (t) async {
      final f = voice.speakUtterance('Thread A reads count.', tag: 'ev1');
      await tick(t);
      expect(engine.spoken, ['Thread A reads count.']);
      expect(voice.state, SpeechState.starting);
      engine.start();
      expect(voice.state, SpeechState.speaking);
      engine.complete();
      expect(await f, SpeechOutcome.completed);
      expect(voice.state, SpeechState.completed);
      expect(engine.rates.single, 0.5, reason: 'normal speed on a mobile-style platform rate');
    });

    tw('the speed choices map to the right platform rate on every platform', (t) async {
      expect([for (final s in BitVoice.speedChoices) platformSpeechRate(s, web: true)], [0.85, 1.0, 1.2], reason: 'web: used as is, 1.0 is normal');
      expect([for (final s in BitVoice.speedChoices) platformSpeechRate(s, web: false)], [0.425, 0.5, 0.6], reason: 'Android and iOS: 0.5 is normal');
      expect(platformSpeechRate(9, web: true), 2.0);
      voice.speed = BitVoice.faster;
      final f = voice.speakUtterance('Faster please.');
      await tick(t);
      expect(engine.rates.single, 0.6);
      engine.start();
      engine.complete();
      await f;
    });

    tw('is skipped, not spoken, when narration is off, the voice is unavailable, or the text is empty', (t) async {
      voice.enabled = false;
      expect(await voice.speakUtterance('quiet'), SpeechOutcome.skipped);
      voice.enabled = true;
      expect(await voice.speakUtterance('   '), SpeechOutcome.skipped);
      voice.available = false;
      expect(await voice.speakUtterance('quiet'), SpeechOutcome.skipped);
      expect(engine.spoken, isEmpty);
    });
  });

  group('replacing and cancelling', () {
    tw('a new sentence waits for the engine to confirm the old one stopped: no overlap, no stop-then-speak', (t) async {
      final a = voice.speakUtterance('First sentence.', tag: 'ev1');
      await tick(t);
      engine.start();
      final b = voice.speakUtterance('Second sentence.', tag: 'ev2');
      await tick(t); // the engine has been told to stop but has not confirmed yet
      expect(engine.stops, 1);
      expect(engine.spoken, ['First sentence.'], reason: 'the second sentence is not handed over before the stop is confirmed');
      expect(await a, SpeechOutcome.cancelled);
      await tick(t, const Duration(milliseconds: 30)); // the cancel confirmation arrives
      expect(engine.spoken, ['First sentence.', 'Second sentence.']);
      expect(engine.overlaps, 0);
      engine.start();
      engine.complete();
      expect(await b, SpeechOutcome.completed);
    });

    tw('a late completion of the cancelled sentence cannot finish the new one', (t) async {
      final a = voice.speakUtterance('First sentence.');
      await tick(t);
      engine.start();
      final b = voice.speakUtterance('Second sentence.');
      await tick(t, const Duration(milliseconds: 40));
      expect(await a, SpeechOutcome.cancelled);
      expect(voice.state, SpeechState.starting);
      engine.complete(); // the first sentence's end-event, arriving after the second was handed over
      await tick(t);
      expect(voice.state, SpeechState.starting, reason: 'a completion before the sentence started belongs to an earlier one');
      expect(voice.diagnostics.entries.any((e) => e.what.contains('belongs to an earlier one')), isTrue);
      engine.start();
      expect(voice.state, SpeechState.speaking);
      engine.complete();
      expect(await b, SpeechOutcome.completed);
    });

    tw('a duplicate completion is ignored, and does not touch the next sentence', (t) async {
      final a = voice.speakUtterance('One.');
      await tick(t);
      engine.start();
      engine.complete();
      expect(await a, SpeechOutcome.completed);
      final b = voice.speakUtterance('Two.');
      await tick(t);
      engine.complete(); // the duplicate, before Two has started
      await tick(t);
      expect(voice.state, SpeechState.starting);
      engine.start();
      engine.complete();
      expect(await b, SpeechOutcome.completed);
      expect(engine.spoken, ['One.', 'Two.']);
    });

    tw('only the owner can cancel its own speech', (t) async {
      final mine = Object();
      final other = Object();
      final f = voice.speakUtterance('Mine.', owner: mine);
      await tick(t);
      engine.start();
      await voice.stop(owner: other);
      expect(voice.state, SpeechState.speaking, reason: 'another component must not silence this sentence');
      await voice.stop(owner: mine);
      expect(await f, SpeechOutcome.cancelled);
      expect(voice.state, SpeechState.cancelled);
    });

    tw('stopping with no owner (mute) cancels whatever is being said', (t) async {
      final f = voice.speakUtterance('Anything.', owner: Object());
      await tick(t);
      engine.start();
      await voice.configure(enabled: false);
      expect(await f, SpeechOutcome.cancelled);
    });
  });

  group('an engine that misbehaves', () {
    tw('never confirms the stop: speaks anyway after a bounded wait, and says so', (t) async {
      engine.confirmStop = false;
      final a = voice.speakUtterance('First.');
      await tick(t);
      engine.start();
      final b = voice.speakUtterance('Second.');
      await tick(t, const Duration(milliseconds: 300));
      expect(await a, SpeechOutcome.cancelled);
      expect(engine.spoken, ['First.', 'Second.']);
      expect(voice.diagnostics.entries.any((e) => e.what.contains('quiet-gave-up')), isTrue);
      engine.speaking = false;
      engine.start();
      engine.complete();
      expect(await b, SpeechOutcome.completed);
    });

    tw('very slow or missing start: the utterance times out, is logged, and the next one still works', (t) async {
      final a = voice.speakUtterance('Never starts.', tag: 'ev1');
      await tick(t, const Duration(milliseconds: 250));
      expect(await a, SpeechOutcome.timedOut);
      expect(voice.state, SpeechState.failed);
      expect(voice.diagnostics.entries.any((e) => e.what.contains('start-timeout')), isTrue);
      expect(engine.stops, greaterThanOrEqualTo(1), reason: 'the stuck engine is stopped so it cannot speak over the next sentence');
      await tick(t, const Duration(milliseconds: 60));
      final b = voice.speakUtterance('Works.');
      await tick(t, const Duration(milliseconds: 60));
      engine.start();
      engine.complete();
      expect(await b, SpeechOutcome.completed);
      expect(engine.overlaps, 0);
    });

    tw('missing completion: stopped after the fallback, reported as timed out, never stuck', (t) async {
      final a = voice.speakUtterance('Never ends.', tag: 'ev1');
      await tick(t);
      engine.start();
      await tick(t, const Duration(milliseconds: 450));
      expect(await a, SpeechOutcome.timedOut);
      expect(voice.diagnostics.entries.any((e) => e.what.contains('completion-timeout')), isTrue);
      expect(engine.stops, greaterThanOrEqualTo(1));
    });

    tw('an obsolete fallback timer cannot end the next sentence', (t) async {
      final a = voice.speakUtterance('First.');
      await tick(t);
      engine.start();
      await tick(t, const Duration(milliseconds: 300)); // most of the first sentence's fallback has passed
      final b = voice.speakUtterance('Second.');
      await tick(t, const Duration(milliseconds: 60));
      engine.start();
      await tick(t, const Duration(milliseconds: 200)); // the first sentence's fallback would have fired by now
      expect(voice.state, SpeechState.speaking, reason: 'the second sentence is still within its own fallback');
      engine.complete();
      expect(await b, SpeechOutcome.completed);
      expect(await a, SpeechOutcome.cancelled);
    });

    tw('an immediate failure marks the voice unavailable and completes the waiter', (t) async {
      engine.failWith = StateError('no tts');
      expect(await voice.speakUtterance('Hello.'), SpeechOutcome.failed);
      expect(voice.available, isFalse);
    });

    tw('an engine error event fails only that sentence; the voice stays available', (t) async {
      final a = voice.speakUtterance('Oops.');
      await tick(t);
      engine.start();
      engine.emit(const SpeechEvent(SpeechEventKind.error, 'synthesis-failed'));
      expect(await a, SpeechOutcome.failed);
      expect(voice.available, isTrue);
    });
  });

  group('preferences and diagnostics', () {
    tw('older speed values move to the nearest of the three choices', (t) async {
      for (final (saved, expected) in [(0.7, 0.85), (0.85, 0.85), (0.95, 1.0), (1.0, 1.0), (1.04, 1.0), (1.3, 1.2), (1.5, 1.2)]) {
        SharedPreferences.setMockInitialValues({'voice_speed': saved});
        voice.debugReset();
        await voice.load();
        expect(voice.speed, expected, reason: 'saved $saved');
      }
    });

    tw('the speed setting only accepts the three choices', (t) async {
      await voice.configure(speed: 1.37);
      expect(voice.speed, BitVoice.faster);
      await voice.configure(speed: 0.5);
      expect(voice.speed, BitVoice.slower);
    });

    tw('the log is bounded and never contains the spoken text', (t) async {
      for (var i = 0; i < 200; i++) {
        voice.diagnostics.add(i, 'x', 'ev$i', 'noise');
      }
      expect(voice.diagnostics.entries.length, SpeechDiagnostics.capacity);
      voice.diagnostics.clear();
      final f = voice.speakUtterance('A private sentence about nothing.', tag: 'ev1');
      await tick(t);
      engine.start();
      engine.complete();
      await f;
      final dump = voice.diagnostics.dump(voice.describe());
      expect(dump, isNot(contains('private')));
      expect(dump, matches(RegExp(r'#\d+ \[app ev1\] requested len=33')));
      expect(dump, contains('ev1'));
      expect(dump, contains('platform='));
    });
  });

  group('narration over a lifecycle engine', () {
    late VizPlaybackController playback;
    late NarrationController narration;

    void build({int length = 4}) {
      playback = VizPlaybackController(length: length, baseInterval: const Duration(milliseconds: 100));
      narration = NarrationController(playback: playback, textAt: (p) => 'Event number $p.');
    }

    /// Ends the test body cleanly: the binding checks for pending timers before any tearDown.
    void tn(String name, Future<void> Function(WidgetTester t) body) => tw(name, (t) async {
          build();
          await body(t);
          narration.dispose();
          playback.dispose();
        });

    tn('autoplay speaks every event once, in order, including the last, and never overlaps', (t) async {
      engine.autoRun = true;
      playback.play();
      for (var i = 0; i < 40; i++) {
        await tick(t, const Duration(milliseconds: 100));
      }
      expect(playback.position, 3);
      expect(playback.playing, isFalse);
      expect(engine.spoken, ['Event number 0.', 'Event number 1.', 'Event number 2.', 'Event number 3.']);
      expect(engine.overlaps, 0);
      final ids = voice.diagnostics.entries.where((e) => e.what.startsWith('requested')).map((e) => e.tag).toList();
      expect(ids, ['ev0', 'ev1', 'ev2', 'ev3'], reason: 'the utterance tags are the selected events, in order');
    });

    tn('autoplay waits for the sentence to end, and moves on only after its own completion', (t) async {
      playback.play();
      await tick(t, const Duration(milliseconds: 10));
      engine.start();
      await tick(t, const Duration(milliseconds: 300)); // three times the minimum dwell, inside the 400ms fallback
      expect(playback.position, 0);
      engine.complete();
      await tick(t, const Duration(milliseconds: 10));
      expect(playback.position, 1);
    });

    tn('a cancelled event cannot advance playback when its late completion arrives', (t) async {
      playback.play();
      await tick(t, const Duration(milliseconds: 10));
      engine.start();
      playback.seek(3);
      await tick(t, const Duration(milliseconds: 60));
      expect(engine.spoken.last, 'Event number 3.');
      engine.complete(); // the cancelled sentence's end-event
      await tick(t, const Duration(milliseconds: 500));
      expect(playback.position, 3, reason: 'playback is on event 3, still being spoken');
    });

    tn('rapid pause and resume never overlaps speech and ends on the current event', (t) async {
      for (var i = 0; i < 6; i++) {
        playback.play();
        await tick(t, const Duration(milliseconds: 8));
        playback.pause();
        await tick(t, const Duration(milliseconds: 8));
      }
      playback.play();
      await tick(t, const Duration(milliseconds: 100));
      expect(engine.overlaps, 0);
      expect(voice.activeUtterance, isNotNull);
      engine.start();
      expect(engine.spoken.last, 'Event number 0.');
      expect(playback.position, 0);
    });

    tn('seeking around while paused is silent: nothing is queued', (t) async {
      for (var p = 0; p < 4; p++) {
        playback.seek(p);
        await tick(t, const Duration(milliseconds: 5));
      }
      expect(engine.spoken, isEmpty);
      expect(voice.activeUtterance, isNull);
    });

    tn('muting stops the sentence, unmuting speaks nothing until asked, and playback keeps working', (t) async {
      playback.play();
      await tick(t, const Duration(milliseconds: 10));
      engine.start();
      await voice.configure(enabled: false);
      await tick(t, const Duration(milliseconds: 30));
      expect(voice.activeUtterance, isNull);
      await tick(t, const Duration(milliseconds: 150));
      expect(playback.position, greaterThanOrEqualTo(1), reason: 'visual playback carries on by its timer');
      playback.pause();
      await tick(t, const Duration(milliseconds: 20));
      final before = engine.spoken.length;
      await voice.configure(enabled: true);
      await tick(t, const Duration(milliseconds: 20));
      expect(engine.spoken.length, before, reason: 'unmuting while paused does not suddenly speak a stale event');
    });

    tn('a start that never comes does not freeze autoplay, and is logged', (t) async {
      engine.autoRun = true;
      engine.emitStart = false;
      playback.play();
      for (var i = 0; i < 60; i++) {
        await tick(t, const Duration(milliseconds: 100));
      }
      expect(playback.position, 3, reason: 'each event timed out and playback moved on');
      expect(voice.diagnostics.entries.any((e) => e.what.contains('start-timeout')), isTrue);
      expect(engine.overlaps, 0);
    });

    tn('the sentence in flight is the sentence for the selected event (caption and speech agree)', (t) async {
      engine.autoRun = true;
      playback.seek(2);
      narration.hear();
      await tick(t, const Duration(milliseconds: 20));
      expect(engine.spoken, [narration.textAt(2)]);
      expect(narration.speakingAt, 2);
      await tick(t, const Duration(milliseconds: 400)); // let the fake engine finish its sentence
    });
  });
}
