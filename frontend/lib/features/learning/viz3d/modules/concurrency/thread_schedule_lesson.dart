import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/models/backend_models.dart';
import '../../contract/viz_contract.dart';
import '../../render/scene_spec.dart';
import '../viz_palette.dart';

/// Domain state for a thread interleaving: one shared variable, each thread's private copy, locks and who is
/// blocked. This is the model the "lost update", safe-order and deadlock lessons all share; nothing in the
/// renderer knows about it.
class ThreadSchedState {
  final String memoryName;
  final String memoryValue;
  final List<ThreadRun> threads;
  final Map<String, String> lockOwners; // lock name -> thread that holds it
  final VizStep? last;
  final int writes;

  /// The shared value just before [last] ran, and who wrote it (null before the first write).
  final String? memoryBefore;
  final String? lastWriter;

  const ThreadSchedState(
      {required this.memoryName,
      required this.memoryValue,
      required this.threads,
      this.lockOwners = const {},
      this.last,
      this.writes = 0,
      this.memoryBefore,
      this.lastWriter});

  ThreadRun run(String thread) => threads.firstWhere((t) => t.name == thread);
}

class ThreadRun {
  final String name;
  final String? local; // the private copy it last read
  final int opsDone;
  final int opsTotal;
  final String? blockedOn;

  /// True from the moment the thread reads the shared value until it writes its result back: the window in which
  /// its private copy can go out of date.
  final bool holdsCopy;

  /// What the thread saw when it last read the shared value. If shared memory has moved on since, the thread is
  /// working from out-of-date data ([outOfDate]).
  final String? readValue;
  const ThreadRun(this.name, this.local, this.opsDone, this.opsTotal, [this.blockedOn, this.holdsCopy = false, this.readValue]);

  bool outOfDate(String shared) => holdsCopy && readValue != null && readValue != shared;

  ThreadRun copyWith({String? local, int? opsDone, String? blockedOn, bool clearBlock = false, bool? holdsCopy, String? readValue}) => ThreadRun(
      name,
      local ?? this.local,
      opsDone ?? this.opsDone,
      opsTotal,
      clearBlock ? null : (blockedOn ?? this.blockedOn),
      holdsCopy ?? this.holdsCopy,
      readValue ?? this.readValue);
}

/// What the learner is told about one event: the words (captioned and spoken), the reason it matters, and the value
/// it changes. Built only from the event and the state around it, so it cannot describe a different event.
class ThreadNarration {
  final String text;
  final String why;
  final VizChange? change;
  const ThreadNarration(this.text, this.why, this.change);
}

String _num(String? v) => v ?? '?';

ThreadNarration narrateThreadEvent(VizStep e, {required ThreadSchedState before, required ThreadSchedState after, required String Function(String) label}) {
  final who = label(e.thread);
  final mem = e.target.isEmpty ? after.memoryName : e.target;
  final others = [for (final t in before.threads) if (t.name != e.thread && t.holdsCopy) label(t.name)];
  final mine = before.run(e.thread).local;
  switch (e.kind.toUpperCase()) {
    case 'READ':
      final v = _num(e.value ?? e.local);
      return ThreadNarration(
        others.isEmpty
            ? '$who reads $mem from shared memory and sees $v. That value is now $who\'s own private copy.'
            : '$who also reads $mem and sees $v, the same old value, because ${others.join(' and ')} has read it but has not written yet. Each thread now holds its own copy.',
        'A read copies the value into the thread. Writes by other threads later do not update that copy.',
        VizChange('$who\'s copy', mine ?? 'nothing yet', v),
      );
    case 'COMPUTE':
      final from = e.before ?? mine;
      final to = _num(e.value ?? e.local);
      return ThreadNarration(
        '$who calculates on its private copy: ${_num(from)} becomes $to. Shared $mem is untouched and still holds ${after.memoryValue}.',
        'The result exists only inside this thread until it is written back.',
        VizChange('$who\'s copy', _num(from), to),
      );
    case 'WRITE':
      final v = _num(e.value);
      final prev = e.before ?? before.memoryValue;
      final change = VizChange('shared $mem', prev, v);
      if (e.stale) {
        final writer = before.lastWriter == null ? 'the other thread' : label(before.lastWriter!);
        return ThreadNarration(
          '$who writes $v into shared $mem. That replaces the $prev $writer just wrote, because $who calculated from the old value it read earlier. $writer\'s increment is lost.',
          'A write replaces the whole value. $who never saw the other update, so its result was built on out-of-date data.',
          change,
        );
      }
      return ThreadNarration(
        '$who writes $v into shared $mem, which held $prev.${others.isEmpty ? '' : ' ${others.join(' and ')} still holds its old copy.'}',
        'Shared memory now holds this value. Any thread that reads from now on sees it.',
        change,
      );
    case 'SLEEP':
      return ThreadNarration(
        '$who pauses for a moment. This gap is exactly where the other thread can run.',
        'Real programs get paused or switched out at moments like this. Another thread can run here.',
        null,
      );
    case 'LOCK':
      final lock = e.target;
      if (e.blocked) {
        final holder = e.waitingFor == null ? 'another thread' : label(e.waitingFor!);
        return ThreadNarration(
          '$who tries to take $lock, but $holder holds it. $who has to wait, so it cannot read ${after.memoryName} yet.',
          'Both threads need the same lock, so only one at a time can run read, calculate and write.',
          null,
        );
      }
      return ThreadNarration(
        '$who enters the synchronized block and takes $lock. Any thread that asks for $lock must wait until it leaves.',
        'A lock only holds back threads that ask for the same lock. A thread using a different lock still runs.',
        null,
      );
    case 'UNLOCK':
      final waiting = [for (final t in after.threads) if (t.blockedOn != null) label(t.name)];
      return ThreadNarration(
        '$who leaves the block and releases ${e.target}.${waiting.isEmpty ? '' : ' Now ${waiting.join(' and ')} can enter.'}',
        'Releasing the lock is what lets a waiting thread go, and it will read the value written inside the block.',
        null,
      );
    default:
      return ThreadNarration('$who: ${e.text}', 'One step of the thread\'s program.', null);
  }
}

String threadLabel(String t) {
  if (RegExp(r'^[A-Za-z]$').hasMatch(t)) return 'Thread ${t.toUpperCase()}';
  final m = RegExp(r'(\d+)').firstMatch(t);
  return m == null ? t : 'Thread ${m.group(1)}';
}

/// Where a thread lesson's events come from, in words a learner can check. A simulated sequence is never presented as
/// a recording of the JVM, and an authored fallback is never presented as the learner's own program.
VizProvenance threadProvenance(VisualizationModel m) {
  if (m.authored) {
    return const VizProvenance(
      VizProvenanceKind.authored,
      'Authored example',
      'The simulator could not be reached, so this is a prewritten example of the same lost update. It was not generated from your code.',
    );
  }
  return VizProvenance(
    VizProvenanceKind.simulation,
    'Teaching simulation',
    'A deterministic model of this code\'s threads. It shows one valid way they can interleave. It is not a recording of a JVM run.',
    caveats: m.support.reasons,
  );
}

const _threadLessonPrefix = 'thread-schedule/';

/// Builds the lesson for a set of backend (or built-in) schedules. The schedule list decides the variants, so a
/// concept that only has a RACE schedule offers just "The bug".
VizLesson threadScheduleLesson({
  required String conceptId,
  required String? topicId,
  required String title,
  required List<VizSchedule> schedules,
  required List<VizHazard> hazards,
  String code = '',
  VizProvenance? provenance,
}) {
  final byKind = {for (final s in schedules) s.kind.toUpperCase(): s};
  const order = ['RACE', 'RACE_ALT', 'SYNC', 'SAFE', 'DEADLOCK'];
  var kinds = [...order.where(byKind.containsKey), ...byKind.keys.where((k) => !order.contains(k))];
  // The synchronized schedule is the safe one shown in the same layout as the bug; a separate plain "safe order" would repeat it.
  if (byKind.containsKey('SYNC')) kinds = kinds.where((k) => k != 'SAFE').toList();
  String labelFor(String k) => switch (k) {
        'RACE' => 'The bug',
        'RACE_ALT' => 'Another order',
        'SYNC' => 'With synchronized',
        'SAFE' => 'Safe order',
        'DEADLOCK' => 'Deadlock',
        _ => k,
      };
  final codeLines = code.isEmpty ? const <String>[] : code.split('\n');

  return VizLesson(
    id: '$_threadLessonPrefix$conceptId',
    conceptId: conceptId,
    topicId: topicId,
    category: VizCategory.concurrency,
    title: title,
    summary: 'Real thread interleavings, one step at a time, on shared memory.',
    variants: [for (final k in kinds) VizVariant(k, labelFor(k))],
    interactions: const {VizInteraction.orbit, VizInteraction.zoom, VizInteraction.select, VizInteraction.replay, VizInteraction.compare},
    provenance: provenance,
    abstractionNote: 'The chamber is a metaphor: each core is a thread, the central block is the one shared variable, and a glowing packet is a value moving over the memory bus.',
    builder: (variant, params) => _threadTimeline(byKind[variant] ?? byKind[kinds.first]!, variant, hazards, codeLines),
  );
}

VizTimeline _threadTimeline(VizSchedule s, String variant, List<VizHazard> hazards, List<String> code) {
  final threads = s.threads.isNotEmpty ? s.threads : (s.steps.map((e) => e.thread).toSet().toList()..sort());
  String memName = 'value';
  for (final st in s.steps) {
    if ((st.kind.toUpperCase() == 'READ' || st.kind.toUpperCase() == 'WRITE') && st.target.isNotEmpty) {
      memName = st.target;
      break;
    }
  }
  String memInitial = '0';
  for (final st in s.steps) {
    if (st.kind.toUpperCase() == 'READ' && st.value != null) {
      memInitial = st.value!;
      break;
    }
  }
  final totals = {for (final t in threads) t: s.steps.where((e) => e.thread == t && !e.blocked).length};
  // Each schedule says which of its own steps are in the race window; the backend's hazard list indexes only one schedule.
  final hazardSteps = {for (final st in s.steps) if (st.hazard) st.index};
  // A blocked attempt to take a lock shares its op index with the LOCK that later succeeds; show that statement once.
  bool retried(VizStep e) => e.blocked && s.steps.any((o) => o.thread == e.thread && o.opIndex == e.opIndex && !o.blocked);
  final ops = {for (final t in threads) t: (s.steps.where((e) => e.thread == t && !retried(e)).toList()..sort((a, b) => a.opIndex.compareTo(b.opIndex)))};

  final initial = ThreadSchedState(
    memoryName: memName,
    memoryValue: memInitial,
    threads: [for (final t in threads) ThreadRun(t, null, 0, totals[t] ?? 0)],
  );

  ThreadSchedState reduce(ThreadSchedState st, VizStep e) {
    var memory = st.memoryValue;
    var writes = st.writes;
    var lastWriter = st.lastWriter;
    final owners = {...st.lockOwners};
    final runs = [
      for (final t in st.threads)
        if (t.name != e.thread) t else _applyToThread(t, e, owners),
    ];
    final k = e.kind.toUpperCase();
    if (k == 'WRITE' && e.value != null) {
      memory = e.value!;
      writes++;
      lastWriter = e.thread;
    }
    return ThreadSchedState(
        memoryName: st.memoryName,
        memoryValue: memory,
        threads: runs,
        lockOwners: owners,
        last: e,
        writes: writes,
        memoryBefore: st.memoryValue,
        lastWriter: lastWriter);
  }

  final expected = s.expected;
  final actual = s.actual;
  final deadlocked = variant == 'DEADLOCK';

  late final ReducerTimeline<ThreadSchedState, VizStep> timeline;
  timeline = ReducerTimeline<ThreadSchedState, VizStep>(
    initial: initial,
    events: s.steps,
    reduce: reduce,
    code: code,
    cameraHint: const CameraHint(yaw: -0.28, pitch: 0.62),
    actors: threads,
    isMarker: (st, e, pos) => e != null && (e.stale || (deadlocked && e.blocked)),
    mark: (st, e, pos) => VizEventMark(pos, threads.indexOf(e.thread), _markLabel(e), problem: e.stale || (deadlocked && e.blocked), waiting: e.blocked),
    outcome: (fin) {
      if (deadlocked) {
        final stuck = fin.threads.where((t) => t.blockedOn != null).length;
        return VizOutcome(
          label: 'threads finished',
          expected: '${threads.length}',
          actual: '${threads.length - stuck}',
          meaning: 'Each thread holds one lock and waits for the other, so none of them can ever finish.',
        );
      }
      if (expected == null) return null;
      return VizOutcome(
        label: 'final $memName',
        expected: expected,
        actual: actual ?? fin.memoryValue,
        meaning: (actual ?? fin.memoryValue) == expected ? 'Every update survived.' : 'An update was overwritten, so the total is wrong.',
      );
    },
    explain: (st, e, pos) {
      final lines = code.isEmpty || e == null || e.line <= 0 ? const <int>[] : [math.min(e.line - 1, code.length - 1)];
      final vars = {
        st.memoryName: st.memoryValue,
        for (final t in st.threads)
          if (t.local != null) '${threadLabel(t.name)} copy': t.local!
      };
      if (e == null) {
        final n = threads.length;
        return VizExplanation(
          '${n == 2 ? 'Two threads' : '$n threads'} are about to run on the same shared variable ${st.memoryName}, which holds ${st.memoryValue}. '
          'Each will read it, calculate, and write it back. Press play or step forward to watch.',
          variables: vars,
          codeLines: lines,
        );
      }
      final before = timeline.stateAt(pos - 1);
      final n = narrateThreadEvent(e, before: before, after: st, label: threadLabel);
      final atEnd = pos == s.steps.length;
      var text = n.text;
      if (atEnd && !deadlocked && expected != null) {
        final fin = actual ?? st.memoryValue;
        text += fin == expected
            ? ' Final ${st.memoryName}: $fin. Every update survived.'
            : ' Final ${st.memoryName}: $fin, but it should be $expected: an update was lost.';
      }
      return VizExplanation(
        text,
        note: e.text,
        codeLines: lines,
        variables: vars,
        why: n.why,
        change: n.change,
        cue: _cueFor(e),
        hazard: e.stale ? 'Lost update' : (e.blocked ? (deadlocked ? 'Waiting in a cycle' : 'Waiting for the lock') : null),
      );
    },
    scene: (st, pos) => _threadScene(st, pos, s, variant, threads, ops, hazardSteps),
  );
  return timeline;
}

/// The sound worth playing for an event, if any (see SoundCue): only the events that carry the lesson.
String? _cueFor(VizStep e) => switch (e.kind.toUpperCase()) {
      'WRITE' => e.stale ? 'lost' : 'write',
      'LOCK' => e.blocked ? 'blocked' : 'lock',
      'UNLOCK' => 'lock',
      _ => null,
    };

String _markLabel(VizStep e) => switch (e.kind.toUpperCase()) {
      'COMPUTE' => 'calc',
      'LOCK' => e.blocked ? 'wait' : 'lock',
      final k => k.toLowerCase(),
    };

ThreadRun _applyToThread(ThreadRun t, VizStep e, Map<String, String> owners) {
  switch (e.kind.toUpperCase()) {
    case 'READ':
      return t.copyWith(local: e.local ?? e.value, opsDone: t.opsDone + 1, holdsCopy: true, readValue: e.value ?? e.local);
    case 'COMPUTE':
      return t.copyWith(local: e.local ?? e.value, opsDone: t.opsDone + 1);
    case 'WRITE':
      return t.copyWith(opsDone: t.opsDone + 1, holdsCopy: false);
    case 'LOCK':
      if (e.blocked) return t.copyWith(blockedOn: e.target);
      owners[e.target] = e.thread;
      return t.copyWith(opsDone: t.opsDone + 1, clearBlock: true);
    case 'UNLOCK':
      if (owners[e.target] == e.thread) owners.remove(e.target);
      return t.copyWith(opsDone: t.opsDone + 1);
    default:
      return t.copyWith(opsDone: t.opsDone + 1);
  }
}

// ------------------------------------------------------------------ scene

SceneSpec _threadScene(ThreadSchedState st, int pos, VizSchedule s, String variant, List<String> threads, Map<String, List<VizStep>> ops, Set<int> hazardSteps) {
  final nodes = <SceneNode>[];
  final links = <SceneLink>[];
  final n = threads.length;
  final spacing = 6.2;
  double coreX(int i) => (i - (n - 1) / 2) * spacing;

  final atEnd = pos == s.steps.length && s.steps.isNotEmpty;
  final wrong = atEnd && variant != 'SAFE' && s.expected != null && st.memoryValue != s.expected;
  final lastWrite = st.last != null && st.last!.kind.toUpperCase() == 'WRITE';

  nodes.add(SceneNode(
    id: 'board',
    backdrop: true,
    shape: SceneShape.box,
    position: Vec3(0, -0.15, 1.4),
    size: Vec3(math.max(9, n * spacing + 0.5), 0.3, 10.4),
    color: VizPalette.board,
  ));

  // Shared memory: the one variable every thread touches.
  final memColor = wrong ? AppColors.error : (lastWrite ? AppColors.success : AppColors.accentCyan);
  nodes.add(SceneNode(
    id: 'memory',
    shape: SceneShape.box,
    position: const Vec3(0, 0.55, -3.4),
    size: const Vec3(3.6, 1.1, 2.2),
    color: Color.lerp(VizPalette.plate, memColor, 0.55)!,
    glow: lastWrite || wrong ? 0.9 : 0.35,
    label: st.memoryValue,
    labelSize: 0.9,
    caption: s.expected != null && variant != 'DEADLOCK' ? 'shared ${st.memoryName} (should end at ${s.expected})' : 'shared ${st.memoryName}',
    selectable: true,
    inspect: {
      'What': 'Shared memory: one variable both threads use',
      'Name': st.memoryName,
      'Value now': st.memoryValue,
      if (s.expected != null) 'Should end at': s.expected!,
      'Writes so far': '${st.writes}',
    },
    related: [
      for (final t in threads)
        for (final o in ops[t]!)
          if (o.target == st.memoryName && (o.kind.toUpperCase() == 'READ' || o.kind.toUpperCase() == 'WRITE')) 'op:${o.index}'
    ],
  ));

  // Locks, shown as small gates beside the shared memory.
  final lockNames = {
    for (final t in threads)
      for (final o in ops[t]!)
        if (o.kind.toUpperCase() == 'LOCK') o.target
  }.toList()
    ..sort();
  for (var i = 0; i < lockNames.length; i++) {
    final owner = st.lockOwners[lockNames[i]];
    final ownerIdx = owner == null ? -1 : threads.indexOf(owner);
    final x = (i - (lockNames.length - 1) / 2) * 2.6;
    nodes.add(SceneNode(
      id: 'lock:${lockNames[i]}',
      shape: SceneShape.cylinder,
      position: Vec3(x, 0.35, -1.0),
      size: const Vec3(1.2, 0.7, 1.2),
      color: ownerIdx >= 0 ? VizPalette.thread(ownerIdx) : VizPalette.idle,
      glow: ownerIdx >= 0 ? 0.7 : 0,
      label: owner == null ? 'free' : 'held',
      labelSize: 0.28,
      caption: lockNames[i],
      selectable: true,
      inspect: {'What': 'A lock', 'Name': lockNames[i], 'Held by': owner == null ? 'nobody' : threadLabel(owner)},
    ));
    if (ownerIdx >= 0) {
      links.add(SceneLink(id: 'own:${lockNames[i]}', from: Vec3(x, 0.7, -1.0), to: Vec3(coreX(ownerIdx), 0.9, 0.9), color: VizPalette.thread(ownerIdx), glow: 0.6, width: 2.5));
    }
  }

  for (var ti = 0; ti < n; ti++) {
    final t = threads[ti];
    final run = st.run(t);
    final color = VizPalette.thread(ti);
    final x = coreX(ti);
    final isCurrent = st.last?.thread == t;
    final blocked = run.blockedOn != null;
    nodes.add(SceneNode(
      id: 'core:$t',
      shape: SceneShape.box,
      position: Vec3(x, 0.45, 0.9),
      size: const Vec3(3.2, 0.9, 1.8),
      color: Color.lerp(VizPalette.plate, color, blocked ? 0.25 : 0.7)!,
      glow: isCurrent ? 0.9 : 0.25,
      label: threadLabel(t),
      labelSize: 0.38,
      caption: run.local == null ? 'my copy: -' : 'my copy: ${run.local}',
      selectable: true,
      inspect: {
        'What': 'A thread running on its own core',
        'Private copy': run.local ?? 'nothing read yet',
        'Steps done': '${run.opsDone} of ${run.opsTotal}',
        if (blocked) 'Waiting for': run.blockedOn!,
      },
      related: ['core:$t', for (final o in ops[t]!) 'op:${o.index}'],
    ));
    // The thread's register holds its private copy, so a stale value is visibly stale.
    nodes.add(SceneNode(
      id: 'reg:$t',
      shape: SceneShape.box,
      position: Vec3(x, 1.75, 0.9),
      size: const Vec3(1.0, 0.55, 0.9),
      color: run.local == null ? VizPalette.dim : color,
      glow: isCurrent && st.last!.kind.toUpperCase() == 'READ' ? 0.9 : 0.15,
      label: run.local ?? '',
      labelSize: 0.4,
      opacity: run.local == null ? 0.5 : 1,
    ));

    // The thread's program, nearest the viewer: one slab per operation.
    final list = ops[t]!;
    for (var oi = 0; oi < list.length; oi++) {
      final o = list[oi];
      final done = o.index < pos;
      final current = pos > 0 && s.steps[pos - 1].index == o.index;
      final hazard = hazardSteps.contains(o.index);
      final base = hazard && (done || current) ? AppColors.error : color;
      nodes.add(SceneNode(
        id: 'op:${o.index}',
        shape: SceneShape.box,
        position: Vec3(x, 0.18, 3.3 + oi * 0.95),
        size: const Vec3(3.2, 0.36, 0.82),
        color: current ? base : (done ? Color.lerp(VizPalette.plate, base, 0.55)! : VizPalette.dim),
        glow: current ? 0.95 : (hazard && done ? 0.4 : 0),
        label: _short(o.text, 22),
        labelSize: 0.26,
        labelColor: current || done ? Colors.white : AppColors.textHint,
        selectable: true,
        inspect: {
          'What': 'One step of ${threadLabel(t)}',
          'Code': o.text,
          'Kind': o.kind,
          if (o.line > 0) 'Java line': '${o.line}',
          'Status': current ? 'running now' : (done ? 'finished' : 'not yet'),
          if (hazard) 'Why it matters': variant == 'DEADLOCK' ? 'Part of the wait cycle' : 'Inside the race window: another thread can interleave here',
        },
        related: ['core:$t', 'memory'],
      ));
    }

    // The value packet travels the bus: memory -> core on a read, core -> memory on a write.
    final next = _nextOp(s.steps, pos, t);
    final here = pos > 0 ? s.steps[pos - 1] : null;
    final moving = here != null && here.thread == t && (here.kind.toUpperCase() == 'READ' || here.kind.toUpperCase() == 'WRITE') && here.value != null;
    final coreTop = Vec3(x, 1.0, 2.15);
    const memTop = Vec3(0, 0.95, -1.9);
    final parkedAtMemory = next != null && next.kind.toUpperCase() == 'READ';
    final Vec3 at;
    if (moving) {
      at = here.kind.toUpperCase() == 'READ' ? coreTop : memTop;
    } else {
      at = parkedAtMemory ? memTop : coreTop;
    }
    nodes.add(SceneNode(
      id: 'pkt:$t',
      shape: SceneShape.sphere,
      position: at,
      size: const Vec3(0.75, 0.75, 0.75),
      color: color,
      glow: 1,
      opacity: moving ? 1 : 0,
      label: moving ? here.value : null,
      labelSize: 0.36,
      labelColor: AppColors.onAccent,
    ));
    if (moving) {
      links.add(SceneLink(id: 'bus:$t', from: coreTop, to: memTop, color: color, glow: 0.8, width: 2.5, directed: true, dashed: false));
    }
  }

  return SceneSpec(nodes: nodes, links: links, camera: const CameraHint(yaw: -0.28, pitch: 0.62));
}

VizStep? _nextOp(List<VizStep> steps, int pos, String thread) {
  for (var i = pos; i < steps.length; i++) {
    if (steps[i].thread == thread) return steps[i];
  }
  return null;
}

String _short(String s, int max) => s.length <= max ? s : '${s.substring(0, max - 1)}…';

/// True for lessons built by [threadScheduleLesson]. The lesson screen shows these in its thread simulator and
/// every other lesson in the 3D lab.
bool isThreadScheduleLesson(VizLesson l) => l.id.startsWith(_threadLessonPrefix);
