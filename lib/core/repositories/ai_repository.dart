import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kpss_2026/core/services/api_key_service.dart';
import 'package:kpss_2026/core/services/local_progress_service.dart';
import 'package:kpss_2026/core/services/quiz_stats_service.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';

class AiRepository {
  AiRepository();

  /// Get coaching advice from AI - Streaming ile
  Stream<String> getCoachingAdviceStreaming(String question, List<Map<String, dynamic>> chatHistory) async* {
    try {
      // API Key'i al (cache'den veya Firebase'den)
      final apiKey = await ApiKeyService.getApiKey();
      
      // Soru performans analizi mi gerektiriyor?
      final needsAnalysis = _questionNeedsUserAnalysis(question);
      
      // Sadece analiz gereken sorular için kullanıcı verilerini al
      final userContext = needsAnalysis ? await _getUserContext() : '';
      
      // Streaming API çağrısı
      await for (final chunk in _callOpenRouterStreaming(apiKey, question, userContext)) {
        yield chunk;
      }
    } catch (e) {
      AppLogger.error('AI Coach Streaming Error', e);
      yield 'AI Koç şu an meşgul, biraz sonra tekrar dene.';
    }
  }

  /// Sorunun kullanıcı analizi gerektirip gerektirmediğini kontrol et
  bool _questionNeedsUserAnalysis(String question) {
    final lowerQuestion = question.toLowerCase();
    
    // Performans analizi gerektiren kelimeler
    final analysisKeywords = [
      // Durum soruları
      'durumum', 'durum', 'nasıl gidiyorum', 'nasılım', 'neredeyim',
      // Performans soruları  
      'performansım', 'performans', 'başarı oranım', 'başarım', 'başarı',
      'oranım', 'oran', 'skor', 'puan', 'not',
      // Analiz soruları
      'zayıf yönlerim', 'zayıf', 'güçlü yönlerim', 'güçlü', 'eksik',
      'ilerleme', 'gelişim', 'analiz', 'değerlendir', 'yorumla',
      // İstatistik soruları
      'serim', 'seri', 'istatistik', 'veri', 'kaç soru', 'kaç tane',
      'çözdüm', 'doğru yaptım', 'yanlış yaptım', 'doğru', 'yanlış',
      // Genel çalışma soruları
      'çalışıyorum', 'hazırlanıyorum', 'öğrenciyim', 'öğrenci olarak',
      'ne kadar', 'hangi konu', 'hangi ders'
    ];
    
    return analysisKeywords.any((keyword) => lowerQuestion.contains(keyword));
  }

  /// Kullanıcı verilerini AI için hazırla
  Future<String> _getUserContext() async {
    try {
      // LocalProgressService'ten verileri al
      final progressService = await LocalProgressService.getInstance();
      final summary = progressService.getAISummary();
      
      // QuizStatsService'ten de istatistikleri al (backup olarak)
      final totalSolved = await QuizStatsService.getTotalSolved();
      final totalCorrect = await QuizStatsService.getTotalCorrect();
      final successRate = await QuizStatsService.getSuccessRate();
      
      final totalQuestions = summary['totalQuestionsAnswered'] as int;
      final summaryTotalCorrect = summary['totalCorrectAnswers'] as int;
      final summarySuccessRate = summary['overallSuccessRate'] as double;
      final streak = summary['currentStreak'] as int;
      final weakTopics = summary['weakTopics'] as List<String>;
      final strongTopics = summary['strongTopics'] as List<String>;
      final quizCount = summary['quizCount'] as int;
      
      // Hiç veri yoksa genel KPSS tavsiyeleri ver
      if (totalQuestions == 0 && totalSolved == 0) {
        return '''ÖĞRENCİ BİLGİSİ: Henüz soru çözmemiş, yeni başlayan bir öğrenci.

GENEL KPSS HAZIRLIK TAVSİYELERİ:
- KPSS müfredatını 4 ana ders olarak ayır: Tarih, Coğrafya, Vatandaşlık, Türkçe
- Haftada en az 3-4 gün çalış, günde 2-3 saat
- Önce temel kavramları öğren, sonra soru çöz
- Yanlış yapılan soruları tekrar çalış
- Düzenli tekrar yap, unutma eğrisine göre çalış

Bu öğrenci için temel hazırlık tavsiyeleri ver.''';
      }
      
      // QuizStatsService'ten gelen verileri kullan (daha güncel olabilir)
      final finalTotalQuestions = totalSolved > totalQuestions ? totalSolved : totalQuestions;
      final finalTotalCorrect = totalCorrect > 0 ? totalCorrect : summaryTotalCorrect;
      final finalSuccessRate = successRate > 0 ? successRate : summarySuccessRate;
      
      final weakStr = weakTopics.isNotEmpty ? weakTopics.join(', ') : 'Henüz belirlenmemiş';
      final strongStr = strongTopics.isNotEmpty ? strongTopics.join(', ') : 'Henüz belirlenmemiş';
      
      return '''ÖĞRENCİ PERFORMANS VERİLERİ:
Toplam çözülen soru: $finalTotalQuestions
Doğru cevap: $finalTotalCorrect
Başarı oranı: %${finalSuccessRate.toStringAsFixed(1)}
Günlük seri: $streak gün
Tamamlanan test: $quizCount
Zayıf konular: $weakStr
Güçlü konular: $strongStr

Bu verilere göre öğrenciye kişiselleştirilmiş tavsiyeler ver.''';
    } catch (e) {
      AppLogger.error('User context error', e);
      return '''ÖĞRENCİ BİLGİSİ: Öğrenci verilerine erişilemedi.

GENEL KPSS HAZIRLIK TAVSİYELERİ:
- Düzenli çalışma programı oluştur
- Temel kavramları önceliklendir
- Soru çözme pratiği yap
- Yanlışları analiz et ve tekrar çalış
- Motivasyonunu yüksek tut

Genel KPSS tavsiyeleri ver.''';
    }
  }

  /// OpenRouter API çağrısı - Streaming ile
  Stream<String> _callOpenRouterStreaming(String apiKey, String question, String userContext) async* {
    final hasUserData = userContext.isNotEmpty;
    
    final systemPrompt = '''Sen KPSS hazırlık sürecinde öğrencilere rehberlik eden deneyimli bir eğitim koçusun.

${hasUserData ? '''$userContext

ÖNEMLİ: Yukarıdaki öğrenci verileri sana sağlandı. Bu verileri kullanarak cevap ver. Öğrenciden veri isteme, zaten elinde var. Verilere göre kişiselleştirilmiş tavsiyeler ver.''' : ''}

TEMEL KURALLAR:
- Kısa ve öz cevaplar ver, gereksiz uzatma
- Düz yazı kullan, asla liste veya madde işareti kullanma
- Emoji kullanma
- Samimi ama profesyonel ol
- Soruya doğrudan cevap ver

UZMANLIK ALANLARIN:
- KPSS müfredatı ve sınav stratejileri
- Çalışma teknikleri ve zaman yönetimi
- Motivasyon ve psikolojik destek
- Konu anlatımı ve soru çözme

YASAKLAR:
- Sağlık, siyaset, din konularına girme
- Markdown işaretleri kullanma (*, **, -, 1. vb.)
- Öğrenciden veri isteme (veriler zaten sağlandıysa)''';

    final request = http.Request('POST', Uri.parse('https://openrouter.ai/api/v1/chat/completions'))
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://kpssasistan.app',
        'X-Title': 'KPSS Asistan AI Coach',
      })
      ..body = jsonEncode({
        'model': 'x-ai/grok-4.1-fast',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': question}
        ],
        'max_tokens': 500,
        'temperature': 0.7,
        'stream': true, // Streaming aktif
      });

    final response = await http.Client().send(request);
    
    if (response.statusCode != 200) {
      throw Exception('API Hatası: ${response.statusCode}');
    }

    String buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder).transform(LineSplitter())) {
      if (chunk.startsWith('data: ')) {
        final data = chunk.substring(6);
        if (data == '[DONE]') break;
        
        try {
          final jsonData = jsonDecode(data);
          final content = jsonData['choices']?[0]?['delta']?['content'] ?? '';
          if (content.isNotEmpty) {
            buffer += content;
            yield buffer; // Her chunk'ta güncel metni gönder
          }
        } catch (e) {
          // JSON parse hatası, devam et
        }
      }
    }
  }

  /// Quiz Analizi için özel streaming metodu - Kısa ve öz yanıtlar
  Stream<String> getQuizAnalysisStreaming(String analysisPrompt) async* {
    try {
      final apiKey = await ApiKeyService.getApiKey();
      await for (final chunk in _callQuizAnalysisStreaming(apiKey, analysisPrompt)) {
        yield chunk;
      }
    } catch (e) {
      AppLogger.error('Quiz Analysis Streaming Error', e);
      yield 'Analiz yapılırken bir hata oluştu.';
    }
  }

  /// Quiz Analizi için OpenRouter çağrısı - Kısa yanıtlar
  Stream<String> _callQuizAnalysisStreaming(String apiKey, String prompt) async* {
    final systemPrompt = '''Sen KPSS uzmanı eğitim koçusun.

GÖREV: Test sonucunu 4 madde halinde analiz et.

FORMAT:
• Durum: [1 cümle değerlendirme]
• Odaklan: [Hangi konuya odaklanmalı]  
• Öneri: [1 pratik öneri]
• Motivasyon: [1 motive edici cümle]

KURALLAR:
- Her madde TEK CÜMLE
- Toplam 50-60 kelime
- Emoji kullanabilirsin
- Türkçe yaz
- ASLA ** veya * kullanma, düz metin yaz''';

    final request = http.Request('POST', Uri.parse('https://openrouter.ai/api/v1/chat/completions'))
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://kpssasistan.app',
        'X-Title': 'KPSS Asistan Quiz Analysis',
      })
      ..body = jsonEncode({
        'model': 'x-ai/grok-4.1-fast',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 200, // Kısa yanıtlar için düşük token
        'temperature': 0.5, // Daha tutarlı yanıtlar
        'stream': true,
      });

    final response = await http.Client().send(request);
    
    if (response.statusCode != 200) {
      throw Exception('API Hatası: ${response.statusCode}');
    }

    String buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder).transform(LineSplitter())) {
      if (chunk.startsWith('data: ')) {
        final data = chunk.substring(6);
        if (data == '[DONE]') break;
        
        try {
          final jsonData = jsonDecode(data);
          final content = jsonData['choices']?[0]?['delta']?['content'] ?? '';
          if (content.isNotEmpty) {
            buffer += content;
            yield buffer;
          }
        } catch (e) {
          // JSON parse hatası
        }
      }
    }
  }
}
