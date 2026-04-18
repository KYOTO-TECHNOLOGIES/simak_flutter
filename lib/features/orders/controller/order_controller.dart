import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';
import 'package:uae_ecom_project/features/orders/model/review_model.dart';
import 'package:uae_ecom_project/features/orders/service/order_service.dart';
import 'package:uae_ecom_project/features/orders/service/review_service.dart';

class OrderController extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  final ReviewService _reviewService = ReviewService();

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  double _freeDeliveryThreshold = 40.0;
  double get freeDeliveryThreshold => _freeDeliveryThreshold;

  Future<void> fetchDeliverySettings() async {
    try {
      final rawData = await _orderService.getDeliveryChargeSettings();
      Map<String, dynamic> data;

      if (rawData is Map<String, dynamic>) {
        data = rawData;
      } else {
        return;
      }

      // Look for keys based on admin headers: "MINIMUM AMOUNT FOR FREE SHIPPING"
      final threshold = data['minimum_amount_for_free_shipping'] ??
                        data['min_free_shipping_amount'] ??
                        data['min_order_value'] ??
                        data['free_delivery_threshold'] ??
                        40.0;

      _freeDeliveryThreshold = double.tryParse(threshold.toString()) ?? 40.0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching delivery settings: $e');
    }
  }

  Future<void> fetchMyOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _orderService.getMyOrders();
      _orders = data.map((json) => OrderModel.fromJson(json)).toList();
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      await _reviewService.submitReview(
        productId: productId,
        rating: rating,
        comment: comment,
        images: images,
      );
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
      _userReviews = data.map((json) => ReviewModel.fromJson(json)).toList();
      _userReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      await _reviewService.editReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
        images: images,
      );
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
}
