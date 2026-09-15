/// TopicModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class TopicModel {
  final String id;

  const TopicModel({
    required this.id,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
