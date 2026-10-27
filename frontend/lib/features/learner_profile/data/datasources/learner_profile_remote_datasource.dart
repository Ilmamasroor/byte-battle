import '../../../../app/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/learner_profile_model.dart';

/// Talks to `/api/learner-profile` and nothing else — no caching, no
/// state. That lives one layer up in [LearnerProfileRepository], same
/// split as auth's [ApiClient] usage.
class LearnerProfileRemoteDatasource {
  const LearnerProfileRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `GET /api/learner-profile`
  Future<LearnerProfileModel> getProfile() async {
    final json = await _apiClient.get(ApiEndpoints.learnerProfile);
    return LearnerProfileModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// `POST /api/learner-profile` — creates the learner profile. Only
  /// valid once per user; call this the first time (e.g. right after
  /// onboarding), and [updateProfile] afterwards.
  Future<LearnerProfileModel> createProfile(LearnerProfileModel profile) async {
    final json = await _apiClient.post(
      ApiEndpoints.learnerProfile,
      body: profile.toJson(),
    );
    return LearnerProfileModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// `PUT /api/learner-profile` — partial update. Only the field(s) the
  /// caller actually wants to change are sent, same convention as
  /// `AuthRemoteDatasource.updateCurrentUser`.
  Future<LearnerProfileModel> updateProfile({
    ExperienceLevel? experienceLevel,
    String? preferredLanguage,
    int? dailyGoalMinutes,
  }) async {
    final json = await _apiClient.put(
      ApiEndpoints.learnerProfile,
      body: {
        if (experienceLevel != null) 'experienceLevel': experienceLevel.apiValue,
        if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
        if (dailyGoalMinutes != null) 'dailyGoalMinutes': dailyGoalMinutes,
      },
    );
    return LearnerProfileModel.fromJson(json['data'] as Map<String, dynamic>);
  }
}
