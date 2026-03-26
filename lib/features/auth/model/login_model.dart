class LoginRequest {
  final String? email;
  final String? phoneNumber;
  final String password;

  const LoginRequest({
    this.email,
    this.phoneNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'password': password,
    };
    if (email != null && email!.isNotEmpty) data['email'] = email;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) data['phone_number'] = phoneNumber;
    return data;
  }
}
