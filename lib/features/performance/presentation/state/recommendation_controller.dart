import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../../../learner_profile/data/models/learner_profile_model.dart';
import '../../data/datasources/recommendation_remote_datasource.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/repositories/recommendation_repository.dart';

/// Single source of truth for the AI "what should I practice next" call
/// (`POST /api/ai/recommend`), typically run right after a
/// [DiagnosisController] or [DiagnosisSummaryController] result comes
/// back. Same plain-singleton pattern as `AuthController.instance` /
/// `MnemonicController.instance`.
class RecommendationController extends ChangeNotifier {
  RecommendationController._(this._repository);

  static RecommendationController? _instance;

  static RecommendationController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);
    final repository = RecommendationRepository(RecommendationRemoteDatasource(apiClient));
    _instance = RecommendationController._(repository);
    return _instance!;
  }

  final RecommendationRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  RecommendationAiResponse? recommendation;

  /// `POST /api/ai/recommend`. `userId` is never passed in by the
  /// caller — it's pulled from `AuthController.instance.currentUser`,
  /// same as every other authenticated call in the app. Set [force] to
  /// true to re-fetch even if a recommendation has already been loaded.
  Future<void> getRecommendation({
    required ExperienceLevel technicalExperience,
    required String topic,
    required List<String> repeatedMistakes,
    required double conceptUnderstanding,
    required double decisionMaking,
    required double boundaryConditions,
    required double codingImplementation,
    required double hintDependency,
    bool force = false,
  }) async {
    if (!force && recommendation != null) {
      return;
    }

    final userId = AuthController.instance.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      errorMessage = 'You need to be logged in to get a recommendation.';
      debugPrint('🎯 [RecommendationController] FAILED -> no authenticated userId');
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      recommendation = await _repository.getRecommendation(
        RecommendationAiRequest(
          userId: userId,
          technicalExperience: technicalExperience,
          topic: topic,
          repeatedMistakes: repeatedMistakes,
          conceptUnderstanding: conceptUnderstanding,
          decisionMaking: decisionMaking,
          boundaryConditions: boundaryConditions,
          codingImplementation: codingImplementation,
          hintDependency: hintDependency,
        ),
      );
      debugPrint('🎯 [RecommendationController] loaded recommendation for $userId ($topic)');
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🎯 [RecommendationController] FAILED -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('🎯 [RecommendationController] FAILED -> unexpected error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
