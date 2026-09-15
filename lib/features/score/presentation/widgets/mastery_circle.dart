import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Small circular mastery-score badge, e.g. "82" ringed in purple.
class MasteryCircle extends StatelessWidget {
  final int score;
  final double size;

  const MasteryCircle({super.key, required this.score, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      alignment: Alignment.center,
      child: Text('$score', style: AppTextStyles.heading2),
    );
  }
}
