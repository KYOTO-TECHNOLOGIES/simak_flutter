import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uae_ecom_project/features/cart/model/cart_item_model.dart';
import 'package:uae_ecom_project/features/cart/model/cart_model.dart';
import 'package:uae_ecom_project/features/cart/service/cart_service.dart';

class CartController extends ChangeNotifier {
  final CartService _service = CartService();

  final Map<int, Timer> _debounceTimers = {};
  final Set<int> _removingItemIds = {};
  final Set<int> _updatingQuantityIds = {};
  final Map<int, int> _optimisticQuantities = {};

  bool isItemRemoving(int productId, {int? preparationId, int? cartItemId}) {
    final key = cartItemId ?? (preparationId != null ? '${productId}_$preparationId'.hashCode : productId);
    return _removingItemIds.contains(key);
  }

  bool isItemUpdatingQuantity(int productId, {int? preparationId, int? cartItemId}) {
    final key = cartItemId ?? (preparationId != null ? '${productId}_$preparationId'.hashCode : productId);
    return _updatingQuantityIds.contains(key);
  }

  int getItemQuantity(CartItemModel item) {
    final key = item.id; // Always use item.id for optimistic quantity
    return _optimisticQuantities[key] ?? item.quantity;
  }


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
  List<CartItemModel> get outOfStockItems => (_cart?.items ?? [])
      .where((item) => item.product.stock == 0 || !item.product.isAvailable)
      .toList();
  
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

  Future<bool> addToCart(int productId, int quantity, {int? preparationSpecificationId, String? preparationInstructions}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.addItem(productId, quantity, 
        preparationSpecificationId: preparationSpecificationId,
        preparationInstructions: preparationInstructions,
      );
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


  // ... (previous methods)

  void updateQuantity(int productId, int quantity, {int? preparationSpecificationId, int? cartItemId}) {
    if (quantity < 1) return;
    
    final itemKey = cartItemId ?? (preparationSpecificationId != null 
        ? '${productId}_$preparationSpecificationId'.hashCode 
        : productId);
    
    // Optimistic update
    if (cartItemId != null) {
      _optimisticQuantities[cartItemId] = quantity;
    }
    
    _updatingQuantityIds.add(itemKey);
    notifyListeners();

    _debounceTimers[itemKey]?.cancel();
    _debounceTimers[itemKey] = Timer(const Duration(milliseconds: 400), () async {
      try {
        await _service.updateQuantity(productId, quantity, 
          preparationSpecificationId: preparationSpecificationId,
          cartItemId: cartItemId,
        );
        await fetchCart();
      } catch (e) {
        _error = e.toString();
        debugPrint('CartController.updateQuantity Error: $e');
        // Rollback optimistic update on error? 
        // Better to just let fetchCart fix it or notify user.
      } finally {
        if (cartItemId != null) {
          _optimisticQuantities.remove(cartItemId);
        }
        _updatingQuantityIds.remove(itemKey);
        notifyListeners();
      }
    });
  }

   Future<bool> removeItem(int productId, {int? preparationSpecificationId, int? cartItemId}) async {
    final itemKey = cartItemId ?? (preparationSpecificationId != null 
        ? '${productId}_$preparationSpecificationId'.hashCode 
        : productId);
        
    _removingItemIds.add(itemKey);
    _error = null;
    notifyListeners();
    try {
      await _service.removeItem(productId, 
        preparationSpecificationId: preparationSpecificationId,
        cartItemId: cartItemId,
      );
      await fetchCart();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('CartController.removeItem Error: $e');
      return false;
    } finally {
      _removingItemIds.remove(itemKey);
      notifyListeners();
    }
  }

  Future<void> removeOutOfStockItems() async {
    if (_cart == null) return;
    
    final oosItems = outOfStockItems;
    
    if (oosItems.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      for (final item in oosItems) {
        await _service.removeItem(
          item.product.id,
          preparationSpecificationId: item.preparationSpecificationId,
          cartItemId: item.id,
        );
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
