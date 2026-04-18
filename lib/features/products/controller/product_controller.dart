import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/config/app_constants.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/model/category_model.dart';
import 'package:uae_ecom_project/features/products/service/product_service.dart';

class ProductController extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<ProductModel> _products = [];
  List<ProductModel> get products {
    // TEMPORARY: Disable emirate filtering
    // if (_activeEmirate == null || _activeEmirate!.isEmpty) return _products;
    // return _products.where((p) => p.availableEmirates.contains(_activeEmirate!.toLowerCase())).toList();
    return _products;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ─── Backend Categories ─────────────────────────────────────────
  List<CategoryModel> _backendCategories = [];
  List<CategoryModel> get backendCategories => _backendCategories;

  bool _isCategoriesLoading = false;
  bool get isCategoriesLoading => _isCategoriesLoading;

  // Selected product for detail view
  ProductModel? _selectedProduct;
  ProductModel? get selectedProduct => _selectedProduct;

  // ─── Emirate Filter ─────────────────────────────────────────────
  String? _activeEmirate;
  String? get activeEmirate => _activeEmirate;

  // ─── Category Filter ────────────────────────────────────────────
  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  /// Unique category names extracted from backend and loaded products.
  List<String> get categories {
    final Set<String> allCats = {};
    
    // 1. Add categories from backend
    for (var cat in _backendCategories) {
      if (cat.name.isNotEmpty) allCats.add(cat.name);
    }
    
    // 2. Add categories from products (as fallback or for uncategorized ones)
    for (var p in products) {
      if (p.categoryName.isNotEmpty) allCats.add(p.categoryName);
    }
    
    final list = allCats.toList();
    list.sort();
    
    // Ensure 'All' is at the beginning
    return ['All', ...list];
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // ─── Search ─────────────────────────────────────────────────────
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ─── Filtered Products ──────────────────────────────────────────
  /// Products filtered by the selected category and search query.
  List<ProductModel> get filteredProducts {
    var list = _products;

    // TEMPORARY: Disable emirate filtering
    // if (_activeEmirate != null && _activeEmirate!.isNotEmpty) {
    //   list = list.where((p) => p.availableEmirates.contains(_activeEmirate!.toLowerCase())).toList();
    // }

    if (_selectedCategory != 'All') {
      list = list.where((p) => p.categoryName == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.categoryName.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  // ─── Trending (Top Rated) ───────────────────────────────────────
  /// Top-rated products (rating > 0), sorted descending by rating.
  List<ProductModel> get trendingProducts {
    final rated = products.where((p) => p.rating > 0).toList();
    rated.sort((a, b) => b.rating.compareTo(a.rating));
    return rated.take(10).toList();
  }

  // ─── On Sale ────────────────────────────────────────────────────
  /// Products that have a discount price set.
  List<ProductModel> get onSaleProducts {
    return products.where((p) => p.discountPrice != null).toList();
  }

  // ─── Fallback Image ─────────────────────────────────────────────
  /// Returns the first real API image found across all loaded products.
  /// Used as a default image for products that have no images yet.
  String get fallbackImageUrl {
    for (final p in _products) {
      if (p.images.isNotEmpty) {
        return p.images.first.image;
      }
    }
    return AppConstants.kDefaultProductImage;
  }

  // ─── Fetching (Offline-First) ────────────────────────────────
  /// Loads products from cache instantly, then silently refreshes
  /// from API in the background if the cache is stale.
  Future<void> fetchProducts({String? emirate}) async {
    // TEMPORARY: ignore emirate parameter
    _activeEmirate = null;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.fetchProducts(
        emirate: null, // Force fetch all
        // This callback fires when background API refresh completes.
        // It updates the product list and the UI seamlessly.
        onRefresh: (freshProducts) {
          _products = freshProducts;
          notifyListeners();
        },
      );
    } catch (e) {
      // Only reaches here if there is NO cache AND the API failed.
      _error = 'failed_load_products';
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads categories from backend (offline-first).
  Future<void> fetchCategories() async {
    _isCategoriesLoading = true;
    _error = null;
    notifyListeners();

    try {
      _backendCategories = await _service.fetchCategories(
        onRefresh: (freshCategories) {
          _backendCategories = freshCategories;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      // We don't necessarily want to set the main _error here 
      // as it might override product loading errors.
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  /// Loads a single product detail, offline-first.
  Future<void> fetchProductDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProduct = await _service.fetchProductDetail(
        id,
        onRefresh: (freshProduct) {
          _selectedProduct = freshProduct;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'failed_load_details';
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Notify Me (Back-in-Stock) ──────────────────────────────
  /// Registers interest in a product. Returns true if successful.
  Future<bool> notifyMe(int productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.notifyMe(productId);
      return success;
    } catch (e) {
      debugPrint('Error requesting notification: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
