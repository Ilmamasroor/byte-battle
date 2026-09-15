import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../concepts/presentation/widgets/concept_progress.dart';
import '../widgets/concept_visualizer.dart';

class _Step {
  final int left, right, mid;
  final String title;
  final String explanation;

  const _Step(this.left, this.right, this.mid, this.title, this.explanation);
}

class VisualizationScreen extends StatefulWidget {
  final String conceptId;

  const VisualizationScreen({super.key, required this.conceptId});

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen> {
  @override
  void initState() {
    super.initState();
    Helpers.noApiYet('VisualizationScreen');
  }

  static const _values = [4, 9, 15, 23, 34, 42, 51];
  static const _target = 42;

  static const _steps = [
    _Step(0, 6, 3, 'Middle Value: 23', 'Target is greater. We search the right half.'),
    _Step(4, 6, 5, 'Middle Value: 42', 'Compare mid to target: they match!'),
  ];

  int _stepIndex = 0;

  void _next() {
    if (_stepIndex < _steps.length - 1) {
      setState(() => _stepIndex++);
    } else {
      Navigator.of(context).pushReplacementNamed(
        RouteNames.relate,
        arguments: {'conceptId': widget.conceptId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final isLast = _stepIndex == _steps.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Explore: How it Works', style: AppTextStyles.heading2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConceptProgress(
              current: ConceptStage.visualize,
              conceptId: widget.conceptId,
              routes: const {
                ConceptStage.concept: RouteNames.conceptDetail,
                ConceptStage.understand: RouteNames.understand,
                ConceptStage.visualize: RouteNames.explore,
                ConceptStage.relate: RouteNames.relate,
              },
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              alignment: Alignment.center,
              child: const Text('Target = 42',
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            ConceptVisualizer(
              values: _values,
              left: step.left,
              right: step.right,
              mid: step.mid,
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 6),
                  Text(step.explanation,
                      style: AppTextStyles.body.copyWith(color: AppColors.success)),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _stepIndex ? AppColors.primary : AppColors.border,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            AppButton(label: isLast ? 'START CHALLENGE' : 'CONTINUE', onPressed: _next),
          ],
        ),
      ),
    );
  }
}
