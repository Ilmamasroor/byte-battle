import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// Centered "something went wrong" state with a message and a Retry
/// button, used by any screen whose network/AI call failed. Sized to fill
/// the space it's given (wrap it in an `Expanded` or give the parent a
/// bounded height).
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.btnGamificationPink, size: 32),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.primaryLight),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spacingLg),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.accentCyan),
                label: const Text('Retry', style: TextStyle(color: AppColors.accentCyan)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
