import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/network_exception.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../../../auth/presentation/state/auth_controller.dart';
import '../../../../learner_profile/data/models/learner_profile_model.dart';
import '../../data/datasources/onboarding_ai_remote_datasource.dart';
import '../../data/models/onboarding_ai_model.dart';
import '../../data/repositories/onboarding_ai_repository.dart';

/// Single source of truth for the AI-personalized onboarding call
/// (`POST /api/ai/onboarding`) that seeds a brand-new user's ByteDNA.
/// Same plain-singleton pattern as `AuthController.instance` /
/// `MnemonicController.instance`.
class OnboardingAiController extends ChangeNotifier {
  OnboardingAiController._(this._repository);

  static OnboardingAiController? _instance;

  static OnboardingAiController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);
    final repository = OnboardingAiRepository(OnboardingAiRemoteDatasource(apiClient));
    _instance = OnboardingAiController._(repository);
    return _instance!;
  }

  final OnboardingAiRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  OnboardingAiResponse? response;

  /// `POST /api/ai/onboarding`. `userId` is NOT passed in by the
  /// caller — pulled here from `AuthController.instance.currentUser`
  /// (populated right after register/login) and sent explicitly in the
  /// body. The backend's FastAPI personalization service 422s with
  /// `"userId ... Input should be a valid string"` when it's left out —
  /// it doesn't reliably inject it server-side from the JWT the way the
  /// original design assumed. Set [force] to true to re-submit even if
  /// a response has already been loaded.
  Future<void> submitOnboarding({
    required ExperienceLevel technicalExperience,
    required String preferredLanguage,
    required String careerGoal,
    required String learningStyle,
    required String explanationStyle,
    required List<String> interests,
    bool force = false,
  }) async {
    if (!force && response != null) {
      return;
    }

    final userId = AuthController.instance.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('🧬 [OnboardingAiController] FAILED -> no logged-in userId available');
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      response = await _repository.submitOnboarding(
        OnboardingAiRequest(
          userId: userId,
          technicalExperience: technicalExperience,
          preferredLanguage: preferredLanguage,
          careerGoal: careerGoal,
          learningStyle: learningStyle,
          explanationStyle: explanationStyle,
          interests: interests,
        ),
      );
      debugPrint('🧬 [OnboardingAiController] loaded onboarding ByteDNA');
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🧬 [OnboardingAiController] FAILED -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('🧬 [OnboardingAiController] FAILED -> unexpected error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
