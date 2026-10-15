import '../../../../app/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/performance_model.dart';

/// Talks to `POST /api/ai/diagnose` and nothing else.
class DiagnosisRemoteDatasource {
  const DiagnosisRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/diagnose` — JSON body, no query params. Uses
  /// [ApiClient.postRaw] since the response isn't wrapped in
  /// `{success, data}`.
  Future<DiagnosisResultModel> diagnoseActivity(DiagnosisActivityModel activity) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiDiagnose,
      body: activity.toJson(),
    );
    return DiagnosisResultModel.fromJson(json);
  }
}
