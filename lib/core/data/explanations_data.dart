// Hardcoded konu anlatımları - Modüler yapı
// Her konu ayrı bir dosyada saklanır ve buradan import edilir.

// TARİH
import 'explanations/islamiyet_oncesi_turk_tarihi.dart' as islamiyet_oncesi;
import 'explanations/ilk_musluman_turk_devletleri.dart' as ilk_musluman;
import 'explanations/osmanli_devleti_tarihi.dart' as osmanli;
import 'explanations/kurtulus_savasi_donemi.dart' as kurtulus;
import 'explanations/ataturk_ilke_ve_inkilaplari.dart' as ataturk;
import 'explanations/cumhuriyet_donemi.dart' as cumhuriyet;
import 'explanations/cagdas_turk_ve_dunya_tarihi.dart' as cagdas;

// TÜRKÇE
import 'explanations/ses_bilgisi.dart' as ses;
import 'explanations/yapi_bilgisi.dart' as yapi;
import 'explanations/sozcuk_turleri.dart' as sozcuk_tur;
import 'explanations/sozcukte_anlam.dart' as sozcuk_anlam;
import 'explanations/cumlede_anlam.dart' as cumle_anlam;
import 'explanations/paragrafta_anlam.dart' as paragraf;
import 'explanations/anlatim_bozukluklari.dart' as anlatim;
import 'explanations/yazim_kurallari_ve_noktalama.dart' as yazim;
import 'explanations/sozel_mantik_ve_akil_yurutme.dart' as sozel;

// COĞRAFYA
import 'explanations/turkiyenin_cografi_konumu.dart' as konum;
import 'explanations/turkiyenin_fiziki_ozellikleri.dart' as fiziki;
import 'explanations/turkiyenin_iklimi_ve_bitki_ortusu.dart' as iklim;
import 'explanations/beseri_cografya.dart' as beseri;
import 'explanations/ekonomik_cografya.dart' as ekonomik;
import 'explanations/turkiyenin_cografi_bolgeleri.dart' as bolgeler;

// VATANDAŞLIK
import 'explanations/hukuka_giris.dart' as hukuk;
import 'explanations/anayasa_hukuku.dart' as anayasa;
import 'explanations/anayasa_1982_temel_ilkeleri.dart' as anayasa82;
import 'explanations/devlet_organlari.dart' as devlet;
import 'explanations/idari_yapi.dart' as idari;
import 'explanations/guncel_olaylar.dart' as guncel;

class ExplanationsData {
  static final Map<String, List<Map<String, dynamic>>> explanations = {
    // TARİH (7 konu)
    islamiyet_oncesi.topicId: List<Map<String, dynamic>>.from(islamiyet_oncesi.sections),
    ilk_musluman.topicId: List<Map<String, dynamic>>.from(ilk_musluman.sections),
    osmanli.topicId: List<Map<String, dynamic>>.from(osmanli.sections),
    kurtulus.topicId: List<Map<String, dynamic>>.from(kurtulus.sections),
    ataturk.topicId: List<Map<String, dynamic>>.from(ataturk.sections),
    cumhuriyet.topicId: List<Map<String, dynamic>>.from(cumhuriyet.sections),
    cagdas.topicId: List<Map<String, dynamic>>.from(cagdas.sections),

    // TÜRKÇE (9 konu)
    ses.topicId: List<Map<String, dynamic>>.from(ses.sections),
    yapi.topicId: List<Map<String, dynamic>>.from(yapi.sections),
    sozcuk_tur.topicId: List<Map<String, dynamic>>.from(sozcuk_tur.sections),
    sozcuk_anlam.topicId: List<Map<String, dynamic>>.from(sozcuk_anlam.sections),
    cumle_anlam.topicId: List<Map<String, dynamic>>.from(cumle_anlam.sections),
    paragraf.topicId: List<Map<String, dynamic>>.from(paragraf.sections),
    anlatim.topicId: List<Map<String, dynamic>>.from(anlatim.sections),
    yazim.topicId: List<Map<String, dynamic>>.from(yazim.sections),
    sozel.topicId: List<Map<String, dynamic>>.from(sozel.sections),

    // COĞRAFYA (6 konu)
    konum.topicId: List<Map<String, dynamic>>.from(konum.sections),
    fiziki.topicId: List<Map<String, dynamic>>.from(fiziki.sections),
    iklim.topicId: List<Map<String, dynamic>>.from(iklim.sections),
    beseri.topicId: List<Map<String, dynamic>>.from(beseri.sections),
    ekonomik.topicId: List<Map<String, dynamic>>.from(ekonomik.sections),
    bolgeler.topicId: List<Map<String, dynamic>>.from(bolgeler.sections),

    // VATANDAŞLIK (6 konu)
    hukuk.topicId: List<Map<String, dynamic>>.from(hukuk.sections),
    anayasa.topicId: List<Map<String, dynamic>>.from(anayasa.sections),
    anayasa82.topicId: List<Map<String, dynamic>>.from(anayasa82.sections),
    devlet.topicId: List<Map<String, dynamic>>.from(devlet.sections),
    idari.topicId: List<Map<String, dynamic>>.from(idari.sections),
    guncel.topicId: List<Map<String, dynamic>>.from(guncel.sections),
  };

  // Topic ID'ye göre konu anlatımı getir
  static List<Map<String, dynamic>>? getExplanation(String topicId) {
    return explanations[topicId];
  }

  // Tüm topic ID'lerini getir
  static List<String> getAllTopicIds() {
    return explanations.keys.toList();
  }

  // Belirli bir topic için konu anlatımı var mı kontrol et
  static bool hasExplanation(String topicId) {
    return explanations.containsKey(topicId);
  }
}
