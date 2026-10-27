import '../../../../../app/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../models/analogy_model.dart';

/// Talks to `POST /api/ai/analogy` and nothing else.
class AnalogyRemoteDatasource {
  const AnalogyRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/analogy?conceptId={conceptId}` — no JSON body needed;
  /// the backend loads the concept, canonical knowledge and the user's
  /// Byte DNA itself. Uses [ApiClient.postJson] since the response isn't
  /// wrapped in `{success, data}`.
  Future<AnalogyModel> getAnalogy(String conceptId, {String? lens}) async {
    final json = await _apiClient.postJson(
      ApiEndpoints.aiAnalogy,
      query: {'conceptId': conceptId, if (lens != null) 'lens': lens},
      timeout: ApiClient.slowTimeout,
    );
    return AnalogyModel.fromJson(Map<String, dynamic>.from(json as Map));
  }
}
