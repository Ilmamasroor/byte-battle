import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Renders a row of number boxes representing an array, highlighting
/// left/right bounds and the current mid pointer — used by the
/// Explore visualization and the Challenge/Battle screens.
class ConceptVisualizer extends StatelessWidget {
  final List<int> values;
  final int left;
  final int right;
  final int mid;

  const ConceptVisualizer({
    super.key,
    required this.values,
    required this.left,
    required this.right,
    required this.mid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(values.length, (index) {
            final inRange = index >= left && index <= right;
            final isMid = index == mid;
            return Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isMid
                    ? AppColors.primary
                    : (inRange ? AppColors.surface : AppColors.background),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(
                  color: isMid
                      ? AppColors.primary
                      : (inRange ? AppColors.success : AppColors.border),
                ),
              ),
              child: Text(
                '${values[index]}',
                style: AppTextStyles.bodyBold.copyWith(
                  color: inRange || isMid ? AppColors.textPrimary : AppColors.textHint,
                  fontSize: 13,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text('mid', style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight)),
      ],
    );
  }
}
