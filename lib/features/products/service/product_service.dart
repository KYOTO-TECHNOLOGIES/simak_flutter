import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';
import 'package:uae_ecom_project/features/products/model/product_model.dart';
import 'package:uae_ecom_project/features/products/model/category_model.dart';
import 'package:uae_ecom_project/service/cache_service.dart';

/// ------------------------------------------------------------------
/// ProductService — Handles product-related API calls with
/// OFFLINE-FIRST caching.
///
/// STRATEGY (offline-first):
///   1. ALWAYS return cached data instantly (even if stale) so the
///      UI is never blank.
///   2. If the cache is still fresh (within 1 hour) → done.
///   3. If the cache is stale (or missing) → try API in background.
///   4. If API succeeds → update cache + notify UI via [onRefresh].
///   5. If API fails → keep using old cached data silently.
///   6. Only throw an error when there is NO cache AND the API fails.
/// ------------------------------------------------------------------
class ProductService {
  final Dio _dio = ApiClient().dio;
  final CacheService _cache = CacheService();

  // ─── Cache Keys ──────────────────────────────────────────────
  static const String _productsCacheKey = 'products';
  static const String _categoriesCacheKey = 'categories';
  static String _productDetailCacheKey(int id) => 'product_$id';

  // ─── Fetch Products (offline-first) ──────────────────────────
  /// Returns products from cache immediately, then optionally
  /// refreshes from API in the background.
  ///
  /// [onRefresh] is called if the API returns newer data so the
  /// controller can update the UI without blocking.
  Future<List<ProductModel>> fetchProducts({
    String? emirate,
    void Function(List<ProductModel>)? onRefresh,
  }) async {
    final cacheKey = emirate != null ? '${_productsCacheKey}_$emirate' : _productsCacheKey;

    // ── Step 1: Try to return cached data instantly ─────────────
    final cachedData = _cache.getFromCache(
      cacheKey,
      ignoreExpiry: true, // Return data regardless of age.
    );

    if (cachedData != null) {
      debugPrint('✅ Loaded products from Cache (offline-first)');
      final cachedProducts = _parseProductList(cachedData);

      // Check if cache is still fresh → no need to call API.
      final freshData = _cache.getFromCache(cacheKey);
      if (freshData != null) {
        debugPrint('   ↳ Cache is fresh, skipping API call');
        return cachedProducts;
      }

      // Cache is stale → try refreshing from API in background.
      debugPrint('   ↳ Cache is stale, refreshing in background...');
      _refreshProductsInBackground(emirate, onRefresh);

      // Return stale cached data immediately so UI is never blank.
      return cachedProducts;
    }

    // ── Step 2: No cache at all → must call API ────────────────
    debugPrint('📡 No cache found, fetching products from API...');
    try {
      final products = await _fetchProductsFromApi(emirate: emirate);
      debugPrint('🌐 Fetched products from API (first load)');
      return products;
    } catch (e) {
      // No cache AND API failed → nothing to show.
      debugPrint('❌ No cache and API failed — showing error');
      rethrow;
    }
  }

  // ─── Fetch Categories (offline-first) ────────────────────────
  Future<List<CategoryModel>> fetchCategories({
    void Function(List<CategoryModel>)? onRefresh,
  }) async {
    const cacheKey = _categoriesCacheKey;

    // ── Step 1: Cache retrieval
    final cachedData = _cache.getFromCache(cacheKey, ignoreExpiry: true);
    if (cachedData != null) {
      debugPrint('✅ Loaded categories from Cache');
      final cachedCategories = (cachedData as List)
          .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final freshData = _cache.getFromCache(cacheKey);
      if (freshData == null) {
        debugPrint('   ↳ Cache is stale, refreshing categories in background...');
        _refreshCategoriesInBackground(onRefresh);
      }
      return cachedCategories;
    }

    // ── Step 2: API fetch
    debugPrint('📡 No cache for categories, fetching from API...');
    try {
      return await _fetchCategoriesFromApi();
    } catch (e) {
      debugPrint('❌ No cache and category API failed');
      rethrow;
    }
  }

  // ─── Fetch Product Detail (offline-first) ────────────────────
  /// Returns details for a single product, cache-first.
  ///
  /// [onRefresh] is called if a newer version is fetched from API.
  Future<ProductModel> fetchProductDetail(
    int id, {
    void Function(ProductModel)? onRefresh,
  }) async {
    final cacheKey = _productDetailCacheKey(id);

    // ── Step 1: Try to return cached data instantly ─────────────
    final cachedData = _cache.getFromCache(cacheKey, ignoreExpiry: true);

    if (cachedData != null) {
      debugPrint('✅ Loaded product #$id from Cache');
      final cachedProduct = ProductModel.fromJson(
        Map<String, dynamic>.from(cachedData as Map),
      );

      // Check if cache is still fresh.
      final freshData = _cache.getFromCache(cacheKey);
      if (freshData != null) {
        debugPrint('   ↳ Cache is fresh, skipping API call');
        return cachedProduct;
      }

      // Cache is stale → try refreshing in background.
      debugPrint('   ↳ Cache is stale, refreshing in background...');
      _refreshProductDetailInBackground(id, onRefresh);

      return cachedProduct;
    }

    // ── Step 2: No cache → must call API ───────────────────────
    debugPrint('📡 No cache for product #$id, fetching from API...');
    try {
      final response = await _dio.get('products/products/$id/');
      await _cache.saveToCache(cacheKey, response.data);
      debugPrint('🌐 Fetched product #$id from API');
      return ProductModel.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ No cache and API failed for product #$id');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Fetches the product list from the API and saves it to cache.
  Future<List<ProductModel>> _fetchProductsFromApi({String? emirate}) async {
    final String url = emirate != null 
        ? 'products/products/?available_emirates=$emirate' 
        : 'products/products/';
        
    final response = await _dio.get(url);
    final data = response.data;

    final List<dynamic> rawList;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      rawList = data['results'] as List;
    } else if (data is List) {
      rawList = data;
    } else {
      rawList = [];
    }

    // Save to cache.
    final cacheKey = emirate != null ? '${_productsCacheKey}_$emirate' : _productsCacheKey;
    await _cache.saveToCache(cacheKey, rawList);
    return rawList.map((e) => ProductModel.fromJson(e)).toList();
  }

  /// Silently refreshes products from API in the background.
  /// If successful, saves to cache and calls [onRefresh].
  /// If it fails, does nothing — old cached data stays in use.
  void _refreshProductsInBackground(
    String? emirate,
    void Function(List<ProductModel>)? onRefresh,
  ) {
    _fetchProductsFromApi(emirate: emirate).then((freshProducts) {
      debugPrint('🔄 Background refresh complete — products updated');
      onRefresh?.call(freshProducts);
    }).catchError((e) {
      // API failed silently — keep using stale cache.
      debugPrint('⚠️ Background refresh failed, keeping stale cache');
    });
  }

  /// Silently refreshes a single product detail in the background.
  void _refreshProductDetailInBackground(
    int id,
    void Function(ProductModel)? onRefresh,
  ) {
    final cacheKey = _productDetailCacheKey(id);
    _dio.get('products/products/$id/').then((response) async {
      await _cache.saveToCache(cacheKey, response.data);
      debugPrint('🔄 Background refresh complete — product #$id updated');
      onRefresh?.call(ProductModel.fromJson(response.data));
    }).catchError((e) {
      debugPrint('⚠️ Background refresh failed for product #$id');
    });
  }

  /// Parses a raw dynamic list into a typed list of [ProductModel].
  List<ProductModel> _parseProductList(dynamic rawData) {
    final list = rawData as List;
    return list
        .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Fetches categories from API and saves to cache.
  Future<List<CategoryModel>> _fetchCategoriesFromApi() async {
    final response = await _dio.get('products/categories/');
    final data = response.data;

    final List<dynamic> rawList;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      rawList = data['results'] as List;
    } else if (data is List) {
      rawList = data;
    } else {
      rawList = [];
    }

    await _cache.saveToCache(_categoriesCacheKey, rawList);
    return rawList.map((e) => CategoryModel.fromJson(e)).toList();
  }

  /// Silently refreshes categories in background.
  void _refreshCategoriesInBackground(
    void Function(List<CategoryModel>)? onRefresh,
  ) {
    _fetchCategoriesFromApi().then((freshCategories) {
      debugPrint('🔄 Background refresh complete — categories updated');
      onRefresh?.call(freshCategories);
    }).catchError((e) {
      debugPrint('⚠️ Background refresh failed for categories');
    });
  }

  // ─── Notify Me (Back-in-Stock) ──────────────────────────────
  /// Registers the user's interest in an out-of-stock product.
  /// POST /api/products/products/{id}/notify_stock/
  Future<bool> notifyMe(int productId) async {
    try {
      final response = await _dio.post('products/products/$productId/notify_stock/');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ Failed to register for back-in-stock notification: $e');
      return false;
    }
  }
}
