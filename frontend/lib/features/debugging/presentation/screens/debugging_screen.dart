import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/models/diagnosis_model.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glow_card.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../concepts/presentation/widgets/concept_header.dart';
import '../../../concepts/presentation/widgets/concept_progress.dart';
import '../state/debugging_hint_controller.dart';
import '../widgets/buggy_code_view.dart';
import '../widgets/debug_result_card.dart';

/// Debug challenge screen — "your solution failed 1 test case", the
/// buggy code, the failing test's expected/received values, and a
/// Submit Fix / Need a Hint pair. Submitting a fix flips the same
/// screen into the "DEBUG RESULT — all test cases passed" state, then
/// "Continue" hands off to related follow-ups (AI feedback, Byte DNA,
/// more practice) instead of a dead end.
class DebuggingScreen extends StatefulWidget {
  const DebuggingScreen({super.key});

  @override
  State<DebuggingScreen> createState() => _DebuggingScreenState();
}

class _DebuggingScreenState extends State<DebuggingScreen> {
  @override
  void initState() {
    super.initState();
    Helpers.noApiYet('DebuggingScreen', note: 'challenge is hardcoded');
  }

  static const int _navIndex = 1;

  // TODO: replace with data from DebuggingController / debugging_challenge_model.dart.
  // The concept/diagnosis below feed the real `POST /api/ai/debugging-hint`
  // call in [_needAHint] — they're still hardcoded here because the
  // challenge itself is, but the AI call they drive is live.
  static const _concept = ConceptModel(
    id: '00000000-0000-0000-0000-000000001001',
    name: 'Java Fundamentals',
    difficulty: 'BEGINNER',
  );
  static const _diagnosis = DiagnosisModel(
    errorType: 'LOGIC_ERROR',
    explanation: "The loop's stopping condition runs one iteration past "
        'the end of the array.',
    suggestion: 'Compare i against nums.length using < instead of <=.',
  );

  static const _code = '''public class Solution {
    public static int loopBoundaries(int[] nums) {
        int count = 0;
        for (int i = 0; i <= nums.length; i++) {
            if (nums[i] > 0) {
                count++;
            }
        }
        return count;
    }
}''';
  static const _bugLine = 4;
  static const _expected = '7';
  static const _received = '9';

  final _noteController = TextEditingController();
  bool _fixed = false;
  bool _isSubmitting = false;
  bool _isHintLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitFix() async {
    setState(() => _isSubmitting = true);
    // TODO: send the fix via DebuggingController -> debugging repository.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _fixed = true;
    });
  }

  Future<void> _needAHint() async {
    final controller = DebuggingHintController.instance;
    setState(() => _isHintLoading = true);

    await controller.loadNextHint(concept: _concept, diagnosis: _diagnosis);

    if (!mounted) return;
    setState(() => _isHintLoading = false);

    final hint = controller.hint?.hint;
    final error = controller.errorMessage;
    if (error != null) {
      AppSnackBar.show(context, error);
    } else if (hint != null && hint.isNotEmpty) {
      AppSnackBar.show(context, hint);
    } else {
      AppSnackBar.show(
        context,
        "Hint: check the loop's stopping condition against the array length.",
      );
    }
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(RouteNames.dashboard);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(RouteNames.bossBattleIntro);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(RouteNames.coding);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(RouteNames.profile);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: AppBottomNav(currentIndex: _navIndex, onTap: _onNavTap),
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
                title: 'Loop Boundaries',
                difficulty: 'Medium',
                tags: ['Loops', 'Control Flow', 'Logic'],
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              ConceptProgress(
                current: ConceptStage.coding,
                routes: const {
                  ConceptStage.concept: RouteNames.conceptDetail,
                  ConceptStage.understand: RouteNames.understand,
                  ConceptStage.visualize: RouteNames.explore,
                  ConceptStage.battle: RouteNames.battle,
                  ConceptStage.coding: RouteNames.debugging,
                },
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              _fixed ? _buildResult(context) : _buildDebug(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebug(BuildContext context) {
    return GlowCard(
      borderColor: AppColors.error,
      glowColor: AppColors.error,
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.error),
                ),
                child: const Icon(Icons.bug_report_rounded, color: AppColors.error, size: 20),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DEBUG',
                        style: AppTextStyles.heading2.copyWith(color: AppColors.error)),
                    Text('Your solution failed 1 test case.', style: AppTextStyles.body),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          const BuggyCodeView(code: _code, highlightLine: _bugLine),
          const SizedBox(height: AppDimensions.spacingLg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.error.withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Text('Error / Failed Test',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.error)),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Text.rich(
                  TextSpan(
                    style: AppTextStyles.body,
                    children: [
                      const TextSpan(text: 'Expected: '),
                      TextSpan(
                        text: '$_expected\n',
                        style: const TextStyle(
                            color: AppColors.success, fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: 'Received: '),
                      TextSpan(
                        text: _received,
                        style: const TextStyle(
                            color: AppColors.error, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          TextField(
            controller: _noteController,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              labelText: 'Your note (optional)',
              hintText: 'What do you think is wrong?',
              prefixIcon: Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.textHint, size: 20),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppButton(
                  label: 'Submit Fix',
                  icon: Icons.play_arrow_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _submitFix,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                flex: 3,
                child: AppButton(
                  label: 'Need a Hint?',
                  icon: Icons.auto_awesome_rounded,
                  outlined: true,
                  isLoading: _isHintLoading,
                  onPressed: _needAHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DEBUG RESULT',
                        style: AppTextStyles.heading2.copyWith(color: AppColors.accentCyan)),
                    Text('Your fix worked! All test cases passed.', style: AppTextStyles.body),
                  ],
                ),
              ),
            ],
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
                Text('Test Results', style: AppTextStyles.bodyBold),
                const SizedBox(height: AppDimensions.spacingSm),
                const DebugResultCard(label: 'Test 1'),
                const DebugResultCard(label: 'Test 2'),
                const DebugResultCard(label: 'Test 3', showDivider: false),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Container(
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
                    const Icon(Icons.psychology_alt_rounded,
                        color: AppColors.btnAccentPurple, size: 20),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Expanded(child: Text("What's Next?", style: AppTextStyles.bodyBold)),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Great work! You solved the challenge. Explore your Byte DNA '
                  'insights and get personalized practice recommendations.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: _NextActionTile(
                        icon: Icons.science_outlined,
                        label: 'Diagnosis',
                        caption: 'See what went well, and where to improve.',
                        onTap: () => Navigator.of(context).pushNamed(RouteNames.aiFeedback),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Expanded(
                      child: _NextActionTile(
                        icon: Icons.fingerprint_rounded,
                        label: 'Byte DNA',
                        caption: 'View your strengths, patterns, and progress.',
                        onTap: () =>
                            Navigator.of(context).pushNamed(RouteNames.byteDnaSummary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                _NextActionTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Next Best Action',
                  caption: 'Get personalized practice recommendations.',
                  color: AppColors.btnAccentPurple,
                  onTap: () => Navigator.of(context).pushNamed(RouteNames.nextMove),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          AppButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(context).pushReplacementNamed(RouteNames.dashboard),
          ),
        ],
      ),
    );
  }
}

class _NextActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;
  final Color color;
  final VoidCallback onTap;

  const _NextActionTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.color = AppColors.accentCyan,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingSm + 4),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.bodyBold.copyWith(color: color, fontSize: 13)),
                ),
                Icon(Icons.chevron_right_rounded, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 4),
            Text(caption, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
