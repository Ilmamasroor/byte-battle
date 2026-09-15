/// Response model for `POST /api/ai/interview/question`.
/// Not wrapped in the usual `{success, data}` envelope — the payload IS
/// the response body: `{ "question": "..." }`.
class InterviewQuestionModel {
  final String question;

  const InterviewQuestionModel({required this.question});

  factory InterviewQuestionModel.fromJson(Map<String, dynamic> json) {
    return InterviewQuestionModel(
      question: json['question']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'question': question};
}
