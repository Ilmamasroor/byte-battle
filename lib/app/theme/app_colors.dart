import 'package:flutter/material.dart';

/// Central color palette for the BYTL Battle app.
///
/// Every screen's real background is now the single image at
/// `AppConstants.appBackground` (painted once behind the whole app — see
/// `BytlBattleApp`'s `MaterialApp.builder` in app.dart), not a flat color.
/// The colors below are derived from that image's deep-navy-blue tone and
/// are only used for things that still need a solid color: cards/surfaces,
/// input fields, borders, text, and the brand accent — everything is set
/// to sit legibly on top of that background.
class AppColors {
  AppColors._();

  // Solid fallbacks — small elements only (progress-bar tracks, chip
  // backgrounds, image-loading placeholders). Sampled from the darkest
  // part of the background image.
  static const Color background = Color(0xFF071021);
  static const Color backgroundSecondary = Color(0xFF0B1C38);

  // Cards / surfaces — a touch lighter than the background image so
  // content still reads clearly on top of it.
  static const Color surface = Color(0xFF122A4C);
  static const Color inputFill = Color(0xFF0F2340);

  // Brand / accent — bright blue lifted straight from the sword/shield
  // glow in the Byte Battle logo, replacing the old purple theme.
  // Bumped up in saturation/brightness so buttons read as bold, electric
  // color pops (not muted/washed-out) against the dark navy background.
  static const Color primary = Color(0xFF1966FF);
  static const Color primaryDark = Color(0xFF0F3FA8);
  static const Color primaryLight = Color(0xFF66A8FF);
  static const Color accentCyan = Color(0xFF22D3FF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Button Styles palette (from the "Button Styles" design reference) ──
  // Used by everything under core/widgets/buttons/. Kept separate from the
  // brand colors above so existing screens are untouched.
  static const Color btnPrimaryBlue = Color(0xFF00E5FF); // Primary Blue
  static const Color btnAccentPurple = Color(0xFFA855F7); // Accent Purple
  static const Color btnSuccessGreen = Color(0xFF22C55E); // Success Green
  static const Color btnErrorRed = Color(0xFFEF4444); // Error Red
  static const Color btnWarningOrange = Color(0xFFF59E0B); // Warning Orange
  static const Color btnNeutralGrey = Color(0xFF94A3B8); // Neutral Grey
  static const Color btnGamificationPink = Color(0xFFEC4899); // Pink accent
  static const Color btnGamificationGold = Color(0xFFFBBF24); // Gold accent

  // Default-state gradient for Primary / Action / Navigation buttons
  // (cyan → brand blue, diagonal-left-to-right pill fill).
  static const LinearGradient btnPrimaryGradient = LinearGradient(
    colors: [Color(0xFF22E1E1), Color(0xFF7C6CF7), Color(0xFFEC4899)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient btnPrimaryGradientHover = LinearGradient(
    colors: [Color(0xFF7DF3F3), Color(0xFFA79BFA), Color(0xFFF9A8D4)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Color btnPrimaryPressed = Color(0xFF3B2FA0);

  static const LinearGradient btnPinkGradient = LinearGradient(
    colors: [Color(0xFFF472B6), btnGamificationPink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient btnPinkGradientHover = LinearGradient(
    colors: [Color(0xFFF9A8D4), Color(0xFFDB2777)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient btnGoldGradient = LinearGradient(
    colors: [Color(0xFFFDE68A), btnGamificationGold],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient btnGoldGradientHover = LinearGradient(
    colors: [Color(0xFFFEF08A), Color(0xFFF59E0B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Solid, no-glow border used on every button in place of drop-shadows
  // (buttons must never carry a boxShadow, in any state).
  static const Color btnDarkBorder = Color(0xFF0A1524);

  // Text
  static const Color textPrimary = Color(0xFFF3F7FF);
  static const Color textSecondary = Color(0xFF9FB3D1);
  static const Color textHint = Color(0xFF66799C);

  // Borders / dividers
  static const Color border = Color(0xFF1E3A5F);
  static const Color divider = Color(0xFF17304F);

  // Lighter "shiny" border used on input fields now that the fields
  // are no longer solid filled boxes — a brighter, glowing outline
  // instead of a flat dark border.
  static const Color borderLight = Color(0xFF5EA8FF);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Misc
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color overlay = Color(0x99000000);
}
