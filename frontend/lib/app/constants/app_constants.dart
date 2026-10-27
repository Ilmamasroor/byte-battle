class AppConstants {
  AppConstants._();

  static const String appName = 'Byte Battle';
  static const String tagline = 'Learn it. See it. Battle it. Code it.';

  static const int otpLength = 6;

  // Used as a fallback when a screen that needs a conceptId (Understand /
  // Relate / Remember stages) is opened without one passed via route
  // arguments — e.g. during standalone screen testing. The flagship concept seeded by the backend.
  static const String defaultConceptId = '00000000-0000-0000-0000-000000001003';
  // ^ "Race Conditions" (Java Multithreading & Concurrency): the flagship journey. The backend seeds a battle, coding
  //   challenges, debugging exercises, a visualization and AI interview material for exactly this concept.
}
