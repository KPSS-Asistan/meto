// Matematik - Problemler (FİNAL DOĞRU VERSİYON)
const String topicId = 'mat_prob_001';

const List<Map<String, dynamic>> sections = [
  {
    'title': '1. Oran ve Orantı',
    'content': [
      {
        'type': 'text',
        'text': 'Problemlerin temelidir. a/b = c/d = k. (k: Orantı Sabiti, en iyi dostun).'
      },
      {
        'type': 'highlighted',
        'text': 'ORANTI ÇEŞİTLERİ:\n\n• DOĞRU ORANTI (Bölüm): Biri artarken diğeri artar. (Benzin - Yol). (y/x = k) -> ÇAPRAZ ÇARPILIR.\n\n• TERS ORANTI (Çarpım): Biri artarken diğeri azalır. (İşçi Sayısı - Süre). (y.x = k) -> DÜZ (YAN YANA) ÇARPILIR.'
      },
      {
        'type': 'tip',
        'text': 'Taktik: a/3 = b/4 = c/5 diyorsa; a=3k, b=4k, c=5k vererek tek bilinmeyene düşür.'
      }
    ]
  },
  {
    'title': '2. Kesir ve Sayı Problemleri',
    'content': [
      {
        'type': 'text',
        'text': 'Türkçeyi matematiğe çevir. "Hangi sayının 3 fazlası" -> x+3.'
      },
      {
        'type': 'highlighted',
        'text': '12x KURALI (Hayat Kurtarır):\n\nSoruda "Parasının 1/3\'ü, sonra kalanın 1/4\'ü" gibi kesirler varsa sayıya "x" deme!\nPaydaları çarp (3x4=12), paraya "12x" de.\n\n• 12x\'in 1/3\'ü = 4x gitti. Kaldı 8x.\n• Kalanın (8x) 1/4\'ü = 2x gitti.\nVirgülle uğraşmazsın.'
      }
    ]
  },
  {
    'title': '3. Yaş Problemleri',
    'content': [
      {
        'type': 'text',
        'text': 'Mutlaka TABLO ÇİZ. Sütuna isimleri, satıra yılları yaz.'
      },
      {
        'type': 'highlighted',
        'text': 'KURALLAR:\n\n• Yaş Farkı ASLA Değişmez.\n• Herkes aynı miktarda büyür.\n• n kişinin yaşları toplamı, t yıl sonra "n.t" kadar artar.'
      }
    ]
  },
  {
    'title': '4. Hareket Problemleri',
    'content': [
      {
        'type': 'text',
        'text': 'Yol = Hız x Zaman (x = V.t).'
      },
      {
        'type': 'highlighted',
        'text': 'FORMÜLLER:\n\n• ZIT YÖN (Karşılaşma): Hızları TOPLA. t = Yol / (V1 + V2).\n\n• AYNI YÖN (Yakalama): Hızları ÇIKAR. t = Yol / (V1 - V2).\n\n• ORTALAMA HIZ: (Toplam Yol) / (Toplam Zaman). (Hızları toplayıp 2\'ye bölme sakın!).'
      }
    ]
  },
  {
    'title': '5. Yüzde, Kar-Zarar',
    'content': [
      {
        'type': 'text',
        'text': 'Maliyet üzerinden hesap yapılır.'
      },
      {
        'type': 'highlighted',
        'text': '100x KURALI:\n\nMaliyete her zaman 100x de.\n\n• %20 Kar -> 120x\n• %30 Zarar -> 70x (100-30)\n• %10 İndirim -> 90x\n• %18 KDV -> 118x\n\nFormülle uğraşma. 100 üzerinden ekle çıkar.'
      }
    ]
  },
  {
    'title': '6. İşçi Problemleri',
    'content': [
      {
        'type': 'text',
        'text': 'Birim zamanda yapılan iş üzerinden gidilir. (1/t mantığı).'
      },
      {
        'type': 'tip',
        'text': 'PRATİK (İki Kişi): BERABER SÜRESİ = (ÇARPIMLARI) / (TOPLAMLARI).\nAli 10, Veli 15 günde yapıyorsa:\n(10.15) / (10+15) = 150/25 = 6 gün.'
      }
    ]
  }
];
