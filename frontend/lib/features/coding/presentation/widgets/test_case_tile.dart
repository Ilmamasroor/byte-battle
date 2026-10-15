import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// A single row in the coding submission result list —
/// "Test Case 1 ✔" / "Edge Case 1 ✘".
class TestCaseTile extends StatelessWidget {
  final String label;
  final bool passed;

  const TestCaseTile({super.key, required this.label, required this.passed});

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.success : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyBold),
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }
}
