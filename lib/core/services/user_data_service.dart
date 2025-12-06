import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UserDataService - Local-First Pattern
/// Firebase maliyetini %99 azaltır
/// Favoriler ve yanlış cevaplar lokal olarak saklanır
/// ⚡ GÜNDE 1 KERE toplu Firebase sync (tek write)
class UserDataService {
  static const _favoritesKey = 'user_favorites_v2';
  static const _wrongAnswersKey = 'user_wrong_answers_v2';
  static const _lastSyncKey = 'user_data_last_sync';
  static const _lastDailySyncKey = 'user_data_last_daily_sync';
  
  // ⚡ SINGLETON: Tek SharedPreferences instance
  static SharedPreferences? _prefs;
  static bool _initialSyncDone = false;
  
  // ⚡ DIRTY FLAG: Sadece değişiklik varsa sync yap
  static bool _isDirty = false;
  
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAVORİLER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Favorileri lokal'den getir (0 Firebase okuma)
  static Future<Set<String>> getFavorites() async {
    final prefs = await _instance;
    final list = prefs.getStringList(_favoritesKey) ?? [];
    
    // ⚡ SADECE İLK AÇILIŞTA Firebase'den çek + günlük sync kontrol
    if (!_initialSyncDone) {
      _initialSyncDone = true;
      unawaited(_syncFromFirebaseOnce());
      unawaited(_dailySyncToFirebase()); // Günlük sync kontrolü
    }
    
    return list.toSet();
  }

  /// Favori ekle/çıkar (lokal + lazy sync)
  static Future<void> toggleFavorite(String questionId) async {
    final prefs = await _instance;
    final favorites = (prefs.getStringList(_favoritesKey) ?? []).toSet();
    
    if (favorites.contains(questionId)) {
      favorites.remove(questionId);
    } else {
      favorites.add(questionId);
    }
    
    await prefs.setStringList(_favoritesKey, favorites.toList());
    _isDirty = true; // ⚡ Değişiklik var
  }

  /// Soru favorilerde mi? (0 Firebase okuma)
  static Future<bool> isFavorite(String questionId) async {
    final prefs = await _instance;
    final list = prefs.getStringList(_favoritesKey) ?? [];
    return list.contains(questionId);
  }

  /// Tüm favorileri temizle (tek işlem)
  static Future<void> clearAllFavorites() async {
    final prefs = await _instance;
    await prefs.setStringList(_favoritesKey, []);
    _isDirty = true; // ⚡ Değişiklik var
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // YANLIŞ CEVAPLAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Yanlış cevapları lokal'den getir (0 Firebase okuma)
  static Future<Set<String>> getWrongAnswers() async {
    final prefs = await _instance;
    final list = prefs.getStringList(_wrongAnswersKey) ?? [];
    return list.toSet();
  }

  /// Yanlış cevap ekle
  static Future<void> addWrongAnswer(String questionId) async {
    final prefs = await _instance;
    final wrongAnswers = (prefs.getStringList(_wrongAnswersKey) ?? []).toSet();
    
    wrongAnswers.add(questionId);
    await prefs.setStringList(_wrongAnswersKey, wrongAnswers.toList());
    _isDirty = true; // ⚡ Değişiklik var
  }

  /// Yanlış cevabı sil
  static Future<void> removeWrongAnswer(String questionId) async {
    final prefs = await _instance;
    final wrongAnswers = (prefs.getStringList(_wrongAnswersKey) ?? []).toSet();
    
    wrongAnswers.remove(questionId);
    await prefs.setStringList(_wrongAnswersKey, wrongAnswers.toList());
    _isDirty = true; // ⚡ Değişiklik var
  }

  /// Tüm yanlışları temizle
  static Future<void> clearWrongAnswers() async {
    final prefs = await _instance;
    await prefs.setStringList(_wrongAnswersKey, []);
    _isDirty = true; // ⚡ Değişiklik var
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIREBASE SYNC (Sadece Login/Logout)
  // ═══════════════════════════════════════════════════════════════════════════

  /// ⚡ İLK AÇILIŞTA TEK SEFER Firebase'den çek (günde 1 kere)
  static Future<void> _syncFromFirebaseOnce() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final prefs = await _instance;
      final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
      final now = DateTime.now();
      final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastSync);
      
      // Aynı gün içinde zaten sync yapıldıysa skip
      if (lastSync > 0 && 
          now.year == lastSyncDate.year && 
          now.month == lastSyncDate.month && 
          now.day == lastSyncDate.day) {
        return;
      }

      // TEK document okuma
      final doc = await FirebaseFirestore.instance
          .collection('userData')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final favorites = List<String>.from(data['favorites'] ?? []);
        final wrongAnswers = List<String>.from(data['wrongAnswers'] ?? []);
        await prefs.setStringList(_favoritesKey, favorites);
        await prefs.setStringList(_wrongAnswersKey, wrongAnswers);
      }
      
      await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);
    } catch (_) {
      // Sync hatası - sessizce devam et
    }
  }

  /// ⚡ GÜNDE 1 KERE Firebase'e toplu sync (tek write)
  /// Sadece kayıtlı (email doğrulanmış veya Google ile giriş yapmış) üyeler için
  static Future<void> _dailySyncToFirebase() async {
    // Değişiklik yoksa sync yapma
    if (!_isDirty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Anonim kullanıcılar için Firebase'e yazma
    if (user.isAnonymous) return;
    
    final userId = user.uid;

    try {
      final prefs = await _instance;
      final lastDailySync = prefs.getInt(_lastDailySyncKey) ?? 0;
      final now = DateTime.now();
      final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastDailySync);
      
      // Aynı gün içinde zaten sync yapıldıysa skip
      if (lastDailySync > 0 && 
          now.year == lastSyncDate.year && 
          now.month == lastSyncDate.month && 
          now.day == lastSyncDate.day) {
        return;
      }

      final favorites = prefs.getStringList(_favoritesKey) ?? [];
      final wrongAnswers = prefs.getStringList(_wrongAnswersKey) ?? [];

      // TEK yazma işlemi - tüm data
      await FirebaseFirestore.instance
          .collection('userData')
          .doc(userId)
          .set({
        'favorites': favorites,
        'wrongAnswers': wrongAnswers,
        'lastSync': FieldValue.serverTimestamp(),
        'favoritesCount': favorites.length,
        'wrongAnswersCount': wrongAnswers.length,
      }, SetOptions(merge: true));
      
      await prefs.setInt(_lastDailySyncKey, now.millisecondsSinceEpoch);
      _isDirty = false;
    } catch (_) {
      // Sync hatası - lokal data korunur
    }
  }

  /// ⚡ LOGOUT'TA TEK SEFER Firebase'e yaz - SADECE DEĞİŞİKLİK VARSA
  /// Sadece kayıtlı üyeler için
  static Future<void> _syncToFirebase() async {
    // ⚡ Değişiklik yoksa Firebase'e gitme!
    if (!_isDirty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Anonim kullanıcılar için Firebase'e yazma
    if (user.isAnonymous) return;
    
    final userId = user.uid;

    try {
      final prefs = await _instance;
      final favorites = prefs.getStringList(_favoritesKey) ?? [];
      final wrongAnswers = prefs.getStringList(_wrongAnswersKey) ?? [];

      // TEK yazma işlemi
      await FirebaseFirestore.instance
          .collection('userData')
          .doc(userId)
          .set({
        'favorites': favorites,
        'wrongAnswers': wrongAnswers,
        'lastSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      _isDirty = false; // ⚡ Sync yapıldı, dirty flag sıfırla
    } catch (_) {
      // Sync hatası - lokal data korunur, dirty flag kalır
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC SYNC METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Manuel sync tetikle (ayarlar sayfasından)
  static Future<void> forceSync() async {
    final prefs = await _instance;
    await prefs.remove(_lastSyncKey);
    _initialSyncDone = false;
    await _syncFromFirebaseOnce();
  }

  /// ⚡ Çıkış yaparken tüm data'yı sync et - TEK ÇAĞRI
  static Future<void> syncBeforeLogout() async {
    await _syncToFirebase();
  }

  /// Lokal cache temizle (logout sonrası)
  static Future<void> clearLocalCache() async {
    final prefs = await _instance;
    await prefs.remove(_favoritesKey);
    await prefs.remove(_wrongAnswersKey);
    await prefs.remove(_lastSyncKey);
    _initialSyncDone = false;
    _isDirty = false; // Reset dirty flag
    _prefs = null; // Reset singleton
  }
  
  /// ⚡ Değişiklik var mı? (Debug için)
  static bool get hasPendingChanges => _isDirty;
}
