import 'dart:convert';
import 'dart:io';
import 'package:byte_battle/core/models/backend_models.dart';
import 'package:byte_battle/features/learning/scenes/scene_models.dart';
import 'package:byte_battle/features/learning/viz3d/contract/viz_contract.dart';
import 'package:byte_battle/features/learning/viz3d/render/scene_spec.dart';
import 'package:flutter/material.dart';

const raceId = '00000000-0000-0000-0000-000000001003';
const binarySearchId = '00000000-0000-0000-0000-000000001008';
const sortingId = '00000000-0000-0000-0000-000000001009';
const schedulingId = '00000000-0000-0000-0000-000000001035';

/// Every bundled scene document, keyed by concept id.
Map<String, SceneDoc> loadSceneDocs() {
  final dir = Directory('assets/scenes');
  final out = <String, SceneDoc>{};
  for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
    final doc = SceneDoc.fromJson(jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
    out[doc.conceptId] = doc;
  }
  return out;
}

/// A tiny hand-made timeline over a counter (0, 1, 2, 3) so engine tests do not depend on a topic module.
class CounterState {
  final int n;
  const CounterState(this.n);
}

ReducerTimeline<CounterState, int> counterTimeline({int steps = 3, String prefix = 'c'}) => ReducerTimeline<CounterState, int>(
      initial: const CounterState(0),
      events: List.generate(steps, (i) => i + 1),
      reduce: (s, e) => CounterState(e),
      explain: (s, e, p) => VizExplanation('$prefix is ${s.n}', variables: {'n': '${s.n}'}),
      scene: (s, p) => SceneSpec(nodes: [
        SceneNode(
            id: 'box',
            shape: SceneShape.box,
            position: Vec3(s.n.toDouble(), 0.5, 0),
            size: const Vec3(1, 1, 1),
            color: Colors.orange,
            label: '${s.n}',
            selectable: true,
            inspect: {'Value': '${s.n}'}),
      ]),
      outcome: (fin) => VizOutcome(label: 'final', expected: '$steps', actual: '${fin.n}', meaning: 'counted'),
      isMarker: (s, e, p) => s.n == steps,
    );

VizLesson counterLesson({String id = 'counter', int steps = 3, List<VizVariant>? variants, List<VizParam> params = const []}) => VizLesson(
      id: id,
      conceptId: 'x',
      category: VizCategory.algorithms,
      title: 'Counter $id',
      variants: variants ?? const [VizVariant('a', 'Variant A')],
      params: params,
      builder: (variant, p) => counterTimeline(steps: int.tryParse(p['steps'] ?? '') ?? steps, prefix: '$id/$variant'),
    );

/// A timeline whose frame at [failAt] throws, to exercise the renderer-failure fallback.
class ExplodingTimeline extends VizTimeline {
  final int failAt;
  ExplodingTimeline({this.failAt = 2});

  @override
  int get length => 4;

  @override
  VizFrame frameAt(int position) {
    if (position == failAt) throw StateError('boom at $position');
    return VizFrame(
      SceneSpec(nodes: [SceneNode(id: 'a', shape: SceneShape.box, position: Vec3(position.toDouble(), 0.5, 0), size: const Vec3(1, 1, 1), color: Colors.teal)]),
      VizExplanation('step $position of an exploding lesson'),
    );
  }

  @override
  SceneBounds get bounds => SceneBounds.unit;
}

/// The race-condition schedule shape the backend returns (read, sleep, write per thread, hazard on both writes).
VisualizationModel backendRace() {
  Map<String, dynamic> step(int i, String t, int op, String kind, String text, {int? value, int? local, bool hazard = false, int line = 0, bool stale = false}) => {
        'index': i,
        'thread': t,
        'opIndex': op,
        'kind': kind,
        'target': kind == 'SLEEP' ? '1 ms' : 'count',
        'line': line,
        'text': text,
        'hazard': hazard,
        if (value != null) 'value': value,
        if (local != null) 'local': local,
        if (stale) 'stale': true,
      };
  return VisualizationModel.fromJson({
    'title': 'Counter race',
    'visualization': {
      'schedules': [
        {
          'kind': 'RACE',
          'threads': ['Thread-1-1', 'Thread-2-2'],
          'expected': {'count': 2},
          'finalValues': {'count': 1},
          'steps': [
            step(0, 'Thread-1-1', 0, 'READ', 'read count', value: 0, local: 0, line: 1),
            step(1, 'Thread-2-2', 0, 'READ', 'read count', value: 0, local: 0, line: 1),
            step(2, 'Thread-1-1', 1, 'SLEEP', 'Thread.sleep(1)'),
            step(3, 'Thread-1-1', 2, 'WRITE', 'count = current + 1', value: 1, hazard: true, line: 2),
            step(4, 'Thread-2-2', 1, 'SLEEP', 'Thread.sleep(1)'),
            step(5, 'Thread-2-2', 2, 'WRITE', 'count = current + 1', value: 1, hazard: true, line: 2, stale: true),
          ],
        },
        {
          'kind': 'DEADLOCK',
          'threads': ['Thread-1-1', 'Thread-2-2'],
          'steps': [
            {
              'index': 0,
              'thread': 'Thread-1-1',
              'opIndex': 0,
              'kind': 'LOCK',
              'target': 'A',
              'line': 3,
              'text': 'lock A',
              'hazard': true,
              'holds': ['A']
            },
            {
              'index': 1,
              'thread': 'Thread-2-2',
              'opIndex': 0,
              'kind': 'LOCK',
              'target': 'B',
              'line': 4,
              'text': 'lock B',
              'hazard': true,
              'holds': ['B']
            },
            {
              'index': 2,
              'thread': 'Thread-1-1',
              'opIndex': 1,
              'kind': 'LOCK',
              'target': 'B',
              'line': 5,
              'text': 'lock B',
              'hazard': true,
              'blocked': true,
              'waitingFor': 'Thread-2-2'
            },
            {
              'index': 3,
              'thread': 'Thread-2-2',
              'opIndex': 1,
              'kind': 'LOCK',
              'target': 'A',
              'line': 6,
              'text': 'lock A',
              'hazard': true,
              'blocked': true,
              'waitingFor': 'Thread-1-1'
            },
          ],
        },
      ],
      'hazards': [
        {
          'type': 'LOST_UPDATE',
          'explanation': 'Both threads wrote a stale value.',
          'fixSuggestion': 'Use a lock.',
          'steps': [3, 5]
        },
      ],
      'fixSuggestion': 'Synchronize the increment.',
    },
  }, code: 'class C {\n  int count;\n  void inc() { count++; }\n}');
}
