// Matematik - Rasyonel ve Ondalıklı Sayılar (MALA ANLATIR GİBİ & PROFESYONEL DETAY)
const String topicId = 'mat_rasyonel_001';

const List<Map<String, dynamic>> sections = [
  // -------------------------------------------------------------------------
  // BÖLÜM 1: KESİRLERİN DÜNYASI (TANIMLAR)
  // -------------------------------------------------------------------------
  {
    'title': '1. Rasyonel Sayı Nedir?',
    'content': [
      {
        'type': 'text',
        'text': 'Aklına gelen her türlü kesirli sayı. a/b formatı. Üstteki "Pay", alttaki "Payda", ortadaki "Kesir Çizgisi".'
      },
      {
        'type': 'highlighted',
        'text': 'ALTIN KURAL (TANIMSILIK):\n\nMatematikte PAYDA ASLA SIFIR OLAMAZ!\n\n• Sayı / 0 = TANIMSIZDIR. (Hesap makinesine yaz hata verir).\n• 0 / Sayı = 0\'DIR. (0/5 = 0).\n\n"İfadeyi tanımsız yapan x değeri" diye sorarsa, paydayı 0 yapan sayıya bakacaksın.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 2: DÖRT İŞLEM (PASTA BÖLMECE)
  // -------------------------------------------------------------------------
  {
    'title': '2. Dört İşlem Klavuzu',
    'content': [
      {
        'type': 'text',
        'text': 'Rasyonel sayılarda işlem yaparken kuralları karıştırma. Her işlemin raconu farklı.'
      },
      {
        'type': 'highlighted',
        'text': 'TOPLAMA VE ÇIKARMA (Payda Eşitleme Şart):\n\nPaydalar (altlar) aynı değilse işlem YAPAMAZSIN. Yasak.\n\n• Adım 1: Paydaları eşitle (Birbirinin altına yaz veya EKOK bul).\n• Adım 2: Sadece PAYLARI topla/çıkar. Payda olduğu gibi kalır.\n\nÖrnek: 1/2 + 1/3\n(3 ile genişlet) + (2 ile genişlet) -> 3/6 + 2/6 = 5/6.'
      },
      {
        'type': 'highlighted',
        'text': 'ÇARPMA (Dümdüz Git):\n\nEn kolayı budur. Payda eşitlemeye ÇALIŞMA.\n\n• Üstü üstle çarp, yaz.\n• Altı altla çarp, yaz.\n• (2/3) x (4/5) = 8/15.\n• Varsasadeleştirme yap (Çapraz veya altlı üstlü sadeleşebilir).'
      },
      {
        'type': 'highlighted',
        'text': 'BÖLME (Takla Attırma):\n\nBölme diye bir işlem yoktur aslında, ters çevrilmiş çarpma vardır.\n\n• Kural: BİRİNCİYİ AYNEN YAZ, İKİNCİYİ TERS ÇEVİRİP ÇARP.\n• Soru: (2/3) / (5/7)\n• Çözüm: (2/3) x (7/5) = 14/15.'
      },
      {
        'type': 'tip',
        'text': 'Merdiven İşlemler: En alttan veya en içten başla, yavaş yavaş ana kesir çizgisine gel. Acele etme.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 3: SIRALAMA (HANGİSİ BÜYÜK?)
  // -------------------------------------------------------------------------
  {
    'title': '3. Sıralama Taktikleri',
    'content': [
      {
        'type': 'text',
        'text': 'Payda eşitlemek zorsa (Örn: 13/17 mi büyük 15/19 mu?) şu taktikleri kullan:'
      },
      {
        'type': 'bulletList',
        'items': [
          'PAYLAR EŞİTSE: Paydası KÜÇÜK olan BÜYÜKTÜR. (Bir pastayı 2 kişi yerse mi çok düşer, 10 kişi yerse mi? 2 kişi tabii. 1/2 > 1/10).',
          'PAYDALAR EŞİTSE: Payı BÜYÜK olan BÜYÜKTÜR. (3 dilim pasta, 1 dilimden çoktur).',
          'YARIM/TAM TAKTİĞİ: Sayı yarıma (1/2) mı yakın, tama (1) mı yakın? Oradan kıyasla.'
        ]
      },
      {
        'type': 'warning',
        'text': 'NEGATİF SAYILARDA SIRALAMA:\n\nÖnce pozitifmiş gibi sırala, sonra işaretin YÖNÜNÜ DEĞİŞTİR. (Normalde 5 > 3 ama -5 < -3).'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 4: ONDALIKLI SAYILAR (VİRGÜLLÜLER)
  // -------------------------------------------------------------------------
  {
    'title': '4. Ondalıklı Sayılar',
    'content': [
      {
        'type': 'text',
        'text': 'Paydası 10, 100, 1000 olan kesirlerdir. 0,5 demek 5/10 demektir.'
      },
      {
        'type': 'highlighted',
        'text': 'VİRGÜLDEN KURTULMA OPERASYONU (Hayat Kurtarır):\n\nBölme işlemi yaparken virgüllerle boğuşma.\nHer iki sayıyı da (pay ve payda) virgülden kurtulana kadar SAĞA KAYDIR (10 ile çarp).\n\nÖrnek: 2,4 / 0,08\n1. Adım: Üstü 1 kaydır (24), Altı 1 kaydır (0,8). Yetmedi.\n2. Adım: Üstü bir daha kaydır (Boşluk var, 0 koy -> 240). Altı bir daha kaydır (8).\n3. İşlem: 240 / 8 = 30. Tertemiz.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 5: DEVİRLİ SAYILAR (ŞAPKALILAR)
  // -------------------------------------------------------------------------
  {
    'title': '5. Devirli Ondalıklı Sayılar',
    'content': [
      {
        'type': 'text',
        'text': 'Virgülden sonrası sonsuza kadar tekrar eden sayılardır. Tepesinde çizgi olur.'
      },
      {
        'type': 'highlighted',
        'text': 'FORMÜL (Ezberle):\n\n(Sayının Tamamı - Devretmeyen Kısım)\n----------------------------------------\n(Virgülden sonrası için: Devreden kadar 9, Devretmeyen kadar 0)\n\nÖrnek: 1,23 (3\'ün üstü çizili)\n• Tüm Sayı: 123\n• Devretmeyen: 12\n• Pay: 123 - 12 = 111\n• Payda: 3 devrediyor (bir tane 9), 2 devretmiyor (bir tane 0) -> 90.\n• Sonuç: 111/90.'
      },
      {
        'type': 'tip',
        'text': 'Özel Durum: Eğer devreden sayı 9 ise (1,999...), bir önceki rakamı 1 artır, 9\'u sil. (1,9 devrediyor = 2). (2,9 devrediyor = 3).'
      }
    ]
  }
];
