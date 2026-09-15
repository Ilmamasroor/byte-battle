import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'button_interaction_state.dart';

/// Icon Buttons — "Square/circular icon buttons for compact actions."
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool circular;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveButtonBuilder(
      disabled: onPressed == null,
      onTap: onPressed,
      builder: (context, state) {
        Gradient? gradient;
        Color? solidColor;

        switch (state) {
          case ButtonInteractionState.disabled:
            gradient = null;
            solidColor = AppColors.btnNeutralGrey.withOpacity(0.3);
            break;
          case ButtonInteractionState.pressed:
            gradient = null;
            solidColor = AppColors.primaryDark;
            break;
          case ButtonInteractionState.hover:
            gradient = AppColors.btnPrimaryGradientHover;
            break;
          case ButtonInteractionState.normal:
            gradient = AppColors.btnPrimaryGradient;
            break;
        }

        final iconColor = state == ButtonInteractionState.disabled
            ? AppColors.textPrimary.withOpacity(0.6)
            : AppColors.white;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: gradient,
            color: solidColor,
            shape: circular ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circular ? null : BorderRadius.circular(size * 0.28),
            border: Border.all(color: AppColors.btnDarkBorder, width: 2),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: size * 0.45, color: iconColor),
        );
      },
    );
  }
}
