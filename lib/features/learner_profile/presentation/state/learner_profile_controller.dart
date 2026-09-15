import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../../data/datasources/learner_profile_remote_datasource.dart';
import '../../data/models/learner_profile_model.dart';
import '../../data/repositories/learner_profile_repository.dart';

/// LearnerProfileController — presentation-layer state holder for the
/// `/api/learner-profile` endpoints (GET/POST/PUT).
///
/// Same plain-singleton shape as [AuthController] (project has no
/// provider/riverpod dependency yet): every screen reaches it via
/// `LearnerProfileController.instance` and rebuilds via
/// `ListenableBuilder` or by calling the async methods directly.
class LearnerProfileController extends ChangeNotifier {
  LearnerProfileController._(this._repository);

  static LearnerProfileController? _instance;

  static LearnerProfileController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(
      secureStorage: secureStorage,
      // A 401/403 here means the same expired/invalid token as
      // everywhere else in the app — fall back to the shared
      // logged-out state instead of just failing this one screen.
      onUnauthorized: () => AuthController.instance.logout(),
    );
    final repository = LearnerProfileRepository(
      LearnerProfileRemoteDatasource(apiClient),
    );
    _instance = LearnerProfileController._(repository);
    return _instance!;
  }

  final LearnerProfileRepository _repository;

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;
  LearnerProfileModel? profile;

  /// True once a `GET` has come back 404 — the learner hasn't created a
  /// profile yet, so the screen should show the "create" form (`POST`)
  /// instead of an "edit" form (`PUT`).
  bool profileMissing = false;

  /// `GET /api/learner-profile`
  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await _repository.getProfile();
      profileMissing = false;
      debugPrint('👤 [LearnerProfileController.load] SUCCESS -> ${profile?.toJson()}');
    } on NetworkException catch (e) {
      if (e.statusCode == 404) {
        // Not an error state — just means "nothing saved yet".
        profileMissing = true;
        profile = null;
        debugPrint('👤 [LearnerProfileController.load] 404 -> profileMissing = true');
      } else {
        errorMessage = e.message;
        debugPrint('👤 [LearnerProfileController.load] FAILED -> ${e.message} (status: ${e.statusCode})');
      }
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('👤 [LearnerProfileController.load] FAILED -> unexpected error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// `POST /api/learner-profile` — first-time creation.
  Future<bool> create({
    required ExperienceLevel experienceLevel,
    required String preferredLanguage,
    required int dailyGoalMinutes,
  }) {
    return _save(() => _repository.createProfile(
          experienceLevel: experienceLevel,
          preferredLanguage: preferredLanguage,
          dailyGoalMinutes: dailyGoalMinutes,
        ));
  }

  /// `PUT /api/learner-profile` — partial update; pass only the field(s)
  /// that actually changed, the rest stay as-is on the backend.
  Future<bool> update({
    ExperienceLevel? experienceLevel,
    String? preferredLanguage,
    int? dailyGoalMinutes,
  }) {
    return _save(() => _repository.updateProfile(
          experienceLevel: experienceLevel,
          preferredLanguage: preferredLanguage,
          dailyGoalMinutes: dailyGoalMinutes,
        ));
  }

  Future<bool> _save(Future<LearnerProfileModel> Function() action) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await action();
      profileMissing = false;
      debugPrint('👤 [LearnerProfileController._save] SUCCESS -> ${profile?.toJson()}');
      isSaving = false;
      notifyListeners();
      return true;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('👤 [LearnerProfileController._save] FAILED -> ${e.message} (status: ${e.statusCode})');
      isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('👤 [LearnerProfileController._save] FAILED -> unexpected error: $e');
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
