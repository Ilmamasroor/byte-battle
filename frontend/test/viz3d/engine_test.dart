import 'package:byte_battle/features/learning/viz3d/contract/viz_contract.dart';
import 'package:byte_battle/features/learning/viz3d/engine/playback_controller.dart';
import 'package:byte_battle/features/learning/viz3d/engine/viz_session.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart';

void main() {
  group('VizPlaybackController', () {
    testWidgets('plays to the end on its own, then stops and reports it once', (t) async {
      var finished = 0;
      final c = VizPlaybackController(length: 4, baseInterval: const Duration(milliseconds: 100), onFinished: () => finished++);
      c.play();
      expect(c.playing, isTrue);
      await t.pump(const Duration(milliseconds: 100));
      expect(c.position, 1);
      await t.pump(const Duration(milliseconds: 100));
      expect(c.position, 2);
      await t.pump(const Duration(milliseconds: 100));
      expect(c.position, 3);
      expect(c.playing, isFalse);
      expect(c.atEnd, isTrue);
      expect(finished, 1);
      await t.pump(const Duration(seconds: 1));
      expect(c.position, 3);
      expect(finished, 1);
      c.dispose();
    });

    testWidgets('pause stops the timer; speed changes the pace from the next step', (t) async {
      final c = VizPlaybackController(length: 10, baseInterval: const Duration(milliseconds: 400));
      c.play();
      await t.pump(const Duration(milliseconds: 400));
      expect(c.position, 1);
      c.pause();
      await t.pump(const Duration(seconds: 2));
      expect(c.position, 1);
      c.setSpeed(2);
      expect(c.interval, const Duration(milliseconds: 200));
      c.play();
      await t.pump(const Duration(milliseconds: 200));
      expect(c.position, 2);
      c.dispose();
    });

    testWidgets('playing from the end restarts from the beginning', (t) async {
      final c = VizPlaybackController(length: 3, baseInterval: const Duration(milliseconds: 50));
      c.seek(2);
      c.play();
      expect(c.position, 0);
      expect(c.playing, isTrue);
      c.dispose();
    });

    test('seek clamps, next and previous stop at the ends, reset returns to the start', () {
      final c = VizPlaybackController(length: 5);
      c.seek(99);
      expect(c.position, 4);
      c.next();
      expect(c.position, 4);
      c.seek(-5);
      expect(c.position, 0);
      c.previous();
      expect(c.position, 0);
      c.seek(3);
      c.reset();
      expect(c.position, 0);
      expect(c.playing, isFalse);
      c.dispose();
    });

    testWidgets('stepping manually while playing pauses playback', (t) async {
      final c = VizPlaybackController(length: 6, baseInterval: const Duration(milliseconds: 100));
      c.play();
      c.next();
      expect(c.playing, isFalse);
      await t.pump(const Duration(seconds: 1));
      expect(c.position, 1);
      c.dispose();
    });

    test('configure resets position and playback for a new timeline', () {
      final c = VizPlaybackController(length: 5);
      c.seek(4);
      c.configure(2);
      expect(c.length, 2);
      expect(c.position, 0);
      expect(c.playing, isFalse);
      c.dispose();
    });

    test('replay bumps the nonce without moving', () {
      final c = VizPlaybackController(length: 3);
      c.seek(1);
      final n = c.replayNonce;
      c.replay();
      expect(c.replayNonce, n + 1);
      expect(c.position, 1);
      c.dispose();
    });

    testWidgets('dispose cancels the pending timer and silences listeners', (t) async {
      final c = VizPlaybackController(length: 10, baseInterval: const Duration(milliseconds: 100));
      var notified = 0;
      c.addListener(() => notified++);
      c.play();
      final before = notified;
      c.dispose();
      await t.pump(const Duration(seconds: 1)); // would throw "timer still pending" if the timer survived
      expect(notified, before);
    });

    test('a single-position timeline cannot play', () {
      final c = VizPlaybackController(length: 1);
      c.play();
      expect(c.playing, isFalse);
      c.dispose();
    });
  });

  group('VizPlaybackController advance gate', () {
    VizPlaybackController make() => VizPlaybackController(length: 6, baseInterval: const Duration(milliseconds: 100));

    testWidgets('holds the next step until the gate completes, never less than the normal dwell', (t) async {
      final c = make();
      final gates = <int, Completer<void>>{};
      c.advanceGate = (p) => (gates[p] = Completer<void>()).future;
      c.play();
      await t.pump(const Duration(milliseconds: 99));
      expect(gates, isEmpty, reason: 'the gate is asked only after the dwell');
      await t.pump(const Duration(milliseconds: 5));
      expect(gates.keys, [0]);
      await t.pump(const Duration(seconds: 3));
      expect(c.position, 0);
      gates[0]!.complete();
      await t.pump();
      expect(c.position, 1);
      expect(c.autoAdvances, 1);
      c.dispose();
    });

    testWidgets('a pause while waiting cancels that step: the late completion neither moves nor double-steps', (t) async {
      final c = make();
      final gates = <Completer<void>>[];
      c.advanceGate = (p) => (gates..add(Completer<void>())).last.future;
      c.play();
      await t.pump(const Duration(milliseconds: 110));
      expect(gates, hasLength(1));
      c.pause();
      c.play(); // resumed before the first gate ever completes
      gates.first.complete();
      await t.pump();
      expect(c.position, 0, reason: 'the cancelled gate must not step');
      await t.pump(const Duration(milliseconds: 110));
      expect(gates, hasLength(2));
      gates.last.complete();
      await t.pump();
      expect(c.position, 1, reason: 'exactly one step per dwell');
      c.dispose();
    });

    testWidgets('a seek while waiting restarts the dwell from the new position', (t) async {
      final c = make();
      final gates = <int, Completer<void>>{};
      c.advanceGate = (p) => (gates[p] = Completer<void>()).future;
      c.play();
      await t.pump(const Duration(milliseconds: 110));
      c.seek(3);
      gates[0]!.complete();
      await t.pump();
      expect(c.position, 3);
      await t.pump(const Duration(milliseconds: 110));
      expect(gates.keys, containsAll([0, 3]));
      gates[3]!.complete();
      await t.pump();
      expect(c.position, 4);
      c.dispose();
    });

    testWidgets('manual steps do not count as automatic advances', (t) async {
      final c = make();
      c.next();
      c.seek(4);
      c.previous();
      expect(c.autoAdvances, 0);
      c.dispose();
    });

    testWidgets('reconfiguring bumps the generation even when the position stays at 0', (t) async {
      final c = make();
      final g = c.generation;
      c.configure(8);
      expect(c.generation, g + 1);
      expect(c.position, 0);
      c.dispose();
    });
  });

  group('VizSession', () {
    test('switching lessons drops position, selection, guess and variant from the old lesson', () {
      final s = VizSession(lessons: [
        counterLesson(id: 'one', steps: 4, variants: const [VizVariant('a', 'A'), VizVariant('b', 'B')]),
        counterLesson(id: 'two', steps: 2),
      ]);
      s.setVariant('b');
      s.controller.seek(3);
      s.select('box');
      s.answerPrediction(1);
      expect(s.timeline.length, 5);

      s.selectLesson(1);
      expect(s.lesson.id, 'two');
      expect(s.variantId, 'a');
      expect(s.controller.position, 0);
      expect(s.controller.length, 3);
      expect(s.selectedId, isNull);
      expect(s.guess, isNull);
      expect(s.frame.explanation.text, 'two/a is 0');
      s.dispose();
    });

    test('changing the variant or an input rebuilds the timeline and resets playback', () {
      final s = VizSession(lessons: [
        counterLesson(variants: const [
          VizVariant('a', 'A'),
          VizVariant('b', 'B')
        ], params: const [
          VizParam('steps', 'Steps', [VizChoice('3', '3'), VizChoice('6', '6')], '3')
        ]),
      ]);
      s.controller.seek(2);
      s.select('box');
      s.setParam('steps', '6');
      expect(s.controller.length, 7);
      expect(s.controller.position, 0);
      expect(s.selectedId, isNull);
      s.controller.seek(4);
      s.setVariant('b');
      expect(s.controller.position, 0);
      expect(s.frame.explanation.text, startsWith('counter/b'));
      s.dispose();
    });

    test('ignores unknown variants, params and lesson indexes', () {
      final s = VizSession(lessons: [counterLesson()]);
      final tl = s.timeline;
      s.setVariant('zzz');
      s.setParam('zzz', '1');
      s.selectLesson(7);
      expect(identical(s.timeline, tl), isTrue);
      s.dispose();
    });

    test('reuses a built timeline when the learner returns to a choice', () {
      final s = VizSession(lessons: [
        counterLesson(variants: const [VizVariant('a', 'A'), VizVariant('b', 'B')])
      ]);
      final a = s.timeline;
      s.setVariant('b');
      s.setVariant('a');
      expect(identical(s.timeline, a), isTrue);
      s.dispose();
    });

    test('a render failure keeps the learner on the flat view and stops playback; retrying re-enables 3D', () {
      final s = VizSession(lessons: [counterLesson()]);
      expect(s.show3D, isTrue);
      s.controller.play();
      s.reportFailure(StateError('no gpu'));
      expect(s.failure, isNotNull);
      expect(s.show3D, isFalse);
      expect(s.controller.playing, isFalse);
      s.set3D(true);
      expect(s.failure, isNull);
      expect(s.show3D, isTrue);
      s.dispose();
    });

    test('a lesson whose builder throws yields a one-frame explanation and no 3D', () {
      final s = VizSession(lessons: [
        VizLesson(id: 'bad', conceptId: 'x', category: VizCategory.algorithms, title: 'Bad', builder: (v, p) => throw StateError('cannot build')),
      ]);
      expect(s.show3D, isFalse);
      expect(s.timeline.length, 1);
      expect(s.frame.explanation.text, contains('cannot build'));
      s.dispose();
    });

    test('outcomes of every variant are available for comparison', () {
      final s = VizSession(lessons: [
        counterLesson(variants: const [VizVariant('a', 'A'), VizVariant('b', 'B')])
      ]);
      expect(s.outcomeOf('a')!.matches, isTrue);
      expect(s.outcomeOf('b')!.matches, isTrue);
      s.dispose();
    });

    test('dispose is safe to repeat and stops notifying', () {
      final s = VizSession(lessons: [counterLesson()]);
      s.dispose();
      expect(() => s.select('x'), returnsNormally);
    });
  });
}
