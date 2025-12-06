import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Güvenli Veri Saklama Servisi
/// 
/// Hassas verileri şifreli olarak saklar:
/// - API anahtarları
/// - Kullanıcı token'ları
/// - Premium durumu
/// - Özel ayarlar
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // ═══════════════════════════════════════════════════════════════════════════
  // KEYS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String _keyApiKey = 'openrouter_api_key';
  static const String _keyUserToken = 'user_auth_token';
  static const String _keyPremiumStatus = 'premium_status';
  static const String _keyPremiumExpiry = 'premium_expiry';
  static const String _keyUserId = 'user_id';
  static const String _keyRefreshToken = 'refresh_token';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // GENERIC METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Değer kaydet
  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  /// Değer oku
  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
  
  /// Değer sil
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
  
  /// Tüm verileri sil
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
  
  /// Anahtar var mı kontrol et
  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // API KEY
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// API anahtarını kaydet
  static Future<void> saveApiKey(String apiKey) async {
    await write(_keyApiKey, apiKey);
  }
  
  /// API anahtarını oku
  static Future<String?> getApiKey() async {
    return await read(_keyApiKey);
  }
  
  /// API anahtarını sil
  static Future<void> deleteApiKey() async {
    await delete(_keyApiKey);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // USER AUTH
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Kullanıcı token'ını kaydet
  static Future<void> saveUserToken(String token) async {
    await write(_keyUserToken, token);
  }
  
  /// Kullanıcı token'ını oku
  static Future<String?> getUserToken() async {
    return await read(_keyUserToken);
  }
  
  /// Kullanıcı ID'sini kaydet
  static Future<void> saveUserId(String userId) async {
    await write(_keyUserId, userId);
  }
  
  /// Kullanıcı ID'sini oku
  static Future<String?> getUserId() async {
    return await read(_keyUserId);
  }
  
  /// Refresh token kaydet
  static Future<void> saveRefreshToken(String token) async {
    await write(_keyRefreshToken, token);
  }
  
  /// Refresh token oku
  static Future<String?> getRefreshToken() async {
    return await read(_keyRefreshToken);
  }
  
  /// Kullanıcı verilerini temizle (logout)
  static Future<void> clearUserData() async {
    await delete(_keyUserToken);
    await delete(_keyUserId);
    await delete(_keyRefreshToken);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM STATUS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Premium durumunu kaydet
  static Future<void> savePremiumStatus(bool isPremium, {DateTime? expiryDate}) async {
    await write(_keyPremiumStatus, isPremium.toString());
    if (expiryDate != null) {
      await write(_keyPremiumExpiry, expiryDate.toIso8601String());
    }
  }
  
  /// Premium durumunu oku
  static Future<bool> isPremium() async {
    final status = await read(_keyPremiumStatus);
    if (status != 'true') return false;
    
    // Süre kontrolü
    final expiryStr = await read(_keyPremiumExpiry);
    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && expiry.isBefore(DateTime.now())) {
        // Süre dolmuş
        await clearPremiumStatus();
        return false;
      }
    }
    
    return true;
  }
  
  /// Premium bitiş tarihini oku
  static Future<DateTime?> getPremiumExpiry() async {
    final expiryStr = await read(_keyPremiumExpiry);
    if (expiryStr == null) return null;
    return DateTime.tryParse(expiryStr);
  }
  
  /// Premium durumunu temizle
  static Future<void> clearPremiumStatus() async {
    await delete(_keyPremiumStatus);
    await delete(_keyPremiumExpiry);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MIGRATION - SharedPreferences'tan taşıma
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// SharedPreferences'tan hassas verileri taşı
  /// Bu metod bir kez çalıştırılmalı
  static Future<void> migrateFromSharedPreferences({
    String? apiKey,
    String? userToken,
    bool? isPremium,
  }) async {
    if (apiKey != null && apiKey.isNotEmpty) {
      await saveApiKey(apiKey);
    }
    if (userToken != null && userToken.isNotEmpty) {
      await saveUserToken(userToken);
    }
    if (isPremium != null) {
      await savePremiumStatus(isPremium);
    }
  }
}
