import 'package:flutter/material.dart';
import '../../../scenes/scene_models.dart';
import '../../../scenes/scene_view.dart';
import '../../contract/viz_contract.dart';
import '../../registry/curriculum_catalog.dart';
import '../../render/scene_spec.dart';
import 'doc_state.dart';
import 'layout_computer.dart';
import 'layout_flow.dart';
import 'layout_sequence.dart';
import 'layout_structure.dart';
import 'layout_table.dart';

/// Turns an authored [SceneDoc] (the app's existing 2D narrated lessons) into a 3D lesson.
///
/// This is the lesson adapter for every concept that ships with a scene: the document's steps are the
/// deterministic events, each step's merged state is the domain state, and one layout per [SceneKind] decides how
/// that state looks in 3D. The 2D [SceneView] stays available as the fallback.
VizLesson sceneDocLesson(SceneDoc doc) {
  final info = conceptInfo(doc.conceptId);
  return VizLesson(
    id: 'scene/${doc.conceptId}',
    conceptId: doc.conceptId,
    topicId: info?.topicId,
    category: info?.category ?? _defaultCategory(doc.kind),
    title: doc.title,
    summary: doc.intro,
    variants: const [VizVariant('walkthrough', 'Walkthrough')],
    abstractionNote: _abstraction(doc.kind),
    predict: doc.predict == null ? null : VizPrediction(doc.predict!.question, doc.predict!.options, doc.predict!.answer, doc.predict!.reveal),
    flatBuilder: (context) => SceneView(key: ValueKey('flat:${doc.conceptId}'), doc: doc),
    builder: (variant, params) => sceneDocTimeline(doc),
  );
}

VizCategory _defaultCategory(SceneKind k) {
  switch (k) {
    case SceneKind.computer:
      return VizCategory.codeExecution;
    case SceneKind.structure:
      return VizCategory.dataStructures;
    case SceneKind.table:
      return VizCategory.database;
    case SceneKind.sequence:
      return VizCategory.systemDesign;
    case SceneKind.flow:
      return VizCategory.interview;
  }
}

String? _abstraction(SceneKind k) {
  switch (k) {
    case SceneKind.computer:
      return 'The chamber is a simplified machine: the stack is a tower, the heap is a shelf of objects, and arrows are references.';
    case SceneKind.flow:
      return 'These cards are ideas, not physical things: the raised glowing card is the step you are on.';
    case SceneKind.sequence:
      return 'Time runs toward you: each arrow is one message, placed on the floor in the order it was sent.';
    default:
      return null;
  }
}

/// The timeline for a document. Exposed separately so tests can drive it without a widget.
ReducerTimeline<DocState, SceneStep> sceneDocTimeline(SceneDoc doc) {
  final steps = doc.steps;
  List<Map<String, dynamic>> messagesOf(SceneStep s) {
    final out = <Map<String, dynamic>>[];
    final m = s.state['msg'];
    if (m is Map) out.add(Map<String, dynamic>.from(m));
    final ms = s.state['msgs'];
    if (ms is List) out.addAll(ms.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
    return out;
  }

  final first = steps.first;
  final lines = _codeLines(first.state);
  return ReducerTimeline<DocState, SceneStep>(
    initial: DocState(state: first.state, messages: messagesOf(first)),
    events: steps.skip(1).toList(),
    reduce: (s, step) => DocState(state: step.state, prev: s.state, messages: [...s.messages, ...messagesOf(step)], index: s.index + 1),
    code: lines,
    cameraHint: _hint(doc.kind),
    explain: (s, step, pos) {
      final cur = step ?? first;
      final last = pos == steps.length - 1;
      return VizExplanation(
        last && doc.takeaway.isNotEmpty ? '${cur.say} ${doc.takeaway}'.trim() : cur.say,
        note: cur.note,
        codeLines: _atLines(s.state),
        variables: _variables(s.state),
        output: [for (final c in asList(s.state['console'])) str(c)],
      );
    },
    scene: (s, pos) => _layout(doc.kind, s),
  );
}

CameraHint _hint(SceneKind k) {
  switch (k) {
    case SceneKind.table:
      return const CameraHint(yaw: -0.15, pitch: 0.7);
    case SceneKind.sequence:
      return const CameraHint(yaw: -0.4, pitch: 0.62);
    case SceneKind.computer:
      return const CameraHint(yaw: -0.2, pitch: 0.62);
    default:
      return const CameraHint(yaw: -0.25, pitch: 0.58);
  }
}

SceneSpec _layout(SceneKind k, DocState s) {
  switch (k) {
    case SceneKind.structure:
      return layoutStructure(s);
    case SceneKind.table:
      return layoutTable(s);
    case SceneKind.sequence:
      return layoutSequence(s);
    case SceneKind.flow:
      return layoutFlow(s);
    case SceneKind.computer:
      return layoutComputer(s);
  }
}

List<String> _codeLines(Map<String, dynamic> state) {
  final code = state['code'];
  return code is Map ? [for (final l in asList(code['lines'])) str(l)] : const [];
}

List<int> _atLines(Map<String, dynamic> state) {
  final code = state['code'];
  if (code is! Map) return const [];
  final at = code['at'];
  return [
    if (at is num && at >= 0) at.toInt(),
    if (at is List)
      for (final a in at)
        if (a is num && a >= 0) a.toInt(),
  ];
}

/// The values worth reading off the scene right now: registers, local variables, and array pointers.
Map<String, String> _variables(Map<String, dynamic> state) {
  final out = <String, String>{};
  final cpu = asMap(state['cpu']);
  for (final e in asMap(cpu['regs']).entries) {
    out[e.key] = str(e.value);
  }
  for (final f in asList(state['stack']).map(asMap)) {
    for (final e in asMap(f['vars']).entries) {
      out[e.key] = str(e.value);
    }
  }
  for (final b in asList(state['structures']).map(asMap)) {
    for (final e in asMap(b['pointers']).entries) {
      out[e.key] = str(e.value);
    }
  }
  return out;
}
