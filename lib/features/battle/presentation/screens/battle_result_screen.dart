import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

/// Boss Battle result screen. Matches the "YOU WON!" screenshot: trophy
/// badge, headline, subtitle, a Final Score card and two smaller stat
/// tiles (Mistakes Made / Accuracy), then a CONTINUE cta.
///
/// When [passed] is false it falls back to a "So Close" retry state so
/// the same screen still covers a boss-defeat outcome.
class BattleResultScreen extends StatelessWidget {
  final bool passed;
  final int finalScore;
  final int mistakes;
  final int accuracy;

  const BattleResultScreen({
    super.key,
    this.passed = true,
    this.finalScore = 120,
    this.mistakes = 4,
    this.accuracy = 82,
  });

  @override
  Widget build(BuildContext context) {
    Helpers.noApiYet('BattleResultScreen');
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                alignment: Alignment.center,
                child: Text(
                  passed ? '🏆' : '💥',
                  style: const TextStyle(fontSize: 42),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              Text(
                passed ? 'YOU WON!' : 'BOSS DEFEATED YOU',
                style: AppTextStyles.heading1.copyWith(
                  color: passed ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                passed ? 'Binary Search Master' : 'Give it another shot',
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
                      '$finalScore',
                      style: AppTextStyles.heading1.copyWith(fontSize: 34),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(label: 'MISTAKES MADE', value: '$mistakes', color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: _StatTile(label: 'ACCURACY', value: '$accuracy%', color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              AppButton(
                label: 'CONTINUE',
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed(passed ? RouteNames.score : RouteNames.bossBattleIntro),
              ),
            ],
          ),
        ),
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
