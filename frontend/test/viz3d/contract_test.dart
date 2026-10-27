import 'package:byte_battle/features/learning/viz3d/contract/viz_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart';

void main() {
  group('ReducerTimeline', () {
    test('has one more position than events and starts in the initial state', () {
      final t = counterTimeline(steps: 3);
      expect(t.length, 4);
      expect(t.stateAt(0).n, 0);
      expect(t.frameAt(0).explanation.text, 'c is 0');
    });

    test('is deterministic: the same position always yields the same frame', () {
      final t = counterTimeline(steps: 5);
      for (var i = 0; i < t.length; i++) {
        expect(t.frameAt(i).explanation.text, t.frameAt(i).explanation.text);
      }
      final again = counterTimeline(steps: 5);
      for (var i = 0; i < t.length; i++) {
        expect(again.frameAt(i).explanation.text, t.frameAt(i).explanation.text);
        expect(again.frameAt(i).scene.nodes.single.position, t.frameAt(i).scene.nodes.single.position);
      }
    });

    test('seeking forwards, backwards and at random reconstructs the same state as walking in order', () {
      final t = counterTimeline(steps: 6);
      final walked = [for (var i = 0; i < t.length; i++) t.stateAt(i).n];
      for (final p in [6, 0, 3, 5, 1, 4, 2, 6, 6, 0]) {
        expect(t.stateAt(p).n, walked[p], reason: 'position $p');
        expect(t.frameAt(p).scene.nodes.single.label, '${walked[p]}');
      }
    });

    test('rejects positions outside the timeline instead of clamping silently', () {
      final t = counterTimeline();
      expect(() => t.frameAt(-1), throwsRangeError);
      expect(() => t.frameAt(t.length), throwsRangeError);
    });

    test('reports its markers and checks the declared outcome from the final state', () {
      final t = counterTimeline(steps: 3);
      expect(t.markers, {3});
      expect(t.outcome!.matches, isTrue);
      expect(t.outcome!.actual, '3');
    });

    test('computes bounds that enclose every frame', () {
      final t = counterTimeline(steps: 4);
      final b = t.bounds;
      expect(b.min.x, lessThanOrEqualTo(-0.5));
      expect(b.max.x, greaterThanOrEqualTo(4.5));
    });
  });

  group('VizLesson', () {
    test('builds the first variant when asked for an unknown one, and applies input overrides', () {
      final l = counterLesson(variants: const [
        VizVariant('a', 'A'),
        VizVariant('b', 'B')
      ], params: const [
        VizParam('steps', 'Steps', [VizChoice('2', '2'), VizChoice('5', '5')], '2')
      ]);
      expect(l.build(variant: 'nope').length, 3);
      expect(l.build(variant: 'b', overrides: {'steps': '5'}).length, 6);
      expect(l.build(variant: 'b').frameAt(1).explanation.text, startsWith('counter/b'));
    });
  });
}
