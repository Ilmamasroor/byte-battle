/// DebuggingChallengeModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class DebuggingChallengeModel {
  final String id;

  const DebuggingChallengeModel({
    required this.id,
  });

  factory DebuggingChallengeModel.fromJson(Map<String, dynamic> json) {
    return DebuggingChallengeModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
