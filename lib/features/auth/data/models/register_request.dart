/// Body for `POST /api/auth/register`.
///
/// New file — the API doc's register endpoint needs `email` + `password` +
/// `username`, which doesn't fit the login-only shape of [LoginRequest].
class RegisterRequest {
  final String email;
  final String password;
  final String username;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'username': username,
    };
  }
}
