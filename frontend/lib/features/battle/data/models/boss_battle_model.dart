/// Response model for `POST /api/ai/boss-battle`.
/// Not wrapped in the usual `{success, data}` envelope — the payload IS
/// the response body:
/// ```json
/// { "scenario": "...", "suggestedOptions": ["...", "...", "..."] }
/// ```
class BossBattleModel {
  final String scenario;
  final List<String> suggestedOptions;

  const BossBattleModel({
    required this.scenario,
    required this.suggestedOptions,
  });

  factory BossBattleModel.fromJson(Map<String, dynamic> json) {
    return BossBattleModel(
      scenario: json['scenario']?.toString() ?? '',
      suggestedOptions: _stringList(json['suggestedOptions']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  Map<String, dynamic> toJson() {
    return {'scenario': scenario, 'suggestedOptions': suggestedOptions};
  }
}
