import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/topic_explanation_model.dart';
import '../utils/app_logger.dart';
import '../data/explanations_data.dart';
import 'explanation_repository.dart';

/// Cached Explanation Repository - Önce hardcoded, sonra Firebase
/// Hardcoded veri varsa onu kullanır, yoksa Firebase'den çeker
/// ⚡ OPTIMIZED: Singleton SharedPreferences + Memory cache
class CachedExplanationRepository {
  final ExplanationRepository _firebaseRepo;
  static const String _cachePrefix = 'explanation_cache_';
  static const String _cacheTimestampPrefix = 'explanation_timestamp_';
  static const Duration _cacheExpiry = Duration(days: 30); // 30 gün cache
  
  // ⚡ SINGLETON: SharedPreferences instance
  static SharedPreferences? _prefs;
  
  // ⚡ MEMORY CACHE: Hardcoded explanations
  static final Map<String, TopicExplanationModel> _memoryCache = {};

  CachedExplanationRepository({required FirebaseFirestore firestore})
      : _firebaseRepo = ExplanationRepository(firestore: firestore);
  
  // ⚡ Singleton getter
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<TopicExplanationModel?> getTopicExplanation(String topicId) async {
    // ⚡ 0. Memory cache'e bak (en hızlı)
    if (_memoryCache.containsKey(topicId)) {
      return _memoryCache[topicId];
    }
    
    // 1. Önce hardcoded veriye bak
    final hardcoded = _getHardcodedExplanation(topicId);
    if (hardcoded != null) {
      _memoryCache[topicId] = hardcoded; // Memory cache'e ekle
      return hardcoded;
    }
    
    // 2. Hardcoded yoksa SharedPrefs cache'e bak
    final cached = await _getCachedExplanation(topicId);
    if (cached != null) {
      _memoryCache[topicId] = cached; // Memory cache'e ekle
      _checkForUpdates(topicId);
      return cached;
    }
    
    // 3. Cache yoksa Firebase'den çek
    try {
      final explanation = await _firebaseRepo.getTopicExplanation(topicId);
      
      if (explanation != null) {
        _memoryCache[topicId] = explanation; // Memory cache'e ekle
        await _cacheExplanation(topicId, explanation);
      }
      
      return explanation;
    } catch (e) {
      AppLogger.error('Cached explanation fetch failed', e);
      rethrow;
    }
  }

  /// Hardcoded veriden explanation oluştur
  /// Her section (title + content) tek bir sayfa olarak gösterilir
  TopicExplanationModel? _getHardcodedExplanation(String topicId) {
    final data = ExplanationsData.getExplanation(topicId);
    if (data == null || data.isEmpty) return null;

    final sections = <ExplanationSection>[];
    
    for (var i = 0; i < data.length; i++) {
      final sectionData = data[i];
      final sectionTitle = sectionData['title'] as String? ?? 'Bölüm ${i + 1}';
      final contentList = sectionData['content'] as List<dynamic>? ?? [];
      
      // Tüm content'i tek bir section'da topla
      // Bullet'ları • ile işaretleyerek paragraphs içine ekle
      final List<String> allParagraphs = [];
      final List<int> headingIndexes = [];

      void addHeading(String text) {
        if (text.isEmpty) return;
        headingIndexes.add(allParagraphs.length);
        allParagraphs.add(text);
      }
      
      for (final item in contentList) {
        if (item is! Map<String, dynamic>) continue;
        
        final type = item['type'] as String? ?? 'text';
        
        switch (type) {
          case 'heading':
            final text = item['text'] as String? ?? '';
            addHeading(text);
            break;
          case 'text':
            final text = item['text'] as String? ?? '';
            if (text.isNotEmpty) allParagraphs.add(text);
            break;
          case 'bulletList':
            final items = item['items'] as List<dynamic>? ?? [];
            for (final bullet in items) {
              if (bullet is String && bullet.isNotEmpty) {
                // Bullet'ı • ile işaretle
                allParagraphs.add('• $bullet');
              }
            }
            break;
          case 'highlighted':
            final text = item['text'] as String? ?? '';
            if (text.isNotEmpty) allParagraphs.add('**$text**');
            break;
          case 'tip':
            final text = item['text'] as String? ?? '';
            if (text.isNotEmpty) allParagraphs.add('💡 $text');
            break;
          case 'warning':
            final text = item['text'] as String? ?? '';
            if (text.isNotEmpty) allParagraphs.add('⚠️ $text');
            break;
          case 'example':
            final text = item['text'] as String? ?? '';
            if (text.isNotEmpty) allParagraphs.add('📝 $text');
            break;
          case 'table':
            final headers = item['headers'] as List<dynamic>? ?? [];
            final rows = item['rows'] as List<dynamic>? ?? [];
            if (headers.isNotEmpty) {
              addHeading(headers.join(' | '));
            }
            for (final row in rows) {
              if (row is List) {
                allParagraphs.add('• ${row.join(': ')}');
              }
            }
            break;
        }
      }
      
      // Section'ı ekle (içerik varsa)
      if (allParagraphs.isNotEmpty) {
        sections.add(ExplanationSection(
          title: sectionTitle,
          paragraphs: allParagraphs,
          bullets: const [], // Artık bullets kullanmıyoruz
          order: sections.length,
          headingIndexes: headingIndexes,
        ));
      }
    }

    if (sections.isEmpty) return null;

    return TopicExplanationModel(
      id: topicId,
      topicId: topicId,
      lessonId: 'tarih',
      sections: sections,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  // Arka planda güncelleme kontrolü
  Future<void> _checkForUpdates(String topicId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Güncelleme flag'ini kontrol et
      final updateDoc = await firestore
          .collection('app_updates')
          .doc('explanations')
          .get();
      
      if (updateDoc.exists) {
        final data = updateDoc.data()!;
        final updateAvailable = data['update_available'] as bool? ?? false;
        
        if (updateAvailable) {
          final explanation = await _firebaseRepo.getTopicExplanation(topicId);
          if (explanation != null) {
            await _cacheExplanation(topicId, explanation);
          }
        }
      }
    } catch (e) {
      AppLogger.error('Explanation update check failed', e);
    }
  }

  /// Cache'den explanation oku
  Future<TopicExplanationModel?> _getCachedExplanation(String topicId, {bool ignoreExpiry = false}) async {
    try {
      final prefs = await _instance; // ⚡ Singleton kullan
      final cacheKey = '$_cachePrefix$topicId';
      final timestampKey = '$_cacheTimestampPrefix$topicId';

      // Cache var mı?
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) return null;

      // Cache süresi dolmuş mu?
      if (!ignoreExpiry) {
        final timestamp = prefs.getInt(timestampKey);
        if (timestamp == null) return null;

        final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        if (now.difference(cacheDate) > _cacheExpiry) {
          return null;
        }
      }

      // Cache'i parse et
      final data = jsonDecode(cachedJson) as Map<String, dynamic>;
      return _explanationFromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Explanation'ı cache'e kaydet
  Future<void> _cacheExplanation(String topicId, TopicExplanationModel explanation) async {
    try {
      final prefs = await _instance; // ⚡ Singleton kullan
      final cacheKey = '$_cachePrefix$topicId';
      final timestampKey = '$_cacheTimestampPrefix$topicId';

      // JSON'a çevir
      final json = _explanationToJson(explanation);
      await prefs.setString(cacheKey, jsonEncode(json));
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Silent fail for cache
    }
  }

  /// Cache'i temizle
  Future<void> clearCache(String topicId) async {
    final prefs = await _instance; // ⚡ Singleton kullan
    _memoryCache.remove(topicId); // Memory cache'den de sil
    await prefs.remove('$_cachePrefix$topicId');
    await prefs.remove('$_cacheTimestampPrefix$topicId');
  }

  /// Tüm cache'i temizle
  Future<void> clearAllCache() async {
    final prefs = await _instance; // ⚡ Singleton kullan
    _memoryCache.clear(); // Memory cache'i temizle
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimestampPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// TopicExplanationModel'i JSON'a çevir
  Map<String, dynamic> _explanationToJson(TopicExplanationModel explanation) {
    return {
      'id': explanation.id,
      'topicId': explanation.topicId,
      'lessonId': explanation.lessonId,
      'sections': explanation.sections.map((s) => {
        'title': s.title,
        'paragraphs': s.paragraphs,
        'bullets': s.bullets,
        'order': s.order,
        'heading_indexes': s.headingIndexes,
      }).toList(),
      'createdAt': explanation.createdAt?.millisecondsSinceEpoch,
      'updatedAt': explanation.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// JSON'dan TopicExplanationModel oluştur
  TopicExplanationModel _explanationFromJson(Map<String, dynamic> json) {
    return TopicExplanationModel(
      id: json['id'] as String,
      topicId: json['topicId'] as String,
      lessonId: json['lessonId'] as String,
      sections: (json['sections'] as List).map((s) {
        return ExplanationSection(
          title: s['title'] as String,
          paragraphs: List<String>.from(s['paragraphs'] as List),
          bullets: List<String>.from(s['bullets'] as List),
          order: s['order'] as int,
          headingIndexes: s['heading_indexes'] != null
              ? List<int>.from(s['heading_indexes'] as List)
              : const [],
        );
      }).toList(),
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
    );
  }
}
