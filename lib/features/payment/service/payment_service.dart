import 'package:dio/dio.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';

import 'package:flutter/foundation.dart';

class PaymentService {
  final Dio _dio = ApiClient().dio;


  Future<Map<String, dynamic>> verifyPayment(int orderId) async {
    try {
      final response = await _dio.post('orders/$orderId/verify_payment/');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMsg = e.response?.data?['error']?.toString() ?? '';
        if (errorMsg.contains('Payment is not in pending status')) {
          // The payment was already processed by a webhook. Fetch the actual status from the order!
          try {
            final orderResponse = await _dio.get('orders/$orderId/');
            final String actualStatus = orderResponse.data['payment_status']?.toString() ?? orderResponse.data['status']?.toString() ?? 'COMPLETED';
            return {'status': actualStatus};
          } catch (innerE) {
            debugPrint('Failed to recover actual order status: $innerE');
          }
        }
      }
      rethrow;
    }
  }
}
