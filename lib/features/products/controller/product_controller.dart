import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/core/config/app_constants.dart';
import 'package:uae_ecom_project/core/localization/language_provider.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/model/category_model.dart';
import 'package:uae_ecom_project/features/products/service/product_service.dart';

class ProductController extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<ProductModel> _products = [];
  List<ProductModel> _allProducts = []; // Always "All" category products

  List<ProductModel> get products => _products;
  List<ProductModel> get allProducts => _allProducts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ─── Backend Categories ─────────────────────────────────────────
  List<CategoryModel> _backendCategories = [];
  List<CategoryModel> get backendCategories => _backendCategories;

  bool _isCategoriesLoading = false;
  bool get isCategoriesLoading => _isCategoriesLoading;

  /// Returns the localized category name from the backend category models.
  /// If the categoryName is 'All', it translates 'All'.
  /// If not found in backend categories, returns the original categoryName.
  String getLocalizedCategoryName(BuildContext context, String categoryName) {
    if (categoryName.trim().isEmpty) return '';
    if (categoryName == 'All') {
      return tr(context, 'All');
    }
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final locale = langProvider.locale;
    
    for (var cat in _backendCategories) {
      if (cat.name.toLowerCase() == categoryName.toLowerCase()) {
        return cat.getLocalizedName(locale);
      }
    }
    return categoryName;
  }

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
      if (cat.name.isNotEmpty && cat.name != 'All') allCats.add(cat.name);
    }
    
    // 2. Add categories from products (as fallback or for uncategorized ones)
    for (var p in products) {
      if (p.categoryName.isNotEmpty && p.categoryName != 'All') allCats.add(p.categoryName);
    }
    
    final list = allCats.toList();
    
    // Custom sort order requested by business
    const customOrder = ['Live Fish', 'Fresh Fish', 'Frozen Fish', 'Dry Fish'];
    
    list.sort((a, b) {
      final indexA = customOrder.indexOf(a);
      final indexB = customOrder.indexOf(b);
      
      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      } else if (indexA != -1) {
        return -1; // a is in custom list, b is not -> a comes first
      } else if (indexB != -1) {
        return 1; // b is in custom list, a is not -> b comes first
      } else {
        // Fallback to alphabetical for any other categories
        return a.compareTo(b);
      }
    });
    
    // Ensure 'All' is always at the very beginning
    return ['All', ...list];
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
    
    // Trigger fresh fetch for the newly selected category.
    // This will show cache first, then refresh from API.
    fetchProducts(categoryName: category);
  }

  // ─── Search ─────────────────────────────────────────────────────
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Resets all filters to default (All categories, empty search).
  void clearFilters() {
    _selectedCategory = 'All';
    _searchQuery = '';
    notifyListeners();
    
    // Refresh products to show 'All'
    fetchProducts(categoryName: 'All');
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
  /// Loads products (offline-first). Shows cache instantly, then updates via API.
  Future<void> fetchProducts({String? emirate, String? categoryName}) async {
    final cat = categoryName ?? _selectedCategory;
    
    // TEMPORARY: ignore emirate parameter
    _activeEmirate = null;
    
    // If we have no items at all, show the main loading spinner.
    // If we already have items (cached or from previous fetch), we load silently.
    if (_products.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final freshProducts = await _service.fetchProducts(
        emirate: null, // Force fetch all
        categoryName: cat,
        // This callback fires when background API refresh completes.
        onRefresh: (refreshedData) {
          _products = refreshedData;
          if (cat == 'All') {
            _allProducts = refreshedData;
          }
          notifyListeners();
        },
      );
      
      // Set the initial (cached or first-fetch) data
      _products = freshProducts;
      if (cat == 'All') {
        _allProducts = freshProducts;
      }
      notifyListeners();
    } catch (e) {
      // Only error out if we have absolutely no data to show.
      if (_products.isEmpty) {
        _error = 'failed_load_products';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Specifically fetches "All" products for the Home screen Popular Now section.
  /// This ensures Home products are cached independently of any active category filter.
  Future<void> fetchHomeProducts() async {
    try {
      final freshProducts = await _service.fetchProducts(
        emirate: null,
        categoryName: 'All',
        onRefresh: (refreshedData) {
          _allProducts = refreshedData;
          notifyListeners();
        },
      );
      _allProducts = freshProducts;
      notifyListeners();
    } catch (e) {
      debugPrint('Error in fetchHomeProducts: $e');
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
