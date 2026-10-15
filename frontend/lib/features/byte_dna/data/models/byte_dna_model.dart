/// ByteDnaModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class ByteDnaModel {
  final String id;

  const ByteDnaModel({
    required this.id,
  });

  factory ByteDnaModel.fromJson(Map<String, dynamic> json) {
    return ByteDnaModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
