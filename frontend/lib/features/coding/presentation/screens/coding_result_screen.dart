import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/load_error_view.dart';

/// Stand-alone submission summary: a score ring and the per-test verdicts of the [SubmissionResult] passed in
/// the route arguments (`{'result': SubmissionResult, 'conceptId': String}`). The coding screen shows its result
/// inline, so without a result there is nothing to display.
class CodingResultScreen extends StatelessWidget {
  const CodingResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final result = args is Map && args['result'] is SubmissionResult ? args['result'] as SubmissionResult : null;
    final conceptId = args is Map && args['conceptId'] is String ? args['conceptId'] as String : null;
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
        child: result == null
            ? const LoadErrorView(message: 'There is no submission to show yet.', icon: Icons.inbox_outlined)
            : Padding(
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
                          border: Border.all(color: result.allPassed ? AppColors.success : AppColors.primary, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${result.passed}/${result.total}', style: AppTextStyles.heading1.copyWith(fontSize: 28)),
                            const SizedBox(height: 2),
                            Text('TESTS PASSED', style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXl),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final c in result.cases)
                            ListTile(
                              dense: true,
                              leading: Icon(c.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: c.passed ? AppColors.success : AppColors.error),
                              title: Text(c.hidden ? 'Hidden test ${c.number}' : 'Test ${c.number}',
                                  style: AppTextStyles.bodyBold),
                              trailing: Text(c.passed ? 'Passed' : 'Failed', style: AppTextStyles.caption),
                            ),
                        ],
                      ),
                    ),
                    if (result.allPassed)
                      AppButton(
                        label: 'CONTINUE',
                        onPressed: () => Navigator.of(context).pushReplacementNamed(RouteNames.debugging,
                            arguments: conceptId == null ? null : {'conceptId': conceptId}),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
