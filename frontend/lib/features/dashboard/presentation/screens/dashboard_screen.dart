import 'package:flutter/material.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../app/router/route_names.dart';
import '../../../readiness/data/readiness_store.dart';
import '../../../../app/theme/app_dimensions.dart';
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

  @override
  void initState() {
    super.initState();
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
    const routes = {
      1: RouteNames.conceptList,
      2: RouteNames.bossBattleIntro,
      3: RouteNames.coding,
      4: RouteNames.profile,
    };
    final route = routes[index];
    if (route == null) return;
    setState(() => _navIndex = index);
    // pushNamed (not replace) so the back button on screens without their own bottom bar returns to the dashboard.
    Navigator.of(context).pushNamed(route).then((_) {
      if (!mounted) return;
      setState(() => _navIndex = 0);
      _load();
    });
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
                level: dashboard.stats.level,
                xp: dashboard.stats.xp,
                streakDays: dashboard.stats.streakDays,
                onProfileTap: () => Navigator.of(context).pushNamed(RouteNames.profile),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              CurrentGoalCard(
                title: dashboard.concept?.name ?? 'Race Conditions',
                description: dashboard.concept?.description ??
                    'Understand shared resources, data races, synchronization and execution order.',
                progress: dashboard.conceptProgress,
                tags: const ['Java', 'Concurrency', 'Threads'],
                focusAreaNote: dashboard.nextMove?.message.isNotEmpty == true
                    ? dashboard.nextMove!.message
                    : (dashboard.nextMove?.title.isNotEmpty == true
                        ? 'Recommended next: ${dashboard.nextMove!.title}'
                        : 'Start the journey: learn it, see it, battle it, code it. Every attempt shapes your Byte DNA.'),
                onContinue: () async {
                  await ReadinessStore.open(context, AppConstants.defaultConceptId, RouteNames.learningJourney);
                  if (mounted) _load();
                },
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              PerformanceSummary(
                skills: dashboard.skills,
                onTap: () => Navigator.of(context).pushNamed(RouteNames.byteDnaSummary),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              ProgressSummary(
                xp: dashboard.stats.xp,
                xpTarget: dashboard.xpTarget,
                level: dashboard.stats.level,
                streakDays: dashboard.stats.streakDays,
                weekCompleted: DashboardController.weekStrip(dashboard.stats.streakDays, DateTime.now()),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              // Real: GET /api/learner-profile.
              LearnerProfileSummaryCard(
                isLoading: dashboard.isLoading,
                profile: dashboard.learnerProfile,
                onTap: () => Navigator.of(context)
                    .pushNamed(RouteNames.learnerProfile)
                    .then((_) => _load()),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              DomainSection(
                isLoading: dashboard.isLoading,
                battles: dashboard.battles,
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
