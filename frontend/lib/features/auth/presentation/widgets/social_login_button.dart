import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: AppDimensions.buttonHeight,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18, color: AppColors.textPrimary),
          label: Text(label, style: AppTextStyles.bodyBold),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.borderLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            ),
          ),
        ),
      ),
    );
  }
}
