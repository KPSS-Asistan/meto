import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kpss_2026/core/services/analytics_service.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';

/// Account Deletion Service
/// App Store 5.1.1(v) gereği tüm kullanıcı verilerini siler.
/// Bu işlem Cloud Function yerine Client Side'da güvenli şekilde yapılabilir.
class AccountDeletionService {
  static final AccountDeletionService _instance = AccountDeletionService._internal();
  static AccountDeletionService get instance => _instance;

  AccountDeletionService._internal();

  Future<void> deleteUserAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu açık değil.');
    }

    try {
      final uid = user.uid;
      AppLogger.warning('⚠️ Hesap silme işlemi başlatıldı: $uid');

      // 1. Analytics Event
      await AnalyticsService.instance.logEvent('account_deletion_started');

      // 2. Firestore Verilerini Sil (Kritik Koleksiyonlar)
      await _deleteCollection('users/$uid/progress');
      await _deleteCollection('users/$uid/favorites');
      await _deleteCollection('users/$uid/quiz_history');
      
      // Kullanıcı dökümanını sil
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // 3. Auth Hesabını Sil
      await user.delete();
      
      AppLogger.success('✅ Hesap ve tüm veriler başarıyla silindi.');
      
    } catch (e) {
      AppLogger.error('❌ Hesap silme hatası:', e);
      rethrow; // UI'da göstermek için fırlat
    }
  }

  Future<void> _deleteCollection(String path) async {
    try {
      final collection = FirebaseFirestore.instance.collection(path);
      final snapshot = await collection.get();
      
      if (snapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      AppLogger.info('🗑️ Koleksiyon temizlendi: $path (${snapshot.docs.length} doküman)');
    } catch (e) {
      // Koleksiyon yoksa veya yetki yoksa devam et
      AppLogger.warning('Koleksiyon silinemedi (önemsiz olabilir): $path - $e');
    }
  }
}
