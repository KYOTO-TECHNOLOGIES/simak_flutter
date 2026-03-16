import 'package:flutter/material.dart';
import 'package:uae_ecom_project/features/marketing/model/marketing_model.dart';
import 'package:uae_ecom_project/features/marketing/service/marketing_service.dart';

class MarketingController extends ChangeNotifier {
  final MarketingService _marketingService = MarketingService();
  
  List<MarketingModel> _banners = [];
  bool _isLoading = false;
  String? _error;

  List<MarketingModel> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBanners() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _banners = await _marketingService.fetchMarketingMedia();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
