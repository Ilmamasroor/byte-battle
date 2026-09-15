import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// Small Beginner / Intermediate / Advanced pill, reused anywhere a
/// difficulty level needs to be shown (topic cards, concept cards,
/// etc.) instead of every screen building its own inline chip.
class DifficultyBadge extends StatelessWidget {
  final String level;

  const DifficultyBadge({super.key, required this.level});

  Color get _color {
    switch (level.toLowerCase()) {
      case 'intermediate':
        return AppColors.warning;
      case 'advanced':
        return AppColors.btnGamificationPink;
      case 'beginner':
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        level,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
