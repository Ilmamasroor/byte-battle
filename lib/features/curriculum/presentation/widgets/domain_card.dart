import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';

/// One top-level curriculum domain (Java, Backend Development, DSA...)
/// on [DomainListScreen] — icon, name, topic-count subtitle and a
/// progress bar, in the app's shared [GlowCard] look. Tapping opens
/// [RouteNames.topicList] for this domain (handled by the caller via
/// [onTap], same controlled pattern as the rest of the app's cards).
class DomainCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final int topicCount;
  final double progress; // 0.0 - 1.0
  final bool highlighted;
  final VoidCallback? onTap;

  const DomainCard({
    super.key,
    required this.icon,
    required this.name,
    required this.topicCount,
    required this.progress,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: GlowCard(
        glowColor: highlighted ? AppColors.accentCyan : AppColors.primaryLight,
        borderColor: highlighted ? AppColors.accentCyan : AppColors.borderLight,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Icon(icon, color: AppColors.accentCyan, size: 22),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 4),
                  Text('$topicCount topics', style: AppTextStyles.caption),
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
