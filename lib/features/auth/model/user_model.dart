import 'package:flutter/material.dart';
import 'package:uae_ecom_project/features/auth/model/address_model.dart';
import 'package:uae_ecom_project/features/auth/model/profile_model.dart';

class UserModel {
  final int? id;
  final String firstName;
  final String lastName;
  final String? fullNameFromApi;
  final String email;
  final String? phoneNumber;
  final String? role;
  final bool isActive;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String? googleId;
  final ProfileModel? profile;
  final List<AddressModel> addresses;
  final String? createdAt;
  final String? updatedAt;
  final String? lastLoginAt;

  const UserModel({
    this.id,
    required this.firstName,
    required this.lastName,
    this.fullNameFromApi,
    required this.email,
    this.phoneNumber,
    this.role,
    this.isActive = true,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.googleId,
    this.profile,
    this.addresses = const [],
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullNameFromApi: json['full_name'] as String?,
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      googleId: json['google_id'] as String?,
      profile: json['profile'] != null
          ? ProfileModel.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      addresses: (json['addresses'] as List<dynamic>?)
              ?.map((e) =>
                  AddressModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      lastLoginAt: json['last_login_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'is_active': isActive,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'google_id': googleId,
      'profile': profile?.toJson(),
      'addresses': addresses.map((a) => a.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
      'last_login_at': lastLoginAt,
    };
  }

  String get fullName =>
      fullNameFromApi ?? '$firstName $lastName'.trim();

  static UserModel merge(UserModel existing, Map<String, dynamic> json) {
    // If first_name or last_name are explicitly provided in the update,
    // we should prioritize them over a potentially stale fullNameFromApi.
    final bool hasNameUpdate = json.containsKey('first_name') || json.containsKey('last_name');
    final String? newFullNameFromApi = json.containsKey('full_name') 
        ? json['full_name'] as String? 
        : (hasNameUpdate ? null : existing.fullNameFromApi);

    final String? jsonEmail = json['email'] as String?;
    final bool hasEmailUpdate = json.containsKey('email') && jsonEmail != null && jsonEmail.isNotEmpty;
    final String newEmail = hasEmailUpdate ? jsonEmail : existing.email;
    final bool emailChanged = hasEmailUpdate && newEmail != existing.email;
    
    final bool hasEmailVerifiedJson = json.containsKey('is_email_verified');
    final bool mergedEmailVerified = emailChanged 
        ? (hasEmailVerifiedJson ? (json['is_email_verified'] as bool? ?? false) : false)
        : (hasEmailVerifiedJson 
            ? (existing.isEmailVerified || (json['is_email_verified'] as bool? ?? false)) 
            : existing.isEmailVerified);

    final String? jsonPhone = json['phone_number'] as String?;
    final bool hasPhoneUpdate = json.containsKey('phone_number') && jsonPhone != null && jsonPhone.isNotEmpty;
    final String? newPhone = hasPhoneUpdate ? jsonPhone : existing.phoneNumber;
    
    // Normalize phone numbers for robust comparison (strip non-numeric)
    String normalizePhone(String? s) => s?.replaceAll(RegExp(r'\D'), '') ?? '';
    final String normalizedNewPhone = normalizePhone(newPhone);
    final String normalizedExistingPhone = normalizePhone(existing.phoneNumber);
    final bool phoneChanged = hasPhoneUpdate && normalizedNewPhone != normalizedExistingPhone;
    
    final bool hasPhoneVerifiedJson = json.containsKey('is_phone_verified');
    final bool mergedPhoneVerified = phoneChanged 
        ? (hasPhoneVerifiedJson ? (json['is_phone_verified'] as bool? ?? false) : false)
        : (hasPhoneVerifiedJson 
            ? (existing.isPhoneVerified || (json['is_phone_verified'] as bool? ?? false)) 
            : existing.isPhoneVerified);

    debugPrint('--- UserModel.merge ---');
    debugPrint('Existing: ID=${existing.id}, E=${existing.email}(V:${existing.isEmailVerified}), P=${existing.phoneNumber}(V:${existing.isPhoneVerified})');
    debugPrint('JSON Keys: ${json.keys.toList()}');
    debugPrint('JSON Values: email=${json['email']}, phone=${json['phone_number']}, is_email_v=${json['is_email_verified']}, is_phone_v=${json['is_phone_verified']}');
    debugPrint('Calculated: emailChanged=$emailChanged, emailVerified=$mergedEmailVerified');
    debugPrint('Calculated: phoneChanged=$phoneChanged, phoneVerified=$mergedPhoneVerified');

    return UserModel(
      id: json['id'] as int? ?? existing.id,
      firstName: json['first_name'] as String? ?? existing.firstName,
      lastName: json['last_name'] as String? ?? existing.lastName,
      fullNameFromApi: newFullNameFromApi,
      email: newEmail,
      phoneNumber: newPhone,
      role: json['role'] as String? ?? existing.role,
      isActive: json['is_active'] as bool? ?? existing.isActive,
      isEmailVerified: mergedEmailVerified,
      isPhoneVerified: mergedPhoneVerified,
      googleId: json['google_id'] as String? ?? existing.googleId,
      profile: json['profile'] != null
          ? (existing.profile != null 
              ? ProfileModel.merge(existing.profile!, json['profile'] as Map<String, dynamic>)
              : ProfileModel.fromJson(json['profile'] as Map<String, dynamic>))
          : existing.profile,
      addresses: json['addresses'] != null
          ? (json['addresses'] as List<dynamic>)
              .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : existing.addresses,
      createdAt: json['created_at'] as String? ?? existing.createdAt,
      updatedAt: json['updated_at'] as String? ?? existing.updatedAt,
      lastLoginAt: json['last_login_at'] as String? ?? existing.lastLoginAt,
    );
  }

  UserModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? fullNameFromApi,
    String? email,
    String? phoneNumber,
    String? role,
    bool? isActive,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? googleId,
    ProfileModel? profile,
    List<AddressModel>? addresses,
    String? createdAt,
    String? updatedAt,
    String? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullNameFromApi: fullNameFromApi ?? this.fullNameFromApi,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      googleId: googleId ?? this.googleId,
      profile: profile ?? this.profile,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
