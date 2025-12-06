// Hardcoded eşleştirme oyunu verileri - Firebase yerine bu dosyadan okunacak
// Tüm eşleştirme dosyalarını import et

// TARİH
import 'matching_games/tarih_islamiyet_oncesi.dart';
import 'matching_games/tarih_ilk_musluman_turk.dart';
import 'matching_games/tarih_osmanli.dart';
import 'matching_games/tarih_kurtulus_savasi.dart';
import 'matching_games/tarih_ataturk_ilkeleri.dart';
import 'matching_games/tarih_cumhuriyet.dart';
import 'matching_games/tarih_cagdas.dart';

// TÜRKÇE
import 'matching_games/turkce_ses_bilgisi.dart';
import 'matching_games/turkce_yapi_bilgisi.dart';
import 'matching_games/turkce_sozcuk_turleri.dart';
import 'matching_games/turkce_sozcukte_anlam.dart';
import 'matching_games/turkce_cumlede_anlam.dart';
import 'matching_games/turkce_paragrafta_anlam.dart';
import 'matching_games/turkce_anlatim_bozukluklari.dart';
import 'matching_games/turkce_yazim_noktalama.dart';
import 'matching_games/turkce_sozel_mantik.dart';

// COĞRAFYA
import 'matching_games/cografya_konum.dart';
import 'matching_games/cografya_fiziki.dart';
import 'matching_games/cografya_iklim.dart';
import 'matching_games/cografya_beseri.dart';
import 'matching_games/cografya_ekonomik.dart';
import 'matching_games/cografya_bolgeler.dart';

// VATANDAŞLIK
import 'matching_games/vatandaslik_hukuka_giris.dart';
import 'matching_games/vatandaslik_anayasa.dart';
import 'matching_games/vatandaslik_1982_anayasa.dart';
import 'matching_games/vatandaslik_devlet_organlari.dart';
import 'matching_games/vatandaslik_idari_yapi.dart';
import 'matching_games/vatandaslik_guncel.dart';

class MatchingGamesData {
  // Topic ID -> Eşleştirme listesi eşleştirmesi
  static final Map<String, List<Map<String, String>>> matchingGames = {
    // ═══════════════════════════════════════════════════════════
    // TARİH (7 konu)
    // ═══════════════════════════════════════════════════════════
    tarihIslamiyetOncesiMatchingTopicId: tarihIslamiyetOncesiMatching,
    tarihIlkMuslumanTurkMatchingTopicId: tarihIlkMuslumanTurkMatching,
    tarihOsmanliMatchingTopicId: tarihOsmanliMatching,
    tarihKurtulusSavasiMatchingTopicId: tarihKurtulusSavasiMatching,
    tarihAtaturkIlkeleriMatchingTopicId: tarihAtaturkIlkeleriMatching,
    tarihCumhuriyetMatchingTopicId: tarihCumhuriyetMatching,
    tarihCagdasMatchingTopicId: tarihCagdasMatching,

    // ═══════════════════════════════════════════════════════════
    // TÜRKÇE (9 konu)
    // ═══════════════════════════════════════════════════════════
    turkceSesBlgisiMatchingTopicId: turkceSesBlgisiMatching,
    turkceYapiBilgisiMatchingTopicId: turkceYapiBilgisiMatching,
    turkceSozcukTurleriMatchingTopicId: turkceSozcukTurleriMatching,
    turkceSozcukteAnlamMatchingTopicId: turkceSozcukteAnlamMatching,
    turkceCumledeAnlamMatchingTopicId: turkceCumledeAnlamMatching,
    turkceParagraftaAnlamMatchingTopicId: turkceParagraftaAnlamMatching,
    turkceAnlatimBozukluklariMatchingTopicId: turkceAnlatimBozukluklariMatching,
    turkceYazimNoktalamMatchingTopicId: turkceYazimNoktalamMatching,
    turkceSozelMantikMatchingTopicId: turkceSozelMantikMatching,

    // ═══════════════════════════════════════════════════════════
    // COĞRAFYA (6 konu)
    // ═══════════════════════════════════════════════════════════
    cografyaKonumMatchingTopicId: cografyaKonumMatching,
    cografyaFizikiMatchingTopicId: cografyaFizikiMatching,
    cografyaIklimMatchingTopicId: cografyaIklimMatching,
    cografyaBeseriMatchingTopicId: cografyaBeseriMatching,
    cografyaEkonomikMatchingTopicId: cografyaEkonomikMatching,
    cografyaBolgelerMatchingTopicId: cografyaBolgelerMatching,

    // ═══════════════════════════════════════════════════════════
    // VATANDAŞLIK (6 konu)
    // ═══════════════════════════════════════════════════════════
    vatandaslikHukukaGirisMatchingTopicId: vatandaslikHukukaGirisMatching,
    vatandaslikAnayasaMatchingTopicId: vatandaslikAnayasaMatching,
    vatandaslik1982AnayasaMatchingTopicId: vatandaslik1982AnayasaMatching,
    vatandaslikDevletOrganlariMatchingTopicId: vatandaslikDevletOrganlariMatching,
    vatandaslikIdariYapiMatchingTopicId: vatandaslikIdariYapiMatching,
    vatandaslikGuncelMatchingTopicId: vatandaslikGuncelMatching,
  };

  // Default veri (hiçbir konu için veri yoksa)
  static final List<Map<String, String>> _defaultMatching = [
    {'question': 'Osmanlı Kurucusu', 'answer': 'Osman Bey'},
    {'question': 'İstanbul Fethi', 'answer': '1453'},
    {'question': 'Cumhuriyet İlanı', 'answer': '29 Ekim 1923'},
    {'question': 'Başkent', 'answer': 'Ankara'},
    {'question': 'TBMM Açılışı', 'answer': '23 Nisan 1920'},
    {'question': 'Kurtuluş Savaşı', 'answer': '19 Mayıs 1919'},
    {'question': 'Lozan Antlaşması', 'answer': '24 Temmuz 1923'},
    {'question': 'Saltanatın Kaldırılması', 'answer': '1 Kasım 1922'},
  ];

  // Topic ID'ye göre eşleştirme verisi getir
  static List<Map<String, String>> getMatchingData(String topicId) {
    final data = matchingGames[topicId];
    // Boş liste ise default döndür
    if (data == null || data.isEmpty) return _defaultMatching;
    return data;
  }

  // Tüm topic ID'lerini getir
  static List<String> getAllTopicIds() {
    return matchingGames.keys.toList();
  }

  // Belirli bir topic için özel veri var mı kontrol et
  static bool hasCustomData(String topicId) {
    final data = matchingGames[topicId];
    return data != null && data.isNotEmpty;
  }
}
