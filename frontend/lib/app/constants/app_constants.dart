class AppConstants {
  AppConstants._();

  static const String appName = 'Byte Battle';
  static const String tagline = 'THE SKILL GENERATOR';

  // App-wide background — painted once behind every screen (see
  // BytlBattleApp's MaterialApp.builder in app.dart). Every Scaffold is
  // transparent so this shows through everywhere instead of a flat color.
  static const String appBackground = 'assets/images/app_background.png';

  // App logo mark.
  static const String appLogo = 'assets/images/logo.png';

  // Full splash artwork (already includes the wordmark/tagline) — shown
  // full-bleed, full-screen on the splash screen only.
  static const String splashArtwork = 'assets/images/spalesh_screen.png';

  // Onboarding background — shown full-bleed, full-screen behind all 3
  // onboarding pages (replaces the app-wide background on that screen only).
  static const String onboardingBackground = 'assets/images/on_board_bg.png';

  static const int otpLength = 6;

  // Used as a fallback when a screen that needs a conceptId (Understand /
  // Relate / Remember stages) is opened without one passed via route
  // arguments — e.g. during standalone screen testing. Matches the sample
  // concept id used throughout the backend API docs.
  static const String defaultConceptId = '00000000-0000-0000-0000-000000001001';
}
