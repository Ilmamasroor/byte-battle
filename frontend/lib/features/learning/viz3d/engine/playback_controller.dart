import 'dart:async';
import 'package:flutter/foundation.dart';

/// The single source of truth for where the learner is on a timeline and whether it is playing.
///
/// Both the 3D viewport and any flat view read the same controller, so they can never disagree. It owns its timer
/// and cancels it in [dispose].
class VizPlaybackController extends ChangeNotifier {
  VizPlaybackController({int length = 1, this.baseInterval = const Duration(milliseconds: 1150), this.onFinished}) : _length = length < 1 ? 1 : length;

  static const speeds = [0.5, 1.0, 2.0];

  int _length;
  int _position = 0;
  bool _playing = false;
  double _speed = 1;
  int _replayNonce = 0;
  int _generation = 0;
  int _autoAdvances = 0;
  int _tickToken = 0;
  Timer? _timer;
  bool _disposed = false;

  /// Time between steps at 1x. The screen raises it while Bit is narrating aloud.
  Duration baseInterval;

  /// Called once each time playback runs to the end on its own.
  final VoidCallback? onFinished;

  /// Lets another component (narration) hold the next automatic step until it is ready. It is asked after the
  /// minimum dwell for the position being left, and the step happens when the returned future completes. A pause,
  /// seek, reset or reconfigure while it waits cancels the step, so a late completion can never move playback.
  Future<void> Function(int position)? advanceGate;

  int get length => _length;
  int get position => _position;
  bool get playing => _playing;
  double get speed => _speed;
  bool get atStart => _position == 0;
  bool get atEnd => _position >= _length - 1;

  /// Bumps whenever the learner asks to replay the current transition; the viewport animates again from the
  /// previous frame.
  int get replayNonce => _replayNonce;

  /// Counts the steps playback took by itself (not manual steps or seeks). Lets a listener tell "playback just landed
  /// here" from "the learner moved here", including when playback stops on the very step it lands on.
  int get autoAdvances => _autoAdvances;

  /// Bumps each time [configure] points the controller at a new timeline, even when the position stays 0.
  int get generation => _generation;

  Duration get interval => Duration(milliseconds: (baseInterval.inMilliseconds / _speed).round());

  /// Points the controller at a timeline of [length] positions (lesson, variant or input change). Stops playback
  /// and returns to the start so nothing from the previous timeline survives.
  void configure(int length, {int position = 0}) {
    _generation++;
    _stopTimer();
    _length = length < 1 ? 1 : length;
    _position = position.clamp(0, _length - 1);
    _playing = false;
    _notify();
  }

  void seek(int position) {
    final p = position.clamp(0, _length - 1);
    if (p == _position) return;
    _position = p;
    if (_playing) _schedule(); // seeking while playing restarts the dwell from the new position
    _notify();
  }

  void next() {
    _pauseQuietly();
    seek(_position + 1);
  }

  void previous() {
    _pauseQuietly();
    seek(_position - 1);
  }

  void reset() {
    _stopTimer();
    _playing = false;
    _position = 0;
    _notify();
  }

  void replay() {
    _replayNonce++;
    _notify();
  }

  void play() {
    if (_playing || _length < 2) return;
    if (atEnd) _position = 0;
    _playing = true;
    _schedule();
    _notify();
  }

  void pause() {
    if (!_playing) return;
    _stopTimer();
    _playing = false;
    _notify();
  }

  void toggle() => _playing ? pause() : play();

  void cycleSpeed() {
    final i = speeds.indexOf(_speed);
    setSpeed(speeds[(i + 1) % speeds.length]);
  }

  void setSpeed(double s) {
    _speed = s;
    if (_playing) _schedule(); // the new speed applies from the next step
    _notify();
  }

  void _pauseQuietly() {
    if (_playing) {
      _stopTimer();
      _playing = false;
    }
  }

  void _schedule() {
    _timer?.cancel();
    final token = ++_tickToken;
    _timer = Timer(interval, () => _tick(token));
  }

  void _tick(int token) {
    if (_disposed || !_playing || token != _tickToken) return;
    if (atEnd) {
      _finish();
      return;
    }
    final gate = advanceGate;
    if (gate == null) {
      _advance();
      return;
    }
    final at = _position;
    gate(at).then((_) {
      if (_disposed || !_playing || token != _tickToken || _position != at) return; // cancelled while waiting
      _advance();
    });
  }

  void _advance() {
    _autoAdvances++;
    _position++;
    if (atEnd) {
      _finish();
    } else {
      _schedule();
      _notify();
    }
  }

  void _finish() {
    _stopTimer();
    _playing = false;
    _notify();
    onFinished?.call();
  }

  void _stopTimer() {
    _tickToken++; // a step already waiting on the gate is cancelled too
    _timer?.cancel();
    _timer = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimer();
    super.dispose();
  }
}
