import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../learner_profile/data/models/learner_profile_model.dart';
import '../../../onboarding/ai_onboarding/presentation/state/onboarding_ai_controller.dart';
import '../widgets/career_goal_card.dart';
import '../widgets/interest_selector.dart';
import '../widgets/preference_chip.dart';

const List<String> _learningStyles = ['VISUAL', 'TEXTUAL', 'HANDS_ON'];
const List<String> _explanationStyles = ['SIMPLE', 'DETAILED'];
const List<String> _interestOptions = [
  'DSA',
  'Backend Development',
  'Frontend Development',
  'Data Structures',
  'Algorithms',
  'Object Oriented Programming',
  'System Design',
  'Databases',
];

/// ByteDnaSetupScreen — the one-time post-signup form that seeds a new
/// user's ByteDNA via `POST /api/ai/onboarding`
/// (`OnboardingAiController.instance.submitOnboarding`).
class ByteDnaSetupScreen extends StatefulWidget {
  const ByteDnaSetupScreen({super.key});

  @override
  State<ByteDnaSetupScreen> createState() => _ByteDnaSetupScreenState();
}

class _ByteDnaSetupScreenState extends State<ByteDnaSetupScreen> {
  final _careerGoalController = TextEditingController();
  final _languageController = TextEditingController();

  ExperienceLevel? _technicalExperience;
  String? _learningStyle;
  String? _explanationStyle;
  final Set<String> _interests = {};

  @override
  void dispose() {
    _careerGoalController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_technicalExperience == null) return 'Select your technical experience.';
    if (_languageController.text.trim().isEmpty) return 'Enter your preferred language.';
    if (_careerGoalController.text.trim().isEmpty) return 'Enter or pick a career goal.';
    if (_learningStyle == null) return 'Select a learning style.';
    if (_explanationStyle == null) return 'Select an explanation style.';
    if (_interests.isEmpty) return 'Pick at least one interest.';
    return null;
  }

  /// `"software engineer"` -> `"SOFTWARE_ENGINEER"`.
  String _apiify(String raw) {
    return raw
        .trim()
        .toUpperCase()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .join('_');
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      AppSnackBar.error(context, validationError);
      return;
    }

    final controller = OnboardingAiController.instance;
    await controller.submitOnboarding(
      technicalExperience: _technicalExperience!,
      preferredLanguage: _languageController.text.trim().toUpperCase(),
      careerGoal: _apiify(_careerGoalController.text),
      learningStyle: _learningStyle!,
      explanationStyle: _explanationStyle!,
      interests: _interests.toList(),
      force: true,
    );

    if (!mounted) return;

    if (controller.errorMessage == null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.dashboard,
        (route) => false,
      );
    } else {
      AppSnackBar.error(context, controller.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OnboardingAiController.instance,
      builder: (context, _) {
        final isLoading = OnboardingAiController.instance.isLoading;

        // Mandatory, one-time post-signup step: `register_screen.dart`
        // pushes this screen with `pushNamedAndRemoveUntil`, so there's
        // no previous route left to pop to anyway — `PopScope` here just
        // makes that explicit and also blocks the Android hardware
        // back button / edge-swipe from dismissing the form early.
        return PopScope(
          canPop: false,
          child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: const Text('ByteDNA Setup', style: AppTextStyles.heading2),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: AppTextStyles.heading1,
                      children: [
                        TextSpan(text: 'Build your '),
                        TextSpan(text: 'Byte DNA', style: TextStyle(color: AppColors.accentCyan)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingSm),
                  Text(
                    'A few quick questions so we can personalize your lessons.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),

                  Text('Technical Experience', style: AppTextStyles.bodyBold),
                  const SizedBox(height: AppDimensions.spacingSm),
                  Wrap(
                    spacing: AppDimensions.spacingSm,
                    runSpacing: AppDimensions.spacingSm,
                    children: ExperienceLevel.values.map((level) {
                      return PreferenceChip(
                        label: level.label,
                        selected: _technicalExperience == level,
                        onTap: () => setState(() => _technicalExperience = level),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),

                  Text('Preferred Language', style: AppTextStyles.bodyBold),
                  const SizedBox(height: AppDimensions.spacingSm),
                  TextField(
                    controller: _languageController,
                    style: AppTextStyles.bodyBold,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Java, Python, JavaScript',
                      prefixIcon: Icon(Icons.code_rounded, color: AppColors.textHint, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),

                  Text('Career Goal', style: AppTextStyles.bodyBold),
                  const SizedBox(height: AppDimensions.spacingSm),
                  CareerGoalCard(
                    controller: _careerGoalController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),

                  Text('Learning Style', style: AppTextStyles.bodyBold),
                  const SizedBox(height: AppDimensions.spacingSm),
                  Wrap(
                    spacing: AppDimensions.spacingSm,
                    runSpacing: AppDimensions.spacingSm,
                    children: _learningStyles.map((style) {
                      return PreferenceChip(
                        label: style.replaceAll('_', ' '),
                        selected: _learningStyle == style,
                        onTap: () => setState(() => _learningStyle = style),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),

                  Text('Explanation Style', style: AppTextStyles.bodyBold),
                  const SizedBox(height: AppDimensions.spacingSm),
                  Wrap(
                    spacing: AppDimensions.spacingSm,
                    runSpacing: AppDimensions.spacingSm,
                    children: _explanationStyles.map((style) {
                      return PreferenceChip(
                        label: style,
                        selected: _explanationStyle == style,
                        onTap: () => setState(() => _explanationStyle = style),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),

                  Text('Interests', style: AppTextStyles.bodyBold),
                  const SizedBox(height: AppDimensions.spacingSm),
                  InterestSelector(
                    options: _interestOptions,
                    selected: _interests,
                    onToggle: (interest) => setState(() {
                      if (!_interests.remove(interest)) {
                        _interests.add(interest);
                      }
                    }),
                  ),
                  const SizedBox(height: AppDimensions.spacingXxl),

                  AppButton(
                    label: 'CONTINUE',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}
