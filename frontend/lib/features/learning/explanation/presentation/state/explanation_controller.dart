import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/network_exception.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/explanation_remote_datasource.dart';
import '../../data/models/canonical_knowledge_model.dart';
import '../../data/models/explanation_model.dart';
import '../../data/repositories/explanation_repository.dart';

/// State for the "Understand" stage: the personalized AI explanation (`/api/ai/explanation`) and the canonical
/// key points / rules / examples (`/api/ai/canonical-knowledge`). The two load independently, so one failing
/// still leaves the other usable.
///
/// Plain-singleton pattern like `AuthController.instance` (the app has no provider/riverpod dependency).
class ExplanationController extends ChangeNotifier {
  ExplanationController._(this._repository);

  /// For tests: a controller on a fake repository.
  @visibleForTesting
  ExplanationController.forTest(this._repository);

  static ExplanationController? _instance;

  static ExplanationController get instance {
    if (_instance != null) return _instance!;
    final apiClient = ApiClient(secureStorage: SecureStorageService());
    _instance = ExplanationController._(ExplanationRepository(ExplanationRemoteDatasource(apiClient)));
    return _instance!;
  }

  final ExplanationRepository _repository;

  bool isLoading = false;
  CanonicalKnowledgeModel? knowledge;
  ExplanationModel? explanation;
  String? knowledgeError;
  String? explanationError;

  /// Both calls failed: nothing to show but an error.
  bool get failedCompletely => knowledge == null && explanation == null && (knowledgeError ?? explanationError) != null;

  String? get errorMessage => knowledgeError ?? explanationError;

  /// The conceptId the loaded data belongs to, so a screen re-opened for a *different* concept re-fetches
  /// instead of showing the previous concept's content.
  String? _loadedConceptId;

  /// [force] re-fetches even when this concept is already loaded (Retry / "Ask for Clarification").
  Future<void> load(String conceptId, {bool force = false}) async {
    if (!force && _loadedConceptId == conceptId && (knowledge != null || explanation != null)) return;
    if (_loadedConceptId != conceptId) {
      knowledge = null;
      explanation = null;
    }
    _loadedConceptId = conceptId;
    isLoading = true;
    knowledgeError = null;
    explanationError = null;
    notifyListeners();

    await Future.wait([
      _run(() async => knowledge = await _repository.getCanonicalKnowledge(conceptId), (m) => knowledgeError = m),
      _run(() async => explanation = await _repository.getExplanation(conceptId), (m) => explanationError = m),
    ]);

    // A stale answer for a concept the learner already left must not clobber the current one.
    if (_loadedConceptId != conceptId) return;
    isLoading = false;
    notifyListeners();
  }

  /// Loads only the key points / rules / examples (other features, e.g. battle hints, just need these). Skips
  /// the fetch when this concept's knowledge is already loaded unless [force].
  Future<void> loadCanonicalKnowledge(String conceptId, {bool force = false}) async {
    if (!force && _loadedConceptId == conceptId && knowledge != null) return;
    if (_loadedConceptId != conceptId) {
      knowledge = null;
      explanation = null;
    }
    _loadedConceptId = conceptId;
    knowledgeError = null;
    await _run(() async => knowledge = await _repository.getCanonicalKnowledge(conceptId), (m) => knowledgeError = m);
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() call, void Function(String) onError) async {
    try {
      await call();
    } on NetworkException catch (e) {
      onError(e.message);
    } catch (e) {
      debugPrint('[ExplanationController] unexpected error: $e');
      onError('Something went wrong. Please try again.');
    }
  }
}
