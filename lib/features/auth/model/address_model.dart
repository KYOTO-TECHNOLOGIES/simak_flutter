class AddressModel {
  final String? id;
  final String? type; // 'home', 'work', 'other'
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? line1; // Flat/Villa, Building, Street
  final String? line2; // Area
  final String? city;
  final String? state; // Emirate
  final String? postalCode;
  final String? country;
  final String? landmark;
  final bool isDefault;

  const AddressModel({
    this.id,
    this.type,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.postalCode,
    this.country = 'AE',
    this.landmark,
    this.isDefault = false,
  });

  // Keep old getters for backward compatibility if possible, or update usages
  String? get name => (firstName != null || lastName != null) 
      ? '${firstName ?? ''} ${lastName ?? ''}'.trim() 
      : null;
  String? get label => type;
  String? get addressLine1 => line1;
  String? get addressLine2 => line2;

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    // Handle split names from 'full_name' if first_name/last_name are missing
    String? fName = json['first_name'] as String?;
    String? lName = json['last_name'] as String?;
    if (fName == null && json['full_name'] != null) {
      final parts = (json['full_name'] as String).split(' ');
      fName = parts.length > 1 ? parts.sublist(0, parts.length - 1).join(' ') : parts.first;
      lName = parts.length > 1 ? parts.last : '';
    }

    return AddressModel(
      id: json['id']?.toString(), // Handle UUID string or int (if mixed)
      type: (json['address_type'] ?? json['type']) as String?,
      firstName: fName,
      lastName: lName,
      phoneNumber: json['phone_number'] as String?,
      line1: (json['street_address'] ?? json['line1']) as String?,
      line2: (json['area'] ?? json['line2']) as String?,
      city: json['city'] as String?,
      state: (json['emirate'] ?? json['state']) as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String? ?? 'AE',
      landmark: json['landmark'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'type': type,
      'first_name': firstName,
      'last_name': lastName,
      'name': name,
      'full_name': name,
      'phone_number': phoneNumber?.replaceAll(RegExp(r'[^0-9+]'), ''),
      'line1': line1, 
      'street_address': line1, // REQUIRED by backend
      'line2': line2,
      'city': city,
      'state': state,
      'emirate': _getEmirateCode(state), // Updated to use lowercase keys
      'country': 'AE', // Fix: Ensure <= 2 characters
      'is_default': isDefault,
    };
    if (landmark != null && landmark!.isNotEmpty) data['landmark'] = landmark;
    if (id != null) data['id'] = id;
    
    if (postalCode != null && postalCode != '00000' && postalCode!.isNotEmpty) {
      data['postal_code'] = postalCode;
    }
    
    return data;
  }

  // Helper to map Emirates to codes if backend requires them (typically lowercase for choice keys)
  String _getEmirateCode(String? emirate) {
    if (emirate == null) return 'dubai';
    switch (emirate.toLowerCase()) {
      case 'dubai': return 'dubai'; 
      case 'sharjah': return 'sharjah';
      case 'ajman': return 'ajman';
      case 'umm al quwain': return 'umm_al_quwain';
      default: return emirate.toLowerCase().replaceAll(' ', '_');
    }
  }
}
