/// Model for POST /api/auth/otp/request/
class OtpRequestModel {
  final String identifier;
  final String otpType;
  final bool viaWhatsApp;

  OtpRequestModel({required this.identifier, this.viaWhatsApp = false})
      : otpType = identifier.contains('@') ? 'email' : 'phone';

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'otp_type': otpType};
    if (otpType == 'email') {
      map['email'] = identifier;
    } else {
      map['phone_number'] = identifier;
      if (viaWhatsApp) {
        map['via_whatsapp'] = true;
      }
    }
    return map;
  }
}

/// Model for POST /api/auth/otp/login/
class OtpVerifyRequest {
  final String identifier;
  final String otp;
  final String otpType;

  OtpVerifyRequest({required this.identifier, required this.otp})
      : otpType = identifier.contains('@') ? 'email' : 'phone';

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'otp_type': otpType,
      'otp_code': otp,
    };
    if (otpType == 'email') {
      map['email'] = identifier;
    } else {
      map['phone_number'] = identifier;
    }
    return map;
  }
}
