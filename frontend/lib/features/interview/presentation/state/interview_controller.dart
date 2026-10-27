import 'package:flutter/foundation.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/network/backend_api.dart';

/// One answered question: what was asked, what the learner wrote and how the backend's AI rubric graded it.
class InterviewAnswer {
  final String question;
  final String answer;
  final int? score; // 0-100, null when the AI service could not grade it
  final String feedback;
  final Map<String, double> rubric;
  const InterviewAnswer(this.question, this.answer, this.score, this.feedback, this.rubric);
}

/// One persisted mock interview (`/api/interviews`): the backend asks the questions, grades every answer
/// against a rubric, stores the session and records the result as learner evidence when it is completed.
class InterviewController extends ChangeNotifier {
  InterviewController._();
  static final InterviewController instance = InterviewController._();

  /// The backend's closing prompt after the last allowed answer.
  static const lastQuestionPrefix = 'That was the last question';

  final BackendApi _api = BackendApi.instance;

  ConceptInfo? concept;
  InterviewSessionModel? session;
  String? currentQuestion;
  final List<InterviewAnswer> answers = [];
  InterviewResultModel? result;

  bool isStarting = false;
  bool isSending = false;
  bool isCompleting = false;
  String? errorMessage;

  /// True once the backend says there are no more questions.
  bool get noMoreQuestions => currentQuestion?.startsWith(lastQuestionPrefix) ?? false;

  /// The latest graded answer, shown as feedback above the next question.
  InterviewAnswer? get lastAnswer => answers.isEmpty ? null : answers.last;

  /// Mean of each rubric dimension over all graded answers (0..1); empty when nothing was graded.
  Map<String, double> get averageRubric {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final a in answers) {
      a.rubric.forEach((k, v) {
        sums[k] = (sums[k] ?? 0) + v;
        counts[k] = (counts[k] ?? 0) + 1;
      });
    }
    return {for (final k in sums.keys) k: sums[k]! / counts[k]!};
  }

  String _message(Object e) => e is Exception ? e.toString() : 'Something went wrong. Please try again.';

  void reset() {
    concept = null;
    session = null;
    currentQuestion = null;
    answers.clear();
    result = null;
    errorMessage = null;
    notifyListeners();
  }

  /// Loads the real concept for the intro screen.
  Future<void> loadConcept(String conceptId) async {
    errorMessage = null;
    notifyListeners();
    try {
      concept = await _api.concept(conceptId);
    } catch (e) {
      errorMessage = _message(e);
    }
    notifyListeners();
  }

  /// `POST /api/interviews` then `GET .../messages` for the opening question. Returns true on success.
  Future<bool> start(String conceptId, String difficulty) async {
    isStarting = true;
    errorMessage = null;
    answers.clear();
    result = null;
    notifyListeners();
    try {
      final created = await _api.startInterview(conceptId, difficulty);
      final messages = await _api.interviewMessages(created.id);
      final question = messages.lastWhere((m) => m.role == 'ASSISTANT', orElse: () => messages.first).content;
      session = created;
      currentQuestion = question;
      return true;
    } catch (e) {
      errorMessage = _message(e);
      debugPrint('🎤 [InterviewController.start] FAILED -> $e');
      return false;
    } finally {
      isStarting = false;
      notifyListeners();
    }
  }

  /// `POST /api/interviews/{id}/messages`: the reply carries the next question plus the grade of this answer.
  Future<bool> submit(String text) async {
    final s = session, question = currentQuestion;
    if (s == null || question == null) {
      errorMessage = 'Start the interview first.';
      notifyListeners();
      return false;
    }
    isSending = true;
    errorMessage = null;
    notifyListeners();
    try {
      final reply = await _api.sendInterviewAnswer(s.id, text);
      answers.add(InterviewAnswer(question, text, reply.score, reply.feedback, reply.rubric));
      currentQuestion = reply.content;
      return true;
    } catch (e) {
      errorMessage = _message(e);
      debugPrint('🎤 [InterviewController.submit] FAILED -> $e');
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  /// `POST /api/interviews/{id}/complete`: stores the score and records the evidence. Idempotent.
  Future<bool> complete() async {
    final s = session;
    if (s == null) return false;
    isCompleting = true;
    errorMessage = null;
    notifyListeners();
    try {
      result = await _api.completeInterview(s.id);
      return true;
    } catch (e) {
      errorMessage = _message(e);
      debugPrint('🎤 [InterviewController.complete] FAILED -> $e');
      return false;
    } finally {
      isCompleting = false;
      notifyListeners();
    }
  }
}
