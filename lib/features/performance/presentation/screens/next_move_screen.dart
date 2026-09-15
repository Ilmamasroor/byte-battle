import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/dual_icon_button.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../../../learner_profile/data/models/learner_profile_model.dart';
import '../../../learner_profile/presentation/state/learner_profile_controller.dart';
import '../../data/models/performance_model.dart';
import '../../data/models/recommendation_model.dart';
import '../state/diagnosis_summary_controller.dart';
import '../state/recommendation_controller.dart';

/// "Your Next Move" — personalized recommendation screen shown after a
/// weakness has been detected (e.g. from Performance Diagnosis / Byte
/// DNA). Surfaces the weak skill, drills into the specific sub-topic,
/// and offers a recommended-practice CTA plus a "choose something
/// else" escape hatch. Matches the reference "Your Next Move" screen.
class NextMoveScreen extends StatefulWidget {
  const NextMoveScreen({super.key});

  @override
  State<NextMoveScreen> createState() => _NextMoveScreenState();
}

class _NextMoveScreenState extends State<NextMoveScreen> {
  @override
  void initState() {
    super.initState();
    Helpers.noApiYet(
      'NextMoveScreen',
      note: 'now LIVE via POST /api/ai/diagnose/summary + '
          'POST /api/ai/recommend (DiagnosisSummaryController + '
          'RecommendationController)',
    );
    _load();
  }

  /// Chains two real endpoints, same as the backend contract requires:
  /// 1. `POST /api/ai/diagnose/summary` — aggregate skill scores (or
  ///    reuse [DiagnosisSummaryController]'s result if [PerformanceScreen]
  ///    already loaded it this session).
  /// 2. `POST /api/ai/recommend` — feed those scores in to get back the
  ///    weakest-skill recommendation this screen shows.
  ///
  /// Same as [PerformanceScreen], there's no activity-history store yet,
  /// so step 1 submits representative sample activity data when a
  /// summary isn't already cached — see that screen's `_load` doc for
  /// why. `topic`/`repeatedMistakes` are similarly placeholders until the
  /// app tracks which concept/topic the learner was last practicing.
  Future<void> _load({bool force = false}) async {
    final userId = AuthController.instance.currentUser?.id ?? '';

    final summaryController = DiagnosisSummaryController.instance;
    await summaryController.summarizeActivities(
      activities: [
        DiagnosisActivityModel(
          userId: userId,
          activityType: 'DEBUGGING',
          accuracy: 0.71,
          score: 71,
          attemptCount: 3,
          timeSpentSeconds: 384,
          hintsUsed: 2,
          testCasesPassed: 3,
          testCasesTotal: 5,
          success: true,
        ),
      ],
      force: force,
    );

    final summary = summaryController.summary;
    if (summary == null) {
      // Diagnosis summary failed — surface that error and stop; there's
      // nothing meaningful to recommend without it.
      if (!mounted) return;
      setState(() {});
      return;
    }

    final profileController = LearnerProfileController.instance;
    if (profileController.profile == null && !profileController.profileMissing) {
      // `GET /api/learner-profile` — needed for technicalExperience below.
      // No-op if some other screen (e.g. DashboardScreen) already loaded
      // it this session.
      await profileController.load();
    }
    final experienceLevel = profileController.profile?.experienceLevel ?? ExperienceLevel.beginner;

    await RecommendationController.instance.getRecommendation(
      technicalExperience: experienceLevel,
      topic: 'General Programming',
      repeatedMistakes: const [],
      conceptUnderstanding: summary.conceptUnderstanding,
      decisionMaking: summary.decisionMaking,
      boundaryConditions: summary.boundaryConditions,
      codingImplementation: summary.codingImplementation,
      hintDependency: summary.hintDependency,
      force: force,
    );

    if (!mounted) return;
    setState(() {});
  }

  /// Best-effort mapping from the AI's free-text `recommendedChallengeType`
  /// to an actual practice screen, so "START RECOMMENDED PRACTICE"
  /// genuinely reflects the recommendation instead of always going to
  /// Debugging.
  String _routeForChallengeType(String type) {
    final t = type.toLowerCase();
    if (t.contains('debug')) return RouteNames.debugging;
    if (t.contains('cod')) return RouteNames.coding;
    if (t.contains('interview')) return RouteNames.interviewIntro;
    return RouteNames.bossBattleIntro;
  }

  @override
  Widget build(BuildContext context) {
    final recController = RecommendationController.instance;
    final recommendation = recController.recommendation;
    final summaryController = DiagnosisSummaryController.instance;

    final isInitialLoad =
        (summaryController.isLoading || recController.isLoading) && recommendation == null;
    final error = recController.errorMessage ?? summaryController.errorMessage;
    final hasFailedWithNoData = error != null && recommendation == null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('BYTE BATTLE', style: AppTextStyles.heading2),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppDimensions.spacingMd),
            child: Center(child: _XpChip(xp: 840)),
          ),
        ],
      ),
      body: SafeArea(
        child: isInitialLoad
            ? const LoadingView(message: 'Finding your next best move…')
            : hasFailedWithNoData
                ? ErrorView(
                    message: error!,
                    onRetry: () => _load(force: true),
                  )
                : _buildContent(context, recommendation),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RecommendationAiResponse? recommendation) {
    // Live text from POST /api/ai/recommend when available; sensible
    // fallback copy (matching the old hardcoded strings) if a
    // recommendation hasn't loaded yet.
    final weaknessTitle = recommendation?.targetErrorCategory.toUpperCase() ?? 'DEBUGGING';
    final weaknessCaption = recommendation != null
        ? recommendation.basis
        : 'Your error-fixing skills need more practice.';
    final subtopicTitle = recommendation?.recommendedChallengeType ?? 'Thread Synchronization';
    final subtopicCaption = recommendation != null
        ? recommendation.reason
        : 'Common issues: race conditions, deadlocks, shared resources.';
    final recommendationText = recommendation != null
        ? '${recommendation.reason} (${recommendation.recommendedChallengeType})'
        : 'Practice 3 debugging scenarios focused on synchronization.';
    final practiceRoute = recommendation != null
        ? _routeForChallengeType(recommendation.recommendedChallengeType)
        : RouteNames.debugging;

    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: const Icon(Icons.track_changes_rounded, color: AppColors.white),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: AppTextStyles.heading1.copyWith(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w800,
                            ),
                            children: const [
                              TextSpan(text: 'YOUR NEXT '),
                              TextSpan(text: 'MOVE', style: TextStyle(color: AppColors.accentCyan)),
                            ],
                          ),
                        ),
                        Text(
                          "Personalized for you. Because progress isn't random.",
                          style: AppTextStyles.body.copyWith(color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Text(
                    "Let's turn this\nweakness into\nyour strength!",
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderLight.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.btnGamificationPink.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: const Icon(Icons.warning_amber_rounded,
                              color: AppColors.btnGamificationPink, size: 18),
                        ),
                        const SizedBox(width: AppDimensions.spacingSm),
                        Text.rich(
                          TextSpan(
                            style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                            children: const [
                              TextSpan(text: 'We found a '),
                              TextSpan(
                                text: 'weakness',
                                style: TextStyle(color: AppColors.btnGamificationPink),
                              ),
                              TextSpan(text: ' in:'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    _WeaknessTile(
                      icon: Icons.bug_report_rounded,
                      color: AppColors.btnGamificationPink,
                      title: weaknessTitle,
                      caption: weaknessCaption,
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.25),
                          ),
                          child: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.accentCyan, size: 18),
                        ),
                      ),
                    ),
                    _WeaknessTile(
                      icon: Icons.code_rounded,
                      color: AppColors.accentCyan,
                      title: subtopicTitle,
                      titleCase: false,
                      caption: subtopicCaption,
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.spacingMd),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                            ),
                            child: const Icon(Icons.lightbulb_outline_rounded,
                                color: AppColors.white, size: 16),
                          ),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Recommended:',
                                    style: AppTextStyles.bodyBold
                                        .copyWith(color: AppColors.white)),
                                const SizedBox(height: 2),
                                Text(recommendationText,
                                    style: AppTextStyles.body
                                        .copyWith(color: AppColors.white.withOpacity(0.9))),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingSm),
                          const Icon(Icons.bar_chart_rounded, color: AppColors.white, size: 28),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    DualIconButton(
                      label: 'START RECOMMENDED PRACTICE',
                      leadingIcon: Icons.play_arrow_rounded,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: () => Navigator.of(context).pushNamed(practiceRoute),
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    DualIconButton(
                      label: 'CHOOSE SOMETHING ELSE',
                      leadingIcon: Icons.shuffle_rounded,
                      trailingIcon: Icons.arrow_forward_rounded,
                      outlined: true,
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed(RouteNames.conceptList),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              Center(
                child: Text(
                  '—  BETTER CHOICES = FASTER GROWTH  —',
                  style: AppTextStyles.caption.copyWith(letterSpacing: 0.5),
                ),
              ),
            ],
          ),
      ),
    );
  }
}

class _WeaknessTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String caption;
  final bool titleCase;

  const _WeaknessTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.caption,
    this.titleCase = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleCase ? title.toUpperCase() : title,
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(caption, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _XpChip extends StatelessWidget {
  final int xp;
  const _XpChip({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accentCyan),
          const SizedBox(width: 4),
          Text('$xp XP', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
