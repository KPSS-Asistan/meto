const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(filePath, 'utf8');

const correctTopics = `const TOPICS = {
    // MATEMATİK (9 konu)
    'mat_temel_001': { name: 'Temel Kavramlar ve Sayılar', lesson: 'MATEMATİK', prefix: 'mat', order: 0 },
    'mat_rasyonel_001': { name: 'Rasyonel ve Ondalıklı Sayılar', lesson: 'MATEMATİK', prefix: 'mat', order: 1 },
    'mat_esitsizlik_001': { name: 'Basit Eşitsizlikler ve Mutlak Değer', lesson: 'MATEMATİK', prefix: 'mat', order: 2 },
    'mat_uslu_001': { name: 'Üslü ve Köklü Sayılar', lesson: 'MATEMATİK', prefix: 'mat', order: 3 },
    'mat_carpan_001': { name: 'Çarpanlara Ayırma', lesson: 'MATEMATİK', prefix: 'mat', order: 4 },
    'mat_prob_001': { name: 'Problemler', lesson: 'MATEMATİK', prefix: 'mat', order: 5 },
    'mat_kume_001': { name: 'Kümeler ve Fonksiyonlar', lesson: 'MATEMATİK', prefix: 'mat', order: 6 },
    'mat_olasilik_001': { name: 'PKOB', lesson: 'MATEMATİK', prefix: 'mat', order: 7 },
    'mat_mantik_001': { name: 'Sayısal Mantık', lesson: 'MATEMATİK', prefix: 'mat', order: 8 },
    // TARİH (9 konu)
    'JnFbEQt0uA8RSEuy22SQ': { name: 'İslamiyet Öncesi Türk Tarihi', lesson: 'TARİH', prefix: 'tarih', order: 0 },
    '9Hg8tuMRdMTuVY7OZ9HL': { name: 'İlk Müslüman Türk Devletleri', lesson: 'TARİH', prefix: 'tarih', order: 1 },
    '8aIrKLvItXrwvOHq1L34': { name: 'Türkiye Selçuklu Devleti', lesson: 'TARİH', prefix: 'tarih', order: 2 },
    'JU0iGKNhR7NQzA8M77vt': { name: 'Osmanlı Devleti Tarihi (Siyasi)', lesson: 'TARİH', prefix: 'tarih', order: 3 },
    '9WTotPoDW5OuWxsCf4Li': { name: 'Osmanlı Devleti Tarihi (Kültür)', lesson: 'TARİH', prefix: 'tarih', order: 4 },
    'DlT19snCttf5j5RUAXLz': { name: 'Kurtuluş Savaşı Dönemi', lesson: 'TARİH', prefix: 'tarih', order: 5 },
    '4GUvpqBBImcLmN2eh1HK': { name: 'Atatürk İlke ve İnkılapları', lesson: 'TARİH', prefix: 'tarih', order: 6 },
    'onwrfsH02TgIhlyRUh56': { name: 'Cumhuriyet Dönemi', lesson: 'TARİH', prefix: 'tarih', order: 7 },
    'xQWHl1hBYAKM96X4deR8': { name: 'Çağdaş Türk ve Dünya Tarihi', lesson: 'TARİH', prefix: 'tarih', order: 8 },
    // TÜRKÇE (9 konu)
    '80e0wkTLvaTQzPD6puB7': { name: 'Ses Bilgisi', lesson: 'TÜRKÇE', prefix: 'turkce', order: 0 },
    'yWlh5C6jB7lzuJOodr2t': { name: 'Yapı Bilgisi', lesson: 'TÜRKÇE', prefix: 'turkce', order: 1 },
    'ICNDiSlTmmjWEQPT6rmT': { name: 'Sözcük Türleri', lesson: 'TÜRKÇE', prefix: 'turkce', order: 2 },
    'JmyiPxf3n96Jkxqsa9jY': { name: 'Sözcükte Anlam', lesson: 'TÜRKÇE', prefix: 'turkce', order: 3 },
    'AJNLHhhaG2SLWOvxDYqW': { name: 'Cümlede Anlam', lesson: 'TÜRKÇE', prefix: 'turkce', order: 4 },
    'nN8JOTR7LZm01AN2i3sQ': { name: 'Paragrafta Anlam', lesson: 'TÜRKÇE', prefix: 'turkce', order: 5 },
    'jXcsrl5HEb65DmfpfqqI': { name: 'Anlatım Bozuklukları', lesson: 'TÜRKÇE', prefix: 'turkce', order: 6 },
    'qSEqigIsIEBAkhcMTyCE': { name: 'Yazım Kuralları', lesson: 'TÜRKÇE', prefix: 'turkce', order: 7 },
    'wnt2zWaV1pX8p8s8BBc9': { name: 'Sözel Mantık', lesson: 'TÜRKÇE', prefix: 'turkce', order: 8 },
    // COĞRAFYA (6 konu)
    '1FEcPsGduhjcQARpaGBk': { name: "Türkiye'nin Coğrafi Konumu", lesson: 'COĞRAFYA', prefix: 'cog', order: 0 },
    'kbs0Ffved9pCP3Hq9M9k': { name: "Türkiye'nin Fiziki Özellikleri", lesson: 'COĞRAFYA', prefix: 'cog', order: 1 },
    '6e0Thsz2RRNHFcwqQXso': { name: "Türkiye'nin İklimi", lesson: 'COĞRAFYA', prefix: 'cog', order: 2 },
    'uYDrMlBCEAho5776WZi8': { name: 'Beşeri Coğrafya', lesson: 'COĞRAFYA', prefix: 'cog', order: 3 },
    'WxrtQ26p2My4uJa0h1kk': { name: 'Ekonomik Coğrafya', lesson: 'COĞRAFYA', prefix: 'cog', order: 4 },
    'GdpN8uxJNGtexWrkoL1T': { name: "Türkiye'nin Coğrafi Bölgeleri", lesson: 'COĞRAFYA', prefix: 'cog', order: 5 },
    // VATANDAŞLIK (6 konu)
    'AQ0Zph76dzPdr87H1uKa': { name: 'Hukuka Giriş', lesson: 'VATANDAŞLIK', prefix: 'vat', order: 0 },
    'n4OjWupHmouuybQzQ1Fc': { name: 'Anayasa Hukuku', lesson: 'VATANDAŞLIK', prefix: 'vat', order: 1 },
    'xXGXiqx2TkCtI4C7GMQg': { name: '1982 Anayasası', lesson: 'VATANDAŞLIK', prefix: 'vat', order: 2 },
    '1JZAYECyEn7farNNyGyx': { name: 'Devlet Organları', lesson: 'VATANDAŞLIK', prefix: 'vat', order: 3 },
    'lv93cmhwq7RmOFM5WxWD': { name: 'İdari Yapı', lesson: 'VATANDAŞLIK', prefix: 'vat', order: 4 },
    'Bo3qqooJsqtIZrK5zc9S': { name: 'Temel Hak ve Özgürlükler', lesson: 'VATANDAŞLIK', prefix: 'vat', order: 5 },
    // GÜNCEL BİLGİLER (6 konu)
    'GUNCEL_BM_KURULUS': { name: 'BM ve Bağlı Kuruluşlar', lesson: 'GÜNCEL BİLGİLER', prefix: 'guncel', order: 0 },
    'GUNCEL_NATO_AB': { name: 'NATO ve Avrupa Birliği', lesson: 'GÜNCEL BİLGİLER', prefix: 'guncel', order: 1 },
    'GUNCEL_BOLGESEL_KURULUS': { name: 'Bölgesel Kuruluşlar', lesson: 'GÜNCEL BİLGİLER', prefix: 'guncel', order: 2 },
    'GUNCEL_TURKIYE_KURULUS': { name: "Türkiye'nin Üyelikleri", lesson: 'GÜNCEL BİLGİLER', prefix: 'guncel', order: 3 },
    'GUNCEL_ONEMLI_TARIHLER': { name: 'Önemli Tarihler', lesson: 'GÜNCEL BİLGİLER', prefix: 'guncel', order: 4 },
    'GUNCEL_OLAYLAR': { name: 'Güncel Olaylar', lesson: 'GÜNCEL BİLGİLER', prefix: 'guncel', order: 5 }
};

const correctTargets = `const LESSON_TARGETS = {
    'TARİH': { target: 300, weight: 0.20 },
    'COĞRAFYA': { target: 150, weight: 0.10 },
    'VATANDAŞLIK': { target: 150, weight: 0.10 },
    'TÜRKÇE': { target: 300, weight: 0.20 },
    'MATEMATİK': { target: 300, weight: 0.20 },
    'GÜNCEL BİLGİLER': { target: 100, weight: 0.10 }
}; `;

const startTopics = content.indexOf('const TOPICS = {');
let endTopics = content.indexOf('};', startTopics);

// Ensure we found the closing brace for TOPICS (it might have nested braces, but here structure is simple)
// Actually TOPICS block ends at line 119.
if (startTopics !== -1 && endTopics !== -1) {
    // TOPICS is large, so search for next };
     endTopics = content.indexOf('};', startTopics) + 2;
     content = content.substring(0, startTopics) + correctTopics + content.substring(endTopics);
}

const startTargets = content.indexOf('const LESSON_TARGETS = {');
let endTargets = content.indexOf('};', startTargets);

if (startTargets !== -1 && endTargets !== -1) {
    endTargets = content.indexOf('};', startTargets) + 2;
    content = content.substring(0, startTargets) + correctTargets + content.substring(endTargets);
}

fs.writeFileSync(filePath, content, 'utf8');
console.log('Encoding fixed!');
