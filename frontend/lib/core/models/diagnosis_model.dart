/// The `diagnosis` object sent as part of the request body to both
/// `POST /api/ai/coding-feedback` and `POST /api/ai/debugging-hint`.
/// Shape:
/// ```json
/// { "errorType": "LOGIC_ERROR", "explanation": "...", "suggestion": "..." }
/// ```
/// The backend produces this diagnosis (e.g. from static analysis of the
/// learner's submitted code) *before* either AI endpoint is called — this
/// model is just the wire format the app passes back through.
class DiagnosisModel {
  final String errorType;
  final String explanation;
  final String? suggestion;

  const DiagnosisModel({
    required this.errorType,
    required this.explanation,
    this.suggestion,
  });

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      errorType: json['errorType']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      suggestion: json['suggestion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'errorType': errorType,
      'explanation': explanation,
      if (suggestion != null) 'suggestion': suggestion,
    };
  }
}
