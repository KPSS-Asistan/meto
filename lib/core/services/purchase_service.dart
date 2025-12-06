import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kpss_2026/core/services/secure_storage_service.dart';

/// In-App Purchase Servisi
/// 
/// Premium üyelik satın alma işlemlerini yönetir:
/// - 1 Aylık Premium
/// - 3 Aylık Premium
/// - 12 Aylık Premium
class PurchaseService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Product IDs - App Store Connect ve Google Play Console'da tanımlanmalı
  static const String _monthlyProductId = 'kpss_premium_monthly';
  static const String _quarterlyProductId = 'kpss_premium_quarterly';
  static const String _yearlyProductId = 'kpss_premium_yearly';
  
  static final Set<String> _productIds = {
    _monthlyProductId,
    _quarterlyProductId,
    _yearlyProductId,
  };
  
  // Ürün bilgileri cache
  static List<ProductDetails> _products = [];
  static bool _isAvailable = false;
  
  // Callbacks
  static Function(bool success, String? error)? onPurchaseComplete;
  static Function(bool isPremium)? onPremiumStatusChanged;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Servisi başlat
  static Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    
    if (!_isAvailable) {
      debugPrint('In-App Purchase not available');
      return;
    }
    
    // Satın alma stream'ini dinle
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
    );
    
    // Ürünleri yükle
    await loadProducts();
    
    // Bekleyen satın almaları kontrol et
    await _restorePurchases();
  }
  
  /// Servisi kapat
  static void dispose() {
    _subscription?.cancel();
  }
  
  /// Ürünleri yükle
  static Future<void> loadProducts() async {
    if (!_isAvailable) return;
    
    final response = await _iap.queryProductDetails(_productIds);
    
    if (response.error != null) {
      debugPrint('Product query error: ${response.error}');
      return;
    }
    
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }
    
    _products = response.productDetails;
    debugPrint('Loaded ${_products.length} products');
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PRODUCTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Mevcut ürünleri getir
  static List<ProductDetails> get products => _products;
  
  /// Aylık ürünü getir
  static ProductDetails? get monthlyProduct => 
      _products.where((p) => p.id == _monthlyProductId).firstOrNull;
  
  /// 3 Aylık ürünü getir
  static ProductDetails? get quarterlyProduct => 
      _products.where((p) => p.id == _quarterlyProductId).firstOrNull;
  
  /// Yıllık ürünü getir
  static ProductDetails? get yearlyProduct => 
      _products.where((p) => p.id == _yearlyProductId).firstOrNull;
  
  /// Store mevcut mu?
  static bool get isAvailable => _isAvailable;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PURCHASE
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Satın alma başlat
  static Future<bool> purchase(ProductDetails product) async {
    if (!_isAvailable) {
      onPurchaseComplete?.call(false, 'Store not available');
      return false;
    }
    
    final purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      // Non-consumable (subscription) satın alma
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      debugPrint('Purchase error: $e');
      onPurchaseComplete?.call(false, e.toString());
      return false;
    }
  }
  
  /// Aylık satın al
  static Future<bool> purchaseMonthly() async {
    final product = monthlyProduct;
    if (product == null) {
      onPurchaseComplete?.call(false, 'Product not found');
      return false;
    }
    return purchase(product);
  }
  
  /// 3 Aylık satın al
  static Future<bool> purchaseQuarterly() async {
    final product = quarterlyProduct;
    if (product == null) {
      onPurchaseComplete?.call(false, 'Product not found');
      return false;
    }
    return purchase(product);
  }
  
  /// Yıllık satın al
  static Future<bool> purchaseYearly() async {
    final product = yearlyProduct;
    if (product == null) {
      onPurchaseComplete?.call(false, 'Product not found');
      return false;
    }
    return purchase(product);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PURCHASE HANDLING
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Satın alma güncellemelerini işle
  static void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }
  
  /// Tek satın almayı işle
  static Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        debugPrint('Purchase pending: ${purchase.productID}');
        break;
        
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Satın alma doğrulama
        final valid = await _verifyPurchase(purchase);
        
        if (valid) {
          // Premium durumunu kaydet
          await _activatePremium(purchase.productID);
          onPurchaseComplete?.call(true, null);
        } else {
          onPurchaseComplete?.call(false, 'Verification failed');
        }
        
        // Satın almayı tamamla
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;
        
      case PurchaseStatus.error:
        debugPrint('Purchase error: ${purchase.error}');
        onPurchaseComplete?.call(false, purchase.error?.message ?? 'Unknown error');
        
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;
        
      case PurchaseStatus.canceled:
        debugPrint('Purchase canceled');
        onPurchaseComplete?.call(false, 'Canceled');
        break;
    }
  }
  
  /// Satın almayı doğrula
  static Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Server-side verification
    // Şimdilik client-side kabul ediyoruz
    // Production'da MUTLAKA server-side doğrulama yapılmalı!
    
    if (Platform.isIOS) {
      // iOS için receipt doğrulama
      // purchase.verificationData.serverVerificationData
      return true;
    } else if (Platform.isAndroid) {
      // Android için token doğrulama
      // purchase.verificationData.serverVerificationData
      return true;
    }
    
    return true;
  }
  
  /// Premium'u aktifleştir
  static Future<void> _activatePremium(String productId) async {
    DateTime expiryDate;
    
    switch (productId) {
      case _monthlyProductId:
        expiryDate = DateTime.now().add(const Duration(days: 30));
        break;
      case _quarterlyProductId:
        expiryDate = DateTime.now().add(const Duration(days: 90));
        break;
      case _yearlyProductId:
        expiryDate = DateTime.now().add(const Duration(days: 365));
        break;
      default:
        expiryDate = DateTime.now().add(const Duration(days: 30));
    }
    
    await SecureStorageService.savePremiumStatus(true, expiryDate: expiryDate);
    onPremiumStatusChanged?.call(true);
    
    debugPrint('Premium activated until: $expiryDate');
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // RESTORE
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Satın almaları geri yükle
  static Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _iap.restorePurchases();
  }
  
  /// Başlangıçta satın almaları kontrol et
  static Future<void> _restorePurchases() async {
    // Mevcut premium durumunu kontrol et
    final isPremium = await SecureStorageService.isPremium();
    
    if (!isPremium) {
      // Premium değilse, store'dan kontrol et
      await restorePurchases();
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM STATUS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Premium durumunu kontrol et
  static Future<bool> checkPremiumStatus() async {
    return await SecureStorageService.isPremium();
  }
  
  /// Premium bitiş tarihini getir
  static Future<DateTime?> getPremiumExpiry() async {
    return await SecureStorageService.getPremiumExpiry();
  }
}
