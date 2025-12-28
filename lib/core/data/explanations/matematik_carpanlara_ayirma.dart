// Matematik - Çarpanlara Ayırma (MALA ANLATIR GİBİ & PROFESYONEL DETAY)
const String topicId = 'mat_carpan_001';

const List<Map<String, dynamic>> sections = [
  // -------------------------------------------------------------------------
  // BÖLÜM 1: NEDEN AYIRIYORUZ? (MANTIK)
  // -------------------------------------------------------------------------
  {
    'title': '1. Neden Çarpanlara Ayırıyoruz?',
    'content': [
      {
        'type': 'text',
        'text': 'Amaç sadeleştirmektir. Şişman, karmaşık bir ifadeyi (x² - y²) parçalayıp zayıflatmak ve paydadaki benzeriyle yok etmektir. "Sadeleştirme" sorusu görüyorsan bil ki birileri gidecek.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 2: YÖNTEMLER (SİLAH SEÇİMİ)
  // -------------------------------------------------------------------------
  {
    'title': '2. Temel Yöntemler',
    'content': [
      {
        'type': 'highlighted',
        'text': 'A. ORTAK PARANTEZ (Kardeş Payı):\n\nHer terimde ortak olan ne varsa onu kapının önüne (parantez dışına) al.\n\n• 3x + 3y -> İkisinde de 3 var. 3(x + y).\n• x²y + xy² -> İkisinde de hem x hem y var (xy ortak). xy(x + y).'
      },
      {
        'type': 'highlighted',
        'text': 'B. İKİ KARE FARKI (SINAVIN KRALI):\n\nBunu adın gibi bilmezsen sınava girme. İki şeyin karesi birbirinden çıkıyorsa:\n\nFORMÜL: x² - y² = (x - y) . (x + y)\n\n• Bir eksilisini yaz, bir artılısını yaz, çarp.\n• Örnek: 100² - 1 = (100 - 1) . (100 + 1) = 99 . 101.\n• Örnek: x² - 4 = (x - 2)(x + 2).'
      },
      {
        'type': 'highlighted',
        'text': 'C. ÜÇ TERİMLİLER (Çapraz Ateş):\n\nx² + 5x + 6 gibi ifadeler.\n\n• Çarpımları en sondaki sayıyı (6) verecek.\n• Toplamları ortadaki sayıyı (5) verecek.\n• 2 ve 3 dersen: 2x3=6, 2+3=5. Tuttu!\n• Cevap: (x + 2)(x + 3).'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 3: TAM KARE VE KÜP (AÇILIMLAR)
  // -------------------------------------------------------------------------
  {
    'title': '3. Tam Kare Açılımları',
    'content': [
      {
        'type': 'text',
        'text': 'Parantezin karesi alınıyorsa. (x+y)².'
      },
      {
        'type': 'highlighted',
        'text': 'TEKERLEME:\n\n1. Birincinin karesi (x²)\n2. Birinciyle ikincinin çarpımının iki katı (2xy)\n3. İkincinin karesi (y²)\n\n(x + y)² = x² + 2xy + y²\n(x - y)² = x² - 2xy + y² (Ortası eksi olur).'
      },
      {
        'type': 'tip',
        'text': 'İpucu: (x-y)² ile (y-x)² birbirine EŞİTTİR. (Çünkü negatifin karesi pozitiftir). Sıralamayı kafana takma.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 4: SAZAN AVI (FORMÜLSÜZ ÇÖZÜM)
  // -------------------------------------------------------------------------
  {
    'title': '4. Değer Verme Taktiği',
    'content': [
      {
        'type': 'text',
        'text': 'Diyelim ki formülleri unuttun veya soru çok karışık. Pes mi edeceksin? Asla.'
      },
      {
        'type': 'highlighted',
        'text': 'ALTIN TAKTİK (Sazan Avı):\n\nEğer soru "İfadesinin sadeleşmiş hali hangisidir?" diye soruyorsa ve şıklarda x\'li y\'li ifadeler varsa:\n\n1. x\'e ve y\'ye kafandan basit değerler ver (0, 1, 2 gibi). (Dikkat: Paydayı 0 yapmasın!).\n2. Sorudaki ifadenin sonucunu bul (Mesela 5 çıktı).\n3. Şıklarda da aynı değerleri yerine koy.\n4. Hangi şık 5 çıkıyorsa CEVAP ODUR.\n\nBu yöntemle çarpanlara ayırma bilmeden bile fulleyebilirsin.'
      }
    ]
  }
];
