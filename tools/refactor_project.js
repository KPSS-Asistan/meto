const fs = require('fs').promises;
const path = require('path');

// ═══════════════════════════════════════════════════════════
// KONU ID HARİTASI (Mapping)
// ═══════════════════════════════════════════════════════════
const idMap = {
    // TARİH
    'JnFbEQt0uA8RSEuy22SQ': 'tarih_01_islam_oncesi',
    '9Hg8tuMRdMTuVY7OZ9HL': 'tarih_02_ilk_musluman_turk',
    '8aIrKLvItXrwvOHq1L34': 'tarih_03_selcuklu',
    'JU0iGKNhR7NQzA8M77vt': 'tarih_04_osmanli_siyasi',
    '9WTotPoDW5OuWxsCf4Li': 'tarih_05_osmanli_kultur',
    'DlT19snCttf5j5RUAXLz': 'tarih_06_kurtulus_savasi',
    '4GUvpqBBImcLmN2eh1HK': 'tarih_07_ataturk_inkilap',
    'onwrfsH02TgIhlyRUh56': 'tarih_08_cumhuriyet_donemi',
    'xQWHl1hBYAKM96X4deR8': 'tarih_09_cagdas_turk_dunya',

    // TÜRKÇE
    '80e0wkTLvaTQzPD6puB7': 'turkce_01_ses_bilgisi',
    'yWlh5C6jB7lzuJOodr2t': 'turkce_02_yapi_bilgisi',
    'ICNDiSlTmmjWEQPT6rmT': 'turkce_03_sozcuk_turleri',
    'JmyiPxf3n96Jkxqsa9jY': 'turkce_04_sozcukte_anlam',
    'AJNLHhhaG2SLWOvxDYqW': 'turkce_05_cumlede_anlam',
    'nN8JOTR7LZm01AN2i3sQ': 'turkce_06_paragrafta_anlam',
    'jXcsrl5HEb65DmfpfqqI': 'turkce_07_anlatim_bozuklugu',
    'qSEqigIsIEBAkhcMTyCE': 'turkce_08_yazim_noktalama',
    'wnt2zWaV1pX8p8s8BBc9': 'turkce_09_sozel_mantik',

    // COĞRAFYA
    '1FEcPsGduhjcQARpaGBk': 'cografya_01_konum',
    'kbs0Ffved9pCP3Hq9M9k': 'cografya_02_fiziki',
    '6e0Thsz2RRNHFcwqQXso': 'cografya_03_iklim',
    'uYDrMlBCEAho5776WZi8': 'cografya_04_beseri',
    'WxrtQ26p2My4uJa0h1kk': 'cografya_05_ekonomik',
    'GdpN8uxJNGtexWrkoL1T': 'cografya_06_bolgeler',

    // VATANDAŞLIK
    'AQ0Zph76dzPdr87H1uKa': 'vatandaslik_01_hukuka_giris',
    'n4OjWupHmouuybQzQ1Fc': 'vatandaslik_02_anayasa',
    'xXGXiqx2TkCtI4C7GMQg': 'vatandaslik_03_temel_ilkeler',
    '1JZAYECyEn7farNNyGyx': 'vatandaslik_04_organlar',
    'lv93cmhwq7RmOFM5WxWD': 'vatandaslik_05_idari_yapi',
    'Bo3qqooJsqtIZrK5zc9S': 'vatandaslik_06_haklar'
};

const lessonMap = {
    'MATEMATiK001': 'matematik',
    'caZ5LwfH3QJrBVUQCros': 'tarih',
    'L3i1Rqv2LN3AKFFejuUg': 'turkce',
    'A779wvZWQcbvanmbS8Qz': 'cografya',
    '2ztkqV35cWjGRkhYRutg': 'vatandaslik',
    'GUNCEL001': 'guncel_bilgiler'
};

const TOPICS_FILE = path.join(__dirname, '../lib/core/data/topics_data.dart');
const ASSETS_QUESTIONS_DIR = path.join(__dirname, '../assets/data/questions');
const GITHUB_QUESTIONS_DIR = path.join(__dirname, '../github_data/questions');
const GITHUB_FLASHCARDS_DIR = path.join(__dirname, '../github_data/flashcards');
const GITHUB_VERSION_FILE = path.join(__dirname, '../github_data/version.json');

async function refactor() {
    console.log('🚀 KPSS Asistan Projesi Yeniden Yapılandırma Başlatıldı...');

    try {
        // 1. topics_data.dart dosyasını güncelle
        let topicsContent = await fs.readFile(TOPICS_FILE, 'utf8');

        // ID'leri değiştir
        for (const [oldId, newId] of Object.entries(idMap)) {
            const regex = new RegExp(`'id': '${oldId}'`, 'g');
            topicsContent = topicsContent.replace(regex, `'id': '${newId}'`);
        }

        // Lesson ID'leri değiştir
        for (const [oldId, newId] of Object.entries(lessonMap)) {
            const regex = new RegExp(`'lesson_id': '${oldId}'`, 'g');
            topicsContent = topicsContent.replace(regex, `'lesson_id': '${newId}'`);
        }

        await fs.writeFile(TOPICS_FILE, topicsContent, 'utf8');
        console.log('✅ topics_data.dart güncellendi.');

        // 2. Dosyaları yeniden adlandır (Assets & GitHub)
        const dirsToRename = [ASSETS_QUESTIONS_DIR, GITHUB_QUESTIONS_DIR, GITHUB_FLASHCARDS_DIR];

        for (const dir of dirsToRename) {
            try {
                const files = await fs.readdir(dir);
                for (const file of files) {
                    const oldId = file.split('.')[0];
                    if (idMap[oldId]) {
                        const extension = file.split('.').slice(1).join('.');
                        const oldPath = path.join(dir, file);
                        const newPath = path.join(dir, `${idMap[oldId]}.${extension}`);
                        await fs.rename(oldPath, newPath);
                        console.log(`📦 Taşındı: ${file} -> ${idMap[oldId]}.${extension} (${path.basename(dir)})`);
                    }
                }
            } catch (e) {
                console.warn(`⚠️ Klasör işlenirken hata (Atlanıyor): ${dir}`);
            }
        }

        // 3. version.json dosyasını tertemiz oluştur
        const newVersion = {
            last_updated: new Date().toISOString().split('T')[0],
            questions: {},
            flashcards: {},
            stories: { "history_story_1": 1 },
            explanations: {},
            matching_games: {}
        };

        // Yeni ID'lere göre version.json doldur (Default v1)
        const allNewIds = Object.values(idMap);

        // Matematik ve Güncel Bilgiler gibi zaten anlamlı olanları da ekle
        // (Bu basitlik için topics_data içinden ID'leri cımbızlayabiliriz ama şu an idMap yeterli)

        for (const newId of allNewIds) {
            newVersion.questions[newId] = 1;
            newVersion.flashcards[newId] = 1;
        }

        // Matematik ve Güncel Bilgileri de manuel ekleyelim (Eski ID map'te olmayanlar)
        const otherIds = [
            'mat_temel_001', 'mat_rasyonel_001', 'mat_esitsizlik_001', 'mat_uslu_001',
            'mat_carpan_001', 'mat_prob_001', 'mat_kume_001', 'mat_olasilik_001', 'mat_mantik_001',
            'GUNCEL_BM_KURULUS', 'GUNCEL_NATO_AB', 'GUNCEL_BOLGESEL_KURULUS', 'GUNCEL_TURKIYE_KURULUS',
            'GUNCEL_ONEMLI_TARIHLER', 'GUNCEL_OLAYLAR'
        ];
        for (const id of otherIds) {
            newVersion.questions[id] = 1;
        }

        await fs.writeFile(GITHUB_VERSION_FILE, JSON.stringify(newVersion, null, 2), 'utf8');
        console.log('✅ version.json yeni ID\'lerle sıfırlandı.');

        console.log('\n✨ OPERASYON BAŞARIYLA TAMAMLANDI!');
        console.log('👉 Dashboard\'ı yenileyebilir ve "GitHub\'a Yayınla" diyerek her şeyi pırıl pırıl gönderebilirsin.');

    } catch (error) {
        console.error('❌ KRİTİK HATA:', error);
    }
}

refactor();
