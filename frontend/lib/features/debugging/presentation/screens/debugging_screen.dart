import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/network/backend_api.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glow_card.dart';
import '../../../coding/presentation/widgets/code_editor.dart';
import '../../../coding/presentation/widgets/load_error_view.dart';
import '../../../concepts/presentation/widgets/concept_header.dart';
import '../../../concepts/presentation/widgets/concept_progress.dart';
import '../widgets/debug_result_card.dart';

/// Debug stage: the learner gets a real buggy program for the concept, edits it, and submits the fix. The backend
/// runs it in the Judge0 sandbox against hidden + sample tests and answers with the verdict, the error category,
/// the failure streak and what to do next. Progressive hints come from the exercise's hint ladder.
class DebuggingScreen extends StatefulWidget {
  const DebuggingScreen({super.key});

  @override
  State<DebuggingScreen> createState() => _DebuggingScreenState();
}

class _DebuggingScreenState extends State<DebuggingScreen> {
  static const int _navIndex = 1;

  final _codeController = TextEditingController();
  final _watch = Stopwatch();

  String _conceptId = AppConstants.defaultConceptId;
  bool _started = false;

  ConceptInfo? _concept;
  DebugExerciseModel? _exercise;
  bool _loading = true;
  String? _loadError;
  bool _noExercise = false;

  bool _isSubmitting = false;
  bool _isHintLoading = false;
  String? _actionError;
  DebugAttemptResult? _attempt;
  final List<DebugHint> _hints = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['conceptId'] is String) _conceptId = args['conceptId'] as String;
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _noExercise = false;
    });
    try {
      final api = BackendApi.instance;
      final results = await Future.wait<Object?>([
        api.debugExercises(_conceptId),
        api.concept(_conceptId).then<ConceptInfo?>((c) => c).catchError((_) => null),
      ]);
      final list = results[0] as List<DebugExerciseModel>;
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() {
          _concept = results[1] as ConceptInfo?;
          _noExercise = true;
          _loading = false;
        });
        return;
      }
      final detail = await api.debugExercise(list.first.id);
      if (!mounted) return;
      _codeController.text = detail.buggyCode;
      _watch
        ..reset()
        ..start();
      setState(() {
        _concept = results[1] as ConceptInfo?;
        _exercise = detail;
        _attempt = null;
        _hints.clear();
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load the debugging exercise. Please try again.';
        _loading = false;
      });
    }
  }

  static const _sandboxDown = 'The code sandbox is temporarily unavailable, so your fix was not judged. '
      'This does not count as an attempt. Please try again in a moment.';

  Future<void> _submitFix() async {
    final ex = _exercise;
    if (ex == null || _isSubmitting) return;
    if (_codeController.text.trim().isEmpty) {
      setState(() => _actionError = 'The code is empty. Fix the bug in the program above, then submit.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _actionError = null;
    });
    try {
      final r = await BackendApi.instance.debugAttempt(ex.id, _codeController.text, _watch.elapsed.inSeconds);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _attempt = r;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _actionError = e.statusCode == 503 ? _sandboxDown : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _actionError = 'Something went wrong while running your fix. Please try again.';
      });
    }
  }

  Future<void> _needAHint() async {
    final ex = _exercise;
    if (ex == null || _isHintLoading) return;
    setState(() {
      _isHintLoading = true;
      _actionError = null;
    });
    try {
      final h = await BackendApi.instance.debugHint(ex.id, _hints.length + 1);
      if (!mounted) return;
      setState(() {
        _isHintLoading = false;
        if (h.hint.isNotEmpty) _hints.add(h);
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _isHintLoading = false;
        _actionError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isHintLoading = false;
        _actionError = 'Could not load a hint. Please try again.';
      });
    }
  }

  bool get _hintsLeft {
    final ex = _exercise;
    if (ex == null) return false;
    final total = _hints.isNotEmpty ? _hints.last.totalLevels : ex.hintCount;
    return _hints.length < total;
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
        Navigator.of(context).pushReplacementNamed(RouteNames.coding, arguments: {'conceptId': _conceptId});
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
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) return LoadErrorView(message: _loadError!, onRetry: _load);
    final ex = _exercise;
    if (ex == null || _noExercise) {
      return LoadErrorView(
        message: 'There is no debugging exercise for ${_concept?.name ?? 'this concept'} yet.',
        icon: Icons.bug_report_outlined,
      );
    }
    final fixed = _attempt?.passed ?? false;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConceptHeader(
            title: _concept?.name ?? ex.title,
            difficulty: _titleCase(_concept?.difficulty ?? ex.difficulty),
            tags: [if (ex.bugCategory.isNotEmpty) _titleCase(ex.bugCategory.replaceAll('_', ' '))],
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
          fixed ? _buildResult(context, ex, _attempt!) : _buildDebug(context, ex),
        ],
      ),
    );
  }

  static String _titleCase(String s) => s
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  String _caseDetail(CaseOutcome c) {
    if (c.hidden) return c.passed ? 'Hidden case' : 'Hidden case (inputs are not revealed)';
    if (c.passed) return 'Input: ${c.input}  |  Output: ${c.actual}';
    return 'Input: ${c.input}  |  Expected: ${c.expected}  |  Received: ${c.actual.isEmpty ? c.status : c.actual}';
  }

  Widget _buildDebug(BuildContext context, DebugExerciseModel ex) {
    final a = _attempt;
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
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.error)),
                child: const Icon(Icons.bug_report_rounded, color: AppColors.error, size: 20),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DEBUG', style: AppTextStyles.heading2.copyWith(color: AppColors.error)),
                    Text(ex.title, style: AppTextStyles.body),
                  ],
                ),
              ),
            ],
          ),
          if (ex.description.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Text(ex.description, style: AppTextStyles.body),
          ],
          if (ex.samples.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            for (final s in ex.samples)
              Text(
                'Example ${s.number}: input ${s.input.isEmpty ? '(none)' : s.input}  ->  expected ${s.expectedOutput}',
                style: AppTextStyles.caption.copyWith(fontFamily: AppTextStyles.monoFamily),
              ),
          ],
          const SizedBox(height: AppDimensions.spacingLg),
          Text('Fix the bug in this code', style: AppTextStyles.bodyBold),
          const SizedBox(height: AppDimensions.spacingSm),
          CodeEditor(controller: _codeController),
          if (a != null) ...[
            const SizedBox(height: AppDimensions.spacingLg),
            _buildFailure(a),
          ],
          if (_hints.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingLg),
            for (final h in _hints)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.warning.withOpacity(0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning, size: 18),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Expanded(
                      child: Text.rich(TextSpan(style: AppTextStyles.body, children: [
                        TextSpan(text: 'Hint ${h.level}/${h.totalLevels}: ', style: AppTextStyles.bodyBold),
                        TextSpan(text: h.hint),
                      ])),
                    ),
                  ],
                ),
              ),
          ],
          if (_actionError != null) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Text(_actionError!, style: AppTextStyles.body.copyWith(color: AppColors.warning)),
          ],
          const SizedBox(height: AppDimensions.spacingLg),
          if (_isSubmitting)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
              child: Text('Compiling and testing your fix in the sandbox. This can take up to 30 seconds.',
                  style: AppTextStyles.caption),
            ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppButton(
                  label: _isSubmitting ? 'Running...' : 'Submit Fix',
                  icon: Icons.play_arrow_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _submitFix,
                ),
              ),
              if (ex.hintCount > 0) ...[
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  flex: 3,
                  child: AppButton(
                    label: _hintsLeft ? 'Need a Hint?' : 'No more hints',
                    icon: Icons.auto_awesome_rounded,
                    outlined: true,
                    isLoading: _isHintLoading,
                    onPressed: _hintsLeft ? _needAHint : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFailure(DebugAttemptResult a) {
    final failed = a.testsTotal - a.testsPassed;
    final String title;
    switch (a.status) {
      case 'COMPILATION_ERROR':
        title = 'Your fix does not compile.';
        break;
      case 'RUNTIME_ERROR':
        title = 'Your fix crashed while running.';
        break;
      case 'TIMEOUT':
        title = 'Your fix timed out.';
        break;
      default:
        title = 'Your fix failed $failed of ${a.testsTotal} test${a.testsTotal == 1 ? '' : 's'}.';
    }
    return Container(
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
              Expanded(child: Text(title, style: AppTextStyles.bodyBold.copyWith(color: AppColors.error))),
            ],
          ),
          if (a.errorCategory.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Error category: ${_titleCase(a.errorCategory.replaceAll('_', ' '))}', style: AppTextStyles.caption),
          ],
          const SizedBox(height: AppDimensions.spacingSm),
          for (var i = 0; i < a.cases.length; i++)
            DebugResultCard(
              label: a.cases[i].hidden ? 'Hidden test ${a.cases[i].number}' : 'Test ${a.cases[i].number}',
              passed: a.cases[i].passed,
              detail: _caseDetail(a.cases[i]),
              showDivider: i != a.cases.length - 1,
            ),
          if (a.errorMessage.trim().isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingSm + 4),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
              child: SelectableText(
                a.errorMessage.trim(),
                style: TextStyle(fontFamily: AppTextStyles.monoFamily, fontSize: 12, color: AppColors.error, height: 1.5),
              ),
            ),
          ],
          if (a.consecutiveFailures >= 2 || a.persistentWeakness) ...[
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
                  const Icon(Icons.track_changes_rounded, color: AppColors.btnAccentPurple, size: 18),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: Text(
                      a.persistentWeakness
                          ? '${a.consecutiveFailures} misses in a row: we flagged this as a weak spot. Take a hint or review the diagnosis before another try.'
                          : '${a.consecutiveFailures} misses in a row. A hint or the diagnosis may help.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pushNamed(RouteNames.aiFeedback),
                    child: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, DebugExerciseModel ex, DebugAttemptResult a) {
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
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.success)),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DEBUG RESULT', style: AppTextStyles.heading2.copyWith(color: AppColors.accentCyan)),
                    Text(
                      'Your fix worked! ${a.testsPassed}/${a.testsTotal} test cases passed'
                      '${a.hintsUsed > 0 ? ' (${a.hintsUsed} hint${a.hintsUsed == 1 ? '' : 's'} used)' : ''}.',
                      style: AppTextStyles.body,
                    ),
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
                for (var i = 0; i < a.cases.length; i++)
                  DebugResultCard(
                    label: a.cases[i].hidden ? 'Hidden test ${a.cases[i].number}' : 'Test ${a.cases[i].number}',
                    passed: a.cases[i].passed,
                    showDivider: i != a.cases.length - 1,
                  ),
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
                    const Icon(Icons.psychology_alt_rounded, color: AppColors.btnAccentPurple, size: 20),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Expanded(child: Text("What's Next?", style: AppTextStyles.bodyBold)),
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
                        onTap: () => Navigator.of(context).pushNamed(RouteNames.byteDnaSummary),
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
            onPressed: () => Navigator.of(context)
                .pushReplacementNamed(RouteNames.interviewIntro, arguments: {'conceptId': _conceptId}),
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
