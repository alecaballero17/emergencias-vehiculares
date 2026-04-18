class User {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'],
      phone: json['phone'],
    );
  }
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final String role;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'] ?? 'bearer',
      role: json['role'],
    );
  }
}
