import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:uae_ecom_project/features/auth/model/config_model.dart';
import 'package:uae_ecom_project/features/auth/service/system_service.dart';
import 'package:uae_ecom_project/core/config/app_constants.dart';

class SystemController extends ChangeNotifier {
  final SystemService _service = SystemService();

  ConfigModel? _config = ConfigModel(googleMapsApiKey: AppConstants.googleMapsApiKey);
  ConfigModel? get config => _config;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? get googleMapsApiKey => _config?.googleMapsApiKey ?? AppConstants.googleMapsApiKey;
  Dio get dio => _service.dio;

  Future<void> fetchConfig() async {
    _isLoading = true;
    notifyListeners();

    try {
      _config = await _service.fetchConfig().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('SystemController.fetchConfig Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
