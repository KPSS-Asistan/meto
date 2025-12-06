// Flashcard Data - Modular System
// Her konu icin ayri dosya, buradan import edilir
// 
// Yeni flashcard eklemek icin:
// 1. flashcards/ klasorune yeni dosya olustur
// 2. topicId ve flashcards listesi tanimla
// 3. Bu dosyaya import ekle
// 4. flashcardsData map'ine kayit ekle

// ═══════════════════════════════════════════════════════════════════════════
// IMPORTS - Her konu icin ayri dosya
// ═══════════════════════════════════════════════════════════════════════════

// TARİH (7 konu)
import 'flashcards/tarih_islamiyet_oncesi.dart';
import 'flashcards/tarih_ilk_musluman_turk.dart';
import 'flashcards/tarih_osmanli.dart';
import 'flashcards/tarih_kurtulus_savasi.dart';
import 'flashcards/tarih_ataturk_ilkeleri.dart';
import 'flashcards/tarih_cumhuriyet.dart';
import 'flashcards/tarih_cagdas.dart';

// TÜRKÇE (9 konu)
import 'flashcards/turkce_ses_bilgisi.dart';
import 'flashcards/turkce_yapi_bilgisi.dart';
import 'flashcards/turkce_sozcuk_turleri.dart';
import 'flashcards/turkce_sozcukte_anlam.dart';
import 'flashcards/turkce_cumlede_anlam.dart';
import 'flashcards/turkce_paragrafta_anlam.dart';
import 'flashcards/turkce_anlatim_bozukluklari.dart';
import 'flashcards/turkce_yazim_noktalama.dart';
import 'flashcards/turkce_sozel_mantik.dart';

// COĞRAFYA (6 konu)
import 'flashcards/cografya_konum.dart';
import 'flashcards/cografya_fiziki.dart';
import 'flashcards/cografya_iklim.dart';
import 'flashcards/cografya_beseri.dart';
import 'flashcards/cografya_ekonomik.dart';
import 'flashcards/cografya_bolgeler.dart';

// VATANDAŞLIK (6 konu)
import 'flashcards/vatandaslik_hukuka_giris.dart';
import 'flashcards/vatandaslik_anayasa.dart';
import 'flashcards/vatandaslik_1982_anayasa.dart';
import 'flashcards/vatandaslik_devlet_organlari.dart';
import 'flashcards/vatandaslik_idari_yapi.dart';
import 'flashcards/vatandaslik_guncel.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TOPIC ID REFERENCE - Tum konu ID'leri
// ═══════════════════════════════════════════════════════════════════════════
// 
// TARİH (Lesson: caZ5LwfH3QJrBVUQCros)
// ├── JnFbEQt0uA8RSEuy22SQ - Islamiyet Oncesi Turk Tarihi ✅
// ├── 9Hg8tuMRdMTuVY7OZ9HL - Ilk Musluman Turk Devletleri ✅
// ├── rl2xQTfv1iUaCyhFzp5V - Osmanli Devleti Tarihi ✅
// ├── DlT19snCttf5j5RUAXLz - Kurtulus Savasi Donemi ✅
// ├── 4GUvpqBBImcLmN2eh1HK - Ataturk Ilke ve Inkılaplari ✅
// ├── onwrfsH02TgIhlyRUh56 - Cumhuriyet Donemi
// └── xQWHl1hBYAKM96X4deR8 - Cagdas Turk ve Dunya Tarihi
// 
// TÜRKÇE (Lesson: L3i1Rqv2LN3AKFFejuUg)
// ├── 80e0wkTLvaTQzPD6puB7 - Ses Bilgisi ✅
// ├── yWlh5C6jB7lzuJOodr2t - Yapi Bilgisi
// ├── ICNDiSlTmmjWEQPT6rmT - Sozcuk Turleri
// ├── JmyiPxf3n96Jkxqsa9jY - Sozcukte Anlam
// ├── AJNLHhhaG2SLWOvxDYqW - Cumlede Anlam
// ├── nN8JOTR7LZm01AN2i3sQ - Paragrafta Anlam
// ├── jXcsrl5HEb65DmfpfqqI - Anlatim Bozukluklari
// ├── qSEqigIsIEBAkhcMTyCE - Yazim Kurallari ve Noktalama
// └── wnt2zWaV1pX8p8s8BBc9 - Sozel Mantik ve Akil Yurutme
// 
// COĞRAFYA (Lesson: A779wvZWQcbvanmbS8Qz)
// ├── 1FEcPsGduhjcQARpaGBk - Turkiyenin Cografi Konumu ✅
// ├── kbs0Ffved9pCP3Hq9M9k - Turkiyenin Fiziki Ozellikleri
// ├── 6e0Thsz2RRNHFcwqQXso - Turkiyenin Iklimi ve Bitki Ortusu
// ├── uYDrMlBCEAho5776WZi8 - Beseri Cografya
// ├── WxrtQ26p2My4uJa0h1kk - Ekonomik Cografya
// └── GdpN8uxJNGtexWrkoL1T - Turkiyenin Cografi Bolgeleri
// 
// VATANDAŞLIK (Lesson: 2ztkqV35cWjGRkhYRutg)
// ├── AQ0Zph76dzPdr87H1uKa - Hukuka Giris
// ├── n4OjWupHmouuybQzQ1Fc - Anayasa Hukuku ✅
// ├── xXGXiqx2TkCtI4C7GMQg - 1982 Anayasasi Temel Ilkeleri
// ├── 1JZAYECyEn7farNNyGyx - Devlet Organlari
// ├── lv93cmhwq7RmOFM5WxWD - Idari Yapi
// └── Bo3qqooJsqtIZrK5zc9S - Guncel Olaylar

// ═══════════════════════════════════════════════════════════════════════════
// FLASHCARDS DATA MAP - Topic ID -> Flashcards
// ═══════════════════════════════════════════════════════════════════════════

final Map<String, List<Map<String, String>>> flashcardsData = {
  // ═══════════════════════════════════════════════════════════════════════════
  // TARİH (7 konu)
  // ═══════════════════════════════════════════════════════════════════════════
  tarihIslamiyetOncesiTopicId: tarihIslamiyetOncesiFlashcards,
  tarihIlkMuslumanTurkTopicId: tarihIlkMuslumanTurkFlashcards,
  tarihOsmanliTopicId: tarihOsmanliFlashcards,
  tarihKurtulusSavasiTopicId: tarihKurtulusSavasiFlashcards,
  tarihAtaturkIlkeleriTopicId: tarihAtaturkIlkeleriFlashcards,
  tarihCumhuriyetTopicId: tarihCumhuriyetFlashcards,
  tarihCagdasTopicId: tarihCagdasFlashcards,
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TÜRKÇE (9 konu)
  // ═══════════════════════════════════════════════════════════════════════════
  turkceSesTopicId: turkceSesFlashcards,
  turkceYapiTopicId: turkceYapiFlashcards,
  turkceSozcukTurleriTopicId: turkceSozcukTurleriFlashcards,
  turkceSozcukteAnlamTopicId: turkceSozcukteAnlamFlashcards,
  turkceCumledeAnlamTopicId: turkceCumledeAnlamFlashcards,
  turkceParagraftaAnlamTopicId: turkceParagraftaAnlamFlashcards,
  turkceAnlatimBozukluklariTopicId: turkceAnlatimBozukluklariFlashcards,
  turkceYazimNoktalamTopicId: turkceYazimNoktalamaFlashcards,
  turkceSozelMantikTopicId: turkceSozelMantikFlashcards,
  
  // ═══════════════════════════════════════════════════════════════════════════
  // COĞRAFYA (6 konu)
  // ═══════════════════════════════════════════════════════════════════════════
  cografyaKonumTopicId: cografyaKonumFlashcards,
  cografyaFizikiTopicId: cografyaFizikiFlashcards,
  cografyaIklimTopicId: cografyaIklimFlashcards,
  cografyaBeseriTopicId: cografyaBeseriFlashcards,
  cografyaEkonomikTopicId: cografyaEkonomikFlashcards,
  cografyaBolgelerTopicId: cografyaBolgelerFlashcards,
  
  // ═══════════════════════════════════════════════════════════════════════════
  // VATANDAŞLIK (6 konu)
  // ═══════════════════════════════════════════════════════════════════════════
  vatandaslikHukukaGirisTopicId: vatandaslikHukukaGirisFlashcards,
  vatandaslikAnayasaTopicId: vatandaslikAnayasaFlashcards,
  vatandaslik1982AnayasaTopicId: vatandaslik1982AnayasaFlashcards,
  vatandaslikDevletOrganlariTopicId: vatandaslikDevletOrganlariFlashcards,
  vatandaslikIdariYapiTopicId: vatandaslikIdariYapiFlashcards,
  vatandaslikGuncelTopicId: vatandaslikGuncelFlashcards,
};

// Topic ID'ye gore flashcard listesi dondurur
List<Map<String, String>>? getFlashcardsForTopic(String topicId) {
  return flashcardsData[topicId];
}

// Tum topic ID'lerini dondurur
List<String> getAllFlashcardTopicIds() {
  return flashcardsData.keys.toList();
}

// Belirli bir topic icin flashcard sayisini dondurur
int getFlashcardCount(String topicId) {
  return flashcardsData[topicId]?.length ?? 0;
}

// Flashcard olan tum topic sayisini dondurur
int getTotalFlashcardTopics() {
  return flashcardsData.length;
}

// Toplam flashcard sayisini dondurur
int getTotalFlashcardCount() {
  return flashcardsData.values.fold(0, (sum, list) => sum + list.length);
}
