import '../../../../../app/theme/app_colors.dart';
import '../../contract/viz_contract.dart';
import '../../render/scene_spec.dart';
import '../scene_kit.dart';
import '../viz_palette.dart';

const kSortingConceptId = '00000000-0000-0000-0000-000000001009';

const kSortInputs = {
  'mixed': [6, 3, 8, 2, 9, 1, 5],
  'reversed': [9, 8, 6, 5, 3, 2, 1],
  'nearly': [1, 2, 4, 3, 5, 7, 6],
  'sorted': [1, 2, 3, 4, 5, 6, 7],
};

const _code = [
  'for (int i = 1; i < n; i++) {',
  '  int key = a[i];',
  '  int j = i - 1;',
  '  while (j >= 0 && a[j] > key) {',
  '    a[j + 1] = a[j];',
  '    j--;',
  '  }',
  '  a[j + 1] = key;',
  '}',
];

enum SortKind { pick, compareBigger, shift, compareStop, insert }

class SortEvent {
  final SortKind kind;
  final int i; // the element being inserted
  final int j; // the element it is being compared with
  const SortEvent(this.kind, this.i, this.j);
}

/// Domain state: the array with one gap while an element is held out of it.
class SortState {
  final List<int?> cells; // null = the gap left by the held element
  final int? key;
  final int i;
  final int? j;
  final int comparisons;
  final int shifts;
  final SortKind? last;
  const SortState({required this.cells, this.key, this.i = 0, this.j, this.comparisons = 0, this.shifts = 0, this.last});
}

/// Runs insertion sort on [input] and records each decision. Pure and deterministic.
List<SortEvent> insertionSortEvents(List<int> input) {
  final a = [...input];
  final out = <SortEvent>[];
  for (var i = 1; i < a.length; i++) {
    final key = a[i];
    out.add(SortEvent(SortKind.pick, i, i - 1));
    var j = i - 1;
    while (j >= 0) {
      if (a[j] > key) {
        out.add(SortEvent(SortKind.compareBigger, i, j));
        a[j + 1] = a[j];
        out.add(SortEvent(SortKind.shift, i, j));
        j--;
      } else {
        out.add(SortEvent(SortKind.compareStop, i, j));
        break;
      }
    }
    a[j + 1] = key;
    out.add(SortEvent(SortKind.insert, i, j + 1));
  }
  return out;
}

VizLesson insertionSortLesson({String conceptId = kSortingConceptId, String? topicId}) => VizLesson(
      id: 'insertion-sort/$conceptId',
      conceptId: conceptId,
      topicId: topicId,
      category: VizCategory.algorithms,
      title: 'Insertion sort on your input',
      summary: 'Choose an input and watch real comparisons and shifts.',
      params: const [
        VizParam(
            'input',
            'Input',
            [
              VizChoice('mixed', 'Mixed'),
              VizChoice('reversed', 'Reversed'),
              VizChoice('nearly', 'Nearly sorted'),
              VizChoice('sorted', 'Already sorted'),
            ],
            'mixed'),
      ],
      builder: (variant, params) => _timeline(kSortInputs[params['input']] ?? kSortInputs['mixed']!),
    );

VizTimeline _timeline(List<int> input) {
  final events = insertionSortEvents(input);
  final n = input.length;
  final maxV = input.reduce((a, b) => a > b ? a : b);
  final sorted = [...input]..sort();

  SortState reduce(SortState s, SortEvent e) {
    final cells = [...s.cells];
    switch (e.kind) {
      case SortKind.pick:
        final key = cells[e.i]!;
        cells[e.i] = null;
        return SortState(cells: cells, key: key, i: e.i, j: e.j, comparisons: s.comparisons, shifts: s.shifts, last: e.kind);
      case SortKind.compareBigger:
        return SortState(cells: cells, key: s.key, i: e.i, j: e.j, comparisons: s.comparisons + 1, shifts: s.shifts, last: e.kind);
      case SortKind.shift:
        cells[e.j + 1] = cells[e.j];
        cells[e.j] = null;
        return SortState(cells: cells, key: s.key, i: e.i, j: e.j, comparisons: s.comparisons, shifts: s.shifts + 1, last: e.kind);
      case SortKind.compareStop:
        return SortState(cells: cells, key: s.key, i: e.i, j: e.j, comparisons: s.comparisons + 1, shifts: s.shifts, last: e.kind);
      case SortKind.insert:
        cells[e.j] = s.key;
        return SortState(cells: cells, key: null, i: e.i, j: e.j, comparisons: s.comparisons, shifts: s.shifts, last: e.kind);
    }
  }

  return ReducerTimeline<SortState, SortEvent>(
    initial: SortState(cells: [...input]),
    events: events,
    reduce: reduce,
    code: _code,
    cameraHint: const CameraHint(yaw: -0.2, pitch: 0.5),
    isMarker: (s, e, p) => e != null && e.kind == SortKind.insert,
    outcome: (fin) => VizOutcome(
      label: 'sorted array',
      expected: sorted.join(' '),
      actual: fin.cells.map((c) => c ?? '_').join(' '),
      meaning: '${fin.comparisons} comparisons and ${fin.shifts} shifts for ${input.length} items.',
    ),
    explain: (s, e, p) {
      final vars = {'i': '${s.i}', if (s.key != null) 'key': '${s.key}', if (s.j != null) 'j': '${s.j}', 'comparisons': '${s.comparisons}', 'shifts': '${s.shifts}'};
      if (e == null) {
        return VizExplanation('Here is the unsorted list. The first item alone is already a sorted hand of one card. We will grow that hand one item at a time.',
            codeLines: const [0], variables: {'n': '$n'});
      }
      switch (e.kind) {
        case SortKind.pick:
          return VizExplanation('Pick up ${s.key} from index ${e.i}. Everything left of it is already sorted; find where ${s.key} belongs.',
              note: 'key = a[${e.i}] = ${s.key}', codeLines: const [1, 2], variables: vars);
        case SortKind.compareBigger:
          return VizExplanation('${s.cells[e.j]} is bigger than ${s.key}, so it must move one step right to make room.',
              note: 'a[${e.j}] > ${s.key}', codeLines: const [3], variables: vars);
        case SortKind.shift:
          return VizExplanation('Shift it right into the gap.', note: 'a[${e.j + 1}] = a[${e.j}]', codeLines: const [4, 5], variables: vars);
        case SortKind.compareStop:
          return VizExplanation('${s.cells[e.j]} is not bigger than ${s.key}, so ${s.key} belongs right after it. Stop shifting.',
              note: 'a[${e.j}] <= ${s.key}', codeLines: const [3], variables: vars);
        case SortKind.insert:
          final key = s.cells[e.j];
          return VizExplanation('Drop $key into the gap at index ${e.j}. The sorted hand now covers indexes 0 to ${e.i}.',
              note: 'a[${e.j}] = $key', codeLines: const [7], variables: vars);
      }
    },
    scene: (s, p) {
      final nodes = <SceneNode>[];
      const spacing = 1.2;
      final sortedUpTo = s.last == null ? 0 : s.i;
      for (var idx = 0; idx < n; idx++) {
        final v = s.cells[idx];
        final x = SceneKit.rowX(idx, n, spacing);
        if (v == null) {
          nodes
              .add(SceneNode(id: 'gap:$idx', shape: SceneShape.box, position: Vec3(x, 0.15, 0), size: const Vec3(0.95, 0.3, 0.95), color: AppColors.orchid, glow: 0.5, wire: true));
          continue;
        }
        final h = SceneKit.barHeight(v, maxV);
        final isSorted = idx <= sortedUpTo;
        String state = isSorted ? 'done' : 'idle';
        if (s.j == idx && (s.last == SortKind.compareBigger || s.last == SortKind.compareStop)) state = 'compare';
        if (s.last == SortKind.shift && s.j != null && idx == s.j! + 1) state = 'swap';
        if (s.last == SortKind.insert && s.j == idx) state = 'found';
        nodes.add(SceneNode(
          id: 'val:$v@${_occurrence(input, s.cells, idx)}',
          shape: SceneShape.box,
          position: Vec3(x, h / 2, 0),
          size: Vec3(0.95, h, 0.95),
          color: VizPalette.state(state),
          glow: VizPalette.glow(state),
          label: '$v',
          labelSize: 0.34,
          selectable: true,
          inspect: {'What': 'Array item', 'Index': '$idx', 'Value': '$v', 'Status': isSorted ? 'in the sorted hand' : 'not sorted yet'},
        ));
      }
      if (s.key != null) {
        final h = SceneKit.barHeight(s.key!, maxV);
        final gapIdx = s.cells.indexOf(null);
        final x = gapIdx < 0 ? 0.0 : SceneKit.rowX(gapIdx, n, spacing);
        nodes.add(SceneNode(
          id: 'key',
          shape: SceneShape.box,
          position: Vec3(x, 3.6 + h / 2, 0),
          size: Vec3(0.95, h, 0.95),
          color: AppColors.primary,
          glow: 0.9,
          label: '${s.key}',
          labelSize: 0.34,
          selectable: true,
          inspect: {'What': 'The key being inserted', 'Value': '${s.key}'},
        ));
        nodes.add(SceneNode.label(id: 'keylabel', position: Vec3(x, 3.6 + h + 0.5, 0), text: 'key', color: AppColors.primary, labelSize: 0.3));
      }
      nodes.add(SceneNode.label(
          id: 'counts', position: const Vec3(0, 6.2, 0), text: 'comparisons ${s.comparisons}   shifts ${s.shifts}', color: AppColors.textSecondary, labelSize: 0.34));
      return SceneSpec(nodes: nodes, camera: const CameraHint(yaw: -0.2, pitch: 0.5));
    },
  );
}

/// A stable id per value occurrence so equal values still glide as separate objects.
int _occurrence(List<int> input, List<int?> cells, int idx) {
  var k = 0;
  for (var i = 0; i < idx; i++) {
    if (cells[i] == cells[idx]) k++;
  }
  return k;
}
