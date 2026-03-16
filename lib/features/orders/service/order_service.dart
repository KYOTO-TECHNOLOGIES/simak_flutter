import 'package:dio/dio.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';

class OrderService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> checkout({
    required dynamic addressId,
    int? productId,
    int? quantity,
    required String paymentMethod,
    String? deliveryDate,
    String? deliverySlot,
    String? deliveryNotes,
    double tipAmount = 0.0,
  }) async {
    final response = await _dio.post(
      'orders/checkout/',
      data: {
        'address_id': addressId,
        'payment_method': paymentMethod,
        'preferred_delivery_date': deliveryDate,
        'preferred_delivery_slot': deliverySlot,
        'delivery_notes': deliveryNotes,
        'tip_amount': tipAmount,
        if (productId != null) 'product_id': productId,
        if (quantity != null) 'quantity': quantity,
      },
    );
    return response.data;
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
}
