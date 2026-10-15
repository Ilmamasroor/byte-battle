import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/models/diagnosis_model.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../data/datasources/debugging_remote_datasource.dart';
import '../../data/models/debugging_hint_model.dart';
import '../../data/repositories/debugging_repository.dart';

/// Single source of truth for the AI-generated hint shown while the
/// learner is solving a debugging challenge. Same plain-singleton pattern
/// as `AuthController.instance` / `MnemonicController.instance`.
class DebuggingHintController extends ChangeNotifier {
  DebuggingHintController._(this._repository);

  static DebuggingHintController? _instance;

  static DebuggingHintController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);
    final repository = DebuggingRepository(DebuggingRemoteDatasource(apiClient));
    _instance = DebuggingHintController._(repository);
    return _instance!;
  }

  final DebuggingRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  DebuggingHintModel? hint;

  /// Tracks the progressive hint level (1 -> gentle, 2 -> stronger,
  /// 3 -> almost-solution-level) so repeated taps on "Need a hint?"
  /// escalate instead of repeating the same hint.
  int _hintLevel = 0;

  /// `POST /api/ai/debugging-hint`. Bumps the hint level each call, up to
  /// a max of 3, unless [reset] is passed for a new challenge.
  Future<void> loadNextHint({
    required ConceptModel concept,
    required DiagnosisModel diagnosis,
    bool reset = false,
  }) async {
    if (reset) _hintLevel = 0;
    _hintLevel = _hintLevel >= 3 ? 3 : _hintLevel + 1;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      hint = await _repository.getDebuggingHint(
        concept: concept,
        diagnosis: diagnosis,
        hintLevel: _hintLevel,
      );
      debugPrint('🐞 [DebuggingHintController] loaded hint (level $_hintLevel) for ${concept.id}');
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🐞 [DebuggingHintController] FAILED -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('🐞 [DebuggingHintController] FAILED -> unexpected error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
