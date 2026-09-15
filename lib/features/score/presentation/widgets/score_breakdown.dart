import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// One labeled metric row with a colored progress bar and a "xx/100"
/// value, e.g. "Concept Understanding — 92/100".
class ScoreBreakdown extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;

  const ScoreBreakdown({
    super.key,
    required this.label,
    required this.value,
    this.max = 100,
    this.color = AppColors.success,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.body),
              Text('$value/$max',
                  style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: LinearProgressIndicator(
              value: value / max,
              minHeight: 6,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
