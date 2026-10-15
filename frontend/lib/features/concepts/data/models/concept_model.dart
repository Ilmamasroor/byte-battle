/// ConceptModel — matches the `concept` object embedded in AI Analogy /
/// AI Mnemonic responses (and, eventually, `/api/concepts` itself).
///
/// Only `id` is guaranteed present on every response — the Mnemonic
/// endpoint's `concept` only includes `{id, name}`, so everything else is
/// nullable rather than defaulted, so the UI can tell "not returned" apart
/// from "returned empty".
class ConceptModel {
  final String id;
  final String? name;
  final String? description;
  final String? slug;
  final String? difficulty;
  final int? displayOrder;

  const ConceptModel({
    required this.id,
    this.name,
    this.description,
    this.slug,
    this.difficulty,
    this.displayOrder,
  });

  factory ConceptModel.fromJson(Map<String, dynamic> json) {
    return ConceptModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String?,
      description: json['description'] as String?,
      slug: json['slug'] as String?,
      difficulty: json['difficulty'] as String?,
      displayOrder: json['displayOrder'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (slug != null) 'slug': slug,
      if (difficulty != null) 'difficulty': difficulty,
      if (displayOrder != null) 'displayOrder': displayOrder,
    };
  }
}
