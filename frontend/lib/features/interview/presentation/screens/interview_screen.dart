import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/dual_icon_button.dart';
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
  bool _isSubmitting = false;

  Future<void> _submit() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    setState(() => _isSubmitting = true);
    final controller = InterviewController.instance;
    final success = await controller.submitAnswer(answer);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final error = controller.errorMessage;
    if (!success && error != null) {
      AppSnackBar.error(context, error);
      return;
    }
    Navigator.of(context).pushReplacementNamed(RouteNames.interviewResult);
  }

  @override
  void dispose() {
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
            child: Center(child: _XpChip(xp: 840)),
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
                    child: const Icon(Icons.forum_rounded, color: AppColors.white),
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimensions.spacingLg),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                          border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
                                  ),
                                  child: const Icon(Icons.smart_toy_rounded,
                                      color: AppColors.white, size: 22),
                                ),
                                const SizedBox(width: AppDimensions.spacingMd),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.btnAccentPurple.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(AppDimensions.radiusPill),
                                          border: Border.all(
                                              color: AppColors.btnAccentPurple.withOpacity(0.5)),
                                        ),
                                        child: Text('Interviewer',
                                            style: AppTextStyles.caption
                                                .copyWith(color: AppColors.btnAccentPurple)),
                                      ),
                                      const SizedBox(height: AppDimensions.spacingSm),
                                      Text(
                                        InterviewController.instance.currentQuestion
                                                ?.question ??
                                            'Loading your question…',
                                        style: AppTextStyles.bodyBold.copyWith(fontSize: 17),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),
                      AnswerInput(
                        controller: _answerController,
                        hintText: 'Your answer...',
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),
                      DualIconButton(
                        label: 'Answer',
                        leadingIcon: Icons.auto_awesome_rounded,
                        trailingIcon: Icons.arrow_forward_rounded,
                        isLoading: _isSubmitting,
                        onPressed: _submit,
                      ),
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
                                'After your answer, the AI will ask a follow-up '
                                'question to go deeper.',
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
