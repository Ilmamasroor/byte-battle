import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/diagnosis_model.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../state/coding_feedback_controller.dart';
import '../widgets/code_editor.dart';
import '../widgets/execution_result.dart';

class CodingScreen extends StatefulWidget {
  const CodingScreen({super.key});

  @override
  State<CodingScreen> createState() => _CodingScreenState();
}

class _CodingScreenState extends State<CodingScreen> {
  // TODO: replace with data from CodingController / coding_challenge_model.dart.
  // Feeds the real `POST /api/ai/coding-feedback` call in
  // [_getAiFeedback] — still hardcoded here because the challenge/test
  // run itself is, but the AI call it drives is live.
  static const _concept = ConceptModel(
    id: '00000000-0000-0000-0000-000000001001',
    name: 'Java Fundamentals',
    difficulty: 'BEGINNER',
  );

  final _codeController = TextEditingController(text: '''
function binarySearch(arr, target) {
  let left = 0;
  let right = arr.length - 1;

  while (left <= right) {
    const mid = Math.floor((left + right) / 2);

    if (arr[mid] === target) {
      return mid;
    } else if (arr[mid] < target) {
      left = mid + 1;
    } else {
      right = mid - 1;
    }
  }

  return -1;
}
''');

  bool _isRunning = false;
  ExecutionResult? _result;

  @override
  void initState() {
    super.initState();
    Helpers.noApiYet('CodingScreen', note: 'challenge + run/submit are hardcoded, no coding API wired yet');
  }

  Future<void> _run() async {
    setState(() {
      _isRunning = true;
      _result = null;
    });
    // TODO: send _codeController.text to coding_repository.dart for execution.
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      // TODO: replace with the real TestResultModel response.
      _result = ExecutionResult(
        title: 'Loop Boundaries',
        difficulty: 'Easy',
        runtimeMs: 48,
        cases: const [
          TestCaseResult(
            label: 'Test 1',
            input: '0, 5, 2',
            output: '5',
            passed: true,
            runtimeMs: 12,
          ),
          TestCaseResult(
            label: 'Test 2',
            input: '1, 3, 1',
            output: '3',
            passed: true,
            runtimeMs: 15,
          ),
          TestCaseResult(
            label: 'Test 3',
            input: '2, 10, 3',
            expected: '7',
            got: '9',
            passed: false,
            runtimeMs: 14,
          ),
        ],
        failureSummary: "Looks like an off-by-one error.  Your loop may be running "
            'one iteration too far.',
        failureTechnicalDetail: 'Error\n'
            '  at Solution.loopBoundaries(Main.java:14)\n'
            '  at Main.main(Main.java:8)',
        repeatedMistakeNote: 'You hit this same boundary error twice this week. '
            'A quick review of loop conditions might help!',
        onGetHint: () => Navigator.of(context).pushNamed(RouteNames.debugging),
        onTryAgain: () => setState(() => _result = null),
        onGetAiFeedback: _getAiFeedback,
      );
    });
  }

  /// `POST /api/ai/coding-feedback`. Builds the diagnosis from the
  /// failed test case shown above — in a real run this diagnosis would
  /// come from the backend's own analysis of the submission.
  Future<void> _getAiFeedback() async {
    final controller = CodingFeedbackController.instance;
    await controller.loadFeedback(
      concept: _concept,
      diagnosis: const DiagnosisModel(
        errorType: 'LOGIC_ERROR',
        explanation: "Looks like an off-by-one error. Your loop may be "
            'running one iteration too far.',
        suggestion: 'Check the loop boundary condition.',
      ),
    );

    if (!mounted) return;

    final error = controller.errorMessage;
    final feedback = controller.feedback?.feedback;
    if (error != null) {
      AppSnackBar.show(context, error);
    } else if (feedback != null && feedback.isNotEmpty) {
      AppSnackBar.show(context, feedback);
    }
  }

  Future<void> _submit() async {
    // TODO: submit via CodingController -> CodeSubmissionModel.
    Navigator.of(context).pushReplacementNamed(RouteNames.bossBattleIntro);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
        title: const Text('Implement Binary Search', style: AppTextStyles.heading2),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacingMd),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: const Text('Easy',
                    style: TextStyle(color: AppColors.success, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Write a function that returns the index of `target` in a sorted '
              'array, or -1 if it is not present.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            CodeEditor(controller: _codeController),
            const SizedBox(height: AppDimensions.spacingMd),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    label: _isRunning ? 'Running...' : 'Run Code',
                    icon: Icons.play_arrow_rounded,
                    isLoading: _isRunning,
                    onPressed: _run,
                    size: AppButtonSize.xl,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: NavigationButton(
                    label: 'Submit',
                    icon: Icons.check_rounded,
                    onPressed: _submit,
                    size: AppButtonSize.xl,
                  ),
                ),
              ],
            ),
            if (_result != null) ...[
              const SizedBox(height: AppDimensions.spacingLg),
              const Divider(color: AppColors.divider),
              const SizedBox(height: AppDimensions.spacingLg),
              _result!,
            ],
          ],
        ),
      ),
    );
  }
}

