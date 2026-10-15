import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// One row in the "Test Results" list on the Debug Result panel —
/// "Test 1 ... Passed" with a check icon, matching the reference
/// screenshot.
class DebugResultCard extends StatelessWidget {
  final String label;
  final bool passed;
  final bool showDivider;

  const DebugResultCard({
    super.key,
    required this.label,
    this.passed = true,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.success : AppColors.error;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
          child: Row(
            children: [
              Icon(
                passed ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                color: color,
                size: 18,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(child: Text(label, style: AppTextStyles.bodyBold)),
              Text(
                passed ? 'Passed' : 'Failed',
                style: AppTextStyles.bodyBold.copyWith(color: color),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(color: AppColors.divider, height: 1),
      ],
    );
  }
}
