import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import 'button_interaction_state.dart';

/// Text Buttons — "For subtle actions and inline links." e.g. Skip.
/// No fill, no border — just accent-purple text (+ optional trailing
/// arrow) that shifts shade per interaction state.
class AppTextButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double fontSize;

  const AppTextButton({
    super.key,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
    this.onPressed,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveButtonBuilder(
      disabled: onPressed == null,
      onTap: onPressed,
      builder: (context, state) {
        late final Color color;
        switch (state) {
          case ButtonInteractionState.disabled:
            color = AppColors.btnNeutralGrey.withOpacity(0.5);
            break;
          case ButtonInteractionState.pressed:
            color = const Color(0xFF7E22CE); // darker purple
            break;
          case ButtonInteractionState.hover:
            color = const Color(0xFFC084FC); // lighter purple
            break;
          case ButtonInteractionState.normal:
            color = AppColors.btnAccentPurple;
            break;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyBold.copyWith(
                  fontSize: fontSize,
                  color: color,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: fontSize + 2, color: color),
              ],
            ],
          ),
        );
      },
    );
  }
}
