/// Maps to the `data` object returned by both `POST /api/auth/register`
/// and `POST /api/auth/login` — they share the exact same shape:
/// ```json
/// { "token": "...", "userId": "...", "email": "...", "username": "..." }
/// ```
class AuthResponse {
  final String token;
  final String userId;
  final String email;
  final String username;

  const AuthResponse({
    required this.token,
    required this.userId,
    required this.email,
    required this.username,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userId': userId,
      'email': email,
      'username': username,
    };
  }
}
