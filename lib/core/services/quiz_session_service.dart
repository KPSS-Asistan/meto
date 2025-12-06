import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Quiz oturum yönetimi - Test bitene kadar aynı sorular gösterilir
class QuizSessionService {
  static const _keyPrefix = 'quiz_session_';
  static const int maxQuestions = 20;
  static const int maxMinutes = 20;
  
  static SharedPreferences? _prefs;
  
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Aktif quiz oturumu var mı kontrol et
  static Future<QuizSession?> getActiveSession(String topicId) async {
    try {
      final prefs = await _instance;
      final key = '$_keyPrefix$topicId';
      final jsonStr = prefs.getString(key);
      
      if (jsonStr == null) return null;
      
      final session = QuizSession.fromJson(json.decode(jsonStr));
      
      // Oturum süresi dolmuş mu kontrol et (20 dakika)
      final elapsed = DateTime.now().difference(session.startedAt);
      if (elapsed.inMinutes >= maxMinutes) {
        AppLogger.debug('QuizSession: Session expired for topic $topicId');
        await clearSession(topicId);
        return null;
      }
      
      // Oturum tamamlanmış mı kontrol et
      if (session.isCompleted) {
        AppLogger.debug('QuizSession: Session completed for topic $topicId');
        await clearSession(topicId);
        return null;
      }
      
      AppLogger.debug('QuizSession: Found active session for topic $topicId with ${session.questionIds.length} questions');
      return session;
    } catch (e) {
      AppLogger.error('QuizSession: Failed to get session', e);
      return null;
    }
  }

  /// Yeni quiz oturumu başlat
  static Future<void> startSession({
    required String topicId,
    required List<String> questionIds,
    required List<String> shuffledQuestionIds,
  }) async {
    try {
      final prefs = await _instance;
      final key = '$_keyPrefix$topicId';
      
      final session = QuizSession(
        topicId: topicId,
        questionIds: questionIds,
        shuffledQuestionIds: shuffledQuestionIds,
        currentIndex: 0,
        userAnswers: {},
        startedAt: DateTime.now(),
        isCompleted: false,
      );
      
      await prefs.setString(key, json.encode(session.toJson()));
      AppLogger.debug('QuizSession: Started new session for topic $topicId with ${questionIds.length} questions');
    } catch (e) {
      AppLogger.error('QuizSession: Failed to start session', e);
    }
  }

  /// Oturum ilerlemesini güncelle
  static Future<void> updateProgress({
    required String topicId,
    required int currentIndex,
    required Map<int, String> userAnswers,
  }) async {
    try {
      final prefs = await _instance;
      final key = '$_keyPrefix$topicId';
      final jsonStr = prefs.getString(key);
      
      if (jsonStr == null) return;
      
      final session = QuizSession.fromJson(json.decode(jsonStr));
      final updated = session.copyWith(
        currentIndex: currentIndex,
        userAnswers: userAnswers,
      );
      
      await prefs.setString(key, json.encode(updated.toJson()));
      AppLogger.debug('QuizSession: Updated progress for topic $topicId - index: $currentIndex');
    } catch (e) {
      AppLogger.error('QuizSession: Failed to update progress', e);
    }
  }

  /// Oturumu tamamlandı olarak işaretle
  static Future<void> completeSession(String topicId) async {
    try {
      final prefs = await _instance;
      final key = '$_keyPrefix$topicId';
      final jsonStr = prefs.getString(key);
      
      if (jsonStr == null) return;
      
      final session = QuizSession.fromJson(json.decode(jsonStr));
      final updated = session.copyWith(isCompleted: true);
      
      await prefs.setString(key, json.encode(updated.toJson()));
      AppLogger.debug('QuizSession: Completed session for topic $topicId');
    } catch (e) {
      AppLogger.error('QuizSession: Failed to complete session', e);
    }
  }

  /// Oturumu temizle
  static Future<void> clearSession(String topicId) async {
    try {
      final prefs = await _instance;
      final key = '$_keyPrefix$topicId';
      await prefs.remove(key);
      AppLogger.debug('QuizSession: Cleared session for topic $topicId');
    } catch (e) {
      AppLogger.error('QuizSession: Failed to clear session', e);
    }
  }

  /// Kalan süreyi hesapla (saniye)
  static Future<int> getRemainingTime(String topicId) async {
    try {
      final session = await getActiveSession(topicId);
      if (session == null) return maxMinutes * 60;
      
      // Eğer remainingSeconds varsa onu dön, yoksa hesapla (eski versiyon uyumluluğu)
      if (session.remainingSeconds != null) {
        return session.remainingSeconds!;
      }
      
      final elapsed = DateTime.now().difference(session.startedAt);
      final remaining = (maxMinutes * 60) - elapsed.inSeconds;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return maxMinutes * 60;
    }
  }

  /// Kalan süreyi güncelle (Pause işlemi)
  static Future<void> updateRemainingTime(String topicId, int seconds) async {
    try {
      final prefs = await _instance;
      final key = '$_keyPrefix$topicId';
      final jsonStr = prefs.getString(key);
      
      if (jsonStr == null) return;
      
      final session = QuizSession.fromJson(json.decode(jsonStr));
      final updated = session.copyWith(remainingSeconds: seconds);
      
      await prefs.setString(key, json.encode(updated.toJson()));
      AppLogger.debug('QuizSession: Paused session for topic $topicId with $seconds seconds remaining');
    } catch (e) {
      AppLogger.error('QuizSession: Failed to update remaining time', e);
    }
  }

  /// Tüm oturumları temizle
  static Future<void> clearAllSessions() async {
    try {
      final prefs = await _instance;
      final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
      AppLogger.debug('QuizSession: Cleared all sessions (${keys.length} total)');
    } catch (e) {
      AppLogger.error('QuizSession: Failed to clear all sessions', e);
    }
  }
}

/// Quiz oturum modeli
class QuizSession {
  final String topicId;
  final List<String> questionIds; // Orijinal sıralama
  final List<String> shuffledQuestionIds; // Karıştırılmış sıralama
  final int currentIndex;
  final Map<int, String> userAnswers; // index -> answer
  final DateTime startedAt;
  final bool isCompleted;
  final int? remainingSeconds; // Kalan süre (Pause desteği için)

  QuizSession({
    required this.topicId,
    required this.questionIds,
    required this.shuffledQuestionIds,
    required this.currentIndex,
    required this.userAnswers,
    required this.startedAt,
    required this.isCompleted,
    this.remainingSeconds,
  });

  QuizSession copyWith({
    String? topicId,
    List<String>? questionIds,
    List<String>? shuffledQuestionIds,
    int? currentIndex,
    Map<int, String>? userAnswers,
    DateTime? startedAt,
    bool? isCompleted,
    int? remainingSeconds,
  }) {
    return QuizSession(
      topicId: topicId ?? this.topicId,
      questionIds: questionIds ?? this.questionIds,
      shuffledQuestionIds: shuffledQuestionIds ?? this.shuffledQuestionIds,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      startedAt: startedAt ?? this.startedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'topicId': topicId,
    'questionIds': questionIds,
    'shuffledQuestionIds': shuffledQuestionIds,
    'currentIndex': currentIndex,
    'userAnswers': userAnswers.map((k, v) => MapEntry(k.toString(), v)),
    'startedAt': startedAt.toIso8601String(),
    'isCompleted': isCompleted,
    'remainingSeconds': remainingSeconds,
  };

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    final answersMap = (json['userAnswers'] as Map<String, dynamic>?) ?? {};
    return QuizSession(
      topicId: json['topicId'] as String,
      questionIds: List<String>.from(json['questionIds'] ?? []),
      shuffledQuestionIds: List<String>.from(json['shuffledQuestionIds'] ?? []),
      currentIndex: json['currentIndex'] as int? ?? 0,
      userAnswers: answersMap.map((k, v) => MapEntry(int.parse(k), v as String)),
      startedAt: DateTime.parse(json['startedAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      remainingSeconds: json['remainingSeconds'] as int?,
    );
  }
}
