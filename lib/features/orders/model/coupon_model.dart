class CouponModel {
  final int id;
  final String code;
  final String title;
  final String? description;
  final String discountAmount;
  final String? minOrderAmount;
  final DateTime? expiryDate;
  final bool isActive;
  final bool isUsed;
  final int usageCount;
  final int usageLimit;

  CouponModel({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    required this.discountAmount,
    this.minOrderAmount,
    this.expiryDate,
    this.isActive = true,
    this.isUsed = false,
    this.usageCount = 0,
    this.usageLimit = 0,
  });

  bool get isAvailable {
    if (!isActive) return false;
    if (isUsed) return false;
    if (expiryDate != null && expiryDate!.isBefore(DateTime.now())) return false;
    return true;
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    bool active = true;
    
    if (json.containsKey('is_active')) {
      active = json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1';
    }
    
    if (json.containsKey('status') && json['status'] != null) {
      final statusStr = json['status'].toString().toLowerCase();
      if (statusStr != 'active' && statusStr != 'published' && statusStr != '1' && statusStr != 'true') {
        active = false;
      }
    }

    // Check usage limits
    final int usageCount = int.tryParse(json['usage_count']?.toString() ?? json['used_count']?.toString() ?? json['times_used']?.toString() ?? '0') ?? 0;
    final int usageLimit = int.tryParse(json['usage_limit']?.toString() ?? json['limit']?.toString() ?? json['max_uses']?.toString() ?? '0') ?? 0;
    if (usageLimit > 0 && usageCount >= usageLimit) {
      active = false;
    }

    // Check user-specific limits
    final int userUsageCount = int.tryParse(json['user_usage_count']?.toString() ?? json['times_used_by_user']?.toString() ?? '0') ?? 0;
    final int userUsageLimit = int.tryParse(json['user_usage_limit']?.toString() ?? json['max_uses_per_user']?.toString() ?? '0') ?? 0;
    if (userUsageLimit > 0 && userUsageCount >= userUsageLimit) {
      active = false;
    }

    final bool isUsed = json['is_used'] == true || 
                        json['used'] == true || 
                        json['limit_reached'] == true || 
                        json['is_limit_reached'] == true;

    return CouponModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? json['subtitle'] ?? '',
      discountAmount: json['discount_amount_display'] ?? json['discount'] ?? '',
      minOrderAmount: json['min_order_amount']?.toString(),
      expiryDate: json['expiry_date'] != null 
          ? DateTime.tryParse(json['expiry_date'].toString()) 
          : (json['valid_to'] != null ? DateTime.tryParse(json['valid_to'].toString()) : null),
      isActive: active,
      isUsed: isUsed,
      usageCount: usageCount,
      usageLimit: usageLimit,
    );
  }
}
