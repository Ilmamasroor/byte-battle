import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../learning/explanation/data/models/canonical_knowledge_model.dart';
import '../state/interview_controller.dart';

class InterviewIntroScreen extends StatefulWidget {
  const InterviewIntroScreen({super.key});

  @override
  State<InterviewIntroScreen> createState() => _InterviewIntroScreenState();
}

class _InterviewIntroScreenState extends State<InterviewIntroScreen> {
  // TODO: replace with the real concept + canonical knowledge (e.g. from
  // ExplanationController.instance.knowledge) once concept selection is
  // threaded through navigation to this screen — still hardcoded here
  // because that selection flow doesn't exist yet, but the
  // `POST /api/ai/interview/question` call it drives below is live.
  static const _concept = ConceptModel(
    id: '00000000-0000-0000-0000-000000001001',
    name: 'Java Fundamentals',
    slug: 'java-fundamentals',
    difficulty: 'BEGINNER',
  );
  static const _canonicalKnowledge = CanonicalKnowledgeModel(
    keyPoints: [
      'A variable is a named container that stores a value in memory.',
      'Every variable in Java has a declared type.',
    ],
    rules: [
      'Local variables must be initialized before use.',
    ],
    examples: [
      'int age = 21;',
    ],
  );

  bool _isStarting = false;

  Future<void> _start() async {
    setState(() => _isStarting = true);

    final controller = InterviewController.instance;
    await controller.startInterview(
      concept: _concept,
      canonicalKnowledge: _canonicalKnowledge,
    );

    if (!mounted) return;
    setState(() => _isStarting = false);

    final error = controller.errorMessage;
    if (error != null) {
      AppSnackBar.error(context, error);
      return;
    }
    Navigator.of(context).pushReplacementNamed(RouteNames.interview);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(Icons.mic_none_rounded, color: AppColors.white, size: 44),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            const Text('Mock Interview', style: AppTextStyles.heading1, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              'Explain ${_concept.name} out loud as if in a real interview. '
              'Our AI will review your answer and give feedback.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const Spacer(),
            AppButton(
              label: 'START INTERVIEW',
              isLoading: _isStarting,
              onPressed: _isStarting ? null : _start,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
          ],
        ),
      ),
    );
  }
}
