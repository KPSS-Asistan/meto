import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';

/// 🔒 API Key'i Firebase'den alıp SECURE STORAGE'da cache'leyen servis
/// SharedPreferences yerine flutter_secure_storage kullanılıyor (AES-256 şifreleme)
class ApiKeyService {
  static const String _cacheKey = 'openrouter_api_key_secure';
  static const String _cacheTimeKey = 'openrouter_api_key_time_secure';
  static const Duration _cacheDuration = Duration(days: 1);
  
  static String? _cachedKey;
  
  // 🔒 Güvenli depolama - AES-256 şifreleme
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Android EncryptedSharedPreferences
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device, // iOS Keychain
    ),
  );
  
  /// API Key'i al (önce cache, sonra Firebase)
  static Future<String> getApiKey() async {
    // 1. Memory cache'de varsa direkt döndür
    if (_cachedKey != null && _cachedKey!.isNotEmpty) {
      return _cachedKey!;
    }
    
    // 2. Secure Storage'dan kontrol et
    try {
      final cachedKey = await _secureStorage.read(key: _cacheKey);
      final cacheTimeStr = await _secureStorage.read(key: _cacheTimeKey);
      final cacheTime = int.tryParse(cacheTimeStr ?? '0') ?? 0;
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
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('api_keys')
          .get();
      
      if (doc.exists) {
        final key = doc.data()?['openrouter_api_key'] as String?;
        if (key != null && key.isNotEmpty) {
          // 🔒 Secure Storage'a kaydet (şifrelenmiş)
          await _secureStorage.write(key: _cacheKey, value: key);
          await _secureStorage.write(key: _cacheTimeKey, value: now.toString());
          _cachedKey = key;
          AppLogger.info('API Key fetched from Firebase and cached securely');
          return key;
        }
      }
      
      throw Exception('API Key bulunamadı');
    } catch (e) {
      // Firebase'den alamadıysak eski cache'i kullan
      final cachedKey = await _secureStorage.read(key: _cacheKey);
      if (cachedKey != null && cachedKey.isNotEmpty) {
        _cachedKey = cachedKey;
        AppLogger.warning('Using cached API key due to error: $e');
        return cachedKey;
      }
      AppLogger.error('API Key fetch failed', e);
      rethrow;
    }
  }
  
  /// Cache'i temizle
  static Future<void> clearCache() async {
    await _secureStorage.delete(key: _cacheKey);
    await _secureStorage.delete(key: _cacheTimeKey);
    _cachedKey = null;
  }
  
  /// API Key mevcut mu?
  static Future<bool> hasApiKey() async {
    if (_cachedKey != null) return true;
    final key = await _secureStorage.read(key: _cacheKey);
    return key != null && key.isNotEmpty;
  }
}
