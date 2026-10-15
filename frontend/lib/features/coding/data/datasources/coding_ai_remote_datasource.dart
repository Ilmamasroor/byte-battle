import '../../../../app/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/diagnosis_model.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../models/coding_feedback_model.dart';

/// Talks to `POST /api/ai/coding-feedback` and nothing else.
class CodingAiRemoteDatasource {
  const CodingAiRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/coding-feedback`. Called after the backend has already
  /// diagnosed the learner's submission (see [DiagnosisModel]) — this
  /// just turns that diagnosis into learner-facing feedback text. JSON
  /// body, no `conceptId` query param. Uses [ApiClient.postRaw] since the
  /// response isn't wrapped in `{success, data}`.
  Future<CodingFeedbackModel> getCodingFeedback({
    required ConceptModel concept,
    required DiagnosisModel diagnosis,
  }) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiCodingFeedback,
      body: {'concept': concept.toJson(), 'diagnosis': diagnosis.toJson()},
    );
    return CodingFeedbackModel.fromJson(json);
  }
}
