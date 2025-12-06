import 'package:shared_preferences/shared_preferences.dart';

/// Günlük ilerleme servisi - SharedPreferences üzerinden çalışır
/// Dashboard context'e ihtiyaç duymadan her yerden erişilebilir
class DailyProgressService {
  static const String _keyDailyExplanationsCompleted = 'daily_explanations_completed';
  static const String _keyDailyFlashcardsCompleted = 'daily_flashcards_completed';
  static const String _keyDailyResetDate = 'daily_reset_date';

  /// Konu anlatımı tamamlandığında çağır
  static Future<void> incrementExplanations() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastResetDate = prefs.getString(_keyDailyResetDate);
    
    int current = 0;
    if (lastResetDate == todayStr) {
      current = prefs.getInt(_keyDailyExplanationsCompleted) ?? 0;
    } else {
      // Yeni gün, sıfırla
      await prefs.setString(_keyDailyResetDate, todayStr);
      await prefs.setInt(_keyDailyExplanationsCompleted, 0);
      await prefs.setInt(_keyDailyFlashcardsCompleted, 0);
    }
    
    await prefs.setInt(_keyDailyExplanationsCompleted, current + 1);
  }

  /// Her flashcard tamamlandığında çağır
  static Future<void> incrementFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastResetDate = prefs.getString(_keyDailyResetDate);
    
    int current = 0;
    if (lastResetDate == todayStr) {
      current = prefs.getInt(_keyDailyFlashcardsCompleted) ?? 0;
    } else {
      // Yeni gün, sıfırla
      await prefs.setString(_keyDailyResetDate, todayStr);
      await prefs.setInt(_keyDailyExplanationsCompleted, 0);
      await prefs.setInt(_keyDailyFlashcardsCompleted, 0);
    }
    
    await prefs.setInt(_keyDailyFlashcardsCompleted, current + 1);
  }

  /// Bugünkü ilerlemeyi getir
  static Future<Map<String, int>> getTodayProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastResetDate = prefs.getString(_keyDailyResetDate);
    
    if (lastResetDate != todayStr) {
      return {'explanations': 0, 'flashcards': 0};
    }
    
    return {
      'explanations': prefs.getInt(_keyDailyExplanationsCompleted) ?? 0,
      'flashcards': prefs.getInt(_keyDailyFlashcardsCompleted) ?? 0,
    };
  }
}
