import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../learning/explanation/data/models/canonical_knowledge_model.dart';
import '../../data/datasources/interview_ai_remote_datasource.dart';
import '../../data/models/interview_message_model.dart';
import '../../data/models/interview_question_model.dart';
import '../../data/models/interview_result_model.dart';
import '../../data/repositories/interview_repository.dart';

/// Single source of truth for one Mock Interview session: the running
/// `conversationHistory`, the current question, and the most recent
/// answer evaluation. Same plain-singleton pattern as
/// `CodingFeedbackController.instance` / `BattleAiController.instance`.
class InterviewController extends ChangeNotifier {
  InterviewController._(this._repository);

  static InterviewController? _instance;

  static InterviewController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);
    final repository = InterviewRepository(InterviewAiRemoteDatasource(apiClient));
    _instance = InterviewController._(repository);
    return _instance!;
  }

  final InterviewRepository _repository;

  bool isLoadingQuestion = false;
  bool isEvaluating = false;
  String? errorMessage;

  ConceptModel? _concept;
  CanonicalKnowledgeModel? _canonicalKnowledge;
  final List<InterviewMessageModel> conversationHistory = [];

  InterviewQuestionModel? currentQuestion;
  InterviewEvaluationModel? lastEvaluation;

  /// `POST /api/ai/interview/question` with an empty conversation history
  /// — call this once, from [InterviewIntroScreen], to kick off a fresh
  /// session for [concept]/[canonicalKnowledge].
  Future<void> startInterview({
    required ConceptModel concept,
    required CanonicalKnowledgeModel canonicalKnowledge,
  }) async {
    _concept = concept;
    _canonicalKnowledge = canonicalKnowledge;
    conversationHistory.clear();
    lastEvaluation = null;
    currentQuestion = null;

    isLoadingQuestion = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentQuestion = await _repository.generateQuestion(
        concept: concept,
        canonicalKnowledge: canonicalKnowledge,
        conversationHistory: conversationHistory,
      );
      debugPrint('🎤 [InterviewController] loaded opening question for ${concept.id}');
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🎤 [InterviewController] FAILED (question) -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('🎤 [InterviewController] FAILED (question) -> unexpected error: $e');
    } finally {
      isLoadingQuestion = false;
      notifyListeners();
    }
  }

  /// `POST /api/ai/interview/evaluate` for [answer] against
  /// [currentQuestion], then records both turns in [conversationHistory]
  /// so a later [askFollowUpQuestion] call has the full context.
  /// Returns true on success.
  Future<bool> submitAnswer(String answer) async {
    final concept = _concept;
    final canonicalKnowledge = _canonicalKnowledge;
    final question = currentQuestion?.question;
    if (concept == null || canonicalKnowledge == null || question == null) {
      errorMessage = 'Start the interview before answering.';
      notifyListeners();
      return false;
    }

    isEvaluating = true;
    errorMessage = null;
    notifyListeners();

    var success = false;
    try {
      lastEvaluation = await _repository.evaluateAnswer(
        concept: concept,
        canonicalKnowledge: canonicalKnowledge,
        question: question,
        learnerAnswer: answer,
      );
      conversationHistory.add(InterviewMessageModel.assistant(question));
      conversationHistory.add(InterviewMessageModel.user(answer));
      success = true;
      debugPrint('🎤 [InterviewController] evaluated answer for ${concept.id}');
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🎤 [InterviewController] FAILED (evaluate) -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('🎤 [InterviewController] FAILED (evaluate) -> unexpected error: $e');
    } finally {
      isEvaluating = false;
      notifyListeners();
    }
    return success;
  }

  /// `POST /api/ai/interview/question` again, this time with the
  /// conversation so far, so the AI can ask a deeper follow-up. Not
  /// wired into a screen yet (the current flow goes straight to the
  /// result screen after one answer) but ready for when the "AI will
  /// ask a follow-up question" copy on [InterviewScreen] becomes real.
  Future<void> askFollowUpQuestion() async {
    final concept = _concept;
    final canonicalKnowledge = _canonicalKnowledge;
    if (concept == null || canonicalKnowledge == null) return;

    isLoadingQuestion = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentQuestion = await _repository.generateQuestion(
        concept: concept,
        canonicalKnowledge: canonicalKnowledge,
        conversationHistory: conversationHistory,
      );
    } on NetworkException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      isLoadingQuestion = false;
      notifyListeners();
    }
  }

  /// Clears the whole session (called when the learner backs out of the
  /// interview flow, e.g. from [InterviewIntroScreen]'s dispose or before
  /// starting a new concept's interview).
  void reset() {
    _concept = null;
    _canonicalKnowledge = null;
    conversationHistory.clear();
    currentQuestion = null;
    lastEvaluation = null;
    errorMessage = null;
  }
}
