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
import '../../../../core/widgets/buttons/buttons.dart';
import '../widgets/code_editor.dart';
import '../widgets/execution_result.dart';
import '../widgets/load_error_view.dart';

/// Implement stage: loads the concept's real coding challenge, sends the learner's code to the backend (which
/// runs it against the test cases in the Judge0 sandbox) and shows the verdict per test case plus the AI feedback.
class CodingScreen extends StatefulWidget {
  const CodingScreen({super.key});

  @override
  State<CodingScreen> createState() => _CodingScreenState();
}

class _CodingScreenState extends State<CodingScreen> {
  final _codeController = TextEditingController();
  final _scroll = ScrollController();
  final _resultKey = GlobalKey();

  String _conceptId = AppConstants.defaultConceptId;
  bool _started = false;

  ConceptInfo? _concept;
  CodingChallengeModel? _challenge;
  bool _loading = true;
  String? _loadError;
  bool _noChallenge = false;

  bool _submitting = false;
  String? _submitError;
  SubmissionResult? _result;
  String? _aiFeedback;
  bool _aiPending = false;
  int _runToken = 0;

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
    _runToken++;
    _codeController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _noChallenge = false;
    });
    try {
      final api = BackendApi.instance;
      final results = await Future.wait<Object?>([
        api.challengesForConcept(_conceptId),
        api.concept(_conceptId).then<ConceptInfo?>((c) => c).catchError((_) => null),
      ]);
      final list = results[0] as List<CodingChallengeModel>;
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() {
          _concept = results[1] as ConceptInfo?;
          _noChallenge = true;
          _loading = false;
        });
        return;
      }
      final detail = await api.challenge(list.first.id);
      if (!mounted) return;
      _codeController.text = detail.starterCode;
      setState(() {
        _concept = results[1] as ConceptInfo?;
        _challenge = detail;
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
        _loadError = 'Could not load the coding challenge. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final challenge = _challenge;
    if (challenge == null || _submitting) return;
    if (_codeController.text.trim().isEmpty) {
      setState(() => _submitError = 'Write some code before submitting.');
      return;
    }
    final token = ++_runToken;
    setState(() {
      _submitting = true;
      _submitError = null;
      _result = null;
      _aiFeedback = null;
      _aiPending = false;
    });
    try {
      final r = await BackendApi.instance.submitCode(challenge.id, _codeController.text, challenge.language);
      if (!mounted || token != _runToken) return;
      if (r.status == 'EXECUTION_UNAVAILABLE') {
        setState(() {
          _submitting = false;
          _submitError = _sandboxDown;
        });
        return;
      }
      setState(() {
        _submitting = false;
        _result = r;
        _aiFeedback = r.aiFeedback;
        _aiPending = r.aiFeedback.isEmpty;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _resultKey.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
      });
      if (r.aiFeedback.isEmpty) unawaited(_pollFeedback(r.submissionId, token));
    } on NetworkException catch (e) {
      if (!mounted || token != _runToken) return;
      setState(() {
        _submitting = false;
        _submitError = e.statusCode == 503 ? _sandboxDown : e.message;
      });
    } catch (_) {
      if (!mounted || token != _runToken) return;
      setState(() {
        _submitting = false;
        _submitError = 'Something went wrong while running your code. Please try again.';
      });
    }
  }

  static const _sandboxDown = 'The code sandbox is temporarily unavailable, so your code was not judged. '
      'This is not a failed attempt. Please try again in a moment.';

  /// The backend attaches the AI feedback a few seconds after the verdict; look for it a handful of times.
  Future<void> _pollFeedback(String submissionId, int token) async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted || token != _runToken) return;
      try {
        final s = await BackendApi.instance.submission(submissionId);
        if (!mounted || token != _runToken) return;
        if (s.aiFeedback.isNotEmpty) {
          setState(() {
            _aiFeedback = s.aiFeedback;
            _aiPending = false;
          });
          return;
        }
      } catch (_) {
        // best effort: keep waiting, give up after the last round
      }
    }
    if (mounted && token == _runToken) setState(() => _aiPending = false);
  }

  void _toDebugging() => Navigator.of(context).pushReplacementNamed(RouteNames.debugging, arguments: {'conceptId': _conceptId});

  Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'beginner':
      case 'easy':
        return AppColors.success;
      case 'hard':
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(challenge?.title ?? 'Implement', style: AppTextStyles.heading2),
        actions: [
          if (challenge != null)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spacingMd),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _difficultyColor(challenge.difficulty).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                  child: Text(_cap(challenge.difficulty),
                      style: TextStyle(color: _difficultyColor(challenge.difficulty), fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(challenge),
    );
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Widget _buildBody(CodingChallengeModel? challenge) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) return LoadErrorView(message: _loadError!, onRetry: _load);
    if (challenge == null || _noChallenge) {
      return LoadErrorView(
        message: 'There is no coding challenge for ${_concept?.name ?? 'this concept'} yet.',
        icon: Icons.code_off_rounded,
      );
    }
    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_concept != null) ...[
            Text('${_concept!.name} • Implement',
                style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight)),
            const SizedBox(height: AppDimensions.spacingSm),
          ],
          Text(challenge.description, style: AppTextStyles.body),
          if (challenge.constraints.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            Text('Constraints: ${challenge.constraints}', style: AppTextStyles.caption),
          ],
          if (challenge.samples.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            for (final s in challenge.samples)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Example ${s.number}: input ${s.input.isEmpty ? '(none)' : s.input}  ->  expected ${s.expectedOutput}',
                  style: AppTextStyles.caption.copyWith(fontFamily: AppTextStyles.monoFamily),
                ),
              ),
          ],
          const SizedBox(height: AppDimensions.spacingMd),
          CodeEditor(controller: _codeController),
          const SizedBox(height: AppDimensions.spacingMd),
          ActionButton(
            label: _submitting ? 'Running your code...' : 'Run & Submit',
            icon: Icons.play_arrow_rounded,
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
            size: AppButtonSize.xl,
          ),
          if (_submitting) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            Text('Compiling and testing in the sandbox. This can take up to 30 seconds.',
                style: AppTextStyles.caption),
          ],
          if (_submitError != null) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.warning.withOpacity(0.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(child: Text(_submitError!, style: AppTextStyles.body)),
                ],
              ),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: AppDimensions.spacingLg),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppDimensions.spacingLg),
            KeyedSubtree(
              key: _resultKey,
              child: ExecutionResult(
                title: challenge.title,
                difficulty: _cap(challenge.difficulty),
                result: _result!,
                aiFeedback: _aiFeedback,
                aiFeedbackPending: _aiPending,
                onContinue: _toDebugging,
                onPracticeDebugging: _toDebugging,
                onTryAgain: () => setState(() => _result = null),
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spacingXl),
        ],
      ),
    );
  }
}
