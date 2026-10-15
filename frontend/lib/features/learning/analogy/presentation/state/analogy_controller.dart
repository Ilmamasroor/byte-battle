import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/network_exception.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/analogy_remote_datasource.dart';
import '../../data/models/analogy_model.dart';
import '../../data/repositories/analogy_repository.dart';

/// Single source of truth for the "Relate" stage's AI-generated analogy.
/// Same plain-singleton pattern as `AuthController.instance`.
class AnalogyController extends ChangeNotifier {
  AnalogyController._(this._repository);

  static AnalogyController? _instance;

  static AnalogyController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);
    final repository = AnalogyRepository(AnalogyRemoteDatasource(apiClient));
    _instance = AnalogyController._(repository);
    return _instance!;
  }

  final AnalogyRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  AnalogyModel? analogy;

  String? _loadedConceptId;

  /// `POST /api/ai/analogy?conceptId=...`. Set [force] to true to
  /// re-fetch even if this conceptId is already loaded (e.g. a
  /// "Regenerate" tap).
  Future<void> loadAnalogy(String conceptId, {bool force = false}) async {
    if (!force && _loadedConceptId == conceptId && analogy != null) {
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      analogy = await _repository.getAnalogy(conceptId);
      _loadedConceptId = conceptId;
      debugPrint('🔗 [AnalogyController] loaded analogy for $conceptId');
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🔗 [AnalogyController] FAILED -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('🔗 [AnalogyController] FAILED -> unexpected error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
