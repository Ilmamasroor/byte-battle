import 'package:flutter/foundation.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/network/backend_api.dart';
import '../../../../core/network/network_exception.dart';

/// What the learner did in a finished battle, handed to the result and score screens.
class BattleOutcome {
  final BattleResultModel result;
  final int answered;
  final int wrong;
  final bool boss;
  final String conceptId;
  final String conceptName;
  final String battleTitle;

  const BattleOutcome({
    required this.result,
    required this.answered,
    required this.wrong,
    required this.boss,
    required this.conceptId,
    required this.conceptName,
    required this.battleTitle,
  });

  /// 0..100, share of the answered questions that were right.
  int get accuracy => answered == 0 ? 0 : ((result.correctAnswers / answered) * 100).round().clamp(0, 100);
}

/// Picks the battle to play for a concept: the boss battle for the boss route, otherwise the regular battle
/// (quiz / survival / speed round). Returns null when the concept has no such battle.
BattleInfo? pickBattle(List<BattleInfo> battles, String conceptId, {required bool boss}) {
  for (final b in battles) {
    if (b.conceptId == conceptId && b.isBoss == boss) return b;
  }
  return null;
}

/// Holds one live battle against the backend: loads the concept's battle, starts a session, grades every answer
/// on the server (it never reveals the right option), and completes the session for the final result.
class BattleController extends ChangeNotifier {
  BattleController({required this.conceptId, required this.boss, BackendApi? api}) : _api = api ?? BackendApi.instance;

  final String conceptId;
  final bool boss;
  final BackendApi _api;

  bool isLoading = true;
  String? errorMessage;

  /// True when the failure is "this concept has no battle" rather than a transient one, so retrying is pointless.
  bool noBattle = false;

  ConceptInfo? concept;
  BattleInfo? battle;
  String? sessionId;
  BattleQuestionModel? question;
  int lives = 0;
  int score = 0;
  int answered = 0;
  int wrong = 0;

  /// 1-based number of the question on screen.
  int get round => answered + (answeredCurrent ? 0 : 1);

  /// The graded result of the question currently on screen (null until it has been answered).
  BattleAnswerResult? lastAnswer;
  bool get answeredCurrent => lastAnswer != null;

  bool isSubmitting = false;
  bool isFinishing = false;

  /// Shown under the options when submitting failed in a way the learner can retry.
  String? actionError;

  int get totalQuestions => battle?.totalQuestions ?? 0;
  int get maxLives => battle?.totalLives ?? lives;
  String get conceptName => concept?.name.isNotEmpty == true ? concept!.name : 'this concept';

  /// Seconds the learner gets for each question (0 = untimed).
  int get timeLimitSeconds => battle?.timeLimitSeconds ?? 0;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    noBattle = false;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([_api.battles(), _api.concept(conceptId)]);
      concept = results[1] as ConceptInfo;
      final picked = pickBattle(results[0] as List<BattleInfo>, conceptId, boss: boss);
      if (picked == null) {
        noBattle = true;
        errorMessage = boss
            ? 'There is no boss battle for ${concept!.name} yet.'
            : 'There is no battle for ${concept!.name} yet.';
      } else {
        battle = picked;
        lives = picked.totalLives;
      }
    } on NetworkException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Could not load the battle. Please try again.';
    }
    isLoading = false;
    notifyListeners();
  }

  /// `POST /api/battles/{id}/start`: opens a session and returns the first question.
  Future<void> start() async {
    final b = battle;
    if (b == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final started = await _api.startBattle(b.id);
      sessionId = started.sessionId;
      question = started.firstQuestion;
      lives = started.lives;
      score = 0;
      answered = 0;
      wrong = 0;
      lastAnswer = null;
    } on NetworkException catch (e) {
      errorMessage = e.statusCode == 409 ? 'This battle has no questions yet.' : e.message;
    } catch (_) {
      errorMessage = 'Could not start the battle. Please try again.';
    }
    isLoading = false;
    notifyListeners();
  }

  /// Loads the battle and starts a session in one go (the battle screen's entry point).
  Future<void> loadAndStart() async {
    await load();
    if (errorMessage == null) await start();
  }

  /// `POST /api/battle-sessions/{id}/attempts`. Returns the graded result, or null if it could not be graded
  /// (the reason is in [actionError]); a 409 means the server already closed the session / saw this answer.
  /// [sessionEnded] is true then, so the screen should go straight to the result.
  bool sessionEnded = false;

  Future<BattleAnswerResult?> submit(String answer, int seconds) async {
    final id = sessionId;
    final q = question;
    if (id == null || q == null || isSubmitting || answeredCurrent) return null;
    isSubmitting = true;
    actionError = null;
    notifyListeners();
    try {
      final r = await _api.answerBattle(id, q.id, answer, seconds);
      lastAnswer = r;
      answered += 1;
      if (!r.correct) wrong += 1;
      lives = r.lives;
      score = r.score;
      isSubmitting = false;
      notifyListeners();
      return r;
    } on NetworkException catch (e) {
      if (e.statusCode == 409) {
        // already answered, or the session is finished/expired: the server is the source of truth
        sessionEnded = true;
        actionError = 'This battle has already ended. Showing your result.';
      } else {
        actionError = e.message;
      }
    } catch (_) {
      actionError = 'Could not send your answer. Check your connection and try again.';
    }
    isSubmitting = false;
    notifyListeners();
    return null;
  }

  /// True when the answer on screen was the last one (all questions answered or out of lives).
  bool get finishedAfterAnswer => lastAnswer?.sessionCompleted == true || sessionEnded;

  /// Moves on to the next question the server handed back. Only valid when [finishedAfterAnswer] is false.
  void advance() {
    final next = lastAnswer?.nextQuestion;
    if (next == null) return;
    question = next;
    lastAnswer = null;
    actionError = null;
    notifyListeners();
  }

  /// `POST /api/battle-sessions/{id}/complete`: the server's final result (also records the XP and advances the
  /// learning stage when the battle was won). Returns null on failure ([actionError] explains).
  Future<BattleOutcome?> finish() async {
    final id = sessionId;
    final b = battle;
    if (id == null || b == null || isFinishing) return null;
    isFinishing = true;
    actionError = null;
    notifyListeners();
    try {
      final result = await _api.completeBattle(id);
      isFinishing = false;
      notifyListeners();
      return BattleOutcome(
        result: result,
        answered: answered,
        wrong: wrong,
        boss: boss,
        conceptId: conceptId,
        conceptName: conceptName,
        battleTitle: b.title,
      );
    } on NetworkException catch (e) {
      actionError = e.message;
    } catch (_) {
      actionError = 'Could not load your result. Please try again.';
    }
    isFinishing = false;
    notifyListeners();
    return null;
  }
}
