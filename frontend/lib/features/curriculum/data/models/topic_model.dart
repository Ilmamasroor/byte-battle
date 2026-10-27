/// A topic inside a domain (`/api/curriculum/domains/{id}/topics`), e.g. "Multithreading & Concurrency".
class TopicModel {
  final String id;
  final String domainId;
  final String name;
  final String description;
  final String slug;
  final int displayOrder;

  const TopicModel({
    required this.id,
    required this.domainId,
    required this.name,
    this.description = '',
    this.slug = '',
    this.displayOrder = 0,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) => TopicModel(
        id: json['id']?.toString() ?? '',
        domainId: json['domainId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      );
}
