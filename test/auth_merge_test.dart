import 'package:flutter_test/flutter_test.dart';
import 'package:uae_ecom_project/features/auth/model/user_model.dart';

void main() {
  group('UserModel.merge tests', () {
    const existingUser = UserModel(
      id: 1,
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      phoneNumber: '+971501234567',
      isEmailVerified: true,
      isPhoneVerified: true,
    );

    test('should preserve phone verification when phone number hasn\'t changed', () {
      final json = {
        'email': 'john@example.com',
        'is_email_verified': true,
        // phone_number is missing or same, is_phone_verified is missing or false
      };
      
      final merged = UserModel.merge(existingUser, json);
      
      expect(merged.isPhoneVerified, true);
    });

    test('should preserve phone verification when phone number differs only by format', () {
      final json = {
        'phone_number': '971501234567', // No +
        'is_phone_verified': false, // Explicitly false in JSON, but existing is true
      };
      
      final merged = UserModel.merge(existingUser, json);
      
      expect(merged.isPhoneVerified, true);
      expect(merged.phoneNumber, '971501234567');
    });

    test('should reset verification if phone number actually changes', () {
      final json = {
        'phone_number': '+971509998877',
        // is_phone_verified missing -> should default to false for NEW number
      };
      
      final merged = UserModel.merge(existingUser, json);
      
      expect(merged.isPhoneVerified, false);
    });

    test('should update verification if explicitly provided with new value for changed number', () {
      final json = {
        'phone_number': '+971509998877',
        'is_phone_verified': true,
      };
      
      final merged = UserModel.merge(existingUser, json);
      
      expect(merged.isPhoneVerified, true);
    });

    test('should handle null values in JSON correctly', () {
      final json = {
        'phone_number': null,
        'is_phone_verified': null,
      };
      
      // ignore: unnecessary_null_comparison
      final merged = UserModel.merge(existingUser, json as Map<String, dynamic>);
      
      expect(merged.isPhoneVerified, true);
      expect(merged.phoneNumber, '+971501234567');
    });
  });
}
