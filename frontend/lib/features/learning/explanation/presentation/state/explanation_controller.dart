import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/network_exception.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/explanation_remote_datasource.dart';
import '../../data/models/canonical_knowledge_model.dart';
import '../../data/repositories/explanation_repository.dart';

/// Single source of truth for the "Understand" stage's AI canonical
/// knowledge (key points / rules / examples).
///
/// Same plain-singleton pattern as `AuthController.instance` — the app has
/// no `provider`/`riverpod` dependency, so this is a lazily-built
/// `ChangeNotifier` every screen reaches the same way:
/// `ExplanationController.instance`.
class ExplanationController extends ChangeNotifier {
  ExplanationController._(this._repository);

  static ExplanationController? _instance;

  static ExplanationController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);
    final repository = ExplanationRepository(ExplanationRemoteDatasource(apiClient));
    _instance = ExplanationController._(repository);
    return _instance!;
  }

  final ExplanationRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  CanonicalKnowledgeModel? knowledge;

  /// The conceptId [knowledge] currently belongs to, so a screen that got
  /// re-opened for a *different* concept knows to re-fetch instead of
  /// showing stale data from the previous concept.
  String? _loadedConceptId;

  /// `POST /api/ai/canonical-knowledge?conceptId=...`.
  /// Set [force] to true to re-fetch even if this conceptId is already
  /// loaded (e.g. a pull-to-refresh or "Retry" tap).
  Future<void> loadCanonicalKnowledge(String conceptId, {bool force = false}) async {
    if (!force && _loadedConceptId == conceptId && knowledge != null) {
      return; // Already have it — avoid a redundant network call.
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      knowledge = await _repository.getCanonicalKnowledge(conceptId);
      _loadedConceptId = conceptId;
      debugPrint('🧠 [ExplanationController] loaded canonical knowledge for $conceptId');
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🧠 [ExplanationController] FAILED -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('🧠 [ExplanationController] FAILED -> unexpected error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
