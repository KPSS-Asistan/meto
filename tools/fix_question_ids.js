const fs = require('fs');
const path = require('path');

const QUESTIONS_DIR = path.join(__dirname, '../assets/data/questions');
const GITHUB_DIR = path.join(__dirname, '../github_data/questions');

// Tüm soru dosyalarını işle
const files = fs.readdirSync(QUESTIONS_DIR).filter(f => f.endsWith('.json'));

for (const file of files) {
    const filePath = path.join(QUESTIONS_DIR, file);
    const content = fs.readFileSync(filePath, 'utf8');

    try {
        const questions = JSON.parse(content);

        if (!Array.isArray(questions) || questions.length === 0) continue;

        // Dosya adından prefix al (tarih_01 -> tarih)
        const prefix = file.replace('.json', '').split('_').slice(0, -1).join('_') || file.replace('.json', '');

        // ID'leri yeniden numarala
        questions.forEach((q, index) => {
            const newId = `${prefix}_${String(index + 1).padStart(3, '0')}`;
            q.id = newId;
        });

        // Dosyayı kaydet
        const newContent = JSON.stringify(questions, null, 2);
        fs.writeFileSync(filePath, newContent, 'utf8');

        // GitHub klasörüne de kopyala
        const githubPath = path.join(GITHUB_DIR, file);
        fs.writeFileSync(githubPath, newContent, 'utf8');

        console.log(`✅ ${file}: ${questions.length} soru, ID'ler düzeltildi (${prefix}_001 - ${prefix}_${String(questions.length).padStart(3, '0')})`);

    } catch (e) {
        // Boş veya hatalı dosyaları atla
    }
}

console.log('\n🎉 Tüm soru ID\'leri düzeltildi!');
