import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../app/constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';
import 'network_exception.dart';

/// Thin wrapper around [Dio] that:
///  - points at [ApiEndpoints.baseUrl]
///  - auto-attaches the bearer token via [AuthInterceptor]
///  - converts every failure into a single, predictable [NetworkException]
///
/// Repositories/datasources call `get`/`post` and get back the already
/// decoded JSON body (`Map<String, dynamic>`) — they never touch Dio or
/// HTTP status codes directly.
class ApiClient {
  ApiClient({
    required SecureStorageService secureStorage,
    Future<void> Function()? onUnauthorized,
    Dio? dio,
  })  : _secureStorage = secureStorage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                // Capped at 10s app-wide: a hung/slow/500-erroring backend
                // should never leave a screen spinning indefinitely — every
                // single call through this client (register, login, every
                // AI endpoint, learner-profile, etc.) gets the same 10s
                // ceiling, then fails over to the NetworkException path
                // below, which every controller already catches safely.
                connectTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                contentType: 'application/json',
                // Required when baseUrl points at a free ngrok tunnel
                // (see ApiEndpoints): ngrok otherwise serves an HTML
                // "visit site" interstitial page to non-browser clients
                // instead of forwarding to the real backend, which would
                // break JSON parsing here. Harmless no-op against a plain
                // localhost/production backend.
                headers: const {'ngrok-skip-browser-warning': 'true'},
                // We inspect the response body ourselves for every status
                // code (the backend's own `success` flag matters more than
                // the raw HTTP status), so let everything through here.
                validateStatus: (_) => true,
              ),
            ) {
    _dio.interceptors.add(
      AuthInterceptor(_secureStorage, onUnauthorized: onUnauthorized),
    );
  }

  final Dio _dio;
  final SecureStorageService _secureStorage;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _request(
      'GET',
      path,
      () => _dio.get(path, queryParameters: query),
      query: query,
    );
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, Map<String, dynamic>? query}) {
    return _request(
      'POST',
      path,
      () => _dio.post(path, queryParameters: query, data: body),
      query: query,
      body: body,
    );
  }

  /// Same as [post], but for the handful of endpoints (the `/api/ai/*`
  /// ones) whose response body is the payload directly — no
  /// `{success, message, data, timestamp}` wrapper. A plain 2xx status is
  /// treated as success; anything else throws the same [NetworkException]
  /// every other call in the app already throws, so callers don't need to
  /// special-case these.
  Future<Map<String, dynamic>> postRaw(String path, {Map<String, dynamic>? body, Map<String, dynamic>? query}) {
    return _requestRaw(
      'POST',
      path,
      () => _dio.post(path, queryParameters: query, data: body),
      query: query,
      body: body,
    );
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) {
    return _request(
      'PUT',
      path,
      () => _dio.put(path, data: body),
      body: body,
    );
  }

  Future<Map<String, dynamic>> delete(String path, {Map<String, dynamic>? body}) {
    return _request(
      'DELETE',
      path,
      () => _dio.delete(path, data: body),
      body: body,
    );
  }

  /// -------------------------------------------------------------------
  /// DEBUG LOGGING
  /// Every single request/response/error that goes through this ApiClient
  /// (i.e. every API call from ANY feature/repository in the app) is
  /// printed to the debug console. Only runs in debug builds
  /// (kDebugMode) so it never ships to production/release builds.
  /// -------------------------------------------------------------------
  void _logRequest(String method, String path, {Map<String, dynamic>? query, Map<String, dynamic>? body}) {
    if (!kDebugMode) return;
    debugPrint('┌───────────────────────────────────────────');
    debugPrint('│ 🌐 API REQUEST  [$method] ${ApiEndpoints.baseUrl}$path');
    if (query != null && query.isNotEmpty) debugPrint('│ query : $query');
    if (body != null && body.isNotEmpty) debugPrint('│ body  : $body');
    debugPrint('└───────────────────────────────────────────');
  }

  void _logResponse(String method, String path, int statusCode, Map<String, dynamic> json) {
    if (!kDebugMode) return;
    debugPrint('┌───────────────────────────────────────────');
    debugPrint('│ ✅ API RESPONSE [$method] $path  (status: $statusCode)');
    debugPrint('│ success: ${json['success']}');
    debugPrint('│ data   : ${json['data']}');
    debugPrint('└───────────────────────────────────────────');
  }

  void _logError(String method, String path, Object error) {
    if (!kDebugMode) return;
    debugPrint('┌───────────────────────────────────────────');
    debugPrint('│ ❌ API ERROR    [$method] $path');
    debugPrint('│ $error');
    debugPrint('└───────────────────────────────────────────');
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path,
    Future<Response<dynamic>> Function() call, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    _logRequest(method, path, query: query, body: body);

    Response<dynamic> response;
    try {
      response = await call();
    } on DioException catch (e) {
      final mapped = _mapDioException(e);
      _logError(method, path, mapped);
      throw mapped;
    } catch (e) {
      final mapped = NetworkException(
        message: 'Something went wrong. Please try again.',
        type: NetworkExceptionType.unknown,
      );
      _logError(method, path, e);
      throw mapped;
    }

    final body_ = response.data;
    final Map<String, dynamic> json = body_ is Map<String, dynamic>
        ? body_
        : (body_ is Map ? Map<String, dynamic>.from(body_) : <String, dynamic>{});

    final statusCode = response.statusCode ?? 0;
    final success = json['success'] == true;

    if (statusCode >= 200 && statusCode < 300 && success) {
      _logResponse(method, path, statusCode, json);
      return json;
    }

    // Backend follows the same `{success, message, data, timestamp}` shape
    // on errors too, so surface its `message` whenever it's present.
    final message = (json['message'] as String?)?.trim();
    final exception = NetworkException(
      message: (message != null && message.isNotEmpty)
          ? message
          : _fallbackMessageFor(statusCode),
      statusCode: statusCode,
      type: statusCode >= 500
          ? NetworkExceptionType.server
          : NetworkExceptionType.badRequest,
    );
    _logError(method, path, exception);
    throw exception;
  }

  /// Same request/error handling as [_request], except success is decided
  /// purely by HTTP status code (2xx) — there's no `success` field to
  /// check because these endpoints don't use the envelope. On a non-2xx
  /// response we still try to read a `message` field in case the backend
  /// happens to include one, falling back to the same generic messages as
  /// everywhere else.
  Future<Map<String, dynamic>> _requestRaw(
    String method,
    String path,
    Future<Response<dynamic>> Function() call, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    _logRequest(method, path, query: query, body: body);

    Response<dynamic> response;
    try {
      response = await call();
    } on DioException catch (e) {
      final mapped = _mapDioException(e);
      _logError(method, path, mapped);
      throw mapped;
    } catch (e) {
      final mapped = NetworkException(
        message: 'Something went wrong. Please try again.',
        type: NetworkExceptionType.unknown,
      );
      _logError(method, path, e);
      throw mapped;
    }

    final rawBody = response.data;
    final Map<String, dynamic> json = rawBody is Map<String, dynamic>
        ? rawBody
        : (rawBody is Map ? Map<String, dynamic>.from(rawBody) : <String, dynamic>{});

    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      if (kDebugMode) {
        debugPrint('┌───────────────────────────────────────────');
        debugPrint('│ ✅ API RESPONSE [$method] $path  (status: $statusCode, raw body)');
        debugPrint('│ data   : $json');
        debugPrint('└───────────────────────────────────────────');
      }
      return json;
    }

    final message = (json['message'] as String?)?.trim();
    final exception = NetworkException(
      message: (message != null && message.isNotEmpty)
          ? message
          : _fallbackMessageFor(statusCode),
      statusCode: statusCode,
      type: statusCode >= 500
          ? NetworkExceptionType.server
          : NetworkExceptionType.badRequest,
    );
    _logError(method, path, exception);
    throw exception;
  }

  NetworkException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'The server is taking too long to respond. Please try again.',
          type: NetworkExceptionType.timeout,
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Couldn\'t reach the server. Check your internet connection '
              'and that the backend is running.',
          type: NetworkExceptionType.noConnection,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
        return NetworkException(
          message: 'Unexpected response from the server.',
          statusCode: e.response?.statusCode,
          type: NetworkExceptionType.invalidResponse,
        );
      case DioExceptionType.cancel:
        return const NetworkException(
          message: 'Request was cancelled.',
          type: NetworkExceptionType.unknown,
        );
      case DioExceptionType.unknown:
        return const NetworkException(
          message: 'Couldn\'t reach the server. Check your internet connection '
              'and that the backend is running.',
          type: NetworkExceptionType.noConnection,
        );
      // Default instead of an exhaustive case list: newer Dio versions
      // add enum values (e.g. transformTimeout) over time, and an
      // exhaustive switch fails to *compile* the moment that happens.
      // A default keeps this forward-compatible.
      default:
        return const NetworkException(
          message: 'Something went wrong. Please try again.',
          type: NetworkExceptionType.unknown,
        );
    }
  }

  String _fallbackMessageFor(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Please check the details you entered.';
      case 401:
        return 'Invalid credentials. Please log in again.';
      case 403:
        return 'You don\'t have permission to do that.';
      case 404:
        return 'Requested resource was not found.';
      case 409:
        return 'An account with this email already exists.';
      case 0:
        return 'Couldn\'t reach the server.';
      default:
        return statusCode >= 500
            ? 'Server error. Please try again later.'
            : 'Something went wrong. Please try again.';
    }
  }
}
