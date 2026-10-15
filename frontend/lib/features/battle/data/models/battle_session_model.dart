/// BattleSessionModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class BattleSessionModel {
  final String id;

  const BattleSessionModel({
    required this.id,
  });

  factory BattleSessionModel.fromJson(Map<String, dynamic> json) {
    return BattleSessionModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
