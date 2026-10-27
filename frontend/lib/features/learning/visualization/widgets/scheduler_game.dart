import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/widgets/ai/companion_says.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';
import '../../../../core/widgets/brand/confetti.dart';
import 'viz_board.dart';

/// "You are the scheduler": the learner decides which thread runs its next line. The lines are the ones the
/// backend extracted from the real code; this widget runs them with a tiny interpreter (READ copies the shared
/// value into the thread's private copy, WRITE stores private + delta back), so every order the learner picks is
/// really executed. Goal: find an order that loses an update.
class SchedulerGame extends StatefulWidget {
  final VizSchedule schedule;
  const SchedulerGame({super.key, required this.schedule});

  /// True when the schedule is simple enough to simulate: each thread only READs / WRITEs / SLEEPs and every
  /// WRITE is "current +/- n".
  static bool supports(VizSchedule s) {
    if (s.steps.isEmpty) return false;
    final re = RegExp(r'current\s*([+-])\s*(\d+)');
    var hasWrite = false;
    for (final st in s.steps) {
      final k = st.kind.toUpperCase();
      if (k == 'WRITE') {
        hasWrite = true;
        if (!re.hasMatch(st.text)) return false;
      } else if (k != 'READ' && k != 'SLEEP') {
        return false;
      }
    }
    return hasWrite && s.steps.any((e) => e.kind.toUpperCase() == 'READ' && int.tryParse(e.value ?? '') != null);
  }

  @override
  State<SchedulerGame> createState() => _SchedulerGameState();
}

class _SchedulerGameState extends State<SchedulerGame> {
  late List<String> _threads;
  late Map<String, List<VizStep>> _ops;
  late int _initial;
  late String _target;
  late int _expected;

  final Map<String, int> _pc = {};
  final Map<String, int?> _local = {};
  int _shared = 0;
  int _lastIndexKey = 0;
  (String, int)? _last; // (thread, op index) just executed
  String _lastValue = '';
  bool _lastWasWrite = false;
  int _wins = 0;
  int _confetti = 0;
  bool _countedThisRun = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final s = widget.schedule;
    _threads = s.threads.isNotEmpty ? s.threads : (s.steps.map((e) => e.thread).toSet().toList()..sort());
    _ops = {for (final t in _threads) t: (s.steps.where((e) => e.thread == t).toList()..sort((a, b) => a.opIndex.compareTo(b.opIndex)))};
    final firstRead = s.steps.firstWhere((e) => e.kind.toUpperCase() == 'READ' && int.tryParse(e.value ?? '') != null);
    _initial = int.parse(firstRead.value!);
    _target = firstRead.target.isEmpty ? 'count' : firstRead.target;
    var exp = _initial;
    for (final t in _threads) {
      exp += _delta(_ops[t]!);
    }
    _expected = exp;
    _reset();
  }

  int _delta(List<VizStep> ops) {
    final re = RegExp(r'current\s*([+-])\s*(\d+)');
    var d = 0;
    for (final o in ops) {
      if (o.kind.toUpperCase() != 'WRITE') continue;
      final m = re.firstMatch(o.text);
      if (m != null) d += (m.group(1) == '-' ? -1 : 1) * int.parse(m.group(2)!);
    }
    return d;
  }

  void _reset() {
    setState(() {
      for (final t in _threads) {
        _pc[t] = 0;
        _local[t] = null;
      }
      _shared = _initial;
      _last = null;
      _countedThisRun = false;
      _lastIndexKey++;
    });
  }

  bool get _finished => _threads.every((t) => _pc[t]! >= _ops[t]!.length);

  void _run(String t) {
    final ops = _ops[t]!;
    final op = ops[_pc[t]!];
    final k = op.kind.toUpperCase();
    setState(() {
      if (k == 'READ') {
        _local[t] = _shared;
        _lastValue = '$_shared';
        _lastWasWrite = false;
      } else if (k == 'WRITE') {
        final m = RegExp(r'current\s*([+-])\s*(\d+)').firstMatch(op.text)!;
        final d = (m.group(1) == '-' ? -1 : 1) * int.parse(m.group(2)!);
        _shared = (_local[t] ?? _shared) + d;
        _lastValue = '$_shared';
        _lastWasWrite = true;
      } else {
        _lastValue = '';
      }
      _last = (t, _pc[t]!);
      _pc[t] = _pc[t]! + 1;
      _lastIndexKey++;
      if (_finished && !_countedThisRun) {
        _countedThisRun = true;
        if (_shared != _expected) {
          _wins++;
          _confetti++;
        }
      }
    });
  }

  String _label(String t) {
    final m = RegExp(r'(\d+)').firstMatch(t);
    return m == null ? t : 'Thread ${m.group(1)}';
  }

  String get _says {
    if (_finished) {
      return _shared != _expected
          ? 'BOOM. Lost update! $_target ended at $_shared but should be $_expected. You just caused a real race condition.'
          : 'Correct this time ($_target = $_shared), but that order was lucky. Reset and let both threads READ before either WRITES.';
    }
    final started = _threads.any((t) => _pc[t]! > 0);
    if (!started) return 'You are the scheduler now. You pick who runs next. Can you make $_target come out wrong?';
    final readers = _threads.where((t) => _local[t] != null && _pc[t]! < _ops[t]!.length).length;
    if (readers >= 2) return 'Both threads are holding the same old number. Now let them write, and watch what happens.';
    return 'Nice. Now, what if the OTHER thread jumps in before this one writes?';
  }

  BitMood get _mood => _finished ? (_shared != _expected ? BitMood.cheer : BitMood.curious) : BitMood.curious;

  @override
  Widget build(BuildContext context) {
    final lanes = <BoardLane>[];
    for (var i = 0; i < _threads.length; i++) {
      final t = _threads[i];
      final ops = _ops[t]!;
      lanes.add(BoardLane(
        name: _label(t),
        color: LaneBoard.laneColors[i % LaneBoard.laneColors.length],
        register: _local[t] == null ? null : 'my copy: ${_local[t]}',
        ops: [
          for (var k = 0; k < ops.length; k++)
            BoardOp(
              text: ops[k].text,
              kind: ops[k].kind,
              hazard: false,
              status: _last != null && _last!.$1 == t && _last!.$2 == k ? OpStatus.current : (k < _pc[t]! ? OpStatus.done : OpStatus.future),
            ),
        ],
        bubble: _last != null && _last!.$1 == t && _lastValue.isNotEmpty ? BoardBubble(opIndex: _last!.$2, text: _lastValue, intoMemory: _lastWasWrite) : null,
      ));
    }
    final wrong = _finished && _shared != _expected;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompanionSays(speak: true, text: _says, mood: _mood),
            const SizedBox(height: AppDimensions.spacingMd),
            LaneBoard(
              memoryName: _target,
              memoryValue: '$_shared',
              expected: '$_expected',
              shake: wrong,
              stepKey: _lastIndexKey,
              lanes: lanes,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            if (!_finished)
              for (var i = 0; i < _threads.length; i++)
                if (_pc[_threads[i]]! < _ops[_threads[i]]!.length)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RunButton(
                      color: LaneBoard.laneColors[i % LaneBoard.laneColors.length],
                      title: 'Run next line of ${_label(_threads[i])}',
                      line: _ops[_threads[i]]![_pc[_threads[i]]!].text,
                      onTap: () => _run(_threads[i]),
                    ),
                  ),
            if (_finished)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                decoration: BoxDecoration(
                  color: (wrong ? AppColors.xp : AppColors.success).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: wrong ? AppColors.xp : AppColors.success),
                ),
                child: Row(children: [
                  Icon(wrong ? Icons.emoji_events_rounded : Icons.check_circle_rounded, color: wrong ? AppColors.xp : AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      wrong ? 'Race found! Final $_target = $_shared (expected $_expected).' : 'Final $_target = $_shared. No race this time.',
                      style: AppTextStyles.bodyBold,
                    ),
                  ),
                ]),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.restart_alt_rounded, size: 18), label: const Text('Reset')),
                const Spacer(),
                Icon(Icons.bug_report_rounded, size: 18, color: _wins > 0 ? AppColors.xp : AppColors.textHint),
                const SizedBox(width: 6),
                Text('Races caused: $_wins', style: AppTextStyles.bodyBold.copyWith(color: _wins > 0 ? AppColors.xp : AppColors.textHint)),
              ],
            ),
          ],
        ),
        Positioned.fill(child: ConfettiBurst(trigger: _confetti)),
      ],
    );
  }
}

class _RunButton extends StatelessWidget {
  final Color color;
  final String title;
  final String line;
  final VoidCallback onTap;
  const _RunButton({required this.color, required this.title, required this.line, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.14),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), border: Border.all(color: color.withOpacity(0.7), width: 1.4)),
          child: Row(children: [
            Icon(Icons.play_circle_fill_rounded, color: color, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(line, style: AppTextStyles.code.copyWith(fontSize: 11.5, color: AppColors.textSecondary)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
