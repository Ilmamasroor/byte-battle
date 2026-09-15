import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/network_exception.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/mnemonic_remote_datasource.dart';
import '../../data/models/mnemonic_model.dart';
import '../../data/repositories/mnemonic_repository.dart';

/// Single source of truth for the "Remember" stage's AI-generated
/// mnemonic. Same plain-singleton pattern as `AuthController.instance`.
class MnemonicController extends ChangeNotifier {
  MnemonicController._(this._repository);

  static MnemonicController? _instance;

  static MnemonicController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);
    final repository = MnemonicRepository(MnemonicRemoteDatasource(apiClient));
    _instance = MnemonicController._(repository);
    return _instance!;
  }

  final MnemonicRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  MnemonicModel? mnemonic;

  String? _loadedConceptId;

  /// `POST /api/ai/mnemonic?conceptId=...`. Set [force] to true to
  /// re-fetch even if this conceptId is already loaded.
  Future<void> loadMnemonic(String conceptId, {bool force = false}) async {
    if (!force && _loadedConceptId == conceptId && mnemonic != null) {
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      mnemonic = await _repository.getMnemonic(conceptId);
      _loadedConceptId = conceptId;
      debugPrint('🎵 [MnemonicController] loaded mnemonic for $conceptId');
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🎵 [MnemonicController] FAILED -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('🎵 [MnemonicController] FAILED -> unexpected error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
