import 'package:flutter/foundation.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../../../learner_profile/data/models/learner_profile_model.dart';
import '../../../learner_profile/presentation/state/learner_profile_controller.dart';

/// DashboardController — thin orchestrator for whatever real data the
/// dashboard has to show.
///
/// The dashboard mockup has sections for XP/level, streak, a skill radar,
/// and recommended battles — none of those have a backend endpoint
/// anywhere in this codebase yet (they'd need something like
/// `/api/ai/diagnose/summary` or `/api/ai/recommend`, which aren't wired
/// up — see [DashboardScreen] for exactly which widgets are still
/// hardcoded placeholders pending those).
///
/// What IS real and already wired elsewhere in the app:
///  - the logged-in user, via [AuthController.currentUser] (populated at
///    login/bootstrap, no extra network call needed here).
///  - the learner profile, via `GET /api/learner-profile`
///    ([LearnerProfileController]).
/// This controller doesn't duplicate that networking — it just exposes
/// both through one place the dashboard screen can await/read.
class DashboardController extends ChangeNotifier {
  static DashboardController? _instance;

  /// Same plain-singleton shape as every other feature controller in the
  /// app (`AuthController.instance`, `LearnerProfileController.instance`,
  /// ...) — no `provider`/`riverpod` dependency.
  static DashboardController get instance => _instance ??= DashboardController._();

  DashboardController._();

  bool isLoading = false;
  String? errorMessage;

  UserModel? get user => AuthController.instance.currentUser;
  LearnerProfileModel? get learnerProfile => LearnerProfileController.instance.profile;
  bool get learnerProfileMissing => LearnerProfileController.instance.profileMissing;

  /// `GET /api/learner-profile`. Call once, from [DashboardScreen]'s
  /// `initState`.
  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await LearnerProfileController.instance.load();
    errorMessage = LearnerProfileController.instance.errorMessage;
    debugPrint('🏠 [DashboardController.load] user: ${user?.username}, '
        'learnerProfile: ${learnerProfile?.toJson() ?? (learnerProfileMissing ? "missing (404)" : "null")}');

    isLoading = false;
    notifyListeners();
  }
}
