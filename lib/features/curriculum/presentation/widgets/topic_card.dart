import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/difficulty_badge.dart';
import '../../../../core/widgets/glow_card.dart';

/// One topic within a domain (e.g. "Collections" under "Java") on
/// [TopicListScreen] — name, a [DifficultyBadge] and a progress bar,
/// in the app's shared [GlowCard] look.
class TopicCard extends StatelessWidget {
  final String name;
  final String difficulty;
  final double progress; // 0.0 - 1.0
  final VoidCallback? onTap;

  const TopicCard({
    super.key,
    required this.name,
    required this.difficulty,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: GlowCard(
        glowColor: AppColors.btnAccentPurple,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: AppTextStyles.bodyBold)),
                      DifficultyBadge(level: difficulty),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.background,
                            valueColor: const AlwaysStoppedAnimation(AppColors.accentCyan),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(progress * 100).round()}%', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
