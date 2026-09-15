import 'package:flutter/material.dart';
import 'buttons/app_button_size.dart';
import 'buttons/gradient_pill_button.dart';
import 'buttons/secondary_button.dart';

/// Full-width CTA button used across the app (NEXT, LOGIN, CREATE ACCOUNT,
/// VERIFY, SEND RESET LINK...). Internally this now maps 1:1 onto the
/// "Button Styles" design reference: filled = Primary Button (cyan → blue
/// gradient pill, Default/Hover/Pressed/Disabled states), outlined =
/// Secondary Button (brand-blue outline pill). Kept as a thin wrapper so
/// every existing call site across the app picks up the correct colors
/// and states with no other changes needed.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SecondaryButton(
        label: label,
        icon: icon,
        iconLeading: icon != null,
        onPressed: isLoading ? null : onPressed,
        size: AppButtonSize.xl,
        fullWidth: true,
      );
    }

    return GradientPillButton(
      label: label,
      icon: icon,
      iconLeading: icon != null,
      onPressed: onPressed,
      isLoading: isLoading,
      size: AppButtonSize.xl,
      fullWidth: true,
    );
  }
}
