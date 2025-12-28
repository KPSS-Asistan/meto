const fs = require('fs');
const path = require('path');

// Ters harita - yeni ID'den eski ID'ye
const reverseIdMap = {
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

const DIRS = [
    path.join(__dirname, '../assets/data/questions'),
    path.join(__dirname, '../github_data/questions')
];

for (const dir of DIRS) {
    const files = fs.readdirSync(dir).filter(f => f.endsWith('.json'));

    for (const file of files) {
        const filePath = path.join(dir, file);
        let content = fs.readFileSync(filePath, 'utf8');

        // Her yeni ID'yi eskisiyle değiştir
        for (const [newId, oldId] of Object.entries(reverseIdMap)) {
            content = content.replace(new RegExp(`"topicId":\\s*"${newId}"`, 'g'), `"topicId": "${oldId}"`);
        }

        fs.writeFileSync(filePath, content, 'utf8');
    }
}

console.log('✅ topicId\'ler eski haline getirildi!');
