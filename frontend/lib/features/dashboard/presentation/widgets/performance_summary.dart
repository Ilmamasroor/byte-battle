import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';

/// "Your Byte DNA": a radar of the four skills (a shape that is uniquely yours) with the numbers beneath it.
class PerformanceSummary extends StatelessWidget {
  /// `null` = no evidence yet (the learner has not done that activity).
  final Map<String, double?> skills;
  final VoidCallback? onTap;

  const PerformanceSummary({super.key, required this.skills, this.onTap});

  static const _colors = {
    'Understanding': AppColors.accentCyan,
    'Application': AppColors.primary,
    'Debugging': AppColors.orchid,
    'Communication': AppColors.xp,
  };

  @override
  Widget build(BuildContext context) {
    final labels = skills.keys.toList();
    final values = skills.values.map((v) => v ?? 0.0).toList();
    final hasAny = skills.values.any((v) => v != null);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: GlowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('YOUR BYTE DNA', style: AppTextStyles.eyebrow.copyWith(color: AppColors.orchid)),
                const Spacer(),
                if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(hasAny ? 'The shape of how you learn' : 'Finish a battle or challenge to draw your shape',
                style: AppTextStyles.heading2),
            const SizedBox(height: AppDimensions.spacingMd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 128,
                  height: 128,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => CustomPaint(painter: _RadarPainter(values, t, hasAny)),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    children: [
                      for (final l in labels)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(color: _colors[l] ?? AppColors.primary, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(l, style: AppTextStyles.body.copyWith(fontSize: 12.5))),
                              Text(
                                skills[l] == null ? '–' : '${(skills[l]! * 100).round()}%',
                                style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final double t;
  final bool hasData;
  _RadarPainter(this.values, this.t, this.hasData);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6;
    final n = values.length;
    Offset point(int i, double f) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      return c + Offset(math.cos(a), math.sin(a)) * r * f;
    }

    final grid = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final f in [0.33, 0.66, 1.0]) {
      final p = Path()..moveTo(point(0, f).dx, point(0, f).dy);
      for (var i = 1; i < n; i++) {
        p.lineTo(point(i, f).dx, point(i, f).dy);
      }
      p.close();
      canvas.drawPath(p, grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, point(i, 1), grid);
    }

    final shape = Path();
    for (var i = 0; i < n; i++) {
      final f = (hasData ? values[i].clamp(0.06, 1.0) : 0.06) * t;
      final p = point(i, f);
      i == 0 ? shape.moveTo(p.dx, p.dy) : shape.lineTo(p.dx, p.dy);
    }
    shape.close();
    canvas.drawPath(shape, Paint()..color = AppColors.primary.withOpacity(0.22));
    canvas.drawPath(
      shape,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < n; i++) {
      final f = (hasData ? values[i].clamp(0.06, 1.0) : 0.06) * t;
      canvas.drawCircle(point(i, f), 3.5, Paint()..color = AppColors.textPrimary);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t || old.values != values;
}
