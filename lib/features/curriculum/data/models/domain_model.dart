/// DomainModel — data model.
/// Auto-scaffolded to match the project's target file structure.
/// Fill in fields/serialization as the backend contract is finalized.
class DomainModel {
  final String id;

  const DomainModel({
    required this.id,
  });

  factory DomainModel.fromJson(Map<String, dynamic> json) {
    return DomainModel(
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
