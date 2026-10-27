import 'package:flutter/foundation.dart';
import '../contract/viz_contract.dart';
import '../render/scene_spec.dart';
import 'playback_controller.dart';

/// A timeline that stands in when a lesson's builder throws: one frame that says so, never an empty scene.
class _FailedTimeline extends VizTimeline {
  final String message;
  _FailedTimeline(this.message);

  @override
  int get length => 1;

  @override
  VizFrame frameAt(int position) => VizFrame(SceneSpec.empty, VizExplanation(message));
}

/// Everything the learner has chosen for one visualization: which lesson, which variant and inputs, the timeline
/// built from them, the playback controller, the selected object and the 3D/flat preference.
///
/// There is exactly one session per visualization on screen. Changing the lesson, variant or an input rebuilds
/// the timeline and resets playback and selection in one step, so nothing from the previous choice can linger.
class VizSession extends ChangeNotifier {
  final List<VizLesson> lessons;
  final VizPlaybackController controller;

  int _lessonIndex = 0;
  late String _variantId;
  late Map<String, String> _params;
  late VizTimeline _timeline;
  String? _selectedId;
  bool _prefer3D = true;
  int? _guess; // the learner's answer to the lesson's prediction question; -1 = skipped
  Object? _failure;
  Object? _buildError;
  bool _disposed = false;
  final Map<String, VizTimeline> _cache = {};

  VizSession({required this.lessons, VizPlaybackController? controller, VoidCallback? onFinished, String? variant, int lessonIndex = 0, bool prefer3D = true})
      : assert(lessons.isNotEmpty, 'a session needs at least one lesson'),
        controller = controller ?? VizPlaybackController(onFinished: onFinished) {
    _prefer3D = prefer3D;
    _lessonIndex = lessonIndex.clamp(0, lessons.length - 1);
    _variantId = lesson.variants.any((v) => v.id == variant) ? variant! : lesson.variants.first.id;
    _params = lesson.defaultParams;
    _rebuild(notify: false);
  }

  VizLesson get lesson => lessons[_lessonIndex];
  int get lessonIndex => _lessonIndex;
  String get variantId => _variantId;
  Map<String, String> get params => Map.unmodifiable(_params);
  VizTimeline get timeline => _timeline;
  String? get selectedId => _selectedId;
  bool get prefer3D => _prefer3D;

  /// True while the lesson asks a prediction question the learner has neither answered nor skipped.
  bool get needsGuess => lesson.predict != null && _guess == null;
  int? get guess => _guess;

  /// Why 3D is not being shown (a render or build failure), or null when it is available.
  Object? get failure => _failure;

  /// True when the 3D view should be shown: the learner wants it and nothing has failed.
  bool get show3D => _prefer3D && _failure == null && _buildError == null;

  /// The frame at the current position.
  VizFrame get frame => frameAt(controller.position);

  /// The frame at [position], clamped to the timeline. A timeline that throws for one position yields a plain
  /// "could not be shown" explanation for it instead of taking the whole screen down.
  VizFrame frameAt(int position) {
    try {
      return _timeline.frameAt(position.clamp(0, _timeline.length - 1));
    } catch (_) {
      return VizFrame(SceneSpec.empty, const VizExplanation('This step could not be shown.'));
    }
  }

  /// Records the learner's answer to the prediction question ([skip] passes -1).
  void answerPrediction(int choice) {
    if (_guess == choice) return;
    _guess = choice;
    _notify();
  }

  void selectLesson(int index) {
    if (index == _lessonIndex || index < 0 || index >= lessons.length) return;
    _lessonIndex = index;
    _guess = null;
    _variantId = lesson.variants.first.id;
    _params = lesson.defaultParams;
    _failure = null;
    _rebuild();
  }

  void setVariant(String id) {
    if (id == _variantId || !lesson.variants.any((v) => v.id == id)) return;
    _variantId = id;
    _rebuild();
  }

  void setParam(String id, String value) {
    if (_params[id] == value || !lesson.params.any((p) => p.id == id)) return;
    _params = {..._params, id: value};
    _rebuild();
  }

  void select(String? id) {
    if (id == _selectedId) return;
    _selectedId = id;
    _notify();
  }

  void set3D(bool on) {
    if (_prefer3D == on && (on == false || _failure == null)) return;
    _prefer3D = on;
    if (on) _failure = null; // an explicit retry
    _notify();
  }

  /// Called by the viewport when drawing fails. The learner keeps the flat view and the whole explanation.
  void reportFailure(Object error) {
    if (_failure != null) return;
    _failure = error;
    controller.pause();
    _notify();
  }

  /// The outcome of [variant] with the current inputs, for the side-by-side comparison. Built on demand.
  VizOutcome? outcomeOf(String variant) => _timelineFor(variant, _params).outcome;

  VizTimeline _timelineFor(String variant, Map<String, String> params) {
    final key = '${lesson.id}|$variant|${(params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}=${e.value}').join('&')}';
    return _cache.putIfAbsent(key, () => lesson.build(variant: variant, overrides: params));
  }

  void _rebuild({bool notify = true}) {
    _buildError = null;
    try {
      _timeline = _timelineFor(_variantId, _params);
    } catch (e) {
      _buildError = e;
      _timeline = _FailedTimeline('This visualization could not be built: $e');
    }
    _selectedId = null;
    controller.configure(_timeline.length);
    if (notify) _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    controller.dispose();
    super.dispose();
  }
}
