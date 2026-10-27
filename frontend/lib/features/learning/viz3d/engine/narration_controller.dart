import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/voice/bit_voice.dart';
import '../../../../core/voice/sound_cues.dart';
import 'playback_controller.dart';

/// Keeps spoken narration tied to the event the learner is looking at.
///
/// Policy (the same for every lesson):
/// * Narration is spoken only while playing. Pressing play speaks the event on screen, and each automatic step
///   speaks the event it lands on, including the last one.
/// * A manual step, scrub, restart or variant change cancels any speech and stays silent, so seeking never leaves
///   the voice describing an event the learner has already left. [hear] speaks the current event on request, and
///   so does Replay.
/// * Pausing cancels the speech; playing again starts the current event's narration from its beginning.
/// * An automatic step waits for the narration to finish, never less than the normal dwell and never more than
///   [maxWait], so long narration is heard in full without making a short one wait.
/// * Speed changes apply from the next event; the sentence in flight finishes at the old rate. Speech never slows
///   below the learner's own speed when lesson playback is slowed (that only lengthens the pause between events),
///   and speeds up a little when playback is fast.
/// * Captions are not this class's job: the screen shows [textAt] for the current position whether or not
///   anything is spoken, so muting, an unavailable voice or a failed engine never hides the explanation.
///
/// Every cancel bumps an epoch. A speech that finishes under an old epoch is ignored, so a stale completion can
/// neither advance playback nor clear the state of newer speech.
class NarrationController extends ChangeNotifier {
  NarrationController({
    required this.playback,
    required this.textAt,
    this.cueAt,
    BitVoice? voice,
    SoundCues? cues,
    this.maxWait = const Duration(seconds: 25),
  })  : _voice = voice ?? BitVoice.instance,
        _cues = cues ?? SoundCues() {
    _pos = playback.position;
    _playing = playback.playing;
    _generation = playback.generation;
    _replay = playback.replayNonce;
    _auto = playback.autoAdvances;
    playback.advanceGate = _gate;
    playback.addListener(_onPlayback);
    _voice.addListener(_onVoice);
  }

  final VizPlaybackController playback;

  /// The narration for a timeline position (null for none).
  final String? Function(int position) textAt;

  /// The sound cue for a position (null for none).
  final SoundCue? Function(int position)? cueAt;

  final Duration maxWait;
  final BitVoice _voice;
  final SoundCues _cues;

  int _epoch = 0;
  int? _speakingAt;
  Completer<void>? _done;
  int _pos = 0;
  bool _playing = false;
  int _generation = 0;
  int _replay = 0;
  int _auto = 0;
  bool _disposed = false;

  /// The position being spoken right now, or null.
  int? get speakingAt => _speakingAt;
  bool get speaking => _speakingAt != null;

  /// True when speech can be heard: narration is on and the platform voice works.
  bool get canSpeak => _voice.enabled && _voice.available;

  /// Speaks the event on screen now, whether or not playback is running.
  void hear() => _begin(playback.position, withCue: false);

  /// Stops any speech immediately (leaving the screen, switching lesson).
  void cancel() => _bump();

  /// Lesson playback at 2x speaks a little faster; slower playback only lengthens the pause between events.
  double get _speechScale => playback.speed > 1 ? 1.2 : 1.0;

  void _onPlayback() {
    final p = playback.position;
    final playing = playback.playing;
    final moved = p != _pos || playback.generation != _generation;
    final started = playing && !_playing;
    final replayed = playback.replayNonce != _replay;
    // Playback stops in the same notification that lands on the last event, so "playing" is already false there:
    // the step counter is what says it arrived by itself and that event (the one that ends the story) is still narrated.
    final arrived = playback.autoAdvances != _auto;
    final changed = moved || playing != _playing || replayed;
    _pos = p;
    _playing = playing;
    _generation = playback.generation;
    _replay = playback.replayNonce;
    _auto = playback.autoAdvances;
    if (!changed) return;
    final speakAgain = replayed || arrived || (playing && (moved || started));
    _bump(stopSpeech: !speakAgain); // a new utterance supersedes the old one itself; only stop when nothing follows
    if (speakAgain) _begin(p, withCue: !replayed);
  }

  void _onVoice() {
    if (_speakingAt != null && !canSpeak) _bump();
  }

  void _begin(int position, {required bool withCue}) {
    if (_disposed) return;
    if (withCue && position > 0) _cues.play(cueAt?.call(position));
    final text = textAt(position);
    if (text == null || text.trim().isEmpty || !canSpeak) {
      _bump(); // nothing to say for this event: do not leave the previous event's sentence running
      return;
    }
    _bump(stopSpeech: false);
    final mine = _epoch;
    _speakingAt = position;
    final done = _done = Completer<void>();
    notifyListeners();
    // One utterance per event, owned by this controller. A new utterance from here supersedes the old one inside
    // BitVoice (after the engine confirmed the stop), so there is no separate stop-then-speak.
    _voice.speakUtterance(text, rateScale: _speechScale, owner: this, tag: 'ev$position').then((outcome) {
      if (mine != _epoch) return; // cancelled or superseded by us: not ours to clear
      _speakingAt = null;
      if (!done.isCompleted) done.complete();
      if (!_disposed) notifyListeners();
    });
  }

  /// Cancels speech and invalidates every pending completion.
  void _bump({bool stopSpeech = true}) {
    _epoch++;
    final d = _done;
    if (d != null && !d.isCompleted) d.complete();
    _done = null;
    final wasSpeaking = _speakingAt != null;
    _speakingAt = null;
    if (stopSpeech) _voice.stop(owner: this); // a no-op unless this controller's own sentence is active
    if (wasSpeaking && !_disposed) notifyListeners();
  }

  /// Asked by playback before it advances from [position]: waits for this position's speech to end.
  Future<void> _gate(int position) {
    final d = _done;
    if (_speakingAt != position || d == null) return Future.value();
    final mine = _epoch;
    return d.future.timeout(maxWait, onTimeout: () {
      if (mine == _epoch) _bump(); // the engine never reported completion: stop it so it cannot talk over the next event
    });
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    playback.removeListener(_onPlayback);
    _voice.removeListener(_onVoice);
    if (playback.advanceGate == _gate) playback.advanceGate = null;
    _epoch++;
    final d = _done;
    if (d != null && !d.isCompleted) d.complete();
    _voice.stop(owner: this);
    super.dispose();
  }
}
