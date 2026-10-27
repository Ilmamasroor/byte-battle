import 'package:flutter/material.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../state/interview_controller.dart';

class InterviewIntroScreen extends StatefulWidget {
  const InterviewIntroScreen({super.key});

  @override
  State<InterviewIntroScreen> createState() => _InterviewIntroScreenState();
}

class _InterviewIntroScreenState extends State<InterviewIntroScreen> {
  final _controller = InterviewController.instance;
  bool _requested = false;
  late String _conceptId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    _conceptId = args is Map && args['conceptId'] is String ? args['conceptId'] as String : AppConstants.defaultConceptId;
    _controller.reset();
    _controller.addListener(_onChange);
    _controller.loadConcept(_conceptId);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    final ok = await _controller.start(_conceptId, _controller.concept?.difficulty ?? 'MEDIUM');
    if (!mounted) return;
    if (!ok) {
      AppSnackBar.error(context, _controller.errorMessage ?? 'Could not start the interview.');
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
                child: const Icon(Icons.mic_none_rounded, color: AppColors.onAccent, size: 44),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            const Text('Mock Interview', style: AppTextStyles.heading1, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              _controller.concept == null
                  ? (_controller.errorMessage ?? 'Loading your concept…')
                  : 'Explain ${_controller.concept!.name} as if in a real interview. '
                      'Our AI asks up to 5 questions, grades every answer and saves the result to your progress.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const Spacer(),
            AppButton(
              label: _controller.concept == null && _controller.errorMessage != null ? 'RETRY' : 'START INTERVIEW',
              isLoading: _controller.isStarting,
              onPressed: _controller.isStarting
                  ? null
                  : _controller.concept == null
                      ? (_controller.errorMessage != null ? () => _controller.loadConcept(_conceptId) : null)
                      : _start,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
          ],
        ),
      ),
    );
  }
}
