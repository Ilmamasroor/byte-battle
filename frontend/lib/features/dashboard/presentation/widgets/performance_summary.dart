import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';

/// "Your Byte DNA" card — a set of labelled skill bars (Understanding,
/// Application, Debugging, Communication), matching the reference
/// dashboard screenshot.
class PerformanceSummary extends StatelessWidget {
  final Map<String, double> skills;
  final VoidCallback? onTap;

  const PerformanceSummary({super.key, required this.skills, this.onTap});

  static const _icons = {
    'Understanding': Icons.psychology_outlined,
    'Application': Icons.code_rounded,
    'Debugging': Icons.bug_report_outlined,
    'Communication': Icons.chat_bubble_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: GlowCard(
        glowColor: AppColors.btnAccentPurple,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bloodtype_outlined, size: 20, color: AppColors.btnAccentPurple),
                const SizedBox(width: 8),
                Text('YOUR BYTE DNA',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.accentCyan,
                      letterSpacing: 0.4,
                    )),
                if (onTap != null) ...[
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textHint, size: 18),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text('Your coding strengths across key skills', style: AppTextStyles.caption),
            const SizedBox(height: AppDimensions.spacingMd),
            ...skills.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                  child: _SkillRow(
                    label: e.key,
                    value: e.value,
                    icon: _icons[e.key] ?? Icons.stars_rounded,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _SkillRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AppColors.accentCyan),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: AppColors.background,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text('${(value * 100).round()}%', style: AppTextStyles.bodyBold),
      ],
    );
  }
}
