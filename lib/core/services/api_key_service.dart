import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API Key'i Firebase'den alıp local'de cache'leyen servis
class ApiKeyService {
  static const String _cacheKey = 'openrouter_api_key';
  static const String _cacheTimeKey = 'openrouter_api_key_time';
  static const Duration _cacheDuration = Duration(days: 1); // Günde 1 kere güncelle
  
  static String? _cachedKey;
  
  /// API Key'i al (önce cache, sonra Firebase)
  static Future<String> getApiKey() async {
    // 1. Memory cache'de varsa direkt döndür
    if (_cachedKey != null && _cachedKey!.isNotEmpty) {
      return _cachedKey!;
    }
    
    // 2. SharedPreferences'dan kontrol et
    final prefs = await SharedPreferences.getInstance();
    final cachedKey = prefs.getString(_cacheKey);
    final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Cache geçerli mi? (1 günden eski değilse)
    if (cachedKey != null && cachedKey.isNotEmpty) {
      final cacheAge = Duration(milliseconds: now - cacheTime);
      if (cacheAge < _cacheDuration) {
        _cachedKey = cachedKey;
        return cachedKey;
      }
    }
    
    // 3. Firebase'den al
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('api_keys')
          .get();
      
      if (doc.exists) {
        final key = doc.data()?['openrouter_api_key'] as String?;
        if (key != null && key.isNotEmpty) {
          // Cache'e kaydet
          await prefs.setString(_cacheKey, key);
          await prefs.setInt(_cacheTimeKey, now);
          _cachedKey = key;
          return key;
        }
      }
      
      throw Exception('API Key bulunamadı');
    } catch (e) {
      // Firebase'den alamadıysak eski cache'i kullan
      if (cachedKey != null && cachedKey.isNotEmpty) {
        _cachedKey = cachedKey;
        return cachedKey;
      }
      rethrow;
    }
  }
  
  /// Cache'i temizle (debug için)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
    _cachedKey = null;
  }
}
