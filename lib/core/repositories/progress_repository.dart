import 'package:kpss_2026/core/services/local_progress_service.dart';

/// ⚡ LOCAL-FIRST: Tüm veriler önce local'e kaydedilir
/// Firebase sync günlük yapılır (SyncService ile)
class ProgressRepository {
  LocalProgressService? _localProgress;

  ProgressRepository();
  
  /// LocalProgressService'i lazy initialize et
  Future<LocalProgressService> get _local async {
    _localProgress ??= await LocalProgressService.getInstance();
    return _localProgress!;
  }

  /// Save user progress for a question - LOCAL ONLY
  Future<void> saveProgress({
    required String userId,
    required String questionId,
    required String topicId,
    required bool isCorrect,
    String? topicName,
    String contentType = 'question',
  }) async {
    // Tek soru için kayıt - genellikle batch kullanılır
    // Bu metod backward compatibility için tutuldu
  }

  /// Quiz sonuçlarını LOCAL'e kaydet
  Future<void> saveBatchProgress({
    required String userId,
    required List<Map<String, dynamic>> answers,
    required String topicId,
    String? topicName,
    String? lessonId,
    int durationSeconds = 0,
  }) async {
    if (answers.isEmpty) return;

    final local = await _local;
    
    // Doğru ve yanlış cevapları ayır
    int correctCount = 0;
    final wrongQuestionIds = <String>[];
    final wrongAnswerDetails = <String, String>{};
    final correctAnswerDetails = <String, String>{};
    
    for (final answer in answers) {
      final questionId = answer['questionId'] as String;
      final isCorrect = answer['isCorrect'] as bool;
      final selectedAnswer = answer['selectedAnswer'] as String? ?? '';
      final correctAnswer = answer['correctAnswer'] as String? ?? '';
      
      if (isCorrect) {
        correctCount++;
      } else {
        wrongQuestionIds.add(questionId);
        wrongAnswerDetails[questionId] = selectedAnswer;
        correctAnswerDetails[questionId] = correctAnswer;
      }
    }
    
    // LocalProgressService'e kaydet
    await local.recordQuizResult(
      topicId: topicId,
      lessonId: lessonId ?? '',
      topicName: topicName ?? '',
      totalQuestions: answers.length,
      correctAnswers: correctCount,
      durationSeconds: durationSeconds,
      wrongQuestionIds: wrongQuestionIds,
      wrongAnswerDetails: wrongAnswerDetails,
      correctAnswerDetails: correctAnswerDetails,
    );
  }

  /// Get list of solved question IDs for a topic - LOCAL
  Future<List<String>> getSolvedQuestionIds(
    String userId,
    String topicId,
  ) async {
    // Local'de quiz history'den çözülen soruları al
    // Bu özellik şu an kullanılmıyor, boş döndür
    return [];
  }

  /// Get complete user progress statistics - LOCAL
  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    final local = await _local;
    final userData = local.userData;
    
    return {
      'totalQuestions': userData.totalQuestionsAnswered,
      'correctAnswers': userData.totalCorrectAnswers,
      'currentStreak': userData.currentStreak,
      'accuracy': userData.totalQuestionsAnswered > 0 
          ? (userData.totalCorrectAnswers / userData.totalQuestionsAnswered * 100).toInt() 
          : 0,
      'lessonProgress': <String, int>{},
    };
  }

  /// Get topic statistics - LOCAL
  Future<TopicStats> getTopicStats(String userId, String topicId) async {
    final local = await _local;
    final progress = local.getTopicProgress(topicId);
    
    if (progress == null) {
      return TopicStats(totalSolved: 0, correctCount: 0, wrongCount: 0);
    }
    
    return TopicStats(
      totalSolved: progress.attemptedQuestions,
      correctCount: progress.correctAnswers,
      wrongCount: progress.wrongAnswers,
    );
  }

  /// Check if a specific question is solved - LOCAL
  Future<bool> isQuestionSolved(String userId, String questionId) async {
    // Bu özellik şu an kullanılmıyor
    return false;
  }

  /// Clear progress for a topic - LOCAL
  Future<void> clearTopicProgress(String userId, String topicId) async {
    // Local'de topic progress'i sıfırla
    // TODO: Implement if needed
  }

  /// Get all wrong question IDs for a user - LOCAL
  Future<List<String>> getWrongQuestionIds(String userId) async {
    final local = await _local;
    return local.getWrongQuestionIds();
  }

  /// Get wrong question IDs for a specific topic - LOCAL
  Future<List<String>> getWrongQuestionIdsForTopic(String userId, String topicId) async {
    final local = await _local;
    return local.getWrongQuestionIds(topicId: topicId);
  }

  /// Get all favorite topic IDs for a user - LOCAL
  Future<List<String>> getFavoriteQuestionIds(String userId) async {
    final local = await _local;
    return local.favorites;
  }

  /// Toggle favorite status for a topic - LOCAL
  Future<void> toggleFavorite({
    required String userId,
    required String questionId,
  }) async {
    final local = await _local;
    await local.toggleFavorite(questionId);
  }

  /// Check if a topic is favorited - LOCAL
  Future<bool> isFavorite(String userId, String questionId) async {
    final local = await _local;
    return local.isFavorite(questionId);
  }

  /// Get favorite count for a specific topic - LOCAL
  Future<int> getTopicFavoriteCount(String userId, String topicId) async {
    final local = await _local;
    return local.favorites.contains(topicId) ? 1 : 0;
  }

  /// Invalidate all caches - Not needed for local
  Future<void> invalidateCache(String userId) async {
    // Local storage kullandığımız için cache invalidation gerekmiyor
  }
}

/// Topic statistics model
class TopicStats {
  final int totalSolved;
  final int correctCount;
  final int wrongCount;

  TopicStats({
    required this.totalSolved,
    required this.correctCount,
    required this.wrongCount,
  });

  double get successRate =>
      totalSolved > 0 ? (correctCount / totalSolved) * 100 : 0;
}
