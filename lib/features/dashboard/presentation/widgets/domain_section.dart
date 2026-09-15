import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';

/// "Recommended Battles" section header (icon + title + "View All") and a
/// loading placeholder card underneath, matching the reference dashboard
/// screenshot's loading state.
class DomainSection extends StatelessWidget {
  final VoidCallback? onViewAll;
  final bool isLoading;

  const DomainSection({super.key, this.onViewAll, this.isLoading = true});

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
                const Icon(Icons.sports_kabaddi_rounded, size: 18, color: AppColors.accentCyan),
                const SizedBox(width: 6),
                Text('Recommended Battles', style: AppTextStyles.heading2),
              ],
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                children: [
                  Text('View All',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.accentCyan, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.accentCyan),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        GlowCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 130,
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 90,
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              if (isLoading) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.accentCyan),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Loading recommended battles...',
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
