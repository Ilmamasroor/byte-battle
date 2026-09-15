import '../../../../app/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../learning/explanation/data/models/canonical_knowledge_model.dart';
import '../models/interview_message_model.dart';
import '../models/interview_question_model.dart';
import '../models/interview_result_model.dart';

/// Talks to `POST /api/ai/interview/question` and
/// `POST /api/ai/interview/evaluate` — the two AI calls that belong to
/// the Mock Interview experience.
class InterviewAiRemoteDatasource {
  const InterviewAiRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/interview/question`. Same JSON-body shape as the
  /// battle/coding/debugging AI endpoints (no `conceptId` query param).
  /// [conversationHistory] is the running back-and-forth so far — pass an
  /// empty list to get the opening question. Uses [ApiClient.postRaw]
  /// because the response isn't wrapped in `{success, data}`.
  Future<InterviewQuestionModel> generateQuestion({
    required ConceptModel concept,
    required CanonicalKnowledgeModel canonicalKnowledge,
    List<InterviewMessageModel> conversationHistory = const [],
  }) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiInterviewQuestion,
      body: {
        'concept': concept.toJson(),
        'canonicalKnowledge': canonicalKnowledge.toJson(),
        'conversationHistory':
            conversationHistory.map((m) => m.toJson()).toList(),
      },
    );
    return InterviewQuestionModel.fromJson(json);
  }

  /// `POST /api/ai/interview/evaluate`. Same JSON-body/`postRaw` shape as
  /// [generateQuestion].
  Future<InterviewEvaluationModel> evaluateAnswer({
    required ConceptModel concept,
    required CanonicalKnowledgeModel canonicalKnowledge,
    required String question,
    required String learnerAnswer,
  }) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiInterviewEvaluate,
      body: {
        'concept': concept.toJson(),
        'canonicalKnowledge': canonicalKnowledge.toJson(),
        'question': question,
        'learnerAnswer': learnerAnswer,
      },
    );
    return InterviewEvaluationModel.fromJson(json);
  }
}
