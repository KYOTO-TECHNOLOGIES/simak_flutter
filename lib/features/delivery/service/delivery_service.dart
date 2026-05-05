import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';
import 'package:uae_ecom_project/features/delivery/model/delivery_model.dart';
import 'package:uae_ecom_project/features/orders/model/order_model.dart';

class DeliveryService {
  final Dio _dio = ApiClient().dio;

  Future<DeliveryDashboardData> getDeliveryDashboard() async {
    final response = await _dio.get('orders/delivery_dashboard/');
    return DeliveryDashboardData.fromJson(response.data);
  }

  Future<List<OrderModel>> getAvailableOrders({int? limit, int? offset}) async {
    final response = await _dio.get(
      'orders/available_orders/',
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );
    
    final dynamic responseData = response.data;
    if (responseData is List) {
      return responseData.map((e) => OrderModel.fromJson(e)).toList();
    } else if (responseData is Map && responseData.containsKey('results')) {
      final List results = responseData['results'];
      return results.map((e) => OrderModel.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>> claimOrder(int orderId, {String? notes}) async {
    final response = await _dio.post(
      'orders/$orderId/claim_order/',
      data: {if (notes != null) 'notes': notes},
    );
    return response.data;
  }

  Future<void> updateDeliveryStatus(
    int orderId,
    String status, {
    File? proofImage,
    String? signatureName,
    String? proofNotes,
    String? notes,
    String? cancelReason,
  }) async {
    dynamic data;

    if (status == 'DELIVERED' && proofImage != null) {
      data = FormData.fromMap({
        'status': status,
        'proof_image': await MultipartFile.fromFile(proofImage.path),
        if (signatureName != null) 'signature_name': signatureName,
        if (proofNotes != null) 'proof_notes': proofNotes,
        if (notes != null) 'notes': notes,
      });
    } else if (status == 'CANCELLED') {
      data = {
        'status': status,
        'reason': cancelReason ?? 'No reason provided',
      };
    } else {
      data = {
        'status': status,
        if (notes != null) 'notes': notes,
      };
    }

    await _dio.post(
      'orders/$orderId/delivery_update_status/',
      data: data,
      options: Options(
        contentType: data is FormData ? 'multipart/form-data' : 'application/json',
      ),
    );
  }
}
