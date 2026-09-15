import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Small pill chip showing the remaining time for the current round,
/// e.g. "01:42". Turns orange under 30s remaining.
class BattleTimer extends StatelessWidget {
  final int secondsRemaining;

  const BattleTimer({super.key, required this.secondsRemaining});

  String get _label {
    final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final urgent = secondsRemaining < 30;
    final color = urgent ? AppColors.warning : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Text(_label, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
