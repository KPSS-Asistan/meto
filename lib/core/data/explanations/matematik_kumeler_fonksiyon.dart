// Matematik - Kümeler ve Fonksiyonlar (MALA ANLATIR GİBİ & PROFESYONEL DETAY)
const String topicId = 'mat_kume_001';

const List<Map<String, dynamic>> sections = [
  // -------------------------------------------------------------------------
  // BÖLÜM 1: KÜMELER (SEPET MANTIĞI)
  // -------------------------------------------------------------------------
  {
    'title': '1. Kümeler Nedir?',
    'content': [
      {
        'type': 'text',
        'text': 'Aynı türden şeyleri bir torbaya doldurursan küme olur. "Sınıftaki Gözlüklüler", "A ile başlayan iller" birer kümedir.'
      },
      {
        'type': 'bulletList',
        'items': [
          'Eleman Sayısı (s(A)): Kümede kaç kişi var?',
          'Alt Küme: Kümenin içinden seçtiğin küçük gruplar. Formülü 2 üzeri n. (3 elemanlıysa 2³=8 tane alt kümesi vardır).',
          'Öz Alt Küme: Alt kümelerden kendisini çıkarıyorsun. 2 üzeri n - 1.',
          'Boş Küme: İçinde eleman yok. {} veya ∅. (Dikkat: {∅} boş küme değildir, içinde bir sembol olan 1 elemanlı kümedir!)'
        ]
      },
      {
        'type': 'highlighted',
        'text': 'KÜME İŞLEMLERİ:\n\n• BİRLEŞİM (U) - "VEYA": Herkesi topla gel. (Futbol VEYA Basketbol oynayanlar). Hepsini alırsın.\n\n• KESİŞİM (∩) - "VE": Ortak olanlar. (Hem Futbol VE hem Basketbol oynayanlar).\n\n• FARK (A - B) - "YALNIZ": A\'da olup B\'de olmayanlar. (Sadece Futbol oynayanlar, Basketbolla işi olmayanlar).'
      },
      {
        'type': 'highlighted',
        'text': 'BİRLEŞİM FORMÜLÜ (Hayat Kurtarır):\n\ns(A U B) = s(A) + s(B) - s(A ∩ B)\n\n"A grubunu ve B grubunu toplarsan, ortadaki ortak elemanları (kesişimi) iki kere saymış olursun. O yüzden bir kere ÇIKARMAN lazım."'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 2: FONKSİYONLAR (KIYMA MAKİNESİ)
  // -------------------------------------------------------------------------
  {
    'title': '2. Fonksiyon Nedir?',
    'content': [
      {
        'type': 'text',
        'text': 'Fonksiyon bir makinedir. Bir taraftan sayı atarsın (girdi-x), makine onu işler, diğer taraftan ürün çıkarır (çıktı-y).\n\nÖrnek: f(x) = 2x + 5 makinesi.\nMakineye 3 atarsan (x=3);\n2.3 + 5 = 11 çıkarır. (f(3) = 11).'
      },
      {
        'type': 'highlighted',
        'text': 'BİLEŞKE FONKSİYON (fog):\n\nİki makineyi arka arkaya bağlamaktır.\n\n(fog)(x) demek:\n1. x\'i önce SAĞDAKİ (g) makinesine at.\n2. Oradan çıkanı al, SOLDAKİ (f) makinesine at.\n\nKural: İŞLEM SAĞDAN SOLA DOĞRU YAPILIR!'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 3: TERS FONKSİYON (GERİ SARMA)
  // -------------------------------------------------------------------------
  {
    'title': '3. Ters Fonksiyon',
    'content': [
      {
        'type': 'text',
        'text': 'Makineyi tersine çalıştırmaktır. Çıktıyı verip girdiyi bulmaktır. f⁻¹(x) ile gösterilir.'
      },
      {
        'type': 'highlighted',
        'text': 'PRATİK TERS ALMA:\n\n• f(x) = ax + b ise;\n  Tersi: (x - b) / a.\n  (Çarpmaysa böl, toplamaysa çıkar).\n\n• Örnek: f(x) = 3x + 4\n  Tersi: (x - 4) / 3.'
      },
      {
        'type': 'tip',
        'text': 'Grafik Sorusu: Grafik üzerinde bir nokta (a,b) ise f(a)=b dir. Tersi soruluyorsa f⁻¹(b)=a dır. (Y ekseninden X eksenine git).'
      }
    ]
  }
];
