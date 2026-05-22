import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// ------------------------------------------------------------------
/// CacheService — A reusable, generic caching layer powered by Hive.
///
/// HOW IT WORKS:
///   • Each cache entry is stored as a Map with two keys:
///       { "data": DATA, "timestamp": TIMESTAMP }
///   • Before calling the API, check the cache:
///       – If valid data exists within the TTL → return it (skip API call).
///       – If expired or missing → fetch from API, then save to cache.
///   • If the API fails, stale cached data (even if expired) can still be
///     returned as a fallback.
///
/// USAGE:
///   // 1. Initialize once at app start (main.dart)
///   await CacheService().init();
///
///   // 2. Save data after an API call
///   CacheService().saveToCache('products', apiResponseData);
///
///   // 3. Read data (returns null if expired or not found)
///   final cached = CacheService().getFromCache('products');
///
///   // 4. Force-read stale data (ignores TTL — useful for offline fallback)
///   final stale = CacheService().getFromCache('products', ignoreExpiry: true);
/// ------------------------------------------------------------------
class CacheService {
  // ─── Singleton ────────────────────────────────────────────────
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  /// The name of the Hive box used for caching API responses.
  static const String _boxName = 'api_cache';

  /// Default cache lifetime — 1 hour.
  static const Duration defaultTTL = Duration(hours: 1);

  /// Reference to the opened Hive box.
  late Box _cacheBox;

  // ─── Initialization ──────────────────────────────────────────
  /// Call this once at app startup (in `main()`) to initialize Hive
  /// and open the cache box.
  Future<void> init() async {
    // Initialize Hive for Flutter (sets up the default storage path).
    await Hive.initFlutter();

    // Open (or create) the cache box.
    _cacheBox = await Hive.openBox(_boxName);
  }

  // ─── Save to Cache ───────────────────────────────────────────
  /// Saves [data] under [key] along with the current timestamp.
  ///
  /// Example:
  /// ```dart
  /// await CacheService().saveToCache('products', jsonList);
  /// ```
  Future<void> saveToCache(String key, dynamic data) async {
    final cacheEntry = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _cacheBox.put(key, cacheEntry);
  }

  // ─── Get from Cache ──────────────────────────────────────────
  /// Returns cached data for [key] if it exists.
  ///
  /// • By default, only returns data that is still within the [ttl]
  ///   (defaults to 1 hour).
  /// • Set [ignoreExpiry] to `true` to return data regardless of age
  ///   (useful as an offline / API-failure fallback).
  /// • Returns `null` if no cached data is found (or if it's expired
  ///   and [ignoreExpiry] is false).
  dynamic getFromCache(
    String key, {
    Duration ttl = defaultTTL,
    bool ignoreExpiry = false,
  }) {
    // Retrieve the raw cache entry from Hive.
    final raw = _cacheBox.get(key);

    // If nothing is stored under this key, return null.
    if (raw == null) return null;

    // Cast to a Map to access 'data' and 'timestamp'.
    // Use _recursiveCast to ensure nested maps are also Map<String, dynamic>.
    final cacheEntry = _recursiveCast(raw) as Map<String, dynamic>;
    final int cachedTimestamp = cacheEntry['timestamp'] as int;

    // If we don't care about expiry, return the data immediately.
    if (ignoreExpiry) {
      return cacheEntry['data'];
    }

    // Check whether the cached entry is still within the TTL.
    final cachedTime =
        DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
    final now = DateTime.now();
    final difference = now.difference(cachedTime);

    if (difference < ttl) {
      // Cache is still fresh → return it.
      return cacheEntry['data'];
    }

    // Cache has expired → return null so the caller fetches fresh data.
    return null;
  }

  /// ─── Helper: Recursive Cast ──────────────────────────────────
  /// Hive stores maps as `Map<dynamic, dynamic>`. This helper
  /// recursively converts them to `Map<String, dynamic>`.
  dynamic _recursiveCast(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), _recursiveCast(val)));
    } else if (value is List) {
      return value.map(_recursiveCast).toList();
    }
    return value;
  }

  // ─── Clear Cache ─────────────────────────────────────────────
  /// Removes the cache entry stored under [key].
  Future<void> clearCache(String key) async {
    await _cacheBox.delete(key);
  }

  /// Removes ALL cache entries.
  Future<void> clearAllCache() async {
    try {
      // 1. Clear Hive Storage
      await _cacheBox.clear();
      
      // 2. Clear Flutter Image Cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
    } catch (e) {
      // Silent fail or log
      debugPrint('Error clearing cache: $e');
    }
  }

  // ─── Has Cache ───────────────────────────────────────────────
  /// Returns `true` if ANY cached data exists for [key],
  /// regardless of whether it's expired or not.
  /// Useful for deciding if the app can run in offline mode.
  bool hasCache(String key) {
    return _cacheBox.get(key) != null;
  }
}
