import 'package:uae_ecom_project/features/products/model/product_model.dart';

class ReviewModel {
  final int id;
  final int product;
  final String? productName;
  final int? user;
  final String userName;
  final int rating;
  final String comment;
  final List<String> images;
  final bool isVisible;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.product,
    this.productName,
    this.user,
    this.userName = '',
    required this.rating,
    this.comment = '',
    this.images = const [],
    this.isVisible = true,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Parse images — could be a list of strings or list of objects with 'image' key
    List<String> parsedImages = [];
    if (json['images'] != null) {
      for (var img in (json['images'] as List)) {
        if (img is String) {
          parsedImages.add(_ensureAbsoluteUrl(img));
        } else if (img is Map) {
          final url = img['image'] ?? img['url'] ?? '';
          parsedImages.add(_ensureAbsoluteUrl(url.toString()));
        }
      }
    }
    // Single image field fallback
    if (parsedImages.isEmpty && json['image'] != null) {
      parsedImages.add(_ensureAbsoluteUrl(json['image'].toString()));
    }

    return ReviewModel(
      id: json['id'] ?? 0,
      product: json['product'] is int
          ? json['product']
          : (json['product'] is Map ? json['product']['id'] ?? 0 : 0),
      productName: json['product'] is Map ? json['product']['name'] : null,
      user: json['user'] is int ? json['user'] : null,
      userName: json['user_name'] ?? json['username'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? json['review'] ?? '',
      images: parsedImages,
      isVisible: json['is_visible'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  static String _ensureAbsoluteUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Use the same logic as ProductModel
    return ProductModel.getAbsoluteUrl(path);
  }
}
