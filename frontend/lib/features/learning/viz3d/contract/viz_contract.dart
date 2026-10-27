import 'package:flutter/widgets.dart';
import '../render/scene_spec.dart';

/// The broad family a visualization belongs to. It drives labelling and the coverage matrix, not rendering: each
/// topic module decides how its own state looks.
enum VizCategory {
  codeExecution('Code execution'),
  dataStructures('Data structures'),
  algorithms('Algorithms'),
  database('Databases'),
  operatingSystems('Operating systems'),
  concurrency('Concurrency'),
  networks('Networks'),
  systemDesign('System design'),
  interview('Interview prep');

  final String label;
  const VizCategory(this.label);
}

/// What the learner may do in the 3D view beyond play controls. A lesson lists only the ones that mean something
/// for it.
enum VizInteraction { orbit, zoom, select, replay, compare }

/// Everything the explanation layer shows for one position on the timeline.
class VizExplanation {
  final String text;
  final String? note; // short monospace caption, e.g. `mid = (0 + 6) / 2 = 3`
  final List<int> codeLines; // 0-based lines of [VizTimeline.code] that are executing
  final Map<String, String> variables; // named values worth showing right now
  final List<String> output; // program output or results so far
  final String? hazard; // set when this position is where the lesson's bug/anomaly happens

  /// One sentence on why this event matters (the cause of what follows), shown in the event inspector.
  final String? why;

  /// What is said aloud when it differs from [text] (spoken text should be plain words, never raw code).
  final String? spoken;

  /// The value this event changes: what it is, and its value before and after. Null when nothing changes.
  final VizChange? change;

  /// The sound cue id for this event (see SoundCue), or null for a silent event.
  final String? cue;

  const VizExplanation(this.text,
      {this.note, this.codeLines = const [], this.variables = const {}, this.output = const [], this.hazard, this.why, this.spoken, this.change, this.cue});

  /// The words narrated and captioned for this position. Captions and speech always come from this one string.
  String get narration => spoken ?? text;
}

/// A value an event changes, e.g. `shared count: 0 -> 1`.
class VizChange {
  final String what;
  final String before;
  final String after;
  const VizChange(this.what, this.before, this.after);

  bool get isChange => before != after;
}

/// One event on the timeline strip: who did it and what kind of event it was.
class VizEventMark {
  final int position; // the timeline position reached after this event
  final int actor; // index into [VizTimeline.actors]
  final String label; // short, e.g. `read`
  final bool problem; // the event where the anomaly happens
  final bool waiting; // the actor could not proceed
  const VizEventMark(this.position, this.actor, this.label, {this.problem = false, this.waiting = false});
}

enum VizProvenanceKind { simulation, authored }

/// Says where a visualization's events come from, so a modelled sequence is never mistaken for a recorded run.
class VizProvenance {
  final VizProvenanceKind kind;
  final String label; // the badge text
  final String detail; // one honest sentence
  final List<String> caveats; // stated simplifications
  const VizProvenance(this.kind, this.label, this.detail, {this.caveats = const []});
}

/// One reconstructed position: what to draw and what to say.
class VizFrame {
  final SceneSpec scene;
  final VizExplanation explanation;
  const VizFrame(this.scene, this.explanation);
}

/// The checked result of a timeline: the value it ends on versus the value the lesson declares it must end on.
/// Validation is computed from the deterministic final state, never from AI output.
class VizOutcome {
  final String label; // what is being compared, e.g. `final count`
  final String expected;
  final String actual;
  final String meaning; // one sentence about why they match or differ
  const VizOutcome({required this.label, required this.expected, required this.actual, required this.meaning});

  bool get matches => expected == actual;
}

/// A "guess first, then watch" question a lesson may ask before it plays. The answer is authored with the lesson,
/// never generated at run time.
class VizPrediction {
  final String question;
  final List<String> options;
  final int answer; // index into [options]
  final String reveal; // why the answer is right, shown after the run

  const VizPrediction(this.question, this.options, this.answer, this.reveal);
}

/// A way of running the same lesson (the bug vs the fix, or a different input). Each variant is its own timeline.
class VizVariant {
  final String id;
  final String label;
  const VizVariant(this.id, this.label);
}

/// A learner-controlled input with a fixed set of choices (a search target, an input array, a quantum). Changing
/// it rebuilds the timeline from scratch, so every value on screen is computed from the chosen input.
class VizParam {
  final String id;
  final String label;
  final List<VizChoice> choices;
  final String initial;
  const VizParam(this.id, this.label, this.choices, this.initial);
}

class VizChoice {
  final String value;
  final String label;
  const VizChoice(this.value, this.label);
}

/// A deterministic sequence of positions `0 .. length - 1`. Position `p` always yields the same [VizFrame], no
/// matter how the learner got there, so seeking is a direct lookup rather than a replay.
abstract class VizTimeline {
  int get length;

  /// The frame at [position]. Must be pure and must throw only [RangeError] for out-of-range positions.
  VizFrame frameAt(int position);

  /// Source lines the explanation highlights (may be empty).
  List<String> get code => const [];

  /// The declared expectation checked against the final state, if the lesson has one.
  VizOutcome? get outcome => null;

  /// Positions the scrubber marks (where the bug happens, where the answer is found).
  Set<int> get markers => const {};

  /// Who acts in this timeline (thread names), in a fixed order; [eventMarks] refer to it by index.
  List<String> get actors => const [];

  /// One mark per event, for the event timeline strip. Empty for lessons that do not have separate actors.
  List<VizEventMark> get eventMarks => const [];

  /// The viewing angle used when the camera is reset.
  CameraHint get cameraHint => const CameraHint();

  /// The box around every frame, so the camera never has to move to keep the scene in view.
  SceneBounds get bounds {
    SceneBounds? b;
    for (var i = 0; i < length; i++) {
      final fb = frameAt(i).scene.bounds;
      b = b == null ? fb : b.union(fb);
    }
    return b ?? SceneBounds.unit;
  }
}

/// A timeline built from a reducer: [initial] state, a list of [events], and a pure [reduce]. States are folded
/// once and cached, which is state reconstruction, not animation replay.
///
/// Domain modules supply their own state type `S` and event type `E` instead of sharing one universal model.
class ReducerTimeline<S, E> extends VizTimeline {
  final S initial;
  final List<E> events;
  final S Function(S state, E event) reduce;
  final VizExplanation Function(S state, E? event, int position) explain;
  final SceneSpec Function(S state, int position) scene;
  final VizOutcome? Function(S finalState)? _outcome;
  final bool Function(S state, E? event, int position)? _isMarker;
  final VizEventMark Function(S state, E event, int position)? _mark;
  @override
  final List<String> actors;
  @override
  final List<String> code;
  @override
  final CameraHint cameraHint;

  late final List<S> _states = _fold();
  late final Set<int> _markers = _computeMarkers();
  final Map<int, VizFrame> _frames = {};

  ReducerTimeline({
    required this.initial,
    required this.events,
    required this.reduce,
    required this.explain,
    required this.scene,
    VizOutcome? Function(S finalState)? outcome,
    bool Function(S state, E? event, int position)? isMarker,
    VizEventMark Function(S state, E event, int position)? mark,
    this.actors = const [],
    this.code = const [],
    this.cameraHint = const CameraHint(),
  })  : _outcome = outcome,
        _isMarker = isMarker,
        _mark = mark;

  List<S> _fold() {
    final out = <S>[initial];
    for (final e in events) {
      out.add(reduce(out.last, e));
    }
    return out;
  }

  Set<int> _computeMarkers() {
    final m = _isMarker;
    if (m == null) return const {};
    return {
      for (var i = 0; i < length; i++)
        if (m(_states[i], i == 0 ? null : events[i - 1], i)) i,
    };
  }

  @override
  int get length => events.length + 1;

  /// The domain state at [position].
  S stateAt(int position) {
    RangeError.checkValidIndex(position, _states, 'position', length);
    return _states[position];
  }

  S get finalState => _states.last;

  @override
  Set<int> get markers => _markers;

  @override
  late final List<VizEventMark> eventMarks = _mark == null
      ? const []
      : [for (var i = 1; i < length; i++) _mark!(_states[i], events[i - 1], i)];

  @override
  VizOutcome? get outcome => _outcome?.call(finalState);

  @override
  VizFrame frameAt(int position) {
    RangeError.checkValidIndex(position, _states, 'position', length);
    return _frames.putIfAbsent(position, () {
      final s = _states[position];
      final e = position == 0 ? null : events[position - 1];
      return VizFrame(scene(s, position), explain(s, e, position));
    });
  }
}

/// A visualizable lesson: identity, what it teaches, and how to build a timeline for a variant and a set of inputs.
///
/// A lesson declares what is shown and what the valid transitions are (inside [build]); the renderer only decides
/// how a [SceneSpec] looks.
class VizLesson {
  final String id;
  final int version;
  final String conceptId;
  final String? topicId;
  final VizCategory category;
  final String title;
  final String summary;
  final List<VizVariant> variants;
  final List<VizParam> params;
  final Set<VizInteraction> interactions;

  /// Set when the picture is a metaphor, so the learner is told what it stands for.
  final String? abstractionNote;

  /// An optional question asked before the lesson plays.
  final VizPrediction? predict;

  /// Where the events come from (a teaching simulation, authored data). Null for lessons that do not say.
  final VizProvenance? provenance;

  /// A 2D / code-centric alternative shown when 3D is unavailable or switched off. When null the shell shows the
  /// step-by-step text trace built from the timeline itself.
  final WidgetBuilder? flatBuilder;

  final VizTimeline Function(String variant, Map<String, String> params) _builder;

  VizLesson({
    required this.id,
    required this.conceptId,
    required this.category,
    required this.title,
    required VizTimeline Function(String variant, Map<String, String> params) builder,
    this.version = 1,
    this.topicId,
    this.summary = '',
    this.variants = const [VizVariant('default', 'Walkthrough')],
    this.params = const [],
    this.interactions = const {VizInteraction.orbit, VizInteraction.zoom, VizInteraction.select, VizInteraction.replay},
    this.abstractionNote,
    this.predict,
    this.provenance,
    this.flatBuilder,
  }) : _builder = builder;

  Map<String, String> get defaultParams => {for (final p in params) p.id: p.initial};

  /// Builds the timeline for [variant] with [overrides] applied over the default inputs.
  VizTimeline build({String? variant, Map<String, String> overrides = const {}}) {
    final v = variants.any((x) => x.id == variant) ? variant! : variants.first.id;
    return _builder(v, {...defaultParams, ...overrides});
  }
}
