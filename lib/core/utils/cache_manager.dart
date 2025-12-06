import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache manager for performance optimization - Academic Premium style
/// ⚡ OPTIMIZED: Lazy initialization - No blocking on startup!
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  SharedPreferences? _prefs;
  bool _isInitializing = false;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  /// ⚡ LAZY INIT: İlk kullanımda başlat
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) return _prefs!;
    
    if (!_isInitializing) {
      _isInitializing = true;
      _prefs = await SharedPreferences.getInstance();
      _isInitializing = false;
    } else {
      // Başka bir init çalışıyorsa bekle
      while (_prefs == null) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    return _prefs!;
  }

  /// Initialize cache manager (optional - for pre-warming)
  Future<void> init() async {
    await _getPrefs();
  }

  /// Get from cache (memory first, then disk) - ⚡ NO LOGS
  T? get<T>(String key, {Duration? maxAge}) {
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      if (maxAge != null && _cacheTimestamps.containsKey(key)) {
        final timestamp = _cacheTimestamps[key]!;
        if (DateTime.now().difference(timestamp) > maxAge) {
          _memoryCache.remove(key);
          _cacheTimestamps.remove(key);
        } else {
          return _memoryCache[key] as T;
        }
      } else {
        return _memoryCache[key] as T;
      }
    }

    // Check disk cache
    if (_prefs == null) return null;

    try {
      final value = _prefs!.get(key);
      if (value != null) {
        _memoryCache[key] = value;
        _cacheTimestamps[key] = DateTime.now();
        return value as T;
      }
    } catch (_) {}

    return null;
  }

  /// Set cache (memory and disk) - ⚡ NO LOGS
  Future<void> set<T>(String key, T value) async {
    _memoryCache[key] = value;
    _cacheTimestamps[key] = DateTime.now();

    if (_prefs == null) return;

    try {
      if (value is String) {
        await _prefs!.setString(key, value);
      } else if (value is int) {
        await _prefs!.setInt(key, value);
      } else if (value is double) {
        await _prefs!.setDouble(key, value);
      } else if (value is bool) {
        await _prefs!.setBool(key, value);
      } else if (value is List<String>) {
        await _prefs!.setStringList(key, value);
      } else {
        await _prefs!.setString(key, jsonEncode(value));
      }
    } catch (_) {}
  }

  /// Remove from cache
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    await _prefs?.remove(key);
  }

  /// Clear all cache
  Future<void> clear() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    await _prefs?.clear();
  }

  /// Clear expired cache
  Future<void> clearExpired(Duration maxAge) async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > maxAge) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      await remove(key);
    }
  }

  /// Get cache size
  int get memoryCacheSize => _memoryCache.length;

  /// Get cache keys
  List<String> get keys => _memoryCache.keys.toList();

  /// Check if key exists
  bool contains(String key) {
    return _memoryCache.containsKey(key) || (_prefs?.containsKey(key) ?? false);
  }
}

/// Cache keys constants
class CacheKeys {
  static const String userDisplayName = 'user_display_name';
  static const String userAvatar = 'user_avatar';
  static const String studyStreak = 'study_streak';
  static const String lastSyncTime = 'last_sync_time';
  static const String themeMode = 'theme_mode';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String onboardingCompleted = 'onboarding_completed';
  
  // Lesson cache
  static String lessonCache(String lessonId) => 'lesson_$lessonId';
  static String topicCache(String topicId) => 'topic_$topicId';
  static String progressCache(String userId) => 'progress_$userId';
}
