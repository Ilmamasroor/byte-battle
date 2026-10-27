import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';
import '../../../../core/widgets/difficulty_badge.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../state/battle_ai_controller.dart';
import '../state/battle_controller.dart';
import '../widgets/battle_answer_option.dart';
import '../widgets/battle_timer.dart';
import '../widgets/life_indicator.dart';

/// Battle round screen: loads the concept's battle from the backend, starts a session and plays it question by
/// question. Answers are graded by the server (it never reveals the right option), lives and score come back
/// with every answer, and the per-question countdown comes from the battle's `timeLimitSeconds`.
/// Used for the regular Challenge stage and, with [boss] true, for the Boss Battle.
class BattleScreen extends StatefulWidget {
  final String conceptId;
  final bool boss;

  const BattleScreen({super.key, required this.conceptId, this.boss = false});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final BattleController _battle = BattleController(conceptId: widget.conceptId, boss: widget.boss);
  final _ai = BattleAiController.instance;

  String? _selected;
  Timer? _ticker;
  final Stopwatch _clock = Stopwatch();
  int _secondsLeft = 0;
  String? _timedQuestionId;

  // hints for the question on screen (POST /api/ai/battle-hint, levels 1..3)
  final List<String> _hints = [];
  bool _hintLoading = false;
  String? _hintError;

  @override
  void initState() {
    super.initState();
    _battle.addListener(_onBattleChanged);
    _battle.loadAndStart();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _battle.removeListener(_onBattleChanged);
    _battle.dispose();
    super.dispose();
  }

  /// Starts (or resets) the countdown whenever a new question appears.
  void _onBattleChanged() {
    final q = _battle.question;
    if (q == null || _battle.answeredCurrent || _timedQuestionId == q.id) return;
    _timedQuestionId = q.id;
    _selected = null;
    _hints.clear();
    _hintError = null;
    _clock
      ..reset()
      ..start();
    _secondsLeft = _battle.timeLimitSeconds;
    _ticker?.cancel();
    if (_battle.timeLimitSeconds > 0) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    if (!mounted) return;
    if (_battle.answeredCurrent || _battle.isSubmitting) return;
    final left = (_battle.timeLimitSeconds - _clock.elapsed.inSeconds).clamp(0, _battle.timeLimitSeconds);
    setState(() => _secondsLeft = left);
    if (left == 0) _submit(timedOut: true);
  }

  Future<void> _submit({bool timedOut = false}) async {
    final answer = timedOut ? 'TIME_UP' : _selected;
    if (answer == null) return;
    _ticker?.cancel();
    final seconds = _clock.elapsed.inSeconds;
    _clock.stop();
    final result = await _battle.submit(answer, seconds);
    if (!mounted) return;
    if (_battle.sessionEnded) {
      await _finish();
      return;
    }
    if (result == null) {
      // could not send it: let the learner retry (and keep the clock honest)
      _clock.start();
      if (_battle.timeLimitSeconds > 0 && !timedOut) {
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      }
      return;
    }
    if (!result.correct) {
      await Navigator.of(context).pushNamed(RouteNames.battleFeedback, arguments: {
        'conceptId': widget.conceptId,
        'topicLabel': _battle.conceptName,
        'message': timedOut
            ? "Time ran out on this one. You lost a life (${result.lives} left)."
            : result.lives > 0
                ? 'That was not the right answer. You lost a life (${result.lives} left).'
                : 'That was not the right answer, and you are out of lives.',
        'question': _battle.question?.text,
        'continueLabel': 'Continue',
      });
    }
  }

  Future<void> _next() async {
    if (_battle.finishedAfterAnswer) {
      await _finish();
    } else {
      _battle.advance();
    }
  }

  Future<void> _finish() async {
    final outcome = await _battle.finish();
    if (!mounted || outcome == null) return;
    Navigator.of(context).pushReplacementNamed(RouteNames.bossBattleResult, arguments: outcome);
  }

  Future<void> _getHint() async {
    final q = _battle.question;
    final info = _battle.concept;
    if (q == null || info == null || _hintLoading || _hints.length >= 3) return;
    setState(() {
      _hintLoading = true;
      _hintError = null;
    });
    final knowledge = await _ai.canonicalFor(widget.conceptId);
    await _ai.loadBattleHint(
      concept: ConceptModel(id: info.id, name: info.name, description: info.description, difficulty: info.difficulty),
      question: q.text,
      canonicalKnowledge: knowledge,
      hintLevel: _hints.length + 1,
    );
    if (!mounted) return;
    setState(() {
      _hintLoading = false;
      final text = _ai.battleHint?.hint.hint ?? '';
      if (_ai.hintErrorMessage != null) {
        _hintError = _ai.hintErrorMessage;
      } else if (text.isNotEmpty) {
        _hints.add(text);
      } else {
        _hintError = 'No hint available right now. Try again in a moment.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Intentionally no back button during a live battle (leaving would abandon the session).
    return ListenableBuilder(
      listenable: _battle,
      builder: (context, _) {
        if (_battle.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: LoadingView(message: 'Preparing your battle...'),
          );
        }
        final q = _battle.question;
        if (_battle.errorMessage != null || q == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ErrorView(
                      message: _battle.errorMessage ?? 'Could not load the battle.',
                      onRetry: _battle.noBattle ? null : _battle.loadAndStart,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.screenPadding),
                    child: AppButton(
                      label: 'BACK',
                      outlined: true,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildRound(context, q);
      },
    );
  }

  Widget _buildRound(BuildContext context, BattleQuestionModel q) {
    final answer = _battle.lastAnswer;
    final graded = answer != null;
    final locked = graded || _battle.isSubmitting;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Round ${_battle.round}/${_battle.totalQuestions}', style: AppTextStyles.heading2),
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text(
                          widget.boss ? 'Boss battle' : (_battle.battle?.title ?? 'Battle'),
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_battle.timeLimitSeconds > 0) BattleTimer(secondsRemaining: _secondsLeft),
                  const SizedBox(width: AppDimensions.spacingSm),
                  LifeIndicator(lives: _battle.lives, maxLives: _battle.maxLives),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _RoundProgress(round: _battle.round, total: _battle.totalQuestions, graded: graded),
              const SizedBox(height: AppDimensions.spacingMd),
              Row(
                children: [
                  DifficultyBadge(level: _displayDifficulty(_battle.battle?.difficulty ?? '')),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: Text(
                      '${_battle.conceptName}  •  ${_label(q.type)}',
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('Score ${_battle.score}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight)),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimensions.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(q.text, style: AppTextStyles.bodyBold.copyWith(fontSize: 16, height: 1.45)),
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                      if (q.options.isEmpty)
                        Text('This question has no answer options.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                      for (final option in q.options)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                          child: BattleAnswerOption(
                            label: option,
                            index: q.options.indexOf(option),
                            selected: _selected == option,
                            state: !graded || _selected != option
                                ? BattleOptionState.idle
                                : (answer.correct ? BattleOptionState.correct : BattleOptionState.wrong),
                            onTap: locked ? null : () => setState(() => _selected = option),
                          ),
                        ),
                      if (graded) _AnswerBanner(answer: answer),
                      if (_battle.actionError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppDimensions.spacingSm),
                          child: Text(_battle.actionError!,
                              style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                        ),
                      const SizedBox(height: AppDimensions.spacingSm),
                      for (var i = 0; i < _hints.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                          child: _HintCard(index: i + 1, text: _hints[i]),
                        ),
                      if (_hintError != null)
                        Text(_hintError!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                      if (!graded && _hints.length < 3)
                        TextButton.icon(
                          onPressed: _hintLoading ? null : _getHint,
                          icon: _hintLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.lightbulb_outline_rounded, size: 18),
                          label: Text(_hintLoading
                              ? 'Thinking...'
                              : (_hints.isEmpty ? 'Get a Hint' : 'Get a Stronger Hint')),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              AppButton(
                label: graded
                    ? (_battle.finishedAfterAnswer ? 'SEE RESULT' : 'NEXT')
                    : 'CONTINUE',
                isLoading: _battle.isSubmitting || _battle.isFinishing,
                onPressed: graded
                    ? _next
                    : (_selected == null || _battle.isSubmitting ? null : () => _submit()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `MCQ` / `PREDICT_OUTPUT` -> "Predict output".
  static String _label(String type) {
    if (type.isEmpty) return 'Question';
    if (type == 'MCQ') return 'Multiple choice';
    final words = type.toLowerCase().split('_');
    return '${words.first[0].toUpperCase()}${words.first.substring(1)}${words.length > 1 ? ' ${words.sublist(1).join(' ')}' : ''}';
  }

  /// [DifficultyBadge] only special-cases 'intermediate'/'advanced', so map the backend's EASY/MEDIUM/HARD.
  static String _displayDifficulty(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'MEDIUM':
        return 'Intermediate';
      case 'HARD':
        return 'Advanced';
      default:
        return 'Beginner';
    }
  }
}

/// The companion reacting to the graded answer: cheering a correct one (with an XP pop) and encouraging after a
/// miss, so a wrong answer feels like part of the game instead of a penalty.
class _AnswerBanner extends StatelessWidget {
  final BattleAnswerResult answer;
  const _AnswerBanner({required this.answer});

  static const _cheers = ['Boom! That is exactly it.', 'Clean. You are getting the hang of this.', 'Yes! Nailed it.', 'Sharp thinking. Keep that streak.'];
  static const _oops = ['So close. Every miss teaches you something.', 'Tricky one! Now you know the trap.', 'That is a classic mix-up. It sticks better now.'];

  @override
  Widget build(BuildContext context) {
    final color = answer.correct ? AppColors.success : AppColors.error;
    final pool = answer.correct ? _cheers : _oops;
    final line = pool[(answer.pointsEarned + answer.lives) % pool.length];
    final tail = answer.correct
        ? ''
        : (answer.lives > 0 ? ' You lost a life, ${answer.lives} left.' : ' You are out of lives.');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppDimensions.spacingSm),
      padding: const EdgeInsets.fromLTRB(AppDimensions.spacingSm, AppDimensions.spacingSm, AppDimensions.spacingMd, AppDimensions.spacingSm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          BitMascot(size: 48, mood: answer.correct ? BitMood.cheer : BitMood.curious),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$line$tail', style: AppTextStyles.bodyBold.copyWith(fontSize: 13.5, height: 1.4)),
                if (answer.correct && answer.pointsEarned > 0) ...[
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.4, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, t, child) => Transform.scale(scale: t, alignment: Alignment.centerLeft, child: child),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.xp, borderRadius: BorderRadius.circular(100)),
                      child: Text('+${answer.pointsEarned} XP', style: AppTextStyles.caption.copyWith(color: AppColors.onAccent, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final int index;
  final String text;
  const _HintCard({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppDimensions.spacingSm, AppDimensions.spacingSm, AppDimensions.spacingMd, AppDimensions.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.xp.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.xp.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BitMascot(size: 40, mood: BitMood.curious),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HINT $index', style: AppTextStyles.eyebrow.copyWith(color: AppColors.xp, fontSize: 10)),
                const SizedBox(height: 3),
                Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// Segmented progress through the battle's rounds: done = Flame, current = outlined, upcoming = quiet.
class _RoundProgress extends StatelessWidget {
  final int round;
  final int total;
  final bool graded;
  const _RoundProgress({required this.round, required this.total, required this.graded});

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: 5),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 6,
              decoration: BoxDecoration(
                color: i < round || (i == round && graded) ? AppColors.primary : (i == round ? AppColors.primary.withOpacity(0.4) : AppColors.surfaceRaised),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
