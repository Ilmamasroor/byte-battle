import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';

/// The "AI Explanation" card on the Understand screen — a
/// Concept/Simplified toggle above the actual explanation text, with a
/// "Beginner Level" badge in the corner.
class ExplanationCard extends StatelessWidget {
  final bool simplified;
  final ValueChanged<bool> onToggle;
  final String conceptExplanation;
  final String simplifiedExplanation;
  final String levelLabel;

  const ExplanationCard({
    super.key,
    required this.simplified,
    required this.onToggle,
    required this.conceptExplanation,
    required this.simplifiedExplanation,
    this.levelLabel = 'Beginner Level',
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(Icons.smart_toy_outlined, color: AppColors.white, size: 18),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('AI Explanation', style: AppTextStyles.bodyBold),
                        const SizedBox(width: 4),
                        const Icon(Icons.auto_awesome_rounded,
                            size: 14, color: AppColors.accentCyan),
                      ],
                    ),
                    Text('Tailored to your learning level', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(levelLabel, style: AppTextStyles.caption),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Concept Explanation',
                  selected: !simplified,
                  onTap: () => onToggle(false),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: _TabButton(
                  label: 'Simplified Explanation',
                  selected: simplified,
                  onTap: () => onToggle(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  simplified ? 'Simplified Explanation' : 'Concept Explanation',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.accentCyan),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  simplified ? simplifiedExplanation : conceptExplanation,
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(
            color: selected ? AppColors.accentCyan : AppColors.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.accentCyan : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
