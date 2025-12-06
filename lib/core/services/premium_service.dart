import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Premium kullanıcı kontrolü
class PremiumService {
  static const String _cacheKey = 'is_premium_user';
  static const String _cacheTimeKey = 'premium_check_time';
  static const Duration _cacheDuration = Duration(hours: 6);
  
  static bool? _cachedPremium;
  
  /// SEN - Sınırsız hak
  static const List<String> _premiumEmails = [
    'mertcancilingir@gmail.com',
  ];
  
  /// Premium kullanıcı mı kontrol et
  /// TODO: Şimdilik herkes premium, sonra düşürülecek
  static Future<bool> isPremium() async {
    // 🎁 LANSMAN DÖNEMİ - HERKES PREMIUM
    return true;
    
    // ignore: dead_code
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    // 1. Email listesinde mi?
    if (_premiumEmails.contains(user.email)) {
      return true;
    }
    
    // 2. Memory cache
    if (_cachedPremium != null) {
      return _cachedPremium!;
    }
    
    // 3. SharedPreferences cache
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(_cacheKey);
    final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (cached != null) {
      final cacheAge = Duration(milliseconds: now - cacheTime);
      if (cacheAge < _cacheDuration) {
        _cachedPremium = cached;
        return cached;
      }
    }
    
    // 4. Firebase'den kontrol et
    try {
      final doc = await FirebaseFirestore.instance
          .collection('premium_users')
          .doc(user.uid)
          .get();
      
      final isPremium = doc.exists && (doc.data()?['active'] == true);
      
      // Cache'e kaydet
      await prefs.setBool(_cacheKey, isPremium);
      await prefs.setInt(_cacheTimeKey, now);
      _cachedPremium = isPremium;
      
      return isPremium;
    } catch (e) {
      // Hata durumunda cache'i kullan
      return cached ?? false;
    }
  }
  
  /// Cache temizle
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
    _cachedPremium = null;
  }
}
