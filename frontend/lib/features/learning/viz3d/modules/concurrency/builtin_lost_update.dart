import '../../../../../core/models/backend_models.dart';

/// The concept id of "Race Conditions" in the shipped curriculum.
const kRaceConditionsConceptId = '00000000-0000-0000-0000-000000001003';

/// The program the authored lesson is about. Line numbers in the steps refer to it.
const kLostUpdateCode = '''public class Counter {
    static int count = 0;

    static void increment() {
        int tmp = count;
        tmp = tmp + 1;
        count = tmp;
    }

    public static void main(String[] args) throws Exception {
        Thread a = new Thread(Counter::increment);
        Thread b = new Thread(Counter::increment);
        a.start();
        b.start();
        a.join();
        b.join();
        System.out.println(count);
    }
}
''';

const _a = 'a', _b = 'b';

/// One scheduled event: which thread runs its next statement. [blocked] marks a thread that tried to take the lock
/// while another held it.
class _Turn {
  final String thread;
  final bool blocked;
  const _Turn(this.thread, {this.blocked = false});
}

class _Op {
  final String kind;
  final String text;
  final int line;
  final bool synthetic;
  const _Op(this.kind, this.text, this.line, {this.synthetic = false});
}

const _plain = [_Op('READ', 'read count', 5), _Op('COMPUTE', 'tmp = tmp + 1', 6), _Op('WRITE', 'count = tmp', 7)];
const _guarded = [
  _Op('LOCK', 'synchronized (lock) {', 5, synthetic: true),
  _Op('READ', 'read count', 5),
  _Op('COMPUTE', 'tmp = tmp + 1', 6),
  _Op('WRITE', 'count = tmp', 7),
  _Op('UNLOCK', '}  // release the lock', 7, synthetic: true),
];

/// Runs [turns] against the program and records what each event did. Values are computed here (the shared count,
/// each thread's private copy), never typed in, so the final count is whatever the interleaving produces.
List<VizStep> _run(List<_Turn> turns, List<_Op> program, {required bool markRaceWindow}) {
  var shared = 0;
  final pc = {_a: 0, _b: 0};
  final copy = <String, int>{};
  final seen = <String, int>{};
  String? holder;
  final out = <VizStep>[];
  for (final t in turns) {
    final i = pc[t.thread]!;
    final op = program[i];
    final id = out.length;
    String? value, local, before;
    var stale = false;
    String? waitingFor;
    switch (op.kind) {
      case 'READ':
        copy[t.thread] = shared;
        seen[t.thread] = shared;
        value = local = '$shared';
      case 'COMPUTE':
        before = '${copy[t.thread]}';
        copy[t.thread] = copy[t.thread]! + 1;
        value = local = '${copy[t.thread]}';
      case 'WRITE':
        before = '$shared';
        stale = seen[t.thread] != shared;
        shared = copy[t.thread]!;
        value = '$shared';
      case 'LOCK':
        if (t.blocked) {
          waitingFor = holder;
        } else {
          holder = t.thread;
        }
      case 'UNLOCK':
        holder = null;
    }
    if (!t.blocked) pc[t.thread] = i + 1;
    out.add(VizStep(
      index: id,
      thread: t.thread,
      kind: op.kind,
      target: op.kind == 'LOCK' || op.kind == 'UNLOCK' ? 'lock' : 'count',
      text: op.text,
      hazard: markRaceWindow && (op.kind == 'READ' || op.kind == 'WRITE'),
      value: value,
      local: local,
      opIndex: i,
      line: op.line,
      blocked: t.blocked,
      waitingFor: waitingFor,
      before: before,
      stale: stale,
      synthetic: op.synthetic,
    ));
  }
  return out;
}

String _finalCount(List<VizStep> steps) => steps.lastWhere((s) => s.kind == 'WRITE').value!;

List<_Turn> _t(String order, {Set<int> blockedAt = const {}}) => [
      for (var i = 0; i < order.length; i++) _Turn(order[i] == 'a' ? _a : _b, blocked: blockedAt.contains(i)),
    ];

/// The lost-update lesson as authored data: two threads each run `count++` as read, calculate, write on a shared
/// counter that starts at 0. Used only when the simulator backend is unreachable, and presented as authored, never
/// as the learner's own program (the lesson's provenance says so).
///
/// RACE is the teaching default (both read, both calculate, A writes, B overwrites), RACE_ALT is the other valid
/// order, SYNC wraps the three statements in one lock. The steps have the same shape the simulator returns.
VisualizationModel builtinLostUpdate() {
  final race = _run(_t('ababab'), _plain, markRaceWindow: true);
  final alt = _run(_t('abbbaa'), _plain, markRaceWindow: true);
  // a locks and reads; b tries the lock and waits; a finishes and unlocks; b then runs the whole block.
  final sync = _run(_t('aabaaabbbbb', blockedAt: {2}), _guarded, markRaceWindow: false);
  // aabaaabbbbb: a LOCK, a READ, b LOCK(blocked), a COMPUTE, a WRITE, a UNLOCK, b LOCK, b READ, b COMPUTE, b WRITE, b UNLOCK
  const threads = [_a, _b];

  return VisualizationModel(
    'Race condition: the lost update',
    kLostUpdateCode,
    [
      VizSchedule('RACE', threads, race, '2', _finalCount(race), label: 'Both read first, then both write'),
      VizSchedule('RACE_ALT', threads, alt, '2', _finalCount(alt), label: "One thread finishes inside the other's gap"),
      VizSchedule('SYNC', threads, sync, '2', _finalCount(sync), label: 'Same threads, read-calculate-write inside synchronized'),
    ],
    const [
      VizHazard(
        'LOST_UPDATE',
        'Both threads read 0 before either wrote, so both calculated 1 and Thread B overwrote Thread A with a value built on stale data. The counter ends at 1, not 2.',
        'Guard read, calculate and write with one lock (or use an atomic counter) so the three steps run as one unit.',
        [0, 1, 4, 5],
      ),
    ],
    'Guard the read-calculate-write with a lock so only one thread is inside at a time.',
    authored: true,
  );
}
