import '../datasources/learner_profile_remote_datasource.dart';
import '../models/learner_profile_model.dart';

/// Sits between [LearnerProfileController] and
/// [LearnerProfileRemoteDatasource]. No local caching today (unlike
/// [AuthRepository], there's no offline-first requirement here) — every
/// call goes straight to the network.
class LearnerProfileRepository {
  const LearnerProfileRepository(this._remote);

  final LearnerProfileRemoteDatasource _remote;

  /// `GET /api/learner-profile`
  Future<LearnerProfileModel> getProfile() => _remote.getProfile();

  /// `POST /api/learner-profile` — first-time creation.
  Future<LearnerProfileModel> createProfile({
    required ExperienceLevel experienceLevel,
    required String preferredLanguage,
    required int dailyGoalMinutes,
  }) {
    return _remote.createProfile(
      LearnerProfileModel(
        experienceLevel: experienceLevel,
        preferredLanguage: preferredLanguage,
        dailyGoalMinutes: dailyGoalMinutes,
      ),
    );
  }

  /// `PUT /api/learner-profile` — partial update; pass only what changed.
  Future<LearnerProfileModel> updateProfile({
    ExperienceLevel? experienceLevel,
    String? preferredLanguage,
    int? dailyGoalMinutes,
  }) {
    return _remote.updateProfile(
      experienceLevel: experienceLevel,
      preferredLanguage: preferredLanguage,
      dailyGoalMinutes: dailyGoalMinutes,
    );
  }
}
