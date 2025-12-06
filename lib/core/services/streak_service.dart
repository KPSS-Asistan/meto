import 'package:shared_preferences/shared_preferences.dart';

/// Streak Service - Günlük çalışma takibi
/// Kullanıcının hangi günlerde çalıştığını takip eder
/// ⚡ OPTIMIZED: Singleton SharedPreferences instance
class StreakService {
  static const String _streakDaysKey = 'streak_days';
  static const String _currentStreakKey = 'current_streak';
  static const String _longestStreakKey = 'longest_streak';
  static const String _lastStudyDateKey = 'last_study_date';
  
  // ⚡ SINGLETON: Tek bir SharedPreferences instance
  static SharedPreferences? _prefs;
  
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Bugün çalışıldı olarak işaretle
  static Future<void> markTodayAsStudied() async {
    final prefs = await _instance;
    final today = _getDateKey(DateTime.now());
    
    // Çalışılan günleri al
    final studiedDays = await getStudiedDays();
    
    // Bugün zaten işaretli mi?
    if (studiedDays.contains(today)) return;
    
    // Bugünü ekle
    studiedDays.add(today);
    await prefs.setStringList(_streakDaysKey, studiedDays.toList());
    
    // Streak hesapla
    await _updateStreak();
  }

  /// Belirli bir günü çalışıldı olarak işaretle
  static Future<void> markDayAsStudied(DateTime date) async {
    final prefs = await _instance;
    final dateKey = _getDateKey(date);
    
    final studiedDays = await getStudiedDays();
    
    if (studiedDays.contains(dateKey)) return;
    
    studiedDays.add(dateKey);
    await prefs.setStringList(_streakDaysKey, studiedDays.toList());
    
    await _updateStreak();
  }

  /// Çalışılan günleri al (Set olarak)
  static Future<Set<String>> getStudiedDays() async {
    final prefs = await _instance;
    final days = prefs.getStringList(_streakDaysKey) ?? [];
    return days.toSet();
  }

  /// Belirli bir ayın çalışılan günlerini al
  static Future<Set<int>> getStudiedDaysForMonth(int year, int month) async {
    final studiedDays = await getStudiedDays();
    final prefix = '$year-${month.toString().padLeft(2, '0')}-';
    
    return studiedDays
        .where((day) => day.startsWith(prefix))
        .map((day) => int.parse(day.split('-').last))
        .toSet();
  }

  /// Belirli bir günde çalışılmış mı?
  static Future<bool> isStudied(DateTime date) async {
    final studiedDays = await getStudiedDays();
    return studiedDays.contains(_getDateKey(date));
  }

  /// Mevcut streak'i al
  static Future<int> getCurrentStreak() async {
    final prefs = await _instance;
    return prefs.getInt(_currentStreakKey) ?? 0;
  }

  /// En uzun streak'i al
  static Future<int> getLongestStreak() async {
    final prefs = await _instance;
    return prefs.getInt(_longestStreakKey) ?? 0;
  }

  /// Son 7 günün durumunu al
  static Future<List<bool>> getLast7Days() async {
    final studiedDays = await getStudiedDays();
    final today = DateTime.now();
    
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return studiedDays.contains(_getDateKey(date));
    });
  }

  /// Bu haftanın durumunu al (Pazartesi'den başlayarak)
  static Future<List<bool>> getThisWeek() async {
    final studiedDays = await getStudiedDays();
    final today = DateTime.now();
    
    // Pazartesi'yi bul
    final monday = today.subtract(Duration(days: today.weekday - 1));
    
    return List.generate(7, (index) {
      final date = monday.add(Duration(days: index));
      return studiedDays.contains(_getDateKey(date));
    });
  }

  /// Bu aydaki toplam çalışılan gün sayısı
  static Future<int> getMonthlyStudyCount(int year, int month) async {
    final days = await getStudiedDaysForMonth(year, month);
    return days.length;
  }

  /// Streak'i güncelle - İlk çalışmadan itibaren say
  static Future<void> _updateStreak() async {
    final prefs = await _instance;
    final studiedDays = await getStudiedDays();
    
    if (studiedDays.isEmpty) {
      await prefs.setInt(_currentStreakKey, 0);
      return;
    }
    
    // Bugünden geriye doğru ardışık günleri say
    final today = DateTime.now();
    final todayKey = _getDateKey(today);
    final yesterdayKey = _getDateKey(today.subtract(const Duration(days: 1)));
    
    // Bugün veya dün çalışılmadıysa streak sıfırlanır
    final studiedToday = studiedDays.contains(todayKey);
    final studiedYesterday = studiedDays.contains(yesterdayKey);
    
    if (!studiedToday && !studiedYesterday) {
      // Streak kırıldı ama toplam çalışılan gün sayısını göster
      await prefs.setInt(_currentStreakKey, 0);
      return;
    }
    
    // Ardışık günleri say
    int streak = 0;
    int startOffset = studiedToday ? 0 : 1; // Bugün çalışılmadıysa dünden başla
    
    for (int i = startOffset; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      
      if (studiedDays.contains(dateKey)) {
        streak++;
      } else {
        break; // İlk boş günde dur
      }
    }
    
    await prefs.setInt(_currentStreakKey, streak);
    
    // En uzun streak'i güncelle
    final longestStreak = prefs.getInt(_longestStreakKey) ?? 0;
    if (streak > longestStreak) {
      await prefs.setInt(_longestStreakKey, streak);
    }
  }
  
  /// Toplam çalışılan gün sayısı
  static Future<int> getTotalStudiedDays() async {
    final studiedDays = await getStudiedDays();
    return studiedDays.length;
  }
  
  /// İlk çalışma tarihi
  static Future<DateTime?> getFirstStudyDate() async {
    final studiedDays = await getStudiedDays();
    if (studiedDays.isEmpty) return null;
    
    final sorted = studiedDays.toList()..sort();
    final parts = sorted.first.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
  
  /// Kaç gündür kullanıyorsun (ilk günden bugüne)
  static Future<int> getDaysSinceStart() async {
    final firstDate = await getFirstStudyDate();
    if (firstDate == null) return 0;
    
    return DateTime.now().difference(firstDate).inDays + 1;
  }

  /// Tarih key'i oluştur (YYYY-MM-DD formatında)
  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Tüm verileri sıfırla (test için)
  static Future<void> reset() async {
    final prefs = await _instance;
    _prefs = null; // Reset singleton
    await prefs.remove(_streakDaysKey);
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_longestStreakKey);
    await prefs.remove(_lastStudyDateKey);
  }

  /// Demo verisi ekle (test için)
  static Future<void> addDemoData() async {
    final today = DateTime.now();
    
    // Son 30 günden rastgele günler ekle
    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      // %70 ihtimalle çalışılmış olarak işaretle
      if (i % 3 != 0) {
        await markDayAsStudied(date);
      }
    }
  }
}
