import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

class BattleHeader extends StatelessWidget {
  final String title;
  final double progress;
  final String scoreLabel;

  const BattleHeader({
    super.key,
    required this.title,
    required this.progress,
    required this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.heading2),
            Text(scoreLabel, style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight)),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
