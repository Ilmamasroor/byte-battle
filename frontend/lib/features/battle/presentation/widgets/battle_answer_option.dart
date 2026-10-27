import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

enum BattleOptionState { idle, correct, wrong }

/// One full-width answer choice of a battle question. After grading, the picked option turns green or red
/// (the server never reveals which other option was right).
class BattleAnswerOption extends StatelessWidget {
  final String label;
  final bool selected;
  final BattleOptionState state;
  final VoidCallback? onTap;

  /// 0-based position, shown as an A/B/C/D badge. Null hides the badge.
  final int? index;

  const BattleAnswerOption({
    super.key,
    required this.label,
    this.index,
    this.selected = false,
    this.state = BattleOptionState.idle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      BattleOptionState.correct => AppColors.success,
      BattleOptionState.wrong => AppColors.error,
      BattleOptionState.idle => selected ? AppColors.primary : AppColors.border,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : AppColors.surface.withOpacity(0.6),
            border: Border.all(color: color, width: selected ? 1.6 : 1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: state == BattleOptionState.idle && !selected ? AppColors.surfaceRaised : color,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: switch (state) {
                  BattleOptionState.correct => const Icon(Icons.check_rounded, size: 17, color: AppColors.onAccent),
                  BattleOptionState.wrong => const Icon(Icons.close_rounded, size: 17, color: AppColors.onAccent),
                  BattleOptionState.idle => Text(
                      index == null ? '' : String.fromCharCode(65 + index!),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: selected ? AppColors.onAccent : AppColors.textSecondary,
                      ),
                    ),
                },
              ),
              const SizedBox(width: AppDimensions.spacingSm + 4),
              Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary))),
            ],
          ),
        ),
      ),
    );
  }
}
