import 'package:byte_battle/core/models/backend_models.dart';
import 'package:byte_battle/features/performance/data/performance_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

PerformanceRecordModel rec(String type, double acc, DateTime at, {bool success = true}) => PerformanceRecordModel(
    conceptId: 'c', activityType: type, score: (acc * 100).round(), accuracy: acc, timeSpentSeconds: 60, attemptCount: 1, success: success, createdAt: at);

void main() {
  final now = DateTime(2026, 10, 18, 12);

  test('skills average accuracy per activity type and are null without evidence', () {
    final skills = PerformanceAnalytics.skills([
      rec('BATTLE', 0.5, now),
      rec('BATTLE', 1.0, now),
      rec('CODING', 0.2, now),
    ]);
    expect(skills['Understanding'], 0.75);
    expect(skills['Application'], 0.2);
    expect(skills['Debugging'], isNull);
    expect(skills['Communication'], isNull);
  });

  test('trend buckets records by age and leaves empty buckets null', () {
    final t = PerformanceAnalytics.trend([
      rec('CODING', 0.8, now.subtract(const Duration(hours: 1))),
      rec('CODING', 0.4, now.subtract(const Duration(days: 3))),
      rec('CODING', 0.1, now.subtract(const Duration(days: 20))), // outside 7 days
    ], 7, now);
    expect(t.values.length, 7);
    expect(t.values.last, closeTo(80, 0.001));
    expect(t.values.whereType<double>().length, 2);
    expect(t.latest, closeTo(80, 0.001));
  });

  test('stats count wins and losses', () {
    final s = PerformanceAnalytics.stats([
      rec('BATTLE', 1, now),
      rec('BATTLE', 0, now, success: false),
    ], 'BATTLE');
    expect((s.total, s.successes, s.failures, s.successRate), (2, 1, 1, 0.5));
  });

  test('improvement compares older and newer half', () {
    final d = PerformanceAnalytics.improvement([
      rec('CODING', 0.2, now.subtract(const Duration(days: 2))),
      rec('CODING', 0.9, now),
    ], 'CODING');
    expect(d, closeTo(0.7, 0.001));
    expect(PerformanceAnalytics.improvement([rec('CODING', 0.2, now)], 'CODING'), isNull);
  });

  test('records are sent to the AI without a userId and with lower-case type', () {
    final m = rec('INTERVIEW', 0.5, now).toDiagnosisActivity();
    expect(m.containsKey('userId'), isFalse);
    expect(m['activityType'], 'interview');
  });

  test('diagnosis insight inverts hint dependency', () {
    final i = DiagnosisInsight.from(const DiagnosisScores(80, null, 90, null, 70))!;
    expect(i.weakest, 'Working without hints');
    expect(i.strongest, 'Boundary conditions');
  });

  test('byte dna parses topic accuracy', () {
    final d = ByteDnaModel.fromJson({
      'topicAccuracy': {'threads': {'attemptCount': 2, 'averageAccuracy': 0.25}},
      'difficultyProgression': {'threads': {'currentDifficulty': 'EASY'}},
    });
    expect(d.topicAccuracy['threads']!.attempts, 2);
    expect(d.topicDifficulty['threads'], 'EASY');
  });
}
