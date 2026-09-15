import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glow_card.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../learning/explanation/data/models/canonical_knowledge_model.dart';
import '../state/battle_ai_controller.dart';
import 'hint_button.dart';

/// Full-screen "wrong answer" feedback shown after an incorrect Battle
/// pick — matches the "Not quite." reference screen: a topic chip, a
/// sad mascot mark, the headline + explanation of what was missed, a
/// numbered list of expandable hints, and a "Try Again" CTA that pops
/// back to the battle round so the person can retry the same question.
///
/// Pushed only from [BattleScreen] when the selected answer is wrong —
/// it is never a tab/nav destination, so it can't end up shown out of
/// context. The static [hints] are fallback copy baked into the push
/// call; "Get AI Hint" below them calls the real
/// `POST /api/ai/battle-hint` for a fresh, progressive hint instead.
class BattleFeedback extends StatefulWidget {
  final String topicLabel;
  final String message;
  final List<String> hints;
  final String quote;
  final String? question;

  const BattleFeedback({
    super.key,
    this.topicLabel = 'Practice',
    this.message = 'You got the core idea, but missed one detail.',
    this.hints = const [],
    this.quote = 'Every bug is a lesson in disguise.',
    this.question,
  });

  @override
  State<BattleFeedback> createState() => _BattleFeedbackState();
}

class _BattleFeedbackState extends State<BattleFeedback> {
  // TODO: replace with the concept/canonical knowledge actually being
  // battled once that context flows through from BattleScreen.
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
  int _hintLevel = 0;

  Future<void> _getAiHint() async {
    _hintLevel = _hintLevel >= 3 ? 3 : _hintLevel + 1;
    await _controller.loadBattleHint(
      concept: _concept,
      question: widget.question ?? widget.message,
      canonicalKnowledge: _canonicalKnowledge,
      hintLevel: _hintLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    Helpers.noApiYet('BattleFeedback', note: 'hint list is hardcoded fallback; Get AI Hint calls POST /api/ai/battle-hint');
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.smart_toy_outlined,
                            size: 14, color: AppColors.accentCyan),
                        const SizedBox(width: 6),
                        Text(widget.topicLabel, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppDimensions.spacingLg),
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 30,
                                  spreadRadius: -6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.sentiment_dissatisfied_rounded,
                                color: AppColors.white, size: 46),
                          ),
                          Positioned(
                            right: -6,
                            top: -2,
                            child: Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: AppColors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),
                      GlowCard(
                        glowColor: AppColors.error,
                        borderColor: AppColors.error,
                        padding: const EdgeInsets.all(AppDimensions.spacingLg),
                        child: Column(
                          children: [
                            Text(
                              'Not quite.',
                              style: AppTextStyles.heading1.copyWith(color: AppColors.error),
                            ),
                            const SizedBox(height: AppDimensions.spacingSm),
                            Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body,
                            ),
                            if (widget.hints.isNotEmpty) ...[
                              const SizedBox(height: AppDimensions.spacingLg),
                              Row(
                                children: const [
                                  Icon(Icons.lightbulb_outline_rounded,
                                      color: AppColors.warning, size: 18),
                                  SizedBox(width: AppDimensions.spacingSm),
                                  Text('Need help?', style: AppTextStyles.bodyBold),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('Here are some hints to guide you.',
                                  style: AppTextStyles.caption),
                              const SizedBox(height: AppDimensions.spacingMd),
                              ...List.generate(widget.hints.length, (i) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppDimensions.spacingSm),
                                  child: HintButton(number: i + 1, text: widget.hints[i]),
                                );
                              }),
                            ],
                            const SizedBox(height: AppDimensions.spacingMd),
                            ListenableBuilder(
                              listenable: _controller,
                              builder: (context, _) {
                                final aiHint = _controller.battleHint?.hint;
                                final isLoading = _controller.isHintLoading;
                                final error = _controller.hintErrorMessage;
                                return Column(
                                  children: [
                                    if (aiHint != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: AppDimensions.spacingSm),
                                        child: HintButton(
                                          number: widget.hints.length + 1,
                                          text: aiHint.hint,
                                        ),
                                      ),
                                    if (error != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: AppDimensions.spacingSm),
                                        child: Text(error,
                                            style: AppTextStyles.caption
                                                .copyWith(color: AppColors.error)),
                                      ),
                                    AppButton(
                                      label: aiHint == null ? 'Get AI Hint' : 'Get a Stronger Hint',
                                      icon: Icons.smart_toy_outlined,
                                      outlined: true,
                                      isLoading: isLoading,
                                      onPressed: _hintLevel >= 3 ? null : _getAiHint,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),
                      AppButton(
                        label: 'Try Again',
                        icon: Icons.refresh_rounded,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                      Text(
                        '"${widget.quote}"',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}
