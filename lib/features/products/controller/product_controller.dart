import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/config/app_constants.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/service/product_service.dart';

class ProductController extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<ProductModel> _products = [];
  List<ProductModel> get products {
    if (_activeEmirate == null || _activeEmirate!.isEmpty) return _products;
    return _products.where((p) => p.availableEmirates.contains(_activeEmirate!.toLowerCase())).toList();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Selected product for detail view
  ProductModel? _selectedProduct;
  ProductModel? get selectedProduct => _selectedProduct;

  // ─── Emirate Filter ─────────────────────────────────────────────
  String? _activeEmirate;
  String? get activeEmirate => _activeEmirate;

  // ─── Category Filter ────────────────────────────────────────────
  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  /// Unique category names extracted from loaded products.
  List<String> get categories {
    final cats = products
        .map((p) => p.categoryName)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    cats.sort();
    return ['All', ...cats];
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

    if (_activeEmirate != null && _activeEmirate!.isNotEmpty) {
      list = list.where((p) => p.availableEmirates.contains(_activeEmirate!.toLowerCase())).toList();
    }

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
    _activeEmirate = emirate;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.fetchProducts(
        emirate: emirate,
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
}
