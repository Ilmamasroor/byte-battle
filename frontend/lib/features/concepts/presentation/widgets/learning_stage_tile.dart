import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// A single "What You'll Learn" grid tile on the concept overview
/// screen — an icon badge, a short title and a one-line description.
class LearningStageTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const LearningStageTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, size: 16, color: AppColors.accentCyan),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(title, style: AppTextStyles.bodyBold),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
