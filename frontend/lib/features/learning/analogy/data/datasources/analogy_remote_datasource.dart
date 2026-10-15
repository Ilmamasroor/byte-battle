import '../../../../../app/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../models/analogy_model.dart';

/// Talks to `POST /api/ai/analogy` and nothing else.
class AnalogyRemoteDatasource {
  const AnalogyRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/analogy?conceptId={conceptId}` — no JSON body needed;
  /// the backend loads the concept, canonical knowledge and the user's
  /// Byte DNA itself. Uses [ApiClient.postRaw] since the response isn't
  /// wrapped in `{success, data}`.
  Future<AnalogyModel> getAnalogy(String conceptId) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiAnalogy,
      query: {'conceptId': conceptId},
    );
    return AnalogyModel.fromJson(json);
  }
}
