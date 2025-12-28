import 'package:cloud_functions/cloud_functions.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';

/// 🔒 GÜVENLİ AI SERVİSİ
/// Cloud Functions üzerinden API çağrısı yapar
/// API key client'ta tutulmaz, rate limiting server'da yapılır
class CloudAiService {
  static CloudAiService? _instance;
  static CloudAiService get instance => _instance ??= CloudAiService._();
  
  CloudAiService._();
  
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  
  /// AI Coach'a soru sor (Cloud Functions üzerinden)
  /// Rate limiting: Günlük 10 soru
  /// Returns: {success, response, remaining, quickQuestions?}
  Future<Map<String, dynamic>> askCoach(String question) async {
    try {
      AppLogger.info('🔒 Cloud Functions üzerinden AI çağrısı...');
      
      final callable = _functions.httpsCallable(
        'askAICoach',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );
      
      final result = await callable.call<Map<String, dynamic>>({
        'question': question,
      });
      
      final data = Map<String, dynamic>.from(result.data);
      
      AppLogger.success('✅ AI yanıtı alındı, kalan: ${data['remaining']}');
      
      return {
        'success': true,
        'response': data['response'] ?? '',
        'remaining': data['remaining'] ?? 0,
        'quickQuestions': data['quickQuestions'] ?? [],
      };
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('❌ Cloud Functions hatası: ${e.code}', e);
      
      // Hata kodlarına göre kullanıcı dostu mesajlar
      String errorMessage;
      switch (e.code) {
        case 'unauthenticated':
          errorMessage = 'AI Koç\'u kullanmak için giriş yapmalısın.';
          break;
        case 'resource-exhausted':
          errorMessage = e.message ?? 'Günlük soru limitin doldu (10/10). Yarın gel!';
          break;
        case 'invalid-argument':
          errorMessage = 'Soru çok uzun veya geçersiz.';
          break;
        default:
          errorMessage = 'AI Koç şu an meşgul, biraz sonra tekrar dene.';
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'code': e.code,
      };
    } catch (e) {
      AppLogger.error('❌ AI Service hatası', e);
      return {
        'success': false,
        'error': 'Bağlantı hatası, internet bağlantını kontrol et.',
      };
    }
  }
  
  /// API key'e ihtiyaç duymayan, Cloud Functions'ı kullanan streaming alternatifi
  /// NOT: Cloud Functions HTTPS Callable streaming desteklemiyor
  /// Bu nedenle non-streaming response kullanılıyor
  Stream<String> askCoachStream(String question) async* {
    // Streaming simülasyonu için non-streaming response kullan
    final result = await askCoach(question);
    
    if (result['success'] == true) {
      final response = result['response'] as String;
      // Kelime kelime stream et (UX için)
      final words = response.split(' ');
      String buffer = '';
      for (int i = 0; i < words.length; i++) {
        buffer += (i == 0 ? '' : ' ') + words[i];
        yield buffer;
        await Future.delayed(const Duration(milliseconds: 30));
      }
    } else {
      yield result['error'] ?? 'Bir hata oluştu.';
    }
  }
}
