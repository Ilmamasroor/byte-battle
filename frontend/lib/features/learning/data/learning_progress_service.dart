import 'package:flutter/foundation.dart';
import '../../../core/models/backend_models.dart';
import '../../../core/network/backend_api.dart';

/// The backend's learning stages, in order. Only the first four are completed by the learner (by finishing the
/// screen); BATTLE, CODE, DEBUG and INTERVIEW advance automatically when a verified result passes.
const List<String> kLearningStages = [
  'UNDERSTAND',
  'VISUALIZE',
  'RELATE',
  'REMEMBER',
  'BATTLE',
  'CODE',
  'DEBUG',
  'INTERVIEW',
  'IMPROVE',
  'COMPLETED',
];

int stageIndex(String stage) {
  final i = kLearningStages.indexOf(stage.toUpperCase());
  return i < 0 ? 0 : i;
}

class LearningProgressService {
  LearningProgressService._();

  /// `POST /api/learning/start` is idempotent: it creates the progress row on the first call and returns the
  /// current one afterwards, so this is also how we read the current stage.
  static Future<LearningProgressModel?> current(String conceptId) async {
    try {
      return await BackendApi.instance.startLearning(conceptId);
    } catch (e) {
      debugPrint('📚 [LearningProgress] could not read progress: $e');
      return null;
    }
  }

  /// Marks a content stage finished, but only when the learner is exactly at it (replaying an earlier screen
  /// never skips ahead, and the server refuses to complete evidence stages by hand anyway).
  /// Best effort: a failure must never block the learner from moving on.
  static Future<void> completeIfAt(String conceptId, String expectedStage) async {
    try {
      final progress = await BackendApi.instance.startLearning(conceptId);
      if (progress.currentStage.toUpperCase() == expectedStage) {
        await BackendApi.instance.completeStage(progress.id);
      }
    } catch (e) {
      debugPrint('📚 [LearningProgress] could not complete $expectedStage: $e');
    }
  }
}
