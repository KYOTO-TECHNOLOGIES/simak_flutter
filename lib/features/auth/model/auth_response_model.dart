import 'package:uae_ecom_project/features/auth/model/user_model.dart';

class AuthResponse {
  final String? detail;
  final String accessToken;
  final String refreshToken;
  final UserModel? user;
  final Map<String, dynamic>? rawUserJson;
  final bool isNewUser;

  const AuthResponse({
    this.detail,
    required this.accessToken,
    required this.refreshToken,
    this.user,
    this.rawUserJson,
    this.isNewUser = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? userMap = json['user'] as Map<String, dynamic>?;
    return AuthResponse(
      detail: json['detail'] as String?,
      accessToken: json['access'] as String? ?? '',
      refreshToken: json['refresh'] as String? ?? '',
      user: userMap != null ? UserModel.fromJson(userMap) : null,
      rawUserJson: userMap,
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }
}
