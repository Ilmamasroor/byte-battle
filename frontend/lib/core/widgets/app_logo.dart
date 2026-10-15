import 'package:flutter/material.dart';
import '../../app/constants/app_constants.dart';
import '../../app/theme/app_colors.dart';

/// Shared Byte Battle brand mark. Renders the logo artwork only — the
/// "Byte Battle" wordmark is already part of the image itself, so no
/// separate text is drawn next to it. Used on the login / register
/// screens and the dashboard header so the mark reads exactly the
/// same everywhere.
class AppLogo extends StatelessWidget {
  final double logoSize;
  final double fontSize;

  const AppLogo({super.key, this.logoSize = 32, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    final displaySize = logoSize * 1.6;
    // The brand mark is always `AppConstants.appLogo` (logo.png) — no
    // icon ever stands in for it. If the asset genuinely fails to load,
    // fall back to a plain gradient placeholder (no icon) rather than
    // faking the mark with an unrelated Material icon.
    return Image.asset(
      AppConstants.appLogo,
      width: displaySize,
      height: displaySize,
      errorBuilder: (_, __, ___) => Container(
        width: displaySize,
        height: displaySize,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentCyan, AppColors.btnAccentPurple],
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
