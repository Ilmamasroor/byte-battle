import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/buttons/buttons.dart';

class ContinueLearningCard extends StatelessWidget {
  final String conceptName;
  final String stageLabel;
  final double progress;
  final VoidCallback onContinue;

  const ContinueLearningCard({
    super.key,
    required this.conceptName,
    required this.stageLabel,
    required this.progress,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conceptName, style: AppTextStyles.heading2),
                const SizedBox(height: 4),
                Text(stageLabel, style: AppTextStyles.caption),
                const SizedBox(height: AppDimensions.spacingSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          NavigationButton(
            label: 'Continue',
            onPressed: onContinue,
            size: AppButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
