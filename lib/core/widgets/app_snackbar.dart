import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// What kind of message is being shown. This only changes the icon —
/// the visual style (blurred glass fill + glowing "spark" border) stays
/// identical for every type, and the text is always white. Success no
/// longer turns white-on-green and errors no longer turn red; both use
/// the same glass/spark look as everything else in the app.
enum AppSnackBarType { info, success, error }

/// Single shared snackbar used everywhere in the app instead of raw
/// `ScaffoldMessenger`/`SnackBar` calls, so every toast — success, error,
/// or plain info — looks the same: a blurred glass background with a
/// bright glowing border (matching [GlowCard]), never a solid red/green
/// fill.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: duration,
          padding: EdgeInsets.zero,
          content: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                  vertical: AppDimensions.spacingSm + 4, // 12
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: AppColors.borderLight.withOpacity(0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentCyan.withOpacity(0.22),
                      blurRadius: 24,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _iconFor(type),
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Expanded(
                      child: Text(
                        message,
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  /// Convenience for a success toast — same glass/spark look, white text.
  static void success(BuildContext context, String message) =>
      show(context, message, type: AppSnackBarType.success);

  /// Convenience for an error toast — same glass/spark look, white text
  /// (no red).
  static void error(BuildContext context, String message) =>
      show(context, message, type: AppSnackBarType.error);

  static IconData _iconFor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return Icons.check_circle_outline_rounded;
      case AppSnackBarType.error:
        return Icons.error_outline_rounded;
      case AppSnackBarType.info:
        return Icons.info_outline_rounded;
    }
  }
}
