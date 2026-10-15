import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/glow_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../concepts/presentation/widgets/concept_header.dart';
import '../../../concepts/presentation/widgets/concept_progress.dart';
import '../data/models/canonical_knowledge_model.dart';
import '../presentation/state/explanation_controller.dart';
import '../widgets/explanation_card.dart';

/// "Understand" stage of the concept learning flow — AI-generated
/// "Key Points"/"Rules"/"Example" content (from
/// `POST /api/ai/canonical-knowledge`), an "Ask for Clarification"
/// affordance, and a "Next: Visualize" CTA that hands off to the
/// Visualize stage.
class ExplanationScreen extends StatefulWidget {
  final String conceptId;

  const ExplanationScreen({super.key, required this.conceptId});

  @override
  State<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends State<ExplanationScreen> {
  final _controller = ExplanationController.instance;

  bool _simplified = false;
  bool _showKeyPoints = false;
  bool _showRules = false;
  bool _showExample = false;

  @override
  void initState() {
    super.initState();
    _controller.loadCanonicalKnowledge(widget.conceptId);
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppDimensions.spacingMd),
            child: Center(
              child: Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final knowledge = _controller.knowledge;

            if (_controller.isLoading && knowledge == null) {
              return const LoadingView(message: 'Fetching key points, rules & examples...');
            }
            if (_controller.errorMessage != null && knowledge == null) {
              return ErrorView(
                message: _controller.errorMessage!,
                onRetry: () =>
                    _controller.loadCanonicalKnowledge(widget.conceptId, force: true),
              );
            }

            return _Content(
              conceptId: widget.conceptId,
              knowledge: knowledge,
              simplified: _simplified,
              onToggleSimplified: (v) => setState(() => _simplified = v),
              showKeyPoints: _showKeyPoints,
              onToggleKeyPoints: () => setState(() => _showKeyPoints = !_showKeyPoints),
              showRules: _showRules,
              onToggleRules: () => setState(() => _showRules = !_showRules),
              showExample: _showExample,
              onToggleExample: () => setState(() => _showExample = !_showExample),
            );
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  // TODO: replace with real concept metadata once GET /api/concepts/{id}
  // (or equivalent) is available — canonical-knowledge only returns
  // keyPoints/rules/examples, not the concept's title/description.
  static const _title = 'Loop Boundaries';
  static const _difficulty = 'Medium';
  static const _tags = ['Loops', 'Control Flow', 'Logic'];
  static const _conceptExplanation =
      'Loop boundaries define the starting point, ending point, and the '
      'condition under which a loop will continue or stop. They help '
      'control how many times a block of code is executed, preventing '
      'infinite loops or skipped iterations.';
  static const _simplifiedExplanation =
      "Think of a loop like walking down a hallway of numbered doors. "
      "The boundary tells you which door to start at and which door to "
      "stop at — get it wrong and you either miss doors or keep walking "
      "forever.";

  final String conceptId;
  final CanonicalKnowledgeModel? knowledge;
  final bool simplified;
  final ValueChanged<bool> onToggleSimplified;
  final bool showKeyPoints;
  final VoidCallback onToggleKeyPoints;
  final bool showRules;
  final VoidCallback onToggleRules;
  final bool showExample;
  final VoidCallback onToggleExample;

  const _Content({
    required this.conceptId,
    required this.knowledge,
    required this.simplified,
    required this.onToggleSimplified,
    required this.showKeyPoints,
    required this.onToggleKeyPoints,
    required this.showRules,
    required this.onToggleRules,
    required this.showExample,
    required this.onToggleExample,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ConceptHeader(
            title: _title,
            difficulty: _difficulty,
            tags: _tags,
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
          ExplanationCard(
            simplified: simplified,
            onToggle: onToggleSimplified,
            conceptExplanation: _conceptExplanation,
            simplifiedExplanation: _simplifiedExplanation,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
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
                        fontFamily: 'monospace',
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
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.primaryLight, size: 20),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Still confused?', style: AppTextStyles.bodyBold),
                      Text(
                        'Ask our AI for a simpler explanation or specific help.',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                TextButton.icon(
                  onPressed: () {
                    onToggleSimplified(true);
                    AppSnackBar.show(context, 'Here\'s a simpler take on it above.');
                  },
                  icon: const Icon(Icons.auto_awesome_rounded,
                      size: 16, color: AppColors.accentCyan),
                  label: const Text('Ask for Clarification',
                      style: TextStyle(color: AppColors.accentCyan)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          AppButton(
            label: 'Next: Visualize',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(context).pushReplacementNamed(
              RouteNames.relate,
              arguments: {'conceptId': conceptId},
            ),
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
