import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class TestCaseResult {
  final String label;
  final String input;
  final String? output;
  final String? expected;
  final String? got;
  final bool passed;
  final int runtimeMs;

  const TestCaseResult({
    required this.label,
    required this.input,
    this.output,
    this.expected,
    this.got,
    required this.passed,
    required this.runtimeMs,
  });
}

/// "Run Code" result panel shown under the editor in [CodingScreen] —
/// compiled/pass-count banner, a runtime chip, the individual test
/// case rows, an expandable "Test Failure Detail" explainer, a pattern
/// nudge, and Get a Hint / Try Again actions. Matches the reference
/// "Loop Boundaries — Practice • Easy" result screenshot.
class ExecutionResult extends StatefulWidget {
  final String title;
  final String difficulty;
  final int runtimeMs;
  final List<TestCaseResult> cases;
  final String failureSummary;
  final String failureTechnicalDetail;
  final String? repeatedMistakeNote;
  final VoidCallback onGetHint;
  final VoidCallback onTryAgain;
  final Future<void> Function()? onGetAiFeedback;

  const ExecutionResult({
    super.key,
    required this.title,
    required this.difficulty,
    required this.runtimeMs,
    required this.cases,
    required this.failureSummary,
    required this.failureTechnicalDetail,
    required this.onGetHint,
    required this.onTryAgain,
    this.repeatedMistakeNote,
    this.onGetAiFeedback,
  });

  bool get allPassed => cases.every((c) => c.passed);
  int get passedCount => cases.where((c) => c.passed).length;

  @override
  State<ExecutionResult> createState() => _ExecutionResultState();
}

class _ExecutionResultState extends State<ExecutionResult> {
  bool _showTechnical = true;
  bool _isAiFeedbackLoading = false;

  Future<void> _handleGetAiFeedback() async {
    final callback = widget.onGetAiFeedback;
    if (callback == null || _isAiFeedbackLoading) return;
    setState(() => _isAiFeedbackLoading = true);
    try {
      await callback();
    } finally {
      if (mounted) setState(() => _isAiFeedbackLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passed = widget.passedCount;
    final total = widget.cases.length;
    final allPassed = widget.allPassed;
    final bannerColor = allPassed ? AppColors.success : AppColors.accentCyan;

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
              child: const Icon(Icons.code_rounded, color: AppColors.white),
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
              Icon(Icons.check_circle_outline_rounded, color: bannerColor),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Compiled  —  $passed/$total tests passed',
                        style: AppTextStyles.bodyBold.copyWith(color: bannerColor)),
                    Text(
                      allPassed
                          ? 'Your code compiled successfully and all tests passed.'
                          : 'Your code compiled successfully, but ${total - passed} test failed.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Column(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.textHint),
                  Text('${widget.runtimeMs} ms', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
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
                  Text('$passed / $total passed',
                      style: AppTextStyles.caption.copyWith(color: bannerColor)),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              for (final c in widget.cases)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                  child: _TestCaseRow(result: c),
                ),
            ],
          ),
        ),
        if (!allPassed) ...[
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
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: AppColors.warning, size: 18),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Text('Test Failure Detail', style: AppTextStyles.bodyBold),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.btnAccentPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      ),
                      child: Text('Beginner Friendly',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.btnAccentPurple)),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(widget.failureSummary, style: AppTextStyles.body),
                const SizedBox(height: AppDimensions.spacingMd),
                InkWell(
                  onTap: () => setState(() => _showTechnical = !_showTechnical),
                  child: Row(
                    children: [
                      Text('Technical Details (optional)', style: AppTextStyles.bodyBold),
                      const Spacer(),
                      Icon(
                        _showTechnical
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
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
                      color: const Color(0xFF0A0A14),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      widget.failureTechnicalDetail,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.error,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.repeatedMistakeNote != null) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.btnAccentPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.btnAccentPurple.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.track_changes_rounded,
                      color: AppColors.btnAccentPurple, size: 18),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: Text(widget.repeatedMistakeNote!, style: AppTextStyles.caption),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spacingLg),
          AppButton(
            label: 'Get a Hint',
            icon: Icons.auto_awesome_rounded,
            onPressed: widget.onGetHint,
          ),
          if (widget.onGetAiFeedback != null) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            AppButton(
              label: 'AI Feedback',
              icon: Icons.psychology_alt_rounded,
              outlined: true,
              isLoading: _isAiFeedbackLoading,
              onPressed: _handleGetAiFeedback,
            ),
          ],
          const SizedBox(height: AppDimensions.spacingMd),
          AppButton(
            label: 'Try Again',
            icon: Icons.refresh_rounded,
            outlined: true,
            onPressed: widget.onTryAgain,
          ),
        ],
      ],
    );
  }
}

class _TestCaseRow extends StatelessWidget {
  final TestCaseResult result;
  const _TestCaseRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.passed ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        children: [
          Icon(
            result.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.label, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
                Text(
                  result.passed
                      ? 'Input: ${result.input}  |  Output: ${result.output}'
                      : 'Input: ${result.input}  |  Expected: ${result.expected}  |  Got: ${result.got}',
                  style: AppTextStyles.caption.copyWith(fontFamily: 'monospace'),
                ),
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
                  result.passed ? 'Passed' : 'Failed',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 2),
              Text('${result.runtimeMs} ms', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
