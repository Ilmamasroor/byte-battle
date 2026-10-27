import 'package:flutter/material.dart';
import 'app_button_size.dart';
import 'gradient_pill_button.dart';

/// Primary Buttons — "Main call-to-action. Use once per screen."
/// e.g. Get Started, Login, Create Account, Verify.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.large,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return GradientPillButton(
      label: label,
      icon: icon,
      iconLeading: false,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      fullWidth: fullWidth,
    );
  }
}
