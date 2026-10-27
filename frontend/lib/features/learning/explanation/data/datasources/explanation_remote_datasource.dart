import '../../../../../app/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../models/canonical_knowledge_model.dart';

/// Talks to `POST /api/ai/canonical-knowledge` and nothing else.
class ExplanationRemoteDatasource {
  const ExplanationRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/canonical-knowledge?conceptId={conceptId}` — no JSON
  /// body. Uses [ApiClient.postJson] because this endpoint's response is
  /// the payload directly, not wrapped in `{success, data}`.
  Future<CanonicalKnowledgeModel> getCanonicalKnowledge(String conceptId) async {
    final json = await _apiClient.postJson(
      ApiEndpoints.aiCanonicalKnowledge,
      query: {'conceptId': conceptId},
      timeout: ApiClient.slowTimeout,
    );
    return CanonicalKnowledgeModel.fromJson(Map<String, dynamic>.from(json as Map));
  }
}
