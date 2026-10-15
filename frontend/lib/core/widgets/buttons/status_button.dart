import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import 'app_button_size.dart';

/// Status Buttons — "For results, progress and achievements."
enum StatusButtonType { correct, incorrect, inProgress, locked }

extension _StatusButtonTypeStyle on StatusButtonType {
  Color get color {
    switch (this) {
      case StatusButtonType.correct:
        return AppColors.btnSuccessGreen;
      case StatusButtonType.incorrect:
        return AppColors.btnErrorRed;
      case StatusButtonType.inProgress:
        return AppColors.btnPrimaryBlue;
      case StatusButtonType.locked:
        return AppColors.btnAccentPurple;
    }
  }

  IconData get icon {
    switch (this) {
      case StatusButtonType.correct:
        return Icons.check_rounded;
      case StatusButtonType.incorrect:
        return Icons.close_rounded;
      case StatusButtonType.inProgress:
        return Icons.hourglass_bottom_rounded;
      case StatusButtonType.locked:
        return Icons.lock_rounded;
    }
  }

  String get defaultLabel {
    switch (this) {
      case StatusButtonType.correct:
        return 'Correct';
      case StatusButtonType.incorrect:
        return 'Incorrect';
      case StatusButtonType.inProgress:
        return 'In Progress';
      case StatusButtonType.locked:
        return 'Locked';
    }
  }
}

class StatusButton extends StatelessWidget {
  final StatusButtonType type;
  final String? label;
  final VoidCallback? onPressed;
  final AppButtonSize size;

  const StatusButton({
    super.key,
    required this.type,
    this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final color = type.color;
    final content = Container(
      height: size.height,
      padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: size.iconSize, color: AppColors.white),
          SizedBox(width: size.iconGap),
          Text(
            label ?? type.defaultLabel,
            style: AppTextStyles.button.copyWith(
              fontSize: size.fontSize,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );

    if (onPressed == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        onTap: onPressed,
        child: content,
      ),
    );
  }
}
