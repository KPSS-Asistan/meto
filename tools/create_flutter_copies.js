const fs = require('fs');
const path = require('path');

// Eski isimden yeni isme mapping (Flutter için)
const fileMap = {
    'JnFbEQt0uA8RSEuy22SQ.json': 'tarih_01_islam_oncesi.json',
    '9Hg8tuMRdMTuVY7OZ9HL.json': 'tarih_02_ilk_musluman_turk.json',
    '8aIrKLvItXrwvOHq1L34.json': 'tarih_03_selcuklu.json',
    'JU0iGKNhR7NQzA8M77vt.json': 'tarih_04_osmanli_siyasi.json',
    '9WTotPoDW5OuWxsCf4Li.json': 'tarih_05_osmanli_kultur.json',
    'DlT19snCttf5j5RUAXLz.json': 'tarih_06_kurtulus_savasi.json',
    '4GUvpqBBImcLmN2eh1HK.json': 'tarih_07_ataturk_inkilap.json',
    'onwrfsH02TgIhlyRUh56.json': 'tarih_08_cumhuriyet_donemi.json',
    'xQWHl1hBYAKM96X4deR8.json': 'tarih_09_cagdas_turk_dunya.json',
    '80e0wkTLvaTQzPD6puB7.json': 'turkce_01_ses_bilgisi.json',
    'yWlh5C6jB7lzuJOodr2t.json': 'turkce_02_yapi_bilgisi.json',
    'ICNDiSlTmmjWEQPT6rmT.json': 'turkce_03_sozcuk_turleri.json',
    'JmyiPxf3n96Jkxqsa9jY.json': 'turkce_04_sozcukte_anlam.json',
    'AJNLHhhaG2SLWOvxDYqW.json': 'turkce_05_cumlede_anlam.json',
    'nN8JOTR7LZm01AN2i3sQ.json': 'turkce_06_paragrafta_anlam.json',
    'jXcsrl5HEb65DmfpfqqI.json': 'turkce_07_anlatim_bozuklugu.json',
    'qSEqigIsIEBAkhcMTyCE.json': 'turkce_08_yazim_noktalama.json',
    'wnt2zWaV1pX8p8s8BBc9.json': 'turkce_09_sozel_mantik.json',
    '1FEcPsGduhjcQARpaGBk.json': 'cografya_01_konum.json',
    'kbs0Ffved9pCP3Hq9M9k.json': 'cografya_02_fiziki.json',
    '6e0Thsz2RRNHFcwqQXso.json': 'cografya_03_iklim.json',
    'uYDrMlBCEAho5776WZi8.json': 'cografya_04_beseri.json',
    'WxrtQ26p2My4uJa0h1kk.json': 'cografya_05_ekonomik.json',
    'GdpN8uxJNGtexWrkoL1T.json': 'cografya_06_bolgeler.json',
    'AQ0Zph76dzPdr87H1uKa.json': 'vatandaslik_01_hukuka_giris.json',
    'n4OjWupHmouuybQzQ1Fc.json': 'vatandaslik_02_anayasa.json',
    'xXGXiqx2TkCtI4C7GMQg.json': 'vatandaslik_03_temel_ilkeler.json',
    '1JZAYECyEn7farNNyGyx.json': 'vatandaslik_04_organlar.json',
    'lv93cmhwq7RmOFM5WxWD.json': 'vatandaslik_05_idari_yapi.json',
    'Bo3qqooJsqtIZrK5zc9S.json': 'vatandaslik_06_haklar.json'
};

const assetsDir = path.join(__dirname, '../assets/data/questions');

console.log('📂 Flutter için dosya kopyaları oluşturuluyor...\n');

for (const [oldName, newName] of Object.entries(fileMap)) {
    const oldPath = path.join(assetsDir, oldName);
    const newPath = path.join(assetsDir, newName);

    if (fs.existsSync(oldPath)) {
        // Eski dosyayı yeni isme kopyala
        fs.copyFileSync(oldPath, newPath);
        console.log(`✅ ${oldName} → ${newName} (kopyalandı)`);
    } else if (fs.existsSync(newPath)) {
        console.log(`⏭️ ${newName} zaten var`);
    } else {
        // Her iki dosya da yoksa, boş dosya oluştur
        fs.writeFileSync(newPath, '[]', 'utf8');
        console.log(`📄 ${newName} (boş oluşturuldu)`);
    }
}

console.log('\n✨ Tamamlandı! Flutter artık dosyaları bulabilecek.');
