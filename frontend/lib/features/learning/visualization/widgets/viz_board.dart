import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

enum OpStatus { future, current, done }

class BoardOp {
  final String text;
  final String kind; // READ | WRITE | SLEEP | LOCK | UNLOCK | ...
  final bool hazard;
  final OpStatus status;
  const BoardOp({required this.text, required this.kind, required this.hazard, required this.status});
}

class BoardBubble {
  final int opIndex;
  final String text;
  final bool intoMemory; // WRITE flows up into memory, READ flows down from it
  const BoardBubble({required this.opIndex, required this.text, required this.intoMemory});
}

class BoardLane {
  final String name;
  final Color color;
  final List<BoardOp> ops;
  final String? register;
  final BoardBubble? bubble;
  const BoardLane({required this.name, required this.color, required this.ops, this.register, this.bubble});
}

/// The picture at the heart of the visualization: the shared memory cell on top (its value animates, and shakes
/// when a lost update happens) and one lane per thread below it, each lane a little program whose lines light up
/// as they run. A small value bubble flows between a line and the memory when it reads or writes.
class LaneBoard extends StatelessWidget {
  final String memoryName;
  final String memoryValue;
  final String? expected;
  final bool shake;
  final int stepKey;
  final List<BoardLane> lanes;

  const LaneBoard({
    super.key,
    required this.memoryName,
    required this.memoryValue,
    required this.lanes,
    this.expected,
    this.shake = false,
    this.stepKey = 0,
  });

  static const laneColors = [AppColors.primary, AppColors.accentCyan, AppColors.orchid];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MemoryCell(name: memoryName, value: memoryValue, expected: expected, shake: shake, stepKey: stepKey),
        const SizedBox(height: 6),
        CustomPaint(
          size: const Size(double.infinity, 22),
          painter: _FunnelPainter(lanes.length),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < lanes.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _Lane(lane: lanes[i], stepKey: stepKey)),
            ],
          ],
        ),
      ],
    );
  }
}

class _FunnelPainter extends CustomPainter {
  final int n;
  _FunnelPainter(this.n);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final top = Offset(size.width / 2, 0);
    for (var i = 0; i < n; i++) {
      final x = size.width * (i + 0.5) / n;
      final path = Path()
        ..moveTo(top.dx, top.dy)
        ..cubicTo(top.dx, size.height * 0.6, x, size.height * 0.3, x, size.height);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_FunnelPainter old) => old.n != n;
}

class _MemoryCell extends StatelessWidget {
  final String name;
  final String value;
  final String? expected;
  final bool shake;
  final int stepKey;
  const _MemoryCell({required this.name, required this.value, required this.expected, required this.shake, required this.stepKey});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('mem_$stepKey$shake'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(shake ? math.sin(t * math.pi * 7) * 7 * (1 - t) : 0, 0),
        child: child,
      ),
      child: Container(
        width: 190,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: shake ? AppColors.error : AppColors.primary, width: 2),
          boxShadow: [BoxShadow(color: (shake ? AppColors.error : AppColors.primary).withOpacity(0.28), blurRadius: 26, spreadRadius: -6)],
        ),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.memory_rounded, size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Flexible(child: Text('SHARED MEMORY', overflow: TextOverflow.ellipsis, style: AppTextStyles.eyebrow.copyWith(fontSize: 10))),
            ]),
            const SizedBox(height: 4),
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$name = ', style: AppTextStyles.code.copyWith(color: AppColors.textSecondary, fontSize: 15)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                      child:
                          Text(value, key: ValueKey(value), style: AppTextStyles.display.copyWith(fontSize: 38, height: 1, color: shake ? AppColors.error : AppColors.textPrimary)),
                    ),
                  ],
                )),
            if (expected != null) ...[
              const SizedBox(height: 4),
              Text('should end at $expected', style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Lane extends StatelessWidget {
  final BoardLane lane;
  final int stepKey;
  const _Lane({required this.lane, required this.stepKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: lane.color.withOpacity(0.16),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: lane.color.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Icon(Icons.account_tree_rounded, size: 16, color: lane.color),
              const SizedBox(width: 6),
              Expanded(child: Text(lane.name, style: AppTextStyles.bodyBold.copyWith(fontSize: 12.5, color: lane.color), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
          child: Text(lane.register ?? 'my copy: –', style: AppTextStyles.code.copyWith(fontSize: 11.5, color: lane.register == null ? AppColors.textHint : AppColors.xp)),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < lane.ops.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OpTile(
              op: lane.ops[i],
              color: lane.color,
              bubble: lane.bubble != null && lane.bubble!.opIndex == i ? lane.bubble : null,
              stepKey: stepKey,
            ),
          ),
      ],
    );
  }
}

class _OpTile extends StatelessWidget {
  final BoardOp op;
  final Color color;
  final BoardBubble? bubble;
  final int stepKey;
  const _OpTile({required this.op, required this.color, required this.bubble, required this.stepKey});

  IconData get _icon {
    switch (op.kind.toUpperCase()) {
      case 'READ':
        return Icons.download_rounded;
      case 'WRITE':
        return Icons.upload_rounded;
      case 'SLEEP':
        return Icons.bedtime_rounded;
      case 'LOCK':
        return Icons.lock_rounded;
      case 'UNLOCK':
        return Icons.lock_open_rounded;
      default:
        return Icons.play_arrow_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = op.status == OpStatus.current;
    final done = op.status == OpStatus.done;
    final accent = op.hazard && (current || done) ? AppColors.error : color;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 56,
          transform: Matrix4.identity()..scale(current ? 1.03 : 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: current ? accent.withOpacity(0.2) : (done ? accent.withOpacity(0.08) : AppColors.surface.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: current ? accent : (done ? accent.withOpacity(0.35) : AppColors.border), width: current ? 2 : 1),
            boxShadow: current ? [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 18, spreadRadius: -4)] : null,
          ),
          child: Row(
            children: [
              Icon(done ? Icons.check_circle_rounded : _icon, size: 18, color: current || done ? accent : AppColors.textHint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  op.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.code.copyWith(fontSize: 11.5, height: 1.3, color: current ? AppColors.textPrimary : (done ? AppColors.textSecondary : AppColors.textHint)),
                ),
              ),
            ],
          ),
        ),
        if (bubble != null)
          Positioned(
            right: 6,
            top: 0,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('b_$stepKey'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, t, _) {
                final travel = bubble!.intoMemory ? t : 1 - t;
                return Opacity(
                  opacity: (bubble!.intoMemory ? (1 - t * 0.6) : (0.4 + t * 0.6)).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, -34 - 70 * travel),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.xp, borderRadius: BorderRadius.circular(100)),
                      child: Text(bubble!.text, style: AppTextStyles.code.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.onAccent)),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
