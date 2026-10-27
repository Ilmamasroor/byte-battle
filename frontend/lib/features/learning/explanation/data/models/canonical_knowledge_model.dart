/// Response model for `POST /api/ai/canonical-knowledge?conceptId=...`.
///
/// Response body is NOT wrapped in the usual `{success, data}` envelope —
/// it's the payload directly:
/// ```json
/// { "keyPoints": [...], "rules": [...], "examples": [...] }
/// ```
class CanonicalKnowledgeModel {
  final List<String> keyPoints;
  final List<String> rules;
  final List<String> examples;

  const CanonicalKnowledgeModel({
    required this.keyPoints,
    required this.rules,
    required this.examples,
  });

  factory CanonicalKnowledgeModel.fromJson(Map<String, dynamic> json) {
    return CanonicalKnowledgeModel(
      keyPoints: _stringList(json['keyPoints']),
      rules: _stringList(json['rules']),
      examples: _stringList(json['examples']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'keyPoints': keyPoints,
      'rules': rules,
      'examples': examples,
    };
  }
}
