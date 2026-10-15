import '../../../../app/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/diagnosis_model.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../models/debugging_hint_model.dart';

/// Talks to `POST /api/ai/debugging-hint` and nothing else.
class DebuggingRemoteDatasource {
  const DebuggingRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/debugging-hint`. `hintLevel` supports progressive
  /// hints: 1 -> gentle, 2 -> stronger, 3 -> almost-solution-level. JSON
  /// body, no `conceptId` query param. Uses [ApiClient.postRaw] since the
  /// response isn't wrapped in `{success, data}`.
  Future<DebuggingHintModel> getDebuggingHint({
    required ConceptModel concept,
    required DiagnosisModel diagnosis,
    required int hintLevel,
  }) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiDebuggingHint,
      body: {
        'concept': concept.toJson(),
        'diagnosis': diagnosis.toJson(),
        'hintLevel': hintLevel,
      },
    );
    return DebuggingHintModel.fromJson(json);
  }
}
