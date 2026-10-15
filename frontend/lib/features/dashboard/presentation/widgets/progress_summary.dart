import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';

/// Side-by-side "XP & Level" and "Day Streak" stat cards on the dashboard,
/// matching the reference dashboard screenshot.
class ProgressSummary extends StatelessWidget {
  final int xp;
  final int xpTarget;
  final int level;
  final int streakDays;
  final List<bool> weekCompleted; // 7 entries, Mon..Sun

  const ProgressSummary({
    super.key,
    required this.xp,
    required this.xpTarget,
    required this.level,
    required this.streakDays,
    required this.weekCompleted,
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: AppColors.accentCyan,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.hexagon_outlined,
                            size: 15, color: AppColors.accentCyan),
                      ),
                      const SizedBox(width: 8),
                      Text('XP & LEVEL',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textHint, letterSpacing: 0.4)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('$xp XP', style: AppTextStyles.heading2),
                  const SizedBox(height: 2),
                  Text('Level $level', style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    child: LinearProgressIndicator(
                      value: (xp % xpTarget) / xpTarget,
                      minHeight: 6,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation(AppColors.accentCyan),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${xp % xpTarget} / $xpTarget XP', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            const VerticalDivider(color: AppColors.divider, width: 1),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('$streakDays DAY STREAK',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Keep it going!', style: AppTextStyles.caption),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final done = i < weekCompleted.length && weekCompleted[i];
                      return Column(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done
                                  ? AppColors.accentCyan
                                  : AppColors.background.withOpacity(0.6),
                              border: Border.all(
                                color: done ? AppColors.accentCyan : AppColors.border,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_dayLabels[i], style: AppTextStyles.caption),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
