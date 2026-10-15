import '../../../../app/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/performance_model.dart';

/// Talks to `POST /api/ai/diagnose/summary` and nothing else.
class DiagnosisSummaryRemoteDatasource {
  const DiagnosisSummaryRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/diagnose/summary` — JSON body, no query params. Uses
  /// [ApiClient.postRaw] since the response isn't wrapped in
  /// `{success, data}`.
  Future<DiagnosisSummaryResultModel> summarizeActivities(DiagnosisSummaryRequest request) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiDiagnoseSummary,
      body: request.toJson(),
    );
    return DiagnosisSummaryResultModel.fromJson(json);
  }
}
