import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';

class ReviewService {
  final Dio _dio = ApiClient().dio;

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Resolves a MIME type from a file path, falling back to image/jpeg.
  MediaType _mediaType(String path) {
    final mime = lookupMimeType(path) ?? 'image/jpeg';
    final parts = mime.split('/');
    return MediaType(parts[0], parts.length > 1 ? parts[1] : 'jpeg');
  }

  /// Converts a [File] list into MultipartFile entries keyed as `uploaded_images`.
  /// This matches the React `create` / `update` API which uses:
  ///   form.append("uploaded_images", file)
  Future<List<MapEntry<String, MultipartFile>>> _toUploadedImages(
    List<File> files,
  ) async {
    final entries = <MapEntry<String, MultipartFile>>[];
    for (final file in files) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      entries.add(
        MapEntry(
          'uploaded_images',
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: _mediaType(file.path),
          ),
        ),
      );
    }
    return entries;
  }

  // ── Create ───────────────────────────────────────────────────────────────

  /// POST /api/reviews/
  /// Mirrors the React `reviewsApi.create` method.
  /// Field: `uploaded_images` (multipart, repeated per file).
  Future<Map<String, dynamic>> submitReview({
    required int productId,
    required int rating,
    required String comment,
    List<File> images = const [],
  }) async {
    final formData = FormData.fromMap({
      'product': productId,
      'rating': rating,
      'comment': comment.trim(),
    });

    formData.files.addAll(await _toUploadedImages(images));

    final response = await _dio.post(
      'reviews/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
  }

  // ── Read ────────────────────────────────────────────────────────────────

  /// GET /api/reviews/{id}/
  /// Mirrors the React `reviewsApi.details` method.
  Future<Map<String, dynamic>> getReviewDetails(int reviewId) async {
    final response = await _dio.get('reviews/$reviewId/');
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
  }

  /// GET /api/reviews/?product={productId}
  /// Returns all reviews for a given product.
  Future<List<Map<String, dynamic>>> getProductReviews(int productId) async {
    final response = await _dio.get(
      'reviews/',
      queryParameters: {'product': productId},
    );
    return _parseList(response.data);
  }

  /// GET /api/reviews/?user={userId}
  /// Returns all reviews submitted by a specific user.
  Future<List<Map<String, dynamic>>> getUserReviews(int userId) async {
    final response = await _dio.get(
      'reviews/',
      queryParameters: {'user': userId},
    );
    return _parseList(response.data);
  }

  /// GET /api/reviews/
  /// Returns a list of reviews, optionally filtered.
  Future<List<Map<String, dynamic>>> getReviews({
    int? productId,
    int? userId,
  }) async {
    final Map<String, dynamic> query = {};
    if (productId != null) query['product'] = productId;
    if (userId != null) query['user'] = userId;
    final response = await _dio.get('reviews/', queryParameters: query);
    return _parseList(response.data);
  }

  // ── Update ───────────────────────────────────────────────────────────────

  /// PATCH /api/reviews/{id}/
  /// Mirrors the React `reviewsApi.update` method.
  /// Only sends fields that are provided; images go as `uploaded_images`.
  Future<Map<String, dynamic>> editReview({
    required int reviewId,
    int? rating,
    String? comment,
    List<File> images = const [],
  }) async {
    final Map<String, dynamic> fields = {};
    if (rating != null) fields['rating'] = rating;
    if (comment != null) fields['comment'] = comment;

    final formData = FormData.fromMap(fields);
    formData.files.addAll(await _toUploadedImages(images));

    final response = await _dio.patch(
      'reviews/$reviewId/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map && data.containsKey('results')) {
      return List<Map<String, dynamic>>.from(data['results'] as List);
    }
    return [];
  }
}
