import 'dart:ui';
import '../../../../../app/theme/app_colors.dart';
import '../../contract/viz_contract.dart';
import '../../render/scene_spec.dart';
import '../scene_kit.dart';
import '../viz_palette.dart';

const kBinarySearchConceptId = '00000000-0000-0000-0000-000000001008';

/// The sorted list every run searches. Fixed so the learner varies one thing: the target.
const kBinarySearchData = [3, 8, 12, 17, 21, 26, 30, 35, 41, 47, 52, 58, 63, 71, 88];

const _code = [
  'int lo = 0, hi = n - 1;',
  'while (lo <= hi) {',
  '  int mid = (lo + hi) / 2;',
  '  if (a[mid] == t) return mid;',
  '  if (a[mid] < t) lo = mid + 1;',
  '  else hi = mid - 1;',
  '}',
  'return -1;',
];

enum BsKind { probe, goRight, goLeft, found, missing }

/// One thing the algorithm did. The list of events is produced by running the real algorithm on the chosen target.
class BsEvent {
  final BsKind kind;
  final int lo;
  final int hi;
  final int mid;
  const BsEvent(this.kind, this.lo, this.hi, this.mid);
}

/// Domain state: the live search interval and what has been ruled out.
class BsState {
  final int lo;
  final int hi;
  final int? mid;
  final int? foundAt;
  final bool missing;
  final int probes;
  final BsEvent? last;
  const BsState({required this.lo, required this.hi, this.mid, this.foundAt, this.missing = false, this.probes = 0, this.last});
}

/// Runs binary search for [target] over [a] and records every decision. Pure and deterministic.
List<BsEvent> binarySearchEvents(List<int> a, int target) {
  final out = <BsEvent>[];
  var lo = 0, hi = a.length - 1;
  while (lo <= hi) {
    final mid = (lo + hi) ~/ 2;
    out.add(BsEvent(BsKind.probe, lo, hi, mid));
    if (a[mid] == target) {
      out.add(BsEvent(BsKind.found, lo, hi, mid));
      return out;
    }
    if (a[mid] < target) {
      out.add(BsEvent(BsKind.goRight, lo, hi, mid));
      lo = mid + 1;
    } else {
      out.add(BsEvent(BsKind.goLeft, lo, hi, mid));
      hi = mid - 1;
    }
  }
  out.add(BsEvent(BsKind.missing, lo, hi, -1));
  return out;
}

VizLesson binarySearchLesson({String conceptId = kBinarySearchConceptId, String? topicId}) {
  final data = kBinarySearchData;
  final targets = [3, 30, 63, 88, 50, 1];
  return VizLesson(
    id: 'binary-search/$conceptId',
    conceptId: conceptId,
    topicId: topicId,
    category: VizCategory.algorithms,
    title: 'Binary search on a sorted list',
    summary: 'Pick a target and watch the search interval shrink.',
    params: [
      VizParam(
          'target',
          'Target',
          [
            for (final t in targets) VizChoice('$t', data.contains(t) ? '$t' : '$t (absent)'),
          ],
          '30'),
    ],
    interactions: const {VizInteraction.orbit, VizInteraction.zoom, VizInteraction.select, VizInteraction.replay},
    builder: (variant, params) => _timeline(data, int.tryParse(params['target'] ?? '') ?? 30),
  );
}

VizTimeline _timeline(List<int> a, int target) {
  final events = binarySearchEvents(a, target);
  final expectedIndex = a.indexOf(target); // an independent check: plain linear scan
  final n = a.length;
  final maxV = a.last;

  BsState reduce(BsState s, BsEvent e) {
    switch (e.kind) {
      case BsKind.probe:
        return BsState(lo: e.lo, hi: e.hi, mid: e.mid, probes: s.probes + 1, last: e);
      case BsKind.goRight:
        return BsState(lo: e.mid + 1, hi: e.hi, mid: e.mid, probes: s.probes, last: e);
      case BsKind.goLeft:
        return BsState(lo: e.lo, hi: e.mid - 1, mid: e.mid, probes: s.probes, last: e);
      case BsKind.found:
        return BsState(lo: e.lo, hi: e.hi, mid: e.mid, foundAt: e.mid, probes: s.probes, last: e);
      case BsKind.missing:
        return BsState(lo: e.lo, hi: e.hi, missing: true, probes: s.probes, last: e);
    }
  }

  return ReducerTimeline<BsState, BsEvent>(
    initial: BsState(lo: 0, hi: n - 1),
    events: events,
    reduce: reduce,
    code: _code,
    cameraHint: const CameraHint(yaw: -0.2, pitch: 0.5),
    isMarker: (s, e, p) => e != null && (e.kind == BsKind.found || e.kind == BsKind.missing),
    outcome: (fin) => VizOutcome(
      label: 'index of $target',
      expected: '$expectedIndex',
      actual: fin.foundAt?.toString() ?? '-1',
      meaning: fin.foundAt != null
          ? 'Found after ${fin.probes} look${fin.probes == 1 ? '' : 's'} instead of up to $n.'
          : 'The interval emptied, so $target is not in the list (${fin.probes} looks).',
    ),
    explain: (s, e, p) {
      if (e == null) {
        return VizExplanation('The list is sorted and we want $target. Instead of checking every item, we keep cutting the interval in half.',
            codeLines: const [0], variables: {'lo': '${s.lo}', 'hi': '${s.hi}', 'target': '$target'});
      }
      final vars = {
        'lo': '${s.lo}',
        'hi': '${s.hi}',
        if (s.mid != null) 'mid': '${s.mid}',
        if (s.mid != null) 'a[mid]': '${a[s.mid!]}',
        'target': '$target',
        'looks': '${s.probes}'
      };
      switch (e.kind) {
        case BsKind.probe:
          return VizExplanation('Look at the middle of indexes ${e.lo} to ${e.hi}: index ${e.mid} holds ${a[e.mid]}.',
              note: 'mid = (${e.lo} + ${e.hi}) / 2 = ${e.mid}', codeLines: const [1, 2], variables: vars);
        case BsKind.goRight:
          return VizExplanation('${a[e.mid]} is smaller than $target and the list is sorted, so $target cannot be at indexes ${e.lo} to ${e.mid}. Throw that half away.',
              note: 'a[${e.mid}] = ${a[e.mid]} < $target  ->  lo = ${e.mid + 1}', codeLines: const [4], variables: vars);
        case BsKind.goLeft:
          return VizExplanation('${a[e.mid]} is bigger than $target, so $target cannot be at indexes ${e.mid} to ${e.hi}. Throw that half away.',
              note: 'a[${e.mid}] = ${a[e.mid]} > $target  ->  hi = ${e.mid - 1}', codeLines: const [5], variables: vars);
        case BsKind.found:
          return VizExplanation('Found it: index ${e.mid} holds $target, after ${s.probes} look${s.probes == 1 ? '' : 's'}.',
              note: 'a[${e.mid}] == $target', codeLines: const [3], variables: vars, output: ['return ${e.mid}']);
        case BsKind.missing:
          return VizExplanation('lo passed hi, so nothing is left to search. $target is not in the list.',
              note: 'lo = ${s.lo} > hi = ${s.hi}', codeLines: const [7], variables: vars, output: const ['return -1']);
      }
    },
    scene: (s, p) {
      final nodes = <SceneNode>[];
      const spacing = 1.15;
      final searching = s.foundAt == null && !s.missing;
      for (var i = 0; i < n; i++) {
        final inside = i >= s.lo && i <= s.hi;
        final isMid = s.mid == i && searching && s.last?.kind == BsKind.probe;
        final isFound = s.foundAt == i;
        final h = SceneKit.barHeight(a[i], maxV);
        String state = 'idle';
        if (isFound) {
          state = 'found';
        } else if (isMid) {
          state = 'cur';
        } else if (!inside || s.missing) {
          state = 'dim';
        }
        final eliminated = !inside && !isFound;
        nodes.add(SceneNode(
          id: 'cell:$i',
          shape: SceneShape.box,
          position: Vec3(SceneKit.rowX(i, n, spacing), h / 2, 0),
          size: Vec3(0.92, h, 0.92),
          color: VizPalette.state(state),
          glow: VizPalette.glow(state),
          opacity: eliminated ? 0.5 : 1,
          label: '${a[i]}',
          labelSize: 0.3,
          selectable: true,
          inspect: {
            'What': 'List item',
            'Index': '$i',
            'Value': '${a[i]}',
            'Compared to $target': a[i] == target ? 'equal' : (a[i] < target ? 'smaller' : 'bigger'),
            'Status': isFound ? 'the answer' : (eliminated ? 'ruled out' : (inside ? 'still possible' : '')),
          },
        ));
        nodes.add(SceneNode.label(id: 'idx:$i', position: Vec3(SceneKit.rowX(i, n, spacing), 0.02, 0.85), text: '$i', color: AppColors.textHint, labelSize: 0.24));
      }
      if (s.hi >= s.lo) {
        nodes.add(SceneKit.span(id: 'interval', from: s.lo, to: s.hi, n: n, spacing: spacing, height: 3.5, centre: const Vec3(0, 0, 0), color: AppColors.accentCyan));
      }
      // Pointer markers: lo and hi stand on the ends of the live interval, mid on the probe.
      void marker(String id, int? idx, Color color, double dz) {
        if (idx == null || idx < 0 || idx >= n) return;
        nodes.add(SceneNode(
          id: 'ptr:$id',
          shape: SceneShape.sphere,
          position: Vec3(SceneKit.rowX(idx, n, spacing), 0.35, 1.5 + dz),
          size: const Vec3(0.62, 0.62, 0.62),
          color: color,
          glow: 0.8,
          label: id,
          labelSize: 0.24,
          labelColor: AppColors.onAccent,
        ));
      }

      if (s.hi >= s.lo) {
        marker('lo', s.lo, AppColors.accentCyan, 0);
        marker('hi', s.hi, AppColors.orchid, 0);
      }
      if (searching && s.mid != null) marker('mid', s.mid, AppColors.primary, 0.9);
      nodes.add(SceneNode.label(id: 'target', position: const Vec3(0, 4.4, 0), text: 'looking for $target', color: AppColors.xp, labelSize: 0.5));
      nodes.add(SceneNode.label(
          id: 'looks', position: Vec3(0, 3.85, 0), text: 'looks so far: ${s.probes}   (a full scan could take $n)', color: AppColors.textSecondary, labelSize: 0.3));
      return SceneSpec(nodes: nodes, camera: const CameraHint(yaw: -0.2, pitch: 0.5));
    },
  );
}
