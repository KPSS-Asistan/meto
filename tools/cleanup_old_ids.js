const fs = require('fs').promises;
const path = require('path');

const idMap = {
    'JnFbEQt0uA8RSEuy22SQ': 'tarih_01_islam_oncesi',
    '9Hg8tuMRdMTuVY7OZ9HL': 'tarih_02_ilk_musluman_turk',
    '8aIrKLvItXrwvOHq1L34': 'tarih_03_selcuklu',
    'JU0iGKNhR7NQzA8M77vt': 'tarih_04_osmanli_siyasi',
    '9WTotPoDW5OuWxsCf4Li': 'tarih_05_osmanli_kultur',
    'DlT19snCttf5j5RUAXLz': 'tarih_06_kurtulus_savasi',
    '4GUvpqBBImcLmN2eh1HK': 'tarih_07_ataturk_inkilap',
    'onwrfsH02TgIhlyRUh56': 'tarih_08_cumhuriyet_donemi',
    'xQWHl1hBYAKM96X4deR8': 'tarih_09_cagdas_turk_dunya',
    '80e0wkTLvaTQzPD6puB7': 'turkce_01_ses_bilgisi',
    'yWlh5C6jB7lzuJOodr2t': 'turkce_02_yapi_bilgisi',
    'ICNDiSlTmmjWEQPT6rmT': 'turkce_03_sozcuk_turleri',
    'JmyiPxf3n96Jkxqsa9jY': 'turkce_04_sozcukte_anlam',
    'AJNLHhhaG2SLWOvxDYqW': 'turkce_05_cumlede_anlam',
    'nN8JOTR7LZm01AN2i3sQ': 'turkce_06_paragrafta_anlam',
    'jXcsrl5HEb65DmfpfqqI': 'turkce_07_anlatim_bozuklugu',
    'qSEqigIsIEBAkhcMTyCE': 'turkce_08_yazim_noktalama',
    'wnt2zWaV1pX8p8s8BBc9': 'turkce_09_sozel_mantik',
    '1FEcPsGduhjcQARpaGBk': 'cografya_01_konum',
    'kbs0Ffved9pCP3Hq9M9k': 'cografya_02_fiziki',
    '6e0Thsz2RRNHFcwqQXso': 'cografya_03_iklim',
    'uYDrMlBCEAho5776WZi8': 'cografya_04_beseri',
    'WxrtQ26p2My4uJa0h1kk': 'cografya_05_ekonomik',
    'GdpN8uxJNGtexWrkoL1T': 'cografya_06_bolgeler',
    'AQ0Zph76dzPdr87H1uKa': 'vatandaslik_01_hukuka_giris',
    'n4OjWupHmouuybQzQ1Fc': 'vatandaslik_02_anayasa',
    'xXGXiqx2TkCtI4C7GMQg': 'vatandaslik_03_temel_ilkeler',
    '1JZAYECyEn7farNNyGyx': 'vatandaslik_04_organlar',
    'lv93cmhwq7RmOFM5WxWD': 'vatandaslik_05_idari_yapi',
    'Bo3qqooJsqtIZrK5zc9S': 'vatandaslik_06_haklar'
};

const DIRS = [
    path.join(__dirname, '../assets/data/questions'),
    path.join(__dirname, '../github_data/questions'),
    path.join(__dirname, '../github_data/flashcards')
];

async function finalCleanup() {
    console.log('🧹 Eski ID\'li dosyalar temizleniyor...');

    for (const dir of DIRS) {
        try {
            const files = await fs.readdir(dir);
            for (const file of files) {
                const id = file.split('.')[0];
                if (idMap[id]) {
                    const filePath = path.join(dir, file);
                    await fs.unlink(filePath);
                    console.log(`🗑️ Silindi: ${file} (${path.basename(dir)})`);
                }
            }
        } catch (e) {
            // Klasör yoksa geç
        }
    }
    console.log('✨ Temizlik bitti! Sadece gıcır gıcır yeni isimler kaldı.');
}

finalCleanup();
