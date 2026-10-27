import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

/// Animated circular score (0..100): the ring sweeps and the number counts up. Colour follows the score band
/// (Orchid low, Amber mid, Mint high) instead of a harsh red/green.
class ScoreRing extends StatelessWidget {
  final int score;
  final double size;
  const ScoreRing({super.key, required this.score, this.size = 84});

  static Color colorFor(int s) => s >= 70 ? AppColors.success : (s >= 40 ? AppColors.warning : AppColors.orchid);

  @override
  Widget build(BuildContext context) {
    final c = colorFor(score);
    return TweenAnimationBuilder<double>(
      key: ValueKey(score),
      tween: Tween(begin: 0, end: score.clamp(0, 100) / 100),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(value: 1, strokeWidth: size * 0.1, color: AppColors.surfaceRaised),
            ),
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(value: t, strokeWidth: size * 0.1, strokeCap: StrokeCap.round, color: c),
            ),
            Text('${(t * 100).round()}', style: AppTextStyles.display.copyWith(fontSize: size * 0.34, color: c)),
          ],
        ),
      ),
    );
  }
}
