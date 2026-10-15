import 'package:flutter/material.dart';
import 'route_names.dart';
import '../constants/app_constants.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/concepts/presentation/screens/concept_list_screen.dart';
import '../../features/concepts/presentation/screens/concept_detail_screen.dart';
import '../../features/concepts/presentation/screens/learning_journey_screen.dart';
import '../../features/curriculum/presentation/screens/domain_list_screen.dart';
import '../../features/curriculum/presentation/screens/topic_list_screen.dart';
import '../../features/curriculum/presentation/screens/roadmap_screen.dart';
import '../../features/byte_dna/presentation/screens/byte_dna_setup_screen.dart';
import '../../features/learning/visualization/screens/visualization_screen.dart';
import '../../features/learning/explanation/screens/explanation_screen.dart';
import '../../features/learning/analogy/screens/analogy_screen.dart';
import '../../features/learning/mnemonic/screens/mnemonic_screen.dart';
import '../../features/battle/presentation/screens/battle_screen.dart';
import '../../features/battle/presentation/screens/battle_intro_screen.dart';
import '../../features/battle/presentation/screens/battle_result_screen.dart';
import '../../features/battle/presentation/widgets/battle_feedback.dart';
import '../../features/coding/presentation/screens/coding_screen.dart';
import '../../features/coding/presentation/screens/coding_result_screen.dart';
import '../../features/debugging/presentation/screens/debugging_screen.dart';
import '../../features/byte_dna/presentation/screens/byte_dna_summary_screen.dart';
import '../../features/interview/presentation/screens/interview_intro_screen.dart';
import '../../features/interview/presentation/screens/interview_screen.dart';
import '../../features/interview/presentation/screens/interview_result_screen.dart';
import '../../features/score/presentation/screens/score_screen.dart';
import '../../features/performance/presentation/screens/performance_screen.dart';
import '../../features/performance/presentation/screens/next_move_screen.dart';
import '../../features/ai_feedback/presentation/screens/ai_feedback_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/learner_profile/presentation/screens/learner_profile_screen.dart';

/// Central route generator. Wire this into MaterialApp via
/// `onGenerateRoute: AppRouter.generateRoute`.
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Debug-console navigation log — prints every screen the app
    // navigates to, e.g. "[NAV] -> /dashboard". Visible in the IDE /
    // `flutter run` debug console only (stripped from release builds).
    debugPrint('[NAV] -> ${settings.name ?? 'unknown route'}'
        '${settings.arguments != null ? '  args: ${settings.arguments}' : ''}');

    switch (settings.name) {
      case RouteNames.splash:
        return _fade(const SplashScreen());

      case RouteNames.onboarding:
        return _fade(const OnboardingScreen());

      case RouteNames.login:
        return _fade(const LoginScreen());

      case RouteNames.register:
        return _fade(const RegisterScreen());

      case RouteNames.otpVerification:
        final email = (settings.arguments as Map?)?['email'] as String? ?? '';
        return _fade(OtpVerificationScreen(email: email));

      case RouteNames.forgotPassword:
        return _fade(const ForgotPasswordScreen());

      case RouteNames.dashboard:
        return _fade(const DashboardScreen());

      case RouteNames.conceptList:
        return _fade(const ConceptListScreen());

      case RouteNames.conceptDetail:
        return _fade(const ConceptDetailScreen());

      case RouteNames.learningJourney:
        return _fade(const LearningJourneyScreen());

      case RouteNames.domainList:
        return _fade(DomainListScreen(highlightDomain: _domainArg(settings)));

      case RouteNames.topicList:
        return _fade(TopicListScreen(domainName: _domainArg(settings)));

      case RouteNames.roadmap:
        return _fade(const RoadmapScreen());

      case RouteNames.explore:
        return _fade(VisualizationScreen(conceptId: _conceptId(settings)));

      case RouteNames.understand:
        return _fade(ExplanationScreen(conceptId: _conceptId(settings)));

      case RouteNames.relate:
        return _fade(AnalogyScreen(conceptId: _conceptId(settings)));

      case RouteNames.remember:
        return _fade(MnemonicScreen(conceptId: _conceptId(settings)));

      case RouteNames.battle:
        return _fade(const BattleScreen());

      case RouteNames.battleFeedback:
        final args = settings.arguments as Map?;
        return _fade(BattleFeedback(
          topicLabel: args?['topicLabel'] as String? ?? 'Practice',
          message: args?['message'] as String? ??
              'You got the core idea, but missed one detail.',
          hints: (args?['hints'] as List?)?.cast<String>() ?? const [],
          quote: args?['quote'] as String? ?? 'Every bug is a lesson in disguise.',
          question: args?['question'] as String?,
        ));

      case RouteNames.bossBattleIntro:
        return _fade(const BattleIntroScreen());

      case RouteNames.bossBattleResult:
        return _fade(const BattleResultScreen());

      case RouteNames.coding:
        return _fade(const CodingScreen());

      case RouteNames.codingResult:
        return _fade(const CodingResultScreen());

      case RouteNames.debugging:
        return _fade(const DebuggingScreen());

      case RouteNames.byteDnaSummary:
        return _fade(const ByteDnaSummaryScreen());

      case RouteNames.byteDnaSetup:
        return _fade(const ByteDnaSetupScreen());

      case RouteNames.interviewIntro:
        return _fade(const InterviewIntroScreen());

      case RouteNames.interview:
        return _fade(const InterviewScreen());

      case RouteNames.interviewResult:
        return _fade(const InterviewResultScreen());

      case RouteNames.score:
        return _fade(const ScoreScreen());

      case RouteNames.performance:
        return _fade(const PerformanceScreen());

      case RouteNames.nextMove:
        return _fade(const NextMoveScreen());

      case RouteNames.aiFeedback:
        return _fade(const AiFeedbackScreen());

      case RouteNames.profile:
        return _fade(const ProfileScreen());

      case RouteNames.changePassword:
        return _fade(const ChangePasswordScreen());

      case RouteNames.learnerProfile:
        return _fade(const LearnerProfileScreen());

      default:
        // Any route name that isn't wired up above (typo'd, removed, or
        // not implemented yet) falls back to the dashboard instead of a
        // dead-end "No route defined" screen, so navigation never strands
        // the learner.
        debugPrint(
            '[NAV] no route defined for "${settings.name}" -> redirecting to dashboard');
        return _fade(const DashboardScreen());
    }
  }

  /// Reads `conceptId` off `settings.arguments` (a `Map`, same convention
  /// as `battleFeedback`/`otpVerification` below) for the three AI-backed
  /// learning-stage screens. Falls back to [AppConstants.defaultConceptId]
  /// so these screens still work standalone (e.g. jumped to directly from
  /// the debugging screen, or opened before concept selection passes a
  /// real id) instead of crashing on a null conceptId.
  /// Reads `domainName` off `settings.arguments` (a `Map`), the same
  /// convention as [_conceptId] — used by [RouteNames.domainList] (to
  /// highlight the step tapped from [RoadmapScreen]) and
  /// [RouteNames.topicList] (to pick which domain's topics to show).
  /// Returns `null` when absent so each screen can fall back to its own
  /// sensible default instead of this router guessing one.
  static String? _domainArg(RouteSettings settings) {
    final args = settings.arguments;
    if (args is Map && args['domainName'] is String) {
      return args['domainName'] as String;
    }
    return null;
  }

  static String _conceptId(RouteSettings settings) {
    final args = settings.arguments;
    if (args is Map && args['conceptId'] is String) {
      return args['conceptId'] as String;
    }
    return AppConstants.defaultConceptId;
  }

  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

