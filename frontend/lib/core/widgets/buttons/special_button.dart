import 'package:flutter/material.dart';
import 'app_button_size.dart';
import 'gradient_pill_button.dart';
import 'secondary_button.dart';

/// Special Buttons — "For unique or important actions."
/// Claim XP → gradient pill, crown icon (Default style).
/// Daily Battle → outlined pill, calendar icon (Secondary style).
class SpecialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final bool fullWidth;
  final bool _isPrimaryVariant;

  const SpecialButton.claimXp({
    super.key,
    this.label = 'Claim XP',
    this.icon = Icons.emoji_events_rounded,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.fullWidth = true,
  }) : _isPrimaryVariant = true;

  const SpecialButton.dailyBattle({
    super.key,
    this.label = 'Daily Battle',
    this.icon = Icons.event_available_rounded,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.fullWidth = true,
  }) : _isPrimaryVariant = false;

  @override
  Widget build(BuildContext context) {
    if (_isPrimaryVariant) {
      return GradientPillButton(
        label: label,
        icon: icon,
        iconLeading: true,
        onPressed: onPressed,
        size: size,
        fullWidth: fullWidth,
      );
    }
    return SecondaryButton(
      label: label,
      icon: icon,
      iconLeading: true,
      onPressed: onPressed,
      size: size,
      fullWidth: fullWidth,
    );
  }
}
