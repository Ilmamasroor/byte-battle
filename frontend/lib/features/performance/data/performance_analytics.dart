import '../../../core/models/backend_models.dart';

/// Pure functions that turn the learner's stored performance records into what the analytics screens show.
/// Nothing here is invented: every number is derived from `GET /api/performance`.
class PerformanceAnalytics {
  PerformanceAnalytics._();

  static const battle = 'BATTLE';
  static const coding = 'CODING';
  static const debugging = 'DEBUGGING';
  static const interview = 'INTERVIEW';

  /// Skill shown for each activity type (same mapping as the dashboard).
  static const skillOfActivity = {
    battle: 'Understanding',
    coding: 'Application',
    debugging: 'Debugging',
    interview: 'Communication',
  };
  static const skillNames = ['Understanding', 'Application', 'Debugging', 'Communication'];

  static List<PerformanceRecordModel> ofType(List<PerformanceRecordModel> records, String type) =>
      records.where((r) => r.activityType == type).toList();

  /// Average accuracy (0..1) per skill; `null` = no evidence yet.
  static Map<String, double?> skills(List<PerformanceRecordModel> records) {
    final result = <String, double?>{};
    for (final entry in skillOfActivity.entries) {
      final list = ofType(records, entry.key);
      result[entry.value] = list.isEmpty ? null : list.map((r) => r.accuracy).reduce((a, b) => a + b) / list.length;
    }
    return result;
  }

  static ActivityStats stats(List<PerformanceRecordModel> records, String type) {
    final list = ofType(records, type);
    final won = list.where((r) => r.success).toList();
    return ActivityStats(
      total: list.length,
      successes: won.length,
      averageScore: list.isEmpty ? null : list.map((r) => r.score).reduce((a, b) => a + b) / list.length,
      averageAccuracy: list.isEmpty ? null : list.map((r) => r.accuracy).reduce((a, b) => a + b) / list.length,
      averageSecondsOfSuccesses:
          won.isEmpty ? null : won.map((r) => r.timeSpentSeconds).reduce((a, b) => a + b) / won.length,
    );
  }

  static int inLastDays(List<PerformanceRecordModel> records, int days, DateTime now) =>
      records.where((r) => r.createdAt != null && now.difference(r.createdAt!).inHours < days * 24).length;

  /// Seven buckets covering the last [days] days. `values[i]` is the mean accuracy in percent of the records
  /// of [type] (all types when null) that fall into bucket i, or null when there were none.
  static TrendSeries trend(List<PerformanceRecordModel> records, int days, DateTime now, {String? type}) {
    const buckets = 7;
    final length = days / buckets; // days per bucket
    final sums = List<double>.filled(buckets, 0);
    final counts = List<int>.filled(buckets, 0);
    for (final r in records) {
      if (type != null && r.activityType != type) continue;
      final created = r.createdAt;
      if (created == null) continue;
      final age = now.difference(created).inMinutes / (24 * 60.0);
      if (age < 0 || age >= days) continue;
      final index = (buckets - 1 - (age / length).floor()).clamp(0, buckets - 1);
      sums[index] += r.accuracy * 100;
      counts[index]++;
    }
    return TrendSeries([for (var i = 0; i < buckets; i++) counts[i] == 0 ? null : sums[i] / counts[i]]);
  }

  /// X-axis labels for [trend]: weekday names for 7 days, otherwise day/month of each bucket's end.
  static List<String> trendLabels(int days, DateTime now) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final length = days / 7;
    return [
      for (var i = 0; i < 7; i++)
        () {
          final end = now.subtract(Duration(minutes: ((6 - i) * length * 24 * 60).round()));
          return days <= 7 ? weekdays[end.weekday - 1] : '${end.day}/${end.month}';
        }(),
    ];
  }

  /// Compares the older and the newer half of the evidence of one skill; null when there is too little data.
  static double? improvement(List<PerformanceRecordModel> records, String type) {
    final list = ofType(records, type).where((r) => r.createdAt != null).toList()
      ..sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
    if (list.length < 2) return null;
    final half = list.length ~/ 2;
    double mean(Iterable<PerformanceRecordModel> xs) => xs.map((r) => r.accuracy).reduce((a, b) => a + b) / xs.length;
    return mean(list.sublist(list.length - half)) - mean(list.sublist(0, half));
  }

  /// "m:ss" for a number of seconds.
  static String clock(double seconds) {
    final s = seconds.round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

class ActivityStats {
  final int total;
  final int successes;
  final double? averageScore;
  final double? averageAccuracy;
  final double? averageSecondsOfSuccesses;
  const ActivityStats({
    required this.total,
    required this.successes,
    required this.averageScore,
    required this.averageAccuracy,
    required this.averageSecondsOfSuccesses,
  });
  int get failures => total - successes;
  double? get successRate => total == 0 ? null : successes / total;
}

class TrendSeries {
  final List<double?> values; // percent, null = no activity in that bucket
  const TrendSeries(this.values);
  double? get latest {
    for (var i = values.length - 1; i >= 0; i--) {
      if (values[i] != null) return values[i];
    }
    return null;
  }

  bool get hasData => values.any((v) => v != null);
}

/// The weakest and strongest dimension of an AI diagnosis, for the "Detected pattern" card.
class DiagnosisInsight {
  final String weakest;
  final String weakestAdvice;
  final String strongest;
  const DiagnosisInsight(this.weakest, this.weakestAdvice, this.strongest);

  /// [scores] are 0-100; hint dependency is inverted ("independence") because higher is worse there.
  static DiagnosisInsight? from(DiagnosisScores s) {
    final dims = <String, ({double value, String advice})>{
      if (s.conceptUnderstanding != null)
        'Concept understanding': (value: s.conceptUnderstanding!, advice: 'Revisit the explanation and analogy before the next battle.'),
      if (s.decisionMaking != null)
        'Decision making': (value: s.decisionMaking!, advice: 'Slow down on battle questions and weigh every option.'),
      if (s.boundaryConditions != null)
        'Boundary conditions': (value: s.boundaryConditions!, advice: 'Test the edge cases of your code, not only the happy path.'),
      if (s.codingImplementation != null)
        'Coding implementation': (value: s.codingImplementation!, advice: 'Practice turning the idea into working code.'),
      if (s.hintDependency != null)
        'Working without hints': (value: 100 - s.hintDependency!, advice: 'Try the next exercise before opening a hint.'),
    };
    if (dims.isEmpty) return null;
    final sorted = dims.entries.toList()..sort((a, b) => a.value.value.compareTo(b.value.value));
    return DiagnosisInsight(sorted.first.key, sorted.first.value.advice, sorted.last.key);
  }
}
