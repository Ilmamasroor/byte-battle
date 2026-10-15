import 'package:flutter/material.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/onboarding_model.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingModel data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 20),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
