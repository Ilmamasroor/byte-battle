import '../../../../core/models/backend_models.dart';
import '../../scenes/scene_models.dart';
import '../contract/viz_contract.dart';
import '../modules/algorithms/binary_search_lesson.dart';
import '../modules/algorithms/insertion_sort_lesson.dart';
import '../modules/concurrency/builtin_lost_update.dart';
import '../modules/concurrency/thread_schedule_lesson.dart';
import '../modules/os/round_robin_lesson.dart';
import '../modules/scene_doc/scene_doc_lesson.dart';
import 'curriculum_catalog.dart';

/// Everything the app already knows about one concept that a lesson adapter may turn into a visualization.
class VizSource {
  final String conceptId;

  /// The authored 2D scene bundled for the concept, if any.
  final SceneDoc? scene;

  /// The backend thread simulation for the concept, if the backend served one.
  final VisualizationModel? simulation;

  const VizSource({required this.conceptId, this.scene, this.simulation});
}

/// Builds zero or more lessons for a source. Return an empty list when the adapter does not apply.
typedef VizAdapter = List<VizLesson> Function(VizSource source);

/// The outcome of looking a concept up: the lessons that can be shown, or an explicit reason there are none (the
/// shell then shows its fallback instead of an empty scene).
class VizResolution {
  final List<VizLesson> lessons;
  final String? unsupportedReason;
  final List<String> errors;
  const VizResolution(this.lessons, {this.unsupportedReason, this.errors = const []});

  bool get supported => lessons.isNotEmpty;
}

/// Maps concepts to lessons. Topic modules register an adapter; nothing else needs to change to add one.
///
/// ```dart
/// VizRegistry.instance.register('my-topic', (source) =>
///     source.conceptId == myConceptId ? [myLesson()] : const []);
/// ```
///
/// Adapters run in registration order and their lessons are listed in that order, so register interactive
/// simulations before generic walkthroughs.
class VizRegistry {
  final List<MapEntry<String, VizAdapter>> _adapters = [];

  VizRegistry();

  /// A registry with every built-in module registered.
  factory VizRegistry.standard() {
    final r = VizRegistry();
    r.register('thread-schedule', _threadSchedule);
    r.register('binary-search', (s) => s.conceptId == kBinarySearchConceptId ? [binarySearchLesson(topicId: conceptInfo(s.conceptId)?.topicId)] : const []);
    r.register('insertion-sort', (s) => s.conceptId == kSortingConceptId ? [insertionSortLesson(topicId: conceptInfo(s.conceptId)?.topicId)] : const []);
    r.register('round-robin', (s) => s.conceptId == kCpuSchedulingConceptId ? [roundRobinLesson(topicId: conceptInfo(s.conceptId)?.topicId)] : const []);
    r.register('scene-doc', (s) => s.scene == null ? const [] : [sceneDocLesson(s.scene!)]);
    return r;
  }

  /// The app-wide registry.
  static final VizRegistry instance = VizRegistry.standard();

  List<String> get adapterNames => [for (final e in _adapters) e.key];

  /// Adds an adapter, or replaces the one with the same [name].
  void register(String name, VizAdapter adapter) {
    final i = _adapters.indexWhere((e) => e.key == name);
    if (i >= 0) {
      _adapters[i] = MapEntry(name, adapter);
    } else {
      _adapters.add(MapEntry(name, adapter));
    }
  }

  void unregister(String name) => _adapters.removeWhere((e) => e.key == name);

  /// Asks every adapter. A throwing adapter is skipped (and reported in [VizResolution.errors]) so one faulty
  /// module cannot take the page down.
  VizResolution resolve(VizSource source) {
    final lessons = <VizLesson>[];
    final errors = <String>[];
    for (final e in _adapters) {
      try {
        lessons.addAll(e.value(source));
      } catch (err) {
        errors.add('${e.key}: $err');
      }
    }
    if (lessons.isEmpty) {
      return VizResolution(const [], unsupportedReason: 'There is no 3D visualization for this lesson yet.', errors: errors);
    }
    return VizResolution(lessons, errors: errors);
  }
}

List<VizLesson> _threadSchedule(VizSource s) {
  final sim = s.simulation;
  final info = conceptInfo(s.conceptId);
  if (sim != null && sim.schedules.isNotEmpty) {
    return [
      threadScheduleLesson(
        conceptId: s.conceptId,
        topicId: info?.topicId,
        title: sim.title.isEmpty ? (info?.name ?? 'Threads') : sim.title,
        schedules: sim.schedules,
        hazards: sim.hazards,
        code: sim.code,
        provenance: threadProvenance(sim),
      ),
    ];
  }
  if (s.conceptId == kRaceConditionsConceptId) {
    final b = builtinLostUpdate();
    return [threadScheduleLesson(conceptId: s.conceptId, topicId: info?.topicId, title: b.title, schedules: b.schedules, hazards: b.hazards, code: b.code, provenance: threadProvenance(b))];
  }
  return const [];
}
