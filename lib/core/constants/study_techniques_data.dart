import 'package:kpss_2026/core/models/study_technique_model.dart';

class StudyTechniquesData {
  /// Tüm teknikleri getiren ana getter
  /// Kategorilere bölünmüş listeleri birleştirir
  static List<StudyTechnique> get all => [
        ..._examHacks,      // 🚀 YENİ: Sınav Hackleri (En üste)
        ..._timeManagement, // Zaman Yönetimi
        ..._breakGuide,     // ☕ YENİ: Mola Rehberi
        ..._bioHacking,     // 🧬 YENİ: Bio-Performans
        ..._noteTaking,     // Not Alma
        ..._memory,         // Hafıza (Duplicate temizlendi)
        ..._reading,        // Okuma
        ..._studyPlanning,  // Planlama
        ..._concentration,  // Odaklanma
        ..._motivation,     // Motivasyon
        ..._stress,         // Stres
      ];

  /// Kategoriye göre filtreleme
  static List<StudyTechnique> getTechniquesByCategory(String categoryId) {
    return all.where((t) => t.category == categoryId).toList();
  }

  /// ID'ye göre teknik getirme
  static StudyTechnique? getTechniqueById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🚀 1. SINAV TAKTİKLERİ (EXAM TACTICS)
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<StudyTechnique> _examHacks = [
    StudyTechnique(
      id: 'turlama-teknigi',
      title: 'Turlama Tekniği',
      category: 'examHacks',
      shortDescription: 'Zor sorularla inatlaşma.',
      fullDescription:
          'Sınavdaki soruların zorluk dereceleri farklıdır, ancak çoğu sınavda her soru aynı puandır. Bu teknik, zor sorularla vakit kaybetmek yerine, önce "kolay ve yapılabilir" soruları çözüp, zor olanları ikinci tura bırakma stratejisidir.',
      steps: [
        'Hızlı Tarama: Soruyu oku. Cevabı hemen biliyorsan işaretle.',
        'Karar: Soru karmaşıksa hemen yanına (?) koy ve geç.',
        'İlerleme: Asla bir soruyla inatlaşma. Çözemediğin an geç.',
        'İkinci Tur: Sınavın sonuna geldiğinde, boş bıraktığın sorulara geri dön.',
      ],
      benefits: [
        'Sınavın başında kolay soruları çözmek özgüveni (moral) tavan yaptırır.',
        '"Süre yetmedi, bildiğim soruları göremedim" pişmanlığını %100 engeller.',
        'Zor sorulara döndüğünde, bilinçaltın çözüm üretmiş olabilir.',
      ],
      tips: [
        'İşaret Dili: Yuvarlak içine almak "Döneceğim", çarpı atmak "Bilmiyorum" anlamına gelebilir.',
        'İlk turda kitapçığın %60-70\'ini bitirdiğini görmek paniği yok eder.',
      ],
    ),
    StudyTechnique(
      id: 'soru-koku-analizi',
      title: 'Soru Kökü Analizi (Ters Okuma)',
      category: 'examHacks',
      shortDescription: 'Önce neyin sorulduğunu anla.',
      fullDescription:
          'Beynimiz metni baştan sona okumaya programlıdır. Ancak sınavlarda önce metni değil, neyin sorulduğunu (soru kökünü) okumak gerekir.',
      steps: [
        'Önce Koyu Kısım: Paragrafı okumadan önce en alttaki koyu yazılmış soru kökünü oku.',
        'Anahtar Kelime: Olumsuz ifadelere (değildir, ulaşılamaz) odaklan.',
        'Hedefli Okuma: Şimdi paragrafı, aradığın cevabı bilerek oku.',
      ],
      benefits: [
        'Paragrafı iki kez okumak zorunda kalmazsın (zaman tasarrufu).',
        'Odaklanma seviyesi (seçici dikkat) artar.',
        'Olumsuz soru köklerini kaçırma riskini düşürür.',
      ],
      tips: [
        'Soru kökündeki olumsuz ekin (-me, -ma, değildir) altını çiz.',
      ],
    ),
    StudyTechnique(
      id: 'blok-kodlama',
      title: 'Blok Kodlama (Grup İşaretleme)',
      category: 'examHacks',
      shortDescription: 'Kodlama hatası ve zaman kaybına son.',
      fullDescription:
          'Soruları optik forma geçirirken kullanılan en güvenli yöntemdir. Soruları tek tek kodlamak dikkat dağıtır, hepsini en sona bırakmak ise kaydırma riski yaratır.',
      steps: [
        'Çözüm: Bir sayfadaki tüm soruları veya 4-5 soruyu kitapçık üzerinde çöz.',
        'Toplu Kodlama: Çözdüğün bu 4-5 soruyu optik forma sırayla geçir.',
        'Kontrol: Kodlarken "15 A, 16 C" diye içinden tekrar et.',
      ],
      benefits: [
        'Kitapçık-optik arası git-gel dikkati bölmez.',
        'Kodlama anı, beyne 5-10 saniyelik mikro mola verir.',
        'Kaydırma hatası (Shift Error) riskini minimize eder.',
      ],
      tips: [
        'En pratik yöntem, "Sayfa bitince kodla" kuralıdır.',
        'Asla tüm kodlamayı sınavın son dakikasına bırakma.',
      ],
    ),
    StudyTechnique(
      id: 'celdirici-eleme',
      title: 'Çeldirici Eleme Yöntemi',
      category: 'examHacks',
      shortDescription: 'Yanlışları eleyerek doğruyu bul.',
      fullDescription:
          'Doğru cevabı bulamadığında, yanlış olduğundan emin olduğun şıkları eleyerek doğruya ulaşma stratejisidir. İstatistiksel başarı şansını artırır.',
      steps: [
        'Yanlışı Bul: %100 yanlış olduğunu bildiğin şıkların üzerini çiz.',
        'Daraltma: Seçenekleri 2 veya 3\'e indir.',
        'Kıyaslama: Kalan şıkları birbirleriyle ve soru köküyle kıyasla.',
      ],
      benefits: [
        '2 şıkkı elersen tatmin olma şansın %33\'e çıkar.',
        'Zihinsel yükü azaltır; beyin daha az seçenekle kolay karar verir.',
      ],
      tips: [
        'İki şık arasında kaldığında, ilk aklına gelen (içgüdüsel) cevap genellikle doğrudur.',
        '(A) şıkkı genellikle "güçlü çeldirici" olarak tasarlanır, dikkat et.',
      ],
    ),
    StudyTechnique(
      id: 'anahtar-kelime-avi',
      title: 'Anahtar Kelime Avı',
      category: 'examHacks',
      shortDescription: 'Metnin iskeletini yakala.',
      fullDescription:
          'Uzun paragraf sorularında metnin tamamını ezberlemeye çalışmak yerine, metnin iskeletini oluşturan kelimeleri yakalama tekniğidir.',
      steps: [
        'Tarama: Soruyu okurken önemli tarihlerin, isimlerin, bağlaçların altını çiz.',
        'Bağlaç Alarmı: "Ama, fakat, oysa" gibi kelimelerden sonrası genelde cevaptır.',
        'Görselleştirme: Altı çizili kelimelerle metnin özetini çıkar.',
      ],
      benefits: [
        'Metne geri dönmen gerektiğinde sadece işaretli yerleri okursun.',
        'Pasif okuyucu olmaktan çıkarıp aktif analizci yapar.',
      ],
      tips: [
        'Bütün satırların altını çizersen hiçbir şeyin altını çizmemiş olursun.',
      ],
    ),
    StudyTechnique(
      id: 'zor-soru-yonetimi',
      title: '"Zor Soru" Psikolojisi',
      category: 'examHacks',
      shortDescription: 'Zor soru puan getirmez, tuzaktır.',
      fullDescription:
          'Sınav kitapçıklarında bazen "şok etkisi" yaratmak için çok zor bir soru en başa konulabilir. Bu bir psikolojik dayanıklılık testidir.',
      steps: [
        'Farkındalık: "Bu soru herkes için zor. Yapamamak sınavı kaybettirmez."',
        'Pas Geçme: Maksimum 1-1.5 dakikada çözemiyorsan hemen geç.',
        'Nefes: Moralini bozduysa 10 saniyelik derin nefes molası ver.',
      ],
      benefits: [
        'Sınav anında "donup kalma" durumunu engeller.',
        'Enerjini tek bir soruya harcayıp kolay soruları kaçırmanı önler.',
      ],
      tips: [
        'Zor soru da kolay soru da aynı puandır. Zoru çözmek için kendini paralama, kolayı çöz, puanı kap.',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ☕ 2. MOLA REHBERİ (BREAK GUIDE) - YENİ
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<StudyTechnique> _breakGuide = [
    StudyTechnique(
      id: '20-20-20-rule',
      title: '20-20-20 Göz Kuralı',
      category: 'breakGuide',
      shortDescription: 'Göz yorgunluğunu anında al.',
      fullDescription:
          'Uzun süre yakına (kitap/ekran) bakmak göz kaslarını kasar ve baş ağrısı yapar. Bu kural gözlerini sıfırlar.',
      steps: [
        'Her 20 dakikada bir çalışmayı durdur.',
        '20 feet (yaklaşık 6 metre) uzağa bak.',
        '20 saniye boyunca oraya odaklan.',
      ],
      benefits: [
        'Göz kuruluğunu ve baş ağrısını önler.',
        'Mental bulanıklığı giderir.',
      ],
      tips: [
        'Pencereden dışarı bakmak en iyisidir.',
        'Bu sırada bol bol göz kırp.',
      ],
    ),
    StudyTechnique(
      id: 'power-nap',
      title: 'Power Nap (Güç Uykusu)',
      category: 'breakGuide',
      shortDescription: '20 dakikada 2 saatlik enerji.',
      fullDescription:
          'Öğleden sonra gelen ağırlığı atmak için yapılan kısa şekerleme. Dikkat: 20 dakikayı geçerse sersemleşirsin (uyku ataleti).',
      steps: [
        'Alarmını tam 20 dakikaya kur.',
        'Karanlık veya loş bir ortam bul (veya göz bandı tak).',
        'Uyumaya çalışmasan bile gözlerini kapat ve uzan.',
        'Alarm çalar çalmaz kalk.',
      ],
      benefits: [
        'Dikkat ve reaksiyon hızını artırır.',
        'Öğrendiklerini hafızaya işler.',
      ],
      tips: [
        'Uyumadan hemen önce kahve içersen, uyandığında kafein kana karışmış olur (Coffee Nap).',
      ],
    ),
    StudyTechnique(
      id: 'active-rest',
      title: 'Aktif Dinlenme (Esneme)',
      category: 'breakGuide',
      shortDescription: 'Masa başında kan dolaşımını aç.',
      fullDescription:
          'Telefona bakmak dinlenme değildir! Gerçek dinlenme, kan akışını hızlandırmakla olur.',
      steps: [
        'Ayağa kalk ve kollarını yukarı uzat.',
        'Boynunu yavaşça sağa-sola ve öne-arkaya esnet.',
        'Omuzlarını dairesel hareketlerle rahatlat.',
        'Odanın içinde 2-3 tur at.',
      ],
      benefits: [
        'Oksijen alımını artırır, beyni canlandırır.',
        'Sırt ve boyun ağrılarını engeller.',
      ],
      tips: [
        'Pencereyi açıp derin nefes alarak yap.',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 🧬 3. BIO-PERFORMANS (BIO-HACKING) - YENİ
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<StudyTechnique> _bioHacking = [
    StudyTechnique(
      id: 'sleep-cycles',
      title: 'REM Uykusu Stratejisi',
      category: 'bioHacking',
      shortDescription: 'Bilgileri uykuda kaydet.',
      fullDescription:
          'Hafıza, REM uykusunda pekişir. Sınav döneminde "az uyumak" değil, "döngülü uyumak" önemlidir. Bir uyku döngüsü yaklaşık 90 dakikadır.',
      steps: [
        'Uyku süreni 90 dakikanın katları olarak ayarla (4.5 saat, 6 saat, 7.5 saat).',
        'Örneğin 7.5 saat uyku (5 döngü), 8 saat uykudan daha dinç uyanmanı sağlar.',
        'Aynı saatte yatmaya ve kalkmaya çalış.',
      ],
      benefits: [
        'Sabahları dinç uyanırsın (Sleep Inertia olmaz).',
        'Ezberlediğin bilgiler kalıcı hafızaya geçer.',
      ],
      tips: [
        'Yatmadan 1 saat önce mavi ışığı (telefon) kes.',
      ],
    ),
    StudyTechnique(
      id: 'brain-food',
      title: 'Beyin Yakıtı (Beslenme)',
      category: 'bioHacking',
      shortDescription: 'Şeker çöküşünden kaçın.',
      fullDescription:
          'Karbonhidrat ağırlıklı beslenmek kan şekerini hızla yükseltip düşürür (Sugar Crash), bu da uyku getirir. Protein ve sağlıklı yağlar ise uzun süreli odaklanma sağlar.',
      steps: [
        'Ders öncesi: Ceviz, badem, bitter çikolata.',
        'Kahvaltı: Yumurta (B12 ve Protein).',
        'Kaçın: Hamur işi, şekerli içecekler.',
      ],
      benefits: [
        'Ders çalışırken uyuklamazsın.',
        'Odaklanma süren uzar.',
      ],
      tips: [
        'Yanında her zaman su bulundur. Dehidrasyon = Dikkat dağınıklığı.',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. ZAMAN YÖNETİMİ - KAPSAMLI VE DETAYLI
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<StudyTechnique> _timeManagement = [
    StudyTechnique(
      id: 'pomodoro',
      title: 'Pomodoro Tekniği',
      category: 'timeManagement',
      shortDescription: 'Zamanı düşman değil, müttefik yap.',
      fullDescription:
          'İtalyan Francesco Cirillo tarafından geliştirilen bu teknik, zamanı bir düşman gibi görmek yerine müttefik haline getirmeyi amaçlar. Odaklanma süresini (25 dk) kısa molalarla (5 dk) dengeleyerek zihinsel çevikliği korur. Özellikle dikkat dağınıklığı yaşayanlar için en etkili yöntemdir.',
      steps: [
        'Görev Seçimi: O an üzerinde çalışacağın tek bir görev belirle (Asla birden fazla değil).',
        'Zamanlayıcı Kurulumu: Zamanlayıcıyı tam 25 dakikaya ayarla.',
        'Çalışma: Süre bitene kadar dış dünyayla iletişimini kes ve sadece göreve odaklan.',
        'Kısa Mola: Zil çaldığında iş bitmese bile dur ve 5 dakika mola ver (Nefes al, su iç).',
        'Döngü: Her 4 Pomodoro\'dan (100 dakika çalışma) sonra 15-30 dakikalık uzun bir mola ver.',
      ],
      benefits: [
        'Büyük ve korkutucu görevleri yönetilebilir küçük parçalara böler.',
        'Zamanın ne kadar hızlı geçtiğine dair farkındalık (zaman algısı) yaratır.',
        'Sık molalar sayesinde zihinsel yorgunluğu ve tükenmişliği (burnout) engeller.',
      ],
      tips: [
        'Kesinti Yönetimi: Çalışırken aklına başka bir iş gelirse, kağıdın kenarına not al ve hemen işine dön.',
        'Analog Kullanım: Telefon yerine fiziksel bir saat kullanmak, telefonun dikkat dağıtıcı unsurlarından seni korur.',
      ],
    ),
    StudyTechnique(
      id: 'eisenhower-matrix',
      title: 'Eisenhower Matrisi',
      category: 'timeManagement',
      shortDescription: 'Meşgul olmakla üretken olmak arasındaki fark.',
      fullDescription:
          'Görevleri "Aciliyet" ve "Önem" derecesine göre dört kategoriye ayıran bir karar verme şablonudur. Meşgul olmakla üretken olmak arasındaki farkı netleştirir.',
      steps: [
        'Liste Oluşturma: Tüm yapılacaklar listeni önüne al.',
        'Kutu 1 (Acil ve Önemli): Krizler, son teslim tarihi bugün olan projeler → Hemen Yap.',
        'Kutu 2 (Acil Değil ama Önemli): Kişisel gelişim, spor, uzun vadeli planlar → Zaman Planla.',
        'Kutu 3 (Acil ama Önemsiz): Gereksiz telefonlar, başkasının acil işleri → Devret.',
        'Kutu 4 (Acil Değil ve Önemsiz): Sosyal medya, amaçsız internet sörfü → Sil (Yapma).',
        'Uygulama: Günün başında önce Kutu 1\'i bitir, sonra vaktinin çoğunu Kutu 2\'ye ayır.',
      ],
      benefits: [
        'Kriz yönetimi becerisini artırır.',
        'Gereksiz işlere "Hayır" demeyi kolaylaştırır.',
        'Stratejik ve uzun vadeli hedeflere odaklanmayı sağlar.',
      ],
      tips: [
        'Kutu 2 Tuzağı: İnsanlar Kutu 2\'yi erteler çünkü acil değildir. Ancak başarının sırrı Kutu 2\'dedir.',
        'Renk Kodlaması: Her kategoriyi farklı renkle işaretleyerek görsel bir harita oluştur.',
      ],
    ),
    StudyTechnique(
      id: 'time-blocking',
      title: 'Zaman Bloklama (Time Blocking)',
      category: 'timeManagement',
      shortDescription: 'Yapılacaklar Listesi yerine Takvim kullan.',
      fullDescription:
          'Günü saatlik dilimlere bölerek her bir zaman dilimine spesifik bir görev atama yöntemidir. "Şimdi ne yapsam?" sorusunu ortadan kaldırır.',
      steps: [
        'Tahmin: Yapacağın işlerin ne kadar süreceğini gerçekçi bir şekilde tahmin et.',
        'Bloklama: Takviminde bu işler için kesin saat aralıkları oluştur (Örn: 09:00-10:30 Rapor Yazımı).',
        'Gruplama (Batching): Benzer işleri (e-posta cevaplama, telefon görüşmeleri) tek bir zaman bloğuna topla.',
        'Tampon Süre: Bloklar arasına 10-15 dakikalık boşluklar bırak (Beklenmedik durumlar için).',
      ],
      benefits: [
        '"Şimdi ne yapsam?" karar yorgunluğunu ortadan kaldırır.',
        'Tek bir işe derinlemesine odaklanmayı (Deep Work) kolaylaştırır.',
        'Günün sonunda neye ne kadar vakit harcadığını net bir şekilde gösterir.',
      ],
      tips: [
        'Tema Günleri: Mümkünse günleri temalara ayır. (Örn: Çarşamba toplantı günü, Perşembe üretim günü).',
        'Katı Sınırlar: Blokladığın zaman diliminde iş bitmezse, takvimi revize et ya da diğer bloğa geç.',
      ],
    ),
    StudyTechnique(
      id: 'eat-that-frog',
      title: 'Kurbağayı Ye (Eat That Frog)',
      category: 'timeManagement',
      shortDescription: 'En zor işi sabah ilk yap.',
      fullDescription:
          'Günün en zor, en korkutucu ama en çok katma değer sağlayan işini sabah ilk sırada yapma tekniğidir. İrade gücünün sabah en yüksek seviyede olduğu gerçeğine dayanır.',
      steps: [
        'Kurbağayı Tanımla: Listendeki en zor, ertelemeye en meyilli olduğun görevi seç.',
        'Hazırlık: Geceden masanı hazırla ki sabah direkt başlayabilesin.',
        'İlk İş: Sabah e-postalarına veya telefona bakmadan önce doğrudan bu görevi yap.',
        'Tamamlama: Görev bitmeden başka hiçbir şeye geçme.',
      ],
      benefits: [
        'Erteleme (Procrastination) döngüsünü kırar.',
        'Güne büyük bir başarı hissiyle başlamayı sağlar, motivasyonu gün boyu yüksek tutar.',
        'Günün geri kalanında zihinsel baskıyı azaltır.',
      ],
      tips: [
        'İki Kurbağa Kuralı: Eğer iki zor iş varsa, daha çirkin (daha zor) olanından başla.',
        'Düşünme, Yap: Sabah uyanınca üzerine düşünmeye başlarsan erteleme ihtimalin artar. Robot gibi başla.',
      ],
    ),
    StudyTechnique(
      id: 'gtd',
      title: 'GTD (Getting Things Done)',
      category: 'timeManagement',
      shortDescription: 'Zihni boşalt, sisteme güven.',
      fullDescription:
          'Zihni hatırlama göreviyle yormayıp, tüm işleri harici bir sisteme kaydetme ve sistematik olarak işleme yöntemidir. David Allen tarafından geliştirilen kapsamlı bir akış yönetim sistemidir.',
      steps: [
        'Topla (Capture): Aklına gelen her şeyi (fikir, görev, ödeme) bir havuzda (defter/uygulama) topla.',
        'İşle (Clarify): Her madde için karar ver: Yapılabilir mi? Hayırsa sil. Evetse bir sonraki adım ne?',
        'Düzenle (Organize): Görevleri bağlamına göre listelere ayır (Örn: @Bilgisayar, @Telefon, @Ofis).',
        'Gözden Geçir (Reflect): Haftada bir kez tüm listelerini kontrol et ve güncelle.',
        'Yap (Engage): Bulunduğun ortama ve enerji durumuna uygun görevi seç ve yap.',
      ],
      benefits: [
        'Zihinsel yükü (mental load) sıfırlar, stresi azaltır.',
        'Hiçbir detayın veya görevin gözden kaçmamasını garanti eder.',
        'Yaratıcılık için beyinde boş alan açar.',
      ],
      tips: [
        '2 Dakika Kuralı: Eğer bir işi yapmak 2 dakikadan kısa sürüyorsa, asla listeye yazma. Hemen yap.',
        'Gelen Kutusu Temizliği: Havuzunu her günün sonunda mutlaka boşalt (sınıflandır).',
      ],
    ),
    StudyTechnique(
      id: 'pareto-principle',
      title: 'Pareto İlkesi (80/20 Kuralı)',
      category: 'timeManagement',
      shortDescription: 'Sonuçların %80\'i, çabaların %20\'sinden.',
      fullDescription:
          'Sonuçların %80\'inin, nedenlerin %20\'sinden kaynaklandığını savunan analiz yöntemidir. Az çabayla çok sonuç almayı hedefler. Mükemmeliyetçilik tuzağından kurtarır.',
      steps: [
        'Analiz: Yapılacaklar listendeki tüm işleri yaz.',
        'Değerlendirme: Hangi görevlerin sana en büyük getiriyi (başarı, mutluluk) sağladığını tespit et.',
        'Eleme: Düşük katma değerli işleri (kalan %80\'i) belirle.',
        'Odaklanma: Enerjinin tamamını o "Altın %20"lik kısma harca. Diğerlerini mümkünse yapma.',
      ],
      benefits: [
        'Mükemmeliyetçilik tuzağından kurtarır.',
        'Verimliliği (Efficiency) değil, etkinliği (Effectiveness) artırır.',
        'Gereksiz detaylarda boğulmayı engeller.',
      ],
      tips: [
        'Sürekli Sorgulama: "Şu an yaptığım iş o %20\'lik dilimde mi yoksa vakit mi öldürüyorum?" diye sor.',
        'KPSS\'de en çok soru çıkan konulara (o %20\'lik kısma) odaklan.',
      ],
    ),
    StudyTechnique(
      id: 'kanban',
      title: 'Kanban Tekniği',
      category: 'timeManagement',
      shortDescription: 'İş akışını görselleştir.',
      fullDescription:
          'İş akışını görselleştirmek için panoların ve kartların kullanıldığı bir yöntemdir. İşlerin hangi aşamada olduğunu net bir şekilde gösterir. Japonya\'da Toyota tarafından geliştirilmiştir.',
      steps: [
        'Pano Hazırlığı: Bir kağıda, tahtaya veya Trello gibi bir uygulamaya 3 sütun çiz.',
        'Sütun İsimleri: Yapılacaklar (To Do) | Yapılıyor (Doing) | Bitti (Done)',
        'Kart Oluşturma: Görevleri kartlara yaz ve ilgili sütuna yerleştir.',
        'Hareket: Süreç ilerledikçe kartı sağdaki sütuna taşı.',
      ],
      benefits: [
        'Süreçteki darboğazları (tıkanan yerleri) görmeyi sağlar.',
        'Görsel olarak ilerlemeyi görmek beyinde dopamin salgılar ve motivasyon yaratır.',
        'Aynı anda çok fazla işe başlanmasını engeller.',
      ],
      tips: [
        'WIP Limiti: "Yapılıyor" sütununa aynı anda en fazla 3 iş koyma kuralı getir. Odaklanmanı artırır.',
        'Duvarına veya panona basitçe çizebilirsin, dijital uygulama şart değil.',
      ],
    ),
    StudyTechnique(
      id: 'parkinson-law',
      title: 'Parkinson Yasası',
      category: 'timeManagement',
      shortDescription: 'İşlere yapay süreler vererek hızlan.',
      fullDescription:
          '"Bir iş, tamamlanması için ayrılan süreyi dolduracak şekilde genişler." ilkesine dayanarak, işlere yapay ve kısa süreler verme tekniğidir. Kendine baskı oluşturarak verimliliği artırır.',
      steps: [
        'Süre Belirleme: Bir görevin normalde ne kadar süreceğini düşün (Örn: 2 saat).',
        'Kısıtlama: Kendine bu sürenin yarısını ver (Örn: 1 saat).',
        'Yarış: Sanki patronun başındaymış veya uçak kaçacakmış gibi o sürede işi bitirmeye çalış.',
        'Değerlendirme: Süreyi tutturup tutturamadığını analiz et ve sonraki sefer ayarla.',
      ],
      benefits: [
        'Çalışma hızını ve tempoyu artırır.',
        'Gereksiz detaylarla uğraşmayı ve oyalanmayı engeller.',
        'Karar verme mekanizmasını hızlandırır.',
      ],
      tips: [
        'Şarjsız Çalışma: Bilgisayarının şarj aletini yanına alma. "Şarj bitene kadar bu iş bitecek" hedefi koymak en pratik uygulamadır.',
        'Sınav provalarında gerçek sınav süresinin altında süre vererek pratik yap.',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. NOT ALMA TEKNİKLERİ
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<StudyTechnique> _noteTaking = [
    StudyTechnique(
      id: 'cornell-method',
      title: 'Cornell Metodu',
      category: 'noteTaking',
      shortDescription: 'Sayfayı böl, verimli not al.',
      fullDescription:
          'Kağıdı 3 bölüme ayırarak notları organize etme sistemi. Hem not almayı hem de tekrar etmeyi kolaylaştırır.',
      steps: [
        'Sağ sütun: Ders notlarını ana hatlarıyla yaz.',
        'Sol sütun: Anahtar kelimeleri ve soruları yaz.',
        'Alt kısım: Sayfanın özetini 2-3 cümleyle yaz.',
      ],
      benefits: [
        'Tekrar yaparken sağ tarafı kapatıp soldan kendini test edebilirsin.',
        'Özet çıkarma becerini geliştirir.',
      ],
      tips: [
        'Ders bittikten hemen sonra özeti doldur.',
      ],
    ),
    StudyTechnique(
      id: 'mind-mapping',
      title: 'Zihin Haritası (Mind Map)',
      category: 'noteTaking',
      shortDescription: 'Görsel bağlantılar kur.',
      fullDescription:
          'Merkezi bir fikirden dallara ayrılarak konuları görselleştirme. Özellikle Tarih ve Vatandaşlık gibi sözel dersler için mükemmeldir.',
      steps: [
        'Kağıdın ortasına ana konuyu yaz (Örn: Osmanlı Duraklama).',
        'Ana dalları çıkar (Siyasi, Ekonomik, Sosyal).',
        'Alt dallara detayları ekle, renkler ve çizimler kullan.',
      ],
      benefits: [
        'Bütün resmi görmeni sağlar.',
        'Görsel hafızayı tetikler.',
      ],
      tips: [
        'Farklı renkli kalemler kullanmak akılda kalıcılığı artırır.',
      ],
    ),
    StudyTechnique(
      id: 'feynman-technique',
      title: 'Feynman Tekniği',
      category: 'noteTaking',
      shortDescription: 'Basitleştirerek öğren.',
      fullDescription:
          'Bir konuyu 5 yaşındaki bir çocuğa anlatacakmış gibi basitleştirerek not alma/anlatma yöntemi. Anlatamıyorsan, anlamamışsındır.',
      steps: [
        'Konuyu başlık olarak yaz.',
        'Basit cümlelerle, jargon kullanmadan konuyu anlat.',
        'Takıldığın yerleri belirle ve kaynağa dön.',
        'Benzetmeler (analojiler) kullan.',
      ],
      benefits: [
        'Ezberi değil, mantığı kavramayı sağlar.',
        'Konu eksiğini nokta atışı buldurur.',
      ],
      tips: [
        'Sesli olarak kendi kendine anlatmak da çok etkilidir.',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. HAFIZA TEKNİKLERİ
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<StudyTechnique> _memory = [
    StudyTechnique(
      id: 'memory-palace',
      title: 'Hafıza Sarayı (Loci)',
      category: 'memory',
      shortDescription: 'Bilgileri mekanlara yerleştir.',
      fullDescription:
          'Dünyanın en eski ve etkili hafıza tekniği. Bildiğin bir mekanı (evin, sokağın) kullanarak bilgileri o mekanın eşyalarıyla ilişkilendir.',
      steps: [
        'Zihninde bir rota belirle (Örn: Evin girişi).',
        'Ezberleyeceğin maddeleri bu rotadaki eşyalarla hayali, komik ve abartılı şekilde ilişkilendir.',
        'Geri çağırmak için zihninde o rotada yürü.',
      ],
      benefits: [
        'Sıralı listeleri ezberlemek için rakipsizdir.',
        'Kalıcı hafızaya atar.',
      ],
      tips: [
        'Hayaller ne kadar saçma ve abartılı olursa o kadar akılda kalır.',
      ],
    ),
    StudyTechnique(
      id: 'spaced-repetition',
      title: 'Aralıklı Tekrar',
      category: 'memory',
      shortDescription: 'Unutmadan hemen önce tekrar et.',
      fullDescription:
          'Unutma eğrisini kırmak için yapılan sistematik tekrar. Bilgiyi tam unutacakken hatırlamak, nöral bağları güçlendirir.',
      steps: [
        '1. Tekrar: Dersten hemen sonra.',
        '2. Tekrar: 1 gün sonra.',
        '3. Tekrar: 1 hafta sonra.',
        '4. Tekrar: 1 ay sonra.',
      ],
      benefits: [
        'Bilgiyi kısa süreli hafızadan uzun süreliye aktarır.',
        'Son hafta sabahlamalarını önler.',
      ],
      tips: [
        'Flashcard uygulamamız bu sistemle çalışır, bol bol kullan.',
      ],
    ),
    StudyTechnique(
      id: 'chunking',
      title: 'Gruplama (Chunking)',
      category: 'memory',
      shortDescription: 'Parçalara bölerek ezberle.',
      fullDescription:
          'Beynimiz kısa sürede 7 (±2) birim bilgiyi tutabilir. Uzun bilgileri küçük gruplara bölmek kapasiteyi artırır.',
      steps: [
        'Büyük veriyi analiz et.',
        'Benzer özellikleri olanları grupla.',
        'Örneğin telefon numaralarını 3-3-4 diye ayırmak gibi.',
      ],
      benefits: [
        'Karmaşık bilgileri yönetilebilir kılar.',
        'Hatırlamayı kolaylaştırır.',
      ],
      tips: [
        'Anayasa maddelerini veya tarihleri gruplamak için idealdir.',
      ],
    ),
    StudyTechnique(
      id: 'akrostis',
      title: 'Akrostiş Tekniği',
      category: 'memory',
      shortDescription: 'İlk harflerden kelime veya cümle oluştur.',
      fullDescription:
          'Ezberlenecek listenin her maddesinin ilk harfini alarak akılda kalıcı bir kelime veya cümle oluşturma tekniği. Özellikle sıralı listeler için mükemmeldir.',
      steps: [
        'Ezberlenecek maddelerin listesini çıkar.',
        'Her maddenin ilk harfini al.',
        'Bu harflerle anlamlı veya komik bir kelime/cümle oluştur.',
        'Örnek: Osmanlı padişahları için "Osman, Orhan, Murat..." = "OOM..."',
      ],
      benefits: [
        'Uzun listeleri tek kelimeye sıkıştırır.',
        'Sırayı asla unutmazsın.',
        'Sınav anında hızlı hatırlama sağlar.',
      ],
      tips: [
        'Kendi oluşturduğun akrostişler başkasınınkinden daha akılda kalır.',
        'Komik veya absürt olanlar daha etkili.',
      ],
    ),
    StudyTechnique(
      id: 'hikaye-metodu',
      title: 'Hikaye Metodu',
      category: 'memory',
      shortDescription: 'Bilgileri bir hikayeye dönüştür.',
      fullDescription:
          'Beynimiz hikayeleri, kuru bilgiden 22 kat daha iyi hatırlar (Stanford araştırması). Ezberlenecek bilgileri birbirine bağlayan absürt bir hikaye oluştur.',
      steps: [
        'Ezberlenecek maddeleri sırala.',
        'Her maddeyi bir karaktere veya nesneye dönüştür.',
        'Bunları birbirine bağlayan çılgın bir hikaye yaz.',
        'Hikayeyi zihninde canlandırarak tekrar et.',
      ],
      benefits: [
        'Birbiriyle alakasız bilgileri bağlar.',
        'Duygusal bağ kurarak kalıcılığı artırır.',
        'Görsel hafızayı devreye sokar.',
      ],
      tips: [
        'Hikaye ne kadar absürt, duygusal veya komikse o kadar kalıcı.',
        'Kendin hikayenin kahramanı ol.',
      ],
    ),
    StudyTechnique(
      id: 'cagrisim-zinciri',
      title: 'Çağrışım Zinciri',
      category: 'memory',
      shortDescription: 'Her bilgiyi bir sonrakine bağla.',
      fullDescription:
          'Ardışık bilgileri, her birini bir sonrakiyle görsel olarak ilişkilendirerek zincir gibi bağlama tekniği. Domino etkisiyle tüm listeyi hatırlarsın.',
      steps: [
        'İlk iki maddeyi akılda kalıcı şekilde ilişkilendir.',
        '2. maddeyi 3. ile, 3.yü 4. ile bağla...',
        'Tüm zincir boyunca devam et.',
        'Geri çağırırken ilk halkadan başla, zincir seni götürür.',
      ],
      benefits: [
        'Sıralı listelerde çok etkili.',
        'Bir halkayı hatırlayınca tüm zincir gelir.',
        'Hafıza Sarayı\'ndan daha basit.',
      ],
      tips: [
        'Bağlantılar hareket, ses veya duygu içersin.',
        'Örnek: Atatürk İlkeleri zinciri için her ilkeyi bir sonrakine bağla.',
      ],
    ),
    StudyTechnique(
      id: 'gorsel-kodlama',
      title: 'Görsel Kodlama (Peg System)',
      category: 'memory',
      shortDescription: 'Sayıları görsellerle eşleştir.',
      fullDescription:
          'Sayıları sabit görsellerle eşleştirerek numaralı listeleri ezberleme tekniği. 1=Mum, 2=Kuğu, 3=Kalp gibi şekil benzetmeleri kullanılır.',
      steps: [
        '1-10 arası sayıları sabit görsellerle eşle (1=Mum, 2=Kuğu, 3=Yonca...)',
        'Ezberlenecek listedeki her maddeyi o sayının görseli ile ilişkilendir.',
        '3. maddeyse Yonca ile, 7. maddeyse Orak ile bağla.',
        'Geri çağırırken sayıyı düşün, görsel ve madde gelsin.',
      ],
      benefits: [
        'Numaralı listelerde mükemmel.',
        '"5. madde neydi?" sorusuna anında cevap.',
        'Sınav sorularında sıra numarasıyla ilişkili sorular için ideal.',
      ],
      tips: [
        'Kendi görsel-sayı eşleştirmeni oluştur ve ezberle.',
        'Tarihler için yüzyılları da kodlayabilirsin.',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. OKUMA STRATEJİLERİ
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<StudyTechnique> _reading = [
    StudyTechnique(
      id: 'sq3r',
      title: 'SQ3R Yöntemi',
      category: 'reading',
      shortDescription: 'Aktif ve derinlemesine okuma.',
      fullDescription:
          'Akademik metinleri anlamak için geliştirilmiş 5 aşamalı yöntem: Survey (Göz at), Question (Sor), Read (Oku), Recite (Anlat), Review (Tekrar et).',
      steps: [
        '1. Göz at: Başlıklara ve koyu yerlere bak.',
        '2. Sor: Bu bölüm ne anlatıyor diye soru sor.',
        '3. Oku: Cevabı arayarak oku.',
        '4. Anlat: Okuduğunu kendi cümlelerinle özetle.',
        '5. Tekrar et: Ertesi gün üzerinden geç.',
      ],
      benefits: [
        'Okuduğunu anlamayı maksimize eder.',
        'Pasif okumayı (göz gezdirme) engeller.',
      ],
      tips: [
        'Zor paragraflarda bu yöntemi uygula.',
      ],
    ),
    StudyTechnique(
      id: 'skimming-canning',
      title: 'Göz Atma & Tarama',
      category: 'reading',
      shortDescription: 'Hızlıca ana fikri bul.',
      fullDescription:
          'Her kelimeyi okumak yerine, anahtar kelimeleri ve yapıyı yakalamaya yönelik hızlı okuma teknikleri.',
      steps: [
        'Skimming (Göz Atma): Genel fikri anlamak için başlık, giriş ve sonuca bak.',
        'Scanning (Tarama): Spesifik bir bilgiyi (tarih, isim) aramak için metni tara.',
      ],
      benefits: [
        'Paragraf sorularında zaman kazandırır.',
        'Gereksiz detaylarda boğulmayı önler.',
      ],
      tips: [
        'Paragraf sorularında önce soru kökünü oku (Scanning için ne aradığını bil).',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. ODAKLANMA, PLANLAMA, MOTİVASYON (DİĞERLERİ)
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<StudyTechnique> _concentration = [
    StudyTechnique(
      id: 'deep-work',
      title: 'Derin Çalışma (Deep Work)',
      category: 'concentration',
      shortDescription: 'Dikkat dağıtıcıları yok et.',
      fullDescription:
          'Bilişsel yeteneklerinin sınırlarını zorlayarak, bölünmeden yapılan çalışma. "Yüzeysel çalışma"nın tam zıttıdır.',
      steps: [
        'Telefonu başka odaya koy.',
        'İnterneti kapat.',
        'En az 90 blokları halinde çalış.',
      ],
      benefits: [
        'Zor konuları öğrenmenin tek yoludur.',
        'Verimliliği 3-4 katına çıkarır.',
      ],
      tips: [
        'Kendine "Ulaşılamaz" modu ilan et.',
      ],
    ),
    StudyTechnique(
      id: 'dopamin-detoks',
      title: 'Dopamin Detoksu',
      category: 'concentration',
      shortDescription: 'Beynini ödül bağımlılığından kurtar.',
      fullDescription:
          'Sosyal medya, oyunlar ve anlık bildirimler beynini sürekli dopamin ile bombardımana tutar. Bu, ders çalışmayı "sıkıcı" hissettir. Detoks ile beynini sıfırla.',
      steps: [
        'Telefonu gri moda (renksiz) al - görsel çekicilik düşer.',
        'Sosyal medya uygulamalarını sil (web üzerinden erişebilirsin).',
        'Bildirimleri tamamen kapat.',
        'Hafta sonları "dijital detoks günü" yap.',
      ],
      benefits: [
        'Ders çalışmak eskisi kadar sıkıcı gelmez.',
        'Odaklanma süresi dramatik artar.',
        'Uyku kalitesi iyileşir.',
      ],
      tips: [
        'İlk 3 gün zor geçer, sonra beyin adapte olur.',
        'Telefonu yatak odasına sokma.',
      ],
    ),
    StudyTechnique(
      id: 'iki-dakika-kurali',
      title: 'İki Dakika Kuralı',
      category: 'concentration',
      shortDescription: 'Ertelemeyi yenmek için mikro başlangıçlar.',
      fullDescription:
          'Büyük görevler gözü korkutur. "Sadece 2 dakika başlayayım" demek, başlama direncini kırar. Başladıktan sonra devam etmek çok daha kolay.',
      steps: [
        'Yapman gereken görevi belirle.',
        'Kendine "Sadece 2 dakika yapacağım" de.',
        '2 dakikayı tamamla.',
        'Devam etmek isteyip istemediğine karar ver (genelde edersin).',
      ],
      benefits: [
        'Procrastination (erteleme) döngüsünü kırar.',
        'Momentum oluşturur.',
        'Büyük görevleri yönetilebilir kılar.',
      ],
      tips: [
        'Anahtar: "2 dakika"nın çok kısa olduğunu bilmek ama yine de başlamak.',
        'En nefret ettiğin derste bile işe yarar.',
      ],
    ),
    StudyTechnique(
      id: 'ortam-tasarimi',
      title: 'Ortam Tasarımı',
      category: 'concentration',
      shortDescription: 'Çevren seni şekillendirir, çevreni tasarla.',
      fullDescription:
          'İrade gücüne güvenme, çevreyi öyle tasarla ki doğru davranış kolay, yanlış davranış zor olsun. Telefon uzaktaysa almak için kalkmak gerekir.',
      steps: [
        'Çalışma masanı SADECE çalışma için olsun.',
        'Dikkat dağıtıcıları fiziksel olarak uzaklaştır.',
        'Çalışma malzemelerini hazır ve görünür tut.',
        'Farklı aktiviteler için farklı mekanlar kullan.',
      ],
      benefits: [
        'İrade gücüne ihtiyaç azalır.',
        'Otomatik olarak doğru davranışa yönelirsin.',
        'Çalışma moduna geçiş hızlanır.',
      ],
      tips: [
        'Masanda yatağı görmemen bile fark yaratır.',
        'Kulaklık = çalışma modu sinyali olabilir.',
      ],
    ),
  ];

  static const List<StudyTechnique> _studyPlanning = [
    StudyTechnique(
      id: 'smart-goals',
      title: 'SMART Hedef Belirleme',
      category: 'studyPlanning',
      shortDescription: 'Belirsiz değil, ölçülebilir hedefler koy.',
      fullDescription:
          'Hedeflerini Specific (Spesifik), Measurable (Ölçülebilir), Achievable (Ulaşılabilir), Relevant (İlgili), Time-bound (Zamanlı) kriterlerine göre belirle.',
      steps: [
        'S - Spesifik: "Daha çok çalışacağım" değil, "Her gün 50 soru çözeceğim" de.',
        'M - Ölçülebilir: Sayılarla ifade et (kaç soru, kaç saat, kaç sayfa).',
        'A - Ulaşılabilir: Gerçekçi ol, günde 12 saat hedef koyma.',
        'R - İlgili: KPSS hedefine doğrudan katkı sağlayan işleri seç.',
        'T - Zamanlı: Bitiş tarihi koy (Bu hafta sonuna kadar, 15 Ocak\'a kadar).',
      ],
      benefits: [
        'Belirsiz "çalışacağım" sözleri yerine somut hedefler koyarsın.',
        'İlerlemeyi ölçebilir, motivasyonunu takip edebilirsin.',
        'Hesap verebilirliği artırır.',
      ],
      tips: [
        'Haftalık ve günlük SMART hedefler belirle.',
        'Her pazar günü gelecek haftanın hedeflerini yaz.',
      ],
    ),
    StudyTechnique(
      id: 'weekly-review',
      title: 'Haftalık Gözden Geçirme',
      category: 'studyPlanning',
      shortDescription: 'Her pazar rotanı kontrol et.',
      fullDescription:
          'Her hafta sonunda geçen haftayı değerlendirip, gelecek haftayı planlama ritüeli. Dümenin başında olmanı sağlar.',
      steps: [
        'Geçen haftanın hedeflerini gözden geçir: Hangilerini tamamladın?',
        'Tamamlayamadıklarının nedenini analiz et: Zaman mı yetersizdi, motivasyon mu?',
        'Öğrenilenleri not et: Ne işe yaradı, ne yaramadı?',
        'Gelecek haftanın hedeflerini yaz.',
        'Takvimini güncelle.',
      ],
      benefits: [
        'Reaktif değil, proaktif olmanı sağlar.',
        'Küçük sorunlar büyümeden fark edilir.',
        'Sürekli iyileştirme (Kaizen) kültürü oluşturur.',
      ],
      tips: [
        'Sabit bir gün ve saat belirle (Örn: Her pazar 18:00).',
        '20-30 dakikadan fazla sürmesin.',
      ],
    ),
    StudyTechnique(
      id: 'geri-sayim',
      title: 'Geri Sayım Metodu',
      category: 'studyPlanning',
      shortDescription: 'Sınava kaç gün kaldı?',
      fullDescription:
          'KPSS tarihinden geriye doğru sayarak, her konuya ne kadar zaman kalacağını hesaplama yöntemi. Panik yerine plan üretir.',
      steps: [
        'Sınav tarihini belirle ve takvime koy.',
        'Sınava kaç gün/hafta kaldığını hesapla.',
        'Çalışılacak konuları listele ve önem sırasına koy.',
        'Her konuya gerçekçi gün/hafta ayır.',
        'Her haftayı ayrı bir "Sprint" olarak planla.',
      ],
      benefits: [
        'Son haftalara yığılmayı önler.',
        'Zaman kısıtını görünür kılarak acileyti hissettirir.',
        'Panik yerine sistematik aksiyon alırsın.',
      ],
      tips: [
        'Son 2-3 haftayı sadece tekrar ve deneme için ayır.',
        'Buffer (Tampon) günler bırak, her şey plana göre gitmeyebilir.',
      ],
    ),
  ];

  static const List<StudyTechnique> _motivation = [
    StudyTechnique(
      id: 'five-minute-rule',
      title: '5 Dakika Kuralı',
      category: 'motivation',
      shortDescription: 'Başlamak için kendini kandır.',
      fullDescription:
          'Canın hiç çalışmak istemediğinde kendine "Sadece 5 dakika bakıp bırakacağım" de. Genellikle 5 dakika sonra devam edersin.',
      steps: [
        'Zor gelen görevi seç.',
        'Kronometreyi 5 dakikaya kur.',
        'Sadece 5 dakika dayan.',
      ],
      benefits: [
        'Erteleme hastalığını (Procrastination) yener.',
        'Başlama sürtünmesini azaltır.',
      ],
      tips: [
        'Gerçekten istemezsen 5 dakika sonra bırakabilirsin (ama bırakmayacaksın).',
      ],
    ),
    StudyTechnique(
      id: 'seinfeld-strategy',
      title: 'Zinciri Kırma',
      category: 'motivation',
      shortDescription: 'Her gün küçük bir adım.',
      fullDescription:
          'Komedyen Jerry Seinfeld\'in tekniği. Her gün hedefin için bir şey yap ve takvime bir çarpı at. Amaç o çarpı zincirini koparmamak.',
      steps: [
        'Büyük bir takvim al.',
        'Görevi tamamlayınca üzerine büyük bir X at.',
        'Tek kural: Zinciri kırma.',
      ],
      benefits: [
        'Süreklilik kazandırır.',
        'Görsel motivasyon sağlar.',
      ],
      tips: [
        'Uygulamamızdaki "Streak" özelliği tam olarak budur!',
      ],
    ),
    StudyTechnique(
      id: 'odul-sistemi',
      title: 'Ödül Sistemi',
      category: 'motivation',
      shortDescription: 'Kendini ödüllendirerek motive ol.',
      fullDescription:
          'Beynimiz ödül bekleyince daha çok çalışır. Hedeflere ulaştığında kendine küçük ödüller vererek dopamin döngüsünü çalışmayla ilişkilendir.',
      steps: [
        'Kısa vadeli hedef koy (Örn: 2 saat çalış).',
        'Hedefe ulaşınca ödülü belirle (Çay molası, 1 bölüm dizi).',
        'SADECE hedefe ulaşınca ödülü al (disiplin şart).',
        'Büyük hedeflere büyük ödüller (Konu bitirince film, deneme puan artarsa restoran).',
      ],
      benefits: [
        'Çalışmayı zevkli hale getirir.',
        'Beklenen ödül motivasyonu artırır.',
        'Dopamini çalışmaya bağlar.',
      ],
      tips: [
        'Ödülü önceden belirle ve görünür yap.',
        'Hedefe ulaşamadıysan ödülü ASLA alma.',
      ],
    ),
    StudyTechnique(
      id: 'hesap-verebilirlik',
      title: 'Hesap Verebilirlik',
      category: 'motivation',
      shortDescription: 'Birine söz ver, baskı altında çalış.',
      fullDescription:
          'İnsanlar başkalarına karşı sorumlu olduklarında daha çok çalışır. Bir arkadaşa, aileye veya sosyal gruba hesap vermek motivasyonu artırır.',
      steps: [
        'Bir çalışma ortağı veya mentor bul.',
        'Haftalık hedeflerini paylaş.',
        'Her hafta ilerlemeyi raporla.',
        'Başaramadığında bir "ceza" belirle (Örn: kahve ısmarlamak).',
      ],
      benefits: [
        'Tek başına çalışmanın monotonluğunu kırar.',
        'Erteleme yapmak zorlaşır.',
        'Sosyal baskı motivasyon sağlar.',
      ],
      tips: [
        'Çalışma grupları veya online topluluklar kullanabilirsin.',
        'Aile bireyleri de iyi hesap verebilirlik ortakları olabilir.',
      ],
    ),
    StudyTechnique(
      id: 'kimlik-temelli',
      title: 'Kimlik Temelli Alışkanlıklar',
      category: 'motivation',
      shortDescription: 'Kendin hakkındaki inancını değiştir.',
      fullDescription:
          'Yapman gerekeni değil, olmak istediğin kişinin ne yapacağını düşün. "Çalışmam lazım" yerine "Ben disiplinli bir öğrenciyim, çalışıyorum" de.',
      steps: [
        'Olmak istediğin kişiyi tanımla (Örn: "Atanmış öğretmen").',
        'O kişi şu an ne yapardı diye sor.',
        'Her küçük çalışma, o kimliğe bir kanıt.',
        '"Ben X tipiyim" cümlelerini kullan.',
      ],
      benefits: [
        'İrade gücü gerektirmez, kimlik otomatik yönlendirir.',
        'Her çalışma kimliği güçlendirir.',
        'Uzun vadeli motivasyon sağlar.',
      ],
      tips: [
        '"Ben tembelim" yerine "Ben henüz alışkanlık kurmadım" de.',
        'Küçük başarılar kimlik kanıtıdır.',
      ],
    ),
  ];

  static const List<StudyTechnique> _stress = [
    StudyTechnique(
      id: 'visualization',
      title: 'Görselleştirme',
      category: 'stressManagement',
      shortDescription: 'Başarıyı zihninde yaşa.',
      fullDescription:
          'Zihninde sınav anını, soruları rahatça çözdüğünü ve atandığını detaylıca hayal etme tekniği.',
      steps: [
        'Gözlerini kapat ve sessiz bir ortamda otur.',
        'Sınav salonuna girdiğini, sakince oturduğunu hayal et.',
        'Soruları bildiğini ve keyifle çözdüğünü hisset.',
      ],
      benefits: [
        'Sınav kaygısını azaltır.',
        'Beyni başarıya odaklar (Beyin hayal ile gerçeği ayırt edemez).',
      ],
      tips: [
        'Gece yatmadan önce yapmak çok etkilidir.',
      ],
    ),
    StudyTechnique(
      id: 'breathing',
      title: 'Kutu Nefes Tekniği',
      category: 'stressManagement',
      shortDescription: '4 saniyede sakinleş.',
      fullDescription:
          'ABD Deniz Komandolarının (Navy SEALs) stres altındayken sakinleşmek için kullandığı nefes tekniği.',
      steps: [
        '4 saniye nefes al.',
        '4 saniye tut.',
        '4 saniye ver.',
        '4 saniye tut (boş bırak).',
      ],
      benefits: [
        'Kalp atışını anında yavaşlatır.',
        'Panik atağı engeller.',
      ],
      tips: [
        'Sınav anında heyecanlanırsan 2-3 tur yap.',
      ],
    ),
    StudyTechnique(
      id: 'kaygi-donusturme',
      title: 'Kaygıyı Heyecana Dönüştür',
      category: 'stressManagement',
      shortDescription: 'Korku yerine heyecan hisset.',
      fullDescription:
          'Harvard araştırması: "Sakin ol" demek yerine "Heyecanlıyım" demek performansı artırır. Bedensel belirtiler aynı, sadece etiket değişiyor.',
      steps: [
        'Kaygı hissedince dur ve fark et.',
        'Kendine "Bu kaygı değil, heyecan" de.',
        '"Vücudum beni hazırlıyor, bu iyi bir şey" diye düşün.',
        'Enerjiyi performansa yönlendir.',
      ],
      benefits: [
        'Kaygı belirtileri avantaja dönüşür.',
        'Özgüven artar.',
        'Performans düşmez, artar.',
      ],
      tips: [
        'Kalp çarpıntısı = Vücut oksijen pompalıyor = İyi şey!',
        'Kaygı ve heyecan fizyolojik olarak aynıdır.',
      ],
    ),
    StudyTechnique(
      id: 'grounding-54321',
      title: 'Grounding (5-4-3-2-1)',
      category: 'stressManagement',
      shortDescription: 'Şu ana dön, panikten çık.',
      fullDescription:
          'Anksiyete anında zihni şu ana çekmek için duyuları kullanma tekniği. Panik ataklarını durdurmak için kullanılır.',
      steps: [
        '5 şey GÖR (etrafına bak, 5 nesne say).',
        '4 şey DOKUN (masayı, kumaşı hisset).',
        '3 şey DUY (klima sesi, dışarıdan trafik).',
        '2 şey KOKLA (kağıt, parfüm).',
        '1 şey TAT (suyu yudumla).',
      ],
      benefits: [
        'Panik atağını anında durdurur.',
        'Zihni geçmiş/gelecek kaygısından şu ana çeker.',
        'Her yerde, gizlice yapılabilir.',
      ],
      tips: [
        'Sınav salonunda sessizce yapabilirsin.',
        'Düşünceler değil, duyular önemli.',
      ],
    ),
    StudyTechnique(
      id: 'pozitif-self-talk',
      title: 'Pozitif Kendi Kendine Konuşma',
      category: 'stressManagement',
      shortDescription: 'İç sesin düşmanın değil, koçun olsun.',
      fullDescription:
          'Negatif iç konuşmalar ("Yapamayacağım", "Çok zor") performansı düşürür. Bunları bilinçli olarak pozitife çevirmek beynin modunu değiştirir.',
      steps: [
        'Negatif düşünceyi fark et ("Başaramayacağım").',
        'Dur ve meydan oku ("Bu gerçekten doğru mu?").',
        'Gerçekçi pozitife çevir ("Zor ama hazırlandım, elimden geleni yapacağım").',
        'Bunu sesli veya yazılı olarak tekrarla.',
      ],
      benefits: [
        'Özgüveni yeniden inşa eder.',
        'Kaygı spiralini durdurur.',
        'Beynin problem çözme moduna geçmesini sağlar.',
      ],
      tips: [
        '"Yapamayacağım" → "Henüz yapamıyorum" (Growth Mindset).',
        'Kendine bir arkadaşına konuşur gibi konuş.',
      ],
    ),
  ];
}
