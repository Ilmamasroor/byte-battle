import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';

/// Two stat cards side by side: XP & level (gold), and the day streak with this week's strip (flame).
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
    final inLevel = xp % xpTarget;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.hexagon_rounded,
                        size: 18, color: AppColors.xp),
                    const SizedBox(width: 6),
                    Text('XP',
                        style: AppTextStyles.eyebrow
                            .copyWith(color: AppColors.xp)),
                  ]),
                  const SizedBox(height: 10),
                  Text('$xp',
                      style: AppTextStyles.display
                          .copyWith(fontSize: 34, height: 1)),
                  const SizedBox(height: 2),
                  Text('Level $level', style: AppTextStyles.caption),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusPill),
                    child: LinearProgressIndicator(
                      value: inLevel / xpTarget,
                      minHeight: 7,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation(AppColors.xp),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${xpTarget - inLevel} XP to level ${level + 1}',
                      style: AppTextStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 19,
                        color: streakDays > 0
                            ? AppColors.streak
                            : AppColors.textHint),
                    const SizedBox(width: 6),
                    Text('STREAK',
                        style: AppTextStyles.eyebrow.copyWith(
                            color: streakDays > 0
                                ? AppColors.streak
                                : AppColors.textHint)),
                  ]),
                  const SizedBox(height: 10),
                  Text('$streakDays',
                      style: AppTextStyles.display
                          .copyWith(fontSize: 34, height: 1)),
                  const SizedBox(height: 2),
                  Text(streakDays == 1 ? 'day' : 'days',
                      style: AppTextStyles.caption),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final done = i < weekCompleted.length && weekCompleted[i];
                      return Column(children: [
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done ? AppColors.streak : Colors.transparent,
                            border: Border.all(
                                color: done
                                    ? AppColors.streak
                                    : AppColors.borderLight),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_dayLabels[i],
                            style:
                                AppTextStyles.caption.copyWith(fontSize: 10)),
                      ]);
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
