import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Quiz istatistiklerini takip eden servis
/// Toplam çözülen, doğru, yanlış sayılarını SharedPreferences'a kaydeder
class QuizStatsService {
  static const String _totalSolvedKey = 'quiz_total_solved';
  static const String _totalCorrectKey = 'quiz_total_correct';
  static const String _totalWrongKey = 'quiz_total_wrong';
  static const String _lessonStatsKey = 'quiz_lesson_stats';
  static const String _dailyStatsKey = 'quiz_daily_stats';
  static const String _topicStatsKey = 'quiz_topic_stats';
  static const String _recentAnswersKey = 'quiz_recent_answers';
  
  static SharedPreferences? _prefs;
  
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Soru cevaplandığında çağrılır
  static Future<void> recordAnswer({
    required bool isCorrect,
    String? lessonId,
    String? topicId,
    String? topicName,
  }) async {
    final prefs = await _instance;
    
    // Toplam çözülen
    final totalSolved = prefs.getInt(_totalSolvedKey) ?? 0;
    await prefs.setInt(_totalSolvedKey, totalSolved + 1);
    
    if (isCorrect) {
      final totalCorrect = prefs.getInt(_totalCorrectKey) ?? 0;
      await prefs.setInt(_totalCorrectKey, totalCorrect + 1);
    } else {
      final totalWrong = prefs.getInt(_totalWrongKey) ?? 0;
      await prefs.setInt(_totalWrongKey, totalWrong + 1);
    }

    // Ders bazlı istatistik kaydet
    if (lessonId != null) {
      await _recordLessonStats(lessonId, isCorrect);
    }

    // Konu bazlı istatistik kaydet
    if (topicId != null && topicName != null) {
      await _recordTopicStats(topicId, topicName, lessonId ?? '', isCorrect);
    }

    // Son cevapları kaydet (zayıf konu analizi için)
    await _recordRecentAnswer(topicId ?? '', isCorrect);

    // Günlük istatistik kaydet
    await _recordDailyStats(isCorrect);
  }

  /// Ders bazlı istatistik kaydet
  static Future<void> _recordLessonStats(String lessonId, bool isCorrect) async {
    final prefs = await _instance;
    final statsJson = prefs.getString(_lessonStatsKey);
    final stats = statsJson != null 
        ? Map<String, dynamic>.from(json.decode(statsJson))
        : <String, dynamic>{};

    if (!stats.containsKey(lessonId)) {
      stats[lessonId] = {'solved': 0, 'correct': 0, 'wrong': 0};
    }

    final lessonStats = Map<String, int>.from(stats[lessonId]);
    lessonStats['solved'] = (lessonStats['solved'] ?? 0) + 1;
    if (isCorrect) {
      lessonStats['correct'] = (lessonStats['correct'] ?? 0) + 1;
    } else {
      lessonStats['wrong'] = (lessonStats['wrong'] ?? 0) + 1;
    }
    stats[lessonId] = lessonStats;

    await prefs.setString(_lessonStatsKey, json.encode(stats));
  }

  /// Konu bazlı istatistik kaydet
  static Future<void> _recordTopicStats(String topicId, String topicName, String lessonId, bool isCorrect) async {
    final prefs = await _instance;
    final statsJson = prefs.getString(_topicStatsKey);
    final stats = statsJson != null 
        ? Map<String, dynamic>.from(json.decode(statsJson))
        : <String, dynamic>{};

    if (!stats.containsKey(topicId)) {
      stats[topicId] = {
        'name': topicName,
        'lessonId': lessonId,
        'solved': 0,
        'correct': 0,
        'wrong': 0,
      };
    }

    final topicStats = Map<String, dynamic>.from(stats[topicId]);
    topicStats['solved'] = (topicStats['solved'] as int? ?? 0) + 1;
    if (isCorrect) {
      topicStats['correct'] = (topicStats['correct'] as int? ?? 0) + 1;
    } else {
      topicStats['wrong'] = (topicStats['wrong'] as int? ?? 0) + 1;
    }
    topicStats['name'] = topicName; // Güncel ismi kaydet
    stats[topicId] = topicStats;

    await prefs.setString(_topicStatsKey, json.encode(stats));
  }

  /// Son 100 cevabı kaydet (zayıf konu trendi için)
  static Future<void> _recordRecentAnswer(String topicId, bool isCorrect) async {
    final prefs = await _instance;
    final answersJson = prefs.getString(_recentAnswersKey);
    List<Map<String, dynamic>> answers = [];
    
    if (answersJson != null) {
      answers = List<Map<String, dynamic>>.from(
        (json.decode(answersJson) as List).map((e) => Map<String, dynamic>.from(e))
      );
    }

    answers.add({
      'topicId': topicId,
      'correct': isCorrect,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Son 100 cevabı tut
    if (answers.length > 100) {
      answers = answers.sublist(answers.length - 100);
    }

    await prefs.setString(_recentAnswersKey, json.encode(answers));
  }

  /// Günlük istatistik kaydet
  static Future<void> _recordDailyStats(bool isCorrect) async {
    final prefs = await _instance;
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final statsJson = prefs.getString(_dailyStatsKey);
    final stats = statsJson != null 
        ? Map<String, dynamic>.from(json.decode(statsJson))
        : <String, dynamic>{};

    if (!stats.containsKey(today)) {
      stats[today] = {'solved': 0, 'correct': 0};
    }

    final dailyStats = Map<String, int>.from(stats[today]);
    dailyStats['solved'] = (dailyStats['solved'] ?? 0) + 1;
    if (isCorrect) {
      dailyStats['correct'] = (dailyStats['correct'] ?? 0) + 1;
    }
    stats[today] = dailyStats;

    // Son 30 günden fazlasını temizle
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    stats.removeWhere((key, _) {
      try {
        return DateTime.parse(key).isBefore(cutoffDate);
      } catch (_) {
        return true;
      }
    });

    await prefs.setString(_dailyStatsKey, json.encode(stats));
  }

  /// Zayıf Konu Analizi - Son performansa göre
  /// Returns: List of weak topics with status (critical, warning, improving)
  static Future<List<Map<String, dynamic>>> getWeakTopicAnalysis() async {
    final prefs = await _instance;
    
    // Konu istatistiklerini al
    final topicStatsJson = prefs.getString(_topicStatsKey);
    if (topicStatsJson == null) return [];
    
    final topicStats = Map<String, dynamic>.from(json.decode(topicStatsJson));
    
    // Son cevapları al
    final recentJson = prefs.getString(_recentAnswersKey);
    List<Map<String, dynamic>> recentAnswers = [];
    if (recentJson != null) {
      recentAnswers = List<Map<String, dynamic>>.from(
        (json.decode(recentJson) as List).map((e) => Map<String, dynamic>.from(e))
      );
    }

    List<Map<String, dynamic>> weakTopics = [];

    topicStats.forEach((topicId, data) {
      final stats = Map<String, dynamic>.from(data);
      final solved = stats['solved'] as int? ?? 0;
      final correct = stats['correct'] as int? ?? 0;
      
      if (solved < 5) return; // En az 5 soru çözülmüş olmalı
      
      final overallAccuracy = (correct / solved * 100).round();
      
      // %70'in altında başarı = zayıf konu
      if (overallAccuracy < 70) {
        // Son 20 cevaptan bu konuya ait olanları bul
        final recentTopicAnswers = recentAnswers
            .where((a) => a['topicId'] == topicId)
            .toList();
        
        int recentCorrect = 0;
        int recentTotal = 0;
        
        // Son 20 cevap
        final last20 = recentTopicAnswers.length > 20 
            ? recentTopicAnswers.sublist(recentTopicAnswers.length - 20)
            : recentTopicAnswers;
        
        for (final answer in last20) {
          recentTotal++;
          if (answer['correct'] == true) recentCorrect++;
        }
        
        final recentAccuracy = recentTotal > 0 
            ? (recentCorrect / recentTotal * 100).round() 
            : overallAccuracy;
        
        // Durum belirleme
        String status;
        if (recentAccuracy >= 70) {
          status = 'improving'; // 🟢 İyileşiyor
        } else if (recentAccuracy > overallAccuracy) {
          status = 'warning';   // 🟡 Orta - biraz iyileşme var
        } else {
          status = 'critical';  // 🔴 Kritik - hala zayıf
        }
        
        weakTopics.add({
          'topicId': topicId,
          'topicName': stats['name'] ?? topicId,
          'lessonId': stats['lessonId'] ?? '',
          'totalSolved': solved,
          'overallAccuracy': overallAccuracy,
          'recentAccuracy': recentAccuracy,
          'status': status,
          'trend': recentAccuracy - overallAccuracy, // Pozitif = iyileşme
        });
      }
    });

    // Kritik olanlar önce, sonra warning, sonra improving
    weakTopics.sort((a, b) {
      const statusOrder = {'critical': 0, 'warning': 1, 'improving': 2};
      return (statusOrder[a['status']] ?? 0).compareTo(statusOrder[b['status']] ?? 0);
    });

    return weakTopics.take(5).toList(); // En fazla 5 zayıf konu göster
  }

  /// Toplam çözülen soru sayısı
  static Future<int> getTotalSolved() async {
    final prefs = await _instance;
    return prefs.getInt(_totalSolvedKey) ?? 0;
  }

  /// Toplam doğru sayısı
  static Future<int> getTotalCorrect() async {
    final prefs = await _instance;
    return prefs.getInt(_totalCorrectKey) ?? 0;
  }

  /// Toplam yanlış sayısı
  static Future<int> getTotalWrong() async {
    final prefs = await _instance;
    return prefs.getInt(_totalWrongKey) ?? 0;
  }

  /// Başarı oranı (%)
  static Future<double> getSuccessRate() async {
    final total = await getTotalSolved();
    if (total == 0) return 0.0;
    final correct = await getTotalCorrect();
    return (correct / total) * 100;
  }

  /// Tüm istatistikleri al
  static Future<Map<String, int>> getAllStats() async {
    return {
      'totalSolved': await getTotalSolved(),
      'totalCorrect': await getTotalCorrect(),
      'totalWrong': await getTotalWrong(),
    };
  }

  /// Ders bazlı istatistikleri al
  static Future<Map<String, Map<String, int>>> getLessonStats() async {
    final prefs = await _instance;
    final statsJson = prefs.getString(_lessonStatsKey);
    if (statsJson == null) return {};

    final stats = Map<String, dynamic>.from(json.decode(statsJson));
    return stats.map((key, value) => MapEntry(
      key,
      Map<String, int>.from(value),
    ));
  }

  /// Günlük istatistikleri al (son 7 gün)
  static Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final prefs = await _instance;
    final statsJson = prefs.getString(_dailyStatsKey);
    final stats = statsJson != null 
        ? Map<String, dynamic>.from(json.decode(statsJson))
        : <String, dynamic>{};

    final result = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final dayStats = stats[dateStr] as Map<String, dynamic>?;
      
      result.add({
        'date': date,
        'dayName': _getDayName(date.weekday),
        'solved': dayStats?['solved'] ?? 0,
        'correct': dayStats?['correct'] ?? 0,
      });
    }
    return result;
  }

  /// Bugünkü istatistikleri al
  static Future<Map<String, int>> getTodayStats() async {
    final prefs = await _instance;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final statsJson = prefs.getString(_dailyStatsKey);
    
    if (statsJson == null) return {'solved': 0, 'correct': 0};

    final stats = Map<String, dynamic>.from(json.decode(statsJson));
    final todayStats = stats[today] as Map<String, dynamic>?;
    
    return {
      'solved': todayStats?['solved'] as int? ?? 0,
      'correct': todayStats?['correct'] as int? ?? 0,
    };
  }

  static String _getDayName(int weekday) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday - 1];
  }

  /// İstatistikleri sıfırla (test için)
  static Future<void> reset() async {
    final prefs = await _instance;
    await prefs.remove(_totalSolvedKey);
    await prefs.remove(_totalCorrectKey);
    await prefs.remove(_totalWrongKey);
    await prefs.remove(_lessonStatsKey);
    await prefs.remove(_dailyStatsKey);
    await prefs.remove(_topicStatsKey);
    await prefs.remove(_recentAnswersKey);
  }
}

