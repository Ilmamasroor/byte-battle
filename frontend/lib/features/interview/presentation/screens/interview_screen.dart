import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/ai/companion_says.dart';
import '../../../../core/widgets/ai/key_term_text.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';
import '../../../../core/widgets/brand/score_ring.dart';
import '../../../../core/widgets/dual_icon_button.dart';
import '../../../performance/presentation/widgets/xp_chip.dart';
import '../state/interview_controller.dart';
import '../widgets/answer_input.dart';

/// "Technical Interview" screen — matches the reference screenshot:
/// back button + BYTE BATTLE header + XP chip, an icon/title/subtitle
/// intro, a chat-style "Interviewer" question bubble with a robot
/// avatar, a free-text answer box with character counter, an Answer
/// CTA, and a footer note about the AI follow-up question.
///
/// The question shown comes from `POST /api/ai/interview/question`
/// (already loaded by [InterviewIntroScreen] before navigating here);
/// submitting an answer calls `POST /api/ai/interview/evaluate`.
class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final _answerController = TextEditingController();
  final _controller = InterviewController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty || _controller.isSending) return;
    final ok = await _controller.submit(answer);
    if (!mounted) return;
    if (!ok) {
      AppSnackBar.error(context, _controller.errorMessage ?? 'Could not send your answer.');
      return;
    }
    _answerController.clear();
  }

  Future<void> _finish() async {
    final ok = await _controller.complete();
    if (!mounted) return;
    if (!ok) {
      AppSnackBar.error(context, _controller.errorMessage ?? 'Could not finish the interview.');
      return;
    }
    Navigator.of(context).pushReplacementNamed(RouteNames.interviewResult);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _answerController.dispose();
    super.dispose();
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
            child: Center(child: LiveXpChip()),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: const Icon(Icons.forum_rounded, color: AppColors.onAccent),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Technical Interview', style: AppTextStyles.heading1),
                        Text(
                          'Think like an engineer. Explain your logic. Build your confidence.',
                          style: AppTextStyles.body.copyWith(color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_controller.lastAnswer != null) ...[
                        _FeedbackCard(
                          answer: _controller.lastAnswer!,
                          number: _controller.answers.length,
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),
                      ],
                      Text('QUESTION ${(_controller.answers.length + 1).clamp(1, 5)} OF 5', style: AppTextStyles.eyebrow.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 10),
                      CompanionSays(
                        mood: BitMood.curious,
                        mascotSize: 64,
                        showName: false,
                        text: _controller.currentQuestion ?? 'No interview in progress.',
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),
                      if (!_controller.noMoreQuestions) ...[
                        AnswerInput(
                          controller: _answerController,
                          hintText: 'Your answer...',
                        ),
                        const SizedBox(height: AppDimensions.spacingLg),
                        DualIconButton(
                          label: 'Answer',
                          leadingIcon: Icons.auto_awesome_rounded,
                          trailingIcon: Icons.arrow_forward_rounded,
                          isLoading: _controller.isSending,
                          onPressed: _submit,
                        ),
                      ],
                      if (_controller.answers.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingMd),
                        DualIconButton(
                          label: 'Finish interview',
                          leadingIcon: Icons.flag_rounded,
                          trailingIcon: Icons.arrow_forward_rounded,
                          outlined: !_controller.noMoreQuestions,
                          isLoading: _controller.isCompleting,
                          onPressed: _controller.isSending ? null : _finish,
                        ),
                      ],
                      const SizedBox(height: AppDimensions.spacingLg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimensions.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded,
                                color: AppColors.btnGamificationPink, size: 18),
                            const SizedBox(width: AppDimensions.spacingSm),
                            Expanded(
                              child: Text(
                                _controller.noMoreQuestions
                                    ? 'That was the last question. Finish to see your result.'
                                    : 'After your answer, the AI grades it and asks a follow-up '
                                        'question (up to 5 questions).',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.primaryLight),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded,
                                color: AppColors.primaryLight, size: 16),
                          ],
                        ),
                      ),
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

class _FeedbackCard extends StatelessWidget {
  final InterviewAnswer answer;
  final int number;
  const _FeedbackCard({required this.answer, required this.number});

  static String _reaction(int? score) {
    if (score == null) return 'I could not grade that one, but I saved it. On to the next!';
    if (score >= 70) return 'Strong answer. That is how an engineer explains it.';
    if (score >= 40) return 'Good start. A bit more depth and it is there.';
    return 'Not there yet, and that is fine. Read my note, then try the next one.';
  }

  @override
  Widget build(BuildContext context) {
    final score = answer.score;
    final color = score == null ? AppColors.textHint : ScoreRing.colorFor(score);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (score != null) ScoreRing(score: score, size: 76) else const Icon(Icons.hourglass_empty_rounded, size: 40, color: AppColors.textHint),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ANSWER $number', style: AppTextStyles.eyebrow.copyWith(color: color)),
                const SizedBox(height: 4),
                Text(_reaction(score), style: AppTextStyles.bodyBold.copyWith(fontSize: 14, height: 1.4)),
                if (answer.feedback.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  KeyTermText(text: answer.feedback, style: AppTextStyles.body.copyWith(fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
