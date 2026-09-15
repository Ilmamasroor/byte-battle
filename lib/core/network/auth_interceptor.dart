import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// Attaches `Authorization: Bearer <token>` to every outgoing request that
/// needs it, and reacts when the backend says the token is no longer valid.
///
/// Per the API doc: "Every route except `/api/auth/**` requires this
/// header." So this interceptor skips `/api/auth/register` and
/// `/api/auth/login` (they don't have a token yet — that's the whole point
/// of calling them) and attaches the header to everything else
/// automatically, so no screen/repository has to remember to do it by hand.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._secureStorage, {this.onUnauthorized});

  final SecureStorageService _secureStorage;

  /// Called when the backend responds 401/403, meaning the stored token is
  /// missing/invalid/expired. Wire this to `AuthController.logout()` so the
  /// whole app falls back to the login screen instead of getting stuck.
  final Future<void> Function()? onUnauthorized;

  bool _isPublicAuthRoute(String path) {
    return path.contains('/api/auth/register') || path.contains('/api/auth/login');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isPublicAuthRoute(options.path)) {
      final token = await _secureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if ((status == 401 || status == 403) && !_isPublicAuthRoute(err.requestOptions.path)) {
      await onUnauthorized?.call();
    }
    handler.next(err);
  }
}
