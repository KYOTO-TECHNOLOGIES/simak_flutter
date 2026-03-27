class RegisterRequest {
  final String? email;
  final String? phoneNumber;
  final String password;
  final String passwordConfirm;
  final String firstName;
  final String lastName;
  final String? referralCode;

  const RegisterRequest({
    this.email,
    this.phoneNumber,
    required this.password,
    required this.passwordConfirm,
    required this.firstName,
    required this.lastName,
    this.referralCode,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'password': password,
      'password_confirm': passwordConfirm,
      'first_name': firstName,
      'last_name': lastName,
    };
    if (email != null && email!.isNotEmpty) data['email'] = email;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) data['phone_number'] = phoneNumber;
    if (referralCode != null && referralCode!.isNotEmpty) data['referral_code'] = referralCode;
    return data;
  }
}
