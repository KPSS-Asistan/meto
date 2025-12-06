import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';

/// ⚡ SINGLETON: Premium status manager
/// Prevents unnecessary Firestore reads for premium status checks
/// Cache duration: 1 hour per user
class PremiumStatusManager {
  // Private constructor for singleton
  PremiumStatusManager._();
  
  // Singleton instance
  static final PremiumStatusManager _instance = PremiumStatusManager._();
  static PremiumStatusManager get instance => _instance;
  
  // Cache storage
  static bool? _isPremium;
  static String? _currentUserId;
  static DateTime? _lastCheck;
  
  // Cache duration
  static const _cacheDuration = Duration(hours: 1);
  
  /// Check if user is premium (with caching)
  /// ⚡ OPTIMIZED: Only 1 Firestore read per hour per user!
  static Future<bool> isPremium(String userId) async {
    try {
      // Cache hit - return immediately
      if (_currentUserId == userId && 
          _isPremium != null && 
          _lastCheck != null &&
          DateTime.now().difference(_lastCheck!) < _cacheDuration) {
        AppLogger.debug('Premium status from cache: $_isPremium');
        return _isPremium!;
      }
      
      // Cache miss - fetch from Firestore
      AppLogger.firebase('GET', 'users/$userId', 'premium_status');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      _isPremium = doc.data()?['isPremium'] ?? false;
      _currentUserId = userId;
      _lastCheck = DateTime.now();
      
      AppLogger.info('Premium status fetched: $_isPremium for $userId');
      return _isPremium!;
    } catch (e) {
      AppLogger.error('Premium status check failed', e);
      // Hata durumunda false döndür (güvenli default)
      return false;
    }
  }
  
  /// Invalidate cache (call after purchase/subscription change)
  static void invalidate() {
    _isPremium = null;
    _currentUserId = null;
    _lastCheck = null;
    AppLogger.debug('Premium cache invalidated');
  }
  
  /// Invalidate specific user
  static void invalidateUser(String userId) {
    if (_currentUserId == userId) {
      invalidate();
    }
  }
  
  /// Check if cache is valid
  static bool get isCacheValid {
    return _currentUserId != null && 
           _isPremium != null && 
           _lastCheck != null &&
           DateTime.now().difference(_lastCheck!) < _cacheDuration;
  }
}
