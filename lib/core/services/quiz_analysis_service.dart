import 'package:kpss_2026/core/data/subtopics_mapping.dart';
import 'package:kpss_2026/core/repositories/ai_repository.dart';

/// Test Sonucu AI Analiz Servisi
/// Premium kullanıcılar için detaylı performans analizi
class QuizAnalysisService {
  final AiRepository _aiRepository = AiRepository();
  
  /// Test sonucunu AI ile analiz et - STREAMING
  Stream<String> analyzeQuizResultStreaming({
    required String topicId,
    required String topicName,
    required int totalQuestions,
    required int correctAnswers,
    required int wrongAnswers,
    required double successRate,
    List<WrongQuestionInfo>? wrongQuestions,
  }) async* {
    // Yanlış sorulardan alt konuları çıkar
    final weakTopics = _analyzeWrongQuestionsBySubtopic(topicId, wrongQuestions);
    
    // Prompt oluştur
    final prompt = '''
TEST SONUCU:
- Konu: $topicName
- Toplam: $totalQuestions soru
- Doğru: $correctAnswers
- Yanlış: $wrongAnswers
- Başarı: %${successRate.toStringAsFixed(0)}

${weakTopics.isNotEmpty ? 'En Çok Yanlış Yapılan Alt Konular:\n${weakTopics.entries.map((e) => '- ${e.key}: ${e.value} yanlış').join('\n')}' : 'Alt konu verisi yok.'}

Bu sonucu profesyonel bir koç gibi analiz et.
Çıktıyı aynen aşağıdaki formatta ver (başka bir şey yazma):

Durum: [Kısa özet] (örnek: Tarih testinde genel olarak iyisin ama detaylarda kaçırıyorsun)
•
Odak: [Zayıf olduğum 1-2 alt konu] (örnek: İslamiyet Öncesi Türk Devletleri ve Kültür Medeniyet konularına yoğunlaş)
•
Öneri: [Somut 1 öneri] (örnek: Bu konularda kavram haritası çıkararak çalışmalısın)
•
Motivasyon: [Kısa motivasyon sözü] (örnek: Biraz daha tekrarla mükemmel olacak!)
''';

    yield* _aiRepository.getQuizAnalysisStreaming(prompt);
  }

  /// Test sonucunu AI ile analiz et (eski - callback)
  Future<String> analyzeQuizResult({
    required String topicId,
    required String topicName,
    required int totalQuestions,
    required int correctAnswers,
    required int wrongAnswers,
    required int timeSpent,
    required double successRate,
    List<WrongQuestionInfo>? wrongQuestions,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in analyzeQuizResultStreaming(
      topicId: topicId,
      topicName: topicName,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      successRate: successRate,
    )) {
      buffer.clear();
      buffer.write(chunk);
    }
    return buffer.toString();
  }
  
  /// Yanlış soruları alt konulara göre grupla
  /// Önce subtopicName varsa kullan, yoksa keyword matching ile tespit et
  Map<String, int> _analyzeWrongQuestionsBySubtopic(String topicId, List<WrongQuestionInfo>? wrongQuestions) {
    if (wrongQuestions == null || wrongQuestions.isEmpty) return {};
    
    final Map<String, int> subtopicCounts = {};
    
    for (final wrong in wrongQuestions) {
      String? subtopicName;
      
      // 1. Öncelik: Soruda subtopicName varsa onu kullan
      if (wrong.subtopicName != null && wrong.subtopicName!.isNotEmpty) {
        subtopicName = wrong.subtopicName;
      } 
      // 2. Alternatif: Keyword matching ile tespit et
      else {
        final detected = SubtopicMapping.detectSubtopic(topicId, wrong.questionText);
        subtopicName = detected?.name;
      }
      
      if (subtopicName != null) {
        subtopicCounts[subtopicName] = (subtopicCounts[subtopicName] ?? 0) + 1;
      }
    }
    
    // En çok yanlış yapılandan en aza sırala
    final sorted = Map.fromEntries(
      subtopicCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );
    
    return sorted;
  }
  
  /// Belirli bir alt konuya özel analiz
  Future<String> analyzeSubtopic({
    required String topicId,
    required String subtopicId,
    required List<WrongQuestionInfo> wrongQuestions,
  }) async {
    final subtopics = SubtopicMapping.getSubtopics(topicId);
    final subtopic = subtopics.firstWhere(
      (s) => s.id == subtopicId,
      orElse: () => const SubtopicInfo(id: '', name: 'Bilinmeyen', keywords: []),
    );
    
    final prompt = '''
"${subtopic.name}" konusunda öğrenci şu soruları yanlış yapmış:

${wrongQuestions.take(5).map((q) => '- ${q.questionText.length > 100 ? q.questionText.substring(0, 100) : q.questionText}...').join('\n')}

Bu konuyu daha iyi anlaması için:
1. Konunun özeti (2-3 cümle)
2. Dikkat edilmesi gereken püf noktalar
3. Pratik yapılacak alanlar

Kısa ve öz yanıtla (max 150 kelime). Emoji kullan.
''';

    try {
      final buffer = StringBuffer();
      await for (final chunk in _aiRepository.getCoachingAdviceStreaming(prompt, [])) {
        buffer.write(chunk);
      }
      return buffer.toString();
    } catch (e) {
      throw QuizAnalysisException('Alt konu analizi yapılırken hata: $e');
    }
  }
}

/// Yanlış soru bilgisi
class WrongQuestionInfo {
  final String questionId;
  final String questionText;
  final String userAnswer;
  final String correctAnswer;
  /// Sorunun ait olduğu alt konu ID'si (varsa)
  final String? subtopicId;
  /// Sorunun ait olduğu alt konu adı (varsa)
  final String? subtopicName;
  
  const WrongQuestionInfo({
    required this.questionId,
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
    this.subtopicId,
    this.subtopicName,
  });
}

class QuizAnalysisException implements Exception {
  final String message;
  QuizAnalysisException(this.message);
  
  @override
  String toString() => message;
}
