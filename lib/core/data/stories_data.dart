// Hardcoded hikaye içerikleri - Firebase yerine bu dosyadan okunacak
// Tüm hikaye dosyalarını import et

// TARİH
import 'stories/tarih_islamiyet_oncesi.dart';
import 'stories/tarih_ilk_musluman_turk.dart';
import 'stories/tarih_osmanli.dart';
import 'stories/tarih_kurtulus_savasi.dart';
import 'stories/tarih_ataturk_ilkeleri.dart';
import 'stories/tarih_cumhuriyet.dart';
import 'stories/tarih_cagdas.dart';

// TÜRKÇE
import 'stories/turkce_ses_bilgisi.dart';
import 'stories/turkce_yapi_bilgisi.dart';
import 'stories/turkce_sozcuk_turleri.dart';
import 'stories/turkce_sozcukte_anlam.dart';
import 'stories/turkce_cumlede_anlam.dart';
import 'stories/turkce_paragrafta_anlam.dart';
import 'stories/turkce_anlatim_bozukluklari.dart';
import 'stories/turkce_yazim_noktalama.dart';
import 'stories/turkce_sozel_mantik.dart';

// COĞRAFYA
import 'stories/cografya_konum.dart';
import 'stories/cografya_fiziki.dart';
import 'stories/cografya_iklim.dart';
import 'stories/cografya_beseri.dart';
import 'stories/cografya_ekonomik.dart';
import 'stories/cografya_bolgeler.dart';

// VATANDAŞLIK
import 'stories/vatandaslik_hukuka_giris.dart';
import 'stories/vatandaslik_anayasa.dart';
import 'stories/vatandaslik_1982_anayasa.dart';
import 'stories/vatandaslik_devlet_organlari.dart';
import 'stories/vatandaslik_idari_yapi.dart';
import 'stories/vatandaslik_guncel.dart';

class StoriesData {
  // Topic ID -> Hikaye listesi eşleştirmesi
  static final Map<String, List<Map<String, dynamic>>> stories = {
    // ═══════════════════════════════════════════════════════════
    // TARİH (7 konu)
    // ═══════════════════════════════════════════════════════════
    tarihIslamiyetOncesiStoryTopicId: tarihIslamiyetOncesiStory,
    tarihIlkMuslumanTurkStoryTopicId: tarihIlkMuslumanTurkStory,
    tarihOsmanliStoryTopicId: tarihOsmanliStory,
    tarihKurtulusSavasiStoryTopicId: tarihKurtulusSavasiStory,
    tarihAtaturkIlkeleriStoryTopicId: tarihAtaturkIlkeleriStory,
    tarihCumhuriyetStoryTopicId: tarihCumhuriyetStory,
    tarihCagdasStoryTopicId: tarihCagdasStory,

    // ═══════════════════════════════════════════════════════════
    // TÜRKÇE (9 konu)
    // ═══════════════════════════════════════════════════════════
    turkceSesBlgisiStoryTopicId: turkceSesBlgisiStory,
    turkceYapiBilgisiStoryTopicId: turkceYapiBilgisiStory,
    turkceSozcukTurleriStoryTopicId: turkceSozcukTurleriStory,
    turkceSozcukteAnlamStoryTopicId: turkceSozcukteAnlamStory,
    turkceCumledeAnlamStoryTopicId: turkceCumledeAnlamStory,
    turkceParagraftaAnlamStoryTopicId: turkceParagraftaAnlamStory,
    turkceAnlatimBozukluklariStoryTopicId: turkceAnlatimBozukluklariStory,
    turkceYazimNoktalamStoryTopicId: turkceYazimNoktalamStory,
    turkceSozelMantikStoryTopicId: turkceSozelMantikStory,

    // ═══════════════════════════════════════════════════════════
    // COĞRAFYA (6 konu)
    // ═══════════════════════════════════════════════════════════
    cografyaKonumStoryTopicId: cografyaKonumStory,
    cografyaFizikiStoryTopicId: cografyaFizikiStory,
    cografyaIklimStoryTopicId: cografyaIklimStory,
    cografyaBeseriStoryTopicId: cografyaBeseriStory,
    cografyaEkonomikStoryTopicId: cografyaEkonomikStory,
    cografyaBolgelerStoryTopicId: cografyaBolgelerStory,

    // ═══════════════════════════════════════════════════════════
    // VATANDAŞLIK (6 konu)
    // ═══════════════════════════════════════════════════════════
    vatandaslikHukukaGirisStoryTopicId: vatandaslikHukukaGirisStory,
    vatandaslikAnayasaStoryTopicId: vatandaslikAnayasaStory,
    vatandaslik1982AnayasaStoryTopicId: vatandaslik1982AnayasaStory,
    vatandaslikDevletOrganlariStoryTopicId: vatandaslikDevletOrganlariStory,
    vatandaslikIdariYapiStoryTopicId: vatandaslikIdariYapiStory,
    vatandaslikGuncelStoryTopicId: vatandaslikGuncelStory,
  };

  // Topic ID'ye göre hikaye getir
  static List<Map<String, dynamic>>? getStory(String topicId) {
    final story = stories[topicId];
    // Boş liste ise null döndür (hikaye yok gibi davran)
    if (story == null || story.isEmpty) return null;
    return story;
  }

  // Tüm topic ID'lerini getir
  static List<String> getAllTopicIds() {
    return stories.keys.toList();
  }

  // Belirli bir topic için hikaye var mı kontrol et
  static bool hasStory(String topicId) {
    final story = stories[topicId];
    return story != null && story.isNotEmpty;
  }
}
