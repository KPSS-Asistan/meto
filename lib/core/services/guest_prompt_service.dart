import 'package:firebase_auth/firebase_auth.dart';
import 'prefs_service.dart';

/// Misafir kullanıcı kayıt dönüşümü servisi
/// Tetikleyicileri yönetir, gösterim sayısını takip eder
/// ⚡ OPTIMIZED: PrefsService singleton kullanır
class GuestPromptService {
  static const _keyQuestionsAnswered = 'guest_questions_answered';
  static const _keyPromptDismissedAt = 'guest_prompt_dismissed_at';
  static const _keyPromptShownCount = 'guest_prompt_shown_count';
  
  // Singleton
  static final GuestPromptService _instance = GuestPromptService._internal();
  factory GuestPromptService() => _instance;
  GuestPromptService._internal();

  // ─────────────────────────────────────────────────────────────
  // KULLANICI DURUMU
  // ─────────────────────────────────────────────────────────────
  
  /// Kullanıcı anonim mi?
  static bool isAnonymous() {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous;
  }
  
  /// Kullanıcı giriş yapmış mı? (anonim değil)
  static bool isRegistered() {
    return !isAnonymous();
  }

  // ─────────────────────────────────────────────────────────────
  // SORU SAYACI
  // ─────────────────────────────────────────────────────────────
  
  /// Çözülen soru sayısını artır
  Future<int> incrementQuestionsAnswered() async {
    final prefs = await PrefsService.instance;
    final current = prefs.getInt(_keyQuestionsAnswered) ?? 0;
    final newCount = current + 1;
    await prefs.setInt(_keyQuestionsAnswered, newCount);
    return newCount;
  }
  
  /// Çözülen soru sayısını al
  Future<int> getQuestionsAnswered() async {
    final prefs = await PrefsService.instance;
    return prefs.getInt(_keyQuestionsAnswered) ?? 0;
  }
  
  /// Soru sayısını sıfırla (kayıt olduktan sonra)
  Future<void> resetQuestionsAnswered() async {
    final prefs = await PrefsService.instance;
    await prefs.remove(_keyQuestionsAnswered);
  }

  // ─────────────────────────────────────────────────────────────
  // TETİKLEYİCİLER
  // ─────────────────────────────────────────────────────────────
  
  /// Progress prompt gösterilmeli mi? (5+ soru)
  Future<bool> shouldShowProgressPrompt() async {
    if (!isAnonymous()) return false;
    
    final questionsAnswered = await getQuestionsAnswered();
    if (questionsAnswered < 5) return false;
    
    // Son 24 saatte dismiss edilmişse gösterme
    if (await _wasRecentlyDismissed()) return false;
    
    return true;
  }
  
  /// Feature gate gösterilmeli mi?
  static bool shouldShowFeatureGate(String feature) {
    if (!isAnonymous()) return false;
    
    const gatedFeatures = [
      'favorites',
      'ai_coach_extended', // 3+ mesajdan sonra
      'flashcards',
      'stories',
      'study_schedule',
    ];
    
    return gatedFeatures.contains(feature);
  }
  
  /// Exit prompt gösterilmeli mi? (10+ soru)
  Future<bool> shouldShowExitPrompt() async {
    if (!isAnonymous()) return false;
    
    final questionsAnswered = await getQuestionsAnswered();
    return questionsAnswered >= 10;
  }

  // ─────────────────────────────────────────────────────────────
  // DİSMİSS YÖNETİMİ
  // ─────────────────────────────────────────────────────────────
  
  /// Prompt dismiss edildi olarak işaretle
  Future<void> markPromptDismissed() async {
    final prefs = await PrefsService.instance;
    await prefs.setInt(_keyPromptDismissedAt, DateTime.now().millisecondsSinceEpoch);
    
    // Gösterim sayısını artır
    final count = prefs.getInt(_keyPromptShownCount) ?? 0;
    await prefs.setInt(_keyPromptShownCount, count + 1);
  }
  
  /// Son 24 saatte dismiss edilmiş mi?
  Future<bool> _wasRecentlyDismissed() async {
    final prefs = await PrefsService.instance;
    final dismissedAt = prefs.getInt(_keyPromptDismissedAt);
    
    if (dismissedAt == null) return false;
    
    final dismissedTime = DateTime.fromMillisecondsSinceEpoch(dismissedAt);
    final hoursSinceDismiss = DateTime.now().difference(dismissedTime).inHours;
    
    return hoursSinceDismiss < 24;
  }
  
  /// Prompt kaç kez gösterilmiş?
  Future<int> getPromptShownCount() async {
    final prefs = await PrefsService.instance;
    return prefs.getInt(_keyPromptShownCount) ?? 0;
  }

  // ─────────────────────────────────────────────────────────────
  // TEMİZLİK (Kayıt sonrası)
  // ─────────────────────────────────────────────────────────────
  
  /// Tüm guest verilerini temizle
  Future<void> clearAllGuestData() async {
    final prefs = await PrefsService.instance;
    await prefs.remove(_keyQuestionsAnswered);
    await prefs.remove(_keyPromptDismissedAt);
    await prefs.remove(_keyPromptShownCount);
  }
}
