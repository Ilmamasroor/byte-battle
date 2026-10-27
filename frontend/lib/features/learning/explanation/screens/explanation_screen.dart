import 'package:flutter/material.dart';
import '../../data/learning_progress_service.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/glow_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../concepts/presentation/state/concept_controller.dart';
import '../../../concepts/presentation/widgets/concept_header.dart';
import '../../../concepts/presentation/widgets/concept_progress.dart';
import '../data/models/canonical_knowledge_model.dart';
import '../data/models/explanation_model.dart';
import '../presentation/state/explanation_controller.dart';
import '../../../../core/widgets/ai/companion_says.dart';
import '../../../../core/widgets/ai/story_deck.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';

/// "Understand" stage of the concept learning flow: the concept's real metadata (`GET /api/concepts/{id}`), the
/// grounded + personalized AI explanation (`POST /api/ai/explanation`), the canonical Key Points / Rules /
/// Example (`POST /api/ai/canonical-knowledge`), and a "Next: Visualize" CTA.
class ExplanationScreen extends StatefulWidget {
  final String conceptId;

  const ExplanationScreen({super.key, required this.conceptId});

  @override
  State<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends State<ExplanationScreen> {
  final _controller = ExplanationController.instance;
  final _concept = ConceptController();

  bool _overview = false;
  bool _showKeyPoints = false;
  bool _showRules = false;
  bool _showExample = false;

  @override
  void initState() {
    super.initState();
    _concept.load(widget.conceptId);
    _controller.load(widget.conceptId);
  }

  @override
  void dispose() {
    _concept.dispose();
    super.dispose();
  }

  void _retry() {
    _concept.load(widget.conceptId, force: true);
    _controller.load(widget.conceptId, force: true);
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_controller, _concept]),
          builder: (context, _) {
            final hasContent = _controller.knowledge != null || _controller.explanation != null;

            if ((_controller.isLoading || _concept.isLoading) && !hasContent) {
              return const LoadingView(message: 'Preparing your explanation...');
            }
            if (_concept.concept == null && _concept.errorMessage != null) {
              return ErrorView(message: _concept.errorMessage!, onRetry: _retry);
            }
            if (_controller.failedCompletely) {
              return ErrorView(message: _controller.errorMessage!, onRetry: _retry);
            }

            return _Content(
              conceptId: widget.conceptId,
              concept: _concept.concept,
              explanation: _controller.explanation,
              explanationError: _controller.explanationError,
              knowledge: _controller.knowledge,
              knowledgeError: _controller.knowledgeError,
              refreshing: _controller.isLoading,
              overview: _overview,
              onToggleOverview: (v) => setState(() => _overview = v),
              showKeyPoints: _showKeyPoints,
              onToggleKeyPoints: () => setState(() => _showKeyPoints = !_showKeyPoints),
              showRules: _showRules,
              onToggleRules: () => setState(() => _showRules = !_showRules),
              showExample: _showExample,
              onToggleExample: () => setState(() => _showExample = !_showExample),
              onRegenerate: () {
                setState(() => _overview = false);
                _controller.load(widget.conceptId, force: true);
              },
            );
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final String conceptId;
  final ConceptModel? concept;
  final ExplanationModel? explanation;
  final String? explanationError;
  final CanonicalKnowledgeModel? knowledge;
  final String? knowledgeError;
  final bool refreshing;
  final bool overview;
  final ValueChanged<bool> onToggleOverview;
  final bool showKeyPoints;
  final VoidCallback onToggleKeyPoints;
  final bool showRules;
  final VoidCallback onToggleRules;
  final bool showExample;
  final VoidCallback onToggleExample;
  final VoidCallback onRegenerate;

  const _Content({
    required this.conceptId,
    required this.concept,
    required this.explanation,
    required this.explanationError,
    required this.knowledge,
    required this.knowledgeError,
    required this.refreshing,
    required this.overview,
    required this.onToggleOverview,
    required this.showKeyPoints,
    required this.onToggleKeyPoints,
    required this.showRules,
    required this.onToggleRules,
    required this.showExample,
    required this.onToggleExample,
    required this.onRegenerate,
  });

  String get _explanationText {
    final e = explanation;
    if (e != null && e.content.isNotEmpty) return e.content;
    if (explanationError != null) return 'The AI explanation could not be loaded: $explanationError';
    return 'No explanation is available for this concept yet.';
  }

  String get _overviewText {
    final d = concept?.description?.trim() ?? '';
    return d.isEmpty ? 'No overview is available for this concept yet.' : d;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConceptHeader(
            title: concept?.name ?? 'Concept',
            difficulty: difficultyLabel(concept?.difficulty),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          ConceptProgress(
            current: ConceptStage.understand,
            conceptId: conceptId,
            routes: const {
              ConceptStage.concept: RouteNames.conceptDetail,
              ConceptStage.understand: RouteNames.understand,
              ConceptStage.visualize: RouteNames.explore,
            },
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          CompanionSays(
            mood: BitMood.curious,
            text: explanation?.fallback == true
                ? 'My AI brain is offline, so here is the basic version. Tap Explain again in a moment.'
                : 'Here is ${concept?.name ?? 'this idea'} in a few quick cards${explanation?.personalized == true ? ', shaped around how you learn' : ''}. Tap through at your own pace.',
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              _ModeChip(label: 'Story cards', selected: !overview, onTap: () => onToggleOverview(false)),
              const SizedBox(width: 8),
              _ModeChip(label: 'Quick overview', selected: overview, onTap: () => onToggleOverview(true)),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          StoryDeck(
            key: ValueKey('${overview}_${(overview ? _overviewText : _explanationText).hashCode}'),
            cards: StoryDeck.fromText(overview ? _overviewText : _explanationText),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          if (knowledgeError != null && knowledge == null) Text('Key points could not be loaded: $knowledgeError', style: AppTextStyles.caption),
          _ExpandableSection(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Key Points',
            expanded: showKeyPoints,
            onTap: onToggleKeyPoints,
            child: _BulletList(items: knowledge?.keyPoints ?? const []),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          _ExpandableSection(
            icon: Icons.rule_rounded,
            label: 'Rules',
            expanded: showRules,
            onTap: onToggleRules,
            child: _BulletList(items: knowledge?.rules ?? const []),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          _ExpandableSection(
            icon: Icons.code_rounded,
            label: 'Example',
            expanded: showExample,
            onTap: onToggleExample,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((knowledge?.examples ?? const []).isEmpty) Text('Nothing here yet.', style: AppTextStyles.caption),
                for (final example in (knowledge?.examples ?? const []))
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      example,
                      style: AppTextStyles.body.copyWith(
                        fontFamily: AppTextStyles.monoFamily,
                        color: AppColors.accentCyan,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          GlowCard(
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Still confused?', style: AppTextStyles.bodyBold),
                      Text(
                        'Ask our AI to explain it again, from a fresh angle.',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                TextButton.icon(
                  onPressed: refreshing ? null : onRegenerate,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.accentCyan),
                  label: Text(refreshing ? 'Thinking...' : 'Explain Again', style: const TextStyle(color: AppColors.accentCyan)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          AppButton(
            label: 'Next: Visualize',
            icon: Icons.arrow_forward_rounded,
            onPressed: () async {
              await LearningProgressService.completeIfAt(conceptId, 'UNDERSTAND');
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed(
                RouteNames.explore,
                arguments: {'conceptId': conceptId},
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('Nothing here yet.', style: AppTextStyles.caption);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, size: 5, color: AppColors.accentCyan),
                const SizedBox(width: AppDimensions.spacingSm),
                Expanded(child: Text(item, style: AppTextStyles.body)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const _ExpandableSection({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.accentCyan, size: 18),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(child: Text(label, style: AppTextStyles.bodyBold)),
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingMd,
                0,
                AppDimensions.spacingMd,
                AppDimensions.spacingMd,
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: AppTextStyles.caption.copyWith(color: selected ? AppColors.onAccent : AppColors.textSecondary, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
