/// A curriculum domain (`/api/curriculum/domains`), e.g. "Java Programming".
class DomainModel {
  final String id;
  final String name;
  final String description;
  final String slug;
  final int displayOrder;

  const DomainModel({
    required this.id,
    required this.name,
    this.description = '',
    this.slug = '',
    this.displayOrder = 0,
  });

  factory DomainModel.fromJson(Map<String, dynamic> json) => DomainModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      );
}
