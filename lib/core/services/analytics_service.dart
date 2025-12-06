import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics service - Firebase Analytics entegrasyonu
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Log user action
  Future<void> logEvent(String eventName, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: eventName, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Log login
  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Log sign up
  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Log quiz start
  Future<void> logQuizStart({
    required String topicId,
    required String topicName,
    required int questionCount,
  }) async {
    await logEvent('quiz_start', parameters: {
      'topic_id': topicId,
      'topic_name': topicName,
      'question_count': questionCount,
    });
  }

  /// Log quiz complete
  Future<void> logQuizComplete({
    required String topicId,
    required String topicName,
    required int score,
    required int totalQuestions,
    required int timeSpent,
  }) async {
    await logEvent('quiz_complete', parameters: {
      'topic_id': topicId,
      'topic_name': topicName,
      'score': score,
      'total_questions': totalQuestions,
      'time_spent': timeSpent,
      'success_rate': (score / totalQuestions * 100).toInt(),
    });
  }

  /// Log lesson view
  Future<void> logLessonView({
    required String lessonId,
    required String lessonName,
  }) async {
    await logEvent('lesson_view', parameters: {
      'lesson_id': lessonId,
      'lesson_name': lessonName,
    });
  }

  /// Log topic view
  Future<void> logTopicView({
    required String topicId,
    required String topicName,
    required String lessonId,
  }) async {
    await logEvent('topic_view', parameters: {
      'topic_id': topicId,
      'topic_name': topicName,
      'lesson_id': lessonId,
    });
  }

  /// Log content view
  Future<void> logContentView({
    required String contentType,
    required String contentId,
    required String contentName,
  }) async {
    await logEvent('content_view', parameters: {
      'content_type': contentType,
      'content_id': contentId,
      'content_name': contentName,
    });
  }

  /// Log search
  Future<void> logSearch(String searchTerm) async {
    await logEvent('search', parameters: {
      'search_term': searchTerm,
    });
  }

  /// Log share
  Future<void> logShare({
    required String contentType,
    required String contentId,
    required String method,
  }) async {
    await logEvent('share', parameters: {
      'content_type': contentType,
      'content_id': contentId,
      'method': method,
    });
  }

  /// Log favorite add
  Future<void> logFavoriteAdd({
    required String contentType,
    required String contentId,
  }) async {
    await logEvent('favorite_add', parameters: {
      'content_type': contentType,
      'content_id': contentId,
    });
  }

  /// Log favorite remove
  Future<void> logFavoriteRemove({
    required String contentType,
    required String contentId,
  }) async {
    await logEvent('favorite_remove', parameters: {
      'content_type': contentType,
      'content_id': contentId,
    });
  }

  /// Log AI coach interaction
  Future<void> logAICoachInteraction({
    required String messageType,
    required int messageLength,
  }) async {
    await logEvent('ai_coach_interaction', parameters: {
      'message_type': messageType,
      'message_length': messageLength,
    });
  }

  /// Log productivity technique view
  Future<void> logTechniqueView({
    required String techniqueId,
    required String techniqueName,
    required String category,
  }) async {
    await logEvent('technique_view', parameters: {
      'technique_id': techniqueId,
      'technique_name': techniqueName,
      'category': category,
    });
  }

  /// Set user properties
  Future<void> setUserProperties({
    String? userId,
    String? userType,
    int? studyStreak,
  }) async {
    try {
      if (userId != null) await _analytics.setUserId(id: userId);
      if (userType != null) {
        await _analytics.setUserProperty(name: 'user_type', value: userType);
      }
      if (studyStreak != null) {
        await _analytics.setUserProperty(
          name: 'study_streak',
          value: studyStreak.toString(),
        );
      }
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }
}
