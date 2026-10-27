import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glow_card.dart';

/// "Your next move": the one spotlighted card on the dashboard. Shows the concept, a four-step journey strip
/// (Learn, See, Battle, Code) that fills as the learner progresses, a focus tip, and the Continue CTA.
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

  static const _steps = [
    (Icons.auto_stories_rounded, 'Learn'),
    (Icons.visibility_rounded, 'See'),
    (Icons.bolt_rounded, 'Battle'),
    (Icons.terminal_rounded, 'Code'),
  ];

  @override
  Widget build(BuildContext context) {
    final done = (progress * _steps.length).floor().clamp(0, _steps.length);
    return GlowCard(
      emphasized: true,
      padding: const EdgeInsets.all(AppDimensions.spacingMd + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('YOUR NEXT MOVE', style: AppTextStyles.eyebrow.copyWith(color: AppColors.primary)),
              const Spacer(),
              Text('${(progress * 100).round()}% complete', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: AppTextStyles.display.copyWith(fontSize: 26)),
          const SizedBox(height: 8),
          Text(description, style: AppTextStyles.body, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                Expanded(child: _Step(icon: _steps[i].$1, label: _steps[i].$2, done: i < done, current: i == done)),
                if (i < _steps.length - 1)
                  Container(
                    width: 14,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: i < done ? AppColors.primary : AppColors.border,
                  ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.55),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.xp),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(focusAreaNote, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.45)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((t) => _Tag(label: t)).toList(),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          AppButton(label: 'Continue learning', icon: Icons.arrow_forward_rounded, onPressed: onContinue),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  final bool current;
  const _Step({required this.icon, required this.label, required this.done, required this.current});

  @override
  Widget build(BuildContext context) {
    final Color fg = done ? AppColors.onAccent : (current ? AppColors.primary : AppColors.textHint);
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: done ? AppColors.primary : AppColors.background.withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(color: done ? AppColors.primary : (current ? AppColors.primary : AppColors.border), width: current ? 1.8 : 1),
          ),
          child: Icon(done ? Icons.check_rounded : icon, size: 19, color: fg),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: current || done ? FontWeight.w800 : FontWeight.w500,
              color: current || done ? AppColors.textPrimary : AppColors.textHint,
            )),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11.5)),
    );
  }
}
