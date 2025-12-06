import 'package:kpss_2026/core/models/question_model.dart';
import 'package:kpss_2026/core/data/questions_data.dart';
import 'package:kpss_2026/core/data/topics_data.dart';

/// ⚡ HARDCODED ONLY - Firebase bağımlılığı kaldırıldı
class QuestionRepository {
  // ═══════════════════════════════════════════════════════════════════════════
  // MEMORY CACHE - Sorular için in-memory cache
  // ═══════════════════════════════════════════════════════════════════════════
  static final Map<String, List<QuestionModel>> _topicCache = {};
  static final Map<String, QuestionModel> _questionCache = {};

  QuestionRepository();

  /// Cache'i temizle (gerekirse)
  static void clearCache() {
    _topicCache.clear();
    _questionCache.clear();
  }
  
  /// Belirli topic cache'ini temizle
  static void clearTopicCache(String topicId) {
    _topicCache.remove(topicId);
  }

  /// Soruları getir (CACHED)
  Stream<List<QuestionModel>> getQuestionsByTopic(String topicId) {
    return Stream.fromFuture(_fetchQuestions(topicId));
  }
  
  Future<List<QuestionModel>> _fetchQuestions(String topicId) async {
    // ⚡ MEMORY CACHE: Önce cache'e bak
    if (_topicCache.containsKey(topicId)) {
      return _topicCache[topicId]!;
    }
    
    // Hardcoded data'dan al
    final questionsData = QuestionsData.getQuestions(topicId);
    if (questionsData == null || questionsData.isEmpty) {
      return <QuestionModel>[];
    }
    
    final questions = questionsData.map((data) => _parseQuestion(data)).toList();
    
    // ⚡ CACHE'E KAYDET
    _topicCache[topicId] = questions;
    
    // Her soruyu da individual cache'e ekle
    for (final q in questions) {
      _questionCache[q.id] = q;
    }
    
    return questions;
  }

  Future<QuestionModel?> getQuestionById(String questionId) async {
    // ⚡ MEMORY CACHE: Önce cache'e bak
    if (_questionCache.containsKey(questionId)) {
      return _questionCache[questionId];
    }
    
    // Tüm sorularda ara
    for (final topicId in QuestionsData.questions.keys) {
      final questions = await _fetchQuestions(topicId);
      final found = questions.where((q) => q.id == questionId);
      if (found.isNotEmpty) {
        return found.first;
      }
    }
    
    return null;
  }

  /// Batch fetch questions by IDs (for favorites, wrong answers)
  Future<List<QuestionModel>> getQuestionsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final List<QuestionModel> allQuestions = [];
    
    for (final id in ids) {
      // Önce cache'e bak
      if (_questionCache.containsKey(id)) {
        allQuestions.add(_questionCache[id]!);
      } else {
        // Cache'de yoksa ara
        final question = await getQuestionById(id);
        if (question != null) {
          allQuestions.add(question);
        }
      }
    }

    return allQuestions;
  }
  
  /// Rastgele N soru getir
  Future<List<QuestionModel>> getRandomQuestions(String topicId, int count) async {
    final questionsData = QuestionsData.getRandomQuestions(topicId, count);
    return questionsData.map((data) => _parseQuestion(data)).toList();
  }
  
  /// Soru sayısını getir
  int getQuestionCount(String topicId) {
    return QuestionsData.getQuestionCount(topicId);
  }
  
  /// Konu için soru var mı?
  bool hasQuestions(String topicId) {
    return QuestionsData.hasQuestions(topicId);
  }

  /// Parse question from hardcoded data
  QuestionModel _parseQuestion(Map<String, dynamic> data) {
    final id = data['id'] as String? ?? '';
    final topicId = data['topicId'] as String? ?? '';
    
    // LessonId: Önce soruda varsa al, yoksa topicId'den bul
    String lessonId = data['lessonId'] as String? ?? '';
    if (lessonId.isEmpty && topicId.isNotEmpty) {
      lessonId = _getLessonIdFromTopic(topicId);
    }
    
    final questionText = data['questionText'] as String? ?? '';
    final correctAnswer = data['correctAnswer'] as String? ?? '';
    final explanation = data['explanation'] as String?;

    final optionsData = data['options'] as Map<String, dynamic>?;
    final options = optionsData?.map(
          (key, value) => MapEntry(key, value.toString()),
        ) ??
        {};

    return QuestionModel(
      id: id,
      lessonId: lessonId,
      topicId: topicId,
      questionText: questionText,
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// TopicId'den LessonId bul
  String _getLessonIdFromTopic(String topicId) {
    // topics_data'dan lesson_id bul
    for (final topic in topicsData) {
      if (topic['id'] == topicId) {
        return topic['lesson_id'] as String? ?? '';
      }
    }
    return '';
  }
}
