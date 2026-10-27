import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

class ConceptMiniCard extends StatelessWidget {
  final String name;
  final double mastery; // 0.0 - 1.0
  final VoidCallback? onTap;

  const ConceptMiniCard({
    super.key,
    required this.name,
    required this.mastery,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppTextStyles.bodyBold),
            const SizedBox(height: 6),
            Text('Mastery ${(mastery * 100).round()}%', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              child: LinearProgressIndicator(
                value: mastery,
                minHeight: 4,
                backgroundColor: AppColors.background,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
