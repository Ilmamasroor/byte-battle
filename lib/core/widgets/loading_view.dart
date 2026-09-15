import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// Centered spinner + optional message, used while a screen is waiting on
/// a network/AI call. Sized to fill the space it's given (wrap it in an
/// `Expanded` or give the parent a bounded height).
class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.accentCyan),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.primaryLight),
            ),
          ],
        ],
      ),
    );
  }
}
