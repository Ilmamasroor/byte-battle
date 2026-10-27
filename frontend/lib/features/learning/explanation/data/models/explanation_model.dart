/// `POST /api/ai/explanation?conceptId=...` — grounded + personalized explanation text:
/// `{ success, operation, content, metadata: {grounded, personalized, ...}, fallback }`.
class ExplanationModel {
  final String content;
  final bool grounded;
  final bool personalized;

  /// True when the AI service was unavailable and the backend produced a local template instead.
  final bool fallback;

  const ExplanationModel({
    required this.content,
    required this.grounded,
    required this.personalized,
    required this.fallback,
  });

  factory ExplanationModel.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : const <String, dynamic>{};
    return ExplanationModel(
      content: json['content']?.toString().trim() ?? '',
      grounded: meta['grounded'] == true,
      personalized: meta['personalized'] == true,
      fallback: json['fallback'] == true || json['success'] == false,
    );
  }
}
