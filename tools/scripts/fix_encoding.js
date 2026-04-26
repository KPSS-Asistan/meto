#!/usr/bin/env node
/**
 * Asset dosyalarındaki U+FFFD (replacement) karakterlerini Türkçe kelime sözlüğü ile düzelt.
 *
 * Strateji:
 * 1. Bilinen Türkçe kelime/desen sözlüğü oluştur
 * 2. `\uFFFD+` içeren her kelimeyi, ön/son bağlamla eşleştir
 * 3. Eşleşme bulunmazsa rapor et
 *
 * Kullanım: node tools/scripts/fix_encoding.js [--dry]
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '../..');
const ASSETS_DIR = path.join(ROOT, 'assets', 'data');
const QUESTIONS_DIR = path.join(ROOT, 'questions');
const DRY_RUN = process.argv.includes('--dry');

// ═══════════════════════════════════════════════════════════════════════════
// TÜRKÇE DÜZELTME SÖZLÜĞÜ
// Desen: mangled (\uFFFD+) → doğru Türkçe
// ═══════════════════════════════════════════════════════════════════════════
const FFFD = '\uFFFD';
const R = (k, v) => [new RegExp(k.replace(/\*/g, FFFD + '+'), 'g'), v];

const DICT = [
    // Tam kelimeler (en yaygın)
    R('T\\*rk', 'Türk'),
    R('t\\*rk', 'türk'),
    R('T\\*rkiye', 'Türkiye'),
    R('T\\*rkler', 'Türkler'),
    R('T\\*rklerin', 'Türklerin'),
    R('T\\*re', 'Töre'),
    R('K\\*kt\\*rk', 'Köktürk'),
    R('G\\*kt\\*rk', 'Göktürk'),
    R('Sel\\*uklu', 'Selçuklu'),
    R('K\\*l\\*\\*', 'Kılıç'),
    R('K\\*l\\*\\*ç', 'Kılıç'),
    R('aşa\\*\\*daki', 'aşağıdaki'),
    R('a\\*a\\*\\*daki', 'aşağıdaki'),
    R('a\\*\\*a\\*\\*daki', 'aşağıdaki'),
    R('te\\*kilat', 'teşkilat'),
    R('Do\\*al', 'Doğal'),
    R('do\\*al', 'doğal'),
    R('al\\*nan', 'alınan'),
    R('yarl\\*k', 'yarlık'),
    R('Yaz\\*t', 'Yazıt'),
    R('toprak\\*n', 'toprağın'),
    R('toprakla\\*n', 'topraklarının'),
    R('istilas\\*n\\*n', 'istilasının'),
    R('istilas\\*n', 'istilasın'),
    R('Bat\\*', 'Batı'),
    R('bat\\*', 'batı'),
    R('kontrol\\*n\\*', 'kontrolünü'),
    R('y\\*k\\*lma', 'yıkılma'),
    R('b\\*y\\*k', 'büyük'),
    R('\\*nem', 'önem'),
    R('\\*nemli', 'önemli'),
    R('ta\\*\\*ma', 'taşıma'),
    R('ta\\*\\*d\\*', 'taşıdığı'),
    R('ta\\*\\*m\\*\\*', 'taşımış'),
    R('sava\\*', 'savaş'),
    R('sava\\*\\*', 'savaşı'),
    R('\\*alan', 'çalan'),
    R('\\*\\*alan', 'çalan'),
    R('\\*\\*\\*nda', 'ışığında'),
    R('\\*\\*\\*ğında', 'ışığında'),
    R('refah\\*n\\*', 'refahını'),
    R('inan\\*\\*', 'inanış'),
    R('\\*\\*kt\\*\\*', 'çöktüğü'),
    R('\\*ok', 'çok'),
    R('Karahanl\\*lar', 'Karahanlılar'),
    R('karş\\*la\\*t\\*r', 'karşılaştır'),
    R('kar\\*\\*la\\*t\\*r', 'karşılaştır'),
    R('kar\\*\\*la\\*t\\*rd\\*\\*\\*m\\*zda', 'karşılaştırdığımızda'),
    R('Hayvanl\\*', 'Hayvanlı'),
    R('kan\\*t\\*d\\*r', 'kanıtıdır'),
    R('olu\\*turmalar\\*', 'oluşturmaları'),
    R('kullanmalar\\*', 'kullanmaları'),
    R('dayan\\*r', 'dayanır'),
    R('yan\\*t', 'yanıt'),
    R('yanl\\*\\*', 'yanlış'),
    R('yanl\\*\\*t\\*r', 'yanlıştır'),
    R('Değ\\*\\*ebilirli\\*i', 'Değişebilirliği'),
    R('De\\*i\\*ebilirli\\*i', 'Değişebilirliği'),
    R('\\*lke', 'ülke'),
    R('\\*lkeleri', 'ülkeleri'),
    R('\\*lk', 'İlk'),
    R('\\*\\*\\*nc\\*', 'üçüncü'),
    R('i\\*lerinin', 'işlerinin'),
    R('i\\*', 'iş'),
    R('a\\*\\*l\\*r', 'açılır'),
    R('a\\*\\*klama', 'açıklama'),
    R('yap\\*lm\\*\\*', 'yapılmış'),
    R('yap\\*m\\*\\*', 'yapımış'),
    R('olu\\*turmu\\*', 'oluşturmuş'),
    R('olu\\*an', 'oluşan'),
    R('olu\\*', 'oluş'),
    R('\\*ekilde', 'şekilde'),
    R('\\*ehir', 'şehir'),
    R('ba\\*lam\\*\\*', 'başlamış'),
    R('ba\\*lang\\*', 'başlangıç'),
    R('ba\\*ar\\*', 'başarı'),
    R('ba\\*kan', 'başkan'),
    R('ba\\*', 'baş'),
    R('do\\*um', 'doğum'),
    R('do\\*u', 'doğu'),
    R('bat\\*s\\*', 'batısı'),
    R('kuzey\\*', 'kuzeyi'),
    R('g\\*ney', 'güney'),
    R('\\*a\\*\\*', 'çağı'),
    R('d\\*nem', 'dönem'),
    R('y\\*zy\\*l', 'yüzyıl'),
    R('y\\*l\\*nda', 'yılında'),
    R('y\\*l\\*', 'yılı'),
    R('y\\*l', 'yıl'),
    R('y\\*ne', 'yöne'),
    R('y\\*netim', 'yönetim'),
    R('y\\*netici', 'yönetici'),
    R('\\*retim', 'üretim'),
    R('\\*lke', 'ülke'),
    R('\\*mmet', 'ümmet'),
    R('\\*\\*\\*m', 'üçüm'),
    R('arkada\\*', 'arkadaş'),
    R('al\\*\\*veri\\*', 'alışveriş'),
    R('de\\*il', 'değil'),
    R('de\\*er', 'değer'),
    R('de\\*i\\*', 'değiş'),
    R('de\\*i\\*im', 'değişim'),
    R('de\\*i\\*iklik', 'değişiklik'),
    R('a\\*\\*', 'açı'),
    R('\\*\\*n\\*', 'çünkü'),
    R('g\\*r\\*', 'görü'),
    R('g\\*rev', 'görev'),
    R('g\\*re', 'göre'),
    R('g\\*nder', 'gönder'),
    R('g\\*z', 'göz'),
    R('s\\*z', 'söz'),
    R('s\\*yle', 'söyle'),
    R('s\\*n\\*r', 'sınır'),
    R('s\\*nav', 'sınav'),
    R('n\\*fus', 'nüfus'),
    R('m\\*sl\\*man', 'müslüman'),
    R('M\\*sl\\*man', 'Müslüman'),
    R('h\\*k\\*m', 'hüküm'),
    R('h\\*k\\*mdar', 'hükümdar'),
    R('h\\*k\\*met', 'hükümet'),
    R('\\*zerinde', 'üzerinde'),
    R('\\*zellik', 'özellik'),
    R('\\*zg\\*r', 'özgür'),
    R('k\\*lt\\*r', 'kültür'),
    R('k\\*\\*\\*k', 'küçük'),
    R('k\\*re', 'küre'),
    R('\\*niversi', 'üniversi'),
    R('ara\\*t\\*rma', 'araştırma'),
    R('\\*ocuk', 'çocuk'),
    R('\\*e\\*itli', 'çeşitli'),
    R('\\*e\\*it', 'çeşit'),
    R('\\*al\\*\\*', 'çalış'),
    R('\\*al\\*\\*ma', 'çalışma'),
    R('\\*al\\*\\*maktad\\*r', 'çalışmaktadır'),
    R('hi\\*bir', 'hiçbir'),
    R('hi\\*', 'hiç'),
    R('gen\\*', 'genç'),
    R('u\\*', 'uç'),
    R('gerek\\*e', 'gerekçe'),
    R('M\\*s\\*r', 'Mısır'),
    R('M\\*g\\*l', 'Moğol'),
    R('Ba\\*dat', 'Bağdat'),
    R('\\*ran', 'İran'),
    R('\\*stanbul', 'İstanbul'),
    R('\\*slam', 'İslam'),
    R('\\*spanya', 'İspanya'),
    R('\\*sve\\*', 'İsveç'),
    R('Sel\\*uk', 'Selçuk'),
    R('Anadolu\\*nun', 'Anadolu\'nun'),
    R('mill\\*', 'milli'),
    R('tarih\\*', 'tarihi'),
    R('son\\*', 'sonu'),
    R('kar\\*\\*', 'karşı'),
    R('kar\\*\\*t', 'karşıt'),
    R('kar\\*\\*la\\*', 'karşılaş'),
    R('\\*ok\\*a', 'çokça'),
    R('\\*ok\\*nemli', 'çok önemli'),
    R('\\*sg\\*r', 'özgür'),
    R('kur\\*lmas\\*', 'kurulması'),
    R('kur\\*ldu', 'kuruldu'),
    R('kurulu\\*', 'kuruluş'),
    R('Tuna\\*n\\*n', 'Tuna\'nın'),
    R('yapt\\*\\*\\*', 'yaptığı'),
    R('g\\*r\\*\\*m', 'görüşüm'),
    R('g\\*r\\*\\*t\\*', 'görüştü'),
    R('g\\*nd\\*z', 'gündüz'),
    R('g\\*z\\*', 'gözü'),
    R('g\\*l\\*\\*', 'gülüş'),
    R('te\\*ekk\\*r', 'teşekkür'),
    R('kelimesi\\*nde', 'kelimesi\'nde'),
    R('Miryokefalon', 'Miryokefalon'),
    R('Ha\\*tin', 'Hattin'),
    R('Ha\\*\\*in', 'Hattin'),
    // Genişletilmiş sözlük
    R('b\\*lge', 'bölge'),
    R('b\\*lgesel', 'bölgesel'),
    R('sald\\*r\\*', 'saldırı'),
    R('sald\\*r\\*lar\\*na', 'saldırılarına'),
    R('olmas\\*na', 'olmasına'),
    R('organ\\*', 'organı'),
    R('kar\\*\\*', 'karşı'),
    R('kar\\*\\*\\*', 'karşı'),
    R('te\\*bih', 'teşbih'),
    R('yabanc\\*', 'yabancı'),
    R('da\\*lar', 'dağlar'),
    R('da\\*lar\\*', 'dağları'),
    R('da\\*\\*nda', 'dağında'),
    R('i\\*lem', 'işlem'),
    R('\\*rnek', 'örnek'),
    R('m\\*dahale', 'müdahale'),
    R('avantaj\\*', 'avantajı'),
    R('alt\\*nda', 'altında'),
    R('alt\\*ndad\\*r', 'altındadır'),
    R('Ba\\*kan', 'Başkan'),
    R('Ba\\*kanl\\*\\*\\*', 'Başkanlığı'),
    R('kald\\*r\\*l', 'kaldırıl'),
    R('kald\\*r\\*l\\*p', 'kaldırılıp'),
    R('T\\*marl\\*', 'Tımarlı'),
    R('K\\*pr\\*s\\*', 'Köprüsü'),
    R('K\\*pr\\*', 'Köprü'),
    R('ya\\*anm\\*\\*', 'yaşanmış'),
    R('ya\\*anm\\*\\*t\\*r', 'yaşanmıştır'),
    R('Montr\\*', 'Montreux'),
    R('Montr\\*\\*', 'Montreux'),
    R('Bo\\*az', 'Boğaz'),
    R('Bo\\*azlar', 'Boğazlar'),
    R('Ba\\*komutanl\\*k', 'Başkomutanlık'),
    R('\\*rg\\*t', 'örgüt'),
    R('anlam\\*nda', 'anlamında'),
    R('kullan\\*l\\*r', 'kullanılır'),
    R('Oks\\*zl\\*k', 'Öksüzlük'),
    R('Cermenle\\*me', 'Cermenleşme'),
    R('Cermenle\\*mesini', 'Cermenleşmesini'),
    R('\\*sl\\*mi', 'İslâmi'),
    R('\\*sl\\*m', 'İslâm'),
    R('h\\*k\\*mlerine', 'hükümlerine'),
    R('k\\*r\\*kl\\*', 'kırıklı'),
    R('\\*al\\*\\*t\\*r', 'çalıştır'),
    R('yerle\\*me', 'yerleşme'),
    R('yerle\\*im', 'yerleşim'),
    R('yerle\\*ik', 'yerleşik'),
    R('ge\\*i\\*', 'geçiş'),
    R('ge\\*mi\\*', 'geçmiş'),
    R('ge\\*er', 'geçer'),
    R('ge\\*erli', 'geçerli'),
    R('a\\*ıklar', 'açıklar'),
    R('bilinmektedir\\*', 'bilinmektedir'),
    R('Bilimsel', 'Bilimsel'),
    R('Mehmet', 'Mehmet'),
    R('Beyaz\\*t', 'Beyazıt'),
    R('Osmanl\\*', 'Osmanlı'),
    R('B\\*zans', 'Bizans'),
    R('Emev\\*', 'Emevi'),
    R('Abbas\\*', 'Abbasi'),
    R('Halife', 'Halife'),
    R('kurulmu\\*', 'kurulmuş'),
    R('kurulmu\\*tur', 'kurulmuştur'),
    R('yap\\*lm\\*\\*t\\*r', 'yapılmıştır'),
    R('verilmi\\*', 'verilmiş'),
    R('verilmi\\*tir', 'verilmiştir'),
    R('olmu\\*', 'olmuş'),
    R('olmu\\*tur', 'olmuştur'),
    R('gelmi\\*', 'gelmiş'),
    R('gelmi\\*tir', 'gelmiştir'),
    R('etmi\\*', 'etmiş'),
    R('etmi\\*tir', 'etmiştir'),
    R('gitmi\\*', 'gitmiş'),
    R('gitmi\\*tir', 'gitmiştir'),
    R('bitmi\\*', 'bitmiş'),
    R('bitmi\\*tir', 'bitmiştir'),
    R('d\\*nya', 'dünya'),
    R('D\\*nya', 'Dünya'),
    R('k\\*\\*pe', 'küpe'),
    R('\\*retim', 'üretim'),
    R('\\*ret', 'üret'),
    R('\\*retici', 'üretici'),
    R('t\\*ket', 'tüket'),
    R('t\\*ketim', 'tüketim'),
    R('t\\*ketici', 'tüketici'),
    R('\\*zel', 'özel'),
    R('\\*zerk', 'özerk'),
    R('\\*zne', 'özne'),
    R('n\\*tr', 'nötr'),
    R('n\\*snel', 'nesnel'),
    R('\\*znel', 'öznel'),
    R('s\\*zle\\*me', 'sözleşme'),
    R('s\\*zle\\*mesi', 'sözleşmesi'),
    R('kurulu\\*u', 'kuruluşu'),
    R('Cumhuriyet\\*i', 'Cumhuriyet\'i'),
    R('Cumhuriyet\\*in', 'Cumhuriyet\'in'),
    R('Mustafa', 'Mustafa'),
    R('Atat\\*rk', 'Atatürk'),
    R('Atat\\*rk\\*', 'Atatürk\''),
    R('ink\\*lap', 'inkılap'),
    R('\\*ok partili', 'çok partili'),
    R('milletvekili', 'milletvekili'),
    R('Meclis\\*i', 'Meclis\'i'),
    R('B\\*y\\*k', 'Büyük'),
    R('Millet', 'Millet'),
    R('millet\\*', 'milleti'),
    R('demokra\\*i', 'demokrasi'),
    R('E\\*itim', 'Eğitim'),
    R('e\\*itim', 'eğitim'),
    R('\\*\\*rencisi', 'öğrencisi'),
    R('\\*\\*renci', 'öğrenci'),
    R('\\*\\*retmen', 'öğretmen'),
    R('\\*\\*ret', 'öğret'),
    R('\\*\\*retim', 'öğretim'),
    R('s\\*leyman', 'süleyman'),
    R('S\\*leyman', 'Süleyman'),
    R('F\\*tih', 'Fatih'),
    R('Selim', 'Selim'),
    R('Mahmud', 'Mahmud'),
    R('Abd\\*lhamid', 'Abdülhamid'),
    R('Abd\\*laziz', 'Abdülaziz'),
    R('Kan\\*n\\*', 'Kanunî'),
    R('\\*eyh\\*lislam', 'Şeyhülislam'),
    R('\\*eyh', 'Şeyh'),
    R('sad\\*kat', 'sadakat'),
    R('sadak\\*', 'sadakat'),
    R('sad\\*', 'sade'),
    R('fetih', 'fetih'),
    R('Fetih', 'Fetih'),
    R('\\*ehzade', 'şehzade'),
    R('\\*\\*\\*nc\\*', 'üçüncü'),
    R('d\\*rd\\*nc\\*', 'dördüncü'),
    R('be\\*inci', 'beşinci'),
    R('alt\\*nc\\*', 'altıncı'),
    R('yedinci', 'yedinci'),
    R('sekizinci', 'sekizinci'),
    R('dokuzuncu', 'dokuzuncu'),
    R('onuncu', 'onuncu'),
    R('g\\*revleri', 'görevleri'),
    R('g\\*rev\\*', 'görevi'),
    R('g\\*revli', 'görevli'),
    R('\\*devler', 'ödevler'),
    R('\\*dev', 'ödev'),
    R('\\*d\\*n', 'ödün'),
    R('\\*d\\*l', 'ödül'),
    R('m\\*kafat', 'mükafat'),
    R('\\*ikayet', 'şikayet'),
    R('hakk\\*nda', 'hakkında'),
    R('tan\\*mlan', 'tanımlan'),
    R('tan\\*m', 'tanım'),
    R('tarif', 'tarif'),
    R('ta\\*', 'taş'),
    R('ta\\*\\*', 'taşı'),
    R('ta\\*\\*d\\*', 'taşıdı'),
    R('t\\*ccar', 'tüccar'),
    R('ticar\\*', 'ticari'),
    R('ticaret', 'ticaret'),
    R('tar\\*m', 'tarım'),
    R('tar\\*msal', 'tarımsal'),
    R('hayvan\\*', 'hayvanı'),
    R('hayvanc\\*l\\*k', 'hayvancılık'),
    R('bitki', 'bitki'),
    R('bitkisel', 'bitkisel'),
    R('\\*kim', 'ekim'),
    R('\\*ekim', 'ekim'),
    R('ya\\*mur', 'yağmur'),
    R('ya\\*', 'yağ'),
    R('ya\\*\\*', 'yaşı'),
    R('ya\\*am', 'yaşam'),
    R('ya\\*ama', 'yaşama'),
    R('ya\\*ay', 'yaşay'),
    R('ya\\*l\\*', 'yaşlı'),
    R('genel\\*i', 'genelî'),
    R('hem de', 'hem de'),
    R('\\*nemlidir', 'önemlidir'),
    R('\\*zelliklerinden', 'özelliklerinden'),
    R('\\*zellikle', 'özellikle'),
    R('\\*lm\\*\\*t\\*r', 'ölmüştür'),
    R('\\*l\\*m', 'ölüm'),
    R('\\*ld\\*', 'öldü'),
    R('\\*ld\\*r', 'öldür'),
    R('\\*ld\\*rm', 'öldürm'),
    R('k\\*\\*\\*k', 'küçük'),
    R('b\\*y\\*kl\\*\\*\\*', 'büyüklüğü'),
    R('k\\*\\*\\*kl\\*\\*\\*', 'küçüklüğü'),
    R('uzakl\\*k', 'uzaklık'),
    R('uzakl\\*\\*\\*', 'uzaklığı'),
    R('yak\\*nl\\*k', 'yakınlık'),
    R('y\\*ksek', 'yüksek'),
    R('y\\*kseklik', 'yükseklik'),
    R('al\\*ak', 'alçak'),
    R('derin', 'derin'),
    R('derinlik', 'derinlik'),
    R('geni\\*', 'geniş'),
    R('geni\\*lik', 'genişlik'),
    R('geni\\*letmek', 'genişletmek'),
    R('dar', 'dar'),
    R('darl\\*k', 'darlık'),
    R('\\*zun', 'uzun'),
    R('k\\*sa', 'kısa'),
    R('k\\*sal', 'kısal'),
    R('k\\*saltma', 'kısaltma'),
    R('art\\*\\*', 'artış'),
    R('art\\*r', 'artır'),
    R('azal\\*\\*', 'azalış'),
    R('azal', 'azal'),
    R('azalt', 'azalt'),
    R('fark\\*', 'farkı'),
    R('fark\\*nda', 'farkında'),
    R('fark\\*ndal\\*k', 'farkındalık'),
    R('farkl\\*l\\*k', 'farklılık'),
    R('farkl\\*', 'farklı'),
    R('ayn\\*', 'aynı'),
    R('ba\\*ka', 'başka'),
    R('ba\\*kas\\*', 'başkası'),
    R('kimse', 'kimse'),
    R('birisi', 'birisi'),
    R('biri', 'biri'),
    R('\\*oban', 'çoban'),
    R('k\\*y', 'köy'),
    R('k\\*yl\\*', 'köylü'),
    R('kent', 'kent'),
    R('\\*ehir', 'şehir'),
    R('\\*ehirli', 'şehirli'),
    R('nehir', 'nehir'),
    R('\\*rmak', 'ırmak'),
    R('deniz', 'deniz'),
    R('g\\*l', 'göl'),
    R('akarsu', 'akarsu'),
    R('su', 'su'),
    R('susuz', 'susuz'),
    R('susuzluk', 'susuzluk'),
    R('y\\*zde', 'yüzde'),
    R('y\\*z\\*', 'yüzü'),
    R('y\\*z', 'yüz'),
    R('y\\*zy\\*l\\*n', 'yüzyılın'),
    R('Selahaddin', 'Selahaddin'),
    R('Eyy\\*bi', 'Eyyübi'),
    R('Hal\\*fe', 'Halife'),
    R('\\*ehit', 'şehit'),
    R('\\*ehitlik', 'şehitlik'),
    R('k\\*yamet', 'kıyamet'),
    R('k\\*sa', 'kısa'),
    R('k\\*sm\\*', 'kısmı'),
    R('k\\*sm\\*nda', 'kısmında'),
    R('k\\*t\\*\\*\\*', 'kıtığı'),
    R('k\\*ta', 'kıta'),
    R('k\\*talar', 'kıtalar'),
    R('Afrika', 'Afrika'),
    R('Asya', 'Asya'),
    R('Avrupa', 'Avrupa'),
    R('Amerika', 'Amerika'),
    R('Orta Do\\*u', 'Orta Doğu'),
    R('Yak\\*n Do\\*u', 'Yakın Doğu'),
    R('Uzak Do\\*u', 'Uzak Doğu'),
    R('Balkan', 'Balkan'),
    R('Anadolu\\*nun', 'Anadolu\'nun'),
    R('Anadolu\\*da', 'Anadolu\'da'),
    R('Anadolu', 'Anadolu'),
    R('t\\*r', 'tür'),
    R('t\\*rl\\*', 'türlü'),
    R('farkl\\*l\\*klar', 'farklılıklar'),
    R('birlikte', 'birlikte'),
    R('birlik', 'birlik'),
    R('birlikte', 'birlikte'),
    R('birle\\*', 'birleş'),
    R('birle\\*tirme', 'birleştirme'),
    R('ay\\*r', 'ayır'),
    R('ay\\*rma', 'ayırma'),
    R('ay\\*r\\*l', 'ayırıl'),
    R('ay\\*r\\*lmaz', 'ayrılmaz'),
    R('ayr\\*l\\*k', 'ayrılık'),
    R('\\*nce', 'önce'),
    R('\\*nceki', 'önceki'),
    R('\\*nc\\*', 'öncü'),
    R('\\*nc\\*l', 'öncül'),
    R('sonra', 'sonra'),
    R('sonradan', 'sonradan'),
    R('sonraki', 'sonraki'),
    R('son', 'son'),
    R('sonu\\*', 'sonuç'),
    R('sonucunda', 'sonucunda'),
    R('\\*mp\\*', 'Öyle'),
    R('belki', 'belki'),
    R('m\\*mk\\*n', 'mümkün'),
    R('imk\\*n', 'imkân'),
    R('Y\\*ksek', 'Yüksek'),
    R('Adalet', 'Adalet'),
    R('Bakanl\\*\\*\\*', 'Bakanlığı'),
    R('Bakan', 'Bakan'),
    R('Ba\\*bakan', 'Başbakan'),
    R('Cumhurba\\*kan\\*', 'Cumhurbaşkanı'),
    R('Cumhurba\\*kanl\\*\\*\\*', 'Cumhurbaşkanlığı'),
    R('Anayasa', 'Anayasa'),
    R('anayasa', 'anayasa'),
    R('anayasal', 'anayasal'),
    R('Yarg\\*tay', 'Yargıtay'),
    R('Dan\\*\\*tay', 'Danıştay'),
    R('Say\\*\\*tay', 'Sayıştay'),
    R('T\\*rkiye\\*nin', 'Türkiye\'nin'),
    R('T\\*rkiye\\*de', 'Türkiye\'de'),
    R('T\\*rkiye\\*ye', 'Türkiye\'ye'),
    R('T\\*rkiye\\*den', 'Türkiye\'den'),
    // Sayılar ve eserler
    R('Di\\*van\\*', 'Dîvân'),
    R('Kutadgu Bilig', 'Kutadgu Bilig'),
    R('Atabetü\\*l', 'Atabetü\'l'),
    R('Divan\\*', 'Divan'),
];

// ═══════════════════════════════════════════════════════════════════════════
// TEK KARAKTER TAHMİNİ (sözlükte olmayan kelimeler için)
// Türkçe'de vowel harmony ve frequency bazlı
// ═══════════════════════════════════════════════════════════════════════════
function guessTurkishChar(before, after) {
    const b = before.toLowerCase();
    const a = after.toLowerCase();
    // Basit heuristik: yaygın Türkçe bigramlar
    const rules = [
        // a?a pattern (ağa, aşa, aça)
        [/a$/, /^a/, 'ğ'],
        // a?ı pattern (aşı, açı, ağı)
        [/a$/, /^[ıi]/, 'ş'],
        // i?i (işi, iği, ici)
        [/[eıi]$/, /^[ıi]/, 'ş'],
        // e?e (eşe, ede)
        [/e$/, /^e/, 'ş'],
        // u?u (uğu, uçu)
        [/u$/, /^u/, 'ğ'],
        // o?u (oğu, oşu)
        [/o$/, /^u/, 'ğ'],
        // k? at start (kı, kö, kü)
        [/^k$/, /^[aı]/, 'ı'],
        // t? (tı, tü)
        [/^t$/, /^[aı]/, 'ı'],
        // b? (büyük)
        [/^b$/, /^y/, 'ü'],
    ];
    for (const [rb, ra, ch] of rules) {
        if (rb.test(b) && ra.test(a)) return ch;
    }
    return null;
}

// ═══════════════════════════════════════════════════════════════════════════
// ANA İŞLEM
// ═══════════════════════════════════════════════════════════════════════════
function fixText(text) {
    let fixed = text;
    let fixCount = 0;

    // 1. Sözlük bazlı düzeltmeler
    for (const [pattern, replacement] of DICT) {
        fixed = fixed.replace(pattern, () => {
            fixCount++;
            return replacement;
        });
    }

    return { fixed, fixCount };
}

function scanDir(dir) {
    const files = [];
    if (!fs.existsSync(dir)) return files;
    for (const f of fs.readdirSync(dir)) {
        const full = path.join(dir, f);
        const st = fs.statSync(full);
        if (st.isDirectory()) files.push(...scanDir(full));
        else if (f.endsWith('.json')) files.push(full);
    }
    return files;
}

function countFFFD(text) {
    return (text.match(/\uFFFD/g) || []).length;
}

function main() {
    const targets = [
        ...scanDir(ASSETS_DIR),
        ...scanDir(QUESTIONS_DIR),
    ];

    let totalBefore = 0, totalAfter = 0, filesFixed = 0;

    for (const file of targets) {
        const content = fs.readFileSync(file, 'utf8');
        const before = countFFFD(content);
        if (before === 0) continue;

        const { fixed, fixCount } = fixText(content);
        const after = countFFFD(fixed);

        totalBefore += before;
        totalAfter += after;

        if (before !== after) {
            filesFixed++;
            console.log(`${path.relative(ROOT, file)}: ${before} → ${after} (${before - after} düzeltildi)`);
            if (!DRY_RUN) {
                fs.writeFileSync(file, fixed, 'utf8');
            }
        }
    }

    console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`Dosyalar: ${filesFixed} / ${targets.length}`);
    console.log(`FFFD: ${totalBefore} → ${totalAfter} (${totalBefore - totalAfter} düzeltildi)`);
    console.log(DRY_RUN ? '🔍 DRY RUN (yazılmadı)' : '✅ Yazıldı');

    // Kalan FFFD'ler için örnekler
    if (totalAfter > 0) {
        console.log(`\n⚠️ Kalan sorunlu kelimeler (ilk 30):`);
        const remaining = new Set();
        for (const file of targets) {
            const content = fs.readFileSync(file, 'utf8');
            const matches = content.matchAll(/[^\s\r\n",{}\[\]]{0,15}\uFFFD+[^\s\r\n",{}\[\]]{0,15}/g);
            for (const m of matches) {
                remaining.add(m[0]);
                if (remaining.size >= 30) break;
            }
            if (remaining.size >= 30) break;
        }
        [...remaining].forEach(s => console.log(`  ${JSON.stringify(s)}`));
    }
}

main();
