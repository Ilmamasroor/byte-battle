import 'dart:convert';
import 'dart:io';
import 'package:byte_battle/core/models/backend_models.dart';
import 'package:byte_battle/features/learning/viz3d/contract/viz_contract.dart';
import 'package:byte_battle/features/learning/viz3d/engine/viz_session.dart';
import 'package:byte_battle/features/learning/viz3d/modules/concurrency/builtin_lost_update.dart';
import 'package:byte_battle/features/learning/viz3d/modules/concurrency/thread_schedule_lesson.dart';
import 'package:byte_battle/features/learning/viz3d/registry/viz_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart';

typedef _T = ReducerTimeline<ThreadSchedState, VizStep>;

_T _timeline(VizLesson l, String variant) => l.build(variant: variant) as _T;

void main() {
  final builtin = builtinLostUpdate();
  VizLesson lesson() => VizRegistry.standard().resolve(VizSource(conceptId: raceId, simulation: builtin)).lessons.firstWhere(isThreadScheduleLesson);

  group('lost update: the default order (both read, both calculate, A writes, B overwrites)', () {
    test('runs read, read, calculate, calculate, write, overwrite', () {
      final t = _timeline(lesson(), 'RACE');
      expect(t.length, 7);
      expect([for (final e in t.events) '${e.thread}:${e.kind}'], ['a:READ', 'b:READ', 'a:COMPUTE', 'b:COMPUTE', 'a:WRITE', 'b:WRITE']);
    });

    test('keeps each thread\'s private copy apart from shared memory, event by event', () {
      final t = _timeline(lesson(), 'RACE');
      String local(int p, String thread) => t.stateAt(p).run(thread).local ?? '-';
      expect([for (var p = 0; p < 7; p++) t.stateAt(p).memoryValue], ['0', '0', '0', '0', '0', '1', '1']);
      expect(local(0, 'a'), '-');
      expect(local(1, 'a'), '0'); // A reads 0
      expect(local(2, 'b'), '0'); // B reads the same 0 because A has not written yet
      expect(local(3, 'a'), '1'); // A calculates 1 on its own copy
      expect(local(4, 'b'), '1'); // so does B
      expect(t.stateAt(4).memoryValue, '0'); // calculating changes no shared state
      expect(t.stateAt(5).memoryValue, '1'); // A writes 1
      expect(t.stateAt(6).memoryValue, '1'); // B writes its 1 over A's 1
      expect(t.stateAt(6).writes, 2);
    });

    test('ends at 1 instead of the expected 2, and the outcome agrees with the final event', () {
      final t = _timeline(lesson(), 'RACE');
      final o = t.outcome!;
      expect((o.expected, o.actual, o.matches), ('2', '1', false));
      expect(o.actual, t.finalState.memoryValue);
      expect(o.meaning, contains('overwritten'));
    });

    test('names the stale write, and only that write, as the moment the update is lost', () {
      final t = _timeline(lesson(), 'RACE');
      expect([for (final e in t.events) e.stale], [false, false, false, false, false, true]);
      expect(t.markers, {6});
      expect(t.frameAt(6).explanation.hazard, 'Lost update');
      expect(t.frameAt(5).explanation.hazard, isNull);
      final lost = t.frameAt(6).explanation;
      expect(lost.text, contains('Thread B writes 1 into shared count'));
      expect(lost.text, contains('replaces the 1 Thread A just wrote'));
      expect(lost.text, contains('increment is lost'));
      expect(lost.text, contains('should be 2'));
      expect(lost.why, contains('out-of-date'));
      expect(lost.change!.before, '1');
      expect(lost.change!.after, '1');
      expect(lost.change!.isChange, isFalse); // the value did not move: that is the loss
    });

    test('explains the second read in terms of the first thread not having written yet', () {
      final t = _timeline(lesson(), 'RACE');
      expect(t.frameAt(1).explanation.text, contains('Thread A reads count from shared memory and sees 0'));
      expect(t.frameAt(2).explanation.text, contains('Thread B also reads count and sees 0'));
      expect(t.frameAt(2).explanation.text, contains('Thread A has read it but has not written yet'));
    });

    test('every event has a reason, a change record for what it touches, and a source line', () {
      final t = _timeline(lesson(), 'RACE');
      for (var p = 1; p < t.length; p++) {
        final x = t.frameAt(p).explanation;
        expect(x.why, isNotEmpty, reason: 'position $p');
        expect(x.change, isNotNull, reason: 'position $p');
        expect(x.codeLines, hasLength(1), reason: 'position $p');
      }
      expect(t.frameAt(1).explanation.codeLines, [4]); // `int tmp = count;`
      expect(t.frameAt(3).explanation.codeLines, [5]); // `tmp = tmp + 1;`
      expect(t.frameAt(5).explanation.codeLines, [6]); // `count = tmp;`
      expect(t.code[4].trim(), 'int tmp = count;');
    });

    test('lists one event mark per event for the timeline strip', () {
      final t = _timeline(lesson(), 'RACE');
      expect(t.actors, ['a', 'b']);
      expect([for (final m in t.eventMarks) (m.position, m.actor, m.label, m.problem)], [
        (1, 0, 'read', false),
        (2, 1, 'read', false),
        (3, 0, 'calc', false),
        (4, 1, 'calc', false),
        (5, 0, 'write', false),
        (6, 1, 'write', true),
      ]);
    });

    test('every frame is a valid scene', () {
      for (final v in ['RACE', 'RACE_ALT', 'SYNC']) {
        final t = lesson().build(variant: v);
        for (var p = 0; p < t.length; p++) {
          t.frameAt(p).scene.validate();
        }
      }
    });
  });

  group('lost update: the alternative order (B finishes inside A\'s gap)', () {
    test('loses A\'s update this time, because A writes last from a stale copy', () {
      final t = _timeline(lesson(), 'RACE_ALT');
      expect([for (final e in t.events) '${e.thread}:${e.kind}'], ['a:READ', 'b:READ', 'b:COMPUTE', 'b:WRITE', 'a:COMPUTE', 'a:WRITE']);
      expect(t.stateAt(4).memoryValue, '1'); // B wrote 1
      expect(t.stateAt(5).run('a').local, '1'); // A calculates from its old 0
      expect(t.markers, {6});
      expect(t.frameAt(6).explanation.text, contains('Thread A writes 1 into shared count'));
      expect(t.frameAt(6).explanation.text, contains('Thread B\'s increment is lost'));
      expect(t.outcome!.actual, '1');
    });
  });

  group('lost update: with synchronized', () {
    test('B is blocked while A holds the lock, so B reads A\'s result and the counter ends at 2', () {
      final t = _timeline(lesson(), 'SYNC');
      expect(t.length, 12);
      expect(t.finalState.memoryValue, '2');
      expect((t.outcome!.expected, t.outcome!.actual, t.outcome!.matches), ('2', '2', true));
      expect(t.markers, isEmpty);
      final blocked = t.frameAt(3);
      expect(blocked.explanation.hazard, 'Waiting for the lock');
      expect(blocked.explanation.text, contains('Thread A holds it'));
      expect(t.stateAt(3).run('b').blockedOn, 'lock');
      expect(t.stateAt(3).lockOwners, {'lock': 'a'});
      final bRead = [for (final e in t.events) e].indexWhere((e) => e.thread == 'b' && e.kind == 'READ') + 1;
      expect(t.stateAt(bRead).run('b').local, '1');
    });

    test('never lets both threads hold the lock, and only the owner writes inside it', () {
      final t = _timeline(lesson(), 'SYNC');
      for (var p = 0; p < t.length; p++) {
        final s = t.stateAt(p);
        expect(s.lockOwners.length, lessThanOrEqualTo(1), reason: 'position $p');
        final e = s.last;
        if (e != null && !e.blocked && (e.kind == 'READ' || e.kind == 'COMPUTE' || e.kind == 'WRITE')) {
          expect(s.lockOwners['lock'], e.thread, reason: 'position $p: ${e.kind} must happen while ${e.thread} holds the lock');
        }
      }
      expect(t.stateAt(t.length - 1).lockOwners, isEmpty);
    });

    test('says exactly what synchronized does here, without claiming more', () {
      final t = _timeline(lesson(), 'SYNC');
      final unlock = t.frameAt(6).explanation;
      expect(unlock.text, contains('Thread B can enter'));
      expect(unlock.why, contains('lets a waiting thread go'));
      expect(t.frameAt(1).explanation.why, contains('only holds back threads that ask for the same lock'));
    });
  });

  group('the offline lesson matches what the simulator returns', () {
    final fixture = jsonDecode(File('test/fixtures/lost_update_trace.json').readAsStringSync()) as Map<String, dynamic>;
    final traced = VisualizationModel.fromJson(fixture, code: fixture['code'] as String);

    List<Object?> shape(VizStep s) => [s.thread, s.kind, s.text, s.line, s.value, s.local, s.before, s.stale, s.hazard, s.blocked, s.waitingFor, s.synthetic, s.opIndex];

    test('is the same program', () {
      expect(builtin.code, traced.code);
      expect(builtin.code, kLostUpdateCode);
    });

    for (final kind in ['RACE', 'RACE_ALT', 'SYNC']) {
      test('$kind has the simulator\'s events, values and flags', () {
        final mine = builtin.schedule(kind)!;
        final theirs = traced.schedule(kind)!;
        expect(mine.steps.map(shape).toList(), theirs.steps.map(shape).toList());
        expect(mine.expected, theirs.expected);
        expect(mine.actual, theirs.actual);
      });
    }

    test('is labelled as authored, not as a simulation of the learner\'s code', () {
      expect(builtin.authored, isTrue);
      expect(traced.authored, isFalse);
    });
  });

  group('comparing and switching', () {
    test('offers the bug, the other order and the synchronized fix, and compares their outcomes', () {
      final s = VizSession(lessons: [lesson()]);
      expect(s.lesson.variants.map((v) => v.id), ['RACE', 'RACE_ALT', 'SYNC']);
      expect(s.outcomeOf('RACE')!.matches, isFalse);
      expect(s.outcomeOf('RACE_ALT')!.matches, isFalse);
      expect(s.outcomeOf('SYNC')!.matches, isTrue);
      s.dispose();
    });

    test('switching mode resets playback to the start with nothing stale', () {
      final s = VizSession(lessons: [lesson()]);
      s.controller.seek(6);
      s.select('memory');
      s.setVariant('SYNC');
      expect(s.controller.position, 0);
      expect(s.controller.length, 12);
      expect(s.selectedId, isNull);
      expect(s.frame.scene.node('memory')!.label, '0');
      s.setVariant('RACE');
      expect(s.controller.length, 7);
      expect(s.frame.explanation.hazard, isNull);
      s.dispose();
    });
  });

  group('stepping back and replaying restore the exact state', () {
    test('every position is the same wherever it is reached from', () {
      final s = VizSession(lessons: [lesson()]);
      final t = s.timeline;
      final forward = [for (var p = 0; p < t.length; p++) t.frameAt(p).explanation.text];
      for (var p = 0; p < t.length; p++) {
        s.controller.seek(p);
        expect(s.frame.explanation.text, forward[p]);
      }
      for (var p = t.length - 1; p >= 0; p--) {
        s.controller.seek(p);
        expect(s.frame.explanation.text, forward[p], reason: 'reached $p going backwards');
        expect(s.frame.explanation.variables['count'], t.frameAt(p).explanation.variables['count']);
      }
      s.dispose();
    });

    test('a new timeline for the same variant is event-for-event identical', () {
      final one = lesson().build(variant: 'RACE');
      final two = lesson().build(variant: 'RACE');
      expect([for (var p = 0; p < one.length; p++) one.frameAt(p).explanation.text], [for (var p = 0; p < two.length; p++) two.frameAt(p).explanation.text]);
    });
  });

  group('backend schedules', () {
    VizLesson fromBackend() => VizRegistry.standard().resolve(VizSource(conceptId: raceId, simulation: backendRace())).lessons.firstWhere(isThreadScheduleLesson);

    test('use the same lesson machinery: read, sleep and write steps drive the same state', () {
      final t = _timeline(fromBackend(), 'RACE');
      expect(t.length, 7);
      expect(t.finalState.memoryValue, '1');
      expect(t.outcome!.expected, '2');
      expect(t.outcome!.actual, '1');
      expect(t.frameAt(3).explanation.text, contains('pauses'));
      expect(t.markers, {6});
    });

    test('highlight the Java line of the running step', () {
      final t = _timeline(fromBackend(), 'RACE');
      expect(t.code.length, 4);
      expect(t.frameAt(1).explanation.codeLines, [0]);
      expect(t.frameAt(4).explanation.codeLines, [1]);
    });

    test('model a deadlock: two held locks, two blocked threads, nobody finishes', () {
      final t = _timeline(fromBackend(), 'DEADLOCK');
      expect(t.stateAt(2).lockOwners, {'A': 'Thread-1-1', 'B': 'Thread-2-2'});
      expect(t.stateAt(3).run('Thread-1-1').blockedOn, 'B');
      expect(t.stateAt(4).run('Thread-2-2').blockedOn, 'A');
      expect(t.frameAt(3).explanation.text, contains('has to wait'));
      expect(t.outcome!.actual, '0');
      expect(t.outcome!.matches, isFalse);
      for (var p = 0; p < t.length; p++) {
        t.frameAt(p).scene.validate();
      }
    });

    test('a concept with no simulation and no built-in lesson yields no thread lesson', () {
      final res = VizRegistry.standard().resolve(const VizSource(conceptId: 'unknown'));
      expect(res.lessons.where(isThreadScheduleLesson), isEmpty);
    });
  });
}
