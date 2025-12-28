// Matematik - Eşitsizlikler ve Mutlak Değer (MALA ANLATIR GİBİ & PROFESYONEL DETAY)
const String topicId = 'mat_esitsizlik_001';

const List<Map<String, dynamic>> sections = [
  // -------------------------------------------------------------------------
  // BÖLÜM 1: BASİT EŞİTSİZLİKLER (TERAZİ MANTIĞI)
  // -------------------------------------------------------------------------
  {
    'title': '1. Basit Eşitsizlikler',
    'content': [
      {
        'type': 'text',
        'text': 'Küçüktür (<), Büyüktür (>), Küçük Eşit (<=), Büyük Eşit (>=). Terazi kefeleri gibi düşün, denge bozuk, bir taraf ağır basıyor.'
      },
      {
        'type': 'highlighted',
        'text': 'ALTIN KURALLAR (Hata Yapma!):\n\n1. EKLEME / ÇIKARMA SERBEST:\n   x < 5 ise her iki tarafa sayı ekleyip çıkarabilirsin. Yön değişmez.\n   (x+2 < 7) veya (x-5 < 0).\n\n2. POZİTİF ÇARPMA / BÖLME SERBEST:\n   x < 5 ise her iki tarafı 2 ile çarp. 2x < 10. Yön değişmez.\n\n3. NEGATİF ÇARPMA / BÖLME (KIRMIZI ALARM 🚨):\n   Eşitsizliğin her iki tarafını EKSİ (-) bir sayıyla çarpar veya bölersen; İŞARET TERS DÖNER (Yön değiştirir)! \n   • -x < 5 (Her iki tarafı -1 ile çarp)\n   • x > -5 (Bak işaret döndü!).\n   Bunu unutursan soru gider.'
      },
      {
        'type': 'tip',
        'text': 'Aralık Toplama:\n2 < x < 5\n3 < y < 6\nx+y\'yi soruyorsa ALT ALTA TOPLA: 5 < x+y < 11.\n\nUYARI: Çıkarma (x-y) soruyorsa alt alta ÇIKARMA YAPILMAZ! İkinciyi -1 ile çarpıp (yön değiştirip) toplaman lazım.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 2: MUTLAK DEĞER (MESAFE ÖLÇER)
  // -------------------------------------------------------------------------
  {
    'title': '2. Mutlak Değer Nedir?',
    'content': [
      {
        'type': 'text',
        'text': 'Sayı doğrusunda bir sayının 0\'a olan uzaklığıdır. Uzaklık hiç negatif olur mu? "Evim okula -500 metre" diyebilir misin? Diyemezsin. O yüzden Mutlak Değer hep POZİTİF çıkar.'
      },
      {
        'type': 'bulletList',
        'items': [
          '|5| = 5',
          '|-5| = 5',
          '|0| = 0'
        ]
      },
      {
        'type': 'highlighted',
        'text': 'İÇERİSİ KURALI (Hayat Kurtarır):\n\nMutlak değerden sayı çıkarmak için kendine şunu sor: "İÇERİSİ POZİTİF Mİ NEGATİF Mİ?"\n\n• İÇERİSİ POZİTİFSE (+): Olduğu gibi, aynen dışarı çıkar. (|5| -> 5).\n\n• İÇERİSİ NEGATİFSE (-): Önüne eksi (-) alarak çıkar. (Amaç eksiyle eksiyi çarpıp sonucu artı yapmaktır).\n  |-5| -> -(-5) = +5.\n  |x| ve x < 0 ise -> -x diye çıkar.'
      },
      {
        'type': 'example',
        'text': 'Soru: x < 0 < y ise |x - y| + |x| nedir?\nÇözüm: \n1. |x - y|: Küçük sayıdan büyük sayı çıkarsa sonuç NEGATİF olur. İçerisi (-). O zaman eksiyle çarp çık: -(x-y) = -x + y.\n2. |x|: x sıfırdan küçük, yani Negatif. Eksiyle çarp çık: -x.\n3. Topla: (-x + y) + (-x) = y - 2x.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 3: MUTLAK DEĞERLİ DENKLEMLER
  // -------------------------------------------------------------------------
  {
    'title': '3. Mutlak Değerli Denklemler',
    'content': [
      {
        'type': 'text',
        'text': 'İki ihtimal vardır. Ya artılısına eşittir, ya eksilesine.'
      },
      {
        'type': 'highlighted',
        'text': 'DENKLEM ÇÖZÜMÜ:\n\n|x| = 5 ise;\n• x = 5 olabilir.\n• x = -5 olabilir.\n(Çözüm kümesi: {-5, 5}).\n\n|x| = -3 ise;\n• ÇÖZÜM KÜMESİ BOŞ KÜMEDİR! Mutlak değer eksiye eşit olamaz.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 4: MUTLAK DEĞERLİ EŞİTSİZLİKLER (KANATLANMA VE SIKIŞMA)
  // -------------------------------------------------------------------------
  {
    'title': '4. Eşitsizlik Çözümleri',
    'content': [
      {
        'type': 'text',
        'text': 'Burada iki kural var, şekline göre değişir.'
      },
      {
        'type': 'highlighted',
        'text': '1. KÜÇÜKTÜR (<) DURUMU (Sandviç/Sıkıştırma):\n\n|x| < 5 ise;\nSayı -5 ile 5 arasına sıkışır.\n-5 < x < 5.\n\n2. BÜYÜKTÜR (>) DURUMU (Kanatlanma):\n\n|x| > 5 ise;\nSayı ya 5\'ten büyüktür, ya da -5\'ten küçüktür (Uçlara kaçar).\nx > 5  VEYA  x < -5.'
      },
      {
        'type': 'tip',
        'text': 'Kritik Nokta: Mutlak değerin içini 0 yapan değerdir. En küçük değer sorulduğunda kritik noktayı yerine koy.'
      }
    ]
  }
];
