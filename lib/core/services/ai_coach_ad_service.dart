import 'package:shared_preferences/shared_preferences.dart';

/// AI Koç Rewarded Ad Servisi
/// Ücretsiz kullanıcılar reklam izleyerek soru hakkı kazanabilir
class AICoachAdService {
  static const String _keyBonusQuestions = 'ai_coach_bonus_questions';
  static const String _keyAdsWatchedToday = 'ai_coach_ads_watched_today';
  static const String _keyLastAdDate = 'ai_coach_last_ad_date';
  
  // Günlük reklam limiti
  static const int maxDailyAds = 5;
  // Her reklam için kazanılan soru hakkı
  static const int questionsPerAd = 1;
  
  static SharedPreferences? _prefs;
  
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
  
  /// Bugün izlenen reklam sayısını al
  static Future<int> getAdsWatchedToday() async {
    final prefs = await _instance;
    final lastAdDate = prefs.getString(_keyLastAdDate);
    final today = _getTodayString();
    
    // Yeni gün ise sayacı sıfırla
    if (lastAdDate != today) {
      await prefs.setInt(_keyAdsWatchedToday, 0);
      await prefs.setString(_keyLastAdDate, today);
      return 0;
    }
    
    return prefs.getInt(_keyAdsWatchedToday) ?? 0;
  }
  
  /// Kalan reklam hakkı
  static Future<int> getRemainingAds() async {
    final watched = await getAdsWatchedToday();
    return maxDailyAds - watched;
  }
  
  /// Bonus soru hakkını al
  static Future<int> getBonusQuestions() async {
    final prefs = await _instance;
    return prefs.getInt(_keyBonusQuestions) ?? 0;
  }
  
  /// Bonus soru hakkını kullan
  static Future<bool> useBonusQuestion() async {
    final prefs = await _instance;
    final current = prefs.getInt(_keyBonusQuestions) ?? 0;
    
    if (current <= 0) return false;
    
    await prefs.setInt(_keyBonusQuestions, current - 1);
    return true;
  }
  
  /// Reklam izlendi - bonus hak ekle
  static Future<bool> onAdWatched() async {
    final prefs = await _instance;
    final today = _getTodayString();
    final lastAdDate = prefs.getString(_keyLastAdDate);
    
    // Yeni gün kontrolü
    int adsWatched = prefs.getInt(_keyAdsWatchedToday) ?? 0;
    if (lastAdDate != today) {
      adsWatched = 0;
      await prefs.setString(_keyLastAdDate, today);
    }
    
    // Limit kontrolü
    if (adsWatched >= maxDailyAds) {
      return false;
    }
    
    // Reklam sayacını artır
    await prefs.setInt(_keyAdsWatchedToday, adsWatched + 1);
    
    // Bonus soru hakkı ekle
    final currentBonus = prefs.getInt(_keyBonusQuestions) ?? 0;
    await prefs.setInt(_keyBonusQuestions, currentBonus + questionsPerAd);
    
    return true;
  }
  
  /// Reklam izlenebilir mi?
  static Future<bool> canWatchAd() async {
    final remaining = await getRemainingAds();
    return remaining > 0;
  }
  
  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
