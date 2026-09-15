import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import 'app_button_size.dart';
import 'button_interaction_state.dart';

/// Gamification Buttons — "For challenges, rewards and engagement."
/// Uses brand accent colors (pink / gold) for a more engaging, playful
/// feel than the standard blue action buttons.
enum GamificationButtonType { challenge, unlockBadge }

class GamificationButton extends StatelessWidget {
  final GamificationButtonType type;
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final bool fullWidth;

  const GamificationButton({
    super.key,
    required this.type,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.fullWidth = true,
  });

  IconData get _defaultIcon => type == GamificationButtonType.challenge
      ? Icons.local_fire_department_rounded
      : Icons.emoji_events_rounded;

  @override
  Widget build(BuildContext context) {
    final isPink = type == GamificationButtonType.challenge;

    return InteractiveButtonBuilder(
      disabled: onPressed == null,
      onTap: onPressed,
      builder: (context, state) {
        Gradient? gradient;
        Color? solidColor;

        switch (state) {
          case ButtonInteractionState.disabled:
            gradient = null;
            solidColor = AppColors.btnNeutralGrey.withOpacity(0.35);
            break;
          case ButtonInteractionState.pressed:
            gradient = null;
            solidColor = isPink
                ? const Color(0xFFBE185D)
                : const Color(0xFFB45309);
            break;
          case ButtonInteractionState.hover:
            gradient = isPink
                ? AppColors.btnPinkGradientHover
                : AppColors.btnGoldGradientHover;
            break;
          case ButtonInteractionState.normal:
            gradient =
                isPink ? AppColors.btnPinkGradient : AppColors.btnGoldGradient;
            break;
        }

        final textColor = state == ButtonInteractionState.disabled
            ? AppColors.textPrimary.withOpacity(0.6)
            : AppColors.white;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: size.height,
          width: fullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
          decoration: BoxDecoration(
            gradient: gradient,
            color: solidColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            border: Border.all(color: AppColors.btnDarkBorder, width: 2),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon ?? _defaultIcon, size: size.iconSize, color: textColor),
              SizedBox(width: size.iconGap),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.button.copyWith(
                    fontSize: size.fontSize,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
