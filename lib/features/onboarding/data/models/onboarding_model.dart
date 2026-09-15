/// Simple data model for a single page of the app's intro walkthrough
/// (`OnboardingScreen` / `OnboardingPage`) — the 3-page "Skip"/"Next"
/// carousel shown before login, not to be confused with the ByteDNA
/// AI-onboarding models under `ai_onboarding/data/models`.
class OnboardingModel {
  final String title;
  final String subtitle;

  const OnboardingModel({
    required this.title,
    required this.subtitle,
  });

  /// The fixed 3 pages shown in `OnboardingScreen`. Copy only — there's
  /// no backend for this walkthrough.
  static const List<OnboardingModel> pages = [
    OnboardingModel(
      title: 'Battle Your Way to Mastery',
      subtitle: 'Turn coding practice into head-to-head challenges and level up every skill.',
    ),
    OnboardingModel(
      title: 'Your Own Byte DNA',
      subtitle: 'Byte Battle learns how you learn, then tailors lessons to your strengths.',
    ),
    OnboardingModel(
      title: 'Track Every Win',
      subtitle: 'Earn XP, climb the leaderboard, and watch your progress grow day by day.',
    ),
  ];
}
