import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../state/dashboard_controller.dart';
import '../widgets/current_goal_card.dart';
import '../widgets/domain_section.dart';
import '../widgets/learner_profile_summary_card.dart';
import '../widgets/performance_summary.dart';
import '../widgets/progress_summary.dart';
import '../widgets/user_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  // TODO: swap for real data once `/api/ai/diagnose/summary` (skill
  // radar), `/api/ai/recommend` (recommended battles / current mission)
  // and a gamification/XP endpoint are wired — see DashboardController's
  // doc comment for exactly which sections below are real vs. placeholder.
  final _skills = const {
    'Understanding': 0.72,
    'Application': 0.58,
    'Debugging': 0.41,
    'Communication': 0.65,
  };

  @override
  void initState() {
    super.initState();
    Helpers.noApiYet(
      'DashboardScreen',
      note: 'user + learner-profile are live (GET /api/learner-profile); '
          'XP/level/streak/skills/recommended-battles still hardcoded, no '
          'backend endpoint for those yet',
    );
    _load();
  }

  Future<void> _load() async {
    await DashboardController.instance.load();
    if (!mounted) return;
    setState(() {});
  }

  /// First letters of the learner's username, e.g. "ilma_m" -> "IM".
  /// Falls back to "?" if there's nothing to initial yet (still loading
  /// or logged out).
  String _initialsFor(String? username) {
    if (username == null || username.trim().isEmpty) return '?';
    final parts = username.trim().split(RegExp(r'[\s_.]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    setState(() => _navIndex = index);
    switch (index) {
      case 1:
        Navigator.of(context).pushReplacementNamed(RouteNames.conceptList);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(RouteNames.bossBattleIntro);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(RouteNames.coding);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(RouteNames.profile);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = DashboardController.instance;
    final user = AuthController.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: AppBottomNav(currentIndex: _navIndex, onTap: _onNavTap),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real: username from AuthController.currentUser (GET
              // /api/users/me at login/bootstrap). XP/level have no
              // backend field anywhere yet, so those two stay placeholder.
              UserHeader(
                name: user?.username ?? 'Learner',
                avatarInitials: _initialsFor(user?.username),
                level: 12,
                xp: 840,
                onProfileTap: () => Navigator.of(context).pushNamed(RouteNames.profile),
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              // Real: GET /api/learner-profile.
              LearnerProfileSummaryCard(
                isLoading: dashboard.isLoading,
                profile: dashboard.learnerProfile,
                onTap: () => Navigator.of(context)
                    .pushNamed(RouteNames.learnerProfile)
                    .then((_) => _load()),
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              CurrentGoalCard(
                title: 'Loop Boundaries',
                description:
                    'Understand when to start, stop and control loops effectively in your code.',
                progress: 0.58,
                tags: const ['Loops', 'Control Flow', 'Logic'],
                focusAreaNote:
                    'Loop boundaries have been challenging recently. Let\'s strengthen this concept and build confidence.',
                onContinue: () =>
                    Navigator.of(context).pushNamed(RouteNames.learningJourney),
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              PerformanceSummary(
                skills: _skills,
                onTap: () => Navigator.of(context).pushNamed(RouteNames.byteDnaSummary),
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              const ProgressSummary(
                xp: 840,
                xpTarget: 1000,
                level: 12,
                streakDays: 7,
                weekCompleted: [true, true, true, true, true, true, false],
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              DomainSection(
                onViewAll: () => Navigator.of(context).pushNamed(RouteNames.bossBattleIntro),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
            ],
          ),
        ),
      ),
    );
  }
}
