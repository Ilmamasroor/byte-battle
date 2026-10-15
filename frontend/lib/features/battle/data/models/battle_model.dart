/// BattleModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class BattleModel {
  final String id;

  const BattleModel({
    required this.id,
  });

  factory BattleModel.fromJson(Map<String, dynamic> json) {
    return BattleModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
