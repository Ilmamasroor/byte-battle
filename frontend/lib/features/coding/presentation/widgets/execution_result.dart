import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/widgets/app_button.dart';

/// Submission result panel shown under the editor in [CodingScreen]: a status banner, the per-test-case rows
/// (hidden cases are masked by the backend, so only their verdict is shown), the compiler / runtime error, the
/// AI feedback once it is available, and the follow-up actions.
class ExecutionResult extends StatefulWidget {
  final String title;
  final String difficulty;
  final SubmissionResult result;

  /// null = still being generated, '' = gave up waiting (nothing to show).
  final String? aiFeedback;
  final bool aiFeedbackPending;
  final VoidCallback onContinue;
  final VoidCallback onPracticeDebugging;
  final VoidCallback onTryAgain;

  const ExecutionResult({
    super.key,
    required this.title,
    required this.difficulty,
    required this.result,
    required this.aiFeedback,
    required this.aiFeedbackPending,
    required this.onContinue,
    required this.onPracticeDebugging,
    required this.onTryAgain,
  });

  @override
  State<ExecutionResult> createState() => _ExecutionResultState();
}

class _ExecutionResultState extends State<ExecutionResult> {
  bool _showTechnical = true;

  static String _headline(SubmissionResult r) {
    switch (r.status) {
      case 'PASSED':
        return 'All tests passed';
      case 'COMPILATION_ERROR':
        return 'Compilation failed';
      case 'RUNTIME_ERROR':
        return 'Runtime error';
      case 'TIMEOUT':
        return 'Time limit exceeded';
      default:
        return '${r.passed}/${r.total} tests passed';
    }
  }

  static String _subline(SubmissionResult r) {
    switch (r.status) {
      case 'PASSED':
        return 'Your code compiled and passed every test case.';
      case 'COMPILATION_ERROR':
        return 'Your code did not compile, so no test could run.';
      case 'RUNTIME_ERROR':
        return 'Your code crashed while running the tests.';
      case 'TIMEOUT':
        return 'Your code took too long. Check for infinite loops or missing thread joins.';
      default:
        return 'Your code compiled, but ${r.total - r.passed} of ${r.total} tests failed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final allPassed = r.allPassed;
    final bannerColor = allPassed ? AppColors.success : AppColors.error;
    final cases = r.cases;
    final detail = r.errorMessage.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(Icons.code_rounded, color: AppColors.onAccent),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTextStyles.heading2),
                  Text('Practice • ${widget.difficulty}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          decoration: BoxDecoration(
            color: bannerColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: bannerColor.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Icon(allPassed ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded, color: bannerColor),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_headline(r), style: AppTextStyles.bodyBold.copyWith(color: bannerColor)),
                    Text(_subline(r), style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Column(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.textHint),
                  Text('${r.executionTimeMs} ms', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
        if (cases.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingLg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.science_outlined, size: 18, color: AppColors.accentCyan),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Expanded(child: Text('Test Cases', style: AppTextStyles.bodyBold)),
                    Text('${r.passed} / ${r.total} passed', style: AppTextStyles.caption.copyWith(color: bannerColor)),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                for (final c in cases)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                    child: _TestCaseRow(outcome: c),
                  ),
              ],
            ),
          ),
        ],
        if (!allPassed && detail.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingLg),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: const Border(left: BorderSide(color: AppColors.error, width: 3)),
            ),
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _showTechnical = !_showTechnical),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal_rounded, color: AppColors.warning, size: 18),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Expanded(
                        child: Text(
                          r.status == 'COMPILATION_ERROR' ? 'Compiler output' : 'Error details',
                          style: AppTextStyles.bodyBold,
                        ),
                      ),
                      Icon(
                        _showTechnical ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                ),
                if (_showTechnical) ...[
                  const SizedBox(height: AppDimensions.spacingSm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.spacingSm + 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: SelectableText(
                      detail,
                      style: TextStyle(fontFamily: AppTextStyles.monoFamily, fontSize: 12, color: AppColors.error, height: 1.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppDimensions.spacingMd),
        _AiFeedbackCard(feedback: widget.aiFeedback, pending: widget.aiFeedbackPending),
        const SizedBox(height: AppDimensions.spacingLg),
        if (allPassed)
          AppButton(label: 'Continue to Debugging', icon: Icons.arrow_forward_rounded, onPressed: widget.onContinue)
        else ...[
          AppButton(label: 'Try Again', icon: Icons.refresh_rounded, onPressed: widget.onTryAgain),
          const SizedBox(height: AppDimensions.spacingMd),
          AppButton(
            label: 'Practice Debugging',
            icon: Icons.bug_report_rounded,
            outlined: true,
            onPressed: widget.onPracticeDebugging,
          ),
        ],
      ],
    );
  }
}

class _AiFeedbackCard extends StatelessWidget {
  final String? feedback;
  final bool pending;
  const _AiFeedbackCard({required this.feedback, required this.pending});

  @override
  Widget build(BuildContext context) {
    final text = (feedback ?? '').trim();
    if (text.isEmpty && !pending) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.btnAccentPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.btnAccentPurple.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_alt_rounded, color: AppColors.btnAccentPurple, size: 18),
              const SizedBox(width: AppDimensions.spacingSm),
              Text('AI Feedback', style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          if (text.isNotEmpty)
            Text(text, style: AppTextStyles.body)
          else
            Row(
              children: [
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: AppDimensions.spacingSm),
                Expanded(child: Text('Your mentor is reviewing this attempt...', style: AppTextStyles.caption)),
              ],
            ),
        ],
      ),
    );
  }
}

class _TestCaseRow extends StatelessWidget {
  final CaseOutcome outcome;
  const _TestCaseRow({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final passed = outcome.passed;
    final color = passed ? AppColors.success : AppColors.error;
    final label = outcome.hidden ? 'Hidden test ${outcome.number}' : 'Test ${outcome.number}';
    final String detail;
    if (outcome.hidden) {
      detail = passed ? 'Hidden case: passed' : 'Hidden case: failed (inputs are not revealed)';
    } else if (passed) {
      detail = 'Input: ${outcome.input}  |  Output: ${outcome.actual}';
    } else {
      detail = 'Input: ${outcome.input}  |  Expected: ${outcome.expected}  |  Got: ${outcome.actual.isEmpty ? outcome.status : outcome.actual}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd, vertical: AppDimensions.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        children: [
          Icon(passed ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 18),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
                Text(detail, style: AppTextStyles.caption.copyWith(fontFamily: AppTextStyles.monoFamily)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Text(
                  passed ? 'Passed' : 'Failed',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 2),
              Text('${outcome.timeMs} ms', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
