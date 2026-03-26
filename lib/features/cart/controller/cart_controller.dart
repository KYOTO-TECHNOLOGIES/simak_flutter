import 'package:flutter/material.dart';
import 'package:uae_ecom_project/features/cart/model/cart_model.dart';
import 'package:uae_ecom_project/features/cart/service/cart_service.dart';

class CartController extends ChangeNotifier {
  final CartService _service = CartService();

  CartModel? _cart;
  CartModel? get cart => _cart;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int get itemCount => _cart?.totalItems ?? 0;
  int get uniqueItemCount => _cart?.items.length ?? 0;
  double get totalPrice => _cart?.totalPrice ?? 0.0;

  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cart = await _service.fetchCart();
    } catch (e) {
      _error = 'failed_load_cart';
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(int productId, int quantity) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.addItem(productId, quantity);
      await fetchCart(); // Refresh cart after adding
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('CartController.addToCart Error: $e');
      notifyListeners(); 
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    if (quantity < 1) return;
    
    try {
      await _service.updateQuantity(productId, quantity);
      await fetchCart();
    } catch (e) {
      debugPrint(e.toString());
      notifyListeners();
    }
  }

  Future<void> removeItem(int productId) async {
    try {
      await _service.removeItem(productId);
      await fetchCart();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> clearCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.clearCart();
      _cart = CartModel(items: [], totalPrice: 0.0, totalItems: 0);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _cart = null;
    _error = null;
    notifyListeners();
  }
}
