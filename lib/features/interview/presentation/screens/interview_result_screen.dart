import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/dual_icon_button.dart';
import '../../data/models/interview_result_model.dart';
import '../state/interview_controller.dart';

class _CriterionRow {
  final String label;
  final IconData icon;
  final Color color;
  final int scoreOf5;

  const _CriterionRow(this.label, this.icon, this.color, this.scoreOf5);
}

/// "Explanation Feedback" screen — matches the reference screenshot:
/// back button + BYTE BATTLE header + XP chip, a "Your Explanation"
/// scorecard (5 criteria bars + an Overall x/20) and an AI Feedback
/// callout, sourced from `POST /api/ai/interview/evaluate`'s response
/// (set by [InterviewScreen] before navigating here), plus a Continue CTA.
class InterviewResultScreen extends StatelessWidget {
  const InterviewResultScreen({super.key});

  /// Converts a 0.0–1.0 API score into the 0–5 scale the bars use.
  static int _scoreOf5(double score) => (score * 5).round().clamp(0, 5);

  static List<_CriterionRow> _criteriaFor(InterviewEvaluationModel e) => [
        _CriterionRow('Conceptual Correctness', Icons.check_circle_rounded,
            AppColors.success, _scoreOf5(e.conceptualCorrectness)),
        _CriterionRow('Reasoning', Icons.psychology_rounded,
            AppColors.btnAccentPurple, _scoreOf5(e.reasoning)),
        _CriterionRow('Technical Clarity', Icons.menu_book_rounded,
            AppColors.accentCyan, _scoreOf5(e.technicalClarity)),
        _CriterionRow('Completeness', Icons.track_changes_rounded,
            AppColors.btnGamificationPink, _scoreOf5(e.completeness)),
        _CriterionRow('Explanation', Icons.description_rounded,
            AppColors.btnWarningOrange, _scoreOf5(e.explanation)),
      ];

  @override
  Widget build(BuildContext context) {
    final evaluation = InterviewController.instance.lastEvaluation;
    final criteria = evaluation != null ? _criteriaFor(evaluation) : const <_CriterionRow>[];
    final overall = evaluation?.overallOf20 ?? 0;
    final feedback = evaluation?.feedback ??
        'No feedback yet — answer a question on the interview screen first.';

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
        child: SingleChildScrollView(
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
                    child: const Icon(Icons.fact_check_rounded, color: AppColors.white),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Explanation Feedback', style: AppTextStyles.heading1),
                        Text(
                          "Great effort! Here's how your explanation performed "
                          "and what to improve.",
                          style: AppTextStyles.body.copyWith(color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bar_chart_rounded, color: AppColors.accentCyan, size: 18),
                        const SizedBox(width: AppDimensions.spacingSm),
                        Text('YOUR EXPLANATION',
                            style: AppTextStyles.bodyBold.copyWith(letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    for (final c in criteria)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                        child: _CriterionBar(row: c),
                      ),
                    const Divider(color: AppColors.divider, height: AppDimensions.spacingLg),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded,
                            color: AppColors.btnAccentPurple, size: 20),
                        const SizedBox(width: AppDimensions.spacingSm),
                        Expanded(
                          child: Text('Overall', style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$overall',
                                style: AppTextStyles.heading1
                                    .copyWith(fontSize: 30, color: AppColors.accentCyan),
                              ),
                              const TextSpan(
                                text: '/20',
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _CalloutCard(
                icon: Icons.auto_awesome_rounded,
                color: AppColors.btnAccentPurple,
                title: 'AI Feedback:',
                child: _BulletLine(icon: Icons.arrow_forward_rounded, text: feedback),
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              DualIconButton(
                label: 'Continue',
                leadingIcon: Icons.auto_awesome_rounded,
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(RouteNames.dashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CriterionBar extends StatelessWidget {
  final _CriterionRow row;
  const _CriterionBar({required this.row});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: row.color.withOpacity(0.15),
          ),
          child: Icon(row.icon, color: row.color, size: 15),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          flex: 4,
          child: Text(row.label,
              style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: LinearProgressIndicator(
              value: row.scoreOf5 / 5,
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(row.color),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        SizedBox(
          width: 28,
          child: Text('${row.scoreOf5}/5',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
        ),
      ],
    );
  }
}

class _CalloutCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  const _CalloutCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          child,
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BulletLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.accentCyan),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(child: Text(text, style: AppTextStyles.body)),
      ],
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
