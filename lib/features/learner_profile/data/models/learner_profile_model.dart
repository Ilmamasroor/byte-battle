/// Maps to the `data` object returned by every `/api/learner-profile`
/// endpoint (`GET`, `POST`, `PUT`).
enum ExperienceLevel {
  beginner,
  intermediate,
  advanced;

  /// The exact string the backend expects/returns, e.g. `"BEGINNER"`.
  String get apiValue => name.toUpperCase();

  /// Human-readable label for UI (dropdowns, chips, etc).
  String get label {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.advanced:
        return 'Advanced';
    }
  }

  /// Unknown/missing values fall back to [beginner] rather than throwing,
  /// same defensive approach as `UserModel.role` defaulting to `'USER'`.
  static ExperienceLevel fromApiValue(String? value) {
    switch (value?.toUpperCase()) {
      case 'INTERMEDIATE':
        return ExperienceLevel.intermediate;
      case 'ADVANCED':
        return ExperienceLevel.advanced;
      case 'BEGINNER':
      default:
        return ExperienceLevel.beginner;
    }
  }
}

class LearnerProfileModel {
  final ExperienceLevel experienceLevel;
  final String preferredLanguage;
  final int dailyGoalMinutes;

  const LearnerProfileModel({
    required this.experienceLevel,
    required this.preferredLanguage,
    required this.dailyGoalMinutes,
  });

  factory LearnerProfileModel.fromJson(Map<String, dynamic> json) {
    return LearnerProfileModel(
      experienceLevel: ExperienceLevel.fromApiValue(json['experienceLevel']?.toString()),
      preferredLanguage: json['preferredLanguage']?.toString() ?? '',
      dailyGoalMinutes: (json['dailyGoalMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'experienceLevel': experienceLevel.apiValue,
      'preferredLanguage': preferredLanguage,
      'dailyGoalMinutes': dailyGoalMinutes,
    };
  }

  LearnerProfileModel copyWith({
    ExperienceLevel? experienceLevel,
    String? preferredLanguage,
    int? dailyGoalMinutes,
  }) {
    return LearnerProfileModel(
      experienceLevel: experienceLevel ?? this.experienceLevel,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
    );
  }
}
