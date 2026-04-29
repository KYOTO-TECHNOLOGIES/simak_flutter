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
  final String unit;
  final List<PreparationSpecification> preparationSpecifications;

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
    this.unit = 'piece',
    this.preparationSpecifications = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      sku: json['sku']?.toString(),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e))
              .toList() ??
          [],
      videos: (json['videos'] as List<dynamic>?)
              ?.map((e) => ProductVideo.fromJson(e))
              .toList() ??
          [],
      rating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      reviewsCount: int.tryParse(json['total_reviews']?.toString() ?? '0') ?? 0,
      discountPrice: json['discount_price'] != null
          ? double.tryParse(json['discount_price'].toString())
          : null,
      finalPrice: double.tryParse(json['final_price']?.toString() ?? '0') ?? 0.0,
      categoryName: json['category_name']?.toString() ?? '',
      expectedDeliveryTime: json['expected_delivery_time']?.toString(),
      isAvailable: json['is_available'] == true || json['is_available'] == 1 || json['is_available'] == 'true',
      mainImage: json['image'] != null ? getAbsoluteUrl(json['image'].toString()) : null,
      availableEmirates: (json['available_emirates'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          [],
      unit: json['unit']?.toString() ?? 'piece',
      preparationSpecifications:
          (json['preparation_specifications'] as List<dynamic>?)
                  ?.map((e) => PreparationSpecification.fromJson(Map<String, dynamic>.from(e)))
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
      unit: 'piece',
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
    
    final fullUrl = '$baseUrl$path';
    // Use encodeFull to handle spaces and other special characters in the URL
    // but keep the structure of the URL intact.
    return Uri.encodeFull(fullUrl);
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

class PreparationSpecification {
  final int id;
  final String name;
  final String? description;
  final String? image;

  PreparationSpecification({
    required this.id,
    required this.name,
    this.description,
    this.image,
  });

  factory PreparationSpecification.fromJson(Map<String, dynamic> json) {
    return PreparationSpecification(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      image: json['image'] != null
          ? ProductModel.getAbsoluteUrl(json['image'].toString())
          : null,
    );
  }
}
