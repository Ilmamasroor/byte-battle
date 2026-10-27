import 'package:flutter/foundation.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/network/backend_api.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../../../learner_profile/data/models/learner_profile_model.dart';
import '../../../learner_profile/presentation/state/learner_profile_controller.dart';

/// Everything the dashboard shows, all of it real:
///  - the logged-in user and learner profile (existing controllers)
///  - XP, level and streak from `GET /api/gamification/me` (awarded by the backend from verified results only)
///  - the four Byte DNA skill bars, derived from the learner's stored performance records
///    (battle = Understanding, coding = Application, debugging = Debugging, interview = Communication);
///    `null` means "no evidence yet", never a made-up number
///  - the flagship concept and the learner's stage in it (`/api/concepts`, `/api/learning`)
///  - the latest recommended next action (`/api/recommendations/all`)
class DashboardController extends ChangeNotifier {
  static DashboardController? _instance;

  static DashboardController get instance => _instance ??= DashboardController._();

  DashboardController._();

  final BackendApi _api = BackendApi.instance;

  bool isLoading = false;
  String? errorMessage;

  GamificationStats stats = const GamificationStats(0, 1, 0);
  Map<String, double?> skills = {
    'Understanding': null,
    'Application': null,
    'Debugging': null,
    'Communication': null,
  };
  ConceptInfo? concept;
  LearningProgressModel? progress;
  RecommendationModel? nextMove;
  List<BattleInfo> battles = const [];

  UserModel? get user => AuthController.instance.currentUser;
  LearnerProfileModel? get learnerProfile => LearnerProfileController.instance.profile;
  bool get learnerProfileMissing => LearnerProfileController.instance.profileMissing;

  /// XP needed for the next level (the backend levels up every 100 XP).
  int get xpTarget => stats.level * 100;

  /// 0..1 progress through the flagship concept's stages.
  double get conceptProgress => ((progress?.progressPercentage ?? 0) / 100).clamp(0.0, 1.0);

  static const _activityToSkill = {
    'BATTLE': 'Understanding',
    'CODING': 'Application',
    'DEBUGGING': 'Debugging',
    'INTERVIEW': 'Communication',
  };

  /// Pure function (unit-tested): average accuracy per skill from raw performance records.
  static Map<String, double?> skillsFromRecords(List<Map<String, dynamic>> records) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final r in records) {
      final skill = _activityToSkill[r['activityType']?.toString()];
      final accuracy = r['accuracy'];
      if (skill == null || accuracy is! num) continue;
      sums[skill] = (sums[skill] ?? 0) + accuracy.toDouble();
      counts[skill] = (counts[skill] ?? 0) + 1;
    }
    return {
      for (final skill in ['Understanding', 'Application', 'Debugging', 'Communication'])
        skill: counts[skill] == null ? null : (sums[skill]! / counts[skill]!).clamp(0.0, 1.0),
    };
  }

  /// Marks the last [streakDays] days (ending today) on a Monday-first week strip.
  static List<bool> weekStrip(int streakDays, DateTime today) {
    final todayIndex = today.weekday - 1; // Monday = 0
    return List.generate(7, (i) => i <= todayIndex && todayIndex - i < streakDays);
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await LearnerProfileController.instance.load();

    Future<T?> safe<T>(Future<T> Function() call) async {
      try {
        return await call();
      } catch (e) {
        debugPrint('🏠 [DashboardController] a section failed to load: $e');
        errorMessage ??= e.toString();
        return null;
      }
    }

    final results = await Future.wait<Object?>([
      safe(_api.gamification),
      safe(_api.performanceRecords),
      safe(() => _api.concept(AppConstants.defaultConceptId)),
      safe(_api.learningProgress),
      safe(_api.recommendations),
      safe(_api.battles),
    ]);

    stats = (results[0] as GamificationStats?) ?? stats;
    final records = results[1] as List<Map<String, dynamic>>?;
    if (records != null) skills = skillsFromRecords(records);
    concept = (results[2] as ConceptInfo?) ?? concept;
    final all = results[3] as List<LearningProgressModel>?;
    if (all != null) {
      for (final p in all) {
        if (p.conceptId == AppConstants.defaultConceptId) progress = p;
      }
    }
    final recs = results[4] as List<RecommendationModel>?;
    if (recs != null && recs.isNotEmpty) nextMove = recs.first;
    battles = (results[5] as List<BattleInfo>?) ?? battles;

    isLoading = false;
    notifyListeners();
  }
}
