import 'package:flutter/material.dart';
import 'package:uae_ecom_project/features/orders/model/coupon_model.dart';
import 'package:uae_ecom_project/features/orders/service/order_service.dart';

class CouponController extends ChangeNotifier {
  final OrderService _service = OrderService();

  List<CouponModel> _allCoupons = [];
  List<CouponModel> get allCoupons => _allCoupons;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<CouponModel> get activeCoupons => _allCoupons.where((c) {
        if (!c.isActive) return false;
        if (c.expiryDate != null && c.expiryDate!.isBefore(DateTime.now())) return false;
        return true;
      }).toList();

  List<CouponModel> get expiredCoupons => _allCoupons.where((c) {
        return c.expiryDate != null && c.expiryDate!.isBefore(DateTime.now());
      }).toList();

  List<CouponModel> get inactiveCoupons => _allCoupons.where((c) => !c.isActive).toList();

  Future<void> fetchCoupons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _service.fetchMyCoupons();
      _allCoupons = results.map((e) => CouponModel.fromJson(e)).toList();
    } catch (e) {
      _error = 'Failed to load coupons';
      debugPrint('Error fetching coupons: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get availableCount => activeCoupons.length;
  int get referralCount => _allCoupons.where((c) => (c.description ?? '').toLowerCase().contains('referral')).length;
  int get firstOrderCount => _allCoupons.where((c) => (c.code).toLowerCase().contains('welcome') || (c.description ?? '').toLowerCase().contains('first')).length;
}
