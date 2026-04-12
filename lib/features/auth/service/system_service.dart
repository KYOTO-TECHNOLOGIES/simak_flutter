import 'package:dio/dio.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';
import 'package:uae_ecom_project/features/auth/model/config_model.dart';

class SystemService {
  final Dio _dio = ApiClient().dio;
  Dio get dio => _dio;

  Future<ConfigModel?> fetchConfig() async {
    try {
      // NOTE: This endpoint is assumed based on common practices.
      // If the backend has a different one, it should be updated here.
      final response = await _dio.get('system/settings/');
      if (response.statusCode == 200) {
        return ConfigModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // Return null or handle error as needed
      return null;
    }
  }
}
