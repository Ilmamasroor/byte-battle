/// Response model for `POST /api/ai/coding-feedback`.
/// Not wrapped in the usual `{success, data}` envelope — the payload IS
/// the response body: `{ "feedback": "..." }`.
class CodingFeedbackModel {
  final String feedback;

  const CodingFeedbackModel({required this.feedback});

  factory CodingFeedbackModel.fromJson(Map<String, dynamic> json) {
    return CodingFeedbackModel(feedback: json['feedback']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {'feedback': feedback};
}
