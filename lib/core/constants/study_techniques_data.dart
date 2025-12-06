import 'package:kpss_2026/core/models/study_technique_model.dart';

class StudyTechniquesData {
  /// Tüm teknikleri getiren ana getter
  /// Kategorilere bölünmüş listeleri birleştirir
  static List<StudyTechnique> get all => [
        ..._timeManagement,     // 1. Zaman Yönetimi
        ..._motivation,          // 2. Motivasyon
        ..._studyPlanning,      // 3. Çalışma Planlama
        ..._concentration,      // 4. Odaklanma
        ..._breakGuide,         // 5. Mola Rehberi
        ..._examFastLearning,   // 6. Sınav & Hızlı Öğrenme
        ..._noteMemory,         // 7. Not & Hafıza Teknikleri
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
  // 5. MOLA REHBERİ
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<StudyTechnique> _breakGuide = [
    StudyTechnique(
      id: 'nsdr',
      title: 'NSDR (Non-Sleep Deep Rest / Yoga Nidra)',
      category: 'breakGuide',
      shortDescription: 'Uyumadan derin dinlenme.',
      fullDescription:
          'Stanford nörobilimcisi Andrew Huberman tarafından popülerleştirilen bu yöntem, "Uyumadan Derin Dinlenme" anlamına gelir. Beyni uykuya dalmadan, uykunun yenileyici etkisine sokmayı hedefler.',
      steps: [
        'Sessiz bir yerde sırtüstü uzan veya rahatça otur.',
        'Gözlerini kapat.',
        'YouTube veya bir uygulama üzerinden 10 veya 20 dakikalık bir "NSDR" veya "Yoga Nidra" ses kaydı aç.',
        'Yönlendirmeleri takip ederek vücudunuzdaki belirli noktaları zihnen tarayın ve gevşetin.',
      ],
      benefits: [
        '20 dakikalık bir NSDR, 3-4 saatlik uykuya eşdeğer bir tazelenme hissi yaratabilir.',
        'Dopamin seviyelerini yeniler.',
        'Öğrenilen bilgilerin hafızaya kazınmasını hızlandırır.',
      ],
      tips: [
        'Öğleden sonra gelen rehavet çökmesi (afternoon slump) için kahveden daha etkilidir.',
      ],
    ),
    StudyTechnique(
      id: 'twenty-twenty-twenty-rule',
      title: '20-20-20 Kuralı (Dijital Göz Yorgunluğu İçin)',
      category: 'breakGuide',
      shortDescription: 'Göz ve zihin dinlendirme molası.',
      fullDescription:
          'Sürekli ekrana bakmak "siliyer kasları" kilitler ve göz yorgunluğuna neden olur. Bu optik kural, gözleri ve beynin görsel işlem merkezini sıfırlar.',
      steps: [
        'Her 20 dakikada bir çalışmaya ara ver.',
        'En az 20 feet (yaklaşık 6 metre) uzaktaki bir nesneye bak.',
        'Bu nesneye 20 saniye boyunca odaklan.',
      ],
      benefits: [
        'Göz kuruluğunu ve baş ağrısını önler.',
        'Görsel odaklanmayı yeniden keskinleştirir.',
        'Kısa olduğu için iş akışını bozmaz.',
      ],
      tips: [
        'Uzağa bakarken gözlerinizi bilinçli olarak daha sık kırpın.',
        'Pencereden dışarı bakmak en iyi seçenektir.',
      ],
    ),
    StudyTechnique(
      id: 'niksen',
      title: 'Niksen (Hiçbir Şey Yapmama Sanatı)',
      category: 'breakGuide',
      shortDescription: 'Zihni serbest bırakma molası.',
      fullDescription:
          'Hollanda kökenli bu kavram, "amaçsızca durmak" demektir. Meditasyon değildir; zihni serbest bırakmaktır.',
      steps: [
        '5-10 dakikalık bir mola ver.',
        'Telefonu, kitabı veya herhangi bir girdiyi elinizden bırakın.',
        'Sadece oturun ve pencereden dışarı bakın veya tavanı izleyin.',
        'Düşüncelerin gelip geçmesine izin verin, hiçbir şeye odaklanmaya çalışmayın.',
      ],
      benefits: [
        'Beynin "Default Mode Network" (Varsayılan Mod Ağı) bölgesini aktive eder; bu bölge yaratıcılık ve problem çözme merkezidir.',
        'Tükenmişliği (burnout) engeller.',
        'Sürekli "üretken olma" baskısını azaltır.',
      ],
      tips: [
        'Bunu yaparken "suçluluk" hissetmeyin, bu sürecin bir parçasıdır.',
        'Sosyal medyada gezinmek Niksen değildir, çünkü orada beyniniz hala veri işler.',
      ],
    ),
    StudyTechnique(
      id: 'nasa-power-nap',
      title: 'NASA Usulü Güç Uykusu (Power Nap)',
      category: 'breakGuide',
      shortDescription: '20 dakikada enerjini topla.',
      fullDescription:
          'NASA pilotları üzerinde yapılan araştırmalara dayanan, tam bir uyku döngüsüne girmeden uyanıklığı artıran kısa uyku yöntemidir.',
      steps: [
        'Alarmınızı 10 ile 20 dakika arasına kurun (Asla 30 dakikayı geçmeyin).',
        'Ortamı biraz karartın veya göz bandı takın.',
        'Uyku moduna geçin.',
        'Alarm çalar çalmaz kalkın ve yüzünüzü yıkayın.',
      ],
      benefits: [
        'Bilişsel performansı %34, dikkati %54 artırdığı kanıtlanmıştır.',
        'Gece uykusunu bozmaz.',
        'Öğleden sonraki çöküşler için birebir.',
      ],
      tips: [
        '"Nappuccino" tekniği: Uyumadan hemen önce bir espresso için. Kafein kana karışana kadar (yaklaşık 20 dk) uyursunuz, uyandığınızda hem uykunun hem kafeinin etkisiyle süper enerjik kalkarsınız.',
        '30 dakikayı geçerseniz "uyku sersemliği" (sleep inertia) yaşarsınız, daha yorgun uyanırsınız.',
      ],
    ),
    StudyTechnique(
      id: 'palming',
      title: 'Palming (Göz Avuçlama)',
      category: 'breakGuide',
      shortDescription: 'Çok eski bir göz rahatlama tekniği.',
      fullDescription:
          'Gözleri ışıktan tamamen izole ederek sinir sistemini sakinleştiren çok eski bir yöntemdir.',
      steps: [
        'Avuç içlerinizi birbirine sürterek ısıtın.',
        'Dirseklerinizi masaya dayayın.',
        'Avuç içlerinizi, göz kürelerine baskı yapmadan, gözlerinizi kapatacak şekilde yüzünüze yerleştirin.',
        'Işığın hiç sızmadığından emin olun (Zifiri karanlık olmalı).',
        '1-3 dakika boyunca bu karanlığın içinde nefes alıp verin.',
      ],
      benefits: [
        'Optik sinirleri anında gevşetir.',
        'Zihinsel gürültüyü azaltır.',
        'Ekran başında çalışanlar için en hızlı rahatlama yöntemidir.',
      ],
      tips: [
        'Gözleriniz kapalıyken siyah rengi hayal etmeye çalışın, bu gevşemeyi artırır.',
      ],
    ),
    StudyTechnique(
      id: 'active-micro-exercises',
      title: 'Aktif Mikro-Egzersizler',
      category: 'breakGuide',
      shortDescription: 'Enerji yenileme hareketleri.',
      fullDescription:
          'Oturmanın verdiği fiziksel stresi atmak için kalp ritmini hafifçe yükselten hareketlerdir. Pomodoro molaları için idealdir.',
      steps: [
        'Mola verdiğinizde yerinizde durmayın.',
        '1 dakika boyunca "Jumping Jacks" (zıplayarak el çırpma) yapın.',
        'Veya ofis içinde hızlı tempoda bir tur atın.',
        'Veya 10 tane şınav çekin / squat yapın.',
      ],
      benefits: [
        'Beyne giden kan akışını ve oksijeni artırır.',
        'Uyuşukluğu (letarji) anında keser.',
        'Endorfin salgılatır.',
      ],
      tips: [
        'Terleyecek kadar değil, sadece kan dolaşımını hissedecek kadar yapın.',
      ],
    ),
    StudyTechnique(
      id: 'social-fuel-break',
      title: 'Sosyal Yakıt Molası',
      category: 'breakGuide',
      shortDescription: 'Oksitosin hormonu salgılatan sosyal dinlenme.',
      fullDescription:
          'Beynin odaklanan kısmını kapatıp, sosyal kısmını açarak yapılan dinlenmedir. Oksitosin hormonu salgılatır.',
      steps: [
        'İşle/dersle alakası olmayan bir arkadaşınızı veya aile üyenizi arayın.',
        'Veya ofiste sevdiğiniz bir iş arkadaşının yanına gidin.',
        'Kural: İş, proje veya stresli konular hakkında konuşmak yasak. Sadece havadan sudan veya komik bir olaydan bahsedin.',
        '5-10 dakika sonra işe dönün.',
      ],
      benefits: [
        'Yalnızlık hissini azaltır.',
        'Duygusal bir "reset" atar.',
      ],
      tips: [
        'Enerjinizi emen (negatif) insanlarla değil, size enerji veren kişilerle bu molayı yapın.',
      ],
    ),
    StudyTechnique(
      id: 'green-break',
      title: 'Yeşil Mola (40 Saniye Kuralı)',
      category: 'breakGuide',
      shortDescription: 'Melbourne Üniversitesi araştırmasına dayalı doğa molası.',
      fullDescription:
          'Melbourne Üniversitesi\'nin yaptığı bir araştırmaya göre, sadece doğaya bakmak bile dikkati toplar.',
      steps: [
        'Mola verdiğinizde bir parka gidin veya balkona çıkıp ağaçlara bakın.',
        'Eğer dışarı çıkamıyorsanız, bilgisayarınızda veya telefonunuzda yüksek çözünürlüklü bir orman/doğa fotoğrafı açın.',
        'En az 40 saniye boyunca bu yeşil görüntüye odaklanın.',
      ],
      benefits: [
        'Hata yapma oranını düşürür.',
        'Şehir hayatının yarattığı zihinsel yorgunluğu alır.',
      ],
      tips: [
        'Masanızda canlı bir bitki bulundurmak bu etkiyi sürekli kılar.',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. SINAV & HIZLI ÖĞRENME
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<StudyTechnique> _examFastLearning = [
    StudyTechnique(
      id: 'feynman-technique-exam',
      title: 'Feynman Tekniği',
      category: 'examFastLearning',
      shortDescription: 'Bir konuyu basitçe anlatamıyorsan anlamamışsındır.',
      fullDescription:
          'Nobel ödüllü fizikçi Richard Feynman\'dan adını alan bu teknik, bir konuyu tam anlamıyla öğrenmenin en iyi yolunun onu basitleştirerek anlatmak olduğu ilkesine dayanır.',
      steps: [
        'Konuyu çalıştıktan sonra boş bir kağıt alın.',
        'Konuyu hiç bilmeyen birine (örneğin 5 yaşındaki bir çocuğa) anlatır gibi yazın veya sesli anlatın.',
        'Karmaşık jargon kullanmaktan kaçının, basit analojiler kurun.',
        'Takıldığınız veya basitçe anlatamadığınız yerleri tespit edin; işte orası sizin eksik olduğunuz yerdir. Kaynağa dönüp o kısmı tekrar çalışın.',
      ],
      benefits: [
        'Ezberi değil, mantığı kavramayı sağlar.',
        'Bilgi boşluklarını (illüzyonları) anında ortaya çıkarır.',
        'Konuyu uzun süreli hafızaya atar.',
      ],
      tips: [
        'Gerçekten bir arkadaşınıza veya hayali bir dinleyiciye sesli anlatım yapın.',
        '"Neden?" sorusunu sürekli kendinize sorun.',
      ],
    ),
    StudyTechnique(
      id: 'spaced-repetition-exam',
      title: 'Aralıklı Tekrar (Spaced Repetition)',
      category: 'examFastLearning',
      shortDescription: 'Beyniniz unutma eğrisini kırın.',
      fullDescription:
          'Beynimiz öğrendiği bilgiyi zamanla unutur (Ebbinghaus Unutma Eğrisi). Bu yöntem, bilgiyi tam unutmak üzereyken tekrar ederek unutma eğrisini kırmayı hedefler.',
      steps: [
        'Bir konuyu çalıştıktan sonra şu aralıklarla tekrar edin:',
        '1. Tekrar: 1 gün sonra.',
        '2. Tekrar: 3 gün sonra.',
        '3. Tekrar: 1 hafta sonra.',
        'Tekrarlar sadece "okuma" değil, hatırlama egzersizi olmalıdır.',
      ],
      benefits: [
        'Bilgiyi kısa süreli hafızadan uzun süreli hafızaya en etkili aktaran yöntemdir.',
        'Sınavdan önceki gece sabahlamayı (cramming) gereksiz kılar.',
        'Daha az toplam çalışma süresiyle daha çok akılda tutmayı sağlar.',
      ],
      tips: [
        'Anki veya Quizlet gibi bu algoritmayı kullanan uygulamalar işi çok kolaylaştırır.',
        'Takviminize tekrar günlerini önceden işleyin.',
      ],
    ),
    StudyTechnique(
      id: 'active-recall',
      title: 'Aktif Hatırlama (Active Recall)',
      category: 'examFastLearning',
      shortDescription: 'Beyni dışarıdan almaya değil, içeriden çıkarmaya zorlayın.',
      fullDescription:
          'Pasif okumanın (altını çizme, tekrar tekrar okuma) tam tersidir. Beyni bilgiyi dışarıdan almaya değil, içeriden geri çağırmaya zorlamaktır. Öğrenme, bilgi beyne girerken değil, beyinden çıkarken gerçekleşir.',
      steps: [
        'Bir sayfayı okuyun.',
        'Kitabı/notu kapatın.',
        '"Az önce ne okudum?" diyerek aklınızda kalanları sesli söyleyin veya yazın.',
        'Kitabı açıp ne kadarını doğru hatırladığınızı kontrol edin.',
      ],
      benefits: [
        'Bilimsel olarak kanıtlanmış en yüksek verimli çalışma yöntemidir (High Utility).',
        'Beyindeki nöral bağlantıları güçlendirir.',
        'Sınav stresini azaltır çünkü sınavın kendisi bir "aktif hatırlama" sürecidir.',
      ],
      tips: [
        'Konu başlıklarını soruya çevirin (Örn: "Mitoz bölünme" başlığı yerine "Mitoz bölünmenin evreleri nelerdir?" yazın ve cevaplayın).',
      ],
    ),
    StudyTechnique(
      id: 'leitner-system',
      title: 'Leitner Kutusu Sistemi',
      category: 'examFastLearning',
      shortDescription: 'Aralıklı tekrarın fiziksel kartlarla oyunlaştırılmış hali.',
      fullDescription:
          'Aralıklı tekrarın fiziksel kartlarla oyunlaştırılmış halidir. Özellikle yabancı dil kelimeleri, formüller veya tarih terimleri ezberlemek için mükemmeldir.',
      steps: [
        '3 veya 5 adet kutu (veya zarf) hazırlayın.',
        'Tüm bilgi kartlarını 1. Kutuya koyun.',
        'Kartı çekin ve soruyu cevaplayın:',
        'Doğruysa: Kartı bir sonraki kutuya (Kutu 2) atın.',
        'Yanlışsa: Kartı en başa (Kutu 1) geri gönderin (Hangi kutuda olursa olsun).',
        'Kutu 1\'i her gün, Kutu 2\'yi 3 günde bir, Kutu 3\'ü haftada bir çalışın.',
      ],
      benefits: [
        'Zaten bildiğiniz şeylere zaman harcamanızı engeller.',
        'Zorlandığınız konulara daha sık maruz kalmanızı sağlar.',
        'İlerlemeyi görselleştirir.',
      ],
      tips: [
        'Kartın bir yüzüne soruyu, arkasına cevabı yazın.',
        'Kartlar dijital değil, el yazısı olursa akılda kalıcılık artar.',
      ],
    ),
    StudyTechnique(
      id: 'sq3r-method',
      title: 'SQ3R Metodu',
      category: 'examFastLearning',
      shortDescription: 'Ders kitaplarını anlamak için sistematik yöntem.',
      fullDescription:
          'Francis Pleasant Robinson tarafından geliştirilen bu yöntem, ders kitaplarını veya akademik makaleleri okurken anlamayı maksimuma çıkarmak için kullanılır.',
      steps: [
        'Survey (Göz Gezdir): Başlıkları, görselleri, özetleri hızlıca tara. İskeleti gör.',
        'Question (Soru Sor): Başlıkları soruya çevir (Örn: "Termodinamik Yasaları" -> "Bu yasalar nelerdir ve ne işe yarar?").',
        'Read (Oku): Soruların cevabını bulmak için metni aktif şekilde oku.',
        'Recite (Anlat/Tekrarla): Okuduğunu bakmadan kendi cümlelerinle özetle.',
        'Review (Gözden Geçir): Tüm notları ve metni son kez kontrol et.',
      ],
      benefits: [
        'Okuduğunu anlamama veya "gözlerin satırlarda kayıp gitmesi" sorununu çözer.',
        'Metne bir amaçla yaklaşmanızı sağlar.',
        'Ders kitabı çalışmayı sistematik hale getirir.',
      ],
      tips: [
        'Göz gezdirme aşamasını asla atlamayın, beyni hazırlar.',
      ],
    ),
    StudyTechnique(
      id: 'memory-palace-exam',
      title: 'Zihin Sarayı (Loci Metodu)',
      category: 'examFastLearning',
      shortDescription: 'Bilgileri mekansal hafızayla kodlayarak hatırlayın.',
      fullDescription:
          'Antik Yunan hatiplerinin kullandığı, dünya hafıza şampiyonlarının favori tekniğidir. Bilgileri mekansal hafızayla kodlayarak sırasıyla hatırlamayı sağlar.',
      steps: [
        'Çok iyi bildiğiniz bir mekan seçin (Eviniz, okul yolu vb.).',
        'Ezberlemeniz gereken maddeleri (örneğin elementler tablosu) bu mekandaki eşyalarla sırayla eşleştirin.',
        'Absürt ve abartılı hayaller kurun (Örn: Kapı kolunda sarkan dev bir Hidrojen balonu, koltukta oturan Helyum sesli bir palyaço).',
        'Zihninizde bu mekanda yürüyüşe çıkarak bilgileri toplayın.',
      ],
      benefits: [
        'Sıralı listeleri ezberlemek için rakipsizdir.',
        'Hafıza kapasitesini inanılmaz artırır.',
        'Kalıcıdır, yıllar sonra bile o "yürüyüşü" yapıp hatırlayabilirsiniz.',
      ],
      tips: [
        'Görseller ne kadar komik, korkunç veya tuhaf olursa o kadar iyi hatırlarsınız.',
      ],
    ),
    StudyTechnique(
      id: 'interleaving',
      title: 'Örgülü Çalışma (Interleaving)',
      category: 'examFastLearning',
      shortDescription: 'Konuları ve soru tiplerini karıştırarak çalışın.',
      fullDescription:
          'Genellikle yapılan "Blok Çalışma"nın (Önce A konusunu bitir, sonra B\'ye geç) aksine, konuları veya soru tiplerini karıştırarak çalışmaktır.',
      steps: [
        'Matematik çalışıyorsanız; sadece "Türev" çözmek yerine, testin içine "İntegral" ve "Trigonometri" soruları da serpiştirin.',
        'Farklı dersleri veya aynı dersin farklı ünitelerini dönüşümlü çalışın (20 dk Tarih, 20 dk Coğrafya, tekrar Tarih).',
      ],
      benefits: [
        'Beyni sürekli uyanık tutar.',
        'Hangi problemin hangi teknikle çözüleceğini ayırt etme (discrimination) becerisini geliştirir.',
        'Sınav simülasyonuna daha yakındır (Sınavda sorular karışık gelir).',
      ],
      tips: [
        'Başlangıçta blok çalışmadan daha zor ve yavaş hissettirebilir, bu öğrenmenin gerçekleştiğinin işaretidir. Pes etmeyin.',
      ],
    ),
    StudyTechnique(
      id: 'cornell-notes',
      title: 'Cornell Not Tutma Sistemi',
      category: 'examFastLearning',
      shortDescription: 'Not almayı, tekrarı ve özeti tek sayfada birleştirin.',
      fullDescription:
          'Walter Pauk tarafından geliştirilen bu sistem, not almayı, tekrarı ve özeti tek sayfada birleştirir. Sınav haftası için mükemmel bir kaynak oluşturur.',
      steps: [
        'Kağıdı ters bir "T" şeklinde bölün:',
        'Sağ Geniş Sütun (Notlar): Derste hocanın anlattıklarını ana hatlarıyla buraya yazın.',
        'Sol Dar Sütun (İpuçları): Sağdaki notlarla ilgili anahtar kelimeleri veya potansiyel sınav sorularını buraya yazın.',
        'Alt Kısım (Özet): Sayfanın en altına, tüm sayfanın 2-3 cümlelik özetini yazın.',
        'Tekrar yaparken sağ tarafı kapatıp sadece soldaki sorulara bakarak konuyu anlatmaya çalışın.',
      ],
      benefits: [
        'Notları daha sonra çalışılabilir bir formata sokar.',
        'Ders sırasında aktif dinlemeyi sağlar.',
        'Özet kısmı, konunun ana fikrini yakalamanıza yardımcı olur.',
      ],
      tips: [
        'Ders biter bitmez (henüz sıcakken) sol sütunu ve özeti doldurun.',
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
      shortDescription: '25 dakika çalış, 5 dakika mola.',
      fullDescription:
          'Pomodoro Tekniği, Francesco Cirillo tarafından geliştirilen bir yöntemdir. Çalışma sürelerini kısa aralıklara bölerek odaklanmayı artırır ve yorgunluğu önler.',
      steps: [
        'Bir görev seç.',
        'Zamanlayıcıyı 25 dakikaya ayarla (bir "Pomodoro").',
        'Kesintisiz çalış.',
        'Zaman dolunca 5 dakika mola ver.',
        'Dört Pomodoro\'dan sonra 15-30 dakika uzun mola al.',
      ],
      benefits: [
        'Odaklanmayı artırır ve ertelemeyi azaltır.',
        'Verimliliği yükseltir, zihinsel yorgunluğu önler.',
        'Günlük ilerlemeyi takip etmeyi kolaylaştırır.',
      ],
      tips: [
        'Zamanlayıcı olarak telefon uygulamalarını kullan.',
        'Molalarda ayağa kalk ve hareket et.',
        'Görevleri küçük parçalara ayırarak başla.',
      ],
    ),
    StudyTechnique(
      id: 'eisenhower-matrix',
      title: 'Eisenhower Matrisi',
      category: 'timeManagement',
      shortDescription: 'Acil ve önemli olanı ayır.',
      fullDescription:
          'Dwight D. Eisenhower\'dan esinlenen bu matris, görevleri aciliyet ve önem derecesine göre sınıflandırarak önceliklendirme yapar.',
      steps: [
        'Görevlerini listele.',
        'Her görevi acil/önemli, acil/değil önemli, önemli/acil değil, ne acil ne önemli olarak dört kadrana ayır.',
        'Acil ve önemli olanları hemen yap.',
        'Önemli ama acil olmayanları planla.',
        'Diğerlerini devret veya sil.',
      ],
      benefits: [
        'Karar verme sürecini hızlandırır.',
        'Stresi azaltır ve önemli işlere odaklanmayı sağlar.',
        'Zamanı boşa harcayan görevleri ortadan kaldırır.',
      ],
      tips: [
        'Matrisi bir kağıt veya uygulama (örneğin Trello) ile çiz.',
        'Haftalık gözden geçirme yap.',
        '"Acil" ile "önemli"yi karıştırmamaya dikkat et.',
      ],
    ),
    StudyTechnique(
      id: 'time-blocking',
      title: 'Zaman Bloklama',
      category: 'timeManagement',
      shortDescription: 'Günü belirli bloklara ayır.',
      fullDescription:
          'Zaman Bloklama, günü belirli bloklara ayırarak her bloğa bir aktivite atama yöntemidir. Takvim gibi çalışır.',
      steps: [
        'Gününü saatlik bloklara böl.',
        'Her bloğa bir görev veya aktivite ata (örneğin 9-11 arası e-posta).',
        'Bloklar arasında tampon zaman bırak.',
        'Gün sonunda planı gözden geçir ve ayarla.',
      ],
      benefits: [
        'Günün yapısını sağlar ve dağılmayı önler.',
        'Dengeli bir yaşam için iş-dinlenme dengesi kurar.',
        'Verimliliği artırır ve beklenmedik işleri yönetir.',
      ],
      tips: [
        'Google Calendar gibi araçlar kullan.',
        'Esnek ol, her bloğu katı tutma.',
        'Blokları renk kodlayarak görselleştir.',
      ],
    ),
    StudyTechnique(
      id: 'pareto-principle',
      title: 'Pareto Prensibi (80/20 Kuralı)',
      category: 'timeManagement',
      shortDescription: 'Sonuçların %80\'i çabaların %20\'sinden gelir.',
      fullDescription:
          'Vilfredo Pareto\'dan gelen bu prensip, sonuçların %80\'inin çabaların %20\'sinden geldiğini savunur. En etkili görevlere odaklanmayı teşvik eder.',
      steps: [
        'Görevlerini listele.',
        'Hangi %20\'lik kısmın %80 sonuç verdiğini belirle.',
        'Bu görevlere öncelik ver.',
        'Düşük etkili olanları azalt veya ortadan kaldır.',
      ],
      benefits: [
        'Zamanı en değerli işlere harcar.',
        'Verimliliği maksimize eder ve gereksiz çabayı azaltır.',
        'Uzun vadeli başarıyı artırır.',
      ],
      tips: [
        'Günlük raporlarla %20\'yi takip et.',
        'Analiz için araçlar (örneğin Excel) kullan.',
        'Prensibi hem iş hem kişisel hayatta uygula.',
      ],
    ),
    StudyTechnique(
      id: 'gtd',
      title: 'Getting Things Done (GTD)',
      category: 'timeManagement',
      shortDescription: 'Zihni boşalt, sisteme güven.',
      fullDescription:
          'David Allen\'ın yöntemi olan GTD, görevleri beyinden dışarı aktararak zihni rahatlatır ve sistematik bir süreç izler.',
      steps: [
        'Tüm görevleri topla (yakalama).',
        'Her birini netleştir (ne yapılmalı?).',
        'Organize et (listeler, takvimler).',
        'Gözden geçir (haftalık inceleme).',
        'Uygula (yap, devret, ertele).',
      ],
      benefits: [
        'Zihinsel yükü azaltır ve yaratıcılığı artırır.',
        'Kaosu kontrol altına alır.',
        'Uzun vadeli hedeflere ulaşmayı kolaylaştırır.',
      ],
      tips: [
        'Todoist veya Evernote gibi uygulamalar kullan.',
        'Haftalık incelemeyi atlama.',
        'Görevleri 2 dakikadan kısa olanları hemen yap.',
      ],
    ),
    StudyTechnique(
      id: 'eat-that-frog',
      title: 'Kurbağayı Ye (Eat the Frog)',
      category: 'timeManagement',
      shortDescription: 'En zor işi günün başında yap.',
      fullDescription:
          'Mark Twain\'den esinlenen bu yöntem, en zor veya istenmeyen görevi güne başlarken yaparak momentum kazanmayı hedefler.',
      steps: [
        'Günün en zor görevini belirle ("kurbağa").',
        'Sabah ilk iş olarak onu yap.',
        'Tamamlandıktan sonra diğer görevlere geç.',
      ],
      benefits: [
        'Ertelemeyi önler ve motivasyonu artırır.',
        'Günün kalanını daha hafif geçirir.',
        'Başarı hissi yaratır ve üretkenliği yükseltir.',
      ],
      tips: [
        'Kurbağayı önceki akşam belirle.',
        'Görevi küçük adımlara böl.',
        'Ödül sistemi ekle (tamamlanınca kahve molası).',
      ],
    ),
    StudyTechnique(
      id: 'abc-method',
      title: 'ABC Yöntemi',
      category: 'timeManagement',
      shortDescription: 'Görevleri A, B, C olarak önceliklendir.',
      fullDescription:
          'Görevleri A (çok önemli), B (önemli), C (az önemli) olarak sınıflandıran basit bir önceliklendirme tekniğidir. Hızlı ve kolay uygulanır.',
      steps: [
        'Görev listesi oluştur.',
        'Her göreve A, B veya C etiketi ver.',
        'A\'ları hemen, B\'leri planlayarak, C\'leri boş zamanda yap.',
        'Listeyi günlük güncelle.',
      ],
      benefits: [
        'Hızlı ve kolay uygulanır.',
        'Öncelikleri netleştirir ve zamanı optimize eder.',
        'Stresi azaltır ve odaklanmayı sağlar.',
      ],
      tips: [
        'A görevlerini en fazla 3-5 ile sınırla.',
        'Kağıt kalem veya basit not uygulamaları kullan.',
        'C görevlerini devretmeyi düşün.',
      ],
    ),
    StudyTechnique(
      id: 'kanban',
      title: 'Kanban Yöntemi',
      category: 'timeManagement',
      shortDescription: 'Görsel tahta ile iş akışını yönet.',
      fullDescription:
          'Toyota\'dan gelen görsel bir sistem olan Kanban, görevleri "Yapılacak", "Yapılıyor", "Yapıldı" sütunlarında yönetir. İlerlemeyi görselleştirir.',
      steps: [
        'Bir tahta oluştur (fiziksel veya dijital).',
        'Görevleri kartlara yaz.',
        'Kartları sütunlar arasında taşı (ilerledikçe).',
        'Akışı izle ve tıkanıklıkları gider.',
      ],
      benefits: [
        'İlerlemeyi görselleştirir ve motivasyonu artırır.',
        'Ekip çalışmaları için idealdir.',
        'Esneklik sağlar ve aşırı yüklenmeyi önler.',
      ],
      tips: [
        'Trello veya Microsoft Planner gibi araçlar kullan.',
        'Sütunlara limit koy (örneğin "Yapılıyor"da en fazla 3 kart).',
        'Haftalık tahtayı temizle.',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. NOT & HAFIZA TEKNİKLERİ
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<StudyTechnique> _noteMemory = [
    StudyTechnique(
      id: 'mind-mapping',
      title: 'Zihin Haritası (Mind Mapping)',
      category: 'noteMemory',
      shortDescription: 'Doğrusal not almanın aksine, beynin doğal çalışma şekli.',
      fullDescription:
          'Tony Buzan tarafından popülerleştirilen bu yöntem, doğrusal not almanın (alt alta yazmanın) aksine, beynin doğal çalışma şekli olan çağrışımsal ve dairesel düşünmeyi taklit eder.',
      steps: [
        'Kağıdın tam ortasına ana konuyu veya fikri yazın/çizin.',
        'Ana konudan dışarıya doğru ana dallar (ana başlıklar) çıkarın.',
        'Bu dallardan daha ince alt dallar (detaylar) çıkarın.',
        'Bolca renk, sembol ve anahtar kelime kullanın (uzun cümleler değil).',
      ],
      benefits: [
        'Büyük resmi tek sayfada görmeyi sağlar.',
        'Sağ ve sol beyni aynı anda çalıştırır.',
        'Yeni fikirler üretmeyi ve yaratıcılığı tetikler.',
      ],
      tips: [
        'Kağıdı yatay kullanın.',
        'Her dal için farklı bir renk kullanmak görsel hafızayı güçlendirir.',
      ],
    ),
    StudyTechnique(
      id: 'zettelkasten-method',
      title: 'Zettelkasten Yöntemi (Kutu Sistemi)',
      category: 'noteMemory',
      shortDescription: '"İkinci Beyin" olarak bilinen bilgi yönetim sistemi.',
      fullDescription:
          'Üretken sosyolog Niklas Luhmann\'ın 70 kitap ve 400 makale yazmasını sağlayan, "atomik notlar" prensibine dayanan bir bilgi yönetim sistemidir.',
      steps: [
        'Geçici Notlar: Aklınıza gelen fikirleri hızlıca karalayın.',
        'Literatür Notları: Okuduğunuz kaynaktan kendi cümlelerinizle kısa notlar alın.',
        'Kalıcı Notlar (Atomik): Tek bir fikri içeren, başlığı olan, kendi başına anlamlı kartlar oluşturun.',
        'Bağlantı Kurma: Bu kartı, sistemdeki diğer ilgili kartlarla (notlarla) ilişkilendirin/numaralandırın.',
      ],
      benefits: [
        'Bilgiler arasında beklenmedik bağlantılar kurmanızı sağlar.',
        'Notlarınızın "çöplüğe" dönüşmesini engeller, bir bilgi ağı oluşturur.',
        'Yazarlar ve araştırmacılar için fikir üretimini otomatiğe bağlar.',
      ],
      tips: [
        'Dijital uygulamalar (Obsidian, Roam Research) bu yöntem için idealdir.',
        'Her notun "tek bir fikri" savunduğundan emin olun.',
      ],
    ),
    StudyTechnique(
      id: 'chunking-memory',
      title: 'Chunking (Parçalara Bölme)',
      category: 'noteMemory',
      shortDescription: 'Kısa süreli hafızanızın kapasitesini aşmak için gruplama.',
      fullDescription:
          'Kısa süreli hafızamızın sınırlı kapasitesini (genellikle 4 ila 7 birim) aşmak için kullanılan bir gruplama yöntemidir. Beyin, parçaları tek bir "birim" olarak algılayarak kapasiteyi artırır.',
      steps: [
        'Ezberlenecek uzun bilgi bütününü alın (Örn: 11 haneli bir sayı veya uzun bir liste).',
        'Bunları anlamlı küçük gruplara bölün.',
        'Örnek: "05321234567" yerine "0532 - 123 - 45 - 67" şeklinde gruplayın.',
      ],
      benefits: [
        'Hafızanın işlem kapasitesini anında artırır.',
        'Karmaşık bilgilerin daha kolay işlenmesini sağlar.',
        'Öğrenme hızını artırır.',
      ],
      tips: [
        'Kelimeleri kategorilerine göre gruplayın (Örn: Alışveriş listesini "Sebzeler", "Temizlik" diye bölmek).',
      ],
    ),
    StudyTechnique(
      id: 'linking-method',
      title: 'Zincirleme Yöntemi (Linking Method)',
      category: 'noteMemory',
      shortDescription: 'Mekansız hafıza sarayı, tuhaf hikayelerle bağlama.',
      fullDescription:
          'Zihin Sarayı (Loci) yönteminin "mekansız" versiyonudur. Ezberlenecek maddeleri birbirine tuhaf hikayelerle bağlayarak bir zincir oluşturulur.',
      steps: [
        'Listenin 1. maddesi ile 2. maddesi arasında absürt bir görsel ilişki kurun.',
        'Sonra 2. madde ile 3. maddeyi bağlayın.',
        'Örnek: "Sabun, Ayı, Bal": "Sabunla yıkanan dev bir Ayı, üzerine dökülen Balı yiyor."',
      ],
      benefits: [
        'Mekana ihtiyaç duymadan sırasız listeleri ezberlemeyi sağlar.',
        'Yaratıcılığı geliştirir.',
        'Hatırlaması eğlencelidir.',
      ],
      tips: [
        'Hikayeler ne kadar saçma, korkunç veya tuhaf olursa akılda o kadar iyi kalır.',
        'Zincir koptuğunda diğer elemanlar kaybolabilir, bu yüzden bağları güçlü kurun.',
      ],
    ),
    StudyTechnique(
      id: 'dual-coding',
      title: 'Çift Kodlama (Dual Coding)',
      category: 'noteMemory',
      shortDescription: 'Sözel ve görsel bilgiyi aynı anda kullanarak öğrenmeyi güçlendirin.',
      fullDescription:
          'Allan Paivio\'nun teorisine göre beyin, sözel ve görsel bilgiyi farklı kanallarda işler. İkisini aynı anda kullanmak öğrenmeyi iki kat güçlendirir.',
      steps: [
        'Ders notlarınıza sadece yazı yazmayın.',
        'Yanına kavramı anlatan basit bir grafik, diyagram, zaman çizelgesi veya ikon çizin.',
        'Ders çalışırken metni okurken aynı zamanda o olayı zihninizde film gibi canlandırın.',
      ],
      benefits: [
        'Bilgiyi geri çağırmak için iki farklı "ipucu" (yazı ve resim) oluşturur.',
        'Soyut kavramları somutlaştırır.',
      ],
      tips: [
        'Ressam olmanıza gerek yok; çöp adam veya basit kutular yeterlidir.',
        'İnfografik incelemek bu teknikte ustalaşmanızı sağlar.',
      ],
    ),
    StudyTechnique(
      id: 'peg-system',
      title: 'Kanca Sistemi (Peg System)',
      category: 'noteMemory',
      shortDescription: 'Sıralı listeleri önceden zihne yerleştirilmiş kancalara asma.',
      fullDescription:
          'Sıralı listeleri (1. madde, 5. madde gibi) ezberlemek için önceden zihne yerleştirilmiş "kancalar" kullanılır. Genellikle kafiye veya şekil benzerliği kullanılır.',
      steps: [
        'Önce kancaları ezberleyin (Örn: 1-Bir-Kir, 2-İki-Tilk, 3-Üç-Güç... veya 1-Mum, 2-Kuğu, 3-Martı gibi şekilsel).',
        'Ezberlenecek bilgiyi bu kancaya asın.',
        'Örnek: 1. madde "Elma" ise, "Kirli bir Elma" hayal edin. 2. madde "Kalem" ise, "Kalem çalan bir Tilki" hayal edin.',
      ],
      benefits: [
        'Listenin sırasını karıştırmadan, örneğin direkt 7. maddeyi hatırlamanızı sağlar.',
        'Uzun süreli hafıza için çok güçlüdür.',
      ],
      tips: [
        'Kancalarınızı (1\'den 10\'a veya 20\'ye kadar) bir kez oluşturun ve ömür boyu aynılarını kullanın.',
      ],
    ),
    StudyTechnique(
      id: 'flow-based-note-taking',
      title: 'Akış Temelli Not Alma (Flow-Based Note Taking)',
      category: 'noteMemory',
      shortDescription: 'Dersi kelimesi kelimesine yazmak yerine, fikirleri akışkan şekilde dökme.',
      fullDescription:
          'Scott Young tarafından önerilen bu yöntem, dersi kelimesi kelimesine yazmak (transkripsiyon) yerine, fikirleri ve bağlantıları anında kağıda dökmeyi hedefler.',
      steps: [
        'Hocayı dinlerken "Burada ana fikir ne?" diye düşünün.',
        'Fikri kağıda kısa bir kelimeyle yazın.',
        'Yeni bir fikir geldiğinde, önceki fikirle nasıl bağlantılı olduğunu oklarla gösterin.',
        'Hiyerarşik bir liste değil, karmaşık bir ağ oluşturun.',
      ],
      benefits: [
        'Pasif dinlemeyi (duyduğunu yazmayı) engeller, aktif öğrenmeyi sağlar.',
        'Konunun mantığını ders esnasında çözmenize yardımcı olur.',
      ],
      tips: [
        'Bu notlar "dağınık" görünür, sonradan temize çekmek veya özetlemek gerekebilir.',
        'Zor ve kavramsal dersler için idealdir, tarih gibi olgusal dersler için zor olabilir.',
      ],
    ),
    StudyTechnique(
      id: 'charting-method',
      title: 'Tablo Yöntemi (Charting Method)',
      category: 'noteMemory',
      shortDescription: 'Karşılaştırma gerektiren verileri kategorize etme.',
      fullDescription:
          'Karşılaştırma gerektiren, çok fazla veri içeren konular için en düzenli not alma biçimidir. Cornell veya Zihin Haritasından farklı olarak, veriyi kategorize eder.',
      steps: [
        'Sayfayı sütunlara bölün.',
        'Sütun başlıklarına kategorileri yazın (Örn: Tarih, Önemli Kişiler, Olaylar, Sonuçlar).',
        'Ders boyunca ilgili bilgiyi ilgili kutucuğa yazın.',
      ],
      benefits: [
        'Bilgileri karşılaştırmayı (X ile Y arasındaki farklar nedir?) çok kolaylaştırır.',
        'Ezber yaparken görsel hafızayı destekler.',
        'Dağınık bilgiyi anında yapılandırır.',
      ],
      tips: [
        'Dersin formatını önceden biliyorsanız tabloyu dersten önce çizin.',
        'Sınavdan önce hızlı tekrar için mükemmeldir.',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. ODAKLANMA
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<StudyTechnique> _concentration = [
    StudyTechnique(
      id: 'deep-work',
      title: 'Derin Çalışma (Deep Work)',
      category: 'concentration',
      shortDescription: 'Dikkat dağıtıcıları yok et.',
      fullDescription:
          'Cal Newport tarafından popülerleştirilen bu kavram, bilişsel olarak talepkar görevleri, dikkat dağıtıcı unsurlar olmadan (sıfır kesintiyle) yapma becerisidir. Yüzeysel çalışmanın tam tersidir.',
      steps: [
        'Çalışma takviminize 2-4 saatlik "Derin Çalışma" blokları koyun.',
        'Bu süre zarfında interneti, telefonu ve bildirimleri tamamen kapatın.',
        'Kendinizi izole edin (kapıyı kilitleyin veya kütüphaneye gidin).',
        'Beyninizi zorlayan tek bir yeteneğe veya projeye odaklanın.',
      ],
      benefits: [
        'Karmaşık bilgileri daha hızlı öğrenmenizi sağlar.',
        'Daha az zamanda daha kaliteli iş üretirsiniz.',
        'Zihinsel kapasitenin sınırlarını genişletir.',
      ],
      tips: [
        'Derin çalışmaya geçiş için bir ritüel belirleyin (örneğin kahve almak ve ışığı ayarlamak).',
        'Başlangıçta 1 saat ile başlayıp süreyi yavaşça artırın (beyin kası gibidir).',
      ],
    ),
    StudyTechnique(
      id: 'distraction-parking-lot',
      title: 'Park Yeri Tekniği (Distraction Parking Lot)',
      category: 'concentration',
      shortDescription: 'Aklınıza gelen fikirleri not ederek dikkati koru.',
      fullDescription:
          'Çalışırken aklınıza gelen alakasız düşünceleri veya yapılması gereken işleri, o anki odağınızı bozmadan yönetme yöntemidir. İçsel kesintileri kontrol altına alır.',
      steps: [
        'Yanınızda boş bir kağıt veya not defteri bulundurun (Dijital değil, analog olması daha iyidir).',
        'Çalışırken aklınıza "Faturayı öde", "X\'i ara", "Acaba hava nasıl?" gibi bir düşünce gelirse;',
        'Bunu hemen kağıda yazın ("Park edin").',
        'Düşünceyi zihninizden atıp hemen işinize dönün.',
      ],
      benefits: [
        'Aklınıza gelen fikirleri unutma korkusunu yok eder.',
        'Dikkatin tamamen dağılmasını ve başka sekmelere geçişi engeller.',
        'Çalışma bitiminde elinizde hazır bir yapılacaklar listesi olur.',
      ],
      tips: [
        'Bu listeyi sadece çalışma bloğunuz bittiğinde gözden geçirin.',
        'Google aramalarını bile buraya yazın, hemen aramayın.',
      ],
    ),
    StudyTechnique(
      id: 'body-doubling',
      title: 'Body Doubling (Eşlikçi Yöntemi)',
      category: 'concentration',
      shortDescription: 'Yanınızda başka biriyle odaklanmayı artır.',
      fullDescription:
          'Genellikle DEHB (Dikkat Eksikliği ve Hiperaktivite Bozukluğu) yönetiminde kullanılan bu yöntem, yanınızda başka birinin varlığıyla odaklanmayı sağlar. O kişi işe karışmaz, sadece orada "bulunur".',
      steps: [
        'Çalışan veya kitap okuyan bir arkadaşınızı bulun (Fiziksel veya online kamera ile).',
        'Birbirinize ne üzerinde çalışacağınızı söyleyin.',
        'Sessizce kendi işlerinize odaklanın.',
        'Başkası sizi izliyor veya yanınızda çalışıyor hissiyle göreve sadık kalın.',
      ],
      benefits: [
        'Sosyal sorumluluk hissiyle kaytarmanızı engeller.',
        'Yalnızlık hissini ve çalışma sıkıntısını azaltır.',
        'Ortama ciddiyet katar.',
      ],
      tips: [
        '"Focusmate" gibi online platformları kullanabilirsiniz.',
        'Eşlikçinizle sohbet etmeyin, sadece molalarda konuşun.',
      ],
    ),
    StudyTechnique(
      id: 'ultradian-rhythms',
      title: 'Ultradiyen Ritimler',
      category: 'concentration',
      shortDescription: '90 dakikalık doğal odaklanma döngülerini kullan.',
      fullDescription:
          'Pomodoro\'nun (25 dk) aksine, bu yöntem vücudun doğal biyolojik saatine dayanır. İnsan beyni genellikle 90 dakikalık yüksek odaklanma döngüleriyle çalışır.',
      steps: [
        '90 dakika boyunca kesintisiz çalışın (Zihinsel enerjinin zirve yaptığı süre).',
        'Ardından 20 dakika tam dinlenme yapın (Ekran yok, sadece dinlenme).',
        'Bu döngüyü gün içinde enerjinize göre tekrarlayın.',
      ],
      benefits: [
        'Biyolojik saatinizle uyumlu olduğu için tükenmişliği (burnout) önler.',
        'Derinlemesine odaklanma için yeterli uzunlukta süre tanır.',
        'Enerji yönetimini optimize eder.',
      ],
      tips: [
        'Bu yöntemi sabahın en verimli saatlerinde uygulayın.',
        '20 dakikalık molada mutlaka beyin aktivitesini düşürün (yürüyüş, nefes egzersizi).',
      ],
    ),
    StudyTechnique(
      id: 'box-breathing',
      title: 'Kutu Nefesi (Box Breathing)',
      category: 'concentration',
      shortDescription: 'Navy SEALs\'ların stresli anlarda kullandığı nefes tekniği.',
      fullDescription:
          'Navy SEALs (Amerikan Donanması Özel Kuvvetleri) tarafından stresli anlarda odaklanmak ve sakinleşmek için kullanılan fizyolojik bir yöntemdir. Dağınık zihni anında "şimdiye" getirir.',
      steps: [
        '4 saniye boyunca burnunuzdan yavaşça nefes alın.',
        '4 saniye boyunca nefesinizi tutun.',
        '4 saniye boyunca ağzınızdan yavaşça nefes verin.',
        '4 saniye boyunca nefessiz bekleyin.',
        'Bu döngüyü 4-5 kez tekrarlayın.',
      ],
      benefits: [
        'Parasempatik sinir sistemini aktive ederek stresi düşürür.',
        'Beyne giden oksijeni düzenler ve zihinsel berraklık sağlar.',
        'Çalışmaya başlamadan önce "başlatma butonu" işlevi görür.',
      ],
      tips: [
        'Odaklanmakta zorlandığınız anlarda veya zor bir göreve başlarken yapın.',
        'Sayarken sadece sayıya odaklanın.',
      ],
    ),
    StudyTechnique(
      id: 'neuro-architecture',
      title: 'Ortam Tasarımı (Neuro-Architecture)',
      category: 'concentration',
      shortDescription: 'Çevrenizi odaklanmayı zorunlu kılacak şekilde düzenleyin.',
      fullDescription:
          'İrade gücüne güvenmek yerine, çevrenizi odaklanmayı zorunlu kılacak şekilde düzenleme sanatıdır. "Sürtünme" prensibini kullanır.',
      steps: [
        'Sürtünmeyi Artırın: Telefonu başka odaya koyun, oyun konsolunun fişini çekin, sosyal medya uygulamalarına şifre koyun (ulaşması zor olsun).',
        'Sürtünmeyi Azaltın: Kitabı masanın üzerine açık bırakın, suyunuzu hazırlayın, çalışma dosyasını ekranda açık tutun (başlaması kolay olsun).',
        'Sadece çalışmak için kullanılan bir köşe veya masa lambası belirleyin.',
      ],
      benefits: [
        'İrade gücünüzü harcamadan odaklanmanızı sağlar.',
        'Beyniniz belirli nesneleri (örneğin o özel lambayı) çalışmakla ilişkilendirir (Klasik koşullanma).',
        'Başlama ertelemesini minimize eder.',
      ],
      tips: [
        'Masada sadece o anki işle ilgili nesneler kalsın.',
        'Işıklandırmayı iyi ayarlayın; loş ışık uykuyu, parlak beyaz ışık odaklanmayı tetikler.',
      ],
    ),
    StudyTechnique(
      id: 'binaural-beats',
      title: 'Binaural Beats (İşitsel Odaklanma)',
      category: 'concentration',
      shortDescription: 'Beyin dalgalarını seslerle senkronize ederek odaklanma.',
      fullDescription:
          'Beyin dalgalarını belirli frekanslarla senkronize etmek için ses teknolojisinin kullanılmasıdır. Farklı frekanslar farklı zihinsel durumları tetikler.',
      steps: [
        'Kulaklık takın (Stereo olması şarttır).',
        'Odaklanmak için 40 Hz (Gamma) veya 14-30 Hz (Beta) dalgaları içeren ses dosyaları açın.',
        'Arka planda kısık sesle çalarken çalışmaya başlayın.',
      ],
      benefits: [
        'Dış gürültüyü maskeler.',
        'Beyni "odaklanma moduna" girmesi için biyolojik olarak uyarır.',
        'Zihinsel yorgunluğu azaltabilir.',
      ],
      tips: [
        'Sözlü müzikler dinlemeyin, sözler beynin dil merkezini meşgul eder.',
        'YouTube veya Spotify\'da "Focus Music", "Binaural Beats for Concentration" şeklinde aratın.',
      ],
    ),
    StudyTechnique(
      id: 'digital-minimalism',
      title: 'Dijital Minimalizm (Gri Tonlama Modu)',
      category: 'concentration',
      shortDescription: 'Akıllı cihazların ödül mekanizmasını kırmak için gri tonlama.',
      fullDescription:
          'Akıllı cihazların ödül mekanizmasını kırmak için kullanılan bir yöntemdir. Renkli ikonlar beyni uyarır, gri tonlama ise bu cazibeyi yok eder.',
      steps: [
        'Telefonunuzun "Erişilebilirlik" ayarlarından ekranı "Gri Tonlama" (Grayscale) veya Siyah-Beyaz moduna alın.',
        'Bildirimlerin "önizleme" özelliğini kapatın.',
        'Ana ekranınızda sadece araçlar (takvim, notlar, harita) kalsın; sosyal medya uygulamalarını klasörlere gömün.',
      ],
      benefits: [
        'Telefonu elinize aldığınızda aldığınız dopamin hazzını düşürür.',
        'Ekranın sıkıcı görünmesi, telefonda geçirilen süreyi ve dikkat dağılmasını azaltır.',
        'Bilinçsiz kaydırma (doomscrolling) alışkanlığını kırar.',
      ],
      tips: [
        'Çalışma saatlerinde bu modu mutlaka aktif tutun.',
        'Sadece fotoğraflara bakacağınız zaman renkli moda geçin, sonra hemen kapatın.',
      ],
    ),
  ];

  static const List<StudyTechnique> _studyPlanning = [
    StudyTechnique(
      id: 'ivy-lee-method',
      title: 'Ivy Lee Metodu',
      category: 'studyPlanning',
      shortDescription: '100 yıllık geçmişe sahip günlük planlama tekniği.',
      fullDescription:
          '100 yıllık bir geçmişe sahip olan bu yöntem, sadeliği ve karar yorgunluğunu ortadan kaldırmasıyla bilinir. Günlük planlama için en net tekniklerden biridir.',
      steps: [
        'Her iş gününün sonunda, yarın yapmanız gereken en önemli 6 görevi yazın (6\'dan fazla olmamalı).',
        'Bu 6 görevi önem sırasına göre dizin.',
        'Ertesi gün sadece ilk göreve odaklanın. O bitmeden ikinciye geçmeyin.',
        'Gün bittiğinde bitmeyen işleri yarının listesine aktarın ve süreci tekrarlayın.',
      ],
      benefits: [
        '"Nereden başlasam?" sorusunu ortadan kaldırır.',
        'Çoklu görev (multitasking) hatasına düşmeyi engeller.',
        'Basit olduğu için sürdürülebilirliği yüksektir.',
      ],
      tips: [
        'Listeyi mutlaka bir önceki akşamdan hazırlayın, sabah değil.',
        '6 madde kuralına sadık kalın, listeyi şişirmeyin.',
      ],
    ),
    StudyTechnique(
      id: 'moscow-analysis',
      title: 'MoSCoW Analizi',
      category: 'studyPlanning',
      shortDescription: 'Görevleri katı bir süzgeçten geçirerek önceliklendir.',
      fullDescription:
          'Genellikle proje yönetiminde kullanılan bu teknik, yapılacaklar listesini katı bir süzgeçten geçirerek önceliklendirir. Eisenhower matrisinden farklı olarak, yapılması gerekenler ile istenilenler arasındaki çizgiyi çizer.',
      steps: [
        'M (Must have): Kesinlikle yapılmalı, olmazsa proje/gün başarısız olur.',
        'S (Should have): Yapılmalı, ama yapılmazsa dünya yıkılmaz (alternatifi vardır).',
        'C (Could have): Yapılsa iyi olur, ama şart değil (bonus görevler).',
        'W (Won\'t have): Şimdilik yapılmayacaklar (bilerek elediğiniz işler).',
      ],
      benefits: [
        'Beklentileri yönetmeyi sağlar.',
        'Zaman darlığında hangi görevden vazgeçileceğini önceden belirler.',
        'Gereksiz mükemmeliyetçiliği önler.',
      ],
      tips: [
        'Listenizin %60\'ından fazlasını "Must" (Zorunlu) kategorisine koymayın.',
        'Ekip çalışmalarında ortak anlayış için çok etkilidir.',
      ],
    ),
    StudyTechnique(
      id: 'one-three-five-rule',
      title: '1-3-5 Kuralı',
      category: 'studyPlanning',
      shortDescription: 'Günlük yapılacaklar listesinin kapasitesini sınırlayarak gerçekçi planlama.',
      fullDescription:
          'Günlük yapılacaklar listesinin kapasitesini sınırlayarak gerçekçi bir planlama sunan yöntemdir. Enerji yönetimi temellidir.',
      steps: [
        'Gününüzü planlarken sadece şu kontenjanları doldurun:',
        '1 Büyük İş: Çok efor gerektiren ana görev.',
        '3 Orta İş: Yarım saat veya bir saat sürebilecek görevler.',
        '5 Küçük İş: Hızlıca halledilebilecek ufak işler (e-posta, randevu alma vb.).',
      ],
      benefits: [
        'Günün sonunda "her şeyi bitiremedim" suçluluğunu önler.',
        'Zor ve kolay işleri dengeli bir şekilde dağıtır.',
        'Esneklik sağlar.',
      ],
      tips: [
        'Büyük işi, enerjinizin en yüksek olduğu saate koyun.',
        'Beklenmedik işler çıkarsa, listeden eşit büyüklükte bir işi silin veya erteleyin.',
      ],
    ),
    StudyTechnique(
      id: 'reverse-engineering',
      title: 'Geriye Doğru Planlama (Reverse Engineering)',
      category: 'studyPlanning',
      shortDescription: 'Planlamayı son teslim tarihinden başlayarak geriye doğru yap.',
      fullDescription:
          'Planlamayı bugünden değil, son teslim tarihinden (deadline) başlatarak geriye doğru gelme yöntemidir.',
      steps: [
        'Projenin bitiş tarihini belirleyin.',
        'Sonuçtan bir önceki adımın ne olması gerektiğini yazın.',
        'Adım adım geriye gelerek bugüne kadar ulaşın.',
        'Bugün yapmanız gereken "ilk adımı" bu şekilde tespit edin.',
      ],
      benefits: [
        'Son teslim tarihini kaçırma riskini minimize eder.',
        'Gerçekçi olmayan zaman tahminlerini ortaya çıkarır.',
        'Projenin eksik parçalarını erkenden görmenizi sağlar.',
      ],
      tips: [
        'Her aşama için "tampon süre" eklemeyi unutmayın.',
        'Özellikle uzun vadeli (aylık/yıllık) projeler için idealdir.',
      ],
    ),
    StudyTechnique(
      id: 'okr',
      title: 'OKR (Objectives and Key Results)',
      category: 'studyPlanning',
      shortDescription: 'Sadece "ne" yapılacağını değil, başarının "nasıl" ölçüleceğini planlar.',
      fullDescription:
          'Google ve Intel gibi devlerin kullandığı bu sistem, sadece "ne" yapılacağını değil, başarının "nasıl" ölçüleceğini de planlar. Kişisel planlamaya da uyarlanabilir.',
      steps: [
        'Objective (Hedef): Nereye gitmek istiyorum? (İlham verici, niteliksel). Örn: "İngilizce konuşma becerimi profesyonel seviyeye taşımak."',
        'Key Results (Anahtar Sonuçlar): Oraya vardığımı nasıl anlarım? (Ölçülebilir, sayısal). Örn: "1. TOEFL\'dan 100 almak. 2. Haftada 3 kez yabancılarla konuşma pratiği yapmak."',
      ],
      benefits: [
        'Sadece meşgul olmayı değil, sonuç almayı hedefler.',
        'Büyük resmi görmeyi sağlar.',
        'İlerlemeyi net rakamlarla takip ettirir.',
      ],
      tips: [
        'Hedefleri (Objective) az sayıda tutun (en fazla 3).',
        'Her hedef için 3-4 anahtar sonuç belirleyin.',
      ],
    ),
    StudyTechnique(
      id: 'bullet-journal',
      title: 'Bullet Journal Sistemi',
      category: 'studyPlanning',
      shortDescription: 'Dijital araçlar yerine kağıt-kalem kullanılan bütüncül analog sistem.',
      fullDescription:
          'Ryder Carroll tarafından geliştirilen, dijital araçlar yerine kağıt-kalem kullanılan, geçmişi takip edip geleceği planlayan bütüncül bir analog sistemdir.',
      steps: [
        'Boş bir defter edinin.',
        'Index: İçindekiler bölümü oluşturun.',
        'Future Log: Gelecek aylar için genel plan sayfası yapın.',
        'Monthly/Daily Log: Aylık ve günlük görevleri, simgelerle (görev için nokta, olay için daire vb.) listeleyin.',
        'Tamamlanmayan görevleri bir sonraki güne/aya "göç ettirin" (migration).',
      ],
      benefits: [
        'Dijital dikkat dağınıklığından uzaklaştırır.',
        'Planlama yaparken aynı zamanda günlük tutmanızı sağlar (Mindfulness etkisi).',
        'Kişiselleştirilebilir; çizimler, tablolar eklenebilir.',
      ],
      tips: [
        'Süslü çizimlere takılmayın, sistemin işlevselliğine odaklanın.',
        '"Göç ettirme" (erteleme) işlemi sırasında, o görevin gerçekten gerekli olup olmadığını sorgulayın.',
      ],
    ),
    StudyTechnique(
      id: 'rpm',
      title: 'RPM (Rapid Planning Method)',
      category: 'studyPlanning',
      shortDescription: 'Tony Robbins\'in geliştirdiği, "Sonuç-Amaç-Eylem" sistemi.',
      fullDescription:
          'Tony Robbins\'in geliştirdiği bu yöntem, sadece yapılacaklar listesi oluşturmayı değil, o işin arkasındaki "amacı" bulmayı hedefler. "Result-Purpose-Massive Action" (Sonuç-Amaç-Eylem) açılımıdır.',
      steps: [
        'Result (Sonuç): Ne elde etmek istiyorum? (Net vizyon).',
        'Purpose (Amaç): Bunu neden istiyorum? (Güçlü bir "neden" motivasyonu tetikler).',
        'Massive Action Plan (MAP): Oraya ulaşmak için hangi eylemleri yapmalıyım?',
      ],
      benefits: [
        'Angarya işlerden ziyade, hayatınıza değer katan işlere odaklanmanızı sağlar.',
        'Motivasyon düştüğünde "neden" sorusuna cevap vererek sizi yolda tutar.',
        'Duygusal bağ kurdurur.',
      ],
      tips: [
        'Kağıdınızı üç sütuna bölün (Sonuç | Amaç | Eylem Planı).',
        'Özellikle "neden" kısmını detaylandırın; yakıtınız orasıdır.',
      ],
    ),
    StudyTechnique(
      id: 'agile-personal-planning',
      title: 'Sprint (Çevik/Agile) Kişisel Planlama',
      category: 'studyPlanning',
      shortDescription: 'Yazılım dünyasındaki Scrum metodolojisinin kişisel hayata uyarlanması.',
      fullDescription:
          'Yazılım dünyasındaki Scrum metodolojisinin kişisel hayata uyarlanmasıdır. Yılı 12 aya değil, kısa döngülere (sprintlere) bölerek planlama yapılır.',
      steps: [
        'Sprint Planlama: Önünüzdeki 1 veya 2 hafta için hedefleri belirleyin.',
        'Uygulama: Sadece bu süreye odaklanın, diğer her şeyi arka plana atın.',
        'Review (Gözden Geçirme): Sprint sonunda ne kadarını yaptığınızı kontrol edin.',
        'Retrospective (Geriye Bakış): Süreçte neyin iyi gittiğini, neyin kötü gittiğini analiz edip sonraki sprinti iyileştirin.',
      ],
      benefits: [
        'Hızlı adaptasyon sağlar; çalışmayan planı 1 yıl sonra değil 1 hafta sonra fark edersiniz.',
        'Düzenli iyileştirme kültürü oluşturur.',
        'Uzun vadeli hedeflerin yarattığı baskıyı azaltır.',
      ],
      tips: [
        'Sprint süresini sabit tutun (örneğin hep Pazar akşamı planlayıp Cuma bitirin).',
        'Bitmemiş işleri bir sonraki sprinte otomatik aktarmayın, tekrar değerlendirin.',
      ],
    ),
  ];

  static const List<StudyTechnique> _motivation = [
    // MOTİVASYON TEKNİKLERİ
    StudyTechnique(
      id: 'smart-goals',
      title: 'SMART Hedefler',
      category: 'motivation',
      shortDescription: 'Belirsizliği yok et.',
      fullDescription:
          'Peter Drucker\'ın yönetim felsefesinden doğan bu yöntem, motivasyonun belirsizlikten kaybolmasını önler. Hedefleri somut ve ulaşılabilir hale getirerek harekete geçme isteğini tetikler.',
      steps: [
        'S (Specific): Hedefini net tanımla (Örn: "3 konu bitireceğim").',
        'M (Measurable): İlerlemeyi ölçülebilir kıl (Sayısal veri).',
        'A (Achievable): Gerçekçi ol, ulaşılabilir hedef seç.',
        'R (Relevant): Hedefin uzun vadeli planınla ilgili olsun.',
        'T (Time-bound): Son tarih belirle (Deadline etkisi).',
      ],
      benefits: [
        'Zihinsel netlik sağlar.',
        'Başarı hissini somutlaştırır.',
        'Yol haritası çizerek kaybolmayı önler.',
      ],
      tips: [
        'Hedefleri mutlaka yazılı hale getir.',
        'Çok büyük hedefleri küçük SMART parçalarına böl.',
      ],
    ),
    StudyTechnique(
      id: '5-second-rule',
      title: '5 Saniye Kuralı',
      category: 'motivation',
      shortDescription: 'Düşünme, harekete geç.',
      fullDescription:
          'Mel Robbins tarafından geliştirilen teknik. Beyin erteleme veya korku üretmeye başlamadan önce eyleme geçmeyi sağlayan bir "başlatma ritüeli"dir.',
      steps: [
        'Yapman gereken zor bir görevi fark et.',
        'İçinden geriye say: 5-4-3-2-1.',
        '"1" dediğin an roket gibi fırla ve harekete geç.',
        'Asla düşünmeye fırsat verme.',
      ],
      benefits: [
        'Analiz felcini (aşırı düşünmeyi) kırar.',
        'Cesaret ve özgüven kasını geliştirir.',
        'Ertelemeyi anında durdurur.',
      ],
      tips: [
        'Sayımı geriye doğru yap, bu beyni odaklar.',
        'Sabah yataktan kalkmakta zorlanıyorsan hemen dene.',
      ],
    ),
    StudyTechnique(
      id: 'seinfeld-chain',
      title: 'Zinciri Kırma (Seinfeld)',
      category: 'motivation',
      shortDescription: 'Süreci oyuna çevir.',
      fullDescription:
          'Komedyen Jerry Seinfeld\'in tekniği. Tutarlılık ve görsel ilerlemeye dayanır. Motivasyonu "süreci bozmama" dürtüsü üzerine kurar. Uygulamamızdaki "Streak" özelliği budur.',
      steps: [
        'Büyük bir duvar takvimi edin.',
        'Her gün hedefin için bir şey yap (Örn: 20 soru çöz).',
        'Görevi tamamlayınca takvime kocaman bir çarpı (X) at.',
        'Tek amaç: O X zincirini koparmamak.',
      ],
      benefits: [
        'İlerlemeyi somut ve görsel hale getirir.',
        'Alışkanlık kazanmayı oyunlaştırır.',
        '"Sadece bugünü kurtar" mantığıyla stresi azaltır.',
      ],
      tips: [
        'Zincir koptuğunda suçluluk duyma, hemen ertesi gün yenisini başlat.',
        'Görevi "asla yapamayacağın" kadar zor seçme.',
      ],
    ),
    StudyTechnique(
      id: 'woop-method',
      title: 'WOOP Tekniği',
      category: 'motivation',
      shortDescription: 'Engelleri önceden planla.',
      fullDescription:
          'Sadece pozitif düşünmek yetmez. Hayallerle gerçek engelleri zihinde karşılaştırarak (Mental Contrasting) gerçekçi bir motivasyon sağlar.',
      steps: [
        'Wish (Dilek): Ne istiyorsun?',
        'Outcome (Sonuç): En iyi sonucu hayal et.',
        'Obstacle (Engel): Seni ne durdurabilir? (Tembellik, telefon vb.)',
        'Plan: "Eğer [engel] çıkarsa, o zaman [şunu] yapacağım" diyerek planla.',
      ],
      benefits: [
        'Kuru iyimserlik yerine gerçekçi eylem planı sunar.',
        'Bilinçaltını çözüm üretmeye programlar.',
      ],
      tips: [
        'Bu işlemi 5 dakikalık sessiz bir sürede zihninde yap.',
      ],
    ),
    StudyTechnique(
      id: 'gamification',
      title: 'Oyunlaştırma (Gamification)',
      category: 'motivation',
      shortDescription: 'Hayatı bir RPG oyunu gibi oyna.',
      fullDescription:
          'Oyun tasarım öğelerinin (puanlar, seviyeler, ödüller) gerçek hayatta kullanılmasıdır. Sıkıcı görevleri eğlenceli hale getirerek dopamin salgılanmasını tetikler.',
      steps: [
        'Görevleri "Quest" olarak tanımla.',
        'Her görev için XP (Puan) belirle (Rapor = 100 XP).',
        'Puanlar birikince kendine gerçek ödül ver (Sinema, yemek).',
        'Kendi seviyeni takip et.',
      ],
      benefits: [
        'Sıkıcı işleri çekici hale getirir.',
        'Anında geri bildirim ve tatmin sağlar.',
      ],
      tips: [
        'Ceza sistemi ekleme, sadece pozitif pekiştirmeye odaklan.',
      ],
    ),
    StudyTechnique(
      id: 'visualization',
      title: 'Görselleştirme',
      category: 'motivation',
      shortDescription: 'Başarıyı zihninde yaşa.',
      fullDescription:
          'Elit sporcuların kullandığı teknik. Beyni başarının zaten gerçekleştiğine inandırarak performansı ve istekliliği artırır.',
      steps: [
        'Gözlerini kapat.',
        'Hedefine ulaştığını, atandığını, o masada oturduğunu detaylarıyla (ses, koku, his) hayal et.',
        'Süreci de hayal et: Zorlukları nasıl aştığını canlandır.',
      ],
      benefits: [
        'Özgüveni artırır, kaygıyı azaltır.',
        'Beyindeki nöral yolları eyleme hazırlar.',
      ],
      tips: [
        'Sabah uyanınca veya gece yatmadan önce yap.',
      ],
    ),
    StudyTechnique(
      id: 'growth-mindset',
      title: 'Büyüme Zihniyeti (Growth Mindset)',
      category: 'motivation',
      shortDescription: '"Henüz" yapamıyorum.',
      fullDescription:
          'Yeteneklerin sabit olmadığını, çabayla gelişebileceğini savunan yaklaşım. Başarısızlığı bir son değil, bir veri olarak görür.',
      steps: [
        '"Bunu yapamam" yerine "Bunu HENÜZ yapamam" de.',
        'Zorlukları tehdit değil, antrenman olarak gör.',
        'Başkalarının başarısını kıskanma, ilham al.',
      ],
      benefits: [
        'Başarısızlık korkusunu ve kırılganlığı azaltır.',
        'Dayanıklılığı (Resilience) artırır.',
      ],
      tips: [
        'Kendine karşı kullandığın dile dikkat et.',
        'Hata yaptığında "Buradan ne öğrendim?" diye sor.',
      ],
    ),
    StudyTechnique(
      id: 'flow-state',
      title: 'Akış (Flow) Teorisi',
      category: 'motivation',
      shortDescription: 'Zamanın nasıl geçtiğini unut.',
      fullDescription:
          'Kişinin yaptığı işe kendini tamamen kaptırdığı, zamanın akıp gittiği optimum odaklanma hali (Mihaly Csikszentmihalyi).',
      steps: [
        'Beceri ve zorluk seviyesi dengeli bir görev seç.',
        'Net hedef ve anında geri bildirim olsun.',
        'Tüm dikkat dağıtıcıları yok et.',
        'Sonuca değil, sürece (o ana) odaklan.',
      ],
      benefits: [
        'İçsel motivasyonu ve keyfi maksimize eder.',
        'Yaratıcılığı ve performansı zirveye taşır.',
      ],
      tips: [
        'Sevdiğin derslerle başlayarak bu modu tetikle.',
      ],
    ),
  ];
}
