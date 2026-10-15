/// Uniform, user-friendly error type thrown by [ApiClient] for every
/// failure mode (no internet, timeout, 4xx/5xx from the backend,
/// unexpected/unparsable response, etc).
///
/// Every catch site in the app (repositories, controllers, screens) only
/// ever needs to deal with this one type instead of raw Dio/HTTP errors.
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final NetworkExceptionType type;

  const NetworkException({
    required this.message,
    this.statusCode,
    this.type = NetworkExceptionType.unknown,
  });

  /// True for 401/403 — the token is missing, invalid or expired and the
  /// caller should treat the user as logged out.
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

enum NetworkExceptionType {
  /// No internet connection / DNS failure / socket error.
  noConnection,

  /// Request took too long (connect/send/receive timeout).
  timeout,

  /// Backend responded with `success: false` and a 4xx status
  /// (bad request, validation error, wrong credentials, 401/403...).
  badRequest,

  /// Backend responded with a 5xx status.
  server,

  /// Response body didn't match the expected shape.
  invalidResponse,

  /// Anything else (cancelled request, programmer error, etc).
  unknown,
}
