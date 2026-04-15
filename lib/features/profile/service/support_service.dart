import 'package:dio/dio.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';

class SupportService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> submitSupportRequest({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final response = await _dio.post(
      'notifications/contact/',
      data: {
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
