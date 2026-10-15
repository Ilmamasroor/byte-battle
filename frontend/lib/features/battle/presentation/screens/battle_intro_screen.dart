import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../learning/explanation/data/models/canonical_knowledge_model.dart';
import '../../data/models/boss_battle_model.dart';
import '../state/battle_ai_controller.dart';

/// "Challenge Prep" screen — shown before a timed Boss Battle stage.
/// Matches the boss-battle intro screenshot: skull badge, BOSS BATTLE
/// title, concept subtitle, Lives / Rounds info cards, a Time Limit
/// card, the primary CONTINUE cta and a one-attempt warning banner.
class BattleIntroScreen extends StatefulWidget {
  final String bossTitle;
  final String conceptSubtitle;
  final String description;
  final int lives;
  final int rounds;
  final String timeLimitLabel;

  const BattleIntroScreen({
    super.key,
    this.bossTitle = 'BOSS BATTLE',
    this.conceptSubtitle = 'Binary Search Master',
    this.description =
        'Prove that you\'ve mastered the concept. Solve the maze, trace '
        'the array, and defeat the system boundaries.',
    this.lives = 3,
    this.rounds = 5,
    this.timeLimitLabel = '05:00',
  });

  @override
  State<BattleIntroScreen> createState() => _BattleIntroScreenState();
}

class _BattleIntroScreenState extends State<BattleIntroScreen> {
  // TODO: replace with the concept actually being battled, plus its real
  // canonical knowledge (e.g. from ExplanationController once that stage
  // has run for this concept) instead of an empty placeholder.
  static const _concept = ConceptModel(
    id: '00000000-0000-0000-0000-000000001001',
    name: 'Java Fundamentals',
    difficulty: 'BEGINNER',
  );
  static const _canonicalKnowledge = CanonicalKnowledgeModel(
    keyPoints: [],
    rules: [],
    examples: [],
  );

  final _controller = BattleAiController.instance;

  @override
  void initState() {
    super.initState();
    _controller.loadBossBattle(concept: _concept, canonicalKnowledge: _canonicalKnowledge);
  }

  @override
  Widget build(BuildContext context) {
    Helpers.noApiYet('BattleIntroScreen', note: 'lives/rounds/timer are hardcoded; boss briefing calls POST /api/ai/boss-battle');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Challenge Prep', style: AppTextStyles.bodyBold),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppDimensions.spacingMd),
            child: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.spacingXl),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withOpacity(0.12),
                  border: Border.all(color: AppColors.error.withOpacity(0.6), width: 1.5),
                ),
                child: const Icon(Icons.face_retouching_off_rounded,
                    color: AppColors.error, size: 40),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              Text(
                widget.bossTitle,
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.error,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(widget.conceptSubtitle, style: AppTextStyles.bodyBold),
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _BossBriefingCard(
                  isLoading: _controller.isBossBattleLoading,
                  errorMessage: _controller.bossBattleErrorMessage,
                  bossBattle: _controller.bossBattle,
                  onRetry: () => _controller.loadBossBattle(
                    concept: _concept,
                    canonicalKnowledge: _canonicalKnowledge,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      label: 'LIVES',
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: AppDimensions.spacingXs),
                          Text('x${widget.lives}', style: AppTextStyles.bodyBold),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: _InfoCard(
                      label: 'ROUNDS',
                      child: Row(
                        children: [
                          const Icon(Icons.flag_rounded, color: AppColors.primaryLight, size: 18),
                          const SizedBox(width: AppDimensions.spacingXs),
                          Text('${widget.rounds}', style: AppTextStyles.bodyBold),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _InfoCard(
                label: 'TIME LIMIT',
                fullWidth: true,
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: AppDimensions.spacingXs),
                    Text(widget.timeLimitLabel, style: AppTextStyles.bodyBold),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              AppButton(
                label: 'CONTINUE',
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(RouteNames.battle),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spacingMd,
                  horizontal: AppDimensions.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.error.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Expanded(
                      child: Text(
                        'Retry allowed only once. Lose all lives and the boss wins.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the AI-generated boss battle scenario (`POST /api/ai/boss-battle`)
/// — a loading spinner while it's in flight, a retry affordance on
/// failure, and the scenario text + suggested-approach chips once loaded.
class _BossBriefingCard extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final BossBattleModel? bossBattle;
  final VoidCallback onRetry;

  const _BossBriefingCard({
    required this.isLoading,
    required this.errorMessage,
    required this.bossBattle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.accentCyan),
              const SizedBox(width: AppDimensions.spacingSm),
              Text('AI Boss Briefing', style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.accentCyan),
                ),
              ),
            )
          else if (errorMessage != null)
            Row(
              children: [
                Expanded(
                  child: Text(errorMessage!,
                      style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            )
          else if (bossBattle != null) ...[
            Text(bossBattle!.scenario, style: AppTextStyles.body),
            if (bossBattle!.suggestedOptions.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spacingSm),
              Wrap(
                spacing: AppDimensions.spacingSm,
                runSpacing: AppDimensions.spacingSm,
                children: [
                  for (final option in bossBattle!.suggestedOptions)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(option, style: AppTextStyles.caption),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final Widget child;
  final bool fullWidth;

  const _InfoCard({required this.label, required this.child, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppDimensions.spacingXs),
          child,
        ],
      ),
    );
  }
}
