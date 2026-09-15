/// CodeSubmissionModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class CodeSubmissionModel {
  final String id;

  const CodeSubmissionModel({
    required this.id,
  });

  factory CodeSubmissionModel.fromJson(Map<String, dynamic> json) {
    return CodeSubmissionModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
