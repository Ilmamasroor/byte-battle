import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../../data/datasources/diagnosis_remote_datasource.dart';
import '../../data/models/performance_model.dart';
import '../../data/repositories/diagnosis_repository.dart';

/// Single source of truth for the AI activity diagnosis call
/// (`POST /api/ai/diagnose`), run after the learner finishes a coding/
/// concept/interview activity. Same plain-singleton pattern as
/// `AuthController.instance` / `MnemonicController.instance`.
class DiagnosisController extends ChangeNotifier {
  DiagnosisController._(this._repository);

  static DiagnosisController? _instance;

  static DiagnosisController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);
    final repository = DiagnosisRepository(DiagnosisRemoteDatasource(apiClient));
    _instance = DiagnosisController._(repository);
    return _instance!;
  }

  final DiagnosisRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  DiagnosisResultModel? diagnosis;

  /// `POST /api/ai/diagnose`. `userId` is never passed in by the
  /// caller — it's pulled from `AuthController.instance.currentUser`,
  /// same as every other authenticated call in the app. Set [force] to
  /// true to re-submit even if a diagnosis has already been loaded.
  Future<void> diagnoseActivity({
    required String activityType,
    required double accuracy,
    required int score,
    required int attemptCount,
    required int timeSpentSeconds,
    required int hintsUsed,
    required int testCasesPassed,
    required int testCasesTotal,
    required bool success,
    bool force = false,
  }) async {
    if (!force && diagnosis != null) {
      return;
    }

    final userId = AuthController.instance.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      errorMessage = 'You need to be logged in to see your diagnosis.';
      debugPrint('🩺 [DiagnosisController] FAILED -> no authenticated userId');
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      diagnosis = await _repository.diagnoseActivity(
        DiagnosisActivityModel(
          userId: userId,
          activityType: activityType,
          accuracy: accuracy,
          score: score,
          attemptCount: attemptCount,
          timeSpentSeconds: timeSpentSeconds,
          hintsUsed: hintsUsed,
          testCasesPassed: testCasesPassed,
          testCasesTotal: testCasesTotal,
          success: success,
        ),
      );
      debugPrint('🩺 [DiagnosisController] loaded diagnosis for $userId ($activityType)');
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🩺 [DiagnosisController] FAILED -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('🩺 [DiagnosisController] FAILED -> unexpected error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
