import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:safe_device/safe_device.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';

/// 🔒 GÜVENLİK SERVİSİ
/// Root/Jailbreak detection, emulator detection, debug detection
/// ve diğer güvenlik kontrollerini yönetir.
class SecurityService {
  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();
  
  SecurityService._();
  
  // Güvenlik durumu cache
  bool? _isDeviceSecure;
  bool? _isJailbroken;
  bool? _isRealDevice;
  bool? _isOnExternalStorage;
  bool? _isMockLocation;
  
  /// Tam güvenlik kontrolü yap
  /// Returns: true = güvenli, false = güvenlik riski var
  Future<SecurityCheckResult> performFullSecurityCheck() async {
    final results = SecurityCheckResult();
    
    try {
      // 1. Debug mode kontrolü
      results.isDebugMode = kDebugMode;
      
      // 2. Release mode kontrolü
      results.isReleaseMode = kReleaseMode;
      
      // 3. Root/Jailbreak kontrolü
      results.isJailbroken = await _checkJailbreak();
      
      // 4. Emulator kontrolü
      results.isEmulator = await _checkEmulator();
      
      // 5. Gerçek cihaz kontrolü
      results.isRealDevice = await _checkRealDevice();
      
      // 6. Mock location kontrolü
      results.hasMockLocation = await _checkMockLocation();
      
      // 7. Harici depolama kontrolü (Android)
      results.isOnExternalStorage = await _checkExternalStorage();
      
      // 8. Developer options kontrolü
      results.hasDeveloperOptions = await _checkDeveloperOptions();
      
      // Genel güvenlik durumu
      results.isSecure = !results.isJailbroken && 
                         !results.isEmulator && 
                         results.isRealDevice &&
                         !results.hasMockLocation;
      
      _isDeviceSecure = results.isSecure;
      
      AppLogger.info('Security check completed: ${results.isSecure ? "SECURE" : "RISK DETECTED"}');
      
    } catch (e) {
      AppLogger.error('Security check failed', e);
      results.error = e.toString();
    }
    
    return results;
  }
  
  /// Root/Jailbreak kontrolü
  Future<bool> _checkJailbreak() async {
    try {
      _isJailbroken = await FlutterJailbreakDetection.jailbroken;
      return _isJailbroken!;
    } catch (e) {
      AppLogger.warning('Jailbreak check failed: $e');
      return false;
    }
  }
  
  /// Emulator kontrolü
  Future<bool> _checkEmulator() async {
    try {
      final isRealDevice = await SafeDevice.isRealDevice;
      return !isRealDevice;
    } catch (e) {
      AppLogger.warning('Emulator check failed: $e');
      return false;
    }
  }
  
  /// Gerçek cihaz kontrolü
  Future<bool> _checkRealDevice() async {
    try {
      _isRealDevice = await SafeDevice.isRealDevice;
      return _isRealDevice!;
    } catch (e) {
      AppLogger.warning('Real device check failed: $e');
      return true; // Hata durumunda güvenli varsay
    }
  }
  
  /// Mock location kontrolü
  Future<bool> _checkMockLocation() async {
    try {
      _isMockLocation = await SafeDevice.isMockLocation;
      return _isMockLocation!;
    } catch (e) {
      AppLogger.warning('Mock location check failed: $e');
      return false;
    }
  }
  
  /// Harici depolama kontrolü (Android)
  Future<bool> _checkExternalStorage() async {
    try {
      if (Platform.isAndroid) {
        _isOnExternalStorage = await SafeDevice.isOnExternalStorage;
        return _isOnExternalStorage!;
      }
      return false;
    } catch (e) {
      AppLogger.warning('External storage check failed: $e');
      return false;
    }
  }
  
  /// Developer options kontrolü
  Future<bool> _checkDeveloperOptions() async {
    try {
      // Android'de developer options kontrolü
      if (Platform.isAndroid) {
        return await SafeDevice.isDevelopmentModeEnable;
      }
      return false;
    } catch (e) {
      AppLogger.warning('Developer options check failed: $e');
      return false;
    }
  }
  
  /// Developer mode aktif mi?
  Future<bool> isDeveloperModeEnabled() async {
    try {
      return await SafeDevice.isDevelopmentModeEnable;
    } catch (e) {
      return false;
    }
  }
  
  /// Screenshot engelleme (Android)
  /// Bu fonksiyon Activity'de FLAG_SECURE ayarlar
  static Future<void> enableScreenshotProtection() async {
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.kpssasistan.app/security');
        await platform.invokeMethod('enableSecureFlag');
        AppLogger.info('Screenshot protection enabled');
      } catch (e) {
        AppLogger.warning('Screenshot protection failed: $e');
      }
    }
  }
  
  /// Screenshot engellemeyi kaldır
  static Future<void> disableScreenshotProtection() async {
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.kpssasistan.app/security');
        await platform.invokeMethod('disableSecureFlag');
      } catch (e) {
        AppLogger.warning('Disable screenshot protection failed: $e');
      }
    }
  }
  
  /// Hızlı güvenlik kontrolü (cached)
  bool get isDeviceSecure => _isDeviceSecure ?? true;
  bool get isJailbroken => _isJailbroken ?? false;
  bool get isRealDevice => _isRealDevice ?? true;
  
  /// Cache temizle
  void clearCache() {
    _isDeviceSecure = null;
    _isJailbroken = null;
    _isRealDevice = null;
    _isOnExternalStorage = null;
    _isMockLocation = null;
  }
}

/// Güvenlik kontrolü sonuçları
class SecurityCheckResult {
  bool isSecure = true;
  bool isDebugMode = false;
  bool isReleaseMode = true;
  bool isJailbroken = false;
  bool isEmulator = false;
  bool isRealDevice = true;
  bool hasMockLocation = false;
  bool isOnExternalStorage = false;
  bool hasDeveloperOptions = false;
  String? error;
  
  /// Tüm riskleri listele
  List<String> get risks {
    final list = <String>[];
    if (isJailbroken) list.add('Root/Jailbreak tespit edildi');
    if (isEmulator) list.add('Emulator tespit edildi');
    if (!isRealDevice) list.add('Gerçek cihaz değil');
    if (hasMockLocation) list.add('Sahte konum tespit edildi');
    if (isOnExternalStorage) list.add('Uygulama harici depolamada');
    if (hasDeveloperOptions) list.add('Geliştirici seçenekleri açık');
    if (isDebugMode) list.add('Debug modunda çalışıyor');
    return list;
  }
  
  /// Risk seviyesi (0-10)
  int get riskLevel {
    int level = 0;
    if (isJailbroken) level += 4;
    if (isEmulator) level += 2;
    if (!isRealDevice) level += 2;
    if (hasMockLocation) level += 1;
    if (isOnExternalStorage) level += 1;
    return level.clamp(0, 10);
  }
  
  @override
  String toString() {
    return '''
SecurityCheckResult:
  isSecure: $isSecure
  riskLevel: $riskLevel/10
  risks: ${risks.join(', ')}
  isDebugMode: $isDebugMode
  isReleaseMode: $isReleaseMode
  isJailbroken: $isJailbroken
  isEmulator: $isEmulator
  isRealDevice: $isRealDevice
  hasMockLocation: $hasMockLocation
  isOnExternalStorage: $isOnExternalStorage
  hasDeveloperOptions: $hasDeveloperOptions
''';
  }
}
