import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kpss_2026/core/services/local_progress_service.dart';

/// Günlük Firebase sync servisi
/// Sadece giriş yapmış kullanıcılar için çalışır
/// Uygulama açılışında 24 saatten eski ise sync yapar
class SyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalProgressService _localProgress;
  
  SyncService({
    required LocalProgressService localProgress,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _localProgress = localProgress,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  
  /// Mevcut kullanıcı
  User? get _currentUser => _auth.currentUser;
  
  /// Kullanıcı giriş yapmış mı?
  bool get isLoggedIn => _currentUser != null;
  
  /// Sync gerekli mi kontrol et ve gerekiyorsa yap
  /// Uygulama açılışında çağrılır
  Future<SyncResult> checkAndSync() async {
    // Giriş yapmamış kullanıcılar için sync yapma
    if (!isLoggedIn) {
      return SyncResult(
        success: true,
        message: 'Giriş yapılmamış, sync atlandı',
        skipped: true,
      );
    }
    
    // 24 saatten yeni ise sync yapma
    if (!_localProgress.needsSync) {
      return SyncResult(
        success: true,
        message: 'Son sync 24 saatten yeni, atlandı',
        skipped: true,
      );
    }
    
    // Sync yap
    return await sync();
  }
  
  /// Manuel sync
  Future<SyncResult> sync() async {
    if (!isLoggedIn) {
      return SyncResult(
        success: false,
        message: 'Giriş yapılmamış',
        skipped: true,
      );
    }
    
    try {
      final userId = _currentUser!.uid;
      
      // 1. Firebase'den mevcut veriyi al
      final firebaseDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('progress')
          .get();
      
      final firebaseData = firebaseDoc.data();
      final localData = _localProgress.exportForFirebase();
      
      // 2. Hangi veri daha yeni?
      DateTime? firebaseLastSync;
      DateTime? localLastSync = _localProgress.userData.lastSync;
      
      if (firebaseData != null && firebaseData['lastSync'] != null) {
        firebaseLastSync = DateTime.tryParse(firebaseData['lastSync']);
      }
      
      // 3. Merge stratejisi
      Map<String, dynamic> mergedData;
      
      if (firebaseData == null) {
        // Firebase'de veri yok, local'i yükle
        mergedData = localData;
      } else if (localLastSync == null) {
        // Local'de sync tarihi yok, Firebase'i al
        mergedData = firebaseData;
        await _localProgress.importFromFirebase(firebaseData);
      } else if (firebaseLastSync == null) {
        // Firebase'de sync tarihi yok, local'i yükle
        mergedData = localData;
      } else if (firebaseLastSync.isAfter(localLastSync)) {
        // Firebase daha yeni, onu al
        mergedData = firebaseData;
        await _localProgress.importFromFirebase(firebaseData);
      } else {
        // Local daha yeni veya eşit, local'i yükle
        mergedData = localData;
      }
      
      // 4. Firebase'e kaydet
      mergedData['lastSync'] = DateTime.now().toIso8601String();
      mergedData['userId'] = userId;
      mergedData['email'] = _currentUser!.email;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('progress')
          .set(mergedData, SetOptions(merge: true));
      
      // 5. Local sync tarihini güncelle
      await _localProgress.markSynced();
      
      return SyncResult(
        success: true,
        message: 'Sync başarılı',
        skipped: false,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync hatası: $e',
        skipped: false,
      );
    }
  }
  
  /// Firebase'den veriyi çek (login sonrası)
  Future<SyncResult> pullFromFirebase() async {
    if (!isLoggedIn) {
      return SyncResult(
        success: false,
        message: 'Giriş yapılmamış',
        skipped: true,
      );
    }
    
    try {
      final userId = _currentUser!.uid;
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('progress')
          .get();
      
      if (doc.exists && doc.data() != null) {
        await _localProgress.importFromFirebase(doc.data()!);
        await _localProgress.markSynced();
        
        return SyncResult(
          success: true,
          message: 'Veriler Firebase\'den alındı',
          skipped: false,
        );
      }
      
      return SyncResult(
        success: true,
        message: 'Firebase\'de veri bulunamadı',
        skipped: true,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Pull hatası: $e',
        skipped: false,
      );
    }
  }
  
  /// Local veriyi Firebase'e gönder (logout öncesi)
  Future<SyncResult> pushToFirebase() async {
    if (!isLoggedIn) {
      return SyncResult(
        success: false,
        message: 'Giriş yapılmamış',
        skipped: true,
      );
    }
    
    try {
      final userId = _currentUser!.uid;
      final localData = _localProgress.exportForFirebase();
      
      localData['lastSync'] = DateTime.now().toIso8601String();
      localData['userId'] = userId;
      localData['email'] = _currentUser!.email;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('progress')
          .set(localData);
      
      await _localProgress.markSynced();
      
      return SyncResult(
        success: true,
        message: 'Veriler Firebase\'e gönderildi',
        skipped: false,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Push hatası: $e',
        skipped: false,
      );
    }
  }
  
  /// Kullanıcının tüm verilerini sil (hesap silme)
  Future<SyncResult> deleteUserData() async {
    if (!isLoggedIn) {
      return SyncResult(
        success: false,
        message: 'Giriş yapılmamış',
        skipped: true,
      );
    }
    
    try {
      final userId = _currentUser!.uid;
      
      // Firebase'den sil
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('progress')
          .delete();
      
      // Local'den sil
      await _localProgress.clearAllData();
      
      return SyncResult(
        success: true,
        message: 'Tüm veriler silindi',
        skipped: false,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Silme hatası: $e',
        skipped: false,
      );
    }
  }
}

/// Sync sonucu
class SyncResult {
  final bool success;
  final String message;
  final bool skipped;
  
  SyncResult({
    required this.success,
    required this.message,
    required this.skipped,
  });
  
  @override
  String toString() => 'SyncResult(success: $success, message: $message, skipped: $skipped)';
}
