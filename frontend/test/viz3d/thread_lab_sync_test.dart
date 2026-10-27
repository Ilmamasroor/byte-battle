import 'dart:convert';
import 'dart:io';
import 'package:byte_battle/app/theme/app_theme.dart';
import 'package:byte_battle/core/models/backend_models.dart';
import 'package:byte_battle/core/voice/bit_voice.dart';
import 'package:byte_battle/core/voice/sound_cues.dart';
import 'package:byte_battle/features/learning/viz3d/engine/narration_controller.dart';
import 'package:byte_battle/features/learning/viz3d/engine/viz_session.dart';
import 'package:byte_battle/features/learning/viz3d/modules/concurrency/builtin_lost_update.dart';
import 'package:byte_battle/features/learning/viz3d/modules/concurrency/thread_lanes.dart';
import 'package:byte_battle/features/learning/viz3d/modules/concurrency/thread_schedule_lesson.dart';
import 'package:byte_battle/features/learning/viz3d/registry/viz_registry.dart';
import 'package:byte_battle/features/learning/viz3d/ui/explanation_panel.dart';
import 'package:byte_battle/features/learning/viz3d/ui/viz_controls.dart';
import 'package:byte_battle/features/learning/visualization/widgets/thread_lab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'narration_test.dart' show ControlledEngine, FakeSound;
import 'support.dart';

VisualizationModel _traced() {
  final f = jsonDecode(File('test/fixtures/lost_update_trace.json').readAsStringSync()) as Map<String, dynamic>;
  return VisualizationModel.fromJson({'title': 'Counter race', 'visualization': f}, code: f['code'] as String);
}

void main() {
  late ControlledEngine engine;
  late VizSession session;
  late NarrationController narration;

  Future<void> open(WidgetTester t, VisualizationModel model) async {
    SharedPreferences.setMockInitialValues({});
    engine = ControlledEngine()..autoFinish = true;
    BitVoice.instance
      ..engine = engine
      ..enabled = true
      ..available = true
      ..sfxEnabled = false;
    final lesson = VizRegistry.standard().resolve(VizSource(conceptId: raceId, simulation: model)).lessons.firstWhere(isThreadScheduleLesson);
    session = VizSession(lessons: [lesson], prefer3D: false);
    narration = NarrationController(
      playback: session.controller,
      textAt: (p) => session.frameAt(p).explanation.narration,
      cues: SoundCues(engine: FakeSound()),
    );
    t.view.physicalSize = const Size(430 * 2, 3200 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: ThreadLab(session: session, model: model, narration: narration))),
    ));
    await t.pump(const Duration(milliseconds: 300));
  }

  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox.shrink());
    narration.dispose();
    session.dispose();
  }

  Future<void> goTo(WidgetTester t, int p) async {
    session.controller.seek(p);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }

  /// Everything on screen for position [p] must describe that one event.
  void expectAgreement(WidgetTester t, int p) {
    final last = session.controller.length - 1;
    final frame = session.frameAt(p);
    final text = t.widget<Text>(find.descendant(of: find.byKey(const Key('caption')), matching: find.byType(Text)).first);
    expect(text.data, frame.explanation.narration, reason: 'caption at $p');
    expect(find.text(p == 0 ? 'BEFORE THE FIRST EVENT' : 'EVENT $p OF $last'), findsOneWidget, reason: 'inspector at $p');
    final panel = t.widget<ExplanationPanel>(find.byType(ExplanationPanel));
    expect(panel.explanation.codeLines, frame.explanation.codeLines, reason: 'source highlight at $p');
    expect(panel.explanation.variables, frame.explanation.variables, reason: 'variables at $p');
    final state = (session.timeline as dynamic).stateAt(p) as ThreadSchedState;
    expect(find.descendant(of: find.byType(ThreadLanes), matching: find.text(state.memoryValue)), findsWidgets, reason: 'shared value at $p');
    expect(t.widget<VizControls>(find.byType(VizControls)).controller.position, p);
    // exactly the statement that just ran is "running now"
    final running = find.bySemanticsLabel(RegExp(r'running now'));
    expect(running, p == 0 ? findsNothing : findsOneWidget, reason: 'current statement at $p');
  }

  group('with the authored lesson (backend unreachable)', () {
    testWidgets('every position agrees across lanes, timeline, inspector, source, values and caption, forwards and backwards', (t) async {
      final sem = t.ensureSemantics();
      await open(t, builtinLostUpdate());
      for (var p = 0; p <= 6; p++) {
        await goTo(t, p);
        expectAgreement(t, p);
      }
      for (var p = 6; p >= 0; p--) {
        await goTo(t, p);
        expectAgreement(t, p);
      }
      await close(t);
      sem.dispose();
    });

    testWidgets('the current statement is the one that belongs to the selected event', (t) async {
      final sem = t.ensureSemantics();
      await open(t, builtinLostUpdate());
      await goTo(t, 3); // Thread A calculates
      expect(find.bySemanticsLabel(RegExp(r'^Thread A, calculate: .*running now')), findsOneWidget);
      await goTo(t, 6); // Thread B writes: the lost update
      expect(find.bySemanticsLabel(RegExp(r'^Thread B, write: .*running now.*the update is lost')), findsOneWidget);
      await close(t);
      sem.dispose();
    });

    testWidgets('tapping an event on the timeline selects it everywhere', (t) async {
      final sem = t.ensureSemantics();
      await open(t, builtinLostUpdate());
      await t.ensureVisible(find.bySemanticsLabel(RegExp(r'^Event 5: Thread A write')));
      await t.tap(find.bySemanticsLabel(RegExp(r'^Event 5: Thread A write')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(session.controller.position, 5);
      expectAgreement(t, 5);
      await t.ensureVisible(find.bySemanticsLabel(RegExp(r'^Event 6: Thread B write, the update is lost here')));
      await t.pump();
      await t.tap(find.bySemanticsLabel(RegExp(r'^Event 6: Thread B write, the update is lost here')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expectAgreement(t, 6);
      await close(t);
      sem.dispose();
    });

    testWidgets('tapping a statement in a lane selects the event that ran it', (t) async {
      final sem = t.ensureSemantics();
      await open(t, builtinLostUpdate());
      await t.tap(find.bySemanticsLabel(RegExp(r'^Thread B, calculate: .*Select this event')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(session.controller.position, 4);
      expectAgreement(t, 4);
      await close(t);
      sem.dispose();
    });

    testWidgets('shows the lost update as it happens: B\'s copy goes out of date, then B overwrites A', (t) async {
      await open(t, builtinLostUpdate());
      await goTo(t, 5); // A has written 1; B still holds what it read
      expect(find.text('read 0, shared is now 1'), findsOneWidget);
      await goTo(t, 6);
      expect(find.text('was 1: nothing new was added'), findsOneWidget);
      expect(find.text('should end at 2'), findsOneWidget);
      expect(find.text('WHY IT MATTERS'), findsOneWidget);
      expect(find.textContaining('out-of-date data'), findsWidgets);
      await close(t);
    });

    testWidgets('says the example is authored, not generated from the learner\'s code', (t) async {
      await open(t, builtinLostUpdate());
      expect(find.text('AUTHORED EXAMPLE'), findsOneWidget);
      expect(find.text('TEACHING SIMULATION'), findsNothing);
      await close(t);
    });
  });

  group('with the simulator\'s own trace', () {
    testWidgets('every position agrees in all three runs', (t) async {
      final sem = t.ensureSemantics();
      await open(t, _traced());
      for (final v in ['RACE', 'RACE_ALT', 'SYNC']) {
        session.setVariant(v);
        await t.pump();
        for (var p = 0; p < session.controller.length; p++) {
          await goTo(t, p);
          expectAgreement(t, p);
        }
      }
      await close(t);
      sem.dispose();
    });

    testWidgets('names the simulation as a model, with the real Java statements in the lanes', (t) async {
      await open(t, _traced());
      expect(find.text('TEACHING SIMULATION'), findsOneWidget);
      expect(find.textContaining('not a recording of a JVM run'), findsOneWidget);
      expect(find.text('int tmp = count;'), findsNWidgets(2));
      expect(find.text('tmp = tmp + 1;'), findsNWidgets(2));
      expect(find.text('count = tmp;'), findsNWidgets(2));
      await close(t);
    });

    testWidgets('the synchronized run shows B waiting, with the added lines marked as not the learner\'s code', (t) async {
      final sem = t.ensureSemantics();
      await open(t, _traced());
      session.setVariant('SYNC');
      await t.pump();
      await goTo(t, 3);
      expect(find.bySemanticsLabel(RegExp(r'^Thread B, lock: synchronized \(lock\) \{, running now, waiting for the lock')), findsOneWidget);
      expect(find.text('waiting for the lock'), findsOneWidget);
      expect(find.text('Waiting for the lock'), findsWidgets);
      expect(find.text('waiting'), findsOneWidget);
      expect(find.text('added'), findsWidgets);
      expect(find.textContaining('Thread A holds it'), findsWidgets);
      await goTo(t, 11);
      expect(find.textContaining('Every update survived'), findsWidgets);
      await close(t);
      sem.dispose();
    });
  });

  group('captions and audio', () {
    testWidgets('the caption is the sentence that is spoken, for the event on screen', (t) async {
      await open(t, builtinLostUpdate());
      await goTo(t, 2);
      await t.tap(find.byKey(const Key('hear-step')));
      await t.pump();
      expect(engine.spoken, [session.frameAt(2).explanation.narration]);
      await close(t);
    });

    testWidgets('moving to another event while a sentence plays never leaves the old one speaking', (t) async {
      await open(t, builtinLostUpdate());
      engine.autoFinish = false;
      await goTo(t, 2);
      await t.tap(find.byKey(const Key('hear-step')));
      await t.pump();
      expect(find.byKey(const Key('speaking')), findsOneWidget);
      await goTo(t, 5);
      expect(find.byKey(const Key('speaking')), findsNothing);
      expect(engine.inFlight, isFalse);
      expect(engine.spoken, [session.frameAt(2).explanation.narration], reason: 'seeking is silent; nothing new was spoken');
      await close(t);
    });

    testWidgets('with the voice unavailable the lesson, captions and transcript still work and the learner is told why', (t) async {
      await open(t, builtinLostUpdate());
      BitVoice.instance.available = false;
      BitVoice.instance.notifyListeners();
      await t.pump();
      expect(find.byKey(const Key('voice-unavailable')), findsOneWidget);
      expect(find.byKey(const Key('hear-step')), findsNothing);
      await goTo(t, 4);
      expectAgreementWithoutAudio(t, 4);
      await t.tap(find.byKey(const Key('transcript-toggle')));
      await t.pump();
      expect(find.byKey(const Key('transcript')), findsOneWidget);
      expect(find.textContaining('1.  '), findsOneWidget);
      expect(find.textContaining('4.  '), findsOneWidget);
      expect(find.textContaining('5.  '), findsNothing, reason: 'the transcript stops at the current event');
      await close(t);
    });
  });
}

void expectAgreementWithoutAudio(WidgetTester t, int p) {
  expect(find.text('EVENT $p OF 6'), findsOneWidget);
  expect(find.byKey(const Key('caption')), findsOneWidget);
}
