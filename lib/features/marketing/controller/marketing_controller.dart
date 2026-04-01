import 'package:flutter/material.dart';
import 'package:uae_ecom_project/features/marketing/model/marketing_model.dart';
import 'package:uae_ecom_project/features/marketing/service/marketing_service.dart';

class MarketingController extends ChangeNotifier {
  final MarketingService _marketingService = MarketingService();
  
  List<MarketingModel> _banners = [];
  bool _isLoading = false;
  String? _error;

  List<MarketingModel> get banners => _banners;
  
  List<MarketingModel> get popups {
    final now = DateTime.now();
    return _banners.where((m) {
      // Basic visibility checks
      if (m.position?.toLowerCase() != 'popup' || !m.isActive) return false;
      
      // Date validity checks
      if (m.startAt != null && m.startAt!.isAfter(now)) return false;
      if (m.endAt != null && m.endAt!.isBefore(now)) return false;
      
      return true;
    }).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

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
