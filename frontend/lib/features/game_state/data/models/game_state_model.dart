/// GameStateModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class GameStateModel {
  final String id;

  const GameStateModel({
    required this.id,
  });

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    return GameStateModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
