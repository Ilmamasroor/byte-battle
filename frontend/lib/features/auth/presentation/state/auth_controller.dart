import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus {
  /// App just started — [bootstrap] hasn't resolved yet. Splash screen
  /// should stay on screen while in this state.
  unknown,
  authenticating,
  authenticated,
  unauthenticated,
}

/// Single source of truth for "who is logged in" across the whole app.
///
/// Not tied to any DI package on purpose (the project has no `provider`/
/// `riverpod` dependency yet) — [AuthController.instance] is a plain lazy
/// singleton so every screen can reach it the same way:
/// `AuthController.instance`. Screens rebuild on changes via
/// `ListenableBuilder` (built into Flutter, no extra package needed) or by
/// simply calling the async methods and handling the result/error inline,
/// same as the pre-existing screen code already did.
class AuthController extends ChangeNotifier {
  AuthController._(this._repository);

  static AuthController? _instance;

  /// Lazily builds the whole auth stack (storage -> api client -> datasource
  /// -> repository -> controller) the first time it's touched.
  static AuthController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    late final ApiClient apiClient;
    apiClient = ApiClient(
      secureStorage: secureStorage,
      // If any protected call ever comes back 401/403 (expired/invalid
      // token), force the app back to a logged-out state instead of
      // silently failing.
      onUnauthorized: () async => _instance?._forceLogout(),
    );
    final repository = AuthRepository(
      AuthRemoteDatasource(apiClient),
      secureStorage,
    );
    _instance = AuthController._(repository);
    return _instance!;
  }

  final AuthRepository _repository;

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;
  String? errorMessage;

  bool get isLoading => status == AuthStatus.authenticating;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Call once, from [SplashScreen], before deciding where to navigate.
  /// Resolves from the locally cached session only — no network call — so
  /// it's instant even with no internet connection.
  Future<AuthStatus> bootstrap() async {
    final cached = await _repository.loadCachedUser();
    currentUser = cached;
    status = cached != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    debugPrint('🔐 [AuthController.bootstrap] cachedUser: ${cached?.toJson() ?? "null"} -> status: $status');
    notifyListeners();
    return status;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    return _run(() => _repository.register(
          email: email.trim(),
          password: password,
          username: username.trim(),
        ));
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _run(() => _repository.login(
          email: email.trim(),
          password: password,
        ));
  }

  /// Fetches the full profile (`GET /api/users/{id}`, includes `role` and
  /// `createdAt`) for whoever is currently logged in. Useful for a profile
  /// screen that wants fresher/more complete data than what register/login
  /// returned.
  Future<bool> refreshProfile() async {
    if (!isAuthenticated) {
      debugPrint('🔐 [AuthController.refreshProfile] skipped: not authenticated');
      return false;
    }
    try {
      currentUser = await _repository.refreshCurrentUser();
      errorMessage = null;
      debugPrint('🔐 [AuthController.refreshProfile] SUCCESS -> ${currentUser?.toJson()}');
      notifyListeners();
      return true;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🔐 [AuthController.refreshProfile] FAILED -> ${e.message} (status: ${e.statusCode})');
      notifyListeners();
      return false;
    }
  }

  /// `PUT /api/users/me`. Only pass the field(s) the user actually
  /// changed — the other stays as-is. Updates [currentUser] (and the
  /// cached copy in secure storage) on success.
  Future<bool> updateProfile({String? username, String? email}) async {
    if (!isAuthenticated) {
      debugPrint('🔐 [AuthController.updateProfile] skipped: not authenticated');
      return false;
    }
    try {
      currentUser = await _repository.updateProfile(username: username, email: email);
      errorMessage = null;
      debugPrint('🔐 [AuthController.updateProfile] SUCCESS -> ${currentUser?.toJson()}');
      notifyListeners();
      return true;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🔐 [AuthController.updateProfile] FAILED -> ${e.message} (status: ${e.statusCode})');
      notifyListeners();
      return false;
    }
  }

  /// `PUT /api/users/me/password`. Doesn't change [currentUser] — only
  /// the account's password on the backend.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      errorMessage = null;
      debugPrint('🔐 [AuthController.changePassword] SUCCESS');
      notifyListeners();
      return true;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🔐 [AuthController.changePassword] FAILED -> ${e.message} (status: ${e.statusCode})');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    debugPrint('🔐 [AuthController.logout] logging out user: ${currentUser?.email}');
    await _repository.logout();
    _forceLogout();
  }

  /// `DELETE /api/users/me`. Irreversible — permanently deletes the
  /// account on the backend, then forces the app back to a logged-out
  /// state (same as [logout]) since there's no account left to hold a
  /// session for.
  Future<bool> deleteAccount() async {
    if (!isAuthenticated) {
      debugPrint('🔐 [AuthController.deleteAccount] skipped: not authenticated');
      return false;
    }
    try {
      await _repository.deleteAccount();
      debugPrint('🔐 [AuthController.deleteAccount] SUCCESS');
      _forceLogout();
      return true;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('🔐 [AuthController.deleteAccount] FAILED -> ${e.message} (status: ${e.statusCode})');
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('🔐 [AuthController.deleteAccount] FAILED -> unknown error');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void _forceLogout() {
    currentUser = null;
    errorMessage = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> _run(Future<UserModel> Function() action) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await action();
      status = AuthStatus.authenticated;
      debugPrint('🔐 [AuthController._run] SUCCESS -> user: ${currentUser?.toJson()}');
      notifyListeners();
      return true;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      status = AuthStatus.unauthenticated;
      debugPrint('🔐 [AuthController._run] FAILED -> ${e.message} (status: ${e.statusCode}, type: ${e.type})');
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      status = AuthStatus.unauthenticated;
      debugPrint('🔐 [AuthController._run] FAILED -> unexpected error: $e');
      notifyListeners();
      return false;
    }
  }
}
