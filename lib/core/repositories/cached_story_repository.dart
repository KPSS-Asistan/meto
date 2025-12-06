import '../models/topic_story_model.dart';
import '../data/stories_data.dart';
import '../data/topics_data.dart';

/// ⚡ HARDCODED ONLY - Firebase bağımlılığı kaldırıldı
class CachedStoryRepository {
  // ⚡ MEMORY CACHE: Hardcoded stories
  static final Map<String, TopicStoryModel> _memoryCache = {};

  CachedStoryRepository();

  /// Get topic story - Tamamen hardcoded
  Future<TopicStoryModel?> getTopicStory(String topicId) async {
    // ⚡ Memory cache'e bak (en hızlı)
    if (_memoryCache.containsKey(topicId)) {
      return _memoryCache[topicId];
    }
    
    // Hardcoded veriyi al
    final hardcodedStory = _getHardcodedStory(topicId);
    if (hardcodedStory != null) {
      _memoryCache[topicId] = hardcodedStory;
      return hardcodedStory;
    }

    return null;
  }

  /// Hardcoded veriden hikaye oluştur
  TopicStoryModel? _getHardcodedStory(String topicId) {
    final data = StoriesData.getStory(topicId);
    if (data == null) return null;

    final sections = <StorySection>[];
    for (var i = 0; i < data.length; i++) {
      final sectionData = data[i];
      sections.add(StorySection(
        title: sectionData['title'] as String,
        content: sectionData['content'] as String,
        keyPoints: (sectionData['keyPoints'] as List<dynamic>).cast<String>(),
        order: sectionData['order'] as int,
      ));
    }

    // Topic bilgilerini al
    final topicInfo = _getTopicInfo(topicId);

    return TopicStoryModel(
      id: topicId,
      topicId: topicId,
      topicName: topicInfo['name'] ?? '',
      lessonId: topicInfo['lessonId'] ?? '',
      lessonName: topicInfo['lessonName'] ?? '',
      sections: sections,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPublished: true,
    );
  }
  
  /// Topic bilgilerini al
  Map<String, String> _getTopicInfo(String topicId) {
    for (final topic in topicsData) {
      if (topic['id'] == topicId) {
        return {
          'name': topic['name'] as String? ?? '',
          'lessonId': topic['lesson_id'] as String? ?? '',
          'lessonName': _getLessonName(topic['lesson_id'] as String? ?? ''),
        };
      }
    }
    return {};
  }
  
  /// Ders adını al
  String _getLessonName(String lessonId) {
    switch (lessonId) {
      case 'tarih': return 'Tarih';
      case 'turkce': return 'Türkçe';
      case 'cografya': return 'Coğrafya';
      case 'vatandaslik': return 'Vatandaşlık';
      default: return '';
    }
  }

  /// Clear cache for a specific topic
  void clearCache(String topicId) {
    _memoryCache.remove(topicId);
  }

  /// Clear all story caches
  void clearAllCaches() {
    _memoryCache.clear();
  }
}
