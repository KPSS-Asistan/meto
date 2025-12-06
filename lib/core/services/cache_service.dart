import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// In-memory + SharedPreferences cache service
/// ⚡ OPTIMIZED: Singleton SharedPreferences
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // ⚡ Singleton SharedPreferences
  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _sharedPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // In-memory cache (hızlı erişim)
  final Map<String, _CacheEntry> _memoryCache = {};
  
  // Cache süreleri (dakika)
  static const int _defaultTTL = 30; // 30 dakika

  /// Generic cache get
  Future<T?> get<T>(
    String key, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    // 1. Memory cache kontrol et
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      return memoryEntry.data as T?;
    }

    // 2. SharedPreferences kontrol et
    final prefs = await _sharedPrefs;
    final jsonString = prefs.getString(key);
    
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final timestamp = json['timestamp'] as int;
        final ttl = json['ttl'] as int;
        
        // Expire kontrolü
        if (DateTime.now().millisecondsSinceEpoch - timestamp < ttl * 60 * 1000) {
          final data = json['data'];
          
          // Memory cache'e ekle
          _memoryCache[key] = _CacheEntry(
            data: data,
            timestamp: DateTime.now(),
            ttl: ttl,
          );
          
          return fromJson != null && data is Map<String, dynamic>
              ? fromJson(data)
              : data as T?;
        } else {
          // Expire olmuş, sil
          await prefs.remove(key);
        }
      } catch (e) {
        // Parse hatası, sil
        await prefs.remove(key);
      }
    }

    return null;
  }

  /// Generic cache set
  Future<void> set<T>(
    String key,
    T data, {
    int ttl = _defaultTTL,
    Map<String, dynamic> Function(T)? toJson,
  }) async {
    // 1. Memory cache'e ekle
    _memoryCache[key] = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl,
    );

    // 2. SharedPreferences'a ekle
    final prefs = await _sharedPrefs;
    final cacheData = {
      'data': toJson != null ? toJson(data) : data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'ttl': ttl,
    };
    
    await prefs.setString(key, jsonEncode(cacheData));
  }

  /// String cache (basit kullanım)
  Future<String?> getString(String key) async {
    return get<String>(key);
  }

  Future<void> setString(String key, String value, {int ttl = _defaultTTL}) async {
    await set<String>(key, value, ttl: ttl);
  }

  /// List cache
  Future<List<T>?> getList<T>(
    String key, {
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final data = await get<List>(key);
    if (data == null) return null;
    
    return data
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> setList<T>(
    String key,
    List<T> list, {
    required Map<String, dynamic> Function(T) toJson,
    int ttl = _defaultTTL,
  }) async {
    final jsonList = list.map((item) => toJson(item)).toList();
    await set<List>(key, jsonList, ttl: ttl);
  }

  /// Cache invalidate (tek key)
  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    final prefs = await _sharedPrefs;
    await prefs.remove(key);
  }

  /// Cache invalidate (pattern ile)
  Future<void> invalidatePattern(String pattern) async {
    // Memory cache temizle
    _memoryCache.removeWhere((key, _) => key.contains(pattern));
    
    // SharedPreferences temizle
    final prefs = await _sharedPrefs;
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.contains(pattern)) {
        await prefs.remove(key);
      }
    }
  }

  /// Tüm cache'i temizle
  Future<void> clear() async {
    _memoryCache.clear();
    final prefs = await _sharedPrefs;
    await prefs.clear();
  }

  /// Cache boyutunu al (debug için)
  int get memoryCacheSize => _memoryCache.length;

  /// Expire olmuş cache'leri temizle
  Future<void> cleanExpired() async {
    // Memory cache temizle
    _memoryCache.removeWhere((_, entry) => entry.isExpired);
    
    // SharedPreferences temizle
    final prefs = await _sharedPrefs;
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final timestamp = json['timestamp'] as int;
          final ttl = json['ttl'] as int;
          
          if (DateTime.now().millisecondsSinceEpoch - timestamp >= ttl * 60 * 1000) {
            await prefs.remove(key);
          }
        } catch (_) {
          await prefs.remove(key);
        }
      }
    }
  }
}

/// Cache entry (memory cache için)
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final int ttl; // dakika

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired {
    final now = DateTime.now();
    final diff = now.difference(timestamp).inMinutes;
    return diff >= ttl;
  }
}

/// Cache key'leri (merkezi yönetim)
class CacheKeys {
  // User data
  static String userProfile(String userId) => 'user_profile_$userId';
  static String userProgress(String userId) => 'user_progress_$userId';
  static String userStats(String userId) => 'user_stats_$userId';
  
  // Lessons
  static const String lessons = 'lessons_all';
  static String lessonTopics(String lessonId) => 'lesson_topics_$lessonId';
  static String topicModules(String topicId) => 'topic_modules_$topicId';
  
  // Questions
  static String topicQuestions(String topicId) => 'questions_topic_$topicId';
  static String lessonQuestions(String lessonId) => 'questions_lesson_$lessonId';
  
  // Practice
  static String userFavorites(String userId) => 'favorites_$userId';
  static String userWrongAnswers(String userId) => 'wrong_answers_$userId';
  
  // Static data
  static const String techniques = 'study_techniques_all';
  static const String badges = 'badges_all';
}
