import '../../../../core/storage/secure_storage_service.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';

/// Sits between [AuthController] and [AuthRemoteDatasource].
///
/// Responsibilities beyond "call the API":
///  - persists the token + user returned by register/login into secure
///    storage so the session survives an app restart
///  - clears that storage on logout
///  - resolves "who is currently logged in" for splash-screen auto-login
class AuthRepository {
  const AuthRepository(this._remote, this._secureStorage);

  final AuthRemoteDatasource _remote;
  final SecureStorageService _secureStorage;

  /// Registers a new account and immediately logs the user in (the backend
  /// returns a token on register, same as login), persisting the session.
  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final auth = await _remote.register(
      RegisterRequest(email: email, password: password, username: username),
    );
    return _persistSession(auth);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final auth = await _remote.login(
      LoginRequest(email: email, password: password),
    );
    return _persistSession(auth);
  }

  /// Fetches the full profile for the currently logged-in user via
  /// `GET /api/users/me` and refreshes the cached copy.
  Future<UserModel> refreshCurrentUser() async {
    final user = await _remote.getCurrentUser();
    await _secureStorage.saveUser(user.toJson());
    return user;
  }

  /// `PUT /api/users/me`. Pass only the field(s) that changed — `null`
  /// means "leave as-is".
  Future<UserModel> updateProfile({String? username, String? email}) async {
    final user = await _remote.updateCurrentUser(username: username, email: email);
    await _secureStorage.saveUser(user.toJson());
    return user;
  }

  /// `PUT /api/users/me/password`. Doesn't touch the cached session — the
  /// token stays valid, only the password changes.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _remote.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Reads whatever is cached in secure storage without hitting the
  /// network — used by [AuthController.bootstrap] on app start so the
  /// splash screen can decide instantly whether to send the user to the
  /// dashboard or to onboarding/login.
  Future<UserModel?> loadCachedUser() async {
    final token = await _secureStorage.getToken();
    if (token == null || token.isEmpty) return null;
    final cached = await _secureStorage.getUser();
    if (cached == null) return null;
    try {
      return UserModel.fromJson(cached);
    } catch (_) {
      return null;
    }
  }

  Future<bool> get isLoggedIn async {
    final token = await _secureStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() => _secureStorage.clearAll();

  /// `DELETE /api/users/me`. Irreversible on the backend, so once it
  /// succeeds there's nothing left to stay logged into — wipe the local
  /// session too.
  Future<void> deleteAccount() async {
    await _remote.deleteAccount();
    await _secureStorage.clearAll();
  }

  Future<UserModel> _persistSession(AuthResponse auth) async {
    await _secureStorage.saveToken(auth.token);
    // Register/login don't return `role`/`createdAt` — only
    // `GET /api/users/me` does. Default to USER here; `refreshCurrentUser`
    // fills in the rest once the caller wants the full profile.
    final user = UserModel(
      id: auth.userId,
      email: auth.email,
      username: auth.username,
      role: 'USER',
    );
    await _secureStorage.saveUser(user.toJson());
    return user;
  }
}
