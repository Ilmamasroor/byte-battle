/// Response model for `POST /api/ai/debugging-hint`.
/// Not wrapped in the usual `{success, data}` envelope — the payload IS
/// the response body: `{ "hint": "..." }`.
class DebuggingHintModel {
  final String hint;

  const DebuggingHintModel({required this.hint});

  factory DebuggingHintModel.fromJson(Map<String, dynamic> json) {
    return DebuggingHintModel(hint: json['hint']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {'hint': hint};
}
