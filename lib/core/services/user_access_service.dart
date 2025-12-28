import 'package:firebase_auth/firebase_auth.dart';
import 'prefs_service.dart';
import 'premium_service.dart';

/// Kullanıcı Erişim Yönetimi
/// Misafir, Kayıtlı ve Pro kullanıcılar için farklı limitler
class UserAccessService {
  static const String _keyDailyQuestions = 'daily_questions_count';
  static const String _keyLastQuestionDate = 'last_question_date';
  
  // Günlük soru limitleri
  static const int guestDailyLimit = 20;
  static const int registeredDailyLimit = 50;
  static const int proDailyLimit = 999999; // Sınırsız
  
  static Future<dynamic> get _instance async => PrefsService.instance;
  
  /// Kullanıcıya özel storage key (UID bazlı)
  static String _getUserKey(String baseKey) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'guest';
    return '${baseKey}_$uid';
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // KULLANICI TİPİ KONTROL
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Kullanıcı anonim mi?
  static bool isGuest() {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous;
  }
  
  /// Kullanıcı kayıtlı mı (anonim değil)?
  static bool isRegistered() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && !user.isAnonymous;
  }
  
  /// Kullanıcı premium mi?
  static Future<bool> isPro() async {
    return await PremiumService.checkPremium();
  }
  
  /// Premium cache'i temizle (login/logout sonrası)
  static void clearPremiumCache() {
    // Cache artık PremiumService'te yönetiliyor
    // Bu metod geriye uyumluluk için korunuyor
  }
  
  /// Kullanıcı tipini döndür
  static Future<UserType> getUserType() async {
    if (await isPro()) return UserType.pro;
    if (isRegistered()) return UserType.registered;
    return UserType.guest;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // GÜNLÜK SORU LİMİTİ
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Bugünkü günlük limit
  static Future<int> getDailyLimit() async {
    final userType = await getUserType();
    switch (userType) {
      case UserType.pro:
        return proDailyLimit;
      case UserType.registered:
        return registeredDailyLimit;
      case UserType.guest:
        return guestDailyLimit;
    }
  }
  
  /// Bugün çözülen soru sayısı (kullanıcıya özel)
  static Future<int> getTodayQuestionsCount() async {
    final prefs = await _instance;
    final today = _getTodayStr();
    final countKey = _getUserKey(_keyDailyQuestions);
    final dateKey = _getUserKey(_keyLastQuestionDate);
    final lastDate = prefs.getString(dateKey);
    
    // Yeni gün başladıysa sıfırla
    if (lastDate != today) {
      await prefs.setInt(countKey, 0);
      await prefs.setString(dateKey, today);
      return 0;
    }
    
    return prefs.getInt(countKey) ?? 0;
  }
  
  /// Kalan soru hakkı
  static Future<int> getRemainingQuestions() async {
    final limit = await getDailyLimit();
    final used = await getTodayQuestionsCount();
    return (limit - used).clamp(0, limit);
  }
  
  /// Soru çözülebilir mi?
  static Future<QuestionAccessResult> canSolveQuestion() async {
    final userType = await getUserType();
    
    // 🎯 Premium kullanıcılar sınırsız erişime sahip
    if (userType == UserType.pro) {
      return QuestionAccessResult(
        canAccess: true,
        remaining: -1, // -1 = sınırsız
        userType: userType,
        isUnlimited: true,
      );
    }
    
    final remaining = await getRemainingQuestions();
    
    if (remaining > 0) {
      return QuestionAccessResult(
        canAccess: true,
        remaining: remaining,
        userType: userType,
      );
    }
    
    // Limit doldu
    return QuestionAccessResult(
      canAccess: false,
      remaining: 0,
      userType: userType,
      message: userType == UserType.guest
          ? 'Günlük 20 soru limitine ulaştın. Daha fazlası için giriş yap!'
          : 'Günlük 50 soru limitine ulaştın. Sınırsız erişim için Pro\'ya geç!',
      upgradeMessage: userType == UserType.guest
          ? 'Giriş yap'
          : userType == UserType.registered
              ? 'Pro\'ya geç'
              : null,
    );
  }
  
  /// Soru çözüldüğünde say (kullanıcıya özel)
  static Future<void> incrementQuestionCount() async {
    final prefs = await _instance;
    final today = _getTodayStr();
    final countKey = _getUserKey(_keyDailyQuestions);
    final dateKey = _getUserKey(_keyLastQuestionDate);
    final lastDate = prefs.getString(dateKey);
    
    int count = 0;
    if (lastDate == today) {
      count = prefs.getInt(countKey) ?? 0;
    } else {
      await prefs.setString(dateKey, today);
    }
    
    await prefs.setInt(countKey, count + 1);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ÖZELLİK ERİŞİMİ
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// AI Koç erişimi var mı?
  static Future<FeatureAccessResult> canAccessAiCoach() async {
    if (isGuest()) {
      return FeatureAccessResult(
        canAccess: false,
        feature: 'AI Koç',
        message: 'AI Koç\'u kullanmak için giriş yap',
        upgradeAction: UpgradeAction.login,
      );
    }
    return FeatureAccessResult(canAccess: true, feature: 'AI Koç');
  }
  
  /// Performans istatistikleri erişimi var mı?
  static Future<FeatureAccessResult> canAccessPerformance() async {
    if (isGuest()) {
      return FeatureAccessResult(
        canAccess: false,
        feature: 'Performans',
        message: 'İstatistiklerini görmek için giriş yap',
        upgradeAction: UpgradeAction.login,
      );
    }
    return FeatureAccessResult(canAccess: true, feature: 'Performans');
  }
  
  /// Flashcard erişimi var mı?
  static Future<FeatureAccessResult> canAccessFlashcards() async {
    if (isGuest()) {
      return FeatureAccessResult(
        canAccess: false,
        feature: 'Flashcard',
        message: 'Flashcard\'ları kullanmak için giriş yap',
        upgradeAction: UpgradeAction.login,
      );
    }
    
    // Kayıtlı kullanıcılar için premium kontrolü
    if (!await isPro()) {
      return FeatureAccessResult(
        canAccess: false,
        feature: 'Flashcard',
        message: 'Flashcard\'lar Pro üyelere özel',
        upgradeAction: UpgradeAction.upgrade,
      );
    }
    
    return FeatureAccessResult(canAccess: true, feature: 'Flashcard');
  }
  
  /// Hikayeler erişimi var mı?
  static Future<FeatureAccessResult> canAccessStories() async {
    if (isGuest()) {
      return FeatureAccessResult(
        canAccess: false,
        feature: 'Hikayeler',
        message: 'Hikayeleri okumak için giriş yap',
        upgradeAction: UpgradeAction.login,
      );
    }
    
    if (!await isPro()) {
      return FeatureAccessResult(
        canAccess: false,
        feature: 'Hikayeler',
        message: 'Hikayeler Pro üyelere özel',
        upgradeAction: UpgradeAction.upgrade,
      );
    }
    
    return FeatureAccessResult(canAccess: true, feature: 'Hikayeler');
  }
  
  /// Favoriler erişimi var mı?
  static Future<FeatureAccessResult> canAccessFavorites() async {
    if (isGuest()) {
      return FeatureAccessResult(
        canAccess: false,
        feature: 'Favoriler',
        message: 'Favorilerini kaydetmek için giriş yap',
        upgradeAction: UpgradeAction.login,
      );
    }
    return FeatureAccessResult(canAccess: true, feature: 'Favoriler');
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String _getTodayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
  
  /// Sayaçları sıfırla (test için)
  static Future<void> resetDailyCount() async {
    final prefs = await _instance;
    await prefs.remove(_keyDailyQuestions);
    await prefs.remove(_keyLastQuestionDate);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELLER
// ═══════════════════════════════════════════════════════════════════════════

enum UserType { guest, registered, pro }

enum UpgradeAction { login, upgrade }

class QuestionAccessResult {
  final bool canAccess;
  final int remaining;
  final UserType userType;
  final String? message;
  final String? upgradeMessage;
  final bool isUnlimited; // Premium kullanıcılar için sınırsız erişim
  
  QuestionAccessResult({
    required this.canAccess,
    required this.remaining,
    required this.userType,
    this.message,
    this.upgradeMessage,
    this.isUnlimited = false,
  });
}

class FeatureAccessResult {
  final bool canAccess;
  final String feature;
  final String? message;
  final UpgradeAction? upgradeAction;
  
  FeatureAccessResult({
    required this.canAccess,
    required this.feature,
    this.message,
    this.upgradeAction,
  });
}
