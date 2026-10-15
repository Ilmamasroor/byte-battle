import '../../../learner_profile/data/models/learner_profile_model.dart';

/// Request body for `POST /api/ai/recommend`.
class RecommendationAiRequest {
  // TODO: security — should come from JWT, not client.
  final String userId;
  final ExperienceLevel technicalExperience;
  final String topic;
  final List<String> repeatedMistakes;
  final double conceptUnderstanding;
  final double decisionMaking;
  final double boundaryConditions;
  final double codingImplementation;
  final double hintDependency;

  const RecommendationAiRequest({
    required this.userId,
    required this.technicalExperience,
    required this.topic,
    required this.repeatedMistakes,
    required this.conceptUnderstanding,
    required this.decisionMaking,
    required this.boundaryConditions,
    required this.codingImplementation,
    required this.hintDependency,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'technicalExperience': technicalExperience.apiValue,
      'topic': topic,
      'repeatedMistakes': repeatedMistakes,
      'conceptUnderstanding': conceptUnderstanding,
      'decisionMaking': decisionMaking,
      'boundaryConditions': boundaryConditions,
      'codingImplementation': codingImplementation,
      'hintDependency': hintDependency,
    };
  }
}

/// Response model for `POST /api/ai/recommend`. Not wrapped in the usual
/// `{success, message, data, timestamp}` envelope — the body IS the
/// payload.
class RecommendationAiResponse {
  final String userId;
  final String topic;
  final String targetErrorCategory;
  final String recommendedChallengeType;
  final String reason;
  final String basis;

  const RecommendationAiResponse({
    required this.userId,
    required this.topic,
    required this.targetErrorCategory,
    required this.recommendedChallengeType,
    required this.reason,
    required this.basis,
  });

  factory RecommendationAiResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationAiResponse(
      userId: json['userId']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      targetErrorCategory: json['targetErrorCategory']?.toString() ?? '',
      recommendedChallengeType: json['recommendedChallengeType']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      basis: json['basis']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'topic': topic,
      'targetErrorCategory': targetErrorCategory,
      'recommendedChallengeType': recommendedChallengeType,
      'reason': reason,
      'basis': basis,
    };
  }
}
