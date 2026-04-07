import 'package:dio/dio.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';
import 'package:uae_ecom_project/features/payment/model/payment_model.dart';
import 'package:flutter/foundation.dart';

class PaymentService {
  final Dio _dio = ApiClient().dio;

  Future<List<PaymentModel>> getPaymentsList({
    String? search,
    String? status,
    String? paymentMethod,
    String? orderStatus,
    String? ordering,
    int page = 1,
    int? limit,
    int? offset,
  }) async {
    final response = await _dio.get(
      'orders/payments/',
      queryParameters: {
        if (search != null) 'search': search,
        if (status != null) 'status': status,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (orderStatus != null) 'order__status': orderStatus,
        if (ordering != null) 'ordering': ordering,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        'page': page,
      },
    );

    final dynamic data = response.data;
    List<dynamic> results = [];
    if (data is List) {
      results = data;
    } else if (data is Map && data.containsKey('results')) {
      results = data['results'] as List<dynamic>;
    }

    return results.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PaymentModel> getPaymentDetail(int id) async {
    final response = await _dio.get('orders/payments/$id/');
    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PaymentModel> updatePaymentStatus(int id, String status) async {
    final response = await _dio.patch(
      'orders/payments/$id/',
      data: {
        'status': status.toUpperCase(),
      },
    );
    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PaymentModel?> getLatestPaymentForOrder(int orderId) async {
    try {
      final payments = await getPaymentsList();
      for (final p in payments) {
        if (p.orderId == orderId) return p;
      }
    } catch (e) {
      debugPrint('Error fetching latest payment: $e');
    }
    return null;
  }
}
