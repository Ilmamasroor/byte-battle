/// BattleResultModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class BattleResultModel {
  final String id;

  const BattleResultModel({
    required this.id,
  });

  factory BattleResultModel.fromJson(Map<String, dynamic> json) {
    return BattleResultModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
