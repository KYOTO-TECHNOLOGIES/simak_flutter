import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';
import 'package:uae_ecom_project/features/orders/model/review_model.dart';
import 'package:uae_ecom_project/features/orders/service/order_service.dart';
import 'package:uae_ecom_project/features/orders/service/review_service.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/service/product_service.dart';

class OrderController extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  final ReviewService _reviewService = ReviewService();
  final ProductService _productService = ProductService();

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  double _freeDeliveryThreshold = 40.0;
  double get freeDeliveryThreshold => _freeDeliveryThreshold;

  double _deliveryCharge = 10.0;
  double get deliveryCharge => _deliveryCharge;

  Future<void> fetchDeliverySettings() async {
    try {
      final rawData = await _orderService.getDeliveryChargeSettings();
      Map<String, dynamic> data;

      if (rawData is Map<String, dynamic>) {
        data = rawData;
      } else {
        return;
      }

      // Look for keys based on admin headers
      final threshold =
          data['minimum_amount_for_free_shipping'] ??
          data['min_free_shipping_amount'] ??
          data['min_order_value'] ??
          data['free_delivery_threshold'] ??
          40.0;

      final charge =
          data['delivery_charge'] ??
          data['shipping_charge'] ??
          data['charge'] ??
          10.0;

      _freeDeliveryThreshold = double.tryParse(threshold.toString()) ?? 40.0;
      _deliveryCharge = double.tryParse(charge.toString()) ?? 10.0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching delivery settings: $e');
    }
  }

  Map<int, ReviewModel> _productReviewMap = {};
  Map<int, ReviewModel> get productReviewMap => _productReviewMap;

  Future<void> fetchMyOrders({required int userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch orders and reviews in parallel
      final results = await Future.wait([
        _orderService.getMyOrders(),
        _reviewService.getUserReviews(userId),
      ]);

      final orderData = results[0] as List<Map<String, dynamic>>;
      final reviewData = results[1] as List<Map<String, dynamic>>;

      _orders = orderData.map((json) => OrderModel.fromJson(json)).toList();
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final reviews = reviewData
          .map((json) => ReviewModel.fromJson(json))
          .toList();

      // ── Step 3: Hydrate reviews with product metadata from orders ────────
      // Bulk Reviews API often lacks name/image; we pull them from the order list.
      for (int i = 0; i < reviews.length; i++) {
        var r = reviews[i];
        if (!r.hasProductMetadata) {
          try {
            // Find a matching product in ANY order
            for (var order in _orders) {
              final matchIndex = order.items.indexWhere((item) => item.product.id == r.product);
              if (matchIndex != -1) {
                final match = order.items[matchIndex];
                reviews[i] = ReviewModel(
                  id: r.id,
                  product: r.product,
                  productName: match.product.name,
                  productImage: match.product.thumbnail,
                  user: r.user,
                  userName: r.userName,
                  rating: r.rating,
                  comment: r.comment,
                  images: r.images,
                  isVisible: r.isVisible,
                  createdAt: r.createdAt,
                );
                break;
              }
            }
          } catch (_) {}
        }
      }

      _productReviewMap = {for (var r in reviews) r.product: r};
      _userReviews = reviews; // Update the list used in Profile screen too
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ReviewModel? getReviewForProduct(int productId) =>
      _productReviewMap[productId];

  Future<OrderModel?> fetchOrderDetails(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final json = await _orderService.getOrderDetails(id);
      return OrderModel.fromJson(json);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit a review for a product (with optional image files).
  Future<bool> addReview({
    required int productId,
    required int rating,
    required String comment,
    List<File> images = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final json = await _reviewService.submitReview(
        productId: productId,
        rating: rating,
        comment: comment,
        images: images,
      );

      // Immediately update local maps and lists for preloading
      final newReview = ReviewModel.fromJson(json);
      _productReviewMap[productId] = newReview;

      // Update _userReviews list
      _userReviews.insert(0, newReview); // Add to the top
      _userReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ReviewModel> _userReviews = [];
  List<ReviewModel> get userReviews => _userReviews;

  /// Fetch all reviews submitted by the current user.
  Future<void> fetchUserReviews(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _reviewService.getUserReviews(userId);
      final reviews = data.map((json) => ReviewModel.fromJson(json)).toList();

      // Hydrate with order metadata if available
      for (int i = 0; i < reviews.length; i++) {
        var r = reviews[i];
        if (!r.hasProductMetadata) {
          try {
            for (var order in _orders) {
              final matchIndex =
                  order.items.indexWhere((item) => item.product.id == r.product);
              if (matchIndex != -1) {
                final match = order.items[matchIndex];
                reviews[i] = ReviewModel(
                  id: r.id,
                  product: r.product,
                  productName: match.product.name,
                  productImage: match.product.thumbnail,
                  user: r.user,
                  userName: r.userName,
                  rating: r.rating,
                  comment: r.comment,
                  images: r.images,
                  isVisible: r.isVisible,
                  createdAt: r.createdAt,
                );
                break;
              }
            }
          } catch (_) {}
        }
      }

      _userReviews = reviews;
      _userReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      // Also update map for individual lookups
      for (var r in _userReviews) {
        _productReviewMap[r.product] = r;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing review.
  Future<bool> editReview({
    required int reviewId,
    int? rating,
    String? comment,
    List<File> images = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final json = await _reviewService.editReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
        images: images,
      );

      // Immediately update local map for preloading
      final updatedReview = ReviewModel.fromJson(json);
      _productReviewMap[updatedReview.product] = updatedReview;

      // Update _userReviews list
      final index = _userReviews.indexWhere((r) => r.id == updatedReview.id);
      if (index != -1) {
        _userReviews[index] = updatedReview;
      } else {
        _userReviews.insert(0, updatedReview);
      }
      _userReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all reviews for a specific product.
  Future<List<ReviewModel>> fetchProductReviews(int productId) async {
    try {
      final data = await _reviewService.getProductReviews(productId);
      return data.map((json) => ReviewModel.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  /// GET /api/reviews/{id}/
  /// Fetches fresh data for a single review and updates local caches.
  /// Call this after editing a review so the UI reflects the server response
  /// (especially the updated `images` list).
  Future<ReviewModel?> fetchReviewDetails(int reviewId) async {
    try {
      final json = await _reviewService.getReviewDetails(reviewId);
      if (json.isNotEmpty) {
        ReviewModel review = ReviewModel.fromJson(json);

        // Fallback: If metadata is missing, fetch full product details
        if (!review.hasProductMetadata && review.product != 0) {
          try {
            final product =
                await _productService.fetchProductDetail(review.product);
            review = ReviewModel(
              id: review.id,
              product: review.product,
              productName: product.name,
              productImage: product.thumbnail,
              user: review.user,
              userName: review.userName,
              rating: review.rating,
              comment: review.comment,
              images: review.images,
              isVisible: review.isVisible,
              createdAt: review.createdAt,
            );
          } catch (e) {
            debugPrint('Fallback product fetch failed for review #$reviewId: $e');
          }
        }

        _productReviewMap[review.product] = review;

        final index = _userReviews.indexWhere((r) => r.id == review.id);
        if (index != -1) {
          _userReviews[index] = review;
        }

        notifyListeners();
        return review;
      }
    } catch (e) {
      debugPrint('Error fetching review details: $e');
    }
    return null;
  }

  List<ReviewModel> _homeReviews = [];
  List<ReviewModel> get homeReviews => _homeReviews;

  /// Fetch all reviews for home page display.
  Future<void> fetchHomeReviews() async {
    try {
      final data = await _reviewService.getReviews();
      _homeReviews = data.map((json) => ReviewModel.fromJson(json)).toList();
      _homeReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// GET /api/reviews/?product={productId}&user={userId}
  /// Fetches a review for a specific product and current user, updating local caches.
  Future<ReviewModel?> fetchReviewByProduct({
    required int productId,
    required int userId,
  }) async {
    try {
      final reviews = await _reviewService.getReviews(
        productId: productId,
        userId: userId,
      );
      if (reviews.isNotEmpty) {
        ReviewModel review = ReviewModel.fromJson(reviews.first);

        // Fallback: If metadata is missing, fetch full product details
        if (!review.hasProductMetadata) {
          try {
            final product =
                await _productService.fetchProductDetail(productId);
            review = ReviewModel(
              id: review.id,
              product: review.product,
              productName: product.name,
              productImage: product.thumbnail,
              user: review.user,
              userName: review.userName,
              rating: review.rating,
              comment: review.comment,
              images: review.images,
              isVisible: review.isVisible,
              createdAt: review.createdAt,
            );
          } catch (e) {
            debugPrint('Fallback product fetch failed for product #$productId: $e');
          }
        }

        _productReviewMap[productId] = review;

        final index = _userReviews.indexWhere((r) => r.id == review.id);
        if (index != -1) {
          _userReviews[index] = review;
        } else {
          _userReviews.insert(0, review);
          _userReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        notifyListeners();
        return review;
      }
    } catch (e) {
      debugPrint('Error fetching review by product: $e');
    }
    return null;
  }
}
