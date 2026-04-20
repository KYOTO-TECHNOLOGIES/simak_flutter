import 'package:flutter/material.dart';
import 'package:uae_ecom_project/features/marketing/model/marketing_model.dart';
import 'package:uae_ecom_project/features/marketing/service/marketing_service.dart';

import 'package:uae_ecom_project/features/marketing/model/delivery_offer_model.dart';

class MarketingController extends ChangeNotifier {
  final MarketingService _marketingService = MarketingService();
  
  List<MarketingModel> _banners = [];
  List<DeliveryOfferModel> _deliveryOffers = [];
  bool _isLoading = false;
  bool _isOffersLoading = false;
  String? _error;

  List<MarketingModel> get banners {
    final now = DateTime.now();
    return _banners.where((m) {
      final pos = m.position?.toLowerCase() ?? '';
      final isPopup = pos == 'popup' || pos == 'promo' || pos == 'ad' || pos == 'advertisement';
      
      // We only want banners, not popups
      if (isPopup || !m.isActive) return false;
      
      // Date validity checks
      if (m.startAt != null && m.startAt!.isAfter(now)) return false;
      if (m.endAt != null && m.endAt!.isBefore(now)) return false;
      
      return true;
    }).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<MarketingModel> get popups {
    final now = DateTime.now();
    // ignore: avoid_print
    print('DEBUG: MarketingController banners count: ${_banners.length}');
    return _banners.where((m) {
      // Basic visibility checks
      final pos = m.position?.toLowerCase() ?? '';
      final isPopup = pos == 'popup' || pos == 'promo' || pos == 'ad' || pos == 'advertisement';
      if (!isPopup || !m.isActive) return false;
      
      // Date validity checks
      if (m.startAt != null && m.startAt!.isAfter(now)) return false;
      if (m.endAt != null && m.endAt!.isBefore(now)) return false;
      
      return true;
    }).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<DeliveryOfferModel> get deliveryOffers => _deliveryOffers;
  bool get isLoading => _isLoading;
  bool get isOffersLoading => _isOffersLoading;
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

  Future<void> fetchDeliveryOffers() async {
    _isOffersLoading = true;
    notifyListeners();

    try {
      _deliveryOffers = await _marketingService.fetchDeliveryOffers();
      // ignore: avoid_print
      print('DEBUG: Fetched ${_deliveryOffers.length} delivery offers');
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: Error fetching delivery offers: $e');
    } finally {
      _isOffersLoading = false;
      notifyListeners();
    }
  }
}
