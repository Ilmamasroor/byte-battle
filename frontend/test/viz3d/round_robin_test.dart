import 'package:byte_battle/features/learning/viz3d/contract/viz_contract.dart';
import 'package:byte_battle/features/learning/viz3d/modules/os/round_robin_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

ReducerTimeline<RrState, RrEvent> _rr(String workload, int quantum) =>
    roundRobinLesson().build(overrides: {'workload': workload, 'quantum': '$quantum'}) as ReducerTimeline<RrState, RrEvent>;

void main() {
  group('round robin scheduler', () {
    test('classic workload at quantum 2 matches the curriculum: waits 5, 6, 4 and average 5.0', () {
      final t = _rr('classic', 2);
      final fin = t.finalState;
      int wait(String id) {
        final p = fin.proc(id);
        return p.finish! - p.job.arrival - p.job.burst;
      }

      expect(wait('P1'), 5);
      expect(wait('P2'), 6);
      expect(wait('P3'), 4);
      expect(t.outcome!.expected, '5.0');
      expect(t.outcome!.actual, '5.0');
      expect(t.outcome!.matches, isTrue);
    });

    test('processes move ready -> running -> ready/terminated, and only one runs at a time', () {
      for (final q in [1, 2, 3, 4]) {
        final t = _rr('classic', q);
        for (var p = 0; p < t.length; p++) {
          final s = t.stateAt(p);
          expect(s.procs.where((x) => x.state == ProcState.running).length, lessThanOrEqualTo(1), reason: 'q=$q @$p');
          expect(s.running == null || s.proc(s.running!).state == ProcState.running, isTrue);
          // a process is in the queue exactly when it is ready
          expect({for (final x in s.procs.where((x) => x.state == ProcState.ready)) x.job.id}, s.queue.toSet(), reason: 'q=$q @$p');
          expect(s.queue.toSet().length, s.queue.length, reason: 'no duplicates in the queue');
        }
      }
    });

    test('CPU time is conserved: busy ticks equal total burst, and nobody gets more than the quantum at once', () {
      for (final workload in kRrWorkloads.keys) {
        for (final q in [1, 2, 3, 4]) {
          final t = _rr(workload, q);
          final fin = t.finalState;
          final busy = fin.gantt.where((g) => g.job != null).fold<int>(0, (a, g) => a + g.end - g.start);
          expect(busy, kRrWorkloads[workload]!.fold<int>(0, (a, j) => a + j.burst), reason: '$workload q=$q');
          for (final g in fin.gantt.where((g) => g.job != null)) {
            expect(g.end - g.start, lessThanOrEqualTo(q));
          }
          for (final p in fin.procs) {
            expect(p.state, ProcState.terminated);
            expect(p.remaining, 0);
            expect(p.finish!, greaterThanOrEqualTo(p.job.arrival + p.job.burst));
          }
        }
      }
    });

    test('two independent ways of computing the waiting time agree for every workload and slice', () {
      for (final workload in kRrWorkloads.keys) {
        for (final q in [1, 2, 3, 4]) {
          final o = _rr(workload, q).outcome!;
          expect(o.matches, isTrue, reason: '$workload q=$q: formula ${o.expected} vs tracked ${o.actual}');
        }
      }
    });

    test('a staggered workload leaves the CPU idle until the late job arrives', () {
      final t = _rr('staggered', 2);
      expect(t.finalState.gantt.any((g) => g.job == null), isTrue);
      final idle = t.finalState.gantt.firstWhere((g) => g.job == null);
      expect(idle.start, 12);
      expect(idle.end, 14);
    });

    test('jobs that arrive during a slice queue before the pre-empted job', () {
      final t = _rr('staggered', 2);
      // P1 runs 0..2; P2 (t=1) and P3 (t=2) arrive meanwhile, so P1 re-queues behind them.
      final i = [for (var p = 0; p < t.length; p++) p].firstWhere((p) => t.stateAt(p).last?.kind == RrKind.preempt && t.stateAt(p).last!.job == 'P1');
      expect(t.stateAt(i).queue.take(3).toList(), ['P2', 'P3', 'P1']);
    });

    test('a smaller slice changes the schedule, not just the picture', () {
      expect(_rr('classic', 1).finalState.gantt.length, greaterThan(_rr('classic', 4).finalState.gantt.length));
    });

    test('scene towers shrink as work is done and every frame is valid', () {
      final t = _rr('classic', 2);
      final first = t.frameAt(0).scene.node('proc:P1')!.size.y;
      var min = first;
      for (var p = 0; p < t.length; p++) {
        final scene = t.frameAt(p).scene..validate();
        final h = scene.node('proc:P1')!.size.y;
        if (h < min) min = h;
      }
      expect(min, lessThan(first));
    });
  });
}
