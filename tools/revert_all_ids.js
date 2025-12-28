const fs = require('fs');
const path = require('path');

// Yeni ID'den eski ID'ye mapping
const idMap = {
    'tarih_01_islam_oncesi': 'JnFbEQt0uA8RSEuy22SQ',
    'tarih_02_ilk_musluman_turk': '9Hg8tuMRdMTuVY7OZ9HL',
    'tarih_03_selcuklu': '8aIrKLvItXrwvOHq1L34',
    'tarih_04_osmanli_siyasi': 'JU0iGKNhR7NQzA8M77vt',
    'tarih_05_osmanli_kultur': '9WTotPoDW5OuWxsCf4Li',
    'tarih_06_kurtulus_savasi': 'DlT19snCttf5j5RUAXLz',
    'tarih_07_ataturk_inkilap': '4GUvpqBBImcLmN2eh1HK',
    'tarih_08_cumhuriyet_donemi': 'onwrfsH02TgIhlyRUh56',
    'tarih_09_cagdas_turk_dunya': 'xQWHl1hBYAKM96X4deR8',
    'turkce_01_ses_bilgisi': '80e0wkTLvaTQzPD6puB7',
    'turkce_02_yapi_bilgisi': 'yWlh5C6jB7lzuJOodr2t',
    'turkce_03_sozcuk_turleri': 'ICNDiSlTmmjWEQPT6rmT',
    'turkce_04_sozcukte_anlam': 'JmyiPxf3n96Jkxqsa9jY',
    'turkce_05_cumlede_anlam': 'AJNLHhhaG2SLWOvxDYqW',
    'turkce_06_paragrafta_anlam': 'nN8JOTR7LZm01AN2i3sQ',
    'turkce_07_anlatim_bozuklugu': 'jXcsrl5HEb65DmfpfqqI',
    'turkce_08_yazim_noktalama': 'qSEqigIsIEBAkhcMTyCE',
    'turkce_09_sozel_mantik': 'wnt2zWaV1pX8p8s8BBc9',
    'cografya_01_konum': '1FEcPsGduhjcQARpaGBk',
    'cografya_02_fiziki': 'kbs0Ffved9pCP3Hq9M9k',
    'cografya_03_iklim': '6e0Thsz2RRNHFcwqQXso',
    'cografya_04_beseri': 'uYDrMlBCEAho5776WZi8',
    'cografya_05_ekonomik': 'WxrtQ26p2My4uJa0h1kk',
    'cografya_06_bolgeler': 'GdpN8uxJNGtexWrkoL1T',
    'vatandaslik_01_hukuka_giris': 'AQ0Zph76dzPdr87H1uKa',
    'vatandaslik_02_anayasa': 'n4OjWupHmouuybQzQ1Fc',
    'vatandaslik_03_temel_ilkeler': 'xXGXiqx2TkCtI4C7GMQg',
    'vatandaslik_04_organlar': '1JZAYECyEn7farNNyGyx',
    'vatandaslik_05_idari_yapi': 'lv93cmhwq7RmOFM5WxWD',
    'vatandaslik_06_haklar': 'Bo3qqooJsqtIZrK5zc9S'
};

// lesson_id mapping (topic grupların ders isimleri)
const lessonIdMap = {
    'tarih': 'caZ5LwfH3QJrBVUQCros',
    'turkce': 'L3i1Rqv2LN3AKFFejuUg',
    'cografya': 'A779wvZWQcbvanmbS8Qz',
    'vatandaslik': '2ztkqV35cWjGRkhYRutg'
};

console.log('🔄 Tüm ID\'ler eski haline getiriliyor...\n');

// 1. version.json güncelle
console.log('📄 version.json güncelleniyor...');
const versionPath = path.join(__dirname, '../github_data/version.json');
let versionContent = fs.readFileSync(versionPath, 'utf8');
for (const [newId, oldId] of Object.entries(idMap)) {
    versionContent = versionContent.replace(new RegExp(`"${newId}"`, 'g'), `"${oldId}"`);
}
fs.writeFileSync(versionPath, versionContent, 'utf8');
console.log('✅ version.json güncellendi');

// 2. topics_data.dart güncelle
console.log('\n📄 topics_data.dart güncelleniyor...');
const topicsDataPath = path.join(__dirname, '../lib/core/data/topics_data.dart');
let topicsDataContent = fs.readFileSync(topicsDataPath, 'utf8');
for (const [newId, oldId] of Object.entries(idMap)) {
    topicsDataContent = topicsDataContent.replace(new RegExp(`'${newId}'`, 'g'), `'${oldId}'`);
}
// lesson_id'leri de düzelt
for (const [newId, oldId] of Object.entries(lessonIdMap)) {
    topicsDataContent = topicsDataContent.replace(new RegExp(`lessonId: '${newId}'`, 'g'), `lessonId: '${oldId}'`);
}
fs.writeFileSync(topicsDataPath, topicsDataContent, 'utf8');
console.log('✅ topics_data.dart güncellendi');

// 3. lessons_data.dart güncelle
console.log('\n📄 lessons_data.dart güncelleniyor...');
const lessonsDataPath = path.join(__dirname, '../lib/core/data/lessons_data.dart');
let lessonsDataContent = fs.readFileSync(lessonsDataPath, 'utf8');
for (const [newId, oldId] of Object.entries(lessonIdMap)) {
    lessonsDataContent = lessonsDataContent.replace(new RegExp(`'${newId}'`, 'g'), `'${oldId}'`);
}
fs.writeFileSync(lessonsDataPath, lessonsDataContent, 'utf8');
console.log('✅ lessons_data.dart güncellendi');

// 4. Flashcards klasöründeki dosya isimlerini de değiştir
console.log('\n📂 Flashcard dosya isimleri güncelleniyor...');
const flashcardDirs = [
    path.join(__dirname, '../github_data/flashcards')
];

for (const dir of flashcardDirs) {
    if (!fs.existsSync(dir)) continue;

    for (const [newId, oldId] of Object.entries(idMap)) {
        const newPath = path.join(dir, `${newId}.json`);
        const oldPath = path.join(dir, `${oldId}.json`);

        if (fs.existsSync(newPath) && !fs.existsSync(oldPath)) {
            fs.renameSync(newPath, oldPath);
            console.log(`  ✅ ${newId}.json → ${oldId}.json`);
        }
    }
}

console.log('\n✨ Tüm ID\'ler eski haline getirildi!');
console.log('📌 Şimdi GitHub\'a push edebilirsiniz.');
