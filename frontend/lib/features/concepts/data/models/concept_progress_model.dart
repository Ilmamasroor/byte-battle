/// ConceptProgressModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class ConceptProgressModel {
  final String id;

  const ConceptProgressModel({
    required this.id,
  });

  factory ConceptProgressModel.fromJson(Map<String, dynamic> json) {
    return ConceptProgressModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
