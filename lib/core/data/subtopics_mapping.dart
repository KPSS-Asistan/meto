// Alt Konu (Subtopic) Haritalama - DETAYLI VERSİYON
// Her ana konu için kapsamlı alt konular ve anahtar kelimeler
// AI analiz, soru kategorilendirme ve zayıf nokta tespiti için kullanılır
// 
// KULLANIM:
// - subtopicId: Soru verisinde kullanılacak ID
// - subtopicName: Kullanıcıya gösterilecek isim
// - keywords: AI'ın soruyu kategorize etmesi için anahtar kelimeler

class SubtopicMapping {
  /// Tüm alt konu haritası
  /// Key: topicId, Value: alt konu listesi
  static const Map<String, List<SubtopicInfo>> topicSubtopics = {
    // ═══════════════════════════════════════════════════════════════════════════
    // TARİH (7 Ana Konu)
    // ═══════════════════════════════════════════════════════════════════════════
    
    // ─────────────────────────────────────────────────────────────────────────
    // 1. İSLAMİYET ÖNCESİ TÜRK TARİHİ
    // ─────────────────────────────────────────────────────────────────────────
    'JnFbEQt0uA8RSEuy22SQ': [
      // Orta Asya Türk Devletleri
      SubtopicInfo(
        id: 'asya_hun',
        name: 'Asya Hun Devleti (Büyük Hun)',
        keywords: ['asya hun', 'büyük hun', 'mete han', 'teoman', 'baydur', 'mo-tun', 'çin seddi', 'onlu sistem', 'turan taktiği', 'hilal taktiği', 'yüeçi', 'vusun', 'hsiung-nu', 'm.ö. 220', 'm.ö. 209', 'ho-han-ye', 'çiçi', 'kuzey hun', 'güney hun', 'ipek yolu'],
      ),
      SubtopicInfo(
        id: 'avrupa_hun',
        name: 'Avrupa Hun Devleti',
        keywords: ['avrupa hun', 'attila', 'balamir', 'uldız', 'rua', 'bleda', 'kavimler göçü', 'margus', 'anatolius', 'roma', 'batı roma', 'tanrının kamçısı', 'flagellum dei', '375', '434', '453', 'galya', 'katalon', 'orleans', 'pannonia'],
      ),
      SubtopicInfo(
        id: 'gokturk_1',
        name: 'I. Göktürk Devleti',
        keywords: ['i. göktürk', 'birinci göktürk', 'bumin kağan', 'istemi yabgu', 'mukan kağan', 'tapo kağan', 'avarlar', 'juan juan', 'ötüken', 'sasani', 'bizans', '552', '582', 'doğu göktürk', 'batı göktürk', 'ipekyolu', 'demir işlemeciliği', 'ergenekon'],
      ),
      SubtopicInfo(
        id: 'gokturk_2',
        name: 'II. Göktürk (Kutluk) Devleti',
        keywords: ['ii. göktürk', 'ikinci göktürk', 'kutluk devleti', 'kutluk kağan', 'ilterişkağan', 'kapgan kağan', 'bilge kağan', 'kül tigin', 'tonyukuk', 'orhun yazıtları', 'orhun abideleri', 'göktürk kitabeleri', '682', '745', 'tonyukuk yazıtı', 'bilge kağan yazıtı', 'kül tigin yazıtı'],
      ),
      SubtopicInfo(
        id: 'uygur',
        name: 'Uygur Devleti',
        keywords: ['uygur', 'kutluk bilge kül kağan', 'bögü kağan', 'moyençur', 'karabalgasun', 'ordubalık', 'maniheizm', 'budizm', 'matbaa', 'kağıt para', 'çav', '745', '840', 'kırgız', 'yerleşik hayat', 'turfan', 'hoço', 'uygur alfabesi', 'şehircilik', 'tarım'],
      ),
      
      // Diğer Türk Devletleri
      SubtopicInfo(
        id: 'akhun',
        name: 'Akhun (Eftalit) Devleti',
        keywords: ['akhun', 'eftalit', 'ak hun', 'heftalit', 'toran', 'hindistan', 'sasani', 'afganistan', '420', '557', 'mihirakula'],
      ),
      SubtopicInfo(
        id: 'turges',
        name: 'Türgişler',
        keywords: ['türgiş', 'türgeş', 'sulu kağan', 'baga tarkan', 'talas', 'emevi', 'arap', 'batı türkistan', '699', '766'],
      ),
      SubtopicInfo(
        id: 'kirgiz',
        name: 'Kırgızlar',
        keywords: ['kırgız', 'yenisey', 'uygur', '840', 'ötüken', 'manas destanı', 'yenisey yazıtları'],
      ),
      SubtopicInfo(
        id: 'hazar',
        name: 'Hazar Hakanlığı',
        keywords: ['hazar', 'itil', 'volga', 'musevilik', 'yahudilik', 'sarkel', 'bizans', 'arap', 'ipek yolu', 'ticaret', '630', '969', 'şaman', 'hristiyan'],
      ),
      SubtopicInfo(
        id: 'avar',
        name: 'Avarlar',
        keywords: ['avar', 'bayan kağan', 'pannonia', 'macaristan', 'bizans', 'frank', 'sasani', '558', '805', 'üzengi', 'kılıç'],
      ),
      SubtopicInfo(
        id: 'bulgar',
        name: 'Bulgarlar',
        keywords: ['bulgar', 'itil bulgar', 'tuna bulgar', 'asparuh', 'boris', 'hristiyanlık', 'slavlaşma', '681', 'balkan'],
      ),
      SubtopicInfo(
        id: 'pecenekler',
        name: 'Peçenekler',
        keywords: ['peçenek', 'bizans', 'kiev', 'rus', 'kıpçak', 'kuman', 'malazgirt', 'turan taktiği'],
      ),
      SubtopicInfo(
        id: 'kipcak_kuman',
        name: 'Kıpçaklar (Kumanlar)',
        keywords: ['kıpçak', 'kuman', 'codex cumanicus', 'altın orda', 'memlük', 'deşt-i kıpçak', 'bizans', 'macar', 'rus'],
      ),
      SubtopicInfo(
        id: 'karluk',
        name: 'Karluklar',
        keywords: ['karluk', 'talas savaşı', '751', 'arap', 'çin', 'tang', 'müslüman', 'türkistan', 'karahanlı'],
      ),
      SubtopicInfo(
        id: 'oguz',
        name: 'Oğuzlar',
        keywords: ['oğuz', 'dokuz oğuz', 'yirmi dört oğuz', 'oğuz kağan', 'oğuz destanı', 'selçuklu', 'osmanlı', 'bozok', 'üçok', 'kayı', 'türkmen'],
      ),
      
      // Kültür ve Medeniyet
      SubtopicInfo(
        id: 'devlet_teskilati',
        name: 'Devlet Teşkilatı',
        keywords: ['kut', 'töre', 'kurultay', 'toy', 'kengeş', 'kağan', 'hakan', 'yabgu', 'şad', 'tigin', 'tarkan', 'tudun', 'buyruk', 'ayuki', 'hatun', 'katun', 'veraset', 'ikili yönetim', 'doğu-batı'],
      ),
      SubtopicInfo(
        id: 'ordu_askerlik',
        name: 'Ordu ve Askerlik',
        keywords: ['onlu sistem', 'turan taktiği', 'hilal taktiği', 'sahte ricat', 'süvari', 'atlı okçu', 'ok', 'yay', 'kılıç', 'kalkan', 'zırh', 'ordu', 'tümen', 'bin başı', 'yüz başı', 'on başı'],
      ),
      SubtopicInfo(
        id: 'din_inanc',
        name: 'Din ve İnanç Sistemi',
        keywords: ['gök tanrı', 'tengri', 'tengricilik', 'şaman', 'şamanizm', 'kam', 'baksı', 'umay', 'yer-su', 'erlik', 'ruh', 'atalar kültü', 'totemizm', 'animizm', 'kurgan', 'balbal', 'yuğ', 'ölü gömme'],
      ),
      SubtopicInfo(
        id: 'yazi_edebiyat',
        name: 'Yazı, Dil ve Edebiyat',
        keywords: ['göktürk alfabesi', 'orhun alfabesi', 'uygur alfabesi', 'runik', 'orhun yazıtları', 'yenisey yazıtları', 'karabalgasun yazıtı', 'destan', 'sagu', 'koşuk', 'sav', 'yaratılış destanı', 'göç destanı', 'ergenekon', 'bozkurt', 'türeyiş', 'oğuz kağan destanı', 'manas', 'alp er tunga'],
      ),
      SubtopicInfo(
        id: 'sosyal_ekonomi',
        name: 'Sosyal ve Ekonomik Yapı',
        keywords: ['boy', 'oguş', 'bod', 'bodun', 'il', 'el', 'konar-göçer', 'yarı göçebe', 'hayvancılık', 'at', 'koyun', 'keçe', 'yurt', 'çadır', 'otag', 'kımız', 'kurut', 'ticaret', 'ipek yolu', 'kürk yolu', 'altın', 'gümüş', 'demir'],
      ),
      SubtopicInfo(
        id: 'sanat_mimari',
        name: 'Sanat ve Mimari',
        keywords: ['hayvan üslubu', 'bozkır sanatı', 'kurgan', 'balbal', 'taş baba', 'altın', 'gümüş', 'metal işçiliği', 'keçe', 'halı', 'kilim', 'at koşum takımları', 'eyer', 'üzengi', 'kemer tokası', 'pazırık', 'esik', 'altın adam'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 2. İLK MÜSLÜMAN TÜRK DEVLETLERİ
    // ─────────────────────────────────────────────────────────────────────────
    '9Hg8tuMRdMTuVY7OZ9HL': [
      // Ana Devletler
      SubtopicInfo(
        id: 'karahanli',
        name: 'Karahanlı Devleti',
        keywords: ['karahanlı', 'satuk buğra han', 'abdülkerim', 'bilge kül kadir han', 'tamgaç han', 'balasagun', 'kaşgar', 'semerkant', 'türkçe resmi dil', 'ilk müslüman türk devleti', '840', '1212', 'doğu karahanlı', 'batı karahanlı', 'yusuf has hacip', 'kutadgu bilig', 'kaşgarlı mahmut', 'divanü lügati\'t-türk', 'edip ahmet', 'atabetü\'l-hakayık', 'ribat', 'türbe'],
      ),
      SubtopicInfo(
        id: 'gazneli',
        name: 'Gazneli Devleti',
        keywords: ['gazneli', 'gazneli mahmut', 'sebük tekin', 'alptekin', 'gazne', 'hindistan seferleri', 'sultan unvanı', 'ilk sultan', '963', '1187', 'firdevsi', 'şehname', 'biruni', 'utbi', 'dandanakan', 'hindistan', 'pencap', 'lahore', 'türk-islam', 'hint'],
      ),
      SubtopicInfo(
        id: 'buyuk_selcuklu',
        name: 'Büyük Selçuklu Devleti',
        keywords: ['büyük selçuklu', 'selçuk bey', 'tuğrul bey', 'çağrı bey', 'alparslan', 'melikşah', 'berkyaruk', 'sencer', 'dandanakan', 'malazgirt', 'pasinler', 'rey', 'isfahan', 'nişabur', 'bağdat', 'abbasi', 'halife', 'sultanüs selatin', '1040', '1157', 'nizamülmülk', 'siyasetname', 'nizamiye medresesi', 'atabey', 'melik', 'uc', 'ikta'],
      ),
      SubtopicInfo(
        id: 'turkiye_selcuklu',
        name: 'Türkiye Selçuklu Devleti',
        keywords: ['türkiye selçuklu', 'anadolu selçuklu', 'kutalmışoğlu süleyman şah', 'i. kılıç arslan', 'i. mesut', 'ii. kılıç arslan', 'i. gıyaseddin keyhüsrev', 'i. izzeddin keykavus', 'i. alaeddin keykubat', 'ii. gıyaseddin keyhüsrev', 'iznik', 'konya', 'miryokefalon', 'kösedağ', 'haçlı', '1075', '1308', 'denizcilik', 'sinop', 'alanya', 'kervansaray', 'han', 'medrese', 'darüşşifa', 'ahi', 'lonca', 'mevlana', 'hacı bektaş', 'yunus emre', 'nasreddin hoca'],
      ),
      SubtopicInfo(
        id: 'harzemşah',
        name: 'Harzemşahlar',
        keywords: ['harzem', 'harzemşah', 'anuş tekin', 'kutbeddin muhammed', 'alaeddin tekiş', 'alaeddin muhammed', 'celaleddin mengüberti', 'gürgenç', 'ürgenç', 'moğol', 'cengiz han', 'otrar', 'buhara', 'semerkant', '1097', '1231', 'son büyük türk-islam devleti'],
      ),
      SubtopicInfo(
        id: 'mogol_turk',
        name: 'Moğol ve Türk-Moğol Devletleri',
        keywords: ['moğol', 'cengiz han', 'kubilay', 'hülagü', 'ilhanlı', 'altın orda', 'çağatay', 'timur', 'timurlular', 'babür', 'babürlüler', 'hindistan', 'delhi', 'agra'],
      ),
      
      // Anadolu Beylikleri
      SubtopicInfo(
        id: 'beylikler_bati',
        name: 'Batı Anadolu Beylikleri',
        keywords: ['karesioğulları', 'saruhanoğulları', 'aydınoğulları', 'menteşeoğulları', 'germiyanoğulları', 'hamidoğulları', 'denizcilik', 'ege', 'balıkesir', 'manisa', 'aydın', 'muğla', 'kütahya', 'isparta', 'osmanlı', 'katılım'],
      ),
      SubtopicInfo(
        id: 'beylikler_orta',
        name: 'Orta ve Doğu Anadolu Beylikleri',
        keywords: ['karamanoğulları', 'candaroğulları', 'isfendiyaroğulları', 'eretna', 'kadı burhaneddin', 'dulkadiroğulları', 'ramazanoğulları', 'akkoyunlu', 'karakoyunlu', 'konya', 'karaman', 'kastamonu', 'sinop', 'sivas', 'erzincan', 'maraş', 'adana', 'diyarbakır', 'türkçe resmi dil'],
      ),
      SubtopicInfo(
        id: 'osmanlı_kuruluş_beylik',
        name: 'Osmanlı Beyliği (Kuruluş)',
        keywords: ['osmanlı beyliği', 'kayı', 'ertuğrul gazi', 'osman bey', 'söğüt', 'domaniç', 'bizans', 'tekfur', 'karacahisar', 'bilecik', 'inegöl', 'bursa'],
      ),
      
      // Kültür ve Medeniyet
      SubtopicInfo(
        id: 'devlet_yonetimi_islam',
        name: 'Devlet Yönetimi ve Hukuk',
        keywords: ['sultan', 'halife', 'divan', 'vezir', 'atabey', 'melik', 'şıhne', 'amid', 'müstevfi', 'tuğra', 'berat', 'ferman', 'şeriat', 'örfi hukuk', 'kadı', 'kazasker', 'ikta', 'has', 'vakıf'],
      ),
      SubtopicInfo(
        id: 'ordu_askerlik_islam',
        name: 'Ordu ve Askerlik',
        keywords: ['gulam', 'memlük', 'hassa ordusu', 'sipahi', 'ikta askeri', 'türkmen', 'uc', 'serhat', 'gaza', 'gazi', 'cihad', 'ribat', 'subaşı', 'serdar'],
      ),
      SubtopicInfo(
        id: 'bilim_egitim_islam',
        name: 'Bilim ve Eğitim',
        keywords: ['medrese', 'nizamiye', 'molla', 'müderris', 'talebe', 'icazetname', 'külliye', 'kütüphane', 'rasathane', 'biruni', 'farabi', 'ibn sina', 'harezmi', 'ömer hayyam', 'matematik', 'astronomi', 'tıp', 'felsefe', 'mantık'],
      ),
      SubtopicInfo(
        id: 'edebiyat_sanat_islam',
        name: 'Edebiyat ve Sanat',
        keywords: ['türkçe', 'farsça', 'arapça', 'divan edebiyatı', 'halk edebiyatı', 'tasavvuf', 'kutadgu bilig', 'divanü lügati\'t-türk', 'atabetü\'l-hakayık', 'divan-ı hikmet', 'mesnevi', 'gazel', 'kaside', 'minyatür', 'hat', 'tezhip', 'ebru', 'çini', 'halı', 'seramik'],
      ),
      SubtopicInfo(
        id: 'mimari_islam',
        name: 'Mimari',
        keywords: ['cami', 'mescit', 'medrese', 'türbe', 'kümbet', 'külliye', 'kervansaray', 'han', 'ribat', 'darüşşifa', 'bimarhane', 'hamam', 'çeşme', 'köprü', 'kale', 'sur', 'selçuklu üslubu', 'geometrik süsleme', 'bitkisel süsleme', 'mukarnas', 'eyvan', 'revak'],
      ),
      SubtopicInfo(
        id: 'ekonomi_ticaret_islam',
        name: 'Ekonomi ve Ticaret',
        keywords: ['ipek yolu', 'baharat yolu', 'kervan', 'kervansaray', 'han', 'pazar', 'panayır', 'lonca', 'ahi', 'ahilik', 'gedik', 'esnaf', 'tüccar', 'vergi', 'öşür', 'haraç', 'cizye', 'gümrük'],
      ),
      SubtopicInfo(
        id: 'tasavvuf_tarikat',
        name: 'Tasavvuf ve Tarikatlar',
        keywords: ['tasavvuf', 'sufi', 'derviş', 'tarikat', 'tekke', 'zaviye', 'dergah', 'mevlevi', 'mevlana', 'bektaşi', 'hacı bektaş veli', 'yesevi', 'ahmet yesevi', 'nakşibendi', 'kadiri', 'rifai', 'yunus emre', 'aşık paşa'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 3. OSMANLI DEVLETİ TARİHİ
    // ─────────────────────────────────────────────────────────────────────────
    'rl2xQTfv1iUaCyhFzp5V': [
      // Dönemler
      SubtopicInfo(
        id: 'kurulus_donemi',
        name: 'Kuruluş Dönemi (1299-1453)',
        keywords: ['kuruluş', 'osman bey', 'orhan bey', 'i. murat', 'yıldırım bayezid', 'i. mehmet', 'ii. murat', 'söğüt', 'bursa', 'edirne', 'karesioğulları', 'koyunhisar', 'palekanon', 'sırpsındığı', 'kosova', 'niğbolu', 'ankara savaşı', 'fetret devri', 'varna', 'ii. kosova', 'devşirme', 'yeniçeri', 'tımar', 'kapıkulu'],
      ),
      SubtopicInfo(
        id: 'yukselis_donemi',
        name: 'Yükseliş Dönemi (1453-1579)',
        keywords: ['yükseliş', 'fatih sultan mehmet', 'ii. bayezid', 'yavuz sultan selim', 'kanuni sultan süleyman', 'ii. selim', 'istanbul fethi', 'mora', 'trabzon', 'kırım', 'otlukbeli', 'çaldıran', 'ridaniye', 'mercidabık', 'mohaç', 'viyana kuşatması', 'preveze', 'rodos', 'belgrad', 'barbaros', 'piri reis', 'mimar sinan', 'kanunname', 'kapitülasyon'],
      ),
      SubtopicInfo(
        id: 'duraklama_donemi',
        name: 'Duraklama Dönemi (1579-1699)',
        keywords: ['duraklama', 'iii. murat', 'iii. mehmet', 'i. ahmet', 'iv. murat', 'köprülüler', 'celali isyanları', 'yeniçeri isyanları', 'hotin', 'revan', 'bağdat', 'girit', 'vasvar', 'ii. viyana kuşatması', 'karlofça', 'kutsal ittifak', 'haçova', 'zitvatorok'],
      ),
      SubtopicInfo(
        id: 'gerileme_donemi',
        name: 'Gerileme Dönemi (1699-1792)',
        keywords: ['gerileme', 'lale devri', 'patrona halil', 'iii. ahmet', 'i. mahmut', 'iii. mustafa', 'i. abdülhamit', 'iii. selim', 'pasarofça', 'belgrad', 'prut', 'küçük kaynarca', 'yaş', 'isveç', 'rusya', 'avusturya', 'matbaa', 'ibrahim müteferrika', 'nizam-ı cedit'],
      ),
      SubtopicInfo(
        id: 'dagilma_donemi',
        name: 'Dağılma Dönemi (1792-1922)',
        keywords: ['dağılma', 'ii. mahmut', 'abdülmecit', 'abdülaziz', 'ii. abdülhamit', 'v. mehmet reşat', 'vi. mehmet vahdettin', 'yeniçerinin kaldırılması', 'tanzimat', 'islahat', 'meşrutiyet', 'kanun-i esasi', 'meclis-i mebusan', 'balkan savaşları', 'trablusgarp', 'i. dünya savaşı', 'mondros', 'sevr', 'saltanatın kaldırılması'],
      ),
      
      // Devlet Teşkilatı
      SubtopicInfo(
        id: 'merkez_teskilati',
        name: 'Merkez Teşkilatı',
        keywords: ['padişah', 'sultan', 'şehzade', 'valide sultan', 'harem', 'enderun', 'birun', 'divan-ı hümayun', 'kubbealtı', 'sadrazam', 'vezir', 'veziriazam', 'defterdar', 'nişancı', 'kazasker', 'şeyhülislam', 'kaptan-ı derya', 'yeniçeri ağası', 'reisülküttap'],
      ),
      SubtopicInfo(
        id: 'tasra_teskilati',
        name: 'Taşra Teşkilatı',
        keywords: ['eyalet', 'sancak', 'kaza', 'nahiye', 'köy', 'beylerbeyi', 'sancakbeyi', 'subaşı', 'kadı', 'naib', 'muhtesip', 'salyaneli', 'salyanesiz', 'yurtluk', 'ocaklık', 'hass', 'arpalık', 'paşmaklık'],
      ),
      SubtopicInfo(
        id: 'ordu_donanma',
        name: 'Ordu ve Donanma',
        keywords: ['kapıkulu', 'yeniçeri', 'ocak', 'acemi oğlan', 'devşirme', 'sipahi', 'silahtar', 'cebeci', 'topçu', 'humbaracı', 'lağımcı', 'eyalet askeri', 'tımarlı sipahi', 'akıncı', 'azap', 'yaya', 'müsellem', 'donanma', 'tersane', 'kaptan-ı derya', 'reis', 'kalyon', 'kadırga'],
      ),
      SubtopicInfo(
        id: 'hukuk_adalet',
        name: 'Hukuk ve Adalet',
        keywords: ['şeriat', 'örfi hukuk', 'kanunname', 'ferman', 'berat', 'kadı', 'kazasker', 'şeyhülislam', 'fetva', 'müftü', 'mahkeme', 'sicil', 'divan-ı mezalim'],
      ),
      
      // Ekonomi
      SubtopicInfo(
        id: 'toprak_sistemi',
        name: 'Toprak Sistemi',
        keywords: ['miri', 'mülk', 'vakıf', 'tımar', 'zeamet', 'has', 'dirlik', 'sipahi', 'çift bozan', 'çiftlik', 'malikane', 'mukataa', 'iltizam'],
      ),
      SubtopicInfo(
        id: 'ticaret_sanayi',
        name: 'Ticaret ve Sanayi',
        keywords: ['lonca', 'gedik', 'esnaf', 'çarşı', 'bedesten', 'kapan', 'arasta', 'han', 'kervansaray', 'gümrük', 'kapitülasyon', 'avrupa tüccarı', 'ipek', 'baharat', 'pamuk', 'deri'],
      ),
      SubtopicInfo(
        id: 'vergi_maliye',
        name: 'Vergi ve Maliye',
        keywords: ['öşür', 'haraç', 'cizye', 'ağnam', 'resm-i çift', 'avarız', 'nüzül', 'imdadiye', 'hazine', 'iç hazine', 'dış hazine', 'defterdar', 'muhasebe', 'sikke', 'akçe', 'kuruş', 'altın'],
      ),
      
      // Kültür
      SubtopicInfo(
        id: 'egitim_osmanlı',
        name: 'Eğitim',
        keywords: ['sıbyan mektebi', 'medrese', 'enderun', 'darülfünun', 'rüştiye', 'idadi', 'sultani', 'mühendishane', 'tıbbiye', 'harbiye', 'müderris', 'molla', 'kadı', 'icazet'],
      ),
      SubtopicInfo(
        id: 'edebiyat_osmanli',
        name: 'Edebiyat',
        keywords: ['divan edebiyatı', 'halk edebiyatı', 'gazel', 'kaside', 'mesnevi', 'şarkı', 'koşma', 'semai', 'destan', 'fuzuli', 'baki', 'nedim', 'şeyh galip', 'karacaoğlan', 'pir sultan abdal', 'köroğlu', 'aşık veysel'],
      ),
      SubtopicInfo(
        id: 'sanat_mimari_osmanli',
        name: 'Sanat ve Mimari',
        keywords: ['mimar sinan', 'süleymaniye', 'selimiye', 'sultanahmet', 'topkapı', 'dolmabahçe', 'cami', 'külliye', 'medrese', 'türbe', 'çeşme', 'sebil', 'köprü', 'han', 'hamam', 'kervansaray', 'minyatür', 'hat', 'tezhip', 'ebru', 'çini', 'kündekari'],
      ),
      SubtopicInfo(
        id: 'bilim_teknoloji_osmanli',
        name: 'Bilim ve Teknoloji',
        keywords: ['matbaa', 'ibrahim müteferrika', 'rasathane', 'takiyüddin', 'piri reis', 'kitab-ı bahriye', 'harita', 'coğrafya', 'tıp', 'astronomi', 'evliya çelebi', 'seyahatname', 'katip çelebi', 'keşfü\'z-zunun'],
      ),
      
      // Islahatlar
      SubtopicInfo(
        id: 'islahatlar_17_18',
        name: '17-18. Yüzyıl Islahatları',
        keywords: ['köprülü', 'ıı. osman', 'genç osman', 'ıv. murat', 'lale devri', 'patrona halil', 'ııı. selim', 'nizam-ı cedit', 'matbaa', 'tercüme odası', 'yenilik', 'batılılaşma'],
      ),
      SubtopicInfo(
        id: 'islahatlar_19',
        name: '19. Yüzyıl Islahatları',
        keywords: ['ıı. mahmut', 'sened-i ittifak', 'vaka-i hayriye', 'yeniçerinin kaldırılması', 'asakir-i mansure', 'tanzimat', 'gülhane', 'mustafa reşit paşa', 'islahat fermanı', 'meşrutiyet', 'kanun-i esasi', 'mithat paşa', 'meclis-i mebusan'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 4. KURTULUŞ SAVAŞI DÖNEMİ
    // ─────────────────────────────────────────────────────────────────────────
    'DlT19snCttf5j5RUAXLz': [
      // I. Dünya Savaşı ve Sonuçları
      SubtopicInfo(
        id: 'dunya_savasi',
        name: 'I. Dünya Savaşı',
        keywords: ['birinci dünya savaşı', 'üçlü itilaf', 'üçlü ittifak', 'osmanlı', 'almanya', 'avusturya', 'çanakkale', 'kafkas', 'kanal', 'irak', 'hicaz', 'yemen', 'suriye', 'filistin', 'galiçya', 'romanya', 'makedonya', 'enver paşa', 'cemal paşa', 'talat paşa', 'mustafa kemal'],
      ),
      SubtopicInfo(
        id: 'mondros',
        name: 'Mondros Mütarekesi',
        keywords: ['mondros', 'mütareke', 'ateşkes', '30 ekim 1918', 'limni', 'agamemnon', 'rauf orbay', 'teslim', 'işgal', '7. madde', 'boğazlar', 'silah', 'terhis'],
      ),
      SubtopicInfo(
        id: 'isgaller',
        name: 'İşgaller ve Tepkiler',
        keywords: ['işgal', 'ingiliz', 'fransız', 'italyan', 'yunan', 'istanbul', 'izmir', 'antalya', 'adana', 'antep', 'maraş', 'urfa', 'musul', 'kuvayı milliye', 'direniş', 'milis', 'çete'],
      ),
      SubtopicInfo(
        id: 'sevr',
        name: 'Sevr Antlaşması',
        keywords: ['sevr', 'antlaşma', '10 ağustos 1920', 'paris', 'toprak kaybı', 'kapitülasyon', 'azınlık', 'doğu anadolu', 'ermenistan', 'kürdistan', 'trakya', 'ege', 'boğazlar', 'komisyon', 'mali denetim'],
      ),
      SubtopicInfo(
        id: 'cemiyetler',
        name: 'Cemiyetler',
        keywords: ['milli cemiyetler', 'zararlı cemiyetler', 'müdafaa-i hukuk', 'reddi ilhak', 'kilikyalılar', 'trakya paşaeli', 'sulh ve selamet', 'ingiliz muhipleri', 'wilson prensipleri', 'kürt teali', 'rum pontus', 'mavri mira', 'etniki eterya', 'hınçak', 'taşnak'],
      ),
      
      // Milli Mücadelenin Hazırlık Safhası
      SubtopicInfo(
        id: 'mustafa_kemal_samsun',
        name: 'Mustafa Kemal\'in Samsun\'a Çıkışı',
        keywords: ['samsun', '19 mayıs 1919', '9. ordu müfettişi', 'bandırma vapuru', 'havza', 'genelge', 'milli bilinç', 'mitingler'],
      ),
      SubtopicInfo(
        id: 'amasya_genelgesi',
        name: 'Amasya Genelgesi',
        keywords: ['amasya', 'genelge', 'tamim', '22 haziran 1919', 'vatanın bütünlüğü', 'milletin istiklali', 'istanbul hükümeti', 'millet', 'sivas kongresi', 'heyet-i temsiliye', 'ali fuat cebesoy', 'rauf orbay', 'refet bele'],
      ),
      SubtopicInfo(
        id: 'erzurum_kongresi',
        name: 'Erzurum Kongresi',
        keywords: ['erzurum', 'kongre', '23 temmuz 1919', 'doğu anadolu', 'müdafaa-i hukuk', 'manda', 'himaye', 'milli sınırlar', 'misakımilli', 'heyet-i temsiliye', 'mustafa kemal başkan', 'kararlar'],
      ),
      SubtopicInfo(
        id: 'sivas_kongresi',
        name: 'Sivas Kongresi',
        keywords: ['sivas', 'kongre', '4 eylül 1919', 'ulusal', 'birleşme', 'anadolu ve rumeli', 'müdafaa-i hukuk', 'heyet-i temsiliye', 'ali fuat paşa', 'batı cephesi', 'istanbul', 'damat ferit', 'aydede'],
      ),
      SubtopicInfo(
        id: 'son_osmanli_meclisi',
        name: 'Son Osmanlı Mebusan Meclisi',
        keywords: ['mebusan meclisi', 'ocak 1920', 'istanbul', 'misakımilli', 'milli ant', '28 ocak 1920', '6 madde', 'milli sınırlar', 'kapitülasyon', 'azınlık', 'boğazlar', 'adalar', 'trakya', 'işgal'],
      ),
      
      // TBMM Dönemi
      SubtopicInfo(
        id: 'tbmm_acilisi',
        name: 'TBMM\'nin Açılması',
        keywords: ['tbmm', 'büyük millet meclisi', '23 nisan 1920', 'ankara', 'meclis', 'en yaşlı üye', 'sinop mebusu', 'şerif bey', 'mustafa kemal başkan', 'kurucu meclis', 'olağanüstü', 'yasama', 'yürütme', 'yargı', 'meclis hükümeti'],
      ),
      SubtopicInfo(
        id: 'tbmm_ilk_icraatlar',
        name: 'TBMM\'nin İlk İcraatları',
        keywords: ['hıyanet-i vataniye', 'istiklal mahkemeleri', 'icra vekilleri heyeti', 'anayasa', 'teşkilat-ı esasiye', '20 ocak 1921', 'egemenlik', 'milli irade', 'başkomutanlık'],
      ),
      
      // Cepheler
      SubtopicInfo(
        id: 'dogu_cephesi',
        name: 'Doğu Cephesi',
        keywords: ['doğu cephesi', 'ermenistan', 'kazım karabekir', 'sarıkamış', 'kars', 'gümrü', 'antlaşma', '3 aralık 1920', 'batum', 'moskova', 'kars antlaşması'],
      ),
      SubtopicInfo(
        id: 'guney_cephesi',
        name: 'Güney Cephesi',
        keywords: ['güney cephesi', 'fransız', 'ermeni', 'kilikya', 'adana', 'antep', 'maraş', 'urfa', 'şahin bey', 'sütçü imam', 'ankara antlaşması', '20 ekim 1921', 'hatay'],
      ),
      SubtopicInfo(
        id: 'bati_cephesi',
        name: 'Batı Cephesi',
        keywords: ['batı cephesi', 'yunan', 'ali fuat cebesoy', 'ismet paşa', 'düzenli ordu', 'gediz', 'i. inönü', 'ii. inönü', 'kütahya', 'eskişehir', 'sakarya', 'büyük taarruz', 'dumlupınar', 'başkomutan', 'mustafa kemal'],
      ),
      SubtopicInfo(
        id: 'inonu_savaslari',
        name: 'İnönü Savaşları',
        keywords: ['inönü', 'i. inönü', '10 ocak 1921', 'ii. inönü', '31 mart 1921', 'ismet paşa', 'yunan', 'metristepe', 'londra konferansı', 'moskova antlaşması', 'istiklal marşı', 'mehmet akif'],
      ),
      SubtopicInfo(
        id: 'sakarya_meydan_muharebesi',
        name: 'Sakarya Meydan Muharebesi',
        keywords: ['sakarya', 'meydan muharebesi', '23 ağustos 1921', '13 eylül 1921', '22 gün', '100 km cephe', 'başkomutan', 'mustafa kemal', 'gazi', 'mareşal', 'kara fatma', 'polatlı', 'haymana', 'fransız', 'ankara antlaşması'],
      ),
      SubtopicInfo(
        id: 'buyuk_taarruz',
        name: 'Büyük Taarruz',
        keywords: ['büyük taarruz', '26 ağustos 1922', 'afyon', 'kocatepe', 'başkomutanlık', 'dumlupınar', '30 ağustos', 'zafer bayramı', 'izmir', '9 eylül', 'mudanya', 'ateşkes', 'yunan', 'trikopis'],
      ),
      
      // İç İsyanlar
      SubtopicInfo(
        id: 'ic_isyanlar',
        name: 'İç İsyanlar',
        keywords: ['isyan', 'ayaklanma', 'bolu', 'düzce', 'anzavur', 'çerkez ethem', 'yozgat', 'koçgiri', 'pontus', 'milli aşiret', 'delibaş mehmet', 'istiklal mahkemesi', 'hıyanet-i vataniye'],
      ),
      
      // Antlaşmalar
      SubtopicInfo(
        id: 'mudanya',
        name: 'Mudanya Ateşkes Antlaşması',
        keywords: ['mudanya', 'ateşkes', '11 ekim 1922', 'ismet paşa', 'ingiliz', 'fransız', 'italyan', 'yunan', 'trakya', 'boğazlar', 'istanbul', 'lozan'],
      ),
      SubtopicInfo(
        id: 'lozan',
        name: 'Lozan Barış Antlaşması',
        keywords: ['lozan', 'barış', '24 temmuz 1923', 'ismet paşa', 'curzon', 'kapitülasyon', 'boğazlar', 'musul', 'azınlık', 'osmanlı borçları', 'sınır', 'egemenlik', 'bağımsızlık', 'uluslararası tanınma'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 5. ATATÜRK İLKE VE İNKILAPLARI
    // ─────────────────────────────────────────────────────────────────────────
    '4GUvpqBBImcLmN2eh1HK': [
      // Siyasi Alanda
      SubtopicInfo(
        id: 'saltanatin_kaldirilmasi',
        name: 'Saltanatın Kaldırılması',
        keywords: ['saltanat', 'kaldırılması', '1 kasım 1922', 'padişah', 'vi. mehmet vahdettin', 'lozan', 'osmanlı', 'tbmm', 'egemenlik', 'millet'],
      ),
      SubtopicInfo(
        id: 'cumhuriyetin_ilani',
        name: 'Cumhuriyetin İlanı',
        keywords: ['cumhuriyet', 'ilan', '29 ekim 1923', 'cumhurbaşkanı', 'mustafa kemal', 'başbakan', 'ismet inönü', 'rejim', 'anayasa değişikliği', 'egemenlik'],
      ),
      SubtopicInfo(
        id: 'hilafetin_kaldirilmasi',
        name: 'Halifeliğin Kaldırılması',
        keywords: ['hilafet', 'kaldırılması', '3 mart 1924', 'halife', 'abdülmecit efendi', 'osmanlı hanedanı', 'sürgün', 'dini siyaset', 'laiklik'],
      ),
      SubtopicInfo(
        id: 'cok_partili_hayat',
        name: 'Çok Partili Hayat Denemeleri',
        keywords: ['çok partili', 'demokrasi', 'terakkiperver cumhuriyet fırkası', 'kazım karabekir', 'rauf orbay', 'ali fuat cebesoy', 'şeyh sait isyanı', 'serbest cumhuriyet fırkası', 'fethi okyar', 'menemen olayı'],
      ),
      
      // Hukuki Alanda
      SubtopicInfo(
        id: 'anayasalar',
        name: 'Anayasalar',
        keywords: ['anayasa', 'teşkilat-ı esasiye', '1921 anayasası', '1924 anayasası', '1961 anayasası', '1982 anayasası', 'egemenlik', 'milli irade', 'temel haklar'],
      ),
      SubtopicInfo(
        id: 'hukuk_birlik',
        name: 'Hukuk Birliği',
        keywords: ['hukuk birliği', 'medeni kanun', '17 şubat 1926', 'isviçre', 'aile hukuku', 'miras', 'kadın hakları', 'çok eşlilik', 'boşanma', 'ticaret kanunu', 'ceza kanunu', 'borçlar kanunu'],
      ),
      SubtopicInfo(
        id: 'kadin_haklari',
        name: 'Kadın Hakları',
        keywords: ['kadın hakları', 'seçme hakkı', 'seçilme hakkı', '1930 belediye', '1934 milletvekili', 'medeni kanun', 'eşitlik', 'miras', 'boşanma', 'eğitim', 'çalışma'],
      ),
      
      // Eğitim ve Kültür
      SubtopicInfo(
        id: 'tevhidi_tedrisat',
        name: 'Tevhid-i Tedrisat Kanunu',
        keywords: ['tevhid-i tedrisat', '3 mart 1924', 'öğretim birliği', 'medrese', 'kapatılması', 'maarif vekaleti', 'milli eğitim', 'laik eğitim', 'modern eğitim'],
      ),
      SubtopicInfo(
        id: 'harf_inkilabi',
        name: 'Harf İnkılabı',
        keywords: ['harf inkılabı', '1 kasım 1928', 'latin alfabesi', 'yeni türk harfleri', 'millet mektepleri', 'okuma yazma', 'atatürk başöğretmen', 'arap alfabesi', 'osmanlıca'],
      ),
      SubtopicInfo(
        id: 'turk_tarih_kurumu',
        name: 'Türk Tarih Kurumu',
        keywords: ['türk tarih kurumu', '15 nisan 1931', 'tarih araştırma', 'türk tarihi', 'milli tarih', 'türk tarih tezi', 'afet inan'],
      ),
      SubtopicInfo(
        id: 'turk_dil_kurumu',
        name: 'Türk Dil Kurumu',
        keywords: ['türk dil kurumu', '12 temmuz 1932', 'dil araştırma', 'türkçe', 'sadeleştirme', 'güneş dil teorisi', 'öz türkçe', 'yabancı kelime'],
      ),
      SubtopicInfo(
        id: 'universite_reformu',
        name: 'Üniversite Reformu',
        keywords: ['üniversite reformu', '1933', 'istanbul üniversitesi', 'darülfünun', 'kapatılması', 'modern üniversite', 'alman profesörler', 'bilimsel araştırma'],
      ),
      SubtopicInfo(
        id: 'guzel_sanatlar',
        name: 'Güzel Sanatlar',
        keywords: ['güzel sanatlar', 'konservatuvar', 'halkevleri', 'köy enstitüleri', 'opera', 'bale', 'tiyatro', 'resim', 'heykel', 'müzik', 'halk müziği'],
      ),
      
      // Ekonomik Alanda
      SubtopicInfo(
        id: 'izmir_iktisat_kongresi',
        name: 'İzmir İktisat Kongresi',
        keywords: ['izmir iktisat kongresi', '17 şubat 1923', 'milli ekonomi', 'misak-ı iktisadi', 'yerli malı', 'sanayileşme', 'çiftçi', 'tüccar', 'işçi', 'esnaf'],
      ),
      SubtopicInfo(
        id: 'ekonomi_politikasi',
        name: 'Ekonomi Politikası',
        keywords: ['liberal dönem', 'devletçilik', '1929 buhranı', 'planlı ekonomi', 'beş yıllık kalkınma planı', 'kit', 'fabrika', 'sanayileşme', 'demiryolu'],
      ),
      SubtopicInfo(
        id: 'tarim_politikasi',
        name: 'Tarım Politikası',
        keywords: ['tarım', 'aşar vergisi', 'kaldırılması', 'ziraat bankası', 'tohum', 'kredi', 'kooperatif', 'tarım makinesi', 'modern tarım'],
      ),
      SubtopicInfo(
        id: 'sanayi_yatirimlari',
        name: 'Sanayi Yatırımları',
        keywords: ['sanayi', 'fabrika', 'sümerbank', 'etibank', 'tekstil', 'şeker', 'çimento', 'demir çelik', 'karabük', 'kağıt', 'cam'],
      ),
      SubtopicInfo(
        id: 'ulastirma_haberlesme',
        name: 'Ulaştırma ve Haberleşme',
        keywords: ['demiryolu', 'karayolu', 'liman', 'havayolu', 'thy', 'posta', 'telgraf', 'telefon', 'kabotaj', 'denizcilik'],
      ),
      
      // Toplumsal Alanda
      SubtopicInfo(
        id: 'sapka_inkilabi',
        name: 'Şapka ve Kıyafet İnkılabı',
        keywords: ['şapka inkılabı', '25 kasım 1925', 'kıyafet', 'fes', 'sarık', 'peçe', 'çarşaf', 'batılı giyim', 'modern görünüm'],
      ),
      SubtopicInfo(
        id: 'tekke_zaviye',
        name: 'Tekke ve Zaviyelerin Kapatılması',
        keywords: ['tekke', 'zaviye', 'türbe', 'kapatılması', '30 kasım 1925', 'tarikat', 'şeyhlik', 'dervişlik', 'laiklik'],
      ),
      SubtopicInfo(
        id: 'takvim_saat',
        name: 'Takvim, Saat ve Ölçü Birimi',
        keywords: ['takvim', 'miladi takvim', '1 ocak 1926', 'saat', 'uluslararası saat', 'ölçü', 'metrik sistem', 'metre', 'kilogram', 'hafta tatili'],
      ),
      SubtopicInfo(
        id: 'soyadi_kanunu',
        name: 'Soyadı Kanunu',
        keywords: ['soyadı kanunu', '21 haziran 1934', 'soyadı', 'lakap', 'ünvan', 'ağa', 'hacı', 'hoca', 'bey', 'paşa', 'efendi', 'atatürk'],
      ),
      
      // Atatürk İlkeleri
      SubtopicInfo(
        id: 'cumhuriyetcilik',
        name: 'Cumhuriyetçilik',
        keywords: ['cumhuriyetçilik', 'cumhuriyet', 'egemenlik', 'millet', 'seçim', 'meclis', 'demokrasi', 'halk iradesi', 'temsil'],
      ),
      SubtopicInfo(
        id: 'milliyetcilik',
        name: 'Milliyetçilik',
        keywords: ['milliyetçilik', 'millet', 'ulus', 'birlik', 'beraberlik', 'vatan', 'türk milleti', 'milli bilinç', 'milli kimlik'],
      ),
      SubtopicInfo(
        id: 'halcikilik',
        name: 'Halkçılık',
        keywords: ['halkçılık', 'halk', 'eşitlik', 'ayrıcalık', 'sınıf', 'imtiyaz', 'sosyal adalet', 'fırsat eşitliği'],
      ),
      SubtopicInfo(
        id: 'devletcilik',
        name: 'Devletçilik',
        keywords: ['devletçilik', 'devlet', 'ekonomi', 'sanayi', 'yatırım', 'kit', 'planlama', 'kalkınma', 'özel sektör'],
      ),
      SubtopicInfo(
        id: 'laiklik',
        name: 'Laiklik',
        keywords: ['laiklik', 'din', 'devlet', 'ayrılık', 'vicdan özgürlüğü', 'ibadet özgürlüğü', 'diyanet', 'anayasa', 'kanun'],
      ),
      SubtopicInfo(
        id: 'inkilapcilik',
        name: 'İnkılapçılık',
        keywords: ['inkılapçılık', 'devrimcilik', 'yenilik', 'değişim', 'modernleşme', 'çağdaşlaşma', 'ilerleme', 'koruma'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 6. CUMHURİYET DÖNEMİ TÜRKİYE TARİHİ
    // ─────────────────────────────────────────────────────────────────────────
    'onwrfsH02TgIhlyRUh56': [
      SubtopicInfo(
        id: 'tek_parti',
        name: 'Tek Parti Dönemi (1923-1946)',
        keywords: ['tek parti', 'chp', 'cumhuriyet halk partisi', 'halk fırkası', 'ismet inönü', 'celal bayar', 'şükrü saraçoğlu', 'milli şef', 'dünya savaşı', 'tarafsızlık'],
      ),
      SubtopicInfo(
        id: 'cok_partili_gecis',
        name: 'Çok Partili Hayata Geçiş',
        keywords: ['çok partili', 'demokrasi', 'demokrat parti', 'dp', 'celal bayar', 'adnan menderes', '1946 seçimleri', 'açık oy gizli sayım', '1950 seçimleri', 'iktidar değişikliği'],
      ),
      SubtopicInfo(
        id: 'demokrat_parti',
        name: 'Demokrat Parti Dönemi (1950-1960)',
        keywords: ['demokrat parti', 'menderes', 'celal bayar', 'liberal ekonomi', 'marshall yardımı', 'nato üyeliği', 'kore savaşı', 'kıbrıs', 'basın', 'muhalefet', '6-7 eylül'],
      ),
      SubtopicInfo(
        id: '27_mayis',
        name: '27 Mayıs 1960',
        keywords: ['27 mayıs', 'askeri müdahale', 'darbe', 'milli birlik komitesi', 'cemal gürsel', '1961 anayasası', 'yassıada', 'menderes', 'idam', 'kurucu meclis'],
      ),
      SubtopicInfo(
        id: '1961_71',
        name: '1961-1971 Dönemi',
        keywords: ['koalisyon', 'ismet inönü', 'süleyman demirel', 'ap', 'adalet partisi', 'planlı kalkınma', 'dpd', 'işçi hareketleri', 'öğrenci hareketleri', '12 mart'],
      ),
      SubtopicInfo(
        id: '12_mart',
        name: '12 Mart 1971 Muhtırası',
        keywords: ['12 mart', 'muhtıra', 'askeri müdahale', 'nihat erim', 'sıkıyönetim', 'anayasa değişikliği', 'sol örgütler', 'deniz gezmiş'],
      ),
      SubtopicInfo(
        id: '1971_80',
        name: '1971-1980 Dönemi',
        keywords: ['koalisyon', 'ecevit', 'demirel', 'erbakan', 'türkeş', 'kıbrıs barış harekatı', '1974', 'ambargo', 'ekonomik kriz', 'terör', 'sağ-sol çatışması'],
      ),
      SubtopicInfo(
        id: '12_eylul',
        name: '12 Eylül 1980',
        keywords: ['12 eylül', 'askeri darbe', 'kenan evren', 'milli güvenlik konseyi', '1982 anayasası', 'siyasi parti kapatma', 'sıkıyönetim', 'darağacı'],
      ),
      SubtopicInfo(
        id: '1983_sonrasi',
        name: '1983 Sonrası',
        keywords: ['turgut özal', 'anap', 'liberalizasyon', 'özelleştirme', 'gümrük birliği', 'ab adaylığı', 'körfez savaşı', 'kürt sorunu', 'koalisyonlar', 'akp', 'erdoğan'],
      ),
      SubtopicInfo(
        id: 'dis_politika_cumhuriyet',
        name: 'Cumhuriyet Dönemi Dış Politikası',
        keywords: ['dış politika', 'atatürk dönemi', 'yurtta sulh cihanda sulh', 'milletler cemiyeti', 'montrö', 'balkan antantı', 'sadabat paktı', 'hatay', 'nato', 'ab', 'kıbrıs', 'ege', 'yunanistan', 'suriye', 'irak'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 7. ÇAĞDAŞ TÜRK VE DÜNYA TARİHİ
    // ─────────────────────────────────────────────────────────────────────────
    'xQWHl1hBYAKM96X4deR8': [
      SubtopicInfo(
        id: 'ii_dunya_savasi',
        name: 'II. Dünya Savaşı',
        keywords: ['ikinci dünya savaşı', 'hitler', 'mussolini', 'almanya', 'japonya', 'italya', 'mihver', 'müttefik', 'abd', 'sscb', 'ingiltere', 'fransa', 'pearl harbor', 'stalingrad', 'normandiya', 'atom bombası', 'hiroşima', 'nagasaki', 'holokost'],
      ),
      SubtopicInfo(
        id: 'soguk_savas_baslangic',
        name: 'Soğuk Savaş\'ın Başlangıcı',
        keywords: ['soğuk savaş', 'demir perde', 'churchill', 'truman doktrini', 'marshall planı', 'nato', 'varşova paktı', 'blok', 'batı', 'doğu', 'kapitalizm', 'komünizm'],
      ),
      SubtopicInfo(
        id: 'bloklar',
        name: 'İki Kutuplu Dünya',
        keywords: ['batı bloku', 'doğu bloku', 'abd', 'sscb', 'soğuk savaş', 'silahlanma yarışı', 'nükleer', 'uzay yarışı', 'sputnik', 'apollo', 'casusluk', 'propaganda'],
      ),
      SubtopicInfo(
        id: 'soguk_savas_krizleri',
        name: 'Soğuk Savaş Krizleri',
        keywords: ['berlin krizi', 'berlin duvarı', 'kore savaşı', 'vietnam savaşı', 'küba krizi', 'füze krizi', 'afganistan', 'prag baharı', 'macaristan'],
      ),
      SubtopicInfo(
        id: 'bagimsizlik_hareketleri',
        name: 'Bağımsızlık Hareketleri',
        keywords: ['sömürgecilik', 'dekolonizasyon', 'afrika', 'asya', 'hindistan', 'gandhi', 'cezayir', 'vietnam', 'bağımsızlık', 'ulusal kurtuluş'],
      ),
      SubtopicInfo(
        id: 'ortadogu',
        name: 'Ortadoğu',
        keywords: ['ortadoğu', 'israil', 'filistin', 'arap-israil savaşları', 'süveyş', 'altı gün savaşı', 'yom kippur', 'camp david', 'oslo', 'intifada', 'petrol', 'opec'],
      ),
      SubtopicInfo(
        id: 'sscb_cokusu',
        name: 'SSCB\'nin Çöküşü',
        keywords: ['sscb', 'sovyetler birliği', 'gorbaçov', 'glasnost', 'perestroyka', 'berlin duvarı yıkılışı', '1989', '1991', 'bağımsız devletler topluluğu', 'bdt', 'rusya', 'türk cumhuriyetleri'],
      ),
      SubtopicInfo(
        id: 'kuresellesme',
        name: 'Küreselleşme',
        keywords: ['küreselleşme', 'globalleşme', 'internet', 'bilgi çağı', 'wto', 'imf', 'dünya bankası', 'çok uluslu şirketler', 'serbest ticaret', 'ab'],
      ),
      SubtopicInfo(
        id: 'guncel_gelismeler',
        name: 'Güncel Gelişmeler',
        keywords: ['11 eylül', 'terörizm', 'irak savaşı', 'arap baharı', 'suriye iç savaşı', 'göç', 'mülteci', 'rusya-ukrayna', 'çin yükselişi', 'yapay zeka'],
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════════════════
    // TÜRKÇE (9 Ana Konu)
    // ═══════════════════════════════════════════════════════════════════════════
    
    // ─────────────────────────────────────────────────────────────────────────
    // 1. SES BİLGİSİ
    // ─────────────────────────────────────────────────────────────────────────
    '80e0wkTLvaTQzPD6puB7': [
      SubtopicInfo(
        id: 'unlular',
        name: 'Ünlüler (Sesli Harfler)',
        keywords: ['ünlü', 'sesli', 'a', 'e', 'ı', 'i', 'o', 'ö', 'u', 'ü', 'kalın ünlü', 'ince ünlü', 'düz ünlü', 'yuvarlak ünlü', 'geniş ünlü', 'dar ünlü', '8 ünlü'],
      ),
      SubtopicInfo(
        id: 'unsuzler',
        name: 'Ünsüzler (Sessiz Harfler)',
        keywords: ['ünsüz', 'sessiz', 'sert ünsüz', 'yumuşak ünsüz', 'sürekli ünsüz', 'süreksiz ünsüz', 'f s t k ç ş h p', 'çıkış noktası', '21 ünsüz', 'dudak', 'diş', 'damak'],
      ),
      SubtopicInfo(
        id: 'ses_olaylari',
        name: 'Ses Olayları',
        keywords: ['ses olayı', 'ünsüz yumuşaması', 'ünsüz sertleşmesi', 'ünlü düşmesi', 'ünlü daralması', 'ünsüz düşmesi', 'ünsüz türemesi', 'ünlü türemesi', 'ses türemesi', 'ses düşmesi', 'ulama', 'kaynaşma', 'benzeşme'],
      ),
      SubtopicInfo(
        id: 'buyuk_unlu_uyumu',
        name: 'Büyük Ünlü Uyumu',
        keywords: ['büyük ünlü uyumu', 'kalınlık incelik', 'arka ünlü', 'ön ünlü', 'uyum bozukluğu', 'aykırı', 'anne', 'elma', 'kardeş', 'istisna'],
      ),
      SubtopicInfo(
        id: 'kucuk_unlu_uyumu',
        name: 'Küçük Ünlü Uyumu',
        keywords: ['küçük ünlü uyumu', 'düzlük yuvarlaklık', 'düz ünlü', 'yuvarlak ünlü', 'dar yuvarlak', 'geniş düz', 'uyum kuralı'],
      ),
      SubtopicInfo(
        id: 'hece',
        name: 'Hece Bilgisi',
        keywords: ['hece', 'açık hece', 'kapalı hece', 'hece sayısı', 'heceleme', 'ünlü sayısı', 'satır sonunda bölme'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 2. YAPI BİLGİSİ
    // ─────────────────────────────────────────────────────────────────────────
    'yWlh5C6jB7lzuJOodr2t': [
      SubtopicInfo(
        id: 'kok',
        name: 'Kök',
        keywords: ['kök', 'asıl kök', 'isim kökü', 'fiil kökü', 'sesteş kök', 'ortak kök', 'kök anlam', 'ek almamış'],
      ),
      SubtopicInfo(
        id: 'ek',
        name: 'Ek',
        keywords: ['ek', 'yapım eki', 'çekim eki', 'ek türleri', 'son ek', 'ön ek', 'iç ek'],
      ),
      SubtopicInfo(
        id: 'govde',
        name: 'Gövde',
        keywords: ['gövde', 'türemiş sözcük', 'kök + yapım eki', 'isim gövdesi', 'fiil gövdesi'],
      ),
      SubtopicInfo(
        id: 'isimden_isim',
        name: 'İsimden İsim Yapım Ekleri',
        keywords: ['isimden isim', '-lık', '-lı', '-sız', '-cı', '-ce', '-daş', '-sel', '-sal', '-ımsı', '-cil'],
      ),
      SubtopicInfo(
        id: 'isimden_fiil',
        name: 'İsimden Fiil Yapım Ekleri',
        keywords: ['isimden fiil', '-la', '-le', '-al', '-el', '-a', '-e', '-ar', '-da', '-sa', '-ık', '-imse'],
      ),
      SubtopicInfo(
        id: 'fiilden_isim',
        name: 'Fiilden İsim Yapım Ekleri',
        keywords: ['fiilden isim', '-ma', '-me', '-ış', '-iş', '-im', '-i', '-gi', '-gı', '-ak', '-ek', '-gan', '-gen', '-ıcı', '-ici', '-ıntı', '-inti'],
      ),
      SubtopicInfo(
        id: 'fiilden_fiil',
        name: 'Fiilden Fiil Yapım Ekleri',
        keywords: ['fiilden fiil', '-dır', '-dir', '-t', '-ıl', '-il', '-ın', '-in', '-ış', '-iş', 'ettirgen', 'edilgen', 'dönüşlü', 'işteş'],
      ),
      SubtopicInfo(
        id: 'cekim_ekleri',
        name: 'Çekim Ekleri',
        keywords: ['çekim eki', 'hal eki', 'iyelik eki', 'çoğul eki', 'kip eki', 'kişi eki', '-ler', '-de', '-den', '-e', '-i', '-in'],
      ),
      SubtopicInfo(
        id: 'birlesik_sozcuk',
        name: 'Birleşik Sözcükler',
        keywords: ['birleşik sözcük', 'birleşik isim', 'birleşik fiil', 'kaynaşma', 'kalıplaşma', 'anlam kayması', 'ses düşmesi'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 3. SÖZCÜK TÜRLERİ
    // ─────────────────────────────────────────────────────────────────────────
    'ICNDiSlTmmjWEQPT6rmT': [
      SubtopicInfo(
        id: 'isim',
        name: 'İsimler (Adlar)',
        keywords: ['isim', 'ad', 'somut isim', 'soyut isim', 'özel isim', 'cins isim', 'topluluk ismi', 'tekil', 'çoğul', 'varlık', 'kavram'],
      ),
      SubtopicInfo(
        id: 'sifat',
        name: 'Sıfatlar',
        keywords: ['sıfat', 'ön ad', 'niteleme sıfatı', 'belirtme sıfatı', 'işaret sıfatı', 'sayı sıfatı', 'soru sıfatı', 'belgisiz sıfat', 'sıfat tamlaması'],
      ),
      SubtopicInfo(
        id: 'zamir',
        name: 'Zamirler (Adıllar)',
        keywords: ['zamir', 'adıl', 'kişi zamiri', 'işaret zamiri', 'belgisiz zamir', 'soru zamiri', 'dönüşlülük zamiri', 'ilgi zamiri', 'ben', 'sen', 'o', 'biz'],
      ),
      SubtopicInfo(
        id: 'fiil',
        name: 'Fiiller (Eylemler)',
        keywords: ['fiil', 'eylem', 'kip', 'zaman', 'kişi', 'iş', 'oluş', 'hareket', 'bildirme kipleri', 'dilek kipleri', 'mastar'],
      ),
      SubtopicInfo(
        id: 'zarf',
        name: 'Zarflar (Belirteçler)',
        keywords: ['zarf', 'belirteç', 'durum zarfı', 'zaman zarfı', 'yer-yön zarfı', 'miktar zarfı', 'soru zarfı', 'nasıl', 'ne zaman', 'nerede'],
      ),
      SubtopicInfo(
        id: 'edat',
        name: 'Edatlar (İlgeçler)',
        keywords: ['edat', 'ilgeç', 'için', 'ile', 'gibi', 'kadar', 'göre', 'rağmen', 'doğru', 'karşı', 'üzere', 'dolayı'],
      ),
      SubtopicInfo(
        id: 'baglac',
        name: 'Bağlaçlar',
        keywords: ['bağlaç', 've', 'veya', 'ile', 'ama', 'fakat', 'ancak', 'ya da', 'hem', 'ne...ne', 'ki', 'de', 'çünkü', 'oysa'],
      ),
      SubtopicInfo(
        id: 'unlem',
        name: 'Ünlemler',
        keywords: ['ünlem', 'seslenme', 'duygu', 'ey', 'hey', 'eyvah', 'ah', 'of', 'aman', 'yazık', 'bravo'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 4. SÖZCÜKTE ANLAM
    // ─────────────────────────────────────────────────────────────────────────
    'JmyiPxf3n96Jkxqsa9jY': [
      SubtopicInfo(
        id: 'gercek_anlam',
        name: 'Gerçek (Temel) Anlam',
        keywords: ['gerçek anlam', 'temel anlam', 'ilk anlam', 'sözlük anlamı', 'nesnel anlam'],
      ),
      SubtopicInfo(
        id: 'mecaz_anlam',
        name: 'Mecaz Anlam',
        keywords: ['mecaz anlam', 'yan anlam', 'aktarma', 'benzetme', 'somutlaştırma', 'kişileştirme', 'ad aktarması'],
      ),
      SubtopicInfo(
        id: 'es_anlam',
        name: 'Eş Anlamlı Sözcükler',
        keywords: ['eş anlam', 'anlamdaş', 'sinonim', 'aynı anlam', 'yakın anlam'],
      ),
      SubtopicInfo(
        id: 'zit_anlam',
        name: 'Zıt Anlamlı Sözcükler',
        keywords: ['zıt anlam', 'karşıt anlam', 'antonim', 'ters anlam'],
      ),
      SubtopicInfo(
        id: 'es_sesli',
        name: 'Eş Sesli Sözcükler',
        keywords: ['eş sesli', 'sesteş', 'homonim', 'aynı yazılış', 'farklı anlam'],
      ),
      SubtopicInfo(
        id: 'deyim',
        name: 'Deyimler',
        keywords: ['deyim', 'kalıplaşmış söz', 'mecaz anlam', 'göz', 'el', 'baş', 'ayak', 'ağız', 'kalp', 'yüz'],
      ),
      SubtopicInfo(
        id: 'atasozu',
        name: 'Atasözleri',
        keywords: ['atasözü', 'öğüt', 'deneyim', 'anonim', 'halk', 'söz', 'ata', 'gelenek'],
      ),
      SubtopicInfo(
        id: 'sozcuk_iliskileri',
        name: 'Sözcük İlişkileri',
        keywords: ['genel özel', 'parça bütün', 'neden sonuç', 'anlam ilişkisi', 'üst kavram', 'alt kavram'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 5. CÜMLEDE ANLAM
    // ─────────────────────────────────────────────────────────────────────────
    'AJNLHhhaG2SLWOvxDYqW': [
      SubtopicInfo(
        id: 'cumle_ogeleri',
        name: 'Cümle Ögeleri',
        keywords: ['özne', 'yüklem', 'nesne', 'dolaylı tümleç', 'zarf tümleci', 'belirtili nesne', 'belirtisiz nesne', 'yer tamlayıcısı', 'edat tümleci'],
      ),
      SubtopicInfo(
        id: 'yuklem_turu',
        name: 'Yüklemine Göre Cümleler',
        keywords: ['fiil cümlesi', 'isim cümlesi', 'yüklem', 'eylem', 'ad', 'ek fiil'],
      ),
      SubtopicInfo(
        id: 'anlam_ozellikleri',
        name: 'Anlamına Göre Cümleler',
        keywords: ['olumlu', 'olumsuz', 'soru', 'ünlem', 'emir', 'istek', 'gereklilik', 'şart', 'koşul'],
      ),
      SubtopicInfo(
        id: 'anlam_iliskileri',
        name: 'Cümleler Arası Anlam İlişkileri',
        keywords: ['neden sonuç', 'amaç sonuç', 'koşul sonuç', 'karşılaştırma', 'açıklama', 'örnekleme', 'özet', 'sonuç'],
      ),
      SubtopicInfo(
        id: 'cumle_yorumlama',
        name: 'Cümle Yorumlama',
        keywords: ['öznel', 'nesnel', 'varsayım', 'öneri', 'eleştiri', 'tahmin', 'yargı', 'kanı', 'görüş'],
      ),
      SubtopicInfo(
        id: 'devrik_kuralli',
        name: 'Devrik ve Kurallı Cümle',
        keywords: ['devrik', 'kurallı', 'yüklem sonda', 'yüklem başta', 'yüklem ortada', 'eksiltili'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 6. PARAGRAFTA ANLAM
    // ─────────────────────────────────────────────────────────────────────────
    'nN8JOTR7LZm01AN2i3sQ': [
      SubtopicInfo(
        id: 'ana_dusunce',
        name: 'Ana Düşünce (Ana Fikir)',
        keywords: ['ana düşünce', 'ana fikir', 'asıl mesaj', 'temel düşünce', 'vermek istenen', 'amaç'],
      ),
      SubtopicInfo(
        id: 'yardimci_dusunce',
        name: 'Yardımcı Düşünceler',
        keywords: ['yardımcı düşünce', 'yan fikir', 'destekleyici', 'detay', 'örnek', 'açıklama'],
      ),
      SubtopicInfo(
        id: 'konu',
        name: 'Konu',
        keywords: ['konu', 'ne anlatılıyor', 'tema', 'içerik', 'üzerinde durulan'],
      ),
      SubtopicInfo(
        id: 'baslik',
        name: 'Başlık',
        keywords: ['başlık', 'isim', 'paragrafı özetleyen', 'içeriği yansıtan'],
      ),
      SubtopicInfo(
        id: 'paragraf_turleri',
        name: 'Paragraf Türleri',
        keywords: ['açıklayıcı', 'betimleyici', 'öyküleyici', 'tartışmacı', 'düşünsel', 'duygusal'],
      ),
      SubtopicInfo(
        id: 'paragraf_yapisi',
        name: 'Paragraf Yapısı',
        keywords: ['giriş', 'gelişme', 'sonuç', 'bütünlük', 'tutarlılık', 'akıcılık', 'bağdaşıklık'],
      ),
      SubtopicInfo(
        id: 'cumle_yerlestime',
        name: 'Cümle Yerleştirme',
        keywords: ['cümle yerleştirme', 'paragraf tamamlama', 'boşluk doldurma', 'anlam bütünlüğü'],
      ),
      SubtopicInfo(
        id: 'paragraf_siralama',
        name: 'Paragraf Sıralama',
        keywords: ['paragraf sıralama', 'mantıksal sıra', 'zaman sırası', 'neden sonuç'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 7. ANLATIM BOZUKLUKLARI
    // ─────────────────────────────────────────────────────────────────────────
    'jXcsrl5HEb65DmfpfqqI': [
      SubtopicInfo(
        id: 'gereksiz_sozcuk',
        name: 'Gereksiz Sözcük Kullanımı',
        keywords: ['gereksiz sözcük', 'fazlalık', 'anlatım bozukluğu', 'tekrar', 'eş anlamlı tekrar'],
      ),
      SubtopicInfo(
        id: 'anlam_belirsizligi',
        name: 'Anlam Belirsizliği',
        keywords: ['belirsizlik', 'iki anlamlılık', 'muğlaklık', 'karışıklık', 'yanlış anlaşılma'],
      ),
      SubtopicInfo(
        id: 'mantik_hatasi',
        name: 'Mantık Hatası',
        keywords: ['mantık hatası', 'çelişki', 'tutarsızlık', 'mantıksızlık', 'abartı', 'genelleme'],
      ),
      SubtopicInfo(
        id: 'ozne_yüklem_uyumsuzlugu',
        name: 'Özne-Yüklem Uyumsuzluğu',
        keywords: ['özne yüklem', 'uyumsuzluk', 'kişi uyumsuzluğu', 'tekillik çoğulluk'],
      ),
      SubtopicInfo(
        id: 'tamlama_bozuklugu',
        name: 'Tamlama Bozukluğu',
        keywords: ['tamlama', 'isim tamlaması', 'sıfat tamlaması', 'eksiklik', 'yanlış ek'],
      ),
      SubtopicInfo(
        id: 'baglac_edat_hatasi',
        name: 'Bağlaç ve Edat Hataları',
        keywords: ['bağlaç hatası', 'edat hatası', 'yanlış kullanım', 'gereksiz bağlaç'],
      ),
      SubtopicInfo(
        id: 'cati_uyumsuzlugu',
        name: 'Çatı Uyumsuzluğu',
        keywords: ['çatı', 'etken', 'edilgen', 'dönüşlü', 'işteş', 'uyumsuzluk'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 8. YAZIM VE NOKTALAMA KURALLARI
    // ─────────────────────────────────────────────────────────────────────────
    'qSEqigIsIEBAkhcMTyCE': [
      SubtopicInfo(
        id: 'buyuk_harf',
        name: 'Büyük Harf Kullanımı',
        keywords: ['büyük harf', 'özel isim', 'cümle başı', 'başlık', 'kurum', 'unvan', 'coğrafi', 'yer adı', 'kişi adı'],
      ),
      SubtopicInfo(
        id: 'birlesik_yazilan',
        name: 'Birleşik Yazılan Sözcükler',
        keywords: ['birleşik yazım', 'bitişik', 'kaynaşma', 'ses düşmesi', 'anlam kayması'],
      ),
      SubtopicInfo(
        id: 'ayri_yazilan',
        name: 'Ayrı Yazılan Sözcükler',
        keywords: ['ayrı yazım', 'birleşik fiil', 'deyim', 'ikilemeler', 'pekiştirme'],
      ),
      SubtopicInfo(
        id: 'ki_de_mi',
        name: 'ki, de, mi Yazımı',
        keywords: ['ki eki', 'de da', 'mi mı', 'bağlaç', 'soru eki', 'ayrı yazım', 'bitişik yazım'],
      ),
      SubtopicInfo(
        id: 'sayilarin_yazimi',
        name: 'Sayıların Yazımı',
        keywords: ['sayı yazımı', 'rakam', 'yazıyla', 'tarih', 'saat', 'para', 'ölçü'],
      ),
      SubtopicInfo(
        id: 'kisaltmalar',
        name: 'Kısaltmalar',
        keywords: ['kısaltma', 'simge', 'nokta', 'büyük harf', 'kurum adı', 'ölçü birimi'],
      ),
      SubtopicInfo(
        id: 'nokta',
        name: 'Nokta',
        keywords: ['nokta', 'cümle sonu', 'kısaltma', 'sıra sayısı', 'tarih', 'saat'],
      ),
      SubtopicInfo(
        id: 'virgul',
        name: 'Virgül',
        keywords: ['virgül', 'sıralama', 'ara söz', 'seslenme', 'uzun cümle', 'açıklama'],
      ),
      SubtopicInfo(
        id: 'diger_isaretler',
        name: 'Diğer Noktalama İşaretleri',
        keywords: ['noktalı virgül', 'iki nokta', 'üç nokta', 'soru işareti', 'ünlem', 'tırnak', 'parantez', 'kısa çizgi', 'uzun çizgi'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 9. SÖZEL MANTIK
    // ─────────────────────────────────────────────────────────────────────────
    'wnt2zWaV1pX8p8s8BBc9': [
      SubtopicInfo(
        id: 'tumdengelim',
        name: 'Tümdengelim',
        keywords: ['tümdengelim', 'genelden özele', 'dedüksiyon', 'öncül', 'sonuç', 'çıkarım'],
      ),
      SubtopicInfo(
        id: 'tumevarim',
        name: 'Tümevarım',
        keywords: ['tümevarım', 'özelden genele', 'indüksiyon', 'örneklerden sonuç', 'genelleme'],
      ),
      SubtopicInfo(
        id: 'analoji',
        name: 'Analoji (Benzetme)',
        keywords: ['analoji', 'benzetme', 'karşılaştırma', 'örnekseme', 'paralellik'],
      ),
      SubtopicInfo(
        id: 'sozel_oruntu',
        name: 'Sözel Örüntü',
        keywords: ['sözel örüntü', 'kelime ilişkisi', 'eş anlam', 'zıt anlam', 'parça bütün', 'neden sonuç'],
      ),
      SubtopicInfo(
        id: 'mantiksal_siralama',
        name: 'Mantıksal Sıralama',
        keywords: ['mantıksal sıralama', 'zaman sırası', 'öncelik sonralık', 'sebep sonuç sırası'],
      ),
      SubtopicInfo(
        id: 'sonuc_cikarma',
        name: 'Sonuç Çıkarma',
        keywords: ['sonuç çıkarma', 'çıkarım', 'yargı', 'vargı', 'kesin sonuç', 'olası sonuç'],
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════════════════
    // COĞRAFYA (6 Ana Konu)
    // ═══════════════════════════════════════════════════════════════════════════
    
    // ─────────────────────────────────────────────────────────────────────────
    // 1. TÜRKİYE'NİN COĞRAFİ KONUMU
    // ─────────────────────────────────────────────────────────────────────────
    '1FEcPsGduhjcQARpaGBk': [
      SubtopicInfo(
        id: 'matematik_konum',
        name: 'Matematik Konum',
        keywords: ['matematik konum', 'enlem', 'boylam', 'paralel', 'meridyen', 'koordinat', '36-42 kuzey', '26-45 doğu', 'başlangıç meridyeni', 'ekvator', 'kutup'],
      ),
      SubtopicInfo(
        id: 'ozel_konum',
        name: 'Özel (Göreceli) Konum',
        keywords: ['özel konum', 'göreceli konum', 'jeopolitik', 'stratejik', 'boğazlar', 'köprü', 'geçiş', 'kıtalar arası', 'asya', 'avrupa', 'enerji koridoru', 'ticaret yolu'],
      ),
      SubtopicInfo(
        id: 'komsu_ulkeler',
        name: 'Komşu Ülkeler ve Sınırlar',
        keywords: ['komşu', 'sınır', 'yunanistan', 'bulgaristan', 'gürcistan', 'ermenistan', 'nahçıvan', 'iran', 'irak', 'suriye', 'karadeniz', 'akdeniz', 'ege', 'kara sınırı', 'deniz sınırı'],
      ),
      SubtopicInfo(
        id: 'konum_sonuclari',
        name: 'Konumun Sonuçları',
        keywords: ['yerel saat', 'saat farkı', 'mevsim', 'iklim çeşitliliği', 'bitki çeşitliliği', 'tarım çeşitliliği', 'turizm', 'gündüz süresi'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 2. TÜRKİYE'NİN FİZİKİ ÖZELLİKLERİ
    // ─────────────────────────────────────────────────────────────────────────
    'kbs0Ffved9pCP3Hq9M9k': [
      SubtopicInfo(
        id: 'jeolojik_yapi',
        name: 'Jeolojik Yapı ve Tektonik',
        keywords: ['jeoloji', 'tektonik', 'levha', 'fay', 'kuzey anadolu fayı', 'doğu anadolu fayı', 'deprem', 'volkan', 'sismik', 'kıvrım', 'kırık'],
      ),
      SubtopicInfo(
        id: 'yer_sekilleri',
        name: 'Yer Şekilleri',
        keywords: ['yer şekli', 'dağ', 'ova', 'plato', 'vadi', 'kanyon', 'mağara', 'delta', 'traverten', 'peri bacası', 'lapya', 'dolin', 'obruk'],
      ),
      SubtopicInfo(
        id: 'daglar',
        name: 'Dağlar',
        keywords: ['dağ', 'sıradağ', 'kuzey anadolu dağları', 'toros dağları', 'batı anadolu', 'volkanik', 'ağrı', 'erciyes', 'süphan', 'nemrut', 'kaçkar', 'uludağ', 'ilgaz', 'köroğlu'],
      ),
      SubtopicInfo(
        id: 'ovalar_platolar',
        name: 'Ovalar ve Platolar',
        keywords: ['ova', 'plato', 'çukurova', 'bafra', 'çarşamba', 'gediz', 'büyük menderes', 'konya ovası', 'iç anadolu platosu', 'haymana', 'cihanbeyli', 'obruk platosu'],
      ),
      SubtopicInfo(
        id: 'akarsular',
        name: 'Akarsular',
        keywords: ['akarsu', 'nehir', 'çay', 'dere', 'fırat', 'dicle', 'kızılırmak', 'yeşilırmak', 'sakarya', 'büyük menderes', 'seyhan', 'ceyhan', 'gediz', 'meriç', 'çoruh', 'aras', 'rejim', 'debi'],
      ),
      SubtopicInfo(
        id: 'goller',
        name: 'Göller',
        keywords: ['göl', 'tektonik göl', 'volkanik göl', 'karstik göl', 'set gölü', 'lagün', 'van gölü', 'tuz gölü', 'beyşehir', 'eğirdir', 'burdur', 'iznik', 'ulubat', 'sapanca', 'abant', 'nemrut gölü'],
      ),
      SubtopicInfo(
        id: 'kiyi_sekilleri',
        name: 'Kıyı Şekilleri',
        keywords: ['kıyı', 'falez', 'kumsal', 'delta', 'lagün', 'tombolo', 'körfez', 'burun', 'yarımada', 'ada', 'koy', 'boğaz', 'haliç', 'ria', 'dalmaçya', 'limanlık'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 3. TÜRKİYE'NİN İKLİMİ
    // ─────────────────────────────────────────────────────────────────────────
    '6e0Thsz2RRNHFcwqQXso': [
      SubtopicInfo(
        id: 'iklim_elemanlari',
        name: 'İklim Elemanları',
        keywords: ['iklim elemanı', 'sıcaklık', 'basınç', 'rüzgar', 'yağış', 'nem', 'buharlaşma', 'güneşlenme', 'bulutluluk'],
      ),
      SubtopicInfo(
        id: 'sicaklik',
        name: 'Sıcaklık',
        keywords: ['sıcaklık', 'yıllık sıcaklık ortalaması', 'amplitüd', 'sıcaklık farkı', 'enlem', 'yükselti', 'denize uzaklık', 'bakı', 'karasallık'],
      ),
      SubtopicInfo(
        id: 'yagis',
        name: 'Yağış',
        keywords: ['yağış', 'yağmur', 'kar', 'dolu', 'çiy', 'kırağı', 'orografik', 'konveksiyonel', 'cephesel', 'yağış rejimi'],
      ),
      SubtopicInfo(
        id: 'ruzgarlar',
        name: 'Rüzgarlar',
        keywords: ['rüzgar', 'meltem', 'poyraz', 'lodos', 'karayel', 'samyeli', 'fön', 'etezyen', 'monsun', 'batı rüzgarları'],
      ),
      SubtopicInfo(
        id: 'iklim_tipleri',
        name: 'İklim Tipleri',
        keywords: ['iklim tipi', 'akdeniz iklimi', 'karadeniz iklimi', 'karasal iklim', 'marmara iklimi', 'step iklimi', 'yarı kurak', 'nemli'],
      ),
      SubtopicInfo(
        id: 'bitki_ortusu',
        name: 'Bitki Örtüsü',
        keywords: ['bitki örtüsü', 'orman', 'maki', 'step', 'çayır', 'pseudomaki', 'garig', 'alpin', 'iğne yapraklı', 'geniş yapraklı', 'karışık orman'],
      ),
      SubtopicInfo(
        id: 'toprak',
        name: 'Toprak Tipleri',
        keywords: ['toprak', 'alüvyal', 'kestane rengi', 'kahverengi', 'terra rossa', 'kırmızı akdeniz', 'çernozyom', 'podzol', 'laterit', 'tuzlu toprak'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 4. BEŞERİ COĞRAFYA
    // ─────────────────────────────────────────────────────────────────────────
    'uYDrMlBCEAho5776WZi8': [
      SubtopicInfo(
        id: 'nufus_ozellikleri',
        name: 'Nüfus Özellikleri',
        keywords: ['nüfus', 'nüfus sayımı', 'nüfus artışı', 'doğal artış', 'doğum oranı', 'ölüm oranı', 'nüfus yoğunluğu', 'aritmetik yoğunluk', 'fizyolojik yoğunluk'],
      ),
      SubtopicInfo(
        id: 'nufus_yapisi',
        name: 'Nüfus Yapısı',
        keywords: ['nüfus yapısı', 'yaş yapısı', 'cinsiyet yapısı', 'nüfus piramidi', 'genç nüfus', 'yaşlı nüfus', 'aktif nüfus', 'çalışan nüfus', 'bağımlı nüfus'],
      ),
      SubtopicInfo(
        id: 'nufus_dagilisi',
        name: 'Nüfus Dağılışı',
        keywords: ['nüfus dağılışı', 'yoğun nüfus', 'seyrek nüfus', 'sıkışma alanı', 'iklim', 'yer şekli', 'tarım', 'sanayi', 'kıyı'],
      ),
      SubtopicInfo(
        id: 'gocler',
        name: 'Göçler',
        keywords: ['göç', 'iç göç', 'dış göç', 'beyin göçü', 'mübadele', 'mülteci', 'sığınmacı', 'işçi göçü', 'kırdan kente', 'itici faktör', 'çekici faktör'],
      ),
      SubtopicInfo(
        id: 'yerlesme',
        name: 'Yerleşme',
        keywords: ['yerleşme', 'kır yerleşmesi', 'kent yerleşmesi', 'köy', 'kasaba', 'şehir', 'metropol', 'megakent', 'toplu yerleşme', 'dağınık yerleşme', 'gecekondu'],
      ),
      SubtopicInfo(
        id: 'kentlesme',
        name: 'Kentleşme',
        keywords: ['kentleşme', 'şehirleşme', 'kentsel dönüşüm', 'planlı kentleşme', 'çarpık kentleşme', 'kentsel sorunlar', 'altyapı', 'ulaşım', 'çevre kirliliği'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 5. EKONOMİK COĞRAFYA
    // ─────────────────────────────────────────────────────────────────────────
    'WxrtQ26p2My4uJa0h1kk': [
      SubtopicInfo(
        id: 'tarim_genel',
        name: 'Tarım (Genel)',
        keywords: ['tarım', 'tarımsal üretim', 'tarım alanı', 'sulamalı tarım', 'kuru tarım', 'seracılık', 'organik tarım', 'tarım politikası', 'verim'],
      ),
      SubtopicInfo(
        id: 'bitkisel_uretim',
        name: 'Bitkisel Üretim',
        keywords: ['bitkisel üretim', 'tahıl', 'buğday', 'arpa', 'mısır', 'pirinç', 'endüstri bitkisi', 'pamuk', 'tütün', 'şekerpancarı', 'ayçiçeği', 'çay', 'fındık', 'zeytin', 'üzüm', 'turunçgil'],
      ),
      SubtopicInfo(
        id: 'hayvancilik',
        name: 'Hayvancılık',
        keywords: ['hayvancılık', 'büyükbaş', 'küçükbaş', 'kümes', 'arıcılık', 'ipek böcekçiliği', 'süt', 'et', 'deri', 'yün', 'bal', 'mera', 'ahır'],
      ),
      SubtopicInfo(
        id: 'balikcilik',
        name: 'Balıkçılık',
        keywords: ['balıkçılık', 'su ürünleri', 'deniz balıkçılığı', 'tatlı su balıkçılığı', 'kültür balıkçılığı', 'hamsi', 'sardalya', 'palamut', 'levrek', 'çipura', 'alabalık'],
      ),
      SubtopicInfo(
        id: 'madenler',
        name: 'Madenler',
        keywords: ['maden', 'metalik maden', 'demir', 'bakır', 'krom', 'boksit', 'kurşun', 'çinko', 'altın', 'gümüş', 'endüstriyel maden', 'bor', 'mermer', 'tuz', 'kükürt'],
      ),
      SubtopicInfo(
        id: 'enerji',
        name: 'Enerji Kaynakları',
        keywords: ['enerji', 'fosil yakıt', 'kömür', 'linyit', 'taşkömürü', 'petrol', 'doğalgaz', 'yenilenebilir', 'hidroelektrik', 'rüzgar', 'güneş', 'jeotermal', 'biyokütle', 'nükleer'],
      ),
      SubtopicInfo(
        id: 'sanayi',
        name: 'Sanayi',
        keywords: ['sanayi', 'sanayi sektörü', 'ağır sanayi', 'hafif sanayi', 'organize sanayi', 'tekstil', 'gıda', 'otomotiv', 'demir çelik', 'petrokimya', 'makine', 'elektronik'],
      ),
      SubtopicInfo(
        id: 'ulasim',
        name: 'Ulaşım',
        keywords: ['ulaşım', 'karayolu', 'demiryolu', 'havayolu', 'denizyolu', 'boru hattı', 'otoban', 'köprü', 'tünel', 'liman', 'havalimanı', 'transit'],
      ),
      SubtopicInfo(
        id: 'ticaret',
        name: 'Ticaret',
        keywords: ['ticaret', 'iç ticaret', 'dış ticaret', 'ihracat', 'ithalat', 'dış ticaret açığı', 'dış ticaret dengesi', 'serbest bölge', 'gümrük birliği'],
      ),
      SubtopicInfo(
        id: 'turizm',
        name: 'Turizm',
        keywords: ['turizm', 'kültür turizmi', 'deniz turizmi', 'kış turizmi', 'sağlık turizmi', 'kongre turizmi', 'eko turizm', 'termal turizm', 'turist', 'turizm geliri'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 6. COĞRAFİ BÖLGELER
    // ─────────────────────────────────────────────────────────────────────────
    'GdpN8uxJNGtexWrkoL1T': [
      SubtopicInfo(
        id: 'bolge_kavrami',
        name: 'Bölge Kavramı',
        keywords: ['bölge', 'coğrafi bölge', 'bölüm', 'yöre', 'fonksiyonel bölge', 'homojen bölge', 'plan bölgesi', 'düğüm bölgesi'],
      ),
      SubtopicInfo(
        id: 'marmara',
        name: 'Marmara Bölgesi',
        keywords: ['marmara', 'istanbul', 'bursa', 'kocaeli', 'sakarya', 'edirne', 'tekirdağ', 'balıkesir', 'çanakkale', 'sanayi', 'nüfus', 'ticaret', 'ulaşım', 'tarım', 'trakya', 'güney marmara'],
      ),
      SubtopicInfo(
        id: 'ege',
        name: 'Ege Bölgesi',
        keywords: ['ege', 'izmir', 'manisa', 'aydın', 'denizli', 'muğla', 'afyon', 'kütahya', 'uşak', 'pamuk', 'zeytin', 'üzüm', 'turizm', 'tütün', 'incir', 'graben', 'horst'],
      ),
      SubtopicInfo(
        id: 'akdeniz',
        name: 'Akdeniz Bölgesi',
        keywords: ['akdeniz', 'antalya', 'adana', 'mersin', 'hatay', 'isparta', 'burdur', 'kahramanmaraş', 'osmaniye', 'turunçgil', 'muz', 'pamuk', 'turizm', 'çukurova', 'toros'],
      ),
      SubtopicInfo(
        id: 'karadeniz',
        name: 'Karadeniz Bölgesi',
        keywords: ['karadeniz', 'samsun', 'trabzon', 'ordu', 'giresun', 'rize', 'zonguldak', 'çay', 'fındık', 'mısır', 'taşkömürü', 'yağış', 'orman', 'balıkçılık', 'heyelan'],
      ),
      SubtopicInfo(
        id: 'ic_anadolu',
        name: 'İç Anadolu Bölgesi',
        keywords: ['iç anadolu', 'ankara', 'konya', 'eskişehir', 'kayseri', 'sivas', 'yozgat', 'aksaray', 'nevşehir', 'buğday', 'arpa', 'step', 'karasal', 'tuz gölü', 'kapadokya'],
      ),
      SubtopicInfo(
        id: 'dogu_anadolu',
        name: 'Doğu Anadolu Bölgesi',
        keywords: ['doğu anadolu', 'erzurum', 'van', 'malatya', 'elazığ', 'diyarbakır', 'ağrı', 'kars', 'erzincan', 'hayvancılık', 'yükselti', 'karasal', 'kayısı', 'volkanik', 'akarsu'],
      ),
      SubtopicInfo(
        id: 'guneydogu_anadolu',
        name: 'Güneydoğu Anadolu Bölgesi',
        keywords: ['güneydoğu anadolu', 'gaziantep', 'şanlıurfa', 'diyarbakır', 'mardin', 'batman', 'şırnak', 'siirt', 'gap', 'pamuk', 'antep fıstığı', 'petrol', 'buğday', 'sulama'],
      ),
    ],
    
    // ═══════════════════════════════════════════════════════════════════════════
    // VATANDAŞLIK (6 Ana Konu)
    // ═══════════════════════════════════════════════════════════════════════════
    
    // ─────────────────────────────────────────────────────────────────────────
    // 1. HUKUKA GİRİŞ
    // ─────────────────────────────────────────────────────────────────────────
    'AQ0Zph76dzPdr87H1uKa': [
      SubtopicInfo(
        id: 'hukuk_tanimi',
        name: 'Hukukun Tanımı ve Özellikleri',
        keywords: ['hukuk', 'tanım', 'kural', 'toplum düzeni', 'yaptırım', 'müeyyide', 'kamu gücü', 'zorunlu', 'bağlayıcı', 'genel', 'sürekli'],
      ),
      SubtopicInfo(
        id: 'sosyal_kurallar',
        name: 'Sosyal Düzen Kuralları',
        keywords: ['sosyal kural', 'ahlak', 'din', 'görgü', 'gelenek', 'örf adet', 'hukuk', 'yaptırım', 'fark'],
      ),
      SubtopicInfo(
        id: 'hukuk_kaynaklari',
        name: 'Hukukun Kaynakları',
        keywords: ['kaynak', 'yazılı kaynak', 'anayasa', 'kanun', 'khk', 'cumhurbaşkanlığı kararnamesi', 'tüzük', 'yönetmelik', 'içtihat', 'örf adet', 'doktrin', 'normlar hiyerarşisi'],
      ),
      SubtopicInfo(
        id: 'hukuk_dallari',
        name: 'Hukuk Dalları',
        keywords: ['kamu hukuku', 'özel hukuk', 'karma hukuk', 'anayasa hukuku', 'idare hukuku', 'ceza hukuku', 'medeni hukuk', 'borçlar hukuku', 'ticaret hukuku', 'iş hukuku', 'uluslararası hukuk'],
      ),
      SubtopicInfo(
        id: 'yargi_sistemi',
        name: 'Yargı Sistemi',
        keywords: ['yargı', 'mahkeme', 'yüksek mahkeme', 'anayasa mahkemesi', 'yargıtay', 'danıştay', 'sayıştay', 'uyuşmazlık mahkemesi', 'adli yargı', 'idari yargı', 'askeri yargı'],
      ),
      SubtopicInfo(
        id: 'hukuki_kavramlar',
        name: 'Temel Hukuki Kavramlar',
        keywords: ['hak', 'hukuki işlem', 'hukuki olay', 'hukuki fiil', 'kişi', 'gerçek kişi', 'tüzel kişi', 'ehliyet', 'fiil ehliyeti', 'hak ehliyeti'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 2. ANAYASA HUKUKU
    // ─────────────────────────────────────────────────────────────────────────
    'n4OjWupHmouuybQzQ1Fc': [
      SubtopicInfo(
        id: 'anayasa_kavrami',
        name: 'Anayasa Kavramı',
        keywords: ['anayasa', 'temel yasa', 'kurucu iktidar', 'devlet yapısı', 'temel haklar', 'üstün norm', 'bağlayıcılık'],
      ),
      SubtopicInfo(
        id: 'anayasa_turleri',
        name: 'Anayasa Türleri',
        keywords: ['yazılı anayasa', 'yazısız anayasa', 'katı anayasa', 'yumuşak anayasa', 'çerçeve anayasa', 'kazuistik anayasa', 'federal anayasa', 'üniter anayasa'],
      ),
      SubtopicInfo(
        id: 'osmanli_anayasalari',
        name: 'Osmanlı Dönemi Anayasal Belgeler',
        keywords: ['sened-i ittifak', 'tanzimat', 'gülhane', 'islahat fermanı', 'kanun-i esasi', '1876', 'meşrutiyet', 'meclis-i mebusan', 'meclis-i ayan'],
      ),
      SubtopicInfo(
        id: 'cumhuriyet_anayasalari',
        name: 'Cumhuriyet Dönemi Anayasaları',
        keywords: ['1921 anayasası', 'teşkilat-ı esasiye', '1924 anayasası', '1961 anayasası', '1982 anayasası', 'kurucu meclis', 'anayasa değişikliği', 'referandum'],
      ),
      SubtopicInfo(
        id: 'anayasa_degisikligi',
        name: 'Anayasa Değişikliği',
        keywords: ['anayasa değişikliği', 'teklif', 'görüşme', 'kabul', 'onay', 'referandum', 'halk oylaması', 'değiştirilemez hükümler', '3/5', '2/3'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 3. 1982 ANAYASASI
    // ─────────────────────────────────────────────────────────────────────────
    'xXGXiqx2TkCtI4C7GMQg': [
      SubtopicInfo(
        id: 'genel_esaslar',
        name: 'Genel Esaslar',
        keywords: ['cumhuriyet', 'devletin şekli', 'nitelikleri', 'demokratik', 'laik', 'sosyal', 'hukuk devleti', 'atatürk ilkeleri', 'türk milleti', 'egemenlik', 'değiştirilemez'],
      ),
      SubtopicInfo(
        id: 'temel_haklar',
        name: 'Temel Haklar ve Ödevler',
        keywords: ['temel hak', 'özgürlük', 'kişi hakları', 'sosyal haklar', 'siyasi haklar', 'yaşam hakkı', 'kişi dokunulmazlığı', 'özel hayat', 'konut', 'din vicdan', 'düşünce', 'basın', 'dernek', 'toplantı'],
      ),
      SubtopicInfo(
        id: 'hak_sinirlandirma',
        name: 'Temel Hakların Sınırlandırılması',
        keywords: ['sınırlandırma', 'kanunla', 'ölçülülük', 'demokratik toplum', 'laik cumhuriyet', 'olağanüstü hal', 'sıkıyönetim', 'savaş', 'seferberlik', 'çekirdek alan'],
      ),
      SubtopicInfo(
        id: 'vatandaslik_hukuku',
        name: 'Vatandaşlık',
        keywords: ['vatandaşlık', 'türk vatandaşı', 'doğumla', 'sonradan', 'kazanma', 'kaybetme', 'çifte vatandaşlık', 'vatandaşlık bağı', 'yabancı'],
      ),
      SubtopicInfo(
        id: 'secme_secilme',
        name: 'Seçme ve Seçilme Hakkı',
        keywords: ['seçme hakkı', 'seçilme hakkı', 'oy hakkı', 'seçim', 'genel oy', 'eşit oy', 'gizli oy', 'açık sayım', 'seçim barajı', 'milletvekilliği', 'cumhurbaşkanlığı'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 4. DEVLET ORGANLARI
    // ─────────────────────────────────────────────────────────────────────────
    '1JZAYECyEn7farNNyGyx': [
      SubtopicInfo(
        id: 'yasama_tbmm',
        name: 'Yasama (TBMM)',
        keywords: ['yasama', 'tbmm', 'büyük millet meclisi', 'milletvekili', '600', 'yasa', 'kanun', 'komisyon', 'genel kurul', 'meclis başkanı', 'yasama dokunulmazlığı', 'yasama sorumsuzluğu'],
      ),
      SubtopicInfo(
        id: 'tbmm_gorevleri',
        name: 'TBMM\'nin Görev ve Yetkileri',
        keywords: ['kanun yapmak', 'değiştirmek', 'kaldırmak', 'bütçe', 'kesin hesap', 'para basma', 'savaş ilanı', 'af', 'genel af', 'özel af', 'milletlerarası antlaşma', 'denetim'],
      ),
      SubtopicInfo(
        id: 'yurutme_cumhurbaskani',
        name: 'Yürütme (Cumhurbaşkanı)',
        keywords: ['yürütme', 'cumhurbaşkanı', 'devlet başkanı', 'hükümet başkanı', '5 yıl', 'iki dönem', 'seçim', 'yemin', 'cumhurbaşkanlığı kararnamesi', 'veto', 'iade', 'atama'],
      ),
      SubtopicInfo(
        id: 'cumhurbaskani_gorevleri',
        name: 'Cumhurbaşkanının Görev ve Yetkileri',
        keywords: ['yasama ile ilgili', 'yürütme ile ilgili', 'yargı ile ilgili', 'kararname', 'atama', 'af yetkisi', 'olağanüstü hal', 'temsil', 'komutan'],
      ),
      SubtopicInfo(
        id: 'yurutme_bakanlar',
        name: 'Bakanlar ve Bakanlıklar',
        keywords: ['bakan', 'bakanlık', 'atama', 'görevden alma', 'cumhurbaşkanı yardımcısı', 'bakanlık teşkilatı', 'merkez teşkilatı', 'taşra teşkilatı'],
      ),
      SubtopicInfo(
        id: 'yargi_genel',
        name: 'Yargı',
        keywords: ['yargı', 'bağımsız', 'tarafsız', 'hakim', 'savcı', 'teminat', 'azledilemez', 'görevden alınamaz', 'mahkeme', 'yüksek mahkeme', 'adli yargı', 'idari yargı'],
      ),
      SubtopicInfo(
        id: 'anayasa_mahkemesi',
        name: 'Anayasa Mahkemesi',
        keywords: ['anayasa mahkemesi', 'anayasaya uygunluk', 'iptal davası', 'bireysel başvuru', 'siyasi parti kapatma', 'yüce divan', 'üye', '15 üye', 'cumhurbaşkanı', 'tbmm'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 5. İDARİ YAPI
    // ─────────────────────────────────────────────────────────────────────────
    'lv93cmhwq7RmOFM5WxWD': [
      SubtopicInfo(
        id: 'idare_kavrami',
        name: 'İdare Kavramı',
        keywords: ['idare', 'kamu idaresi', 'devlet idaresi', 'idari işlem', 'idari eylem', 'idarenin bütünlüğü', 'idari vesayet', 'hiyerarşi'],
      ),
      SubtopicInfo(
        id: 'merkezi_idare',
        name: 'Merkezi İdare',
        keywords: ['merkezi idare', 'cumhurbaşkanlığı', 'bakanlık', 'merkez teşkilatı', 'başkent teşkilatı', 'taşra teşkilatı', 'il', 'ilçe', 'bucak', 'vali', 'kaymakam'],
      ),
      SubtopicInfo(
        id: 'yerel_yonetimler',
        name: 'Yerel Yönetimler',
        keywords: ['yerel yönetim', 'mahalli idare', 'il özel idaresi', 'belediye', 'köy', 'büyükşehir belediyesi', 'belediye başkanı', 'belediye meclisi', 'encümen', 'muhtar', 'ihtiyar heyeti'],
      ),
      SubtopicInfo(
        id: 'hizmet_yerinden_yonetim',
        name: 'Hizmet Yerinden Yönetim',
        keywords: ['hizmet yerinden yönetim', 'kamu tüzel kişiliği', 'özerklik', 'üniversite', 'trt', 'kamu kurumu', 'kamu kurumları', 'düzenleyici kurul', 'bağımsız idari otorite'],
      ),
      SubtopicInfo(
        id: 'kamu_gorevlileri',
        name: 'Kamu Görevlileri',
        keywords: ['kamu görevlisi', 'memur', 'devlet memuru', 'sözleşmeli personel', '657 sayılı kanun', 'atama', 'disiplin', 'görev', 'yetki', 'sorumluluk'],
      ),
      SubtopicInfo(
        id: 'idari_denetim',
        name: 'İdari Denetim',
        keywords: ['idari denetim', 'hiyerarşik denetim', 'vesayet denetimi', 'yargısal denetim', 'ombudsman', 'kamu denetçiliği', 'sayıştay', 'idari yargı'],
      ),
    ],
    
    // ─────────────────────────────────────────────────────────────────────────
    // 6. GÜNCEL KONULAR
    // ─────────────────────────────────────────────────────────────────────────
    'Bo3qqooJsqtIZrK5zc9S': [
      SubtopicInfo(
        id: 'ulusal_gundem',
        name: 'Ulusal Gündem',
        keywords: ['türkiye', 'iç politika', 'seçim', 'referandum', 'anayasa değişikliği', 'cumhurbaşkanlığı sistemi', 'yerel seçim', 'genel seçim', 'siyasi parti'],
      ),
      SubtopicInfo(
        id: 'uluslararasi_iliskiler',
        name: 'Uluslararası İlişkiler',
        keywords: ['dış politika', 'uluslararası', 'birleşmiş milletler', 'bm', 'nato', 'avrupa birliği', 'ab', 'g20', 'd8', 'türk konseyi', 'ikili ilişkiler', 'diplomasi'],
      ),
      SubtopicInfo(
        id: 'uluslararasi_orgutler',
        name: 'Uluslararası Örgütler',
        keywords: ['uluslararası örgüt', 'bm', 'nato', 'ab', 'unesco', 'who', 'imf', 'dünya bankası', 'islam işbirliği teşkilatı', 'avrupa konseyi', 'agit'],
      ),
      SubtopicInfo(
        id: 'ekonomi_guncel',
        name: 'Ekonomi Gündemi',
        keywords: ['ekonomi', 'enflasyon', 'faiz', 'döviz', 'borsa', 'işsizlik', 'büyüme', 'gsyh', 'merkez bankası', 'para politikası', 'maliye politikası'],
      ),
      SubtopicInfo(
        id: 'cevre_guncel',
        name: 'Çevre ve Sürdürülebilirlik',
        keywords: ['çevre', 'iklim değişikliği', 'küresel ısınma', 'paris anlaşması', 'karbon', 'yenilenebilir enerji', 'sürdürülebilir kalkınma', 'atık', 'geri dönüşüm'],
      ),
      SubtopicInfo(
        id: 'bilim_teknoloji_guncel',
        name: 'Bilim ve Teknoloji',
        keywords: ['teknoloji', 'dijitalleşme', 'yapay zeka', 'uzay', 'türksat', 'göktürk', 'imece', 'savunma sanayi', 'yerli otomobil', 'togg', 'inovasyon'],
      ),
    ],
  };
  
  /// Soru metninden alt konu tespit et
  static SubtopicInfo? detectSubtopic(String topicId, String questionText) {
    final subtopics = topicSubtopics[topicId];
    if (subtopics == null) return null;
    
    final lowerText = questionText.toLowerCase();
    
    // Her alt konu için keyword eşleşmesi kontrol et
    for (final subtopic in subtopics) {
      for (final keyword in subtopic.keywords) {
        if (lowerText.contains(keyword.toLowerCase())) {
          return subtopic;
        }
      }
    }
    
    return null;
  }
  
  /// Bir konunun tüm alt konularını getir
  static List<SubtopicInfo> getSubtopics(String topicId) {
    return topicSubtopics[topicId] ?? [];
  }
}

/// Alt konu bilgisi
class SubtopicInfo {
  final String id;
  final String name;
  final List<String> keywords;
  
  const SubtopicInfo({
    required this.id,
    required this.name,
    required this.keywords,
  });
}
