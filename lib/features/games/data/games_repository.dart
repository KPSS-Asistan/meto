import 'package:kpss_2026/core/data/matching_games_data.dart';

/// ⚡ HARDCODED ONLY - Firebase bağımlılığı kaldırıldı
class GamesRepository {
  GamesRepository();

  /// Eşleştirme oyunu için soru-cevap çiftleri - Tamamen hardcoded
  Future<List<Map<String, String>>> getMatchingGameData(String topicId) async {
    return MatchingGamesData.getMatchingData(topicId);
  }

  /// Hafıza oyunu için kart çiftleri - Hardcoded
  Future<List<Map<String, String>>> getMemoryGameData(String topicId) async {
    // Eşleştirme verisini hafıza oyunu formatına çevir
    final matchingData = MatchingGamesData.getMatchingData(topicId);
    if (matchingData.isNotEmpty) {
      return matchingData.take(6).map((item) => {
        'term': item['question'] ?? '',
        'definition': item['answer'] ?? '',
      }).toList();
    }
    return _getDefaultMemoryData();
  }

  /// Kelime avı oyunu için kategori ve kelimeler - Hardcoded
  Future<Map<String, List<String>>> getWordHuntData(String topicId) async {
    // TODO: WordHuntData oluşturulacak
    return _getDefaultWordHuntData();
  }

  // Default veriler (Firestore'da veri yoksa)
  List<Map<String, String>> _getDefaultMemoryData() {
    return [
      {'term': 'Demokrasi', 'definition': 'Halk egemenliği'},
      {'term': 'Cumhuriyet', 'definition': 'Halk yönetimi'},
      {'term': 'Laiklik', 'definition': 'Din-devlet ayrımı'},
      {'term': 'Milliyetçilik', 'definition': 'Ulus bilinci'},
      {'term': 'Devletçilik', 'definition': 'Devlet müdahalesi'},
      {'term': 'Halkçılık', 'definition': 'Sınıf ayrımı yokluğu'},
    ];
  }

  Map<String, List<String>> _getDefaultWordHuntData() {
    return {
      'Atatürk İlkeleri': ['Cumhuriyetçilik', 'Milliyetçilik', 'Halkçılık', 'Devletçilik', 'Laiklik', 'İnkılapçılık'],
      'Türk Devletleri': ['Hunlar', 'Göktürkler', 'Uygurlar', 'Selçuklular', 'Osmanlı', 'Türkiye'],
      'Tarih Terimleri': ['Fetih', 'İstila', 'Savaş', 'Barış', 'Antlaşma', 'İsyan'],
    };
  }

  /// Kelime avı için soru-cevap formatında veri - Hardcoded
  Future<List<Map<String, String>>> getWordHuntQuestions(String topicId) async {
    // TODO: WordHuntQuestionsData oluşturulacak
    return _getDefaultWordHuntQuestions();
  }

  List<Map<String, String>> _getDefaultWordHuntQuestions() {
    return [
      {'question': 'Şehzadeler şehri olarak bilinen il?', 'answer': 'AMASYA', 'extraLetters': 'KTRN'},
      {'question': 'Osmanlı Devletinin kurucusu?', 'answer': 'OSMAN', 'extraLetters': 'BKYL'},
      {'question': 'İstanbulun fethedildiği yıl?', 'answer': 'BİNDÖRTYÜZELLİÜÇ', 'extraLetters': 'KSMN'},
      {'question': 'TBMM hangi şehirde açıldı?', 'answer': 'ANKARA', 'extraLetters': 'STLM'},
      {'question': 'Kurtuluş Savaşının başladığı şehir?', 'answer': 'SAMSUN', 'extraLetters': 'KBYL'},
      {'question': 'Türkiyenin en büyük gölü?', 'answer': 'VAN', 'extraLetters': 'STKMB'},
      {'question': 'Cumhuriyetin ilan edildiği yıl?', 'answer': 'BİNDOKUZYÜZYİRMİÜÇ', 'extraLetters': 'KLST'},
      {'question': 'Türkiyenin başkenti?', 'answer': 'ANKARA', 'extraLetters': 'STLM'},
    ];
  }
}
