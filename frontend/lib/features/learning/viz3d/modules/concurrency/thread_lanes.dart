import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_text_styles.dart';
import '../../../../../core/models/backend_models.dart';
import '../../contract/viz_contract.dart';
import '../../engine/playback_controller.dart';
import '../viz_palette.dart';
import 'thread_schedule_lesson.dart';

/// The default picture for thread lessons: shared memory on top and one lane per thread below it, each lane the
/// thread's own statements in order. The statement that just ran is lit, the value it moved is shown, and each
/// thread's private copy sits beside shared memory so a stale copy is visible as stale.
///
/// It draws whatever the [timeline]'s state says at the controller's position and nothing else, so it always agrees
/// with the timeline strip, the source highlight and the captions. Tapping a statement seeks to the event that ran it.
class ThreadLanes extends StatelessWidget {
  final ReducerTimeline<ThreadSchedState, VizStep> timeline;
  final VizPlaybackController controller;

  /// The program's source lines; a statement shows its real Java line when there is one.
  final List<String> code;
  final String? expected;

  const ThreadLanes({super.key, required this.timeline, required this.controller, this.code = const [], this.expected});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pos = controller.position.clamp(0, timeline.length - 1);
        final st = timeline.stateAt(pos);
        final threads = timeline.actors;
        final events = timeline.events;
        final atEnd = pos == timeline.length - 1 && events.isNotEmpty;
        final lost = atEnd && expected != null && st.memoryValue != expected && events.any((e) => e.stale);
        return Column(children: [
          _MemoryCell(state: st, expected: expected, lost: lost, reduce: reduce),
          if (st.lockOwners.isNotEmpty || events.any((e) => e.kind == 'LOCK')) _LockBar(state: st, events: events),
          const SizedBox(height: 6),
          CustomPaint(size: const Size(double.infinity, 18), painter: _Funnel(threads.length)),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < threads.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _Lane(
                  index: i,
                  run: st.run(threads[i]),
                  memory: st.memoryValue,
                  ops: [for (final e in events) if (e.thread == threads[i] && !_retried(e, events)) e],
                  pos: pos,
                  code: code,
                  current: st.last,
                  reduce: reduce,
                  onSeek: controller.seek,
                ),
              ),
            ],
          ]),
        ]);
      },
    );
  }

  static bool _retried(VizStep e, List<VizStep> all) => e.blocked && all.any((o) => o.thread == e.thread && o.opIndex == e.opIndex && !o.blocked);
}

class _Funnel extends CustomPainter {
  final int n;
  _Funnel(this.n);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < n; i++) {
      final p = Paint()
        ..color = VizPalette.thread(i).withOpacity(0.55)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      final x = size.width * (i + 0.5) / n;
      canvas.drawPath(
          Path()
            ..moveTo(size.width / 2, 0)
            ..cubicTo(size.width / 2, size.height * 0.6, x, size.height * 0.3, x, size.height),
          p);
    }
  }

  @override
  bool shouldRepaint(_Funnel old) => old.n != n;
}

class _MemoryCell extends StatelessWidget {
  final ThreadSchedState state;
  final String? expected;
  final bool lost;
  final bool reduce;
  const _MemoryCell({required this.state, required this.expected, required this.lost, required this.reduce});

  @override
  Widget build(BuildContext context) {
    final last = state.last;
    final writing = last != null && last.kind.toUpperCase() == 'WRITE';
    final color = lost ? AppColors.error : (writing ? AppColors.success : AppColors.primary);
    final prev = writing ? (last.before ?? state.memoryBefore) : null;
    return Semantics(
      container: true,
      label: 'Shared memory: ${state.memoryName} is ${state.memoryValue}${expected == null ? '' : ', should end at $expected'}${writing && prev != null ? ', it was $prev before this write' : ''}',
      child: AnimatedContainer(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 260),
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 22, spreadRadius: -6)],
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.memory_rounded, size: 14, color: AppColors.textHint),
            const SizedBox(width: 6),
            Text('SHARED MEMORY', style: AppTextStyles.eyebrow.copyWith(fontSize: 10)),
          ]),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('${state.memoryName} = ', style: AppTextStyles.code.copyWith(color: AppColors.textSecondary, fontSize: 15)),
            AnimatedSwitcher(
              duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
              child: Text(state.memoryValue, key: ValueKey(state.memoryValue), style: AppTextStyles.display.copyWith(fontSize: 36, height: 1, color: lost ? AppColors.error : AppColors.textPrimary)),
            ),
          ])),
          if (writing && prev != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(prev == state.memoryValue ? 'was $prev: nothing new was added' : 'was $prev', style: AppTextStyles.caption.copyWith(color: lost || prev == state.memoryValue ? AppColors.error : AppColors.textSecondary, fontSize: 11)),
            ),
          if (expected != null) Text('should end at $expected', style: AppTextStyles.caption.copyWith(fontSize: 11)),
        ]),
      ),
    );
  }
}

class _LockBar extends StatelessWidget {
  final ThreadSchedState state;
  final List<VizStep> events;
  const _LockBar({required this.state, required this.events});

  @override
  Widget build(BuildContext context) {
    final names = {for (final e in events) if (e.kind == 'LOCK') e.target}.toList()..sort();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 8, children: [
        for (final n in names)
          Builder(builder: (context) {
            final owner = state.lockOwners[n];
            final idx = owner == null ? -1 : state.threads.indexWhere((t) => t.name == owner);
            final color = idx >= 0 ? VizPalette.thread(idx) : AppColors.textHint;
            return Semantics(
              label: owner == null ? 'Lock $n is free' : 'Lock $n is held by ${threadLabel(owner)}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(100), border: Border.all(color: color)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(owner == null ? Icons.lock_open_rounded : Icons.lock_rounded, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(owner == null ? '$n: free' : '$n: held by ${threadLabel(owner)}', style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
                ]),
              ),
            );
          }),
      ]),
    );
  }
}

class _Lane extends StatelessWidget {
  final int index;
  final ThreadRun run;
  final String memory;
  final List<VizStep> ops;
  final int pos;
  final List<String> code;
  final VizStep? current;
  final bool reduce;
  final ValueChanged<int> onSeek;
  const _Lane({required this.index, required this.run, required this.memory, required this.ops, required this.pos, required this.code, required this.current, required this.reduce, required this.onSeek});

  @override
  Widget build(BuildContext context) {
    final color = VizPalette.thread(index);
    final isActive = current?.thread == run.name;
    final stale = run.outOfDate(memory);
    final nextOp = ops.where((o) => o.index + 1 > pos).firstOrNull; // the statement this thread is about to run
    // A blocked attempt is not its own statement: it is this thread standing at the lock statement it will run later.
    final attempt = current != null && current!.thread == run.name && current!.blocked ? current : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AnimatedContainer(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(isActive ? 0.26 : 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(isActive ? 1 : 0.5), width: isActive ? 2 : 1),
        ),
        child: Row(children: [
          Icon(isActive ? Icons.play_arrow_rounded : Icons.account_tree_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(threadLabel(run.name), style: AppTextStyles.bodyBold.copyWith(fontSize: 12.5, color: color), overflow: TextOverflow.ellipsis)),
          if (run.blockedOn != null)
            Text('waiting', style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontSize: 10))
          else if (isActive)
            Text('running', style: AppTextStyles.caption.copyWith(color: color, fontSize: 10)),
        ]),
      ),
      const SizedBox(height: 6),
      Semantics(
        label: run.local == null ? '${threadLabel(run.name)} has no private copy yet' : '${threadLabel(run.name)} private copy is ${run.local}${stale ? ', out of date: shared memory is now $memory' : ''}',
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(10),
            border: stale ? Border.all(color: AppColors.warning) : null,
          ),
          child: Column(children: [
            Text(run.local == null ? 'my copy: –' : 'my copy: ${run.local}', style: AppTextStyles.code.copyWith(fontSize: 12, color: run.local == null ? AppColors.textHint : AppColors.xp)),
            if (stale) Text('read ${run.readValue}, shared is now $memory', style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.warning), textAlign: TextAlign.center),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      for (final e in ops)
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: _Statement(
            event: e,
            color: color,
            threadName: threadLabel(run.name),
            status: e.index + 1 == pos || (attempt != null && e.opIndex == attempt.opIndex && e.index + 1 > pos)
                ? _Status.current
                : (e.index + 1 < pos ? _Status.done : _Status.future),
            attempt: attempt != null && e.opIndex == attempt.opIndex && e.index + 1 > pos,
            text: _text(e),
            reduce: reduce,
            waiting: run.blockedOn != null && e.kind == 'LOCK' && identical(e, nextOp),
            onTap: () => onSeek(e.index + 1),
          ),
        ),
    ]);
  }

  /// The statement as the learner wrote it. Where one source line does two things (`count = tmp + 1` both
  /// calculates and writes) the step's own text is shown instead, so the two events stay distinguishable. The
  /// synchronized lines the fix adds are not in the learner's code, so they use the step's text too.
  String _text(VizStep e) {
    final inRange = e.line > 0 && e.line <= code.length;
    if (!inRange || e.synthetic) return e.text;
    final shared = ops.any((o) => o != e && o.line == e.line && !o.synthetic);
    final src = code[e.line - 1].trim();
    return shared || src.isEmpty ? e.text : src;
  }
}

enum _Status { future, current, done }

class _Statement extends StatelessWidget {
  final VizStep event;
  final Color color;
  final String threadName;
  final _Status status;
  final String text;
  final bool reduce;
  final bool waiting;
  final bool attempt; // the thread is blocked at this statement right now
  final VoidCallback onTap;
  const _Statement(
      {required this.event, required this.color, required this.threadName, required this.status, required this.text, required this.reduce, required this.waiting, required this.attempt, required this.onTap});

  IconData get _icon => switch (event.kind.toUpperCase()) {
        'READ' => Icons.download_rounded,
        'WRITE' => Icons.upload_rounded,
        'COMPUTE' => Icons.calculate_rounded,
        'SLEEP' => Icons.bedtime_rounded,
        'LOCK' => Icons.lock_rounded,
        'UNLOCK' => Icons.lock_open_rounded,
        _ => Icons.play_arrow_rounded,
      };

  String get _kindLabel => switch (event.kind.toUpperCase()) {
        'COMPUTE' => 'calculate',
        final k => k.toLowerCase(),
      };

  @override
  Widget build(BuildContext context) {
    final current = status == _Status.current;
    final done = status == _Status.done;
    final lostHere = event.stale && (current || done);
    final accent = lostHere ? AppColors.error : (waiting || attempt ? AppColors.warning : color);
    // What this event moved, shown on the statement itself while it is the current one.
    String? moved;
    if (attempt) moved = 'waiting for the lock';
    if (current && !attempt) {
      final k = event.kind.toUpperCase();
      if (k == 'READ') moved = 'read ${event.value}';
      if (k == 'COMPUTE') moved = '${event.before} → ${event.value}';
      if (k == 'WRITE') moved = event.stale ? 'wrote ${event.value} (stale)' : 'wrote ${event.value}';
    }
    return Semantics(
      button: true,
      label: '$threadName, ${_kindLabel}: $text, ${current ? 'running now' : (done ? 'finished' : 'not yet run')}${attempt ? ', waiting for the lock' : ''}${lostHere ? ', this is where the update is lost' : ''}. Select this event.',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            color: current ? accent.withOpacity(0.2) : (done ? accent.withOpacity(0.08) : AppColors.surface.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: current ? accent : (done ? accent.withOpacity(0.35) : AppColors.border), width: current ? 2 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(done ? Icons.check_circle_rounded : _icon, size: 16, color: current || done ? accent : AppColors.textHint),
              const SizedBox(width: 6),
              Text(_kindLabel.toUpperCase(), style: AppTextStyles.eyebrow.copyWith(fontSize: 9, color: current ? accent : AppColors.textHint)),
              const Spacer(),
              if (event.line > 0 && !event.synthetic) Text('L${event.line}', style: AppTextStyles.caption.copyWith(fontSize: 10)),
              if (event.synthetic) Text('added', style: AppTextStyles.caption.copyWith(fontSize: 10)),
            ]),
            const SizedBox(height: 3),
            Text(text, style: AppTextStyles.code.copyWith(fontSize: 11.5, height: 1.3, color: current ? AppColors.textPrimary : (done ? AppColors.textSecondary : AppColors.textHint))),
            if (moved != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.xp, borderRadius: BorderRadius.circular(100)),
                  child: Text(moved, style: AppTextStyles.code.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.onAccent)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
