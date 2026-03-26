import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';

class ReviewService {
  final Dio _dio = ApiClient().dio;

  /// POST /api/reviews/
  /// Submits a new review with optional image files.
  Future<Map<String, dynamic>> submitReview({
    required int productId,
    required int rating,
    required String comment,
    List<File> images = const [],
  }) async {
    final formData = FormData.fromMap({
      'product': productId,
      'rating': rating,
      'comment': comment,
      'is_visible': true,
    });

    for (int i = 0; i < images.length; i++) {
      final file = images[i];
      final fileName = file.path.split(Platform.pathSeparator).last;
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(file.path, filename: fileName),
      ));
    }

    final response = await _dio.post(
      'reviews/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data is Map<String, dynamic>
        ? response.data
        : <String, dynamic>{};
  }

  /// GET /api/reviews/?product={productId}
  /// Returns all visible reviews for a given product.
  Future<List<Map<String, dynamic>>> getProductReviews(int productId) async {
    final response = await _dio.get(
      'reviews/',
      queryParameters: {'product': productId},
    );

    final dynamic data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    } else if (data is Map && data.containsKey('results')) {
      return List<Map<String, dynamic>>.from(data['results']);
    }
    return [];
  }

  /// GET /api/reviews/?user={userId}
  /// Returns all reviews submitted by a specific user.
  Future<List<Map<String, dynamic>>> getUserReviews(int userId) async {
    final response = await _dio.get(
      'reviews/',
      queryParameters: {'user': userId},
    );

    final dynamic data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    } else if (data is Map && data.containsKey('results')) {
      return List<Map<String, dynamic>>.from(data['results']);
    }
    return [];
  }

  /// PATCH /api/reviews/{id}/
  /// Updates an existing review.
  Future<Map<String, dynamic>> editReview({
    required int reviewId,
    int? rating,
    String? comment,
    List<File> images = const [],
  }) async {
    final Map<String, dynamic> data = {};
    if (rating != null) data['rating'] = rating;
    if (comment != null) data['comment'] = comment;

    FormData? formData;
    if (images.isNotEmpty) {
      formData = FormData.fromMap(data);
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = file.path.split(Platform.pathSeparator).last;
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(file.path, filename: fileName),
        ));
      }
    }

    final response = await _dio.patch(
      'reviews/$reviewId/',
      data: formData ?? data,
      options: formData != null ? Options(contentType: 'multipart/form-data') : null,
    );

    return response.data is Map<String, dynamic>
        ? response.data
        : <String, dynamic>{};
  }
  /// GET /api/reviews/
  /// Returns a list of reviews, optionally filtered.
  Future<List<Map<String, dynamic>>> getReviews({int? productId, int? userId}) async {
    final Map<String, dynamic> query = {};
    if (productId != null) query['product'] = productId;
    if (userId != null) query['user'] = userId;

    final response = await _dio.get(
      'reviews/',
      queryParameters: query,
    );

    final dynamic data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    } else if (data is Map && data.containsKey('results')) {
      return List<Map<String, dynamic>>.from(data['results']);
    }
    return [];
  }
}
