import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// Full-width pill button with a leading icon AND a trailing icon —
/// used where the reference screenshots show e.g. a sparkle + arrow
/// together ("Continue", "Answer", "Start Recommended Practice").
/// [outlined] reuses the same accent-cyan outline look as
/// [AppButton]'s outlined variant, just with two icons instead of one.
class DualIconButton extends StatelessWidget {
  final String label;
  final IconData leadingIcon;
  final IconData trailingIcon;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool isLoading;

  const DualIconButton({
    super.key,
    required this.label,
    required this.leadingIcon,
    required this.trailingIcon,
    this.onPressed,
    this.outlined = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final textColor = outlined ? AppColors.accentCyan : AppColors.white;

    final content = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(textColor),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(leadingIcon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.button.copyWith(fontSize: 16, color: textColor),
                ),
              ),
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 18, color: textColor),
            ],
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: AppDimensions.buttonHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: outlined ? null : (isDisabled ? null : AppColors.btnPrimaryGradient),
        color: outlined
            ? AppColors.accentCyan.withOpacity(0.06)
            : (isDisabled ? AppColors.btnNeutralGrey.withOpacity(0.35) : null),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(
          color: outlined ? AppColors.accentCyan : AppColors.btnDarkBorder,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1,
        child: InkWell(
          onTap: (isDisabled || isLoading) ? null : onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: content,
          ),
        ),
      ),
    );
  }
}
