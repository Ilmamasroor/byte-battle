import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import 'app_button_size.dart';
import 'button_interaction_state.dart';

/// Secondary Buttons — "For less prominent actions." e.g. Learn More.
/// Outlined pill, transparent fill, brand-blue border/text.
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool iconLeading;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final bool fullWidth;

  const SecondaryButton({
    super.key,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
    this.iconLeading = false,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveButtonBuilder(
      disabled: onPressed == null,
      onTap: onPressed,
      builder: (context, state) {
        late final Color borderColor;
        late final Color textColor;
        late final Color fillColor;

        switch (state) {
          case ButtonInteractionState.disabled:
            borderColor = AppColors.btnNeutralGrey.withOpacity(0.4);
            textColor = AppColors.btnNeutralGrey;
            fillColor = Colors.transparent;
            break;
          case ButtonInteractionState.pressed:
            borderColor = AppColors.primaryDark;
            textColor = AppColors.primaryDark;
            fillColor = AppColors.primaryDark.withOpacity(0.12);
            break;
          case ButtonInteractionState.hover:
            borderColor = AppColors.btnPrimaryBlue;
            textColor = AppColors.btnPrimaryBlue;
            fillColor = AppColors.btnPrimaryBlue.withOpacity(0.12);
            break;
          case ButtonInteractionState.normal:
            borderColor = AppColors.accentCyan;
            textColor = AppColors.accentCyan;
            fillColor = AppColors.accentCyan.withOpacity(0.06);
            break;
        }

        final content = Row(
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
            color: fillColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
          alignment: Alignment.center,
          child: content,
        );
      },
    );
  }
}
