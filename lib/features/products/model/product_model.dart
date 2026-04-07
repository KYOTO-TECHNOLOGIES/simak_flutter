import 'package:uae_ecom_project/core/config/env.dart';
import 'package:uae_ecom_project/core/config/app_constants.dart';

class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String? sku;
  final List<ProductImage> images;
  final List<ProductVideo> videos;
  final double rating;
  final int reviewsCount;
  final double? discountPrice;
  final double finalPrice;
  final String categoryName;
  final String? expectedDeliveryTime;
  final bool isAvailable;
  final String? mainImage;
  final List<String> availableEmirates;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.sku,
    this.images = const [],
    this.videos = const [],
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.discountPrice,
    this.finalPrice = 0.0,
    this.categoryName = '',
    this.expectedDeliveryTime,
    this.isAvailable = true,
    this.mainImage,
    this.availableEmirates = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stock: json['stock'] ?? 0,
      sku: json['sku'],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e))
              .toList() ??
          [],
      videos: (json['videos'] as List<dynamic>?)
              ?.map((e) => ProductVideo.fromJson(e))
              .toList() ??
          [],
      rating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      reviewsCount: json['total_reviews'] ?? 0,
      discountPrice: json['discount_price'] != null
          ? double.tryParse(json['discount_price'].toString())
          : null,
      finalPrice: double.tryParse(json['final_price'].toString()) ?? 0.0,
      categoryName: json['category_name'] ?? '',
      expectedDeliveryTime: json['expected_delivery_time'],
      isAvailable: json['is_available'] ?? true,
      mainImage: json['image'] != null ? getAbsoluteUrl(json['image']) : null,
      availableEmirates: (json['available_emirates'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          [],
    );
  }

  factory ProductModel.empty() {
    return ProductModel(
      id: 0,
      name: '',
      description: '',
      price: 0.0,
      stock: 0,
    );
  }

  // Get first main image, or first image, as thumbnail
  String get thumbnail {
    if (mainImage != null && mainImage!.isNotEmpty) return mainImage!;
    if (images.isEmpty) return AppConstants.kDefaultProductImage;
    try {
      return images.firstWhere((img) => img.isMain).image;
    } catch (_) {
      return images.first.image;
    }
  }

  // Helper to ensure URLs are absolute
  static String getAbsoluteUrl(String? path) {
    if (path == null || path.isEmpty) return AppConstants.kDefaultProductImage;
    if (path.startsWith('http')) return path;
    
    // Remove /api/ from end of baseUrl if present to get root URL
    // Env.baseUrl is 'https://simakfresh.ae/api/'
    // Target is 'https://simakfresh.ae/media/...'
    String baseUrl = Env.baseUrl;
    if (baseUrl.endsWith('/api/')) {
      baseUrl = baseUrl.replaceAll('/api/', '');
    } else if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.replaceAll('/api', '');
    }
    
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    
    return '$baseUrl$path';
  }
}

class ProductImage {
  final int id;
  final String image;
  final bool isMain;

  ProductImage({
    required this.id,
    required this.image,
    this.isMain = false,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? 0,
      image: ProductModel.getAbsoluteUrl(json['image']),
      // Support both is_main and is_feature
      isMain: json['is_feature'] ?? json['is_main'] ?? false,
    );
  }
}

class ProductVideo {
  final int id;
  final String video;
  final String? thumbnail;

  ProductVideo({
    required this.id,
    required this.video,
    this.thumbnail,
  });

  factory ProductVideo.fromJson(Map<String, dynamic> json) {
    final videoPath = json['video_file'] ?? json['video_url'] ?? json['video'];
    return ProductVideo(
      id: json['id'] ?? 0,
      video: ProductModel.getAbsoluteUrl(videoPath),
      thumbnail: json['thumbnail'] != null 
        ? ProductModel.getAbsoluteUrl(json['thumbnail']) 
        : null,
    );
  }
}
