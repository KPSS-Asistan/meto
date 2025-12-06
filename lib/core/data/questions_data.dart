// Hardcoded test soruları - Firebase yerine bu dosyadan okunacak
// Tüm soru dosyalarını import et

// TARİH
import 'questions/tarih_islamiyet_oncesi.dart';
import 'questions/tarih_ilk_musluman_turk.dart';
import 'questions/tarih_osmanli.dart';
import 'questions/tarih_kurtulus_savasi.dart';
import 'questions/tarih_ataturk_ilkeleri.dart';
import 'questions/tarih_cumhuriyet.dart';
import 'questions/tarih_cagdas.dart';

// TÜRKÇE
import 'questions/turkce_ses_bilgisi.dart';
import 'questions/turkce_yapi_bilgisi.dart';
import 'questions/turkce_sozcuk_turleri.dart';
import 'questions/turkce_sozcukte_anlam.dart';
import 'questions/turkce_cumlede_anlam.dart';
import 'questions/turkce_paragrafta_anlam.dart';
import 'questions/turkce_anlatim_bozukluklari.dart';
import 'questions/turkce_yazim_noktalama.dart';
import 'questions/turkce_sozel_mantik.dart';

// COĞRAFYA
import 'questions/cografya_konum.dart';
import 'questions/cografya_fiziki.dart';
import 'questions/cografya_iklim.dart';
import 'questions/cografya_beseri.dart';
import 'questions/cografya_ekonomik.dart';
import 'questions/cografya_bolgeler.dart';

// VATANDAŞLIK
import 'questions/vatandaslik_hukuka_giris.dart';
import 'questions/vatandaslik_anayasa.dart';
import 'questions/vatandaslik_1982_anayasa.dart';
import 'questions/vatandaslik_devlet_organlari.dart';
import 'questions/vatandaslik_idari_yapi.dart';
import 'questions/vatandaslik_guncel.dart';

class QuestionsData {
  // Topic ID -> Soru listesi eşleştirmesi
  static final Map<String, List<Map<String, dynamic>>> questions = {
    // ═══════════════════════════════════════════════════════════
    // TARİH (7 konu)
    // ═══════════════════════════════════════════════════════════
    tarihIslamiyetOncesiQuestionsTopicId: tarihIslamiyetOncesiQuestions,
    tarihIlkMuslumanTurkQuestionsTopicId: tarihIlkMuslumanTurkQuestions,
    tarihOsmanliQuestionsTopicId: tarihOsmanliQuestions,
    tarihKurtulusSavasiQuestionsTopicId: tarihKurtulusSavasiQuestions,
    tarihAtaturkIlkeleriQuestionsTopicId: tarihAtaturkIlkeleriQuestions,
    tarihCumhuriyetQuestionsTopicId: tarihCumhuriyetQuestions,
    tarihCagdasQuestionsTopicId: tarihCagdasQuestions,

    // ═══════════════════════════════════════════════════════════
    // TÜRKÇE (9 konu)
    // ═══════════════════════════════════════════════════════════
    turkceSesBlgisiQuestionsTopicId: turkceSesBlgisiQuestions,
    turkceYapiBilgisiQuestionsTopicId: turkceYapiBilgisiQuestions,
    turkceSozcukTurleriQuestionsTopicId: turkceSozcukTurleriQuestions,
    turkceSozcukteAnlamQuestionsTopicId: turkceSozcukteAnlamQuestions,
    turkceCumledeAnlamQuestionsTopicId: turkceCumledeAnlamQuestions,
    turkceParagraftaAnlamQuestionsTopicId: turkceParagraftaAnlamQuestions,
    turkceAnlatimBozukluklariQuestionsTopicId: turkceAnlatimBozukluklariQuestions,
    turkceYazimNoktalamQuestionsTopicId: turkceYazimNoktalamQuestions,
    turkceSozelMantikQuestionsTopicId: turkceSozelMantikQuestions,

    // ═══════════════════════════════════════════════════════════
    // COĞRAFYA (6 konu)
    // ═══════════════════════════════════════════════════════════
    cografyaKonumQuestionsTopicId: cografyaKonumQuestions,
    cografyaFizikiQuestionsTopicId: cografyaFizikiQuestions,
    cografyaIklimQuestionsTopicId: cografyaIklimQuestions,
    cografyaBeseriQuestionsTopicId: cografyaBeseriQuestions,
    cografyaEkonomikQuestionsTopicId: cografyaEkonomikQuestions,
    cografyaBolgelerQuestionsTopicId: cografyaBolgelerQuestions,

    // ═══════════════════════════════════════════════════════════
    // VATANDAŞLIK (6 konu)
    // ═══════════════════════════════════════════════════════════
    vatandaslikHukukaGirisQuestionsTopicId: vatandaslikHukukaGirisQuestions,
    vatandaslikAnayasaQuestionsTopicId: vatandaslikAnayasaQuestions,
    vatandaslik1982AnayasaQuestionsTopicId: vatandaslik1982AnayasaQuestions,
    vatandaslikDevletOrganlariQuestionsTopicId: vatandaslikDevletOrganlariQuestions,
    vatandaslikIdariYapiQuestionsTopicId: vatandaslikIdariYapiQuestions,
    vatandaslikGuncelQuestionsTopicId: vatandaslikGuncelQuestions,
  };

  // Topic ID'ye göre soru getir
  static List<Map<String, dynamic>>? getQuestions(String topicId) {
    final data = questions[topicId];
    // Boş liste ise null döndür (soru yok gibi davran)
    if (data == null || data.isEmpty) return null;
    return data;
  }

  // Tüm topic ID'lerini getir
  static List<String> getAllTopicIds() {
    return questions.keys.toList();
  }

  // Belirli bir topic için soru var mı kontrol et
  static bool hasQuestions(String topicId) {
    final data = questions[topicId];
    return data != null && data.isNotEmpty;
  }
  
  // Soru sayısını getir
  static int getQuestionCount(String topicId) {
    final data = questions[topicId];
    return data?.length ?? 0;
  }
  
  // Rastgele N soru getir
  static List<Map<String, dynamic>> getRandomQuestions(String topicId, int count) {
    final data = questions[topicId];
    if (data == null || data.isEmpty) return [];
    
    final shuffled = List<Map<String, dynamic>>.from(data)..shuffle();
    return shuffled.take(count).toList();
  }
}
