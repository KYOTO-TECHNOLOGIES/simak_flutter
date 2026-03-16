class ProfileModel {
  final int? id;
  final String? profilePicture;
  final String? dateOfBirth;
  final String? gender;
  final String preferredLanguage;
  final bool newsletterSubscribed;
  final bool notificationEnabled;
  final String? languagesSpoken;
  final String? occupation;
  final String? businessName;
  final String? pincode;
  final String? createdAt;
  final String? updatedAt;

  const ProfileModel({
    this.id,
    this.profilePicture,
    this.dateOfBirth,
    this.gender,
    this.preferredLanguage = 'en',
    this.newsletterSubscribed = false,
    this.notificationEnabled = true,
    this.languagesSpoken,
    this.occupation,
    this.businessName,
    this.pincode,
    this.createdAt,
    this.updatedAt,
  });

  static ProfileModel merge(ProfileModel existing, Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as int? ?? existing.id,
      profilePicture: json['profile_picture'] as String? ?? existing.profilePicture,
      dateOfBirth: json['date_of_birth'] as String? ?? existing.dateOfBirth,
      gender: json['gender'] as String? ?? existing.gender,
      preferredLanguage: json['preferred_language'] as String? ?? existing.preferredLanguage,
      newsletterSubscribed: json['newsletter_subscribed'] as bool? ?? existing.newsletterSubscribed,
      notificationEnabled: json['notification_enabled'] as bool? ?? existing.notificationEnabled,
      languagesSpoken: json['languages_spoken'] as String? ?? existing.languagesSpoken,
      occupation: json['occupation'] as String? ?? existing.occupation,
      businessName: json['business_name'] as String? ?? existing.businessName,
      pincode: json['pincode'] as String? ?? existing.pincode,
      createdAt: json['created_at'] as String? ?? existing.createdAt,
      updatedAt: json['updated_at'] as String? ?? existing.updatedAt,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as int?,
      profilePicture: json['profile_picture'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      newsletterSubscribed: json['newsletter_subscribed'] as bool? ?? false,
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
      languagesSpoken: json['languages_spoken'] as String?,
      occupation: json['occupation'] as String?,
      businessName: json['business_name'] as String?,
      pincode: json['pincode'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_picture': profilePicture,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'preferred_language': preferredLanguage,
      'newsletter_subscribed': newsletterSubscribed,
      'notification_enabled': notificationEnabled,
      'languages_spoken': languagesSpoken,
      'occupation': occupation,
      'business_name': businessName,
      'pincode': pincode,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
