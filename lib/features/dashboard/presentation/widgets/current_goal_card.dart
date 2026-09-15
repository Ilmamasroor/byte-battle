import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glow_card.dart';

/// "Current Mission" hero card on the dashboard — icon/label header, title,
/// description, progress bar, topic chips, a focus-area tip and a
/// Continue Mission CTA, matching the reference dashboard screenshot.
class CurrentGoalCard extends StatelessWidget {
  final String title;
  final String description;
  final double progress; // 0.0 - 1.0
  final List<String> tags;
  final String focusAreaNote;
  final VoidCallback onContinue;

  const CurrentGoalCard({
    super.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.tags,
    required this.focusAreaNote,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: AppColors.primary,
      borderColor: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.track_changes_rounded,
                              size: 13, color: AppColors.accentCyan),
                          const SizedBox(width: 5),
                          Text(
                            'CURRENT MISSION',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accentCyan,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Text(title, style: AppTextStyles.heading1.copyWith(fontSize: 22)),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                ),
                child: const Icon(Icons.code_rounded, color: AppColors.accentCyan, size: 24),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(description, style: AppTextStyles.body),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accentCyan),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${(progress * 100).round()}%', style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((t) => _MissionTag(label: t)).toList(),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.lightbulb_outline_rounded,
                    size: 15, color: AppColors.warning),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.caption.copyWith(height: 1.4),
                    children: [
                      TextSpan(
                        text: 'Focus area: ',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accentCyan,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: focusAreaNote),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          AppButton(
            label: 'Continue Mission',
            icon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _MissionTag extends StatelessWidget {
  final String label;

  const _MissionTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppTextStyles.caption),
    );
  }
}
