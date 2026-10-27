import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'bit_voice.dart';

/// The few events worth a sound. Reads and calculations are silent on purpose: a sound on every step would be
/// repetitive and would compete with the narration.
enum SoundCue {
  write, // a value lands in shared memory
  lock, // a lock is taken or released
  blocked, // a thread has to wait
  lost; // the update is lost: the one moment the lesson is about

  static SoundCue? parse(String? id) {
    for (final c in values) {
      if (c.name == id) return c;
    }
    return null;
  }
}

/// What actually makes the sound. Behind an interface so tests (and a future synthesized-tone engine) can swap it.
abstract class SoundEngine {
  /// False on platforms that cannot play a cue reliably; the settings then do not offer sound effects at all.
  bool get supported;
  Future<void> play(SoundCue cue);
}

/// The platform's own short system sounds (no assets, no package). Only a click and an alert exist, so a cue is
/// either an ordinary tick or the alert; richer sounds need an audio package, which is a separate proposal.
class SystemSoundEngine implements SoundEngine {
  @override
  bool get supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Future<void> play(SoundCue cue) => SystemSound.play(cue == SoundCue.lost || cue == SoundCue.blocked ? SystemSoundType.alert : SystemSoundType.click);
}

/// Plays a cue if the learner turned sound effects on. Never throws: a sound that cannot play must not stop the lesson.
class SoundCues {
  SoundCues({SoundEngine? engine, BitVoice? settings})
      : engine = engine ?? SystemSoundEngine(),
        _settings = settings ?? BitVoice.instance;

  SoundEngine engine;
  final BitVoice _settings;

  bool get available => engine.supported;

  Future<void> play(SoundCue? cue) async {
    if (cue == null || !_settings.sfxEnabled || !engine.supported) return;
    try {
      await engine.play(cue);
    } catch (e) {
      debugPrint('SoundCues: cue unavailable: $e');
    }
  }
}
