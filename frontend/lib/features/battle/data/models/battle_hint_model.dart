import '../../../concepts/data/models/concept_model.dart';

/// The nested `hint` object inside the AI Battle Hint response:
/// `{ "hintLevel": 1, "hint": "...", "nextStep": "..." }`.
class BattleHintDetail {
  final int hintLevel;
  final String hint;
  final String nextStep;

  const BattleHintDetail({
    required this.hintLevel,
    required this.hint,
    required this.nextStep,
  });

  factory BattleHintDetail.fromJson(Map<String, dynamic> json) {
    return BattleHintDetail(
      hintLevel: (json['hintLevel'] as num?)?.toInt() ?? 1,
      hint: json['hint']?.toString() ?? '',
      nextStep: json['nextStep']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'hintLevel': hintLevel, 'hint': hint, 'nextStep': nextStep};
  }
}

/// Response model for `POST /api/ai/battle-hint`.
/// Not wrapped in the usual `{success, data}` envelope — the payload IS
/// the response body. Shape:
/// ```json
/// { "concept": { "id": "...", "name": "..." },
///   "question": "...",
///   "hint": { "hintLevel": 1, "hint": "...", "nextStep": "..." } }
/// ```
class BattleHintModel {
  final ConceptModel concept;
  final String question;
  final BattleHintDetail hint;

  const BattleHintModel({
    required this.concept,
    required this.question,
    required this.hint,
  });

  factory BattleHintModel.fromJson(Map<String, dynamic> json) {
    return BattleHintModel(
      concept: ConceptModel.fromJson(
        (json['concept'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      question: json['question']?.toString() ?? '',
      hint: BattleHintDetail.fromJson(
        (json['hint'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'concept': concept.toJson(),
      'question': question,
      'hint': hint.toJson(),
    };
  }
}
