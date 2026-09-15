/// CodingChallengeModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class CodingChallengeModel {
  final String id;

  const CodingChallengeModel({
    required this.id,
  });

  factory CodingChallengeModel.fromJson(Map<String, dynamic> json) {
    return CodingChallengeModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
