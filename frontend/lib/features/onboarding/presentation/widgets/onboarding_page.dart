import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/onboarding_model.dart';
import 'onboarding_scenes.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingModel data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Column(
        children: [
          Expanded(child: Center(child: OnboardingSceneView(scene: data.scene))),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(data.step, style: AppTextStyles.eyebrow.copyWith(color: AppColors.primary)),
                const SizedBox(width: 8),
                Container(width: 18, height: 1.5, color: AppColors.borderLight),
                const SizedBox(width: 8),
                Text(data.verb, style: AppTextStyles.eyebrow.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(data.title, style: AppTextStyles.display.copyWith(fontSize: 30)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(data.subtitle, style: AppTextStyles.body.copyWith(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
