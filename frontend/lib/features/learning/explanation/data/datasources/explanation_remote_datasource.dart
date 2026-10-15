import '../../../../../app/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../models/canonical_knowledge_model.dart';

/// Talks to `POST /api/ai/canonical-knowledge` and nothing else.
class ExplanationRemoteDatasource {
  const ExplanationRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/canonical-knowledge?conceptId={conceptId}` — no JSON
  /// body. Uses [ApiClient.postRaw] because this endpoint's response is
  /// the payload directly, not wrapped in `{success, data}`.
  Future<CanonicalKnowledgeModel> getCanonicalKnowledge(String conceptId) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiCanonicalKnowledge,
      query: {'conceptId': conceptId},
    );
    return CanonicalKnowledgeModel.fromJson(json);
  }
}
