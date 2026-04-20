import 'package:uae_ecom_project/features/products/model/product_model.dart';

/// Mirrors the backend ReviewDto from the React source:
/// ```
/// {
///   id, product, product_name, user, user_name, rating, comment,
///   images: [{ id, image, created_at }],   ← URL is at key "image"
///   admin_response, is_visible, created_at, updated_at
/// }
/// ```
class ReviewModel {
  final int id;
  final int product;
  final String? productName;
  final int? user;
  final String userName;
  final int rating;
  final String comment;

  /// Absolute image URLs extracted from `images[].image`.
  final List<String> images;

  final String? productImage;
  final bool isVisible;
  final DateTime createdAt;

  /// Returns true if we have successfully parsed a non-placeholder name or image.
  bool get hasProductMetadata =>
      (productName != null && productName != 'Product') || productImage != null;

  ReviewModel({
    required this.id,
    required this.product,
    this.productName,
    this.user,
    this.userName = '',
    required this.rating,
    this.comment = '',
    this.images = const [],
    this.productImage,
    this.isVisible = true,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // ── Parse images ────────────────────────────────────────────────────────
    final List<String> parsedImages = _parseImageList(json['images']);

    // ── Parse product id & name ─────────────────────────────────────────────
    int productId = 0;
    String? productName;
    String? productImage;

    final rawProduct = json['product'];
    if (rawProduct is int) {
      productId = rawProduct;
    } else if (rawProduct is Map) {
      productId = int.tryParse(rawProduct['id']?.toString() ?? '0') ?? 0;
      productName = rawProduct['name']?.toString() ??
          rawProduct['product_name']?.toString() ??
          rawProduct['title']?.toString();

      productImage = (rawProduct['image'] ??
              rawProduct['thumbnail'] ??
              rawProduct['main_image'] ??
              rawProduct['product_image'] ??
              rawProduct['product_thumbnail'])
          ?.toString();
      if (productImage != null) productImage = _toAbsolute(productImage);
    }

    // Top level overrides or secondary keys
    productName ??= json['product_name']?.toString() ??
        json['product_title']?.toString() ??
        json['item_name']?.toString() ??
        json['title']?.toString();

    productImage ??= json['product_image']?.toString() ??
        json['product_thumbnail']?.toString() ??
        json['thumbnail']?.toString() ??
        json['image']?.toString();

    if (productImage != null) productImage = _toAbsolute(productImage);

    // Fallback ID
    if (productId == 0) {
      productId = int.tryParse(json['product_id']?.toString() ?? '0') ?? 0;
    }

    return ReviewModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      product: productId,
      productName: productName,
      user: int.tryParse(json['user']?.toString() ?? ''),
      userName: json['user_name']?.toString() ??
          json['username']?.toString() ??
          '',
      rating: json['rating'] is num
          ? (json['rating'] as num).toInt()
          : int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      comment: json['comment']?.toString() ??
          json['review']?.toString() ??
          '',
      images: parsedImages,
      productImage: productImage,
      isVisible: json['is_visible'] == true ||
          json['is_visible'] == 1 ||
          json['is_visible'] == 'true',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Extracts absolute image URLs from the backend list.
  /// Each element is either:
  ///   • a String  → direct URL / path
  ///   • a Map     → { id, image, created_at } — URL is at key `image`
  static List<String> _parseImageList(dynamic raw) {
    if (raw == null || raw is! List || raw.isEmpty) return [];
    final List<String> urls = [];
    for (final item in raw) {
      if (item == null) continue;
      if (item is String) {
        final url = _toAbsolute(item);
        if (url.isNotEmpty) urls.add(url);
      } else if (item is Map) {
        // Confirmed backend shape: { id, image, created_at }
        final raw = item['image'] ??
            item['url'] ??
            item['file'] ??
            item['photo'] ??
            '';
        final url = _toAbsolute(raw.toString());
        if (url.isNotEmpty) urls.add(url);
      }
    }
    return urls;
  }

  static String _toAbsolute(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return ProductModel.getAbsoluteUrl(path);
  }

  /// Creates a minimal [ProductModel] so the edit sheet can display the
  /// product thumbnail even when only a review object is available.
  ProductModel toProductModel() {
    return ProductModel(
      id: product,
      name: productName ?? 'Product',
      description: '',
      price: 0,
      stock: 0,
      mainImage: productImage,
    );
  }
}
