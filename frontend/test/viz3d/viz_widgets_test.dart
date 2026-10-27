import 'package:byte_battle/app/theme/app_theme.dart';
import 'package:byte_battle/features/learning/viz3d/contract/viz_contract.dart';
import 'package:byte_battle/features/learning/viz3d/engine/viz_session.dart';
import 'package:byte_battle/features/learning/viz3d/render/scene_painter.dart';
import 'package:byte_battle/features/learning/viz3d/render/viz_viewport.dart';
import 'package:byte_battle/features/learning/viz3d/ui/viz_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart';

Widget _app(Widget child, {bool reducedMotion = false}) => MaterialApp(
      theme: AppTheme.darkTheme,
      builder: (context, c) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion), child: c!),
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    );

Future<void> _pump(WidgetTester t, Widget w, {bool reducedMotion = false}) async {
  t.view.physicalSize = const Size(390 * 2, 1800 * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(_app(w, reducedMotion: reducedMotion));
  await t.pump(const Duration(milliseconds: 50));
}

ScenePainter _painter(WidgetTester t) => t.widget<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is ScenePainter)).painter! as ScenePainter;

/// A frame to start the animation, then enough time to finish it.
Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 900));
}

Finder get _next => find.byIcon(Icons.skip_next_rounded);
Finder get _prev => find.byIcon(Icons.skip_previous_rounded);

VizSession _session({List<VizLesson>? lessons}) => VizSession(lessons: lessons ?? [counterLesson(steps: 4)]);

void main() {
  group('shell', () {
    testWidgets('renders the 3D viewport, the controls and the explanation for the first position', (t) async {
      final s = _session();
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      expect(find.byType(VizViewport), findsOneWidget);
      expect(find.text('counter/a is 0'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(_painter(t).scene.nodes.single.label, '0');
    });

    testWidgets('next, previous, restart and the scrubber drive one shared position', (t) async {
      final s = _session();
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      await t.tap(_next);
      await _settle(t);
      expect(s.controller.position, 1);
      expect(find.text('counter/a is 1'), findsOneWidget);
      await t.tap(_next);
      await t.tap(_next);
      await _settle(t);
      expect(find.text('counter/a is 3'), findsOneWidget);
      await t.tap(_prev);
      await _settle(t);
      expect(find.text('counter/a is 2'), findsOneWidget);
      t.widget<Slider>(find.byType(Slider)).onChanged!(4);
      await _settle(t);
      expect(s.controller.position, 4);
      expect(_painter(t).scene.nodes.single.label, '4', reason: 'the scrubber jumps straight to the reconstructed frame');
      await t.tap(find.byIcon(Icons.restart_alt_rounded));
      await _settle(t);
      expect(s.controller.position, 0);
      expect(find.text('counter/a is 0'), findsOneWidget);
    });

    testWidgets('play advances on its own and pause stops it', (t) async {
      final s = _session();
      addTearDown(s.dispose);
      s.controller.baseInterval = const Duration(milliseconds: 300);
      await _pump(t, VizShell(session: s));
      await t.tap(find.byIcon(Icons.play_arrow_rounded));
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 300));
      expect(s.controller.position, 2);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      await t.tap(find.byIcon(Icons.pause_rounded));
      await t.pump(const Duration(seconds: 2));
      expect(s.controller.position, 2);
    });

    testWidgets('variant and input chips rebuild the run from the start', (t) async {
      final s = _session(lessons: [
        counterLesson(variants: const [
          VizVariant('a', 'Variant A'),
          VizVariant('b', 'Variant B')
        ], params: const [
          VizParam('steps', 'Steps', [VizChoice('2', 'Two'), VizChoice('5', 'Five')], '2')
        ]),
      ]);
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      expect(s.controller.length, 3);
      await t.tap(find.text('Five'));
      await t.pump(const Duration(milliseconds: 100));
      expect(s.controller.length, 6);
      s.controller.seek(3);
      await _settle(t);
      await t.tap(find.text('Variant B'));
      await t.pump(const Duration(milliseconds: 100));
      expect(s.controller.position, 0);
      expect(find.text('counter/b is 0'), findsOneWidget);
    });

    testWidgets('switching lessons shows the new lesson with nothing left over from the old one', (t) async {
      final s = _session(lessons: [
        counterLesson(id: 'sim', steps: 5, params: const [
          VizParam('steps', 'Steps', [VizChoice('5', 'Five')], '5')
        ]),
        counterLesson(id: 'walk', steps: 2),
      ]);
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      s.controller.seek(4);
      s.select('box');
      await _settle(t);
      expect(find.text('INSPECTING'), findsOneWidget);
      await t.tap(find.text('Walkthrough'));
      await _settle(t);
      expect(find.text('walk/a is 0'), findsOneWidget);
      expect(find.text('INSPECTING'), findsNothing);
      expect(s.controller.length, 3);
      expect(_painter(t).scene.nodes.single.label, '0');
      expect(_painter(t).selectedId, isNull);
    });

    testWidgets('tapping an object inspects it and highlights it; tapping again clears the selection', (t) async {
      final s = _session();
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      s.controller.seek(2); // the box is at the middle of the fitted view here
      await _settle(t);
      final centre = t.getCenter(find.byType(VizViewport));
      await t.tapAt(centre);
      await t.pump(const Duration(milliseconds: 100));
      expect(s.selectedId, 'box');
      expect(find.text('INSPECTING'), findsOneWidget);
      expect(find.textContaining('Value', findRichText: true), findsWidgets);
      expect(_painter(t).selectedId, 'box');
      await t.tapAt(centre);
      await t.pump(const Duration(milliseconds: 100));
      expect(s.selectedId, isNull);
      expect(find.text('INSPECTING'), findsNothing);
    });

    testWidgets('orbiting and zooming move the camera only; seeking never moves it; reset brings it home', (t) async {
      final s = _session();
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      final home = _painter(t).camera;
      final yaw0 = home.yaw, dist0 = home.distance;

      await t.drag(find.byType(VizViewport), const Offset(80, 30));
      await t.pump(const Duration(milliseconds: 50));
      expect(_painter(t).camera.yaw, isNot(closeTo(yaw0, 1e-6)));
      expect(s.controller.position, 0, reason: 'camera movement does not touch playback');

      final moved = _painter(t).camera.yaw;
      await t.tap(_next);
      await _settle(t);
      expect(_painter(t).camera.yaw, moved, reason: 'playback does not touch the camera');

      await t.tap(find.byIcon(Icons.add_rounded));
      await t.pump(const Duration(milliseconds: 50));
      expect(_painter(t).camera.distance, lessThan(dist0));

      await t.tap(find.byIcon(Icons.center_focus_strong_rounded));
      await _settle(t);
      expect(_painter(t).camera.yaw, closeTo(yaw0, 1e-6));
      expect(_painter(t).camera.distance, closeTo(dist0, 1e-6));
      expect(s.controller.position, 1);
    });

    testWidgets('replay re-animates the current step without moving', (t) async {
      final s = _session();
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      await t.tap(_next);
      await _settle(t);
      await t.tap(find.byIcon(Icons.replay_rounded));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(s.controller.position, 1);
      expect(t.hasRunningAnimations, isTrue);
      await t.pump(const Duration(milliseconds: 800));
    });

    testWidgets('shows the checked outcome at the end and every variant\'s result for comparison', (t) async {
      final lesson = VizLesson(
        id: 'cmp',
        conceptId: 'x',
        category: VizCategory.concurrency,
        title: 'Cmp',
        variants: const [VizVariant('bug', 'The bug'), VizVariant('fix', 'The fix')],
        interactions: const {VizInteraction.orbit, VizInteraction.compare},
        builder: (v, p) => ReducerTimeline<int, int>(
          initial: 0,
          events: const [1, 2],
          reduce: (s, e) => e,
          explain: (s, e, pos) => VizExplanation('n=$s'),
          scene: (s, p) => counterTimeline().frameAt(0).scene,
          outcome: (fin) => VizOutcome(label: 'total', expected: '2', actual: v == 'bug' ? '1' : '2', meaning: v == 'bug' ? 'An update was lost.' : 'All good.'),
        ),
      );
      final s = VizSession(lessons: [lesson]);
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      expect(find.textContaining('expected 2'), findsNothing, reason: 'no outcome before the run ends');
      s.controller.seek(2);
      await _settle(t);
      expect(find.text('total: expected 2, got 1'), findsOneWidget);
      expect(find.text('total: expected 2, got 2'), findsOneWidget, reason: 'the other variant is shown beside it');
    });

    testWidgets('asks the prediction first, then plays, then reveals whether the guess held', (t) async {
      final lesson = VizLesson(
        id: 'p',
        conceptId: 'x',
        category: VizCategory.algorithms,
        title: 'P',
        summary: 'Make a guess.',
        predict: const VizPrediction('How many?', ['One', 'Three'], 1, 'Because three.'),
        builder: (v, p) => counterTimeline(steps: 2),
      );
      final s = VizSession(lessons: [lesson]);
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      expect(find.text('How many?'), findsOneWidget);
      expect(find.byType(VizViewport), findsNothing);
      await t.tap(find.text('Three'));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(VizViewport), findsOneWidget);
      s.controller.seek(2);
      await _settle(t);
      expect(find.text('You called it.'), findsOneWidget);
      expect(find.text('Because three.'), findsOneWidget);
    });
  });

  group('fallbacks', () {
    testWidgets('a renderer failure swaps in the flat step list and keeps the explanation usable', (t) async {
      final lesson = VizLesson(id: 'boom', conceptId: 'x', category: VizCategory.algorithms, title: 'Boom', builder: (v, p) => ExplodingTimeline(failAt: 2));
      final s = VizSession(lessons: [lesson]);
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      expect(find.byType(VizViewport), findsOneWidget);
      s.controller.seek(2);
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 100));
      expect(s.failure, isNotNull);
      expect(s.show3D, isFalse);
      expect(find.byType(VizViewport), findsNothing);
      expect(find.textContaining('3D could not start'), findsOneWidget);
      expect(find.text('step 0 of an exploding lesson'), findsWidgets, reason: 'the whole trace is readable without 3D');
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget, reason: 'controls still work');
    });

    testWidgets('a lesson that cannot even be built shows its message, not an empty scene', (t) async {
      final s = VizSession(lessons: [VizLesson(id: 'bad', conceptId: 'x', category: VizCategory.algorithms, title: 'Bad', builder: (v, p) => throw StateError('no data'))]);
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      expect(find.byType(VizViewport), findsNothing);
      expect(find.textContaining('could not be built'), findsWidgets);
    });

    testWidgets('the learner can switch to the flat view and back', (t) async {
      final s = _session();
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      await t.tap(find.text('Flat view'));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(VizViewport), findsNothing);
      expect(find.text('counter/a is 0'), findsWidgets);
      await t.tap(find.text('3D view'));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(VizViewport), findsOneWidget);
    });

    testWidgets('a lesson\'s own 2D view is used as the flat fallback when it has one', (t) async {
      final lesson = VizLesson(
          id: 'flat', conceptId: 'x', category: VizCategory.algorithms, title: 'Flat', builder: (v, p) => counterTimeline(), flatBuilder: (c) => const Text('MY FLAT VIEW'));
      final s = VizSession(lessons: [lesson]);
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      s.set3D(false);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('MY FLAT VIEW'), findsOneWidget);
    });

    testWidgets('an unsupported concept says so plainly and offers the fallback underneath', (t) async {
      await _pump(t, const VizUnsupported(reason: 'There is no 3D visualization for this lesson yet.', fallback: Text('the old explanation')));
      expect(find.textContaining('no 3D visualization'), findsOneWidget);
      expect(find.text('the old explanation'), findsOneWidget);
    });
  });

  group('motion, accessibility and cleanup', () {
    testWidgets('with reduced motion a step change jumps instead of animating', (t) async {
      final s = _session();
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s), reducedMotion: true);
      await t.tap(_next);
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
      expect(_painter(t).scene.nodes.single.position.x, 1, reason: 'already at the new position on the very next frame');
    });

    testWidgets('with normal motion the same step glides over several frames', (t) async {
      final s = _session();
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      await t.tap(_next);
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));
      final x = _painter(t).scene.nodes.single.position.x;
      expect(x, inExclusiveRange(0, 1));
      await t.pump(const Duration(milliseconds: 800));
      expect(_painter(t).scene.nodes.single.position.x, 1);
    });

    testWidgets('the 3D view is described to screen readers with the current explanation', (t) async {
      final s = _session();
      addTearDown(s.dispose);
      final handle = t.ensureSemantics();
      await _pump(t, VizShell(session: s));
      expect(find.bySemanticsLabel(RegExp('3D visualization. counter/a is 0')), findsOneWidget);
      expect(find.bySemanticsLabel('Play'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('unmounting while playing leaves no timers, tickers or listeners behind', (t) async {
      final s = _session(lessons: [counterLesson(steps: 20)]);
      s.controller.baseInterval = const Duration(milliseconds: 100);
      await _pump(t, VizShell(session: s));
      await t.tap(find.byIcon(Icons.play_arrow_rounded));
      await t.pump(const Duration(milliseconds: 150));
      await t.pumpWidget(const SizedBox.shrink());
      s.dispose();
      await t.pump(const Duration(seconds: 2)); // a leaked timer or ticker fails the test here
      expect(t.hasRunningAnimations, isFalse);
    });

    testWidgets('replacing the timeline reloads the viewport instead of keeping the old scene', (t) async {
      final s = _session(lessons: [
        counterLesson(variants: const [VizVariant('a', 'A'), VizVariant('b', 'B')])
      ]);
      addTearDown(s.dispose);
      await _pump(t, VizShell(session: s));
      s.controller.seek(3);
      await _settle(t);
      expect(_painter(t).scene.nodes.single.label, '3');
      s.setVariant('b');
      await t.pump(const Duration(milliseconds: 100));
      expect(_painter(t).scene.nodes.single.label, '0');
    });
  });
}
