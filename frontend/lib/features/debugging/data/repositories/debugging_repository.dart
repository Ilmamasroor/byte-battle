import '../datasources/debugging_remote_datasource.dart';
import '../models/debugging_hint_model.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../../core/models/diagnosis_model.dart';

/// DebuggingRepository — data layer repository.
/// Sits between [DebuggingHintController] and [DebuggingRemoteDatasource].
class DebuggingRepository {
  const DebuggingRepository(this._remote);

  final DebuggingRemoteDatasource _remote;

  /// `POST /api/ai/debugging-hint`.
  Future<DebuggingHintModel> getDebuggingHint({
    required ConceptModel concept,
    required DiagnosisModel diagnosis,
    required int hintLevel,
  }) {
    return _remote.getDebuggingHint(
      concept: concept,
      diagnosis: diagnosis,
      hintLevel: hintLevel,
    );
  }
}
