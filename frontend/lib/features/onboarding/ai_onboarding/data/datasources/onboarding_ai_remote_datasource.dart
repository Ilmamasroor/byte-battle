import '../../../../../app/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../models/onboarding_ai_model.dart';

/// Talks to `POST /api/ai/onboarding` and nothing else.
class OnboardingAiRemoteDatasource {
  const OnboardingAiRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/onboarding` — JSON body, no query params. Uses
  /// [ApiClient.postRaw] since the response isn't wrapped in
  /// `{success, data}`.
  Future<OnboardingAiResponse> submitOnboarding(OnboardingAiRequest request) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiOnboarding,
      body: request.toJson(),
    );
    return OnboardingAiResponse.fromJson(json);
  }
}
