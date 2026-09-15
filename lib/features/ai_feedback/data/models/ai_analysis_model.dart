/// AiAnalysisModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class AiAnalysisModel {
  final String id;

  const AiAnalysisModel({
    required this.id,
  });

  factory AiAnalysisModel.fromJson(Map<String, dynamic> json) {
    return AiAnalysisModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
