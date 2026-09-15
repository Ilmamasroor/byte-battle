import '../datasources/onboarding_ai_remote_datasource.dart';
import '../models/onboarding_ai_model.dart';

/// Sits between [OnboardingAiController] and [OnboardingAiRemoteDatasource].
class OnboardingAiRepository {
  const OnboardingAiRepository(this._remote);

  final OnboardingAiRemoteDatasource _remote;

  Future<OnboardingAiResponse> submitOnboarding(OnboardingAiRequest request) {
    return _remote.submitOnboarding(request);
  }
}
