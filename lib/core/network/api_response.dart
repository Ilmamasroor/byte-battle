/// Mirrors the wrapper every endpoint in this backend returns:
/// ```json
/// {
///   "success": true | false,
///   "message": "string",
///   "data": <the actual response data, or null on error>,
///   "timestamp": "ISO datetime"
/// }
/// ```
///
/// [T] is the type of the already-parsed `data` payload (e.g. `AuthResponse`,
/// `UserModel`, or `void`/`null` when an endpoint has no data).
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? timestamp;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.timestamp,
  });

  /// [fromJsonT] converts the raw `data` map into a [T]. Pass `null` when
  /// the endpoint has no meaningful data payload.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      data: (rawData != null && fromJsonT != null) ? fromJsonT(rawData) : null,
      timestamp: json['timestamp']?.toString(),
    );
  }
}
