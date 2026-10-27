import 'package:flutter/material.dart';

/// Byte Battle colour system, "Ember on Ink".
///
/// The story in one line: a calm, near-black ink canvas (so code and diagrams stay readable) lit by one warm
/// brand colour, Flame, which means "your next move". Aqua is the second voice for visualisation and insight;
/// Gold is reserved for XP and streaks; Mint and Rose are the only success / error colours, and both are tuned to
/// sit on the violet-tinted ink without the harsh clash that pure green and red had on blue.
///
/// Token names from earlier iterations are kept (so every screen picks up the new look) but their values now
/// belong to this palette. New code should prefer the semantic names at the bottom.
class AppColors {
  AppColors._();

  // ── Canvas ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0E0D13);
  static const Color backgroundSecondary = Color(0xFF15131C);
  static const Color surface = Color(0xFF1C1A26);
  static const Color surfaceRaised = Color(0xFF242130);
  static const Color inputFill = Color(0xFF1A1823);

  // ── Brand: Flame ──────────────────────────────────────────────────
  static const Color primary = Color(0xFFFF7A3D);
  static const Color primaryDark = Color(0xFFE5541F);
  static const Color primaryLight = Color(0xFFFFB07F);

  /// Second voice: visualisation, insight, focus rings.
  static const Color accentCyan = Color(0xFF5CCFEF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF9A4D), primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Legacy button palette (kept so existing widgets compile) ────────
  static const Color btnPrimaryBlue = Color(0xFFFF9A4D); // hover Flame
  static const Color btnAccentPurple = Color(0xFFB39DFF); // Orchid, soft violet accent
  static const Color btnSuccessGreen = Color(0xFF3DDC97);
  static const Color btnErrorRed = Color(0xFFFF5D73);
  static const Color btnWarningOrange = Color(0xFFFFC145);
  static const Color btnNeutralGrey = Color(0xFF8E88A0);
  static const Color btnGamificationPink = accentCyan;
  static const Color btnGamificationGold = Color(0xFFFFD166);

  static const LinearGradient btnPrimaryGradient = LinearGradient(
    colors: [Color(0xFFFF8A4A), Color(0xFFFF6A2E)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient btnPrimaryGradientHover = LinearGradient(
    colors: [Color(0xFFFFA05F), Color(0xFFFF7A3D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Color btnPrimaryPressed = Color(0xFFD9511C);

  static const LinearGradient btnPinkGradient = LinearGradient(
    colors: [Color(0xFF5CCFEF), Color(0xFF3FA9E8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient btnPinkGradientHover = LinearGradient(
    colors: [Color(0xFF7FDDF5), Color(0xFF5CBBF0)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient btnGoldGradient = LinearGradient(
    colors: [Color(0xFFFFE29A), btnGamificationGold],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient btnGoldGradientHover = LinearGradient(
    colors: [Color(0xFFFFEBB8), Color(0xFFFFC145)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Color btnDarkBorder = Color(0xFF0A0910);

  // ── Text ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF7F3EE);
  static const Color textSecondary = Color(0xFFBAB4C8);
  static const Color textHint = Color(0xFF8D879E); // AA on the ink canvas

  /// Text that sits ON a Flame / Gold / Aqua fill. Dark ink gives far better contrast than white on orange.
  static const Color onAccent = Color(0xFF1B1008);

  // ── Lines ──────────────────────────────────────────────────────────
  static const Color border = Color(0xFF2E2B3C);
  static const Color divider = Color(0xFF242130);
  static const Color borderLight = Color(0xFF433F57);

  // ── Status ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF3DDC97); // Mint
  static const Color error = Color(0xFFFF5D73); // Rose
  static const Color warning = Color(0xFFFFC145); // Amber

  // ── Semantic (preferred in new code) ───────────────────────────────
  static const Color xp = Color(0xFFFFD166);
  static const Color streak = Color(0xFFFF8A4A);
  static const Color insight = accentCyan;
  static const Color orchid = btnAccentPurple;

  // ── Misc ───────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color overlay = Color(0x99000000);

  /// One colour per difficulty everywhere: Easy = Mint, Medium = Amber, Hard = Orchid (red stays reserved for errors).
  static Color difficulty(String? level) {
    switch ((level ?? '').toLowerCase()) {
      case 'beginner':
      case 'easy':
        return success;
      case 'hard':
      case 'advanced':
        return orchid;
      default:
        return warning;
    }
  }

  /// A soft tinted wash for a status/feature colour: reads as a "tag" on the surface instead of a flat block of
  /// saturated colour. Use for answer feedback, badges and chips.
  static Color wash(Color c, [double opacity = 0.14]) => c.withOpacity(opacity);
}
