import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uae_ecom_project/features/orders/service/order_service.dart';
import 'package:uae_ecom_project/features/payment/service/payment_service.dart';
import 'package:uae_ecom_project/features/payment/model/payment_model.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/orders/model/coupon_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum CheckoutStep { address, summary, payment }

class CheckoutController extends ChangeNotifier {
  final OrderService _service = OrderService();
  final PaymentService _paymentService = PaymentService();

  CheckoutStep _currentStep = CheckoutStep.address;
  CheckoutStep get currentStep => _currentStep;

  // Order Tracking
  int? _lastOrderId;
  int? get lastOrderId => _lastOrderId;
  PaymentModel? _lastPayment;
  PaymentModel? get lastPayment => _lastPayment;

  String? _selectedAddressId;
  String? get selectedAddressId => _selectedAddressId;

  // Status Polling
  Timer? _statusTimer;
  bool _isPolledSuccess = false;
  bool get isPolledSuccess => _isPolledSuccess;

  void startPaymentStatusPolling() {
    _statusTimer?.cancel();
    _isPolledSuccess = false;
    
    if (_lastOrderId == null) return;

    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final payment = await _paymentService.getLatestPaymentForOrder(_lastOrderId!);
        if (payment != null) {
          _lastPayment = payment;
          if (payment.isPaid) {
            _isPolledSuccess = true;
            timer.cancel();
          } else if (payment.isFailed) {
            timer.cancel();
          }
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error polling payment status: $e');
      }

      if (timer.tick > 24) { // Stop after 2 minutes (24 * 5s)
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  // Delivery Preferences
  DateTime? _deliveryDate;
  DateTime? get deliveryDate => _deliveryDate;

  String? _deliverySlot;
  String? get deliverySlot => _deliverySlot;

  String? _deliveryNotes;
  String? get deliveryNotes => _deliveryNotes;

  // Payment & Tipping
  String _paymentMethod = 'Online Payment (Telr)'; 
  String get paymentMethod => _paymentMethod;

  double _tipAmount = 0.0;
  double get tipAmount => _tipAmount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Coupon & Summary Data
  String? _couponCode;
  String? get couponCode => _couponCode;

  bool _isCouponValid = false;
  bool get isCouponValid => _isCouponValid;

  Map<String, dynamic>? _summaryData;
  Map<String, dynamic>? get summaryData => _summaryData;

  List<CouponModel> _availableCoupons = [];
  List<CouponModel> get availableCoupons => _availableCoupons;
  
  bool _isLoadingCoupons = false;
  bool get isLoadingCoupons => _isLoadingCoupons;

  static const String _kCouponKey = 'saved_coupon_code';
 
  // Summary Data Getters
  double get summarySubtotal => double.tryParse(_summaryData?['cart_total_before_discount']?.toString() ?? '0') ?? 0.0;
  double get summaryDiscount => double.tryParse(_summaryData?['discount_amount']?.toString() ?? '0') ?? 0.0;
  double get summaryDeliveryCharge => double.tryParse(_summaryData?['delivery_charge']?.toString() ?? '0') ?? 0.0;
  double get summaryTip => double.tryParse(_summaryData?['tip_amount']?.toString() ?? '0') ?? 0.0;
  double get summaryTotal => double.tryParse(_summaryData?['final_total']?.toString() ?? '0') ?? 0.0;
  
  bool get hasSummary => _summaryData != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _couponCode = prefs.getString(_kCouponKey);
    // Fetch available coupons on init
    fetchAvailableCoupons();
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep == CheckoutStep.address) {
      if (_selectedAddressId == null) {
        _error = 'Please select an address';
        notifyListeners();
        return;
      }
      _currentStep = CheckoutStep.summary;
      fetchAvailableCoupons();
    } else if (_currentStep == CheckoutStep.summary) {
      _currentStep = CheckoutStep.payment;
    }
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep == CheckoutStep.payment) {
      _currentStep = CheckoutStep.summary;
    } else if (_currentStep == CheckoutStep.summary) {
      _currentStep = CheckoutStep.address;
    }
    notifyListeners();
  }

  void setStep(CheckoutStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void selectAddress(String addressId) {
    _selectedAddressId = addressId;
    _error = null;
    notifyListeners();
  }

  void setDeliveryPreferences({DateTime? date, String? slot, String? notes}) {
    if (date != null) _deliveryDate = date;
    if (slot != null) _deliverySlot = slot;
    if (notes != null) _deliveryNotes = notes;
    notifyListeners();
  }

  void selectPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setTipAmount(double amount) {
    _tipAmount = amount;
    notifyListeners();
    // Re-fetch summary so the API total reflects the new tip
    if (_selectedAddressId != null) {
      fetchCheckoutSummary();
    }
  }

  Future<bool> validateCoupon(String code, double cartTotal) async {
    if (code.isEmpty) {
      _couponCode = null;
      _isCouponValid = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCouponKey);
      notifyListeners();
      return true;
    }
 
    _isLoading = true;
    _error = null;
    notifyListeners();
 
    try {
      final result = await _service.validateCoupon(code, cartTotal);
      if (result['valid'] == true || result['success'] == true) {
        _couponCode = code;
        _isCouponValid = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kCouponKey, code);
        _error = null;
        return true;
      } else {
        _isCouponValid = false;
        _error = result['message'] ?? 'Invalid coupon';
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        final errorMsg = e.response?.data?['error'] ?? e.response?.data?['message'];
        if (errorMsg != null) {
          _error = errorMsg;
          return false;
        }
      }
      _error = 'Error validating coupon';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCheckoutSummary({
    ProductModel? product,
    int? quantity,
  }) async {
    if (_selectedAddressId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      dynamic finalAddressId = _selectedAddressId;
      if (_selectedAddressId != null && RegExp(r'^\d+$').hasMatch(_selectedAddressId!)) {
        finalAddressId = int.parse(_selectedAddressId!);
      }

      _summaryData = await _service.getCheckoutSummary(
        addressId: finalAddressId,
        productId: (product != null && product.id != 0) ? product.id : null,
        quantity: (product != null && product.id != 0) ? quantity : null,
        couponCode: _isCouponValid ? _couponCode : null,
        tipAmount: _tipAmount,
      );
    } catch (e) {
      debugPrint('Error fetching summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableCoupons() async {
    _isLoadingCoupons = true;
    notifyListeners();
    try {
      final results = await _service.getAvailableCoupons();
      debugPrint('Available Coupons Raw: $results');
      _availableCoupons = results.map((e) => CouponModel.fromJson(e)).toList();
      debugPrint('Parsed Coupons: ${_availableCoupons.length}');
    } catch (e) {
      debugPrint('Error fetching available coupons: $e');
    } finally {
      _isLoadingCoupons = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> placeOrder({
    ProductModel? product,
    int? quantity,
  }) async {
    if (_selectedAddressId == null) {
      _error = 'Please select an address';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Handle address ID type conversion - backend might expect a number
      dynamic finalAddressId = _selectedAddressId;
      if (_selectedAddressId != null && RegExp(r'^\d+$').hasMatch(_selectedAddressId!)) {
        finalAddressId = int.parse(_selectedAddressId!);
      }

      final response = await _service.checkout(
        addressId: finalAddressId,
        productId: (product != null && product.id != 0) ? product.id : null,
        quantity: (product != null && product.id != 0) ? quantity : null,
        paymentMethod: _paymentMethod,
        deliveryDate: _deliveryDate?.toIso8601String().split('T').first, // Format as YYYY-MM-DD
        deliverySlot: _deliverySlot,
        deliveryNotes: _deliveryNotes,
        tipAmount: _tipAmount,
        couponCode: _isCouponValid ? _couponCode : null,
      );

      // Handle TELR/Ziina redirection
      if (response.containsKey('payment_url') && response['payment_url'] != null) {
        final url = Uri.parse(response['payment_url']);
        // Use inAppBrowserView for a more integrated experience inside the app
        await launchUrl(
          url, 
          mode: LaunchMode.inAppBrowserView,
        );
      }

      // Store order info for tracking
      if (response.containsKey('order_id')) {
        _lastOrderId = response['order_id'];
        try {
          _lastPayment = await _paymentService.getLatestPaymentForOrder(_lastOrderId!);
        } catch (e) {
          debugPrint('Error fetching payment after checkout: $e');
        }
      }

      return response;
    } catch (e) {
      if (e is DioException) {
        debugPrint('Checkout Error Status: ${e.response?.statusCode}');
        debugPrint('Checkout Error Data: ${e.response?.data}');
      }
      _error = e.toString();
      debugPrint('CheckoutController.placeOrder Error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _currentStep = CheckoutStep.address;
    _selectedAddressId = null;
    _deliveryDate = null;
    _deliverySlot = null;
    _deliveryNotes = null;
    _tipAmount = 0.0;
    _paymentMethod = 'Online Payment (Telr)';
    _isLoading = false;
    _error = null;
    _couponCode = null;
    _isCouponValid = false;
    _summaryData = null;
    _lastOrderId = null;
    _lastPayment = null;
    notifyListeners();
  }
}
