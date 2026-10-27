import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/widgets/glow_card.dart';

/// "Recommended Battles" section: header (icon + title + "View All") and the real battles from GET /api/battles
/// (a loading row while they load, an empty message when there are none).
class DomainSection extends StatelessWidget {
  final VoidCallback? onViewAll;
  final bool isLoading;
  final List<BattleInfo> battles;

  const DomainSection({super.key, this.onViewAll, this.isLoading = false, this.battles = const []});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Recommended battles', style: AppTextStyles.heading2),
              ],
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                children: [
                  Text('View all',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primaryLight),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        if (isLoading && battles.isEmpty)
          const GlowCard(
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                SizedBox(width: 8),
                Text('Loading battles...', style: AppTextStyles.caption),
              ],
            ),
          )
        else if (battles.isEmpty)
          GlowCard(child: Text('No battles available yet.', style: AppTextStyles.caption))
        else
          for (final b in battles)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
              child: GestureDetector(
                onTap: () => Navigator.of(context)
                    .pushNamed(RouteNames.battle, arguments: {'conceptId': b.conceptId, 'boss': b.isBoss}),
                child: GlowCard(
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (b.isBoss ? AppColors.orchid : AppColors.accentCyan).withOpacity(0.16),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                        child: Icon(b.isBoss ? Icons.whatshot_rounded : Icons.bolt_rounded,
                            color: b.isBoss ? AppColors.orchid : AppColors.accentCyan),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.title, style: AppTextStyles.bodyBold),
                            const SizedBox(height: 2),
                            Text(
                              '${b.difficulty} \u2022 ${b.totalQuestions} questions \u2022 ${(b.timeLimitSeconds / 60).round()} min',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
