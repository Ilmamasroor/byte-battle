import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// Row of heart icons showing remaining lives during a Boss Battle.
class LifeIndicator extends StatelessWidget {
  final int lives;
  final int maxLives;
  final double size;

  const LifeIndicator({
    super.key,
    required this.lives,
    this.maxLives = 3,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLives, (i) {
        final filled = i < lives;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(
            filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: filled ? AppColors.error : AppColors.textHint,
            size: size,
          ),
        );
      }),
    );
  }
}
