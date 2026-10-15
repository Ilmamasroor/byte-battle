import '../datasources/interview_ai_remote_datasource.dart';
import '../models/interview_message_model.dart';
import '../models/interview_question_model.dart';
import '../models/interview_result_model.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../learning/explanation/data/models/canonical_knowledge_model.dart';

/// InterviewRepository — data layer repository.
/// Sits between the interview presentation layer and
/// [InterviewAiRemoteDatasource] for the two AI-backed calls
/// (interview/question, interview/evaluate).
class InterviewRepository {
  const InterviewRepository(this._aiRemote);

  final InterviewAiRemoteDatasource _aiRemote;

  /// `POST /api/ai/interview/question`.
  Future<InterviewQuestionModel> generateQuestion({
    required ConceptModel concept,
    required CanonicalKnowledgeModel canonicalKnowledge,
    List<InterviewMessageModel> conversationHistory = const [],
  }) {
    return _aiRemote.generateQuestion(
      concept: concept,
      canonicalKnowledge: canonicalKnowledge,
      conversationHistory: conversationHistory,
    );
  }

  /// `POST /api/ai/interview/evaluate`.
  Future<InterviewEvaluationModel> evaluateAnswer({
    required ConceptModel concept,
    required CanonicalKnowledgeModel canonicalKnowledge,
    required String question,
    required String learnerAnswer,
  }) {
    return _aiRemote.evaluateAnswer(
      concept: concept,
      canonicalKnowledge: canonicalKnowledge,
      question: question,
      learnerAnswer: learnerAnswer,
    );
  }
}
