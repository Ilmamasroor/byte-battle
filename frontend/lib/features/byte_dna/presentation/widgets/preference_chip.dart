import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Single tappable chip used for every choice picker on the ByteDNA
/// Setup form — technical experience, learning style, explanation
/// style (single-select), and each interest inside [InterestSelector]
/// (multi-select). The caller owns the selection state; this widget is
/// purely presentational + a tap callback, same controlled pattern as
/// the rest of the form fields in this app.
class PreferenceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  const PreferenceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm + 2, // 10
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentCyan.withOpacity(0.14)
              : AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: Border.all(
            color: selected ? AppColors.accentCyan : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ??
                  (selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined),
              size: 15,
              color: selected ? AppColors.accentCyan : AppColors.textHint,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyBold.copyWith(
                color: selected ? AppColors.accentCyan : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
