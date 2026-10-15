import '../datasources/explanation_remote_datasource.dart';
import '../models/canonical_knowledge_model.dart';

/// Sits between [ExplanationController] and [ExplanationRemoteDatasource].
/// Currently a thin pass-through — kept as its own layer so caching or
/// local persistence can be added later without touching the controller.
class ExplanationRepository {
  const ExplanationRepository(this._remote);

  final ExplanationRemoteDatasource _remote;

  Future<CanonicalKnowledgeModel> getCanonicalKnowledge(String conceptId) {
    return _remote.getCanonicalKnowledge(conceptId);
  }
}
