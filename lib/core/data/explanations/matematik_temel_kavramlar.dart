// Matematik - Temel Kavramlar (MALA ANLATIR GİBİ & PROFESYONEL DETAY)
const String topicId = 'mat_temel_001';

const List<Map<String, dynamic>> sections = [
  // -------------------------------------------------------------------------
  // BÖLÜM 1: SAYILARIN ALFABESİ (KİM KİMDİR?)
  // -------------------------------------------------------------------------
  {
    'title': '1. Sayıların Kimliği (Karakter Analizi)',
    'content': [
      {
        'type': 'text',
        'text': 'Bak güzel kardeşim, matematiğin dili sayılardır. Sorunun başında siyahla yazılan "x bir doğal sayıdır" lafını okumazsan, soruyu çözsen de yanlış şıkkı işaretlersin. Önce şu elemanları tanı:'
      },
      {
        'type': 'highlighted',
        'text': '1. RAKAM (Telefon Tuşları):\nTelefonundaki tuşlara bak: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9.\n\n• Toplam 10 tanedir.\n• En küçük rakam 0, en büyük 9\'dur.\n• UYARI: "10" bir rakam değildir, sayıdır.\n\n2. DOĞAL SAYILAR (N - Naturel):\nDoğada görebildiğin şeyler. "0" tane ağacım var, "5" tane elmam var.\n• {0, 1, 2, 3... sonsuza gider}.\n• Negatif (-) elman olur mu? Olmaz. O yüzden eksi yok.\n\n3. SAYMA SAYILARI (N+):\nMarkette saymaya kaçtan başlarsın? 1\'den. O yüzden 0 yok.\n• {1, 2, 3...}.\n\n4. TAM SAYILAR (Z):\nİşin içine bakkal defteri (borçlar) girdi.\n• Eksi de olur, artı da.\n• {..., -3, -2, -1, 0, 1, 2, 3...}.\n• "Z-" negatifler, "Z+" pozitifler. 0 NÖTRDÜR (İşaretsiz).\n\n5. REEL (GERÇEL) SAYILAR (R):\nHer şey. Aklına gelebilecek tüm sayılar. Sayı doğrusunun tamamı.'
      },
      {
        'type': 'warning',
        'text': 'HAYATİ TUZAK: \nSoruda "x, y birer RAKAM" diyorsa değer ver (0, 1...9).\nSoruda "x, y REEL SAYI" diyorsa SAKIN DEĞER VERME! Eşitsizlik çözümü yapman lazım (Aralık hesabı). Bu ayrımı yapamazsan soru gider.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 2: TEKLİK VE ÇİFTLİK (OMLET KURALI)
  // -------------------------------------------------------------------------
  {
    'title': '2. Tek ve Çift Sayılar',
    'content': [
      {
        'type': 'text',
        'text': 'Çok basit. 2\'ye tam bölünenler ÇİFT (Ç), bölünemeyenler TEK (T). Sonu 0,2,4,6,8 ise çifttir.'
      },
      {
        'type': 'highlighted',
        'text': 'KURALLAR (Ezberleme, Değer Ver Dene):\n\n• Toplama/Çıkarma:\n  1 + 1 = 2 (T + T = Ç)\n  2 + 2 = 4 (Ç + Ç = Ç)\n  1 + 2 = 3 (T + Ç = T)\n  (Yani: Aynılar Çift, Farklılar Tektir).\n\n• ÇARPMA (ÇÜRÜK YUMURTA KURALI):\n  Bir sepette 100 yumurta olsun, biri çürükse (Çiftse) tüm omlet çürük olur (Çift olur).\n  Çarpma işleminde BİR TANE bile çift sayı varsa sonuç BANKO ÇİFTTİR.\n  Sonucun TEK olması için alayının TEK olması gerekir.\n\n• ÜS ALMA (TEMİZLİK):\n  Üs (kuvvet) pozitif tam sayı ise, SİL GİTSİN! Hiçbir şeyi değiştirmez.\n  (2023 üzeri 2024) -> Üssü sil, 2023 Tek mi? O zaman sonuç Tek.'
      },
      {
        'type': 'example',
        'text': 'Soru: a, b tam sayı ve 3.a + 1 = 2.b ise a nedir?\nÇözüm: \n1. Eşitliğin sağına bak: 2.b kesinlikle ÇİFT (Çünkü 2 ile çarpılmış).\n2. Sol taraf da Çift olmalı.\n3. 3.a + 1 = Çift.\n4. "1" Tek sayıdır. Neyle Teki toplarsan Çift eder? Teki. (T+T=Ç).\n5. Demek ki 3.a = Tek.\n6. Çarpım tekse hepsi tektir. O zaman "a" kesinlikle TEKTİR.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 3: POZİTİF VE NEGATİF SAYILAR
  // -------------------------------------------------------------------------
  {
    'title': '3. İşaret Dili (+ ve -)',
    'content': [
      {
        'type': 'text',
        'text': 'Dostumun dostu dostumdur (+ . + = +). Düşmanımın düşmanı dostumdur (- . - = +). Dostumun düşmanı düşmanımdır (+ . - = -).'
      },
      {
        'type': 'highlighted',
        'text': 'ÜS ALIRKEN DİKKAT (Parantez Tuzağı):\n\n• (-2)² = (-2) x (-2) = +4 (Parantez var, eksi de çarpılır).\n• -2² = - (2 x 2) = -4 (Parantez yok, eksi dışarıda kalır, sadece 2\'nin karesini alırsın).\n\nKural: Negatif sayıların ÇİFT kuvvetleri pozitiftir (Parantez varsa). TEK kuvvetleri hep negatiftir.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 4: ASAL SAYILAR (YALNIZ KOVBOYLAR)
  // -------------------------------------------------------------------------
  {
    'title': '4. Asal Sayılar',
    'content': [
      {
        'type': 'text',
        'text': 'Sadece 1\'e ve kendisine bölünebilen, burnu havada sayılardır. Başka kimseye yüz vermezler.'
      },
      {
        'type': 'bulletList',
        'items': [
          'En küçük asal sayı 2\'dir. (1 Asal değildir!).',
          'Çift olan tek asal sayı 2\'dir. Başka çift asal yok (Diğerleri 2\'ye bölünür çünkü).',
          'Liste: 2, 3, 5, 7, 11, 13, 17, 19, 23...'
        ]
      },
      {
        'type': 'highlighted',
        'text': 'ARALARINDA ASAL (Küs Sayılar):\n\nİki sayının 1\'den başka ortak böleni yoksa ARALARINDA ASALDIR.\n\n• Sayıların asal olmasına gerek yok! \n• Örnek: 8 ve 9.\n  8 (2\'ye bölünür), 9 (3\'e bölünür). Ortak bölenleri var mı? Yok. O zaman aralarında asallar.\n• Kural: 1 ile her sayı aralarında asaldır.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 5: BASAMAK ANALİZİ (PARA BOZMA)
  // -------------------------------------------------------------------------
  {
    'title': '5. Basamak Çözümleme',
    'content': [
      {
        'type': 'text',
        'text': 'Bakkalda para bozar gibi sayıları ayıracağız.'
      },
      {
        'type': 'bulletList',
        'items': [
          'AB sayısı = 10 tane A + 1 tane B (10A + B)',
          'ABC sayısı = 100A + 10B + C'
        ]
      },
      {
        'type': 'highlighted',
        'text': 'PRATİK FORMÜLLER (Hız Kazandırır):\n\n• AB + BA = 11(A + B)\n  (Örn: 11(A+B) = 66 ise A+B=6)\n\n• AB - BA = 9(A - B)\n  (Örn: 9(A-B) = 27 ise A-B=3)\n\n• AA = 11A'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 6: FAKTÖRİYEL (GERİ SAYIM)
  // -------------------------------------------------------------------------
  {
    'title': '6. Faktöriyel (!)',
    'content': [
      {
        'type': 'text',
        'text': 'Sayının yanındaki ünlem işaretidir. O sayıdan başla, 1\'e kadar geriye doğru çarp.'
      },
      {
        'type': 'bulletList',
        'items': [
          '3! = 3.2.1 = 6',
          '4! = 4.3.2.1 = 24',
          '5! = 120',
          '0! = 1 (Kabul et geç, sorgulama).'
        ]
      },
      {
        'type': 'tip',
        'text': 'Sadeleştirme Taktiği: 10! / 8! işlemini yapmak için amele gibi çarpma. \nBüyüğü küçüğe benzet: 10! = 10.9.8! diye aç.\n(10.9.8!) / 8! -> 8!\'ler gider. Cevap 90. Bitti.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 7: BÖLÜNEBİLME (ŞİFRELER)
  // -------------------------------------------------------------------------
  {
    'title': '7. Bölünebilme Kuralları',
    'content': [
      {
        'type': 'text',
        'text': 'Bölme yapmadan kalanı bulma sanatıdır.'
      },
      {
        'type': 'highlighted',
        'text': 'KURALLAR:\n\n• 2 ile: Son rakam Çift olacak.\n• 3 ile: Rakamları topla, 3\'ün katı olacak.\n• 4 ile: Son İKİ basamağa bak (00 veya 4\'ün katı).\n• 5 ile: Son rakam 0 veya 5.\n• 9 ile: Rakamları topla, 9\'un katı olacak.\n• 10 ile: Son rakam 0 olacak. (Kalan direkt birler basamağıdır).\n• 11 ile: Sağdan sola (+ - + -) işaretle. Topla.'
      },
      {
        'type': 'warning',
        'text': 'BÜYÜK SAYILAR (Bileşik Kurallar):\n36 ile bölünme kuralı yok. \n36\'yı aralarında asal çarpanlarına ayır: 4 ve 9.\nSayı hem 4\'e hem 9\'a tam bölünüyorsa 36\'ya da tam bölünür.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 8: EBOB ve EKOK (BÖL VE YÖNET)
  // -------------------------------------------------------------------------
  {
    'title': '8. EBOB ve EKOK Mantığı',
    'content': [
      {
        'type': 'text',
        'text': 'Ne zaman hangisini kullanacaksın?'
      },
      {
        'type': 'highlighted',
        'text': 'HANGİSİ?\n\n• EBOB (En Büyük Ortak BÖLEN): BÜYÜK parçaları KÜÇÜK parçalara ayırıyorsan. (Tarlayı bölme, çuvalları poşetleme, ağaç dikme). "Parçalama" varsa EBOB.\n\n• EKOK (En Küçük Ortak KAT): KÜÇÜK parçaları birleştirip BÜYÜK bir şey yapıyorsan. (Fayanslardan duvar örme, zillerin beraber çalması). "Birleştirme" varsa EKOK.'
      },
      {
        'type': 'tip',
        'text': 'Formül: İki sayı (A, B) için;\nA x B = EBOB x EKOK.\nBunu bil, çoğu soruyu çözersin.'
      }
    ]
  }
];
