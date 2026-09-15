/// ScoreModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class ScoreModel {
  final String id;

  const ScoreModel({
    required this.id,
  });

  factory ScoreModel.fromJson(Map<String, dynamic> json) {
    return ScoreModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
