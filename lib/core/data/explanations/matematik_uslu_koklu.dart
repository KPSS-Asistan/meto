// Matematik - Üslü ve Köklü Sayılar (MALA ANLATIR GİBİ & PROFESYONEL DETAY)
const String topicId = 'mat_uslu_001';

const List<Map<String, dynamic>> sections = [
  // -------------------------------------------------------------------------
  // BÖLÜM 1: ÜSLÜ SAYILAR (KUVVETLİ SAYILAR)
  // -------------------------------------------------------------------------
  {
    'title': '1. Üslü Sayı Nedir?',
    'content': [
      {
        'type': 'text',
        'text': 'Bir sayının tepesindeki o küçük sayı, "Onu kaç kere yan yana koyup çarpacağını" söyler. \n2³ = 2.2.2 = 8 demektir. (Sakın 2x3=6 deme, komik duruma düşersin).'
      },
      {
        'type': 'highlighted',
        'text': 'TEMEL KURALLAR (Oyunun Hileleri):\n\n• SIFIRINCI KUVVET: Her sayının 0. kuvveti 1\'dir. (5⁰ = 1, 1000⁰ = 1). (Sıfır hariç, 0⁰ belirsizdir).\n\n• BİRİNCİ KUVVET: Kendisidir. (5¹ = 5).\n\n• BİRİN KUVVETLERİ: 1\'in üzerinde ne yazarsa yazsın sonuç 1\'dir. (1¹⁰⁰ = 1).\n\n• NEGATİF KUVVET (TAKLA ATTIRMA): Üstteki sayı eksiyse, sayıya takla attır demektir. İşareti değiştirmez!\n  2⁻¹ = 1/2\n  (2/3)⁻² = (3/2)² = 9/4 (Önce ters çevir, sonra karesini al).'
      },
      {
        'type': 'warning',
        'text': 'İŞARET TUZAĞI (Parantez Önemli):\n\n• (-2)² = (-2).(-2) = +4 (Parantez var, eksi de çarpılır, çift kuvvet yutar).\n• -2² = -4 (Eksi dışarıda, sadece 2\'nin karesini alırsın).\n• (-2)³ = -8 (Tek kuvvet eksiyi yutamaz, kusar).'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 2: ÜSLÜ SAYILARDA DÖRT İŞLEM
  // -------------------------------------------------------------------------
  {
    'title': '2. Dört İşlem Klavuzu',
    'content': [
      {
        'type': 'text',
        'text': 'Burada kurallar kesindir. Kafana göre işlem yapamazsın.'
      },
      {
        'type': 'highlighted',
        'text': 'ÇARPMA VE BÖLME:\n\n• ÇARPMA (Tabanlar Aynı): Üsleri TOPLA. (2³ . 2⁵ = 2⁸).\n• ÇARPMA (Üsler Aynı): Tabanları ÇARP. (2³ . 5³ = 10³).\n\n• BÖLME (Tabanlar Aynı): Üsleri ÇIKAR. (2⁸ / 2⁵ = 2³).\n• BÖLME (Üsler Aynı): Tabanları BÖL. (10³ / 2³ = 5³).\n\n• ÜSSÜN ÜSSÜ: Üsler ÇARPILIR. (2³)⁴ = 2¹². (Parantez içindeki ve dışındaki çarpılır).'
      },
      {
        'type': 'tip',
        'text': 'TOPLAMA - ÇIKARMA:\nKural yok! Ancak "Ortak Parantez"e alarak yapabilirsin. Elma hesabı yap.\n3 tane 5 üzeri x + 2 tane 5 üzeri x = 5 tane 5 üzeri x.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 3: KÖKLÜ SAYILAR (HAPİSHANE)
  // -------------------------------------------------------------------------
  {
    'title': '3. Köklü Sayı Nedir?',
    'content': [
      {
        'type': 'text',
        'text': 'Üslü sayının tersidir. "Hangi sayının karesi bu eder?" sorusunun cevabıdır. Kök işareti (√) bir hapishanedir.'
      },
      {
        'type': 'highlighted',
        'text': 'KÖK DIŞINA ÇIKARMA (Tahliye):\n\nSayı içeride tam kare çarpanlarına ayrılır. Karesi olan dışarı çıkar, olmayan içeride kalır.\n\nÖrnek: √12\n• 12 = 4 x 3 demektir.\n• 4, 2\'nin karesidir. Dışarı "2" diye çıkar.\n• 3\'ün karesi yoktur. İçeride hapis kalır.\n• Sonuç: 2√3.'
      },
      {
        'type': 'highlighted',
        'text': 'DÖRT İŞLEM:\n\n• TOPLAMA/ÇIKARMA: Sadece kök içleri AYNI olanlar toplanır. (2√3 + 5√3 = 7√3). (Elma ile Armut toplanmaz, √2 + √3 öylece kalır).\n\n• ÇARPMA: Dümdüz çarpılır. (√2 . √3 = √6). Dışarıdakiler kendi arasında, içeridekiler kendi arasında çarpılır.\n\n• BÖLME: Dümdüz bölünür. (√10 / √2 = √5).'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 4: EŞLENİK VE SONSUZ KÖKLER
  // -------------------------------------------------------------------------
  {
    'title': '4. Özel Durumlar',
    'content': [
      {
        'type': 'text',
        'text': 'Paydada kök sevilmez. Onu kurtarmak gerekir (Eşlenik).'
      },
      {
        'type': 'highlighted',
        'text': 'PAYDAYI KURTARMA:\n\nPaydada √2 varsa, kesri √2 ile genişletirsin. Çünkü √2.√2 = √4 = 2 olur. Kök kalkar.\n\nEğer (√3 - 1) varsa, işaretin tersiyle (√3 + 1) ile çarparsın (İki Kare Farkı oluşur).'
      },
      {
        'type': 'highlighted',
        'text': 'SONSUZ KÖK TAKTİĞİ (Sınavda Çıkar):\n\nİç içe sonsuza giden kökler: √(20 + √(20 + ...))\n\n• Sayıyı ardışık çarpanlarına ayır: 20 = 4 x 5.\n• Arada ARTI (+) varsa: BÜYÜK olanı al (Cevap 5).\n• Arada EKSİ (-) varsa: KÜÇÜK olanı al (Cevap 4).\n• Çarpma varsa: Dereceyi 1 azalt.\n• Bölme varsa: Dereceyi 1 artır.'
      }
    ]
  }
];
