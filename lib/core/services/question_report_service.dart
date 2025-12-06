import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';

/// Soru Hata Bildirimi Servisi
/// ⚡ OPTIMIZED: Lokal queue + batch upload
class QuestionReportService {
  static const _reportsKey = 'pending_question_reports';
  static const _reportedQuestionsKey = 'reported_questions';
  
  static SharedPreferences? _prefs;
  
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Hata türleri
  static const reportTypes = {
    'wrong_answer': 'Yanlış cevap',
    'typo': 'Yazım hatası',
    'unclear': 'Anlaşılmaz soru',
    'wrong_topic': 'Yanlış konu',
    'duplicate': 'Tekrar eden soru',
    'other': 'Diğer',
  };

  /// Soru için hata bildir
  /// Lokal'e kaydeder, arka planda Firebase'e gönderir
  static Future<bool> reportQuestion({
    required String questionId,
    required String reportType,
    String? description,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      // Daha önce bildirildiyse engelle
      if (await hasReported(questionId)) {
        return false;
      }

      final report = {
        'questionId': questionId,
        'userId': userId,
        'reportType': reportType,
        'description': description ?? '',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending', // pending, reviewed, fixed, rejected
      };

      // Lokal'e kaydet
      final prefs = await _instance;
      final reports = prefs.getStringList(_reportsKey) ?? [];
      reports.add(_encodeReport(report));
      await prefs.setStringList(_reportsKey, reports);

      // Bildirilen sorular listesine ekle
      final reported = prefs.getStringList(_reportedQuestionsKey) ?? [];
      reported.add(questionId);
      await prefs.setStringList(_reportedQuestionsKey, reported);

      // Arka planda Firebase'e gönder
      _uploadReportsInBackground();

      AppLogger.info('Question reported: $questionId - $reportType');
      return true;
    } catch (e) {
      AppLogger.error('Report question failed', e);
      return false;
    }
  }

  /// Bu soru daha önce bildirildi mi?
  static Future<bool> hasReported(String questionId) async {
    final prefs = await _instance;
    final reported = prefs.getStringList(_reportedQuestionsKey) ?? [];
    return reported.contains(questionId);
  }

  /// Bekleyen rapor sayısı
  static Future<int> getPendingReportCount() async {
    final prefs = await _instance;
    final reports = prefs.getStringList(_reportsKey) ?? [];
    return reports.length;
  }

  /// Arka planda Firebase'e yükle
  static Future<void> _uploadReportsInBackground() async {
    try {
      final prefs = await _instance;
      final reports = prefs.getStringList(_reportsKey) ?? [];
      
      if (reports.isEmpty) return;

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final reportStr in reports) {
        final report = _decodeReport(reportStr);
        final docRef = firestore.collection('questionReports').doc();
        batch.set(docRef, {
          ...report,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      
      // Başarılı - lokal queue'yu temizle
      await prefs.setStringList(_reportsKey, []);
      
      AppLogger.info('Uploaded ${reports.length} question reports to Firebase');
    } catch (e) {
      AppLogger.error('Upload reports failed', e);
      // Hata durumunda lokal'de kalır, sonra tekrar dener
    }
  }

  /// Manuel sync (ayarlar sayfasından)
  static Future<void> syncReports() async {
    await _uploadReportsInBackground();
  }

  /// Lokal cache temizle
  static Future<void> clearCache() async {
    final prefs = await _instance;
    await prefs.remove(_reportsKey);
    await prefs.remove(_reportedQuestionsKey);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENCODING HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static String _encodeReport(Map<String, dynamic> report) {
    return '${report['questionId']}|${report['userId']}|${report['reportType']}|${report['description']}|${report['timestamp']}';
  }

  static Map<String, dynamic> _decodeReport(String encoded) {
    final parts = encoded.split('|');
    return {
      'questionId': parts[0],
      'userId': parts[1],
      'reportType': parts[2],
      'description': parts.length > 3 ? parts[3] : '',
      'timestamp': parts.length > 4 ? parts[4] : DateTime.now().toIso8601String(),
      'status': 'pending',
    };
  }
}
