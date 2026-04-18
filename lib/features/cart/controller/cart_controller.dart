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
  int get uniqueItemCount => (_cart?.items ?? []).length;
  double get totalPrice => _cart?.totalPrice ?? 0.0;

  bool get hasOutOfStock => (_cart?.items ?? []).any((item) => item.product.stock == 0 || !item.product.isAvailable);
  bool get hasInsufficientStock => (_cart?.items ?? []).any((item) => item.quantity > item.product.stock && item.product.stock > 0);
  
  // New getters for partial checkout
  int get uniqueInStockItemCount => (_cart?.items ?? []).where((item) => item.product.stock > 0 && item.product.isAvailable).length;
  bool get hasInStockItems => uniqueInStockItemCount > 0;
  double get inStockTotalPrice => (_cart?.items ?? [])
      .where((item) => item.product.stock > 0 && item.product.isAvailable)
      .fold(0.0, (sum, item) => sum + item.subtotal);

  // The cart is "valid" to proceed if there's at least one available in-stock item
  bool get isCartValid => hasInStockItems && !hasInsufficientStock && uniqueItemCount > 0;

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

  Future<void> removeOutOfStockItems() async {
    if (_cart == null) return;
    
    final oosItems = _cart!.items.where((item) => item.product.stock == 0 || !item.product.isAvailable).toList();
    
    if (oosItems.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      for (final item in oosItems) {
        await _service.removeItem(item.product.id);
      }
      await fetchCart();
    } catch (e) {
      debugPrint('Error removing OOS items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
