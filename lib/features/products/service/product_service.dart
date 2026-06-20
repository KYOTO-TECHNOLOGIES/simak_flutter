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
    String? categoryName,
    void Function(List<ProductModel>)? onRefresh,
  }) async {
    // ── Step 0: Construct accurate cache key ────────────────────
    String cacheKey = _productsCacheKey;
    if (emirate != null) cacheKey += '_$emirate';
    if (categoryName != null && categoryName != 'All') cacheKey += '_cat_$categoryName';

    // ── Step 1: Try to return cached data instantly ─────────────
    final cachedData = _cache.getFromCache(
      cacheKey,
      ignoreExpiry: true, // Return data regardless of age.
    );

    if (cachedData != null) {
      debugPrint('✅ Loaded products from Cache: $cacheKey');
      final cachedProducts = _parseProductList(cachedData);

      // Check if cache is still fresh → if fresh, we still trigger refresh
      // if explicitly asked (e.g. on click), but otherwise save bandwidth.
      final freshData = _cache.getFromCache(cacheKey);
      if (freshData != null) {
        debugPrint('   ↳ Cache is fresh, but updating silently in background');
      }

      // Triger refresh in background to ensure data is always eventually consistent.
      _refreshProductsInBackground(
        emirate: emirate,
        categoryName: categoryName,
        onRefresh: onRefresh,
      );

      // Return stale/cached data immediately so UI is never blank.
      return cachedProducts;
    }

    // ── Step 2: No cache at all → must call API ────────────────
    debugPrint('📡 No cache for $cacheKey, fetching from API...');
    try {
      final products = await _fetchProductsFromApi(
        emirate: emirate,
        categoryName: categoryName,
      );
      debugPrint('🌐 Fetched products from API (first load)');
      return products;
    } catch (e) {
      debugPrint('❌ No cache and FETCH failed: $e');
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

  /// Public entry point for a forced (non-cached) product fetch.
  /// Called by [ProductController.fetchProducts] when [forceRefresh] is true,
  /// e.g. during pull-to-refresh, so the spinner waits for real API data.
  Future<List<ProductModel>> fetchProductsFromApi({
    String? emirate,
    String? categoryName,
  }) =>
      _fetchProductsFromApi(emirate: emirate, categoryName: categoryName);

  /// Fetches ALL products from the API (following pagination) and saves to cache.
  Future<List<ProductModel>> _fetchProductsFromApi({
    String? emirate,
    String? categoryName,
  }) async {
    final Map<String, dynamic> initialQueryParameters = {};
    if (emirate != null) initialQueryParameters['available_emirates'] = emirate;
    if (categoryName != null && categoryName != 'All') {
      initialQueryParameters['category_name'] = categoryName;
    }

    final List<dynamic> allRaw = [];
    // nextUrl starts as null — first request uses the base endpoint + query params.
    String? nextUrl;
    bool isFirstPage = true;

    // Loop through all pages until there is no 'next' URL.
    do {
      final Response<dynamic> response;
      if (isFirstPage) {
        response = await _dio.get(
          'products/products/',
          queryParameters: initialQueryParameters,
        );
        isFirstPage = false;
      } else {
        // The 'next' field from DRF is a full absolute URL.
        // Extract just the path+query to avoid Dio prepending baseUrl again.
        final uri = Uri.parse(nextUrl!);
        final relativeUrl = uri.path.replaceFirst(RegExp(r'^/api/'), '') +
            (uri.query.isNotEmpty ? '?${uri.query}' : '');
        response = await _dio.get(relativeUrl);
      }

      final data = response.data;

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        allRaw.addAll(data['results'] as List);
        // 'next' is either a URL string or null when we're on the last page.
        nextUrl = data['next'] as String?;
      } else if (data is List) {
        allRaw.addAll(data);
        nextUrl = null; // Non-paginated list — only one page.
      } else {
        nextUrl = null;
      }
    } while (nextUrl != null);

    // Save the complete result set to cache.
    String cacheKey = _productsCacheKey;
    if (emirate != null) cacheKey += '_$emirate';
    if (categoryName != null && categoryName != 'All') cacheKey += '_cat_$categoryName';

    await _cache.saveToCache(cacheKey, allRaw);
    debugPrint('📦 Fetched ${allRaw.length} products total for key: $cacheKey');
    return allRaw.map((e) => ProductModel.fromJson(e)).toList();
  }

  /// Silently refreshes products from API in the background.
  void _refreshProductsInBackground({
    String? emirate,
    String? categoryName,
    void Function(List<ProductModel>)? onRefresh,
  }) {
    _fetchProductsFromApi(
      emirate: emirate,
      categoryName: categoryName,
    ).then((freshProducts) {
      debugPrint('🔄 Background refresh complete — products updated');
      onRefresh?.call(freshProducts);
    }).catchError((e) {
      debugPrint('⚠️ Background refresh failed, keeping stale cache: $e');
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
