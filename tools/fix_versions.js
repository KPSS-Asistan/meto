const fs = require('fs').promises;
const path = require('path');

const VERSION_PATH = path.join(__dirname, '../github_data/version.json');
const QUESTIONS_DIR = path.join(__dirname, '../assets/data/questions');

async function fixVersions() {
    try {
        console.log('🔄 Otomatik Versiyon Güncelleme Başlatıldı...');

        // 1. Mevcut version.json'u oku
        const versionData = JSON.parse(await fs.readFile(VERSION_PATH, 'utf8'));

        // 2. Soru klasörünü tara
        const files = await fs.readdir(QUESTIONS_DIR);
        const jsonFiles = files.filter(f => f.endsWith('.json'));

        let updateCount = 0;

        for (const file of jsonFiles) {
            const topicId = file.replace('.json', '');
            const filePath = path.join(QUESTIONS_DIR, file);
            const stats = await fs.stat(filePath);

            // Eğer dosya boş değilse (2 byte'dan büyükse)
            if (stats.size > 10) {
                // Versiyonu artır (Eğer daha önce yoksa 1'den başla)
                const currentVersion = versionData.questions[topicId] || 0;
                versionData.questions[topicId] = currentVersion + 1;
                updateCount++;
                console.log(`✅ ${topicId}: v${currentVersion} -> v${versionData.questions[topicId]}`);
            }
        }

        // 3. Güncel tarihi yaz
        versionData.last_updated = new Date().toISOString().split('T')[0];

        // 4. Kaydet
        await fs.writeFile(VERSION_PATH, JSON.stringify(versionData, null, 2), 'utf8');

        console.log(`\n🚀 BİTTİ! ${updateCount} konu versiyonu güncellendi.`);
        console.log('👉 Şimdi Dashboard üzerinden "Yayınla" butonuna basabilirsin.');

    } catch (error) {
        console.error('❌ HATA:', error);
    }
}

fixVersions();
