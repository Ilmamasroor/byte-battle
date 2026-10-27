import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

/// Centered message with an optional retry button, used for the loading-failed and "nothing here yet"
/// states of the coding and debugging screens.
class LoadErrorView extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const LoadErrorView({
    super.key,
    required this.message,
    this.icon = Icons.cloud_off_rounded,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spacingLg),
              AppButton(label: 'Try Again', icon: Icons.refresh_rounded, outlined: true, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
