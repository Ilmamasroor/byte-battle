import '../../../../learner_profile/data/models/learner_profile_model.dart';

/// Nested `learningPreferences` object on the [OnboardingAiResponse]:
/// `{ "learningStyle": "VISUAL" }`.
class OnboardingLearningPreferences {
  final String? learningStyle;

  const OnboardingLearningPreferences({this.learningStyle});

  factory OnboardingLearningPreferences.fromJson(Map<String, dynamic> json) {
    return OnboardingLearningPreferences(
      learningStyle: json['learningStyle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (learningStyle != null) 'learningStyle': learningStyle,
    };
  }
}

/// Nested `explanationPreferences` object on the [OnboardingAiResponse]:
/// `{ "explanationStyle": "SIMPLE" }`.
class OnboardingExplanationPreferences {
  final String? explanationStyle;

  const OnboardingExplanationPreferences({this.explanationStyle});

  factory OnboardingExplanationPreferences.fromJson(Map<String, dynamic> json) {
    return OnboardingExplanationPreferences(
      explanationStyle: json['explanationStyle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (explanationStyle != null) 'explanationStyle': explanationStyle,
    };
  }
}

/// Request body for `POST /api/ai/onboarding`.
class OnboardingAiRequest {
  final String userId;
  final ExperienceLevel technicalExperience;
  final String preferredLanguage;
  final String careerGoal;
  final String learningStyle;
  final String explanationStyle;
  final List<String> interests;

  const OnboardingAiRequest({
    required this.userId,
    required this.technicalExperience,
    required this.preferredLanguage,
    required this.careerGoal,
    required this.learningStyle,
    required this.explanationStyle,
    required this.interests,
  });

  Map<String, dynamic> toJson() {
    return {
      // The backend's FastAPI personalization service rejects this call
      // with a 422 ("userId ... Input should be a valid string") when
      // this is left out — it does NOT reliably inject the id from the
      // JWT server-side, despite that being the original assumption.
      // Sending it explicitly here works around that.
      'userId': userId,
      'technicalExperience': technicalExperience.apiValue,
      'preferredLanguage': preferredLanguage,
      'careerGoal': careerGoal,
      'learningStyle': learningStyle,
      'explanationStyle': explanationStyle,
      'interests': interests,
    };
  }
}

/// Response model for `POST /api/ai/onboarding`. Not wrapped in the usual
/// `{success, message, data, timestamp}` envelope — the body IS the
/// payload (this is the freshly-seeded ByteDNA snapshot for the user).
class OnboardingAiResponse {
  final String userId;
  final ExperienceLevel technicalExperience;
  final String careerGoal;
  final List<String> interests;
  final String preferredLanguage;
  final OnboardingLearningPreferences learningPreferences;
  final OnboardingExplanationPreferences explanationPreferences;
  final List<String> confidenceAreas;
  final List<String> difficultyAreas;
  final List<String> repeatedMistakes;
  final Map<String, double> topicAccuracy;
  final Map<String, double> difficultyProgression;

  const OnboardingAiResponse({
    required this.userId,
    required this.technicalExperience,
    required this.careerGoal,
    required this.interests,
    required this.preferredLanguage,
    required this.learningPreferences,
    required this.explanationPreferences,
    required this.confidenceAreas,
    required this.difficultyAreas,
    required this.repeatedMistakes,
    required this.topicAccuracy,
    required this.difficultyProgression,
  });

  factory OnboardingAiResponse.fromJson(Map<String, dynamic> json) {
    return OnboardingAiResponse(
      userId: json['userId']?.toString() ?? '',
      technicalExperience: ExperienceLevel.fromApiValue(json['technicalExperience']?.toString()),
      careerGoal: json['careerGoal']?.toString() ?? '',
      interests: _stringList(json['interests']),
      preferredLanguage: json['preferredLanguage']?.toString() ?? '',
      learningPreferences: OnboardingLearningPreferences.fromJson(
        (json['learningPreferences'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      explanationPreferences: OnboardingExplanationPreferences.fromJson(
        (json['explanationPreferences'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      confidenceAreas: _stringList(json['confidenceAreas']),
      difficultyAreas: _stringList(json['difficultyAreas']),
      repeatedMistakes: _stringList(json['repeatedMistakes']),
      topicAccuracy: _doubleMap(json['topicAccuracy']),
      difficultyProgression: _doubleMap(json['difficultyProgression']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'technicalExperience': technicalExperience.apiValue,
      'careerGoal': careerGoal,
      'interests': interests,
      'preferredLanguage': preferredLanguage,
      'learningPreferences': learningPreferences.toJson(),
      'explanationPreferences': explanationPreferences.toJson(),
      'confidenceAreas': confidenceAreas,
      'difficultyAreas': difficultyAreas,
      'repeatedMistakes': repeatedMistakes,
      'topicAccuracy': topicAccuracy,
      'difficultyProgression': difficultyProgression,
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  static Map<String, double> _doubleMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, v) => MapEntry(key.toString(), (v as num?)?.toDouble() ?? 0.0));
  }
}
