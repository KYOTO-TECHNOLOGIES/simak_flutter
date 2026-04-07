class CouponModel {
  final int id;
  final String code;
  final String title;
  final String? description;
  final String discountAmount;
  final String? minOrderAmount;
  final DateTime? expiryDate;

  CouponModel({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    required this.discountAmount,
    this.minOrderAmount,
    this.expiryDate,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? json['subtitle'] ?? '',
      discountAmount: json['discount_amount_display'] ?? json['discount'] ?? '',
      minOrderAmount: json['min_order_amount']?.toString(),
      expiryDate: json['expiry_date'] != null 
          ? DateTime.tryParse(json['expiry_date'].toString()) 
          : null,
    );
  }
}
