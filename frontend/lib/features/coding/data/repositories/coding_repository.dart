import '../datasources/coding_ai_remote_datasource.dart';
import '../models/coding_feedback_model.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../../core/models/diagnosis_model.dart';

/// CodingRepository — data layer repository.
/// Sits between the coding presentation layer and [CodingAiRemoteDatasource]
/// for the AI-backed coding-feedback call. Challenge fetching/submission
/// for the coding exercise itself is a separate concern and is wired up
/// here once that backend contract exists.
class CodingRepository {
  const CodingRepository(this._aiRemote);

  final CodingAiRemoteDatasource _aiRemote;

  /// `POST /api/ai/coding-feedback`.
  Future<CodingFeedbackModel> getCodingFeedback({
    required ConceptModel concept,
    required DiagnosisModel diagnosis,
  }) {
    return _aiRemote.getCodingFeedback(concept: concept, diagnosis: diagnosis);
  }
}
