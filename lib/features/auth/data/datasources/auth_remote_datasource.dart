import '../../../../app/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';

/// Talks to the auth/user HTTP endpoints and nothing else — no token
/// caching, no state. That lives one layer up in [AuthRepository].
class AuthRemoteDatasource {
  const AuthRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/auth/register`
  Future<AuthResponse> register(RegisterRequest request) async {
    final json = await _apiClient.post(
      ApiEndpoints.register,
      body: request.toJson(),
    );
    return AuthResponse.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// `POST /api/auth/login`
  Future<AuthResponse> login(LoginRequest request) async {
    final json = await _apiClient.post(
      ApiEndpoints.login,
      body: request.toJson(),
    );
    return AuthResponse.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// `GET /api/users/me` — the backend resolves "which user" from the
  /// bearer token itself, so no id is needed here.
  Future<UserModel> getCurrentUser() async {
    final json = await _apiClient.get(ApiEndpoints.me);
    return UserModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// `PUT /api/users/me` — only the fields the caller actually wants to
  /// change are sent, so a partial update (e.g. username only) doesn't
  /// accidentally overwrite the other one.
  Future<UserModel> updateCurrentUser({String? username, String? email}) async {
    final json = await _apiClient.put(
      ApiEndpoints.me,
      body: {
        if (username != null) 'username': username,
        if (email != null) 'email': email,
      },
    );
    return UserModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// `PUT /api/users/me/password` — response `data` is `null` on success,
  /// so there's nothing to parse/return beyond "it didn't throw".
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _apiClient.put(
      ApiEndpoints.changePassword,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// `DELETE /api/users/me` — permanently deletes the currently
  /// logged-in user's account on the backend. Response `data` is `null`
  /// on success, same as [changePassword].
  Future<void> deleteAccount() {
    return _apiClient.delete(ApiEndpoints.me);
  }
}
