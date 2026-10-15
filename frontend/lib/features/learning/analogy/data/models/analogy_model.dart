import '../../../../concepts/data/models/concept_model.dart';

/// Response model for `POST /api/ai/analogy?conceptId=...`.
/// Not wrapped in the usual `{success, data}` envelope — the payload IS
/// the response body.
class AnalogyModel {
  final ConceptModel concept;
  final String analogy;
  final String connection;
  final String memoryTip;

  const AnalogyModel({
    required this.concept,
    required this.analogy,
    required this.connection,
    required this.memoryTip,
  });

  factory AnalogyModel.fromJson(Map<String, dynamic> json) {
    return AnalogyModel(
      concept: ConceptModel.fromJson(
        (json['concept'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      analogy: json['analogy']?.toString() ?? '',
      connection: json['connection']?.toString() ?? '',
      memoryTip: json['memoryTip']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'concept': concept.toJson(),
      'analogy': analogy,
      'connection': connection,
      'memoryTip': memoryTip,
    };
  }
}
