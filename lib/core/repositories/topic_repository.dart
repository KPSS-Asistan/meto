import 'package:kpss_2026/core/models/topic_model.dart';
import 'package:kpss_2026/core/data/topics_data.dart';

/// ⚡ HARDCODED ONLY - Firebase bağımlılığı kaldırıldı
class TopicRepository {
  // ⚡ Memory cache
  static Map<String, List<TopicModel>>? _topicsCache;

  TopicRepository();

  /// Konuları al - Tamamen hardcoded
  Future<List<TopicModel>> getTopicsByLesson(String lessonId) async {
    // Memory cache varsa kullan
    if (_topicsCache != null && _topicsCache!.containsKey(lessonId)) {
      return _topicsCache![lessonId]!;
    }
    
    // Hardcode'dan al
    final topics = _getHardcodedTopics(lessonId);
    _topicsCache ??= {};
    _topicsCache![lessonId] = topics;
    return topics;
  }
  
  /// Hardcode'dan konuları al
  List<TopicModel> _getHardcodedTopics(String lessonId) {
    final topics = <TopicModel>[];
    
    for (final topicData in topicsData) {
      if (topicData['lesson_id'] == lessonId) {
        final normalizedData = {
          'id': topicData['id'],
          'lessonId': topicData['lesson_id'],
          'name': topicData['name'],
          'description': topicData['description'],
          'questionCount': topicData['question_count'] ?? 0,
          'order': topicData['order'] ?? 0,
          'createdAt': topicData['created_at'] ?? '2025-01-01T00:00:00.000Z',
          'updatedAt': topicData['updated_at'] ?? '2025-01-01T00:00:00.000Z',
        };
        topics.add(TopicModel.fromJson(normalizedData));
      }
    }
    
    topics.sort((a, b) => a.order.compareTo(b.order));
    return topics;
  }
  
  /// Clear cache
  void clearCache([String? lessonId]) {
    if (lessonId != null) {
      _topicsCache?.remove(lessonId);
    } else {
      _topicsCache = null;
    }
  }

  /// Tek konuyu al
  Future<TopicModel?> getTopicById(String lessonId, String topicId) async {
    final topics = await getTopicsByLesson(lessonId);
    final found = topics.where((t) => t.id == topicId);
    return found.isNotEmpty ? found.first : null;
  }
  
  /// Tüm konuları al
  List<TopicModel> getAllTopics() {
    final topics = <TopicModel>[];
    
    for (final topicData in topicsData) {
      final normalizedData = {
        'id': topicData['id'],
        'lessonId': topicData['lesson_id'],
        'name': topicData['name'],
        'description': topicData['description'],
        'questionCount': topicData['question_count'] ?? 0,
        'order': topicData['order'] ?? 0,
        'createdAt': topicData['created_at'] ?? '2025-01-01T00:00:00.000Z',
        'updatedAt': topicData['updated_at'] ?? '2025-01-01T00:00:00.000Z',
      };
      topics.add(TopicModel.fromJson(normalizedData));
    }
    
    return topics;
  }
  
  /// Konu adını ID'den al
  String? getTopicName(String topicId) {
    for (final topicData in topicsData) {
      if (topicData['id'] == topicId) {
        return topicData['name'] as String?;
      }
    }
    return null;
  }
}
