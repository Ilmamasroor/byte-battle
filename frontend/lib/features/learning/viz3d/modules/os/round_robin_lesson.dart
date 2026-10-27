import 'dart:math' as math;
import '../../../../../app/theme/app_colors.dart';
import '../../contract/viz_contract.dart';
import '../../render/scene_spec.dart';
import '../viz_palette.dart';

const kCpuSchedulingConceptId = '00000000-0000-0000-0000-000000001035';

class RrJob {
  final String id;
  final int arrival;
  final int burst;
  const RrJob(this.id, this.arrival, this.burst);
}

/// The workloads a learner can pick. `classic` matches the walkthrough in the curriculum (average wait 5.0 at
/// quantum 2); `staggered` adds arrival times so a CPU can sit idle.
const kRrWorkloads = {
  'classic': [RrJob('P1', 0, 5), RrJob('P2', 0, 3), RrJob('P3', 0, 2)],
  'staggered': [RrJob('P1', 0, 6), RrJob('P2', 1, 4), RrJob('P3', 2, 2), RrJob('P4', 14, 3)],
};

const _code = [
  'while (jobsLeft) {',
  '  admit every job that has arrived',
  '  p = readyQueue.removeFirst();',
  '  run p for min(quantum, p.remaining)',
  '  admit anything that arrived meanwhile',
  '  if (p.remaining > 0) readyQueue.addLast(p);',
  '  else p.finish = now;',
  '}',
];

enum ProcState { notArrived, ready, running, terminated }

class RrProc {
  final RrJob job;
  final ProcState state;
  final int remaining;
  final int? finish;
  final int readyTime; // ticks spent waiting in the ready queue, tracked as the clock advances
  const RrProc(this.job, this.state, this.remaining, this.finish, this.readyTime);

  RrProc copyWith({ProcState? state, int? remaining, int? finish, int? readyTime}) =>
      RrProc(job, state ?? this.state, remaining ?? this.remaining, finish ?? this.finish, readyTime ?? this.readyTime);
}

class RrSlice {
  final String? job; // null = the CPU was idle
  final int start;
  final int end;
  const RrSlice(this.job, this.start, this.end);
}

enum RrKind { arrive, dispatch, run, preempt, terminate, idle }

class RrEvent {
  final RrKind kind;
  final String? job;
  final int time; // clock after the event
  final int from; // clock before the event
  const RrEvent(this.kind, this.job, this.from, this.time);
}

/// Everything the scheduler knows at one moment.
class RrState {
  final int time;
  final List<RrProc> procs;
  final List<String> queue; // front first
  final String? running;
  final List<RrSlice> gantt;
  final RrEvent? last;
  const RrState({required this.time, required this.procs, required this.queue, this.running, this.gantt = const [], this.last});

  RrProc proc(String id) => procs.firstWhere((p) => p.job.id == id);
}

/// Runs Round Robin and records every scheduling decision as an event. Pure and deterministic. Jobs that arrive
/// while another runs join the queue BEFORE the pre-empted job goes to the back (the usual convention).
List<RrEvent> roundRobinEvents(List<RrJob> jobs, int quantum) {
  final pending = [...jobs]..sort((a, b) => a.arrival.compareTo(b.arrival));
  final remaining = {for (final j in jobs) j.id: j.burst};
  final queue = <String>[];
  final out = <RrEvent>[];
  var t = 0;

  void admit(int upTo) {
    while (pending.isNotEmpty && pending.first.arrival <= upTo) {
      final j = pending.removeAt(0);
      queue.add(j.id);
      out.add(RrEvent(RrKind.arrive, j.id, j.arrival, j.arrival));
    }
  }

  admit(t);
  var done = 0;
  while (done < jobs.length) {
    if (queue.isEmpty) {
      final next = pending.first.arrival;
      out.add(RrEvent(RrKind.idle, null, t, next));
      t = next;
      admit(t);
      continue;
    }
    final id = queue.removeAt(0);
    out.add(RrEvent(RrKind.dispatch, id, t, t));
    final run = math.min(quantum, remaining[id]!);
    final start = t;
    t += run;
    remaining[id] = remaining[id]! - run;
    out.add(RrEvent(RrKind.run, id, start, t));
    admit(t);
    if (remaining[id]! > 0) {
      queue.add(id);
      out.add(RrEvent(RrKind.preempt, id, start, t));
    } else {
      done++;
      out.add(RrEvent(RrKind.terminate, id, start, t));
    }
  }
  return out;
}

VizLesson roundRobinLesson({String conceptId = kCpuSchedulingConceptId, String? topicId}) => VizLesson(
      id: 'round-robin/$conceptId',
      conceptId: conceptId,
      topicId: topicId,
      category: VizCategory.operatingSystems,
      title: 'Round Robin scheduling',
      summary: 'Change the time slice and see how waiting time moves.',
      params: const [
        VizParam('quantum', 'Time slice', [VizChoice('1', '1 tick'), VizChoice('2', '2 ticks'), VizChoice('3', '3 ticks'), VizChoice('4', '4 ticks')], '2'),
        VizParam('workload', 'Jobs', [VizChoice('classic', '3 jobs, all at 0'), VizChoice('staggered', '4 jobs, staggered')], 'classic'),
      ],
      abstractionNote: 'Each tower is a process: its height is the CPU time it still needs. The pad on the right is the CPU.',
      builder: (variant, params) => _timeline(kRrWorkloads[params['workload']] ?? kRrWorkloads['classic']!, int.tryParse(params['quantum'] ?? '') ?? 2),
    );

VizTimeline _timeline(List<RrJob> jobs, int quantum) {
  final events = roundRobinEvents(jobs, quantum);
  final total = events.isEmpty ? 0 : events.map((e) => e.time).reduce(math.max);
  final byId = {for (final j in jobs) j.id: j};

  RrState reduce(RrState s, RrEvent e) {
    final procs = [...s.procs];
    int idx(String id) => procs.indexWhere((p) => p.job.id == id);
    final queue = [...s.queue];
    var gantt = s.gantt;
    switch (e.kind) {
      case RrKind.arrive:
        // A job that arrived while another ran has already waited from its arrival until the clock now.
        final k = idx(e.job!);
        procs[k] = procs[k].copyWith(state: ProcState.ready, readyTime: procs[k].readyTime + (s.time - e.time));
        queue.add(e.job!);
        return RrState(time: s.time, procs: procs, queue: queue, running: s.running, gantt: gantt, last: e);
      case RrKind.idle:
        gantt = [...gantt, RrSlice(null, e.from, e.time)];
        return RrState(time: e.time, procs: procs, queue: queue, gantt: gantt, last: e);
      case RrKind.dispatch:
        queue.remove(e.job);
        final i = idx(e.job!);
        procs[i] = procs[i].copyWith(state: ProcState.running);
        return RrState(time: s.time, procs: procs, queue: queue, running: e.job, gantt: gantt, last: e);
      case RrKind.run:
        final ran = e.time - e.from;
        final i = idx(e.job!);
        procs[i] = procs[i].copyWith(remaining: procs[i].remaining - ran);
        // Everyone already sitting in the ready queue waited for the whole slice.
        for (final id in s.queue) {
          final k = idx(id);
          procs[k] = procs[k].copyWith(readyTime: procs[k].readyTime + ran);
        }
        gantt = [...gantt, RrSlice(e.job, e.from, e.time)];
        return RrState(time: e.time, procs: procs, queue: queue, running: s.running, gantt: gantt, last: e);
      case RrKind.preempt:
        final i = idx(e.job!);
        procs[i] = procs[i].copyWith(state: ProcState.ready);
        queue.add(e.job!); // behind anyone who arrived while it ran
        return RrState(time: s.time, procs: procs, queue: queue, gantt: gantt, last: e);
      case RrKind.terminate:
        final i = idx(e.job!);
        procs[i] = procs[i].copyWith(state: ProcState.terminated, finish: e.time);
        return RrState(time: s.time, procs: procs, queue: queue, gantt: gantt, last: e);
    }
  }

  double avgWaitFromGantt(RrState fin) {
    var sum = 0;
    for (final p in fin.procs) {
      sum += (p.finish ?? 0) - p.job.arrival - p.job.burst;
    }
    return sum / fin.procs.length;
  }

  return ReducerTimeline<RrState, RrEvent>(
    initial: RrState(time: 0, procs: [for (final j in jobs) RrProc(j, ProcState.notArrived, j.burst, null, 0)], queue: const []),
    events: events,
    reduce: reduce,
    code: _code,
    cameraHint: const CameraHint(yaw: -0.25, pitch: 0.6),
    isMarker: (s, e, p) => e != null && e.kind == RrKind.terminate,
    outcome: (fin) {
      final fromFormula = avgWaitFromGantt(fin); // (finish - arrival - burst), straight from the definition
      return VizOutcome(
        label: 'average waiting time',
        expected: fromFormula.toStringAsFixed(1),
        actual: _avgReadyWait(fin, byId).toStringAsFixed(1),
        meaning: 'Waiting time is turnaround minus burst. With a time slice of $quantum, the CPU is shared in turns.',
      );
    },
    explain: (s, e, p) {
      final vars = {'time': '${s.time}', 'running': s.running ?? 'idle', 'queue': s.queue.isEmpty ? '(empty)' : s.queue.join(', '), 'quantum': '$quantum'};
      if (e == null) {
        return VizExplanation('Each job needs some CPU time. Round Robin lets each run for at most $quantum tick${quantum == 1 ? '' : 's'}, then goes to the back of the line.',
            codeLines: const [0], variables: vars);
      }
      switch (e.kind) {
        case RrKind.arrive:
          return VizExplanation(
              e.time < s.time
                  ? '${e.job} arrived at time ${e.time}, while another job was running, and joined the back of the ready queue.'
                  : '${e.job} arrives at time ${e.time} and joins the back of the ready queue.',
              codeLines: const [1, 4],
              variables: vars);
        case RrKind.idle:
          return VizExplanation('Nothing is ready, so the CPU sits idle from ${e.from} to ${e.time}.', codeLines: const [1], variables: vars);
        case RrKind.dispatch:
          return VizExplanation('${e.job} is first in the queue, so it gets the CPU.',
              note: 'run ${e.job} for min($quantum, ${s.proc(e.job!).remaining})', codeLines: const [2, 3], variables: vars);
        case RrKind.run:
          return VizExplanation('${e.job} runs from tick ${e.from} to ${e.time}${e.time - e.from < quantum ? ' (it needed less than a full slice)' : ' (a full slice)'}.',
              note: 't = ${e.from}..${e.time}', codeLines: const [3], variables: vars);
        case RrKind.preempt:
          return VizExplanation('${e.job} used up its slice and still needs ${s.proc(e.job!).remaining}. It goes to the back of the queue.',
              note: 'preempted at t = ${e.time}', codeLines: const [5], variables: vars);
        case RrKind.terminate:
          final pr = s.proc(e.job!);
          return VizExplanation(
              '${e.job} finishes at time ${e.time}. It waited ${e.time - pr.job.arrival - pr.job.burst} tick${e.time - pr.job.arrival - pr.job.burst == 1 ? '' : 's'} in total.',
              note: 'wait = ${e.time} - ${pr.job.arrival} - ${pr.job.burst}',
              codeLines: const [6],
              variables: vars);
      }
    },
    scene: (s, p) => _scene(s, total, quantum),
  );
}

/// The average wait as the scheduler tracked it while it ran: ticks spent in the ready queue.
double _avgReadyWait(RrState fin, Map<String, RrJob> byId) {
  var sum = 0;
  for (final p in fin.procs) {
    sum += p.readyTime;
  }
  return sum / fin.procs.length;
}

SceneSpec _scene(RrState s, int total, int quantum) {
  final nodes = <SceneNode>[];
  final maxBurst = s.procs.map((p) => p.job.burst).reduce(math.max);
  double towerH(int remaining) => math.max(0.25, remaining / maxBurst * 2.6);

  nodes.add(const SceneNode(id: 'board', backdrop: true, shape: SceneShape.box, position: Vec3(0, -0.15, 1.5), size: Vec3(19, 0.3, 11), color: VizPalette.board));
  // CPU pad.
  final running = s.running;
  nodes.add(SceneNode(
    id: 'cpu',
    shape: SceneShape.cylinder,
    position: const Vec3(3.2, 0.2, 0),
    size: const Vec3(3.4, 0.4, 3.4),
    color: running == null ? VizPalette.plate : AppColors.primary,
    glow: running == null ? 0.1 : 0.7,
    label: running ?? 'idle',
    labelSize: 0.5,
    caption: 'CPU',
    selectable: true,
    inspect: {'What': 'The CPU (one core)', 'Running': running ?? 'nothing', 'Clock': 't = ${s.time}', 'Time slice': '$quantum ticks'},
  ));

  for (final p in s.procs) {
    final id = p.job.id;
    final color = {
      ProcState.notArrived: VizPalette.idle,
      ProcState.ready: AppColors.accentCyan,
      ProcState.running: AppColors.primary,
      ProcState.terminated: AppColors.success,
    }[p.state]!;
    final h = towerH(p.state == ProcState.terminated ? p.job.burst : p.remaining);
    final Vec3 spot;
    switch (p.state) {
      case ProcState.running:
        spot = const Vec3(3.2, 0.4, 0);
      case ProcState.ready:
        spot = Vec3(-0.6 - s.queue.indexOf(id) * 1.9, 0, 0);
      case ProcState.terminated:
        spot = Vec3(7.0, 0, -3.2 + s.procs.where((x) => x.state == ProcState.terminated).toList().indexWhere((x) => x.job.id == id) * 1.7);
      case ProcState.notArrived:
        spot = Vec3(-7.5 + s.procs.indexWhere((x) => x.job.id == id) * 1.9, 0, -3.8);
    }
    nodes.add(SceneNode(
      id: 'proc:$id',
      shape: SceneShape.box,
      position: Vec3(spot.x, spot.y + h / 2, spot.z),
      size: Vec3(1.4, h, 1.4),
      color: color,
      glow: p.state == ProcState.running ? 0.9 : (p.state == ProcState.terminated ? 0.15 : 0.3),
      opacity: p.state == ProcState.terminated ? 0.75 : 1,
      label: id,
      labelSize: 0.38,
      caption: p.state == ProcState.terminated ? 'done t=${p.finish}' : (p.state == ProcState.notArrived ? 'arrives t=${p.job.arrival}' : 'needs ${p.remaining}'),
      selectable: true,
      inspect: {
        'What': 'A process',
        'State': const {
          ProcState.notArrived: 'not arrived',
          ProcState.ready: 'ready (waiting in queue)',
          ProcState.running: 'running',
          ProcState.terminated: 'terminated'
        }[p.state]!,
        'Arrival': '${p.job.arrival}',
        'Burst (total CPU needed)': '${p.job.burst}',
        'CPU still needed': '${p.remaining}',
        if (p.finish != null) 'Finished at': '${p.finish}',
        'Waited in queue': '${p.readyTime}',
      },
      related: ['proc:$id'],
    ));
  }
  nodes.add(SceneNode.label(id: 'q-label', position: const Vec3(-4.2, 0.05, -2.2), text: 'ready queue (front is next to the CPU)', color: AppColors.textSecondary, labelSize: 0.3));
  nodes.add(SceneNode.label(id: 'na-label', position: const Vec3(-5.3, 0.05, -5.2), text: 'not arrived yet', color: AppColors.textHint, labelSize: 0.28));
  nodes.add(SceneNode.label(id: 'done-label', position: const Vec3(7, 0.05, -5.0), text: 'finished', color: AppColors.textHint, labelSize: 0.28));

  // Gantt strip along the front: one block per slice, a cursor at the clock.
  final scale = math.min(0.62, 15.0 / math.max(total, 1));
  double gx(num t) => -7.5 + t * scale;
  nodes.add(SceneNode(
      id: 'gantt-base', backdrop: true, shape: SceneShape.box, position: Vec3(gx(total / 2), 0.02, 4.4), size: Vec3(total * scale + 0.3, 0.08, 1.1), color: VizPalette.plate));
  for (var i = 0; i < s.gantt.length; i++) {
    final g = s.gantt[i];
    final ci = g.job == null ? -1 : s.procs.indexWhere((p) => p.job.id == g.job);
    nodes.add(SceneNode(
      id: 'slice:$i',
      shape: SceneShape.box,
      position: Vec3(gx((g.start + g.end) / 2), 0.24, 4.4),
      size: Vec3((g.end - g.start) * scale - 0.06, 0.4, 0.9),
      color: ci < 0 ? VizPalette.dim : VizPalette.thread(ci),
      glow: i == s.gantt.length - 1 ? 0.6 : 0.15,
      label: g.job ?? 'idle',
      labelSize: 0.28,
      labelColor: AppColors.onAccent,
      selectable: true,
      inspect: {'What': 'A slice of CPU time', 'Job': g.job ?? 'idle', 'From': 't = ${g.start}', 'To': 't = ${g.end}'},
    ));
  }
  nodes.add(SceneNode(id: 'cursor', shape: SceneShape.box, position: Vec3(gx(s.time), 0.5, 5.15), size: const Vec3(0.12, 1.0, 0.12), color: AppColors.xp, glow: 0.9));
  nodes.add(SceneNode.label(id: 'clock', position: Vec3(gx(s.time), 1.25, 5.15), text: 't = ${s.time}', color: AppColors.xp, labelSize: 0.34));
  return SceneSpec(nodes: nodes, camera: const CameraHint(yaw: -0.25, pitch: 0.6));
}
