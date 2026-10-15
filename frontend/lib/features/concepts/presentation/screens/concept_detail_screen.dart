import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glow_card.dart';
import '../widgets/concept_header.dart';
import '../widgets/learning_stage_tile.dart';

class _LearnItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LearnItem(this.icon, this.title, this.subtitle);
}

/// Concept overview screen — the first stop in a concept's learning
/// flow ("Concept" step of the Concept/Understand/Visualize/Relate/
/// Remember/Battle journey). Matches the "Loop Boundaries" reference:
/// why the concept matters, the learning objective, a "What You'll
/// Learn" grid, and a "Start Learning" CTA that hands off to the
/// Understand stage.
class ConceptDetailScreen extends StatelessWidget {
  const ConceptDetailScreen({super.key});

  // TODO: replace with data from ConceptRepository / concept_model.dart
  static const _title = 'Loop Boundaries';
  static const _difficulty = 'Medium';
  static const _tags = ['Loops', 'Control Flow', 'Logic'];
  static const _whyItMatters =
      'Loops help you write cleaner, shorter and more powerful code. '
      'They are essential for repetitive tasks, data processing and '
      'problem solving in real world applications.';
  static const _objective =
      'Understand how loops work, when to use different types, and how '
      'to control their boundaries effectively in your code.';
  static const _learnItems = [
    _LearnItem(Icons.autorenew_rounded, 'For Loop', 'Fixed number of iterations'),
    _LearnItem(Icons.code_rounded, 'While Loop', 'Condition based repetition'),
    _LearnItem(Icons.replay_circle_filled_rounded, 'Do-While Loop', 'Execute at least once'),
    _LearnItem(Icons.settings_outlined, 'Loop Control', 'Break, Continue, Exit'),
  ];
  static const _totalSteps = 5;
  static const _stepIndex = 0;

  @override
  Widget build(BuildContext context) {
    Helpers.noApiYet('ConceptDetailScreen');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('BYTE BATTLE', style: AppTextStyles.heading2),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppDimensions.spacingMd),
            child: Center(
              child: Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ConceptHeader(
                title: _title,
                difficulty: _difficulty,
                tags: _tags,
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              GlowCard(
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: AppDimensions.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Why It Matters', style: AppTextStyles.bodyBold),
                              const SizedBox(height: 4),
                              Text(_whyItMatters, style: AppTextStyles.body),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
                      child: Divider(color: AppColors.divider, height: 1),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.track_changes_rounded,
                            color: AppColors.accentCyan, size: 20),
                        const SizedBox(width: AppDimensions.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Learning Objective', style: AppTextStyles.bodyBold),
                              const SizedBox(height: 4),
                              Text(_objective, style: AppTextStyles.body),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              AppButton(
                label: 'Start Learning',
                icon: Icons.arrow_forward_rounded,
                onPressed: () =>
                    Navigator.of(context).pushNamed(RouteNames.understand),
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              Text("What You'll Learn", style: AppTextStyles.heading2),
              const SizedBox(height: AppDimensions.spacingMd),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppDimensions.spacingMd,
                crossAxisSpacing: AppDimensions.spacingMd,
                childAspectRatio: 1.5,
                children: [
                  for (final item in _learnItems)
                    LearningStageTile(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _totalSteps; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _stepIndex ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _stepIndex ? AppColors.accentCyan : AppColors.border,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: Text('${_stepIndex + 1} / $_totalSteps', style: AppTextStyles.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
