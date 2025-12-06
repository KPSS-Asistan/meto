import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Teleport Service - Kullanıcıyı zayıf konularına ışınlar
class TeleportService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kullanıcının performansını analiz et ve zayıf konuyu bul
  Future<TeleportAnalysis> analyzeAndGetWeakTopic() async {
    try {
      debugPrint('🚀 Teleport: Performans analizi başlatılıyor...');
      
      final result = await _functions
          .httpsCallable('analyzeUserRecentPerformance')
          .call();

      final data = result.data as Map<String, dynamic>;
      debugPrint('✅ Teleport: Analiz tamamlandı - ${data['main_diagnosis']}');

      return TeleportAnalysis.fromJson(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Teleport Error: ${e.code} - ${e.message}');
      throw TeleportException(e.message ?? 'Analiz hatası');
    } catch (e) {
      debugPrint('❌ Teleport Unexpected Error: $e');
      throw TeleportException('Beklenmeyen hata: $e');
    }
  }

  /// Belirli bir topic'in flashcard'larını getir
  Future<List<FlashcardData>> getTopicFlashcards(
    String topicId, {
    int limit = 5,
  }) async {
    try {
      debugPrint('📚 Teleport: $topicId için flashcardlar getiriliyor...');
      
      final snapshot = await _firestore
          .collection('flashcards')
          .where('topicId', isEqualTo: topicId)
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ Teleport: Flashcard bulunamadı');
        return [];
      }

      debugPrint('✅ Teleport: ${snapshot.docs.length} flashcard bulundu');
      
      return snapshot.docs
          .map((doc) => FlashcardData.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Teleport Flashcard Error: $e');
      throw TeleportException('Flashcard getirilemedi: $e');
    }
  }
}

/// Teleport Analiz Sonucu
class TeleportAnalysis {
  final String diagnosis;
  final String? topicId;
  final String? topicName;
  final String? lessonId;
  final String? analysisNote;
  final int? wrongCount;
  final int? totalCount;

  TeleportAnalysis({
    required this.diagnosis,
    this.topicId,
    this.topicName,
    this.lessonId,
    this.analysisNote,
    this.wrongCount,
    this.totalCount,
  });

  factory TeleportAnalysis.fromJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>?;
    
    return TeleportAnalysis(
      diagnosis: json['main_diagnosis'] as String,
      topicId: details?['topic_id'] as String?,
      topicName: details?['topic_name'] as String?,
      lessonId: details?['lesson_id'] as String?,
      analysisNote: details?['analysis_note'] as String?,
      wrongCount: details?['wrong_count'] as int?,
      totalCount: details?['total_count'] as int?,
    );
  }

  bool get hasWeakTopic => diagnosis == 'Bilgi Eksikliği' && topicId != null;
  bool get needsMoreData => diagnosis == 'Yeterli Veri Yok';
}

/// Flashcard Data Model
class FlashcardData {
  final String id;
  final String question;
  final String answer;
  final String topicId;

  FlashcardData({
    required this.id,
    required this.question,
    required this.answer,
    required this.topicId,
  });

  factory FlashcardData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlashcardData(
      id: doc.id,
      question: data['question'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      topicId: data['topicId'] as String? ?? '',
    );
  }
}

/// Teleport Exception
class TeleportException implements Exception {
  final String message;
  TeleportException(this.message);

  @override
  String toString() => message;
}
