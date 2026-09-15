/// BattleQuestionModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class BattleQuestionModel {
  final String id;

  const BattleQuestionModel({
    required this.id,
  });

  factory BattleQuestionModel.fromJson(Map<String, dynamic> json) {
    return BattleQuestionModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
