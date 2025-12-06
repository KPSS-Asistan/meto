import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/core/services/security_service.dart';

void main() {
  group('SecurityService Tests', () {
    late SecurityService securityService;

    setUp(() {
      securityService = SecurityService.instance;
      securityService.clearCache();
    });

    test('SecurityCheckResult should have correct default values', () {
      final result = SecurityCheckResult();
      
      expect(result.isSecure, true);
      expect(result.isDebugMode, false);
      expect(result.isReleaseMode, true);
      expect(result.isJailbroken, false);
      expect(result.isEmulator, false);
      expect(result.isRealDevice, true);
      expect(result.hasMockLocation, false);
      expect(result.isOnExternalStorage, false);
      expect(result.hasDeveloperOptions, false);
      expect(result.error, null);
    });

    test('SecurityCheckResult risks should be empty when secure', () {
      final result = SecurityCheckResult();
      expect(result.risks, isEmpty);
    });

    test('SecurityCheckResult riskLevel should be 0 when secure', () {
      final result = SecurityCheckResult();
      expect(result.riskLevel, 0);
    });

    test('SecurityCheckResult should detect jailbreak risk', () {
      final result = SecurityCheckResult()
        ..isJailbroken = true
        ..isSecure = false;
      
      expect(result.risks, contains('Root/Jailbreak tespit edildi'));
      expect(result.riskLevel, 4); // Jailbreak = 4 puan
    });

    test('SecurityCheckResult should detect emulator risk', () {
      final result = SecurityCheckResult()
        ..isEmulator = true
        ..isSecure = false;
      
      expect(result.risks, contains('Emulator tespit edildi'));
      expect(result.riskLevel, 2); // Emulator = 2 puan
    });

    test('SecurityCheckResult should detect multiple risks', () {
      final result = SecurityCheckResult()
        ..isJailbroken = true
        ..isEmulator = true
        ..hasMockLocation = true
        ..isSecure = false;
      
      expect(result.risks.length, 3);
      expect(result.riskLevel, 7); // 4 + 2 + 1
    });

    test('SecurityCheckResult riskLevel should be clamped to 10', () {
      final result = SecurityCheckResult()
        ..isJailbroken = true      // 4
        ..isEmulator = true        // 2
        ..isRealDevice = false     // 2
        ..hasMockLocation = true   // 1
        ..isOnExternalStorage = true; // 1 = toplam 10
      
      expect(result.riskLevel, 10);
    });

    test('SecurityCheckResult toString should include all fields', () {
      final result = SecurityCheckResult();
      final str = result.toString();
      
      expect(str, contains('isSecure'));
      expect(str, contains('riskLevel'));
      expect(str, contains('isJailbroken'));
      expect(str, contains('isEmulator'));
    });

    test('Debug mode should be detected correctly', () {
      final result = SecurityCheckResult()..isDebugMode = true;
      
      expect(result.risks, contains('Debug modunda çalışıyor'));
    });

    test('Developer options should be detected', () {
      final result = SecurityCheckResult()..hasDeveloperOptions = true;
      
      expect(result.risks, contains('Geliştirici seçenekleri açık'));
    });

    test('External storage should be detected', () {
      final result = SecurityCheckResult()..isOnExternalStorage = true;
      
      expect(result.risks, contains('Uygulama harici depolamada'));
    });

    test('SecurityService instance should be singleton', () {
      final instance1 = SecurityService.instance;
      final instance2 = SecurityService.instance;
      
      expect(identical(instance1, instance2), true);
    });

    test('SecurityService cache should work correctly', () {
      // Cache başlangıçta null olmalı
      expect(securityService.isDeviceSecure, true); // Default value
      
      // Clear cache
      securityService.clearCache();
      
      // Hala default value dönmeli
      expect(securityService.isDeviceSecure, true);
    });
  });
}
