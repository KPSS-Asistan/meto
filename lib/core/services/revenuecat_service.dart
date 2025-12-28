import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'prefs_service.dart';

/// RevenueCat Servisi - Premium Abonelik Yönetimi
/// Singleton pattern ile global erişim
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // ══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ══════════════════════════════════════════════════════════════════════════
  
  // API Keys - Test için şu an, production'da değiştirilecek
  static const String _apiKey = 'test_lPjFHLSgSQyjCyWctmjHSOEJWIL';
  
  // Entitlement ID - RevenueCat Dashboard'da tanımlanmalı
  static const String entitlementId = 'pro';
  
  // Product IDs
  static const String productMonthly = 'monthly';
  static const String productThreeMonth = 'three_month';
  static const String productYearly = 'yearly';

  // ══════════════════════════════════════════════════════════════════════════
  // STATE
  // ══════════════════════════════════════════════════════════════════════════
  
  bool _isInitialized = false;
  bool _testModePremium = false; // Test modu: Zorla AÇ
  bool _testModeForceDisable = false; // Test modu: Zorla KAPAT
  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  
  // Stream Controllers
  final _customerInfoController = StreamController<CustomerInfo?>.broadcast();
  final _isPremiumController = StreamController<bool>.broadcast();
  
  // Getters
  bool get isInitialized => _isInitialized;
  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;
  Stream<CustomerInfo?> get customerInfoStream => _customerInfoController.stream;
  Stream<bool> get isPremiumStream => _isPremiumController.stream;
  
  /// Premium durumu kontrolü
  bool get isPremium {
    // ⚡ Test modu: Zorla kapatma (gerçek abonelik olsa bile kapalı göster)
    if (_testModeForceDisable) return false;
    
    // ⚡ Test modu: Zorla açma
    if (_testModePremium) return true;
    
    if (_customerInfo == null) return false;
    
    // 1. Spesifik 'pro' entitlement kontrolü
    final specificEntitlement = _customerInfo!.entitlements.all[entitlementId]?.isActive ?? false;
    if (specificEntitlement) return true;

    // 2. Fallback: Herhangi bir aktif entitlement var mı?
    return _customerInfo!.entitlements.active.isNotEmpty;
  }

  /// Test modu için manuel premium kontrolü (SADECE DEBUG için)
  /// value=true: Zorla AÇ, value=false: Zorla KAPAT
  /// 🔒 GÜVENLİK: Bu fonksiyon production'da çalışmaz!
  void setTestModePremium(bool value) {
    // 🔒 Production'da premium bypass'ı engelle
    if (!kDebugMode) {
      AppLogger.debug('⚠️ SECURITY: Test mode disabled in production!');
      return;
    }
    
    if (value) {
      _testModePremium = true;
      _testModeForceDisable = false;
    } else {
      _testModePremium = false;
      _testModeForceDisable = true; // ⚡ Gerçek abonelik olsa bile kapalı göster
    }
    _isPremiumController.add(isPremium);
    AppLogger.debug('🧪 Test mode: premium=$value, forceDisable=$_testModeForceDisable');
  }
  
  /// Test modunu tamamen sıfırla (gerçek duruma dön)
  /// 🔒 GÜVENLİK: Bu fonksiyon production'da çalışmaz!
  void resetTestMode() {
    if (!kDebugMode) {
      AppLogger.debug('⚠️ SECURITY: Test mode reset disabled in production!');
      return;
    }
    
    _testModePremium = false;
    _testModeForceDisable = false;
    _isPremiumController.add(isPremium);
    AppLogger.debug('🧪 Test mode reset - showing real subscription status');
  }
  
  /// Test modunun aktif olup olmadığını kontrol et
  bool get isTestModePremium => _testModePremium;
  bool get isTestModeForceDisable => _testModeForceDisable;

  // ══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════════════════
  
  /// RevenueCat SDK'yı başlat
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Debug logging (sadece development'ta)
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      
      // SDK yapılandırması
      final configuration = PurchasesConfiguration(_apiKey);
      
      // Kullanıcı ID'sini Firebase Auth ile senkronize et
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        configuration.appUserID = user.uid;
      }
      
      await Purchases.configure(configuration);
      
      // Customer info listener ekle
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      
      // İlk customer info'yu al
      await refreshCustomerInfo();
      
      // Offerings'i yükle
      await loadOfferings();
      
      _isInitialized = true;
      AppLogger.debug('✅ RevenueCat initialized successfully');
    } catch (e) {
      AppLogger.debug('❌ RevenueCat initialization failed: $e');
      rethrow;
    }
  }
  
  /// Customer info güncellendiğinde
  void _onCustomerInfoUpdated(CustomerInfo info) {
    _customerInfo = info;
    _customerInfoController.add(info);
    _isPremiumController.add(isPremium);
    AppLogger.debug('🔄 Customer info updated. Premium: $isPremium');
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // USER MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Firebase kullanıcısı ile RevenueCat'i senkronize et
  Future<void> syncWithFirebaseUser() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || user.isAnonymous) {
      // Anonim veya çıkış yapmış kullanıcı
      await logOut();
      return;
    }
    
    try {
      // Aynı kullanıcı mı kontrol et
      final currentUserId = await Purchases.appUserID;
      if (currentUserId != user.uid) {
        // Farklı kullanıcı, login yap
        await Purchases.logIn(user.uid);
        AppLogger.debug('✅ RevenueCat synced with Firebase user: ${user.uid}');
      }
      
      await refreshCustomerInfo();
    } catch (e) {
      AppLogger.debug('❌ RevenueCat sync failed: $e');
    }
  }
  
  /// Kullanıcı çıkışı
  Future<void> logOut() async {
    try {
      // Anonymous user kontrolü - RevenueCat anonymous user logout'u desteklemiyor
      final isAnonymous = await Purchases.isAnonymous;
      if (!isAnonymous) {
        await Purchases.logOut();
      }
      
      _customerInfo = null;
      _testModePremium = false; // ⚡ Test modunu sıfırla
      _customerInfoController.add(null);
      _isPremiumController.add(false);
      
      // ⚡ Local premium cache'i de temizle
      final prefs = await PrefsService.instance;
      await prefs.remove('is_premium');
      
      AppLogger.debug('✅ RevenueCat logged out + premium cache cleared');
    } catch (e) {
      // Hata olsa bile local state'i temizle
      _customerInfo = null;
      _testModePremium = false;
      _customerInfoController.add(null);
      _isPremiumController.add(false);
      AppLogger.debug('⚠️ RevenueCat logout warning: $e');
    }
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // CUSTOMER INFO
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Customer info'yu yenile
  Future<CustomerInfo?> refreshCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      _customerInfoController.add(_customerInfo);
      _isPremiumController.add(isPremium);
      return _customerInfo;
    } catch (e) {
      AppLogger.debug('❌ Failed to get customer info: $e');
      return null;
    }
  }
  
  /// Premium durumunu async kontrol et
  Future<bool> checkPremiumStatus() async {
    await refreshCustomerInfo();
    return isPremium;
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // OFFERINGS & PRODUCTS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Offerings'i yükle
  Future<Offerings?> loadOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
      AppLogger.debug('✅ Offerings loaded: ${_offerings?.current?.identifier}');
      return _offerings;
    } catch (e) {
      AppLogger.debug('❌ Failed to load offerings: $e');
      return null;
    }
  }
  
  /// Mevcut offering'i al
  Offering? get currentOffering => _offerings?.current;
  
  /// Tüm paketleri al
  List<Package> get availablePackages => currentOffering?.availablePackages ?? [];
  
  /// Belirli bir paketi al
  Package? getPackage(String identifier) {
    return availablePackages.firstWhere(
      (p) => p.identifier == identifier,
      orElse: () => availablePackages.first,
    );
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // PURCHASE
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Paket satın al
  Future<PurchaseResult> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      _customerInfo = customerInfo;
      _customerInfoController.add(customerInfo);
      _isPremiumController.add(isPremium);
      
      if (isPremium) {
        return PurchaseResult.success;
      } else {
        return PurchaseResult.failed;
      }
    } on PurchasesErrorCode catch (e) {
      AppLogger.debug('❌ Purchase error: $e');
      
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled;
      }
      return PurchaseResult.failed;
    } catch (e) {
      AppLogger.debug('❌ Purchase failed: $e');
      
      // ⚠️ TEST MODU: Geniş "Test Failed Purchase" kontrolü
      // RevenueCat test modunda failed purchase seçildiğinde gelen exception'ları yakala
      final errorString = e.toString().toLowerCase();
      if (kDebugMode && (
        errorString.contains('test') || 
        errorString.contains('fail') ||
        errorString.contains('cancel') ||
        errorString.contains('error') ||
        errorString.contains('exception')
      ) && !errorString.contains('serialization')) {
        AppLogger.debug('🧪 TEST: Detected failed purchase test - returning failure');
        return PurchaseResult.failed;
      }
      
      // ✨ FIX: SADECE Debug modunda SerializationException (test_store) hatasını yok say
      // Bu, sadece emulator/test ortamındaki RevenueCat library hatasını aşmak için
      // 🔒 GÜVENLİK: Production'da kesinlikle test premium aktif edilmez!
      if (kDebugMode && e.toString().contains('SerializationException')) {
        AppLogger.debug('⚠️ SerializationException ignored in debug mode. Activating Test Premium Mode.');
        
        // Test modunda premium'u aktif et ve stream'i güncelle
        _testModePremium = true;
        _isPremiumController.add(true); 
        
        return PurchaseResult.success;
      }
      
      // 🔒 Production'da hata logla ve failed döndür
      if (!kDebugMode) {
        AppLogger.debug('❌ SECURITY: Purchase failed in production: $e');
      }
      
      return PurchaseResult.failed;
    }
  }
  
  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      _customerInfoController.add(customerInfo);
      _isPremiumController.add(isPremium);
      return isPremium;
    } catch (e) {
      AppLogger.debug('❌ Restore failed: $e');
      return false;
    }
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // REVENUECAT PAYWALL UI
  // ══════════════════════════════════════════════════════════════════════════
  
  /// RevenueCat hazır paywall'u göster
  Future<PaywallResult> showPaywall({
    required BuildContext context,
    Offering? offering,
  }) async {
    try {
      final paywallResult = await RevenueCatUI.presentPaywallIfNeeded(
        entitlementId,
        offering: offering,
      );
      
      // Paywall sonrası customer info'yu yenile
      await refreshCustomerInfo();
      
      return paywallResult;
    } catch (e) {
      AppLogger.debug('❌ Paywall error: $e');
      return PaywallResult.error;
    }
  }
  
  /// Customer Center göster (abonelik yönetimi)
  Future<void> showCustomerCenter(BuildContext context) async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      AppLogger.debug('❌ Customer center error: $e');
      // Fallback: Manual subscription management
      // ignore: use_build_context_synchronously - context passed from caller
      if (context.mounted) {
        _showManualSubscriptionHelp(context);
      }
    }
  }
  
  void _showManualSubscriptionHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abonelik Yönetimi'),
        content: const Text(
          'Aboneliğinizi yönetmek için:\n\n'
          '1. Google Play Store\'u açın\n'
          '2. Profil → Ödemeler ve abonelikler → Abonelikler\n'
          '3. KPSS Asistan\'ı bulun ve yönetin',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Abonelik bitiş tarihi
  DateTime? get expirationDate {
    final entitlement = _customerInfo?.entitlements.all[entitlementId];
    if (entitlement?.expirationDate != null) {
      return DateTime.tryParse(entitlement!.expirationDate!);
    }
    return null;
  }
  
  /// Kalan gün sayısı
  int get daysRemaining {
    final expDate = expirationDate;
    if (expDate == null) return 0;
    return expDate.difference(DateTime.now()).inDays;
  }
  
  /// Abonelik durumu metni
  String get subscriptionStatusText {
    if (!isPremium) return 'Ücretsiz Plan';
    
    final days = daysRemaining;
    if (days <= 0) return 'Süresi Dolmuş';
    if (days == 1) return '1 gün kaldı';
    if (days <= 7) return '$days gün kaldı';
    return 'Pro Aktif';
  }
  
  /// Cleanup
  void dispose() {
    _customerInfoController.close();
    _isPremiumController.close();
  }
}

/// Satın alma sonucu
enum PurchaseResult {
  success,
  cancelled,
  failed,
}
