/// LearningRoadmapModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class LearningRoadmapModel {
  final String id;

  const LearningRoadmapModel({
    required this.id,
  });

  factory LearningRoadmapModel.fromJson(Map<String, dynamic> json) {
    return LearningRoadmapModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
