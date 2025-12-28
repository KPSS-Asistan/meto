const fs = require('fs');
const path = require('path');

// Yeni isimden eski isme mapping
const fileRenameMap = {
    'tarih_01_islam_oncesi.json': 'JnFbEQt0uA8RSEuy22SQ.json',
    'tarih_02_ilk_musluman_turk.json': '9Hg8tuMRdMTuVY7OZ9HL.json',
    'tarih_03_selcuklu.json': '8aIrKLvItXrwvOHq1L34.json',
    'tarih_04_osmanli_siyasi.json': 'JU0iGKNhR7NQzA8M77vt.json',
    'tarih_05_osmanli_kultur.json': '9WTotPoDW5OuWxsCf4Li.json',
    'tarih_06_kurtulus_savasi.json': 'DlT19snCttf5j5RUAXLz.json',
    'tarih_07_ataturk_inkilap.json': '4GUvpqBBImcLmN2eh1HK.json',
    'tarih_08_cumhuriyet_donemi.json': 'onwrfsH02TgIhlyRUh56.json',
    'tarih_09_cagdas_turk_dunya.json': 'xQWHl1hBYAKM96X4deR8.json',
    'turkce_01_ses_bilgisi.json': '80e0wkTLvaTQzPD6puB7.json',
    'turkce_02_yapi_bilgisi.json': 'yWlh5C6jB7lzuJOodr2t.json',
    'turkce_03_sozcuk_turleri.json': 'ICNDiSlTmmjWEQPT6rmT.json',
    'turkce_04_sozcukte_anlam.json': 'JmyiPxf3n96Jkxqsa9jY.json',
    'turkce_05_cumlede_anlam.json': 'AJNLHhhaG2SLWOvxDYqW.json',
    'turkce_06_paragrafta_anlam.json': 'nN8JOTR7LZm01AN2i3sQ.json',
    'turkce_07_anlatim_bozuklugu.json': 'jXcsrl5HEb65DmfpfqqI.json',
    'turkce_08_yazim_noktalama.json': 'qSEqigIsIEBAkhcMTyCE.json',
    'turkce_09_sozel_mantik.json': 'wnt2zWaV1pX8p8s8BBc9.json',
    'cografya_01_konum.json': '1FEcPsGduhjcQARpaGBk.json',
    'cografya_02_fiziki.json': 'kbs0Ffved9pCP3Hq9M9k.json',
    'cografya_03_iklim.json': '6e0Thsz2RRNHFcwqQXso.json',
    'cografya_04_beseri.json': 'uYDrMlBCEAho5776WZi8.json',
    'cografya_05_ekonomik.json': 'WxrtQ26p2My4uJa0h1kk.json',
    'cografya_06_bolgeler.json': 'GdpN8uxJNGtexWrkoL1T.json',
    'vatandaslik_01_hukuka_giris.json': 'AQ0Zph76dzPdr87H1uKa.json',
    'vatandaslik_02_anayasa.json': 'n4OjWupHmouuybQzQ1Fc.json',
    'vatandaslik_03_temel_ilkeler.json': 'xXGXiqx2TkCtI4C7GMQg.json',
    'vatandaslik_04_organlar.json': '1JZAYECyEn7farNNyGyx.json',
    'vatandaslik_05_idari_yapi.json': 'lv93cmhwq7RmOFM5WxWD.json',
    'vatandaslik_06_haklar.json': 'Bo3qqooJsqtIZrK5zc9S.json'
};

const DIRS = [
    path.join(__dirname, '../assets/data/questions'),
    path.join(__dirname, '../github_data/questions')
];

console.log('🔄 Dosya isimleri eski haline getiriliyor...\n');

for (const dir of DIRS) {
    console.log(`📁 ${dir}`);

    for (const [newName, oldName] of Object.entries(fileRenameMap)) {
        const newPath = path.join(dir, newName);
        const oldPath = path.join(dir, oldName);

        if (fs.existsSync(newPath)) {
            // Eski isimli dosya varsa sil
            if (fs.existsSync(oldPath)) {
                fs.unlinkSync(oldPath);
            }
            // Yeni isimli dosyayı eski isme çevir
            fs.renameSync(newPath, oldPath);
            console.log(`  ✅ ${newName} → ${oldName}`);
        }
    }
}

console.log('\n✨ Tüm dosya isimleri eski haline getirildi!');
