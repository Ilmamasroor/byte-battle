import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted on-device storage for the auth token and the last-known user
/// profile, so the app can auto-login on the next launch (see
/// `SplashScreen` -> `AuthController.bootstrap`).
///
/// Uses `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences
/// on Android) — never plain `SharedPreferences` for tokens/credentials.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              // flutter_secure_storage v9 needed `encryptedSharedPreferences:
              // true` here; v11+ removed that flag because encrypted
              // storage is the only option now, so the plain default
              // AndroidOptions() is all that's needed/valid.
              aOptions: AndroidOptions(),
            );

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  // ---- Token ----

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // ---- Cached user (id/email/username/role) ----

  Future<void> saveUser(Map<String, dynamic> userJson) =>
      _storage.write(key: _userKey, value: jsonEncode(userJson));

  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteUser() => _storage.delete(key: _userKey);

  /// Called on logout — wipes everything this service ever wrote.
  Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
  }
}
