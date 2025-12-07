/// Hive Cache Service
/// Provides offline caching for app data using Hive
library;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Debug logger
void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// Cache box names
class CacheBoxes {
  static const String issues = 'issues_cache';
  static const String announcements = 'announcements_cache';
  static const String bursaries = 'bursaries_cache';
  static const String emergencyContacts = 'emergency_contacts_cache';
  static const String appConfig = 'app_config_cache';
  static const String userProfile = 'user_profile_cache';
}

/// Offline cache service using Hive
class HiveCacheService {
  static bool _initialized = false;

  // Cache TTL in milliseconds
  static const int _defaultTtl = 30 * 60 * 1000; // 30 minutes
  static const int _shortTtl = 5 * 60 * 1000; // 5 minutes
  static const int _longTtl = 2 * 60 * 60 * 1000; // 2 hours

  /// Initialize Hive for Flutter
  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      await Hive.initFlutter();
      
      // Open all cache boxes
      await Hive.openBox<dynamic>(CacheBoxes.issues);
      await Hive.openBox<dynamic>(CacheBoxes.announcements);
      await Hive.openBox<dynamic>(CacheBoxes.bursaries);
      await Hive.openBox<dynamic>(CacheBoxes.emergencyContacts);
      await Hive.openBox<dynamic>(CacheBoxes.appConfig);
      await Hive.openBox<dynamic>(CacheBoxes.userProfile);
      
      _initialized = true;
      _debugLog('✅ Hive cache initialized');
    } catch (e) {
      _debugLog('❌ Hive init error: $e');
    }
  }

  /// Check if device is online
  static Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Generate cache key with timestamp
  static Map<String, dynamic> _wrapWithMeta(dynamic data, {int? ttl}) {
    return {
      'data': data,
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
      'ttl': ttl ?? _defaultTtl,
    };
  }

  /// Check if cached data is still valid
  static bool _isValid(Map<String, dynamic>? cached) {
    if (cached == null) return false;
    
    final cachedAt = cached['cachedAt'] as int?;
    final ttl = cached['ttl'] as int? ?? _defaultTtl;
    
    if (cachedAt == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - cachedAt) < ttl;
  }

  // ============ GENERIC CACHE OPERATIONS ============

  /// Store data in cache
  static Future<void> put(String boxName, String key, dynamic data, {int? ttl}) async {
    try {
      final box = Hive.box<dynamic>(boxName);
      await box.put(key, _wrapWithMeta(data, ttl: ttl));
      _debugLog('💾 Cached: $boxName/$key');
    } catch (e) {
      _debugLog('❌ Cache put error: $e');
    }
  }

  /// Get data from cache (returns null if expired or not found)
  static dynamic get(String boxName, String key, {bool ignoreExpiry = false}) {
    try {
      final box = Hive.box<dynamic>(boxName);
      final cached = box.get(key);
      
      if (cached == null) return null;
      
      if (cached is Map<String, dynamic>) {
        if (ignoreExpiry || _isValid(cached)) {
          return cached['data'];
        } else {
          _debugLog('⏰ Cache expired: $boxName/$key');
          return null;
        }
      }
      
      return cached;
    } catch (e) {
      _debugLog('❌ Cache get error: $e');
      return null;
    }
  }

  /// Delete specific cache entry
  static Future<void> delete(String boxName, String key) async {
    try {
      final box = Hive.box<dynamic>(boxName);
      await box.delete(key);
    } catch (e) {
      _debugLog('❌ Cache delete error: $e');
    }
  }

  /// Clear all entries in a box
  static Future<void> clearBox(String boxName) async {
    try {
      final box = Hive.box<dynamic>(boxName);
      await box.clear();
      _debugLog('🗑️ Cleared cache: $boxName');
    } catch (e) {
      _debugLog('❌ Cache clear error: $e');
    }
  }

  /// Clear all caches
  static Future<void> clearAll() async {
    try {
      await clearBox(CacheBoxes.issues);
      await clearBox(CacheBoxes.announcements);
      await clearBox(CacheBoxes.bursaries);
      await clearBox(CacheBoxes.emergencyContacts);
      await clearBox(CacheBoxes.appConfig);
      _debugLog('🗑️ All caches cleared');
    } catch (e) {
      _debugLog('❌ Clear all error: $e');
    }
  }

  // ============ SPECIALIZED CACHE METHODS ============

  /// Cache user's issues
  static Future<void> cacheMyIssues(String userId, List<Map<String, dynamic>> issues) async {
    await put(CacheBoxes.issues, 'user_$userId', issues, ttl: _shortTtl);
  }

  /// Get cached issues for user
  static List<Map<String, dynamic>>? getCachedIssues(String userId) {
    final data = get(CacheBoxes.issues, 'user_$userId');
    if (data != null && data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }

  /// Cache announcements
  static Future<void> cacheAnnouncements(List<Map<String, dynamic>> announcements) async {
    await put(CacheBoxes.announcements, 'active', announcements, ttl: _defaultTtl);
  }

  /// Get cached announcements
  static List<Map<String, dynamic>>? getCachedAnnouncements() {
    final data = get(CacheBoxes.announcements, 'active');
    if (data != null && data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }

  /// Cache bursary applications
  static Future<void> cacheBursaries(String userId, List<Map<String, dynamic>> bursaries) async {
    await put(CacheBoxes.bursaries, 'user_$userId', bursaries, ttl: _defaultTtl);
  }

  /// Get cached bursaries
  static List<Map<String, dynamic>>? getCachedBursaries(String userId) {
    final data = get(CacheBoxes.bursaries, 'user_$userId');
    if (data != null && data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }

  /// Cache emergency contacts
  static Future<void> cacheEmergencyContacts(List<Map<String, dynamic>> contacts) async {
    await put(CacheBoxes.emergencyContacts, 'all', contacts, ttl: _longTtl);
  }

  /// Get cached emergency contacts
  static List<Map<String, dynamic>>? getCachedEmergencyContacts() {
    final data = get(CacheBoxes.emergencyContacts, 'all');
    if (data != null && data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return null;
  }

  /// Cache app config
  static Future<void> cacheAppConfig(Map<String, dynamic> config) async {
    await put(CacheBoxes.appConfig, 'config', config, ttl: _longTtl);
  }

  /// Get cached app config
  static Map<String, dynamic>? getCachedAppConfig() {
    final data = get(CacheBoxes.appConfig, 'config');
    if (data != null && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /// Cache user profile
  static Future<void> cacheUserProfile(String userId, Map<String, dynamic> profile) async {
    await put(CacheBoxes.userProfile, userId, profile, ttl: _longTtl);
  }

  /// Get cached user profile
  static Map<String, dynamic>? getCachedUserProfile(String userId) {
    final data = get(CacheBoxes.userProfile, userId);
    if (data != null && data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  // ============ OFFLINE-FIRST HELPERS ============

  /// Get data with offline fallback
  /// First tries to fetch fresh data, falls back to cache if offline/error
  static Future<T?> getWithOfflineFallback<T>({
    required Future<T?> Function() fetchFresh,
    required T? Function() getFromCache,
    required Future<void> Function(T data) saveToCache,
  }) async {
    final online = await isOnline();
    
    if (online) {
      try {
        final freshData = await fetchFresh();
        if (freshData != null) {
          await saveToCache(freshData);
          return freshData;
        }
      } catch (e) {
        _debugLog('⚠️ Fetch failed, using cache: $e');
      }
    }
    
    // Fallback to cache
    final cached = getFromCache();
    if (cached != null) {
      _debugLog('📱 Using cached data (offline mode)');
    }
    return cached;
  }

  /// Get cache statistics
  static Map<String, dynamic> getStats() {
    try {
      return {
        'issues': Hive.box<dynamic>(CacheBoxes.issues).length,
        'announcements': Hive.box<dynamic>(CacheBoxes.announcements).length,
        'bursaries': Hive.box<dynamic>(CacheBoxes.bursaries).length,
        'emergencyContacts': Hive.box<dynamic>(CacheBoxes.emergencyContacts).length,
        'appConfig': Hive.box<dynamic>(CacheBoxes.appConfig).length,
        'userProfile': Hive.box<dynamic>(CacheBoxes.userProfile).length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
