import 'dart:convert';
import 'dart:io';
import 'package:byte_battle/app/theme/app_theme.dart';
import 'package:byte_battle/core/models/backend_models.dart';
import 'package:byte_battle/core/voice/bit_voice.dart';
import 'package:byte_battle/core/voice/sound_cues.dart';
import 'package:byte_battle/features/learning/viz3d/contract/viz_contract.dart';
import 'package:byte_battle/features/learning/viz3d/engine/narration_controller.dart';
import 'package:byte_battle/features/learning/viz3d/engine/viz_session.dart';
import 'package:byte_battle/features/learning/viz3d/modules/concurrency/thread_lanes.dart';
import 'package:byte_battle/features/learning/viz3d/modules/concurrency/thread_schedule_lesson.dart';
import 'package:byte_battle/features/learning/viz3d/registry/viz_registry.dart';
import 'package:byte_battle/features/learning/visualization/widgets/thread_lab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'narration_test.dart' show ControlledEngine, FakeSound;

/// Phase 4: a second concept (Synchronization, concept 1013) on the same foundation. Its trace is the real simulator
/// output for the seeded "Two Locks, One Variable" exercise: two threads each hold a lock, but not the same one.
/// Nothing below needed a new timeline, scene, widget, narration or audio code.
const syncId = '00000000-0000-0000-0000-000000001013';

VisualizationModel _model() {
  final f = jsonDecode(File('test/fixtures/synchronization_trace.json').readAsStringSync()) as Map<String, dynamic>;
  return VisualizationModel.fromJson({'title': 'Two locks, one variable', 'visualization': f}, code: f['code'] as String);
}

typedef _T = ReducerTimeline<ThreadSchedState, VizStep>;

void main() {
  VizLesson lesson() => VizRegistry.standard().resolve(VizSource(conceptId: syncId, simulation: _model())).lessons.firstWhere(isThreadScheduleLesson);
  _T tl(String v) => lesson().build(variant: v) as _T;

  group('Synchronization reuses the thread lesson', () {
    test('is built by the same lesson builder with the same variants and provenance', () {
      final l = lesson();
      expect(l.variants.map((v) => v.id), ['RACE', 'RACE_ALT', 'SYNC']);
      expect(l.provenance!.kind, VizProvenanceKind.simulation);
      expect(l.provenance!.caveats.single, contains('Loops are shown as a single pass'));
    });

    test('shows that holding a lock is not enough: two different locks, and an update is still lost', () {
      final t = tl('RACE');
      expect(t.outcome!.expected, '0');
      expect(t.outcome!.actual, '-1');
      expect(t.outcome!.matches, isFalse);
      // both threads are inside their own synchronized blocks at the same time
      final both = [for (var p = 0; p < t.length; p++) t.stateAt(p).lockOwners].where((o) => o.length == 2).toList();
      expect(both, isNotEmpty);
      expect(both.first.keys.toSet(), {'addLock', 'subLock'});
      expect(t.markers, hasLength(1));
      final lost = t.frameAt(t.markers.single).explanation;
      expect(lost.hazard, 'Lost update');
      expect(lost.change!.before, '1', reason: 'the add had already stored 1');
      expect(lost.change!.after, '-1');
    });

    test('narrates a lock by name and does not claim it excludes threads that use another lock', () {
      final t = tl('RACE');
      final first = t.frameAt(1).explanation; // Thread 1 takes addLock
      expect(first.text, contains('takes addLock'));
      expect(first.text, contains('Any thread that asks for addLock must wait'));
      expect(first.why, contains('A thread using a different lock still runs'));
      expect(first.text, isNot(contains('no other thread')));
      // the second thread takes a different lock and is NOT blocked
      final second = [for (var p = 1; p < t.length; p++) t.frameAt(p)].firstWhere((f) => f.explanation.text.contains('subLock'));
      expect(second.explanation.hazard, isNull);
    });

    test('with one shared lock the second thread waits, reads the first thread\'s result, and the total is right', () {
      final t = tl('SYNC');
      expect(t.outcome!.matches, isTrue);
      expect(t.outcome!.actual, '0');
      expect(t.markers, isEmpty);
      final blocked = [for (var p = 1; p < t.length; p++) t.frameAt(p)].where((f) => f.explanation.hazard == 'Waiting for the lock').toList();
      expect(blocked, hasLength(1));
      expect(blocked.single.explanation.text, contains('tries to take lock'));
      expect(blocked.single.explanation.why, contains('same lock'));
      expect([for (final e in t.events) if (e.thread.endsWith('3-1') && e.kind == 'READ') e.value], ['1']);
    });

    test('every frame of every variant is a valid 3D scene too', () {
      for (final v in ['RACE', 'RACE_ALT', 'SYNC']) {
        final t = tl(v);
        for (var p = 0; p < t.length; p++) {
          t.frameAt(p).scene.validate();
        }
      }
    });
  });

  testWidgets('the same lab (lanes, timeline, inspector, caption, source) renders every position of every variant', (t) async {
    SharedPreferences.setMockInitialValues({});
    final engine = ControlledEngine()..autoFinish = true;
    BitVoice.instance
      ..engine = engine
      ..enabled = true
      ..available = true;
    final model = _model();
    final session = VizSession(lessons: [lesson()], prefer3D: false);
    final narration = NarrationController(playback: session.controller, textAt: (p) => session.frameAt(p).explanation.narration, cues: SoundCues(engine: FakeSound()));
    t.view.physicalSize = const Size(430 * 2, 3600 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: ThreadLab(session: session, model: model, narration: narration))),
    ));
    for (final v in ['RACE', 'RACE_ALT', 'SYNC']) {
      session.setVariant(v);
      await t.pump();
      expect(find.byType(ThreadLanes), findsOneWidget);
      for (var p = 0; p < session.controller.length; p++) {
        session.controller.seek(p);
        await t.pump();
        await t.pump(const Duration(milliseconds: 350));
        expect(find.text(p == 0 ? 'BEFORE THE FIRST EVENT' : 'EVENT $p OF ${session.controller.length - 1}'), findsOneWidget, reason: '$v at $p');
      }
    }
    expect(find.textContaining('lock: held by'), findsNothing, reason: 'all locks are released at the end');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    narration.dispose();
    session.dispose();
  });
}
