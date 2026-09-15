import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import 'app_button_size.dart';
import 'button_interaction_state.dart';

/// Cyan → blue gradient pill button. This is the single shared
/// implementation behind [PrimaryButton], [ActionButton] and
/// [NavigationButton] — same visual language, different icon/placement
/// per the "Button Styles" guide ("Different actions. One visual
/// language.").
class GradientPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool iconLeading;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final bool fullWidth;

  const GradientPillButton({
    super.key,
    required this.label,
    this.icon,
    this.iconLeading = false,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.large,
    this.fullWidth = true,
  });

  bool get _disabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    return InteractiveButtonBuilder(
      disabled: _disabled,
      onTap: onPressed,
      builder: (context, state) {
        final Gradient? gradient;
        final Color? solidColor;

        switch (state) {
          case ButtonInteractionState.disabled:
            gradient = null;
            solidColor = AppColors.btnNeutralGrey.withOpacity(0.35);
            break;
          case ButtonInteractionState.pressed:
            gradient = null;
            solidColor = AppColors.btnPrimaryPressed;
            break;
          case ButtonInteractionState.hover:
            gradient = AppColors.btnPrimaryGradientHover;
            solidColor = null;
            break;
          case ButtonInteractionState.normal:
            gradient = AppColors.btnPrimaryGradient;
            solidColor = null;
            break;
        }

        final textColor = state == ButtonInteractionState.disabled
            ? AppColors.textPrimary.withOpacity(0.6)
            : AppColors.white;

        final content = isLoading
            ? SizedBox(
                height: size.iconSize + 4,
                width: size.iconSize + 4,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (icon != null && iconLeading) ...[
                    Icon(icon, size: size.iconSize, color: textColor),
                    SizedBox(width: size.iconGap),
                  ],
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
                  if (icon != null && !iconLeading) ...[
                    SizedBox(width: size.iconGap),
                    Icon(icon, size: size.iconSize, color: textColor),
                  ],
                ],
              );

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
          child: content,
        );
      },
    );
  }
}
