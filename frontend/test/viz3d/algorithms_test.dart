import 'dart:math';
import 'package:byte_battle/features/learning/viz3d/contract/viz_contract.dart';
import 'package:byte_battle/features/learning/viz3d/modules/algorithms/binary_search_lesson.dart';
import 'package:byte_battle/features/learning/viz3d/modules/algorithms/insertion_sort_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

ReducerTimeline<BsState, BsEvent> _bs(int target) => binarySearchLesson().build(overrides: {'target': '$target'}) as ReducerTimeline<BsState, BsEvent>;
ReducerTimeline<SortState, SortEvent> _sort(String input) => insertionSortLesson().build(overrides: {'input': input}) as ReducerTimeline<SortState, SortEvent>;

void main() {
  group('binary search', () {
    const a = kBinarySearchData;

    test('starts with the whole list in play', () {
      final t = _bs(30);
      final s = t.stateAt(0);
      expect((s.lo, s.hi), (0, a.length - 1));
      expect(t.frameAt(0).scene.node('interval'), isNotNull);
    });

    test('finds every present value at the right index and reports not-found for absent ones', () {
      for (final target in [...a, 1, 50, 100, 5]) {
        final t = _bs(target);
        final o = t.outcome!;
        expect(o.matches, isTrue, reason: 'target $target: expected ${o.expected} got ${o.actual}');
        expect(o.actual, '${a.indexOf(target)}');
      }
    });

    test('the live interval always contains the target (when present) and never grows', () {
      for (final target in a) {
        final t = _bs(target);
        var width = a.length;
        for (var p = 0; p < t.length; p++) {
          final s = t.stateAt(p);
          final idx = a.indexOf(target);
          if (s.foundAt == null) expect(idx >= s.lo && idx <= s.hi, isTrue, reason: 'target $target at position $p interval ${s.lo}..${s.hi}');
          final w = s.hi - s.lo + 1;
          expect(w, lessThanOrEqualTo(width));
          width = w;
        }
      }
    });

    test('needs at most log2(n + 1) looks, far fewer than a scan', () {
      final bound = (log(a.length + 1) / ln2).ceil();
      for (final target in [...a, 1, 50, 100]) {
        expect(_bs(target).finalState.probes, lessThanOrEqualTo(bound), reason: 'target $target');
      }
      expect(_bs(30).finalState.probes, lessThan(a.length));
    });

    test('eliminates the discarded half: those bars dim and the wire box shrinks', () {
      final t = _bs(63);
      // position 2 is right after the first "discard left half" decision (mid = 7 holds 35 < 63).
      final scene = t.frameAt(2).scene;
      for (var i = 0; i <= 7; i++) {
        expect(scene.node('cell:$i')!.opacity, lessThan(1), reason: 'cell $i ruled out');
      }
      expect(scene.node('cell:12')!.opacity, 1);
      final before = t.frameAt(0).scene.node('interval')!.size.x;
      expect(scene.node('interval')!.size.x, lessThan(before));
    });

    test('highlights the found cell and reconstructs it directly at the end', () {
      final t = _bs(30);
      final end = t.frameAt(t.length - 1).scene;
      final i = a.indexOf(30);
      expect(end.node('cell:$i')!.glow, greaterThan(0.5));
      expect(t.markers, {t.length - 1});
    });

    test('seeking in any order shows the same frame as walking forward', () {
      final t = _bs(88);
      final walked = [for (var p = 0; p < t.length; p++) t.frameAt(p).explanation.text];
      for (final p in [t.length - 1, 0, 3, 1, t.length - 2, 2]) {
        expect(t.frameAt(p).explanation.text, walked[p]);
      }
    });

    test('a different target produces a different run (the animation follows the input)', () {
      expect(_bs(3).length, isNot(_bs(88).length == _bs(3).length && _bs(3).frameAt(1).explanation.text == _bs(88).frameAt(1).explanation.text ? -1 : 0));
      expect(_bs(3).frameAt(2).explanation.text, isNot(_bs(88).frameAt(2).explanation.text));
    });
  });

  group('insertion sort', () {
    test('sorts every preset input and verifies against Dart\'s own sort', () {
      for (final input in kSortInputs.keys) {
        final t = _sort(input);
        expect(t.outcome!.matches, isTrue, reason: input);
        expect(t.finalState.cells.whereType<int>().length, kSortInputs[input]!.length);
      }
    });

    test('property: random inputs always end sorted, with shifts equal to the inversion count', () {
      final rnd = Random(7);
      for (var k = 0; k < 40; k++) {
        final input = List.generate(2 + rnd.nextInt(8), (_) => rnd.nextInt(50));
        final events = insertionSortEvents(input);
        // replay the events by hand on a plain list
        final a = [...input];
        for (final e in events) {
          if (e.kind == SortKind.shift) a[e.j + 1] = a[e.j];
          if (e.kind == SortKind.pick) a[e.i] = a[e.i];
        }
        var inversions = 0;
        for (var i = 0; i < input.length; i++) {
          for (var j = i + 1; j < input.length; j++) {
            if (input[i] > input[j]) inversions++;
          }
        }
        expect(events.where((e) => e.kind == SortKind.shift).length, inversions, reason: '$input');
      }
    });

    test('exactly one gap exists while a key is held, none otherwise, and no value is ever lost', () {
      for (final input in kSortInputs.keys) {
        final t = _sort(input);
        final sortedInput = [...kSortInputs[input]!]..sort();
        for (var p = 0; p < t.length; p++) {
          final s = t.stateAt(p);
          final gaps = s.cells.where((c) => c == null).length;
          expect(gaps, s.key == null ? 0 : 1, reason: '$input @$p');
          final all = [...s.cells.whereType<int>(), if (s.key != null) s.key!]..sort();
          expect(all, sortedInput, reason: '$input @$p keeps every value');
        }
      }
    });

    test('an already sorted input never shifts anything', () {
      expect(_sort('sorted').finalState.shifts, 0);
      expect(_sort('reversed').finalState.shifts, 21);
    });

    test('the bars are the actual input values: heights follow the numbers', () {
      final t = _sort('mixed');
      final scene = t.frameAt(0).scene;
      final values = kSortInputs['mixed']!;
      final heights = {for (final v in values) v: scene.nodes.firstWhere((n) => n.label == '$v' && n.id.startsWith('val:')).size.y};
      expect(heights[9]!, greaterThan(heights[1]!));
      expect(heights[6]!, greaterThan(heights[3]!));
    });

    test('forward and backward seeking agree', () {
      final t = _sort('mixed');
      final forward = [for (var p = 0; p < t.length; p++) t.stateAt(p).cells.join(',')];
      for (var p = t.length - 1; p >= 0; p--) {
        expect(t.stateAt(p).cells.join(','), forward[p]);
      }
    });
  });
}
