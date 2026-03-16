class RegisterRequest {
  final String email;
  final String phoneNumber;
  final String password;
  final String passwordConfirm;
  final String firstName;
  final String lastName;

  const RegisterRequest({
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.passwordConfirm,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
      'password_confirm': passwordConfirm,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}
