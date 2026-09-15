import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/difficulty_badge.dart';
import '../../data/battle_question_bank.dart';
import '../state/battle_ai_controller.dart';
import '../widgets/battle_option.dart';
import '../widgets/battle_timer.dart';
import '../widgets/life_indicator.dart';

/// Boss Battle round screen — matches the "Round 3/5" screenshot: round
/// + lives header, a countdown timer chip, the question prompt (pulled
/// from [BattleAiController.loadQuestions], see note below) and the
/// SOLVED IT / I'M STUCK choice buttons.
///
/// There's no backend endpoint yet that hands back a fixed list of
/// battle questions, so the round pool always resolves to the local
/// [kBattleQuestionBank] fallback (see [BattleRepository.getQuestions]
/// for the seam that will call a real endpoint once one exists).
class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final _controller = BattleAiController.instance;

  @override
  void initState() {
    super.initState();
    Helpers.noApiYet('BattleScreen', note: 'question bank is hardcoded fallback (no list-battle-questions endpoint yet)');
    _controller.loadQuestions();
  }

  static const _totalRounds = 5;

  int _currentRound = 3;
  int _lives = 3;

  String? _selected;
  bool _answered = false;

  // ---- Hint reveal state (per round) ----
  int _revealedHints = 0;
  bool _hintLoading = false;

  bool get _isCorrect => _selected == 'SOLVED';

  BattleQuestionData _questionFor(List<BattleQuestionData> bank) {
    return bank[(_currentRound - 1) % bank.length];
  }

  void _select(String option) {
    if (_answered) return;
    setState(() => _selected = option);
  }

  Future<void> _revealNextHint(BattleQuestionData question) async {
    if (_hintLoading || _revealedHints >= question.hints.length) return;
    setState(() => _hintLoading = true);
    // Hardcoded 2-second "thinking" delay before the hint appears.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _revealedHints += 1;
      _hintLoading = false;
    });
  }

  void _continue(BattleQuestionData question) {
    if (_selected == null) return;
    setState(() => _answered = true);
    if (!_isCorrect) {
      setState(() => _lives = (_lives - 1).clamp(0, 3));
      // Wrong answer -> show the full-screen feedback with hints. This is
      // only ever reached from here (an "I'm stuck" pick), so it can't
      // show up in the wrong place in the flow. Coming back ("Try Again")
      // resets the round so the person can retry the same question.
      Navigator.of(context)
          .pushNamed(
        RouteNames.battleFeedback,
        arguments: {
          'topicLabel': question.topicLabel,
          'message':
              "No worries — this one's tricky. Here's some help getting unstuck.",
          'hints': question.hints,
          'quote': 'Every bug is a lesson in disguise.',
          'question': question.question,
        },
      )
          .then((_) {
        if (!mounted) return;
        setState(() {
          _selected = null;
          _answered = false;
          _revealedHints = 0;
        });
      });
    }
  }

  void _next() {
    if (_lives == 0) {
      Navigator.of(context).pushReplacementNamed(RouteNames.bossBattleIntro);
      return;
    }
    if (_currentRound >= _totalRounds) {
      Navigator.of(context).pushReplacementNamed(RouteNames.bossBattleResult);
      return;
    }
    setState(() {
      _currentRound += 1;
      _selected = null;
      _answered = false;
      _revealedHints = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Intentionally no back button — confirm with product whether learners
    // should be able to exit an active battle early (e.g. via a confirm-exit
    // dialog) or this is by design.
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final bank = _controller.questions;
        if (bank == null || bank.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final question = _questionFor(bank);

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
                            Text('Round $_currentRound/$_totalRounds', style: AppTextStyles.heading2),
                            const SizedBox(height: AppDimensions.spacingXs),
                            Text('Boss battle', style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const BattleTimer(secondsRemaining: 102),
                      const SizedBox(width: AppDimensions.spacingSm),
                      LifeIndicator(lives: _lives),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Row(
                    children: [
                      DifficultyBadge(level: _displayDifficulty(question.difficulty)),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Expanded(
                        child: Text(
                          question.topicLabel,
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                            ),
                            child: Text(question.question, style: AppTextStyles.bodyBold),
                          ),
                          const SizedBox(height: AppDimensions.spacingLg),
                          for (var i = 0; i < _revealedHints; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                  border: Border.all(color: AppColors.borderLight.withOpacity(0.4)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.lightbulb_outline_rounded,
                                        color: AppColors.warning, size: 18),
                                    const SizedBox(width: AppDimensions.spacingSm),
                                    Expanded(
                                      child: Text('Hint ${i + 1}: ${question.hints[i]}',
                                          style: AppTextStyles.body),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_revealedHints < question.hints.length)
                            TextButton.icon(
                              onPressed: _hintLoading ? null : () => _revealNextHint(question),
                              icon: _hintLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.lightbulb_outline_rounded, size: 18),
                              label: Text(_hintLoading
                                  ? 'Thinking...'
                                  : (_revealedHints == 0 ? 'Get a Hint' : 'Get Next Hint')),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Row(
                    children: [
                      BattleOption(
                        label: "I'M STUCK",
                        color: AppColors.warning,
                        selected: _selected == 'STUCK',
                        onTap: () => _select('STUCK'),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      BattleOption(
                        label: 'SOLVED IT',
                        color: AppColors.success,
                        selected: _selected == 'SOLVED',
                        onTap: () => _select('SOLVED'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  AppButton(
                    label: _answered ? 'NEXT' : 'CONTINUE',
                    onPressed: _answered ? _next : (_selected == null ? null : () => _continue(question)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// [DifficultyBadge] only special-cases 'intermediate'/'advanced'
  /// (defaulting everything else to the beginner/green look), so map this
  /// question bank's EASY/MEDIUM/HARD labels onto that vocabulary.
  String _displayDifficulty(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'MEDIUM':
        return 'Intermediate';
      case 'HARD':
        return 'Advanced';
      case 'EASY':
      default:
        return 'Beginner';
    }
  }
}
