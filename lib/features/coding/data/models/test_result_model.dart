/// TestResultModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class TestResultModel {
  final String id;

  const TestResultModel({
    required this.id,
  });

  factory TestResultModel.fromJson(Map<String, dynamic> json) {
    return TestResultModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
