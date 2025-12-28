// Matematik - Sayısal Mantık (MALA ANLATIR GİBİ & PROFESYONEL DETAY)
const String topicId = 'mat_mantik_001';

const List<Map<String, dynamic>> sections = [
  // -------------------------------------------------------------------------
  // BÖLÜM 1: MANTIK NEDİR? (KORKMA!)
  // -------------------------------------------------------------------------
  {
    'title': '1. Korkma, Sadece Oku',
    'content': [
      {
        'type': 'text',
        'text': 'Bu konunun formülü, ezberi yoktur. Sorular paragraf gibi uzundur ama cevapları çok kısadır. Senden istenen tek şey: DİKKAT.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 2: GRAFİK YORUMLAMA (PASTA DİLİMİ)
  // -------------------------------------------------------------------------
  {
    'title': '2. Grafik Yorumlama',
    'content': [
      {
        'type': 'highlighted',
        'text': 'DAİRE GRAFİĞİ (Pasta):\n\nTamamı 360 derecedir. Sana yüzde verirse (Mesela %40), bunu dereceye çevirmek için orantı kur.\n\n• Formül: (Parça / Bütün) = (Derece / 360).\n• Örnek: %25\'i ne kadardır?\n  %25 demek çeyrek demektir (1/4). 360\'ın çeyreği 90 derecedir.'
      },
      {
        'type': 'highlighted',
        'text': 'ÇİZGİ VE SÜTUN GRAFİĞİ:\n\nArtış ve azalış eğimlerine bak.\n\n• KESİŞİM NOKTASI: İki çizginin kesiştiği yer "EŞİTLİK" anıdır. (Gelirin Gidere eşit olduğu yıl gibi).\n• EĞİM: Çizgi ne kadar dikse artış hızı o kadar fazladır.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 3: ŞEKİL YETENEĞİ (KÜP VE KATLAMA)
  // -------------------------------------------------------------------------
  {
    'title': '3. Şekil Yeteneği',
    'content': [
      {
        'type': 'text',
        'text': 'Üç boyutlu düşünmen gerekir.'
      },
      {
        'type': 'highlighted',
        'text': 'KÜP AÇILIMI (Zıt Yüzler Kuralı):\n\nBir küp açıldığında, "Arada bir kare boşluk olan yüzler" birbirine KARŞILIKLI gelir.\n\n• Bunlar küp kapandığında asla YAN YANA gelmezler.\n• Bu kuralı bilirsen şıkların yarısını elersin.'
      },
      {
        'type': 'tip',
        'text': 'Kağıt Katlama: Soruyu tersten çöz. En son delinmiş halinden geriye doğru "kağıdı açarak" (simetrisini alarak) git.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 4: ÖRÜNTÜLER (SAYI DEDEKTİFLİĞİ)
  // -------------------------------------------------------------------------
  {
    'title': '4. Sayı Dizileri',
    'content': [
      {
        'type': 'text',
        'text': 'Sayılar belli bir kurala göre dizilmiştir. Dedektif gibi o kuralı bul.'
      },
      {
        'type': 'bulletList',
        'items': [
          'Sabit Artış: 2, 5, 8, 11 (Hep +3 artıyor).',
          'Katlayarak Artış: 2, 4, 8, 16 (Hep x2 çarpılıyor).',
          'Karesel Artış: 1, 4, 9, 16 (1², 2², 3²...). (Farkların farkına bak).',
          'Fibonacci: 1, 1, 2, 3, 5, 8 (Kendinden önceki iki sayıyı topla).'
        ]
      }
    ]
  }
];
