import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

class BattleOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const BattleOption({
    super.key,
    required this.label,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.transparent,
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyBold.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
