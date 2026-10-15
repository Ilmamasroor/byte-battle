import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Concept title block: an eyebrow icon badge + "CONCEPT" label, the
/// concept's name, a difficulty badge and topic tag chips — the header
/// used at the top of the concept overview and every stage screen in
/// its learning flow.
class ConceptHeader extends StatelessWidget {
  final String title;
  final String difficulty;
  final List<String> tags;
  final IconData icon;

  const ConceptHeader({
    super.key,
    required this.title,
    this.difficulty = 'Medium',
    this.tags = const [],
    this.icon = Icons.code_rounded,
  });

  Color get _difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'easy':
        return AppColors.success;
      case 'hard':
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
              ),
              child: Icon(icon, color: AppColors.accentCyan, size: 20),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CONCEPT',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryLight,
                        letterSpacing: 1.5,
                      )),
                  Text(title, style: AppTextStyles.heading1),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Wrap(
          spacing: AppDimensions.spacingSm,
          runSpacing: AppDimensions.spacingSm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.signal_cellular_alt_rounded, size: 13, color: _difficultyColor),
                  const SizedBox(width: 4),
                  Text('Difficulty', style: AppTextStyles.caption),
                  const SizedBox(width: 4),
                  Text(difficulty,
                      style: AppTextStyles.caption.copyWith(
                        color: _difficultyColor,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
            for (final tag in tags)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Text(tag,
                    style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight)),
              ),
          ],
        ),
      ],
    );
  }
}
