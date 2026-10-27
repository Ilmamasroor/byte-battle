import 'package:flutter/material.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/network/backend_api.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../data/models/boss_battle_model.dart';
import '../state/battle_ai_controller.dart';
import '../state/battle_controller.dart';

/// "Challenge Prep" screen — shown before a timed Boss Battle stage.
/// Matches the boss-battle intro screenshot: skull badge, BOSS BATTLE
/// title, concept subtitle, Lives / Rounds info cards, a Time Limit
/// card, the primary CONTINUE cta and a one-attempt warning banner.
class BattleIntroScreen extends StatefulWidget {
  final String conceptId;

  const BattleIntroScreen({super.key, required this.conceptId});

  @override
  State<BattleIntroScreen> createState() => _BattleIntroScreenState();
}

class _BattleIntroScreenState extends State<BattleIntroScreen> {
  final _controller = BattleAiController.instance;

  ConceptInfo? _concept;
  BattleInfo? _battle;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = BackendApi.instance;
      final results = await Future.wait<Object>([api.battles(), api.concept(widget.conceptId)]);
      final concept = results[1] as ConceptInfo;
      final battle = pickBattle(results[0] as List<BattleInfo>, widget.conceptId, boss: true);
      if (!mounted) return;
      setState(() {
        _concept = concept;
        _battle = battle;
        _error = battle == null ? 'There is no boss battle for ${concept.name} yet.' : null;
        _loading = false;
      });
      if (battle != null) _loadBriefing();
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the boss battle. Please try again.';
        _loading = false;
      });
    }
  }

  /// `POST /api/ai/boss-battle`: the AI briefing for this concept.
  Future<void> _loadBriefing() async {
    final c = _concept;
    if (c == null) return;
    final knowledge = await _controller.canonicalFor(c.id);
    if (!mounted) return;
    await _controller.loadBossBattle(
      concept: ConceptModel(id: c.id, name: c.name, description: c.description, difficulty: c.difficulty),
      canonicalKnowledge: knowledge,
    );
  }

  static String _timeLabel(int seconds) {
    if (seconds <= 0) return 'No limit';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s per question';
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SafeArea(
        child: _loading
            ? const LoadingView(message: 'Summoning the boss...')
            : _battle == null
                ? ErrorView(message: _error ?? 'Could not load the boss battle.', onRetry: _load)
                : _buildBody(context, _battle!),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BattleInfo battle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.spacingXl),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orchid.withOpacity(0.14),
              border: Border.all(color: AppColors.orchid.withOpacity(0.6), width: 1.5),
            ),
            child: const Icon(Icons.pest_control_rounded, color: AppColors.orchid, size: 44),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Text(
            'BOSS BATTLE',
            style: AppTextStyles.eyebrow.copyWith(color: AppColors.orchid, fontSize: 13, letterSpacing: 3),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(_concept?.name ?? battle.title, style: AppTextStyles.display.copyWith(fontSize: 30), textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            battle.description.isNotEmpty ? battle.description : battle.title,
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
              onRetry: _loadBriefing,
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
                      Text('x${battle.totalLives}', style: AppTextStyles.bodyBold),
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
                      Text('${battle.totalQuestions}', style: AppTextStyles.bodyBold),
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
                Text(_timeLabel(battle.timeLimitSeconds), style: AppTextStyles.bodyBold),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          AppButton(
            label: 'CONTINUE',
            onPressed: () => Navigator.of(context).pushReplacementNamed(
              RouteNames.battle,
              arguments: {'conceptId': widget.conceptId, 'boss': true},
            ),
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
                    'Lose all ${battle.totalLives} lives and the boss wins.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
        ],
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
