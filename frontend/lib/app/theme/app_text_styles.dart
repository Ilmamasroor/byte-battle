import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography: Plus Jakarta Sans for everything you read, Fraunces (a soft, characterful serif) for the few
/// "moments" (greetings, big numbers, results), JetBrains Mono for code. All three are bundled as assets, so they
/// work offline.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'PlusJakartaSans';
  static const String displayFamily = 'Fraunces';
  static const String monoFamily = 'JetBrainsMono';

  /// Expressive serif for hero moments. Use sparingly: one per screen at most.
  static const TextStyle display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.12,
    letterSpacing: -0.5,
  );

  static const TextStyle logoTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle logoSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.55,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  /// Small all-caps label above a section ("YOUR NEXT MOVE").
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: AppColors.textHint,
    letterSpacing: 1.4,
  );

  /// Default button label. Colour is set by each button (dark ink on Flame, light on outlines).
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.onAccent,
    letterSpacing: 0.1,
  );

  static const TextStyle code = TextStyle(
    fontFamily: monoFamily,
    fontSize: 13,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryLight,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
  );
}
