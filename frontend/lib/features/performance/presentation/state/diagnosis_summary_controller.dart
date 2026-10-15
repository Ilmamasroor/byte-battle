import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../../data/datasources/diagnosis_summary_remote_datasource.dart';
import '../../data/models/performance_model.dart';
import '../../data/repositories/diagnosis_summary_repository.dart';

/// Single source of truth for the aggregate AI diagnosis call
/// (`POST /api/ai/diagnose/summary`), run over a batch of the learner's
/// past activities (e.g. to refresh their overall ByteDNA scores). Same
/// plain-singleton pattern as `AuthController.instance` /
/// `MnemonicController.instance`.
class DiagnosisSummaryController extends ChangeNotifier {
  DiagnosisSummaryController._(this._repository);

  static DiagnosisSummaryController? _instance;

  static DiagnosisSummaryController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);
    final repository = DiagnosisSummaryRepository(DiagnosisSummaryRemoteDatasource(apiClient));
    _instance = DiagnosisSummaryController._(repository);
    return _instance!;
  }

  final DiagnosisSummaryRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  DiagnosisSummaryResultModel? summary;

  /// `POST /api/ai/diagnose/summary`. `userId` is never passed in by the
  /// caller (nor is it re-injected per activity here — the caller
  /// supplies whichever [DiagnosisActivityModel]s it already has, e.g.
  /// from prior [DiagnosisController] calls) — it's pulled from
  /// `AuthController.instance.currentUser`, same as every other
  /// authenticated call in the app. Set [force] to true to re-submit
  /// even if a summary has already been loaded.
  Future<void> summarizeActivities({
    required List<DiagnosisActivityModel> activities,
    bool force = false,
  }) async {
    if (!force && summary != null) {
      return;
    }

    final userId = AuthController.instance.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      errorMessage = 'You need to be logged in to see your progress summary.';
      debugPrint('📊 [DiagnosisSummaryController] FAILED -> no authenticated userId');
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      summary = await _repository.summarizeActivities(
        DiagnosisSummaryRequest(userId: userId, activities: activities),
      );
      debugPrint('📊 [DiagnosisSummaryController] loaded summary for $userId (${activities.length} activities)');
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('📊 [DiagnosisSummaryController] FAILED -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('📊 [DiagnosisSummaryController] FAILED -> unexpected error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
