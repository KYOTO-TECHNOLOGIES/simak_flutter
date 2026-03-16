import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uae_ecom_project/features/orders/service/order_service.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';

enum CheckoutStep { address, summary, payment }

class CheckoutController extends ChangeNotifier {
  final OrderService _service = OrderService();

  CheckoutStep _currentStep = CheckoutStep.address;
  CheckoutStep get currentStep => _currentStep;

  String? _selectedAddressId;
  String? get selectedAddressId => _selectedAddressId;

  // Delivery Preferences
  DateTime? _deliveryDate;
  DateTime? get deliveryDate => _deliveryDate;

  String? _deliverySlot;
  String? get deliverySlot => _deliverySlot;

  String? _deliveryNotes;
  String? get deliveryNotes => _deliveryNotes;

  // Payment & Tipping
  String _paymentMethod = 'Cash on Delivery'; 
  String get paymentMethod => _paymentMethod;

  double _tipAmount = 0.0;
  double get tipAmount => _tipAmount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void nextStep() {
    if (_currentStep == CheckoutStep.address) {
      if (_selectedAddressId == null) {
        _error = 'Please select an address';
        notifyListeners();
        return;
      }
      _currentStep = CheckoutStep.summary;
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
      );
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
    _paymentMethod = 'Cash on Delivery';
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
