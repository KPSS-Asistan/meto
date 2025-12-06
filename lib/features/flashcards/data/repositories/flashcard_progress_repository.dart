import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';
import '../../domain/entities/user_flashcard_progress.dart';
import '../../domain/utils/leitner_system.dart';

/// Flashcard progress tracking with Leitner System
/// ⚡ OPTIMIZED: SharedPreferences - Firebase'e bağımlılık yok
class FlashcardProgressRepository {
  static const String _keyPrefix = 'flashcard_progress_';
  
  // ⚡ SINGLETON: SharedPreferences instance
  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get user's progress for a specific flashcard
  Future<UserFlashcardProgress?> getProgress({
    required String userId,
    required String flashcardId,
  }) async {
    try {
      final prefs = await _instance;
      final key = '$_keyPrefix${userId}_$flashcardId';
      final jsonStr = prefs.getString(key);
      
      if (jsonStr == null) return null;
      
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      return UserFlashcardProgress(
        userId: userId,
        flashcardId: flashcardId,
        boxLevel: data['box_level'] as int? ?? 1,
        nextReviewDate: DateTime.parse(data['next_review_date'] as String),
        lastReviewedAt: DateTime.parse(data['last_reviewed_at'] as String),
        totalReviews: data['total_reviews'] as int? ?? 0,
        correctCount: data['correct_count'] as int? ?? 0,
        wrongCount: data['wrong_count'] as int? ?? 0,
      );
    } catch (e) {
      AppLogger.error('Get flashcard progress failed', e);
      return null;
    }
  }

  /// Save correct answer (move to next box)
  Future<void> saveCorrectAnswer({
    required String userId,
    required String flashcardId,
  }) async {
    try {
      final prefs = await _instance;
      final key = '$_keyPrefix${userId}_$flashcardId';
      final existing = await getProgress(userId: userId, flashcardId: flashcardId);

      final currentLevel = existing?.boxLevel ?? 1;
      final newLevel = LeitnerSystem.getNextBoxLevel(currentLevel);
      final nextReview = LeitnerSystem.calculateNextReviewDate(newLevel);

      final data = {
        'user_id': userId,
        'flashcard_id': flashcardId,
        'box_level': newLevel,
        'next_review_date': nextReview.toIso8601String(),
        'last_reviewed_at': DateTime.now().toIso8601String(),
        'total_reviews': (existing?.totalReviews ?? 0) + 1,
        'correct_count': (existing?.correctCount ?? 0) + 1,
        'wrong_count': existing?.wrongCount ?? 0,
      };
      
      await prefs.setString(key, json.encode(data));
    } catch (e) {
      AppLogger.error('Save correct answer failed', e);
    }
  }

  /// Save wrong answer (reset to box 1)
  Future<void> saveWrongAnswer({
    required String userId,
    required String flashcardId,
  }) async {
    try {
      final prefs = await _instance;
      final key = '$_keyPrefix${userId}_$flashcardId';
      final existing = await getProgress(userId: userId, flashcardId: flashcardId);

      final newLevel = LeitnerSystem.resetBoxLevel();
      final nextReview = LeitnerSystem.getImmediateReviewDate();

      final data = {
        'user_id': userId,
        'flashcard_id': flashcardId,
        'box_level': newLevel,
        'next_review_date': nextReview.toIso8601String(),
        'last_reviewed_at': DateTime.now().toIso8601String(),
        'total_reviews': (existing?.totalReviews ?? 0) + 1,
        'correct_count': existing?.correctCount ?? 0,
        'wrong_count': (existing?.wrongCount ?? 0) + 1,
      };
      
      await prefs.setString(key, json.encode(data));
    } catch (e) {
      AppLogger.error('Save wrong answer failed', e);
    }
  }

  /// Get all flashcards that need review for a topic
  Future<List<String>> getFlashcardsNeedingReview({
    required String userId,
    required String topicId,
    required List<String> allFlashcardIds,
  }) async {
    try {
      final needsReview = <String>[];
      
      for (final flashcardId in allFlashcardIds) {
        final progress = await getProgress(userId: userId, flashcardId: flashcardId);
        
        // Eğer progress yoksa veya zamanı geldiyse ekle
        if (progress == null || LeitnerSystem.shouldReview(progress.nextReviewDate)) {
          needsReview.add(flashcardId);
        }
      }

      return needsReview;
    } catch (e) {
      AppLogger.error('Get cards needing review failed', e);
      return allFlashcardIds;
    }
  }
  
  /// Clear all progress (for testing)
  Future<void> clearAllProgress() async {
    try {
      final prefs = await _instance;
      final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      AppLogger.error('Clear progress failed', e);
    }
  }
}
