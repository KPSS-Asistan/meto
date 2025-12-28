const fs = require('fs').promises;
const path = require('path');

const SOURCE_DIR = path.join(__dirname, '../assets/data/questions');
const TARGET_DIR = path.join(__dirname, '../github_data/questions');

async function restoreData() {
    console.log('🚑 Veri Kurtarma Operasyonu Başlatıldı...');

    try {
        const files = await fs.readdir(SOURCE_DIR);
        let count = 0;

        for (const file of files) {
            if (file.endsWith('.json')) {
                const sourcePath = path.join(SOURCE_DIR, file);
                const targetPath = path.join(TARGET_DIR, file);

                const stats = await fs.stat(sourcePath);

                // Sadece dolu dosyaları (1KB üstü) kopyala
                if (stats.size > 100) {
                    await fs.copyFile(sourcePath, targetPath);
                    console.log(`✅ Kurtarıldı: ${file} (${(stats.size / 1024).toFixed(1)} KB)`);
                    count++;
                }
            }
        }

        console.log(`\n✨ Toplam ${count} dosya Assets'ten GitHub Data'ya kopyalandı.`);
        console.log('👉 Şimdi "Yayınla" diyebilirsin!');

    } catch (error) {
        console.error('❌ Hata:', error);
    }
}

restoreData();
