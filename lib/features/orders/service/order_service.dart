import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';

class OrderService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> checkout({
    required dynamic addressId,
    int? productId,
    int? quantity,
    required String paymentMethod,
    String? deliveryDate,
    int? deliverySlotId,
    String? deliveryNotes,
    double tipAmount = 0.0,
    String? couponCode,
    String? successUrl,
    String? cancelUrl,
    String? pendingUrl,
  }) async {
    final response = await _dio.post(
      'orders/checkout/',
      data: {
        'device': 'mobile',
        'address_id': addressId,
        'payment_method': paymentMethod,
        'preferred_delivery_date': deliveryDate,
        'preferred_delivery_slot': deliverySlotId,
        'delivery_notes': deliveryNotes,
        'tip_amount': tipAmount,
        if (couponCode != null) 'coupon_code': couponCode,
        if (productId != null) 'product_id': productId,
        if (quantity != null) 'quantity': quantity,
        if (successUrl != null) 'success_url': successUrl,
        if (cancelUrl != null) 'cancel_url': cancelUrl,
        if (pendingUrl != null) 'pending_url': pendingUrl,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> validateCoupon(String couponCode, double cartTotal) async {
    final response = await _dio.post(
      'orders/validate_coupon/',
      data: {
        'coupon_code': couponCode,
        'cart_total': cartTotal,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getCheckoutSummary({
    required dynamic addressId,
    int? productId,
    int? quantity,
    String? couponCode,
    double tipAmount = 0.0,
  }) async {
    final response = await _dio.post(
      'orders/checkout_summary/',
      data: {
        'device': 'mobile',
        'address_id': addressId,
        'tip_amount': tipAmount,
        if (couponCode != null) 'coupon_code': couponCode,
        if (productId != null) 'product_id': productId,
        if (quantity != null) 'quantity': quantity,
      },
    );
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getAvailableCoupons() async {
    try {
      // Try the primary endpoint first
      final response = await _dio.get('orders/available_coupons/');
      final dynamic data = response.data;
      List<Map<String, dynamic>> results = [];
      
      if (data is List) {
        results = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('results')) {
        results = List<Map<String, dynamic>>.from(data['results']);
      }
      
      if (results.isNotEmpty) return results;
    } catch (e) {
      debugPrint('Error fetching from orders/available_coupons/: $e');
    }

    // fallback to marketing/coupons/ if the first one is empty or fails
    try {
      final response = await _dio.get('marketing/coupons/');
      final dynamic data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('results')) {
        return List<Map<String, dynamic>>.from(data['results']);
      }
    } catch (e) {
      debugPrint('Error fetching from marketing/coupons/: $e');
    }
    
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchMyCoupons() async {
    try {
      final response = await _dio.get('marketing/coupons/');
      final dynamic data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('results')) {
        return List<Map<String, dynamic>>.from(data['results']);
      }
    } catch (e) {
      debugPrint('Error fetching from coupons/: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final response = await _dio.get('orders/');
    final dynamic data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    } else if (data is Map && data.containsKey('results')) {
      return List<Map<String, dynamic>>.from(data['results']);
    }
    return [];
  }

  Future<Map<String, dynamic>> getOrderDetails(int id) async {
    final response = await _dio.get('orders/$id/');
    return response.data;
  }

  Future<String> retryPayment(int id) async {
    final response = await _dio.post('orders/$id/retry_payment/');
    return response.data['payment_url']?.toString() ?? '';
  }

  Future<void> addReview({
    required int productId,
    required int rating,
    required String comment,
  }) async {
    await _dio.post(
      'products/add-review/',
      data: {
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      },
    );
  }

  /// Fetches the earliest available delivery date based on product/address.
  Future<Map<String, dynamic>> getDeliveryEstimate({
    dynamic addressId,
    int? productId,
    int? quantity,
  }) async {
    final response = await _dio.get(
      'orders/estimate_delivery/',
      queryParameters: {
        if (addressId != null) 'address': addressId,
        if (productId != null) 'product_id': productId,
        if (quantity != null) 'quantity': quantity,
      },
    );
    return response.data;
  }

  /// Fetches available timeslots for a specific date.
  Future<Map<String, dynamic>> getAvailableSlots(String date) async {
    final response = await _dio.get(
      'orders/delivery-slots/available/',
      queryParameters: {'date': date},
    );
    return response.data;
  }

  /// Fetches delivery charge settings (min order for free delivery, etc.).
  Future<Map<String, dynamic>> getDeliveryChargeSettings() async {
    final response = await _dio.get('orders/delivery_charge_settings/');
    return response.data;
  }
}
