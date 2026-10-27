import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/widgets/dual_icon_button.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../state/performance_controller.dart';
import '../widgets/xp_chip.dart';

/// "Your Next Move": the learner's top open recommendation from `GET /api/recommendations` (rule-based ones
/// derived from performance records, and AI ones written after each activity). With no evidence yet there is
/// nothing to recommend, and the screen says so.
class NextMoveScreen extends StatefulWidget {
  const NextMoveScreen({super.key});

  @override
  State<NextMoveScreen> createState() => _NextMoveScreenState();
}

class _NextMoveScreenState extends State<NextMoveScreen> {
  final _controller = PerformanceController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  /// Evidence first (the weak concepts decide what can be recommended), then the recommendations.
  Future<void> _load({bool analyse = false}) async {
    await _controller.load(force: true);
    if (!mounted || _controller.errorMessage != null) return;
    await _controller.loadRecommendations(analyse: analyse);
  }

  /// Where "start recommended practice" goes, by recommendation type.
  String _routeFor(RecommendationModel r) {
    switch (r.type) {
      case 'PRACTICE_CODING':
        return RouteNames.coding;
      case 'RETRY_BATTLE':
        return RouteNames.bossBattleIntro;
      case 'TAKE_INTERVIEW':
        return RouteNames.interviewIntro;
      case 'REVISE_CONCEPT':
      case 'ADJUST_DIFFICULTY':
      default:
        return RouteNames.learningJourney;
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'PRACTICE_CODING':
        return Icons.code_rounded;
      case 'RETRY_BATTLE':
        return Icons.sports_martial_arts_rounded;
      case 'TAKE_INTERVIEW':
        return Icons.forum_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final isLoading = (c.isLoading && !c.loaded) || (c.isLoadingRecommendations && c.recommendations.isEmpty);
    final error = c.errorMessage ?? c.recommendationError;
    final hasFailedWithNoData = error != null && c.recommendations.isEmpty;

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
            child: Center(child: LiveXpChip()),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const LoadingView(message: 'Finding your next best move…')
            : hasFailedWithNoData
                ? ErrorView(message: error, onRetry: _load)
                : c.recommendations.isEmpty
                    ? EmptyEvidence(
                        title: c.records.isEmpty ? 'No activity yet' : 'Nothing to fix right now',
                        message: c.records.isEmpty
                            ? 'Finish a battle, coding challenge, debugging exercise or interview and your '
                                'next move will be suggested here.'
                            : 'Your recent results show no weak spot that needs a revision. Keep practicing.',
                        actionLabel: c.records.isEmpty ? 'Choose a concept' : 'Choose something to practice',
                        onAction: () => Navigator.of(context).pushNamed(RouteNames.conceptList),
                      )
                    : _buildContent(context, c.recommendations.first),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RecommendationModel recommendation) {
    final conceptName = _controller.conceptName(recommendation.conceptId);
    final weaknessTitle = recommendation.type.replaceAll('_', ' ');
    final weaknessCaption = 'Concept: $conceptName';
    final subtopicTitle = recommendation.title;
    final subtopicCaption = recommendation.reason;
    final recommendationText = recommendation.message;
    final practiceRoute = _routeFor(recommendation);
    final others = _controller.recommendations.skip(1).toList();

    return RefreshIndicator(
      onRefresh: () => _load(analyse: true),
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
                    child: const Icon(Icons.track_changes_rounded, color: AppColors.onAccent),
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
                      icon: _iconFor(recommendation.type),
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
                              color: AppColors.onAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                            ),
                            child: const Icon(Icons.lightbulb_outline_rounded,
                                color: AppColors.onAccent, size: 16),
                          ),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Recommended:',
                                    style: AppTextStyles.bodyBold
                                        .copyWith(color: AppColors.onAccent)),
                                const SizedBox(height: 2),
                                Text(recommendationText,
                                    style: AppTextStyles.body
                                        .copyWith(color: AppColors.onAccent.withOpacity(0.9))),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingSm),
                          const Icon(Icons.bar_chart_rounded, color: AppColors.onAccent, size: 28),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    DualIconButton(
                      label: 'START RECOMMENDED PRACTICE',
                      leadingIcon: Icons.play_arrow_rounded,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: () => Navigator.of(context)
                          .pushNamed(practiceRoute, arguments: {'conceptId': recommendation.conceptId}),
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
                    const SizedBox(height: AppDimensions.spacingSm),
                    TextButton(
                      onPressed: () => _controller.completeRecommendation(recommendation),
                      child: const Text('Mark as done', style: TextStyle(color: AppColors.accentCyan)),
                    ),
                  ],
                ),
              ),
              if (others.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingLg),
                Text('Also on your list', style: AppTextStyles.bodyBold),
                const SizedBox(height: AppDimensions.spacingSm),
                for (final r in others)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                    child: _WeaknessTile(
                      icon: _iconFor(r.type),
                      color: AppColors.accentCyan,
                      title: r.title,
                      titleCase: false,
                      caption: '${_controller.conceptName(r.conceptId)}: ${r.message}',
                    ),
                  ),
              ],
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
