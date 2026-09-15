import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';

class _SkillRow {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _SkillRow(this.label, this.value, this.icon, this.color);
}

/// "Byte DNA" — the full-screen breakdown behind the compact card on
/// the dashboard: the four skill bars (Understanding / Application /
/// Debugging / Communication), a "Strongest" / "Needs attention" /
/// "Recent improvement" / "Current focus" 2x2 grid, and a footer
/// banner. Matches the "Your Learning Fingerprint" reference screen.
class ByteDnaSummaryScreen extends StatelessWidget {
  const ByteDnaSummaryScreen({super.key});

  // TODO: replace with data from ByteDnaController / byte_dna_model.dart
  static const _skills = [
    _SkillRow('Understanding', 0.78, Icons.lightbulb_outline_rounded, AppColors.accentCyan),
    _SkillRow('Application', 0.64, Icons.code_rounded, AppColors.btnAccentPurple),
    _SkillRow('Debugging', 0.43, Icons.bug_report_outlined, AppColors.btnGamificationPink),
    _SkillRow('Communication', 0.69, Icons.chat_bubble_outline_rounded, AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    Helpers.noApiYet('ByteDnaSummaryScreen');
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
              child: _XpChip(xp: 840),
            ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.fingerprint_rounded,
                        color: AppColors.btnAccentPurple, size: 22),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.heading1,
                        children: [
                          const TextSpan(text: 'BYTE '),
                          TextSpan(
                              text: 'DNA', style: TextStyle(color: AppColors.accentCyan)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Text(
                    'Different skills.\nOne you.',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Padding(
                padding: EdgeInsets.only(left: 60),
                child: Text('Your Learning Fingerprint', style: AppTextStyles.body),
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              GlowCard(
                glowColor: AppColors.btnAccentPurple,
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                child: Column(
                  children: [
                    const _FingerprintArt(),
                    const SizedBox(height: AppDimensions.spacingLg),
                    for (final skill in _skills)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
                        child: _SkillBar(skill: skill),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InsightCard(
                      icon: Icons.star_border_rounded,
                      color: AppColors.accentCyan,
                      title: 'Strongest',
                      lineIcon: Icons.check_rounded,
                      line: 'Concept recognition',
                      caption: 'You grasp new concepts really well!',
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: _InsightCard(
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.btnGamificationPink,
                      title: 'Needs attention',
                      lineIcon: Icons.warning_amber_rounded,
                      line: 'Debugging',
                      caption: 'Take more time to analyze and fix errors.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InsightCard(
                      icon: Icons.trending_up_rounded,
                      color: AppColors.success,
                      title: 'Recent improvement',
                      lineIcon: Icons.arrow_upward_rounded,
                      line: 'Application +8%',
                      caption: "You're applying what you learn more effectively!",
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: _InsightCard(
                      icon: Icons.track_changes_rounded,
                      color: AppColors.btnAccentPurple,
                      title: 'Current focus',
                      lineIcon: Icons.track_changes_rounded,
                      line: 'Debugging',
                      caption: 'Small steps. Big progress.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.white),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: AppTextStyles.bodyBold.copyWith(color: AppColors.white),
                              children: const [
                                TextSpan(text: 'Your '),
                                TextSpan(text: 'Byte DNA'),
                                TextSpan(text: ' is evolving...'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Keep learning. Keep building. Keep becoming.',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.white.withOpacity(0.85)),
                          ),
                        ],
                      ),
                    ),
                  ],
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

class _FingerprintArt extends StatelessWidget {
  const _FingerprintArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.4)),
        gradient: RadialGradient(
          colors: [AppColors.primary.withOpacity(0.25), Colors.transparent],
        ),
      ),
      child: const Icon(Icons.fingerprint_rounded, size: 56, color: AppColors.accentCyan),
    );
  }
}

class _SkillBar extends StatelessWidget {
  final _SkillRow skill;
  const _SkillBar({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: skill.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(skill.icon, size: 16, color: skill.color),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(skill.label, style: AppTextStyles.bodyBold),
                  Text('${(skill.value * 100).round()}%',
                      style: AppTextStyles.bodyBold.copyWith(color: skill.color)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                child: LinearProgressIndicator(
                  value: skill.value,
                  minHeight: 8,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation(skill.color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final IconData lineIcon;
  final String line;
  final String caption;

  const _InsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.lineIcon,
    required this.line,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(title, style: AppTextStyles.bodyBold),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            width: 20,
            height: 2,
            color: color,
          ),
          Row(
            children: [
              Icon(lineIcon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  line,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(caption, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
