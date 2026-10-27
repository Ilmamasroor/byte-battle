import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What actually produces sound. Behind an interface so the app (and tests) can swap the engine.
///
/// [rate] is the platform's own rate (see [platformSpeechRate]); callers go through [BitVoice], which maps the
/// learner's chosen speed.
abstract class SpeechEngine {
  Future<void> speak(String text, {required double rate, required double pitch, String? voice});
  Future<void> stop();
  Future<List<String>> voices();
}

/// Optional: an engine that can set its own loudness. Kept separate from [SpeechEngine] so an engine without a
/// volume control (and every existing test engine) still satisfies the interface.
abstract class VolumeControl {
  Future<void> setVolume(double volume);
}

enum SpeechEventKind { started, completed, cancelled, error }

class SpeechEvent {
  final SpeechEventKind kind;
  final String? message;
  const SpeechEvent(this.kind, [this.message]);

  /// Browsers report a cancelled utterance as an error called "interrupted" or "canceled".
  bool get isCancellation => kind == SpeechEventKind.cancelled || (kind == SpeechEventKind.error && RegExp(r'interrupt|cancel', caseSensitive: false).hasMatch(message ?? ''));
}

/// Optional: an engine that reports when an utterance starts, completes, is cancelled or fails. Without it the only
/// signal is the future returned by [SpeechEngine.speak], which on some platforms is one future shared by every
/// utterance (so a cancelled sentence can complete the next one). [BitVoice] uses these events when they exist.
/// This is a separate interface because adding members to [SpeechEngine] would break every existing implementer.
abstract class SpeechLifecycle {
  set onEvent(void Function(SpeechEvent event)? callback);
}

/// The speech rate to hand to the platform for a learner-facing [normalized] speed where 1.0 is a natural
/// conversational pace. Platforms disagree about what a "rate" means:
/// * web (browser speech synthesis): the rate is used as is, 1.0 is normal;
/// * Android: the plugin doubles it, so 0.5 is normal;
/// * iOS and macOS: 0.5 is the default speed.
double platformSpeechRate(double normalized, {bool? web}) {
  final isWeb = web ?? kIsWeb;
  return isWeb ? normalized.clamp(0.5, 2.0) : (0.5 * normalized).clamp(0.2, 1.0);
}

/// The platform's own text-to-speech (browser speech synthesis on web, the OS voices on Android/iOS/macOS).
/// Free, works offline on devices, and sends no audio or text to any server.
class FlutterTtsEngine implements SpeechEngine, VolumeControl, SpeechLifecycle {
  // Created on first use: building it touches platform channels, which must not happen before the Flutter binding
  // exists (BitVoice.instance is created from main(), very early).
  late final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  Map<String, String> _locales = {};
  void Function(SpeechEvent event)? _callback;

  @override
  set onEvent(void Function(SpeechEvent event)? callback) => _callback = callback;

  void _emit(SpeechEvent e) => _callback?.call(e);

  Future<void> _init() async {
    if (_ready) return;
    // The plugin's "await completion" future is shared by every speak call, so a cancelled sentence's late
    // end-event completes the next sentence's future. Completion is taken from the lifecycle handlers instead.
    await _tts.awaitSpeakCompletion(false);
    _tts.setStartHandler(() => _emit(const SpeechEvent(SpeechEventKind.started)));
    _tts.setCompletionHandler(() => _emit(const SpeechEvent(SpeechEventKind.completed)));
    _tts.setCancelHandler(() => _emit(const SpeechEvent(SpeechEventKind.cancelled)));
    _tts.setErrorHandler((message) => _emit(SpeechEvent(SpeechEventKind.error, '$message')));
    await _tts.setLanguage('en-US');
    await _tts.setVolume(1.0);
    _ready = true;
  }

  @override
  Future<void> speak(String text, {required double rate, required double pitch, String? voice}) async {
    await _init();
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    if (voice != null && _locales.containsKey(voice)) {
      await _tts.setVoice({'name': voice, 'locale': _locales[voice]!});
    }
    await _tts.speak(text);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _init();
    await _tts.setVolume(volume.clamp(0.0, 1.0));
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<List<String>> voices() async {
    await _init();
    final raw = await _tts.getVoices;
    final out = <String>[];
    _locales = {};
    if (raw is List) {
      for (final v in raw) {
        if (v is Map) {
          final name = v['name']?.toString() ?? '';
          final locale = v['locale']?.toString() ?? '';
          if (name.isNotEmpty && locale.toLowerCase().startsWith('en')) {
            out.add(name);
            _locales[name] = locale;
          }
        }
      }
    }
    out.sort();
    return out;
  }
}

/// Where one utterance is in its life. `completed`, `cancelled` and `failed` are terminal.
enum SpeechState { idle, starting, speaking, completed, cancelled, failed }

/// How an utterance ended, as seen by whoever asked for it.
enum SpeechOutcome {
  completed, // the engine reported the end of the sentence
  timedOut, // no completion arrived within the fallback, so it was stopped (logged)
  cancelled, // stopped or replaced before it finished: the caller must not treat it as "heard"
  failed, // the engine could not speak it
  skipped, // never started: narration is off, the voice is unavailable, or the text was empty
}

/// One bounded entry of the temporary speech log. It records identity and timing, never the spoken text.
class SpeechLogEntry {
  final int ms;
  final int? utterance;
  final String owner;
  final String? tag;
  final String what;
  const SpeechLogEntry(this.ms, this.utterance, this.owner, this.tag, this.what);

  @override
  String toString() => '+${ms}ms ${utterance == null ? '    ' : '#$utterance'} [$owner${tag == null ? '' : ' $tag'}] $what';
}

/// A small ring buffer of what the speech pipeline did (temporary diagnostics for the voice reliability work).
class SpeechDiagnostics extends ChangeNotifier {
  static const capacity = 150;
  final _entries = <SpeechLogEntry>[];
  final _clock = Stopwatch()..start();

  List<SpeechLogEntry> get entries => List.unmodifiable(_entries);

  void add(int? utterance, String owner, String? tag, String what) {
    _entries.add(SpeechLogEntry(_clock.elapsedMilliseconds, utterance, owner, tag, what));
    if (_entries.length > capacity) _entries.removeAt(0);
    debugPrint('[bitvoice] ${_entries.last}'); // also visible in the browser console
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  /// Text to paste into a bug report: the platform and settings, then the log.
  String dump(String header) => '$header\n${_entries.join('\n')}';
}

/// The tunable waits of the speech pipeline. All of them exist only to recover from an engine that stays silent;
/// none is a delay in the normal path.
class SpeechTiming {
  /// How long a started utterance may go without the engine saying it started.
  Duration startTimeout;

  /// How long to wait for the engine to confirm it stopped before speaking again (re-tried a few times).
  Duration quietTimeout;

  SpeechTiming({this.startTimeout = const Duration(seconds: 8), this.quietTimeout = const Duration(milliseconds: 600)});

  /// How long a sentence of [chars] characters may take at normalized speed [rate] before it is declared stuck.
  /// Natural speech is roughly 14 characters a second; the fallback is twice that, plus a margin.
  Duration completionFallback(int chars, double rate) {
    final natural = chars / 14.0 / (rate <= 0 ? 1 : rate);
    return Duration(milliseconds: ((natural * 2 + 4) * 1000).round());
  }
}

class _Utterance {
  final int id;
  final Object? owner;
  final String ownerLabel;
  final String? tag;
  final String text;
  final double normalizedRate;
  final Completer<SpeechOutcome> done = Completer<SpeechOutcome>();
  final DateTime requestedAt = DateTime.now();
  SpeechState state = SpeechState.idle;
  bool issued = false; // handed to the engine
  bool started = false; // the engine said it started (or the engine has no events)
  Timer? startTimer;
  Timer? completionTimer;

  _Utterance(this.id, this.owner, this.ownerLabel, this.tag, this.text, this.normalizedRate);

  bool get terminal => state == SpeechState.completed || state == SpeechState.cancelled || state == SpeechState.failed;
}

/// Bit's voice, and the single owner of speech in the app.
///
/// Everything spoken goes through [speakUtterance] / [speak]. At most one utterance is active. A new request
/// supersedes the current one, and the engine is only given the new sentence after it has confirmed that the old
/// one has stopped (never `stop()` immediately followed by `speak()`, which browsers drop or truncate). Each
/// utterance has an identity; engine events are only ever applied to the utterance they belong to, so a cancelled
/// sentence's late completion cannot finish the next one. Cancelling with an `owner` only cancels that owner's
/// own speech, so a widget disposing cannot silence another component.
class BitVoice extends ChangeNotifier {
  BitVoice._() {
    _bind(_engine);
  }
  static final BitVoice instance = BitVoice._();

  SpeechEngine _engine = FlutterTtsEngine();
  SpeechLifecycle? _lifecycle;

  SpeechEngine get engine => _engine;
  set engine(SpeechEngine e) {
    _lifecycle?.onEvent = null;
    _engine = e;
    _engineBusy = false;
    _onEngine = null;
    _bind(e);
  }

  void _bind(SpeechEngine e) {
    final l = e is SpeechLifecycle ? e as SpeechLifecycle : null;
    _lifecycle = l;
    l?.onEvent = _onEngineEvent;
  }

  final SpeechDiagnostics diagnostics = SpeechDiagnostics();
  SpeechTiming timing = SpeechTiming();

  bool enabled = true;
  String? voiceName;

  /// The learner's speed choice: [slower], [normal] or [faster] (see [speedChoices]).
  double speed = normal;

  static const double slower = 0.85;
  static const double normal = 1.0;
  static const double faster = 1.2;
  static const speedChoices = [slower, normal, faster];

  /// Maps any stored or supplied value (older versions saved a 0.7 to 1.5 slider) to the nearest choice.
  static double snapSpeed(double v) => v < 0.925 ? slower : (v < 1.1 ? normal : faster);

  /// 0.8 (deeper) .. 1.4 (brighter, friendlier).
  double pitch = 1.1;

  /// Short sounds for the events that carry a lesson (see SoundCues). Off until the learner turns them on.
  bool sfxEnabled = false;

  /// Loudness of narration, 0 (silent) to 1.
  double volume = 1.0;

  /// False once the platform proved it cannot speak (no engine); the UI then hides itself instead of failing.
  bool available = true;

  bool _loaded = false;
  int _nextId = 1;
  _Utterance? _latest; // the active or pending utterance
  _Utterance? _onEngine; // the utterance the engine is (or may still be) speaking
  bool _engineBusy = false;
  bool _stopRequested = false;
  Completer<void>? _quiet;
  bool _pumping = false;
  int _consecutiveFailures = 0;

  /// Test hook: forget loaded preferences and any utterance, so each test starts from a known state.
  @visibleForTesting
  void debugReset() {
    final u = _latest;
    if (u != null && !u.terminal) _finish(u, SpeechState.cancelled, SpeechOutcome.cancelled, 'test reset');
    _latest = null;
    _loaded = false;
    _consecutiveFailures = 0;
    _engineQuiet();
    diagnostics.clear();
  }

  /// The state of the current utterance, for the UI and tests.
  SpeechState get state => _latest?.state ?? SpeechState.idle;
  int? get activeUtterance => (_latest == null || _latest!.terminal) ? null : _latest!.id;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      enabled = p.getBool('voice_enabled') ?? true;
      voiceName = p.getString('voice_name');
      speed = snapSpeed(p.getDouble('voice_speed') ?? normal);
      pitch = (p.getDouble('voice_pitch') ?? 1.1).clamp(0.8, 1.4);
      sfxEnabled = p.getBool('voice_sfx') ?? false;
      volume = (p.getDouble('voice_volume') ?? 1.0).clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('BitVoice: could not read preferences: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('voice_enabled', enabled);
      voiceName == null ? await p.remove('voice_name') : await p.setString('voice_name', voiceName!);
      await p.setDouble('voice_speed', speed);
      await p.setDouble('voice_pitch', pitch);
      await p.setBool('voice_sfx', sfxEnabled);
      await p.setDouble('voice_volume', volume);
    } catch (e) {
      debugPrint('BitVoice: could not save preferences: $e');
    }
  }

  Future<void> configure({bool? enabled, String? voice, bool clearVoice = false, double? speed, double? pitch, bool? sfx, double? volume}) async {
    if (sfx != null) sfxEnabled = sfx;
    if (volume != null) this.volume = volume.clamp(0.0, 1.0);
    if (enabled != null) this.enabled = enabled;
    if (clearVoice) voiceName = null;
    if (voice != null) voiceName = voice;
    if (speed != null) this.speed = snapSpeed(speed);
    if (pitch != null) this.pitch = pitch.clamp(0.8, 1.4);
    if (!this.enabled) await stop();
    notifyListeners();
    await _save();
  }

  Future<List<String>> voices() async {
    try {
      return await engine.voices();
    } catch (_) {
      return const [];
    }
  }

  /// Turns on-screen text into something that sounds right when read out ("O(n^2)" -> "O of n squared").
  static String speakable(String text) {
    var t = text;
    const swaps = <String, String>{
      'O(1)': 'O of one',
      'O(n^2)': 'O of n squared',
      'O(n log n)': 'O of n log n',
      'O(log n)': 'O of log n',
      'O(n)': 'O of n',
      '->': ' points to ',
      '=>': ' becomes ',
      '!=': ' is not equal to ',
      '==': ' equals ',
      '>=': ' is at least ',
      '<=': ' is at most ',
      '&&': ' and ',
      '||': ' or ',
      '++': ' plus plus ',
      '(s)': '',
    };
    swaps.forEach((k, v) => t = t.replaceAll(k, v));
    t = t.replaceAllMapped(RegExp(r'\btmp\b'), (_) => 'temp').replaceAllMapped(RegExp(r'\bJVM\b'), (_) => 'J V M');
    t = t.replaceAll(RegExp(r'[`*_#]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  // ------------------------------------------------------------------ speaking

  /// Speaks [text] and completes when it has ended (or been cancelled, replaced or failed). Never throws. See
  /// [speakUtterance] for the outcome, [owner] and [tag].
  Future<void> speak(String text, {double rateScale = 1.0, Object? owner, String? tag}) async {
    await speakUtterance(text, rateScale: rateScale, owner: owner, tag: tag);
  }

  /// Speaks [text] as one utterance, superseding whatever is being said. [owner] scopes later cancellation (see
  /// [stop]); [tag] names the event for the diagnostics log; [rateScale] multiplies the learner's speed. The
  /// future completes exactly once, with how the utterance ended.
  Future<SpeechOutcome> speakUtterance(String text, {double rateScale = 1.0, Object? owner, String? tag}) {
    final clean = text.trim();
    if (!enabled || !available || clean.isEmpty) return Future.value(SpeechOutcome.skipped);
    final u = _Utterance(_nextId++, owner, _label(owner), tag, clean, (speed * rateScale));
    final prev = _latest;
    if (prev != null && !prev.terminal) _finish(prev, SpeechState.cancelled, SpeechOutcome.cancelled, 'superseded by #${u.id} (${u.ownerLabel})');
    _latest = u;
    _log(u, 'requested len=${clean.length} rate=${u.normalizedRate.toStringAsFixed(2)}');
    _pump();
    return u.done.future;
  }

  /// Stops speech. With an [owner], only that owner's own utterance is stopped; without one, whatever is being said.
  Future<void> stop({Object? owner}) async {
    final u = _latest;
    if (u == null || u.terminal) {
      if (_lifecycle == null && owner == null) {
        try {
          await _engine.stop();
        } catch (_) {}
      }
      return;
    }
    if (owner != null && !identical(u.owner, owner)) {
      _log(u, 'stop ignored: spoken by ${u.ownerLabel}, requested by ${_label(owner)}');
      return;
    }
    _finish(u, SpeechState.cancelled, SpeechOutcome.cancelled, owner == null ? 'stopped' : 'stopped by owner');
  }

  String _label(Object? o) => o == null ? 'app' : o.runtimeType.toString();

  void _log(_Utterance? u, String what) => diagnostics.add(u?.id, u?.ownerLabel ?? '-', u?.tag, what);

  /// The single runner that hands utterances to the engine one at a time.
  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (true) {
        final u = _latest;
        if (u == null || u.terminal || u.issued) return;
        if (_lifecycle != null) await _awaitQuiet();
        if (u.terminal || !identical(_latest, u)) continue; // superseded while waiting
        await _issue(u);
      }
    } finally {
      _pumping = false;
    }
  }

  /// Waits until the engine has confirmed that whatever it was speaking has stopped. Stopping is requested, not
  /// assumed: the browser only reports the cancel later, and speaking before that drops the new sentence.
  Future<void> _awaitQuiet() async {
    var tries = 0;
    while (_engineBusy && tries < 3) {
      tries++;
      _requestStop();
      final waiter = _quiet ??= Completer<void>();
      var timedOut = false;
      await waiter.future.timeout(timing.quietTimeout, onTimeout: () {
        timedOut = true;
      });
      if (timedOut && _engineBusy) {
        diagnostics.add(null, '-', null, 'quiet-timeout: engine did not confirm the stop (attempt $tries)');
        _stopRequested = false; // ask again
      }
    }
    if (_engineBusy) {
      diagnostics.add(null, '-', null, 'quiet-gave-up: speaking anyway');
      _engineQuiet();
    }
  }

  void _engineQuiet() {
    _engineBusy = false;
    _stopRequested = false;
    _onEngine = null;
    final q = _quiet;
    _quiet = null;
    if (q != null && !q.isCompleted) q.complete();
  }

  void _requestStop() {
    if (_stopRequested) return;
    _stopRequested = true;
    try {
      _engine.stop().catchError((Object _) {});
    } catch (_) {}
  }

  Future<void> _issue(_Utterance u) async {
    u.issued = true;
    u.state = SpeechState.starting;
    final platformRate = platformSpeechRate(u.normalizedRate);
    final startedAt = DateTime.now();
    _log(u, 'starting platform-rate=${platformRate.toStringAsFixed(2)} platform=${kIsWeb ? 'web' : defaultTargetPlatform.name}');
    final lifecycle = _lifecycle != null;
    try {
      if (!lifecycle) {
        // An engine with no events (older engines, test fakes): stop, speak, and take the future as completion.
        try {
          await _engine.stop();
        } catch (_) {}
        if (u.terminal) return;
      }
      final e = _engine;
      if (e is VolumeControl) await (e as VolumeControl).setVolume(volume);
      if (u.terminal) return;
      if (lifecycle) {
        _engineBusy = true;
        _stopRequested = false;
        _onEngine = u;
        u.startTimer = Timer(timing.startTimeout, () {
          if (u.terminal || u.state != SpeechState.starting) return;
          _log(u, 'start-timeout after ${timing.startTimeout.inMilliseconds}ms: the engine never said it started');
          _finish(u, SpeechState.failed, SpeechOutcome.timedOut, 'start-timeout');
        });
      } else {
        _markStarted(u);
      }
      await _engine.speak(speakable(u.text), rate: platformRate, pitch: pitch, voice: voiceName);
      if (lifecycle) {
        // The call returns once the sentence is handed over. If it was cancelled while that was happening, the
        // engine may be about to speak it, so stop again now that it has it.
        if (u.terminal) {
          _stopRequested = false;
          _requestStop();
        }
      } else if (!u.terminal) {
        _log(u, 'engine returned after ${DateTime.now().difference(startedAt).inMilliseconds}ms');
        _finish(u, SpeechState.completed, SpeechOutcome.completed, 'engine future completed');
      }
    } catch (err) {
      if (lifecycle) _engineQuiet();
      if (!u.terminal) {
        _log(u, 'engine error: $err');
        _finish(u, SpeechState.failed, SpeechOutcome.failed, 'engine threw');
      }
      _markUnavailable('$err');
    }
  }

  void _markStarted(_Utterance u) {
    if (u.terminal || u.started) return;
    u.started = true;
    u.state = SpeechState.speaking;
    u.startTimer?.cancel();
    final fallback = timing.completionFallback(u.text.length, u.normalizedRate);
    u.completionTimer = Timer(fallback, () {
      if (u.terminal) return;
      _log(u, 'completion-timeout after ${fallback.inMilliseconds}ms: no completion from the engine, stopping it');
      _finish(u, SpeechState.failed, SpeechOutcome.timedOut, 'completion-timeout');
    });
    _log(u, 'speaking');
  }

  void _onEngineEvent(SpeechEvent e) {
    final u = _onEngine;
    if (u == null) {
      diagnostics.add(null, '-', null, 'engine ${e.kind.name} ignored: nothing is being spoken');
      return;
    }
    if (u.terminal) {
      // The engine finishing a sentence we already ended (a cancel confirming). It is quiet again.
      if (e.kind != SpeechEventKind.started) {
        _log(u, 'engine ${e.kind.name}: confirms the stop');
        _engineQuiet();
      }
      return;
    }
    switch (e.kind) {
      case SpeechEventKind.started:
        _markStarted(u);
      case SpeechEventKind.completed:
        if (!u.started) {
          _log(u, 'completed ignored: it arrived before this sentence started, so it belongs to an earlier one');
          return;
        }
        _engineQuiet();
        _consecutiveFailures = 0;
        _finish(u, SpeechState.completed, SpeechOutcome.completed, 'engine completed');
      case SpeechEventKind.cancelled:
      case SpeechEventKind.error:
        if (e.isCancellation) {
          if (!u.started) {
            _log(u, '${e.kind.name} ignored: it arrived before this sentence started, so it belongs to an earlier one');
            return;
          }
          _engineQuiet();
          _finish(u, SpeechState.cancelled, SpeechOutcome.cancelled, 'engine cancelled');
        } else {
          _engineQuiet();
          _log(u, 'engine error: ${e.message}');
          _finish(u, SpeechState.failed, SpeechOutcome.failed, 'engine error');
          if (++_consecutiveFailures >= 3) _markUnavailable('3 consecutive engine errors');
        }
    }
  }

  /// Ends [u] exactly once: records how, stops the engine if it may still be speaking, and releases the waiter.
  void _finish(_Utterance u, SpeechState state, SpeechOutcome outcome, String reason) {
    if (u.terminal) return;
    u.state = state;
    u.startTimer?.cancel();
    u.completionTimer?.cancel();
    _log(u, '${outcome.name}: $reason (${DateTime.now().difference(u.requestedAt).inMilliseconds}ms since requested)');
    final stillOnEngine = identical(_onEngine, u) && _engineBusy;
    if (outcome != SpeechOutcome.completed) {
      if (stillOnEngine) {
        _requestStop();
      } else if (_lifecycle == null && u.issued) {
        try {
          _engine.stop().catchError((Object _) {});
        } catch (_) {}
      }
    }
    if (!u.done.isCompleted) u.done.complete(outcome);
  }

  void _markUnavailable(String why) {
    diagnostics.add(null, '-', null, 'voice marked unavailable: $why');
    debugPrint('BitVoice: speech unavailable: $why');
    available = false;
    notifyListeners();
  }

  /// Settings and platform in one line for the diagnostics dump.
  String describe() =>
      'platform=${kIsWeb ? 'web' : defaultTargetPlatform.name} engine=${_engine.runtimeType} lifecycleEvents=${_lifecycle != null} '
      'speed=$speed platformRate=${platformSpeechRate(speed).toStringAsFixed(2)} pitch=$pitch volume=$volume enabled=$enabled available=$available';
}
