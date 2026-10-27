import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';
import '../../../../core/widgets/brand/confetti.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../state/battle_controller.dart';

/// Battle result screen. Matches the "YOU WON!" screenshot: trophy badge, headline, subtitle, a Final Score card
/// and two smaller stat tiles (Mistakes Made / Accuracy), then a CONTINUE cta. Every number comes from the
/// server's result for the session (`POST /api/battle-sessions/{id}/complete`).
///
/// When the battle was lost it shows a "BOSS DEFEATED YOU" / "SO CLOSE" retry state instead.
class BattleResultScreen extends StatelessWidget {
  final BattleOutcome? outcome;

  const BattleResultScreen({super.key, required this.outcome});

  @override
  Widget build(BuildContext context) {
    final o = outcome;
    if (o == null) {
      // opened without a finished battle (e.g. a page reload): nothing real to show
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const Expanded(child: ErrorView(message: 'There is no battle result to show yet.')),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                child: AppButton(
                  label: 'BACK TO DASHBOARD',
                  onPressed: () => Navigator.of(context).pushReplacementNamed(RouteNames.dashboard),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final passed = o.result.won;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BitMascot(size: 120, mood: passed ? BitMood.cheer : BitMood.curious),
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                passed ? 'You won!' : (o.boss ? 'The boss got you this time' : 'So close!'),
                textAlign: TextAlign.center,
                style: AppTextStyles.display.copyWith(
                  fontSize: 34,
                  color: passed ? AppColors.xp : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                passed ? '${o.battleTitle}. Bit is very proud of you.' : 'Give ${o.conceptName} another shot, you are closer than you think.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingLg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Text('FINAL SCORE', style: AppTextStyles.caption),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      '${o.result.finalScore}',
                      style: AppTextStyles.heading1.copyWith(fontSize: 34),
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text('${o.result.correctAnswers} of ${o.result.totalQuestions} correct',
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(label: 'MISTAKES MADE', value: '${o.wrong}', color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: _StatTile(label: 'ACCURACY', value: '${o.accuracy}%', color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              AppButton(
                label: passed ? 'Continue' : 'Try again',
                onPressed: () => passed
                    ? Navigator.of(context).pushReplacementNamed(RouteNames.score, arguments: o)
                    : Navigator.of(context).pushReplacementNamed(
                        o.boss ? RouteNames.bossBattleIntro : RouteNames.battle,
                        arguments: {'conceptId': o.conceptId, 'boss': o.boss},
                      ),
              ),
              if (!passed) ...[
                const SizedBox(height: AppDimensions.spacingSm),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(RouteNames.score, arguments: o),
                  child: const Text('See my score'),
                ),
              ],
            ],
          ),
        ),
        Positioned.fill(child: AutoConfetti(enabled: passed)),
        ]),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(value, style: AppTextStyles.bodyBold.copyWith(color: color, fontSize: 18)),
        ],
      ),
    );
  }
}
