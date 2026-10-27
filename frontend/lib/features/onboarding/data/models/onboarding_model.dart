/// Which illustrated scene a story page shows (see `onboarding_scenes.dart`).
enum OnboardingScene { learn, see, battle, own }

/// One page of the intro story shown before login. Not to be confused with the ByteDNA AI-onboarding models
/// under `ai_onboarding/data/models`.
class OnboardingModel {
  final String step; // "01"
  final String verb; // "LEARN IT"
  final String title;
  final String subtitle;
  final OnboardingScene scene;

  const OnboardingModel({
    required this.step,
    required this.verb,
    required this.title,
    required this.subtitle,
    required this.scene,
  });

  /// The story, in order: understand it, watch it happen, fight for it, own it. Copy only; no backend.
  static const List<OnboardingModel> pages = [
    OnboardingModel(
      step: '01',
      verb: 'LEARN IT',
      title: 'Concepts that finally click',
      subtitle: 'Analogies, mnemonics and plain-English explanations, shaped to how your brain likes to learn.',
      scene: OnboardingScene.learn,
    ),
    OnboardingModel(
      step: '02',
      verb: 'SEE IT',
      title: 'Watch the code come alive',
      subtitle: 'Step through threads, memory and race conditions as animations. Understanding beats memorising.',
      scene: OnboardingScene.see,
    ),
    OnboardingModel(
      step: '03',
      verb: 'BATTLE IT',
      title: 'Turn practice into a fight',
      subtitle: 'Boss battles, debugging puzzles and mock interviews. Lose a heart, learn the lesson, win the round.',
      scene: OnboardingScene.battle,
    ),
    OnboardingModel(
      step: '04',
      verb: 'OWN IT',
      title: 'Your Byte DNA, your path',
      subtitle: 'Every answer sharpens a living profile of your strengths, so the next step is always yours.',
      scene: OnboardingScene.own,
    ),
  ];
}
