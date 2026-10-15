/// Response model for `POST /api/ai/interview/evaluate`.
/// Not wrapped in the usual `{success, data}` envelope — the payload IS
/// the response body:
/// ```json
/// {
///   "conceptualCorrectness": 0.85,
///   "completeness": 0.7,
///   "technicalClarity": 0.9,
///   "reasoning": 0.75,
///   "explanation": 0.8,
///   "feedback": "..."
/// }
/// ```
/// The five numeric fields are scores in the `0.0`–`1.0` range; `feedback`
/// is free-text written by the AI for the learner.
class InterviewEvaluationModel {
  final double conceptualCorrectness;
  final double completeness;
  final double technicalClarity;
  final double reasoning;
  final double explanation;
  final String feedback;

  const InterviewEvaluationModel({
    required this.conceptualCorrectness,
    required this.completeness,
    required this.technicalClarity,
    required this.reasoning,
    required this.explanation,
    required this.feedback,
  });

  factory InterviewEvaluationModel.fromJson(Map<String, dynamic> json) {
    return InterviewEvaluationModel(
      conceptualCorrectness: _score(json['conceptualCorrectness']),
      completeness: _score(json['completeness']),
      technicalClarity: _score(json['technicalClarity']),
      reasoning: _score(json['reasoning']),
      explanation: _score(json['explanation']),
      feedback: json['feedback']?.toString() ?? '',
    );
  }

  static double _score(dynamic value) => (value as num?)?.toDouble() ?? 0.0;

  Map<String, dynamic> toJson() {
    return {
      'conceptualCorrectness': conceptualCorrectness,
      'completeness': completeness,
      'technicalClarity': technicalClarity,
      'reasoning': reasoning,
      'explanation': explanation,
      'feedback': feedback,
    };
  }

  /// Overall score out of 20, averaged across all five 0–1 criteria and
  /// rounded to the nearest whole number — used for the "Overall x/20"
  /// readout on [InterviewResultScreen].
  int get overallOf20 {
    final avg = (conceptualCorrectness +
            completeness +
            technicalClarity +
            reasoning +
            explanation) /
        5;
    return (avg * 20).round().clamp(0, 20);
  }
}
