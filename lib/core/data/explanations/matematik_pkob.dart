// Matematik - PKOB (MALA ANLATIR GİBİ & PROFESYONEL DETAY)
const String topicId = 'mat_olasilik_001';

const List<Map<String, dynamic>> sections = [
  // -------------------------------------------------------------------------
  // BÖLÜM 1: PERMÜTASYON vs KOMBİNASYON (FARKI ANLA)
  // -------------------------------------------------------------------------
  {
    'title': '1. Hangisini Kullanacağım?',
    'content': [
      {
        'type': 'text',
        'text': 'En büyük kargaşa budur. Soruda hangisini kullanacağını anlamazsan formülü bilmek işe yaramaz.'
      },
      {
        'type': 'highlighted',
        'text': 'P Mİ C Mİ?\n\n• PERMÜTASYON (P): SIRALAMA önemlidir. Kimin sağda kimin solda olduğu fark eder.\n  - Anahtar Kelimeler: "Sıralanıyor", "Diziliyor", "Fotoğraf çektiriyor", "Anlamlı anlamsız kelimeler", "Sayı yazma".\n  - Ali ve Veli yanyana fotoğraf çektirirse (Ali-Veli) ile (Veli-Ali) FARKLI durumlardır.\n\n• KOMBİNASYON (C): SEÇME önemlidir. Sıranın önemi yoktur.\n  - Anahtar Kelimeler: "Seçiliyor", "Grup oluşturuluyor", "Takım kuruluyor", "Alt küme".\n  - Ali ve Veli\'yi takıma aldım. Önce Ali\'yi sonra Veli\'yi seçmem bir şeyi değiştirmez. Sonuçta ikisi de takımda. (Ali-Veli) = (Veli-Ali) AYNI durumdur.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 2: HESAPLAMA TEKNİKLERİ
  // -------------------------------------------------------------------------
  {
    'title': '2. Nasıl Hesaplanır?',
    'content': [
      {
        'type': 'highlighted',
        'text': 'PERMÜTASYON HESABI (Geriye Say):\n\nP(n, r) -> n\'den geriye r tane say ve çarp.\n\n• P(5, 2) = 5 . 4 = 20.\n• P(6, 3) = 6 . 5 . 4 = 120.\n• Soru: 5 kişi 2 koltuğa kaç farklı şekilde oturur? Cevap 20.'
      },
      {
        'type': 'highlighted',
        'text': 'KOMBİNASYON HESABI (Bölmeli):\n\nC(n, r) -> P(n, r) hesapla, paydaya r! yaz.\n\n• C(5, 2) = (5 . 4) / (2!) = 20 / 2 = 10.\n• Soru: 5 kişiden 2 kişilik takım kaç farklı şekilde seçilir? Cevap 10.'
      },
      {
        'type': 'tip',
        'text': 'PRATİK KURAL:\nC(n, r) = C(n, n-r).\nC(10, 8) hesaplamak zordur. Onun yerine farkını al: C(10, 2) hesapla. Sonuç aynıdır ve çok daha kolaydır.'
      }
    ]
  },

  // -------------------------------------------------------------------------
  // BÖLÜM 3: OLASILIK (ŞANS FAKTÖRÜ)
  // -------------------------------------------------------------------------
  {
    'title': '3. Olasılık Nedir?',
    'content': [
      {
        'type': 'text',
        'text': 'Olasılık = (İstenen Durum Sayısı) / (Tüm Durumların Sayısı). Asla 1\'den büyük olamaz.'
      },
      {
        'type': 'highlighted',
        'text': 'VE / VEYA KURALI:\n\n• "VEYA" diyorsa: Olaylar ayrıktır, TOPLA (+).\n  (Zar 3 VEYA 5 gelsin -> 1/6 + 1/6).\n\n• "VE" diyorsa: Olaylar bağımsızdır, ÇARP (x).\n  (Para tura VE zar 6 gelsin -> 1/2 x 1/6 = 1/12).'
      },
      {
        'type': 'example',
        'text': 'Soru: Torbada 3 Mavi, 2 Kırmızı top var. Çekilenin Mavi olma olasılığı?\nİstenen (Mavi): 3 tane.\nTümü (Toplar): 3 + 2 = 5 tane.\nCevap: 3/5.'
      }
    ]
  }
];
