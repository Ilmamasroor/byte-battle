/// Request body for `POST /api/ai/diagnose` (and reused as a list item
/// in the `/api/ai/diagnose/summary` endpoint).
class DiagnosisActivityModel {
  // TODO: security — should come from JWT, not client.
  final String userId;
  final String activityType;
  final double accuracy;
  final int score;
  final int attemptCount;
  final int timeSpentSeconds;
  final int hintsUsed;
  final int testCasesPassed;
  final int testCasesTotal;
  final bool success;

  const DiagnosisActivityModel({
    required this.userId,
    required this.activityType,
    required this.accuracy,
    required this.score,
    required this.attemptCount,
    required this.timeSpentSeconds,
    required this.hintsUsed,
    required this.testCasesPassed,
    required this.testCasesTotal,
    required this.success,
  });

  factory DiagnosisActivityModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisActivityModel(
      userId: json['userId']?.toString() ?? '',
      activityType: json['activityType']?.toString() ?? '',
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
      timeSpentSeconds: (json['timeSpentSeconds'] as num?)?.toInt() ?? 0,
      hintsUsed: (json['hintsUsed'] as num?)?.toInt() ?? 0,
      testCasesPassed: (json['testCasesPassed'] as num?)?.toInt() ?? 0,
      testCasesTotal: (json['testCasesTotal'] as num?)?.toInt() ?? 0,
      success: json['success'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'activityType': activityType,
      'accuracy': accuracy,
      'score': score,
      'attemptCount': attemptCount,
      'timeSpentSeconds': timeSpentSeconds,
      'hintsUsed': hintsUsed,
      'testCasesPassed': testCasesPassed,
      'testCasesTotal': testCasesTotal,
      'success': success,
    };
  }
}

/// Response model for `POST /api/ai/diagnose`. Not wrapped in the usual
/// `{success, message, data, timestamp}` envelope — the body IS the
/// payload.
class DiagnosisResultModel {
  final String userId;
  final String activityType;
  final double conceptUnderstanding;
  final double decisionMaking;
  final double boundaryConditions;
  final double codingImplementation;
  final double hintDependency;

  const DiagnosisResultModel({
    required this.userId,
    required this.activityType,
    required this.conceptUnderstanding,
    required this.decisionMaking,
    required this.boundaryConditions,
    required this.codingImplementation,
    required this.hintDependency,
  });

  factory DiagnosisResultModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisResultModel(
      userId: json['userId']?.toString() ?? '',
      activityType: json['activityType']?.toString() ?? '',
      conceptUnderstanding: (json['conceptUnderstanding'] as num?)?.toDouble() ?? 0.0,
      decisionMaking: (json['decisionMaking'] as num?)?.toDouble() ?? 0.0,
      boundaryConditions: (json['boundaryConditions'] as num?)?.toDouble() ?? 0.0,
      codingImplementation: (json['codingImplementation'] as num?)?.toDouble() ?? 0.0,
      hintDependency: (json['hintDependency'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'activityType': activityType,
      'conceptUnderstanding': conceptUnderstanding,
      'decisionMaking': decisionMaking,
      'boundaryConditions': boundaryConditions,
      'codingImplementation': codingImplementation,
      'hintDependency': hintDependency,
    };
  }
}

/// Request body for `POST /api/ai/diagnose/summary`. Wraps a `userId`
/// plus a list of the same per-activity shape [DiagnosisActivityModel]
/// already uses for the single-activity `/api/ai/diagnose` endpoint —
/// reused here rather than duplicated.
class DiagnosisSummaryRequest {
  // TODO: security — should come from JWT, not client.
  final String userId;
  final List<DiagnosisActivityModel> activities;

  const DiagnosisSummaryRequest({
    required this.userId,
    required this.activities,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'activities': activities.map((a) => a.toJson()).toList(),
    };
  }
}

/// Response model for `POST /api/ai/diagnose/summary`. Not wrapped in
/// the usual `{success, message, data, timestamp}` envelope — the body
/// IS the payload. Unlike [DiagnosisResultModel], the summary response
/// carries no `userId`/`activityType` — it's an aggregate over the whole
/// activity list.
class DiagnosisSummaryResultModel {
  final double conceptUnderstanding;
  final double decisionMaking;
  final double boundaryConditions;
  final double codingImplementation;
  final double hintDependency;

  const DiagnosisSummaryResultModel({
    required this.conceptUnderstanding,
    required this.decisionMaking,
    required this.boundaryConditions,
    required this.codingImplementation,
    required this.hintDependency,
  });

  factory DiagnosisSummaryResultModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisSummaryResultModel(
      conceptUnderstanding: (json['conceptUnderstanding'] as num?)?.toDouble() ?? 0.0,
      decisionMaking: (json['decisionMaking'] as num?)?.toDouble() ?? 0.0,
      boundaryConditions: (json['boundaryConditions'] as num?)?.toDouble() ?? 0.0,
      codingImplementation: (json['codingImplementation'] as num?)?.toDouble() ?? 0.0,
      hintDependency: (json['hintDependency'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conceptUnderstanding': conceptUnderstanding,
      'decisionMaking': decisionMaking,
      'boundaryConditions': boundaryConditions,
      'codingImplementation': codingImplementation,
      'hintDependency': hintDependency,
    };
  }
}
