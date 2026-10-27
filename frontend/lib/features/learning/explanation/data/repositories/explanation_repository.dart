import '../datasources/explanation_remote_datasource.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/backend_api.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../models/canonical_knowledge_model.dart';
import '../models/explanation_model.dart';

/// Sits between [ExplanationController] and [ExplanationRemoteDatasource].
/// Currently a thin pass-through — kept as its own layer so caching or
/// local persistence can be added later without touching the controller.
class ExplanationRepository {
  const ExplanationRepository(this._remote);

  /// The repository wired to the real backend.
  factory ExplanationRepository.live() => ExplanationRepository(ExplanationRemoteDatasource(ApiClient(secureStorage: SecureStorageService())));

  final ExplanationRemoteDatasource _remote;

  Future<CanonicalKnowledgeModel> getCanonicalKnowledge(String conceptId) {
    return _remote.getCanonicalKnowledge(conceptId);
  }

  Future<ExplanationModel> getExplanation(String conceptId) async => ExplanationModel.fromJson(await BackendApi.instance.aiExplanation(conceptId));
}
