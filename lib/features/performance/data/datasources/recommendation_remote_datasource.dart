import '../../../../app/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/recommendation_model.dart';

/// Talks to `POST /api/ai/recommend` and nothing else.
class RecommendationRemoteDatasource {
  const RecommendationRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/recommend` — JSON body, no query params. Uses
  /// [ApiClient.postRaw] since the response isn't wrapped in
  /// `{success, data}`.
  Future<RecommendationAiResponse> getRecommendation(RecommendationAiRequest request) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiRecommend,
      body: request.toJson(),
    );
    return RecommendationAiResponse.fromJson(json);
  }
}
