import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/test_case_tile.dart';

/// Coding challenge submission result. Matches the "Submission Result"
/// screenshot: a circular X/Y score ring, a list of test/edge cases
/// each marked pass or fail, then a CONTINUE cta.
class CodingResultScreen extends StatelessWidget {
  final int passedCount;
  final int totalCount;
  final List<_CaseResult> cases;

  const CodingResultScreen({
    super.key,
    this.passedCount = 8,
    this.totalCount = 10,
    this.cases = const [
      _CaseResult('Test Case 1', true),
      _CaseResult('Test Case 2', true),
      _CaseResult('Test Case 3', true),
      _CaseResult('Edge Case 1', false),
      _CaseResult('Edge Case 2', false),
    ],
  });

  @override
  Widget build(BuildContext context) {
    Helpers.noApiYet('CodingResultScreen');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Submission Result', style: AppTextStyles.bodyBold),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.spacingMd),
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$passedCount/$totalCount',
                          style: AppTextStyles.heading1.copyWith(fontSize: 28)),
                      const SizedBox(height: 2),
                      Text('TEST PASSED',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              ...cases.map((c) => TestCaseTile(label: c.label, passed: c.passed)),
              const Spacer(),
              AppButton(
                label: 'CONTINUE',
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(RouteNames.interviewIntro),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseResult {
  final String label;
  final bool passed;
  const _CaseResult(this.label, this.passed);
}
