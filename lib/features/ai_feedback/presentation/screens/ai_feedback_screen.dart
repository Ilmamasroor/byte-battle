import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

class _PerfRow {
  final String label;
  final String caption;
  final IconData icon;
  final Color color;
  final int scoreOf10;

  const _PerfRow(this.label, this.caption, this.icon, this.color, this.scoreOf10);
}

/// "Performance Diagnosis" screen — matches the reference screenshot:
/// back button + BYTE BATTLE header + XP chip, an icon/title/subtitle
/// intro, four skill cards (Understanding / Application / Debugging /
/// Communication) each with a percentage, a segmented 10-step progress
/// bar and an "x / 10" fraction, then a "Detected Pattern" insight
/// card with a recurring-issue callout.
class AiFeedbackScreen extends StatelessWidget {
  const AiFeedbackScreen({super.key});

  // TODO: replace with data from AiFeedbackController / ai_analysis_model.dart
  static const _rows = [
    _PerfRow('Understanding', 'Grasp concepts and logic',
        Icons.lightbulb_outline_rounded, AppColors.accentCyan, 8),
    _PerfRow('Application', 'Use knowledge in real scenarios',
        Icons.code_rounded, AppColors.btnAccentPurple, 6),
    _PerfRow('Debugging', 'Find and fix issues efficiently',
        Icons.bug_report_rounded, AppColors.btnGamificationPink, 4),
    _PerfRow('Communication', 'Explain and collaborate effectively',
        Icons.chat_bubble_outline_rounded, AppColors.accentCyan, 7),
  ];

  @override
  Widget build(BuildContext context) {
    Helpers.noApiYet('AiFeedbackScreen');
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
                    child: const Icon(Icons.track_changes_rounded, color: AppColors.white),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Performance Diagnosis', style: AppTextStyles.heading1),
                        Text(
                          "See where you're strong, find what to improve. "
                          "Let's build a better you.",
                          style: AppTextStyles.body.copyWith(color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Text('Your performance', style: AppTextStyles.heading2),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              for (final row in _rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                  child: _PerfCard(row: row),
                ),
              const _DetectedPatternCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfCard extends StatelessWidget {
  final _PerfRow row;
  const _PerfCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: row.color.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: row.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(row.icon, color: row.color, size: 18),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.label, style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
                    Text(row.caption, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Text('${row.scoreOf10 * 10}%',
                  style: AppTextStyles.heading2.copyWith(color: row.color)),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Expanded(child: _SegmentedBar(filled: row.scoreOf10, color: row.color)),
              const SizedBox(width: AppDimensions.spacingSm),
              Text('${row.scoreOf10} / 10', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  final int filled;
  final Color color;
  static const int total = 10;

  const _SegmentedBar({required this.filled, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isOn = i < filled;
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 3),
            decoration: BoxDecoration(
              color: isOn ? color : AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            ),
          ),
        );
      }),
    );
  }
}

class _DetectedPatternCard extends StatelessWidget {
  const _DetectedPatternCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.btnAccentPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.psychology_alt_rounded,
                    color: AppColors.btnAccentPurple, size: 18),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text('Detected Pattern',
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(color: AppColors.accentCyan.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.accentCyan),
                    const SizedBox(width: 4),
                    Text('Personalized insight',
                        style: AppTextStyles.caption.copyWith(color: AppColors.accentCyan)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'You understand race conditions, but debugging synchronization '
            'issues is still difficult.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.btnGamificationPink, size: 16),
                    const SizedBox(width: 6),
                    Text('Recurring issue:',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.btnGamificationPink, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text('Incorrect thread coordination', style: AppTextStyles.body),
                  ],
                ),
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
