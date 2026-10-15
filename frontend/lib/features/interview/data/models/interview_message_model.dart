/// One turn in the `conversationHistory` array sent to
/// `POST /api/ai/interview/question` — matches:
/// ```json
/// { "role": "user", "content": "What is a variable?" }
/// ```
/// `role` is always either `"user"` (the learner's answer) or
/// `"assistant"` (the interviewer's question).
class InterviewMessageModel {
  final String role;
  final String content;

  const InterviewMessageModel({required this.role, required this.content});

  const InterviewMessageModel.assistant(String content)
      : this(role: 'assistant', content: content);

  const InterviewMessageModel.user(String content)
      : this(role: 'user', content: content);

  factory InterviewMessageModel.fromJson(Map<String, dynamic> json) {
    return InterviewMessageModel(
      role: json['role']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
