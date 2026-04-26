const fs = require('fs');
const path = require('path');

const questionsDir = path.join(__dirname, '..', '..', '..', 'questions');

// "ve" anlamında kullanılan "and" kalıpları
const andPatterns = [
    /\band\b/gi,
    /, and /gi,
    / & /gi,
    /\s+and\s+/gi
];

// Türkçe karşılıkları
const turkishReplacements = {
    ', and ': ', ve ',
    ' & ': ' ve ',
    ' and ': ' ve ',
    'And ': 'Ve ',
    'AND ': 'VE '
};

function processFile(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        let modified = content;
        let changes = [];

        // Her bir "and" kalıbını kontrol et
        Object.entries(turkishReplacements).forEach(([english, turkish]) => {
            if (modified.includes(english)) {
                modified = modified.replace(new RegExp(english.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g'), turkish);
                changes.push(`"${english}" → "${turkish}"`);
            }
        });

        // Değişiklik varsa dosyayı güncelle
        if (changes.length > 0) {
            fs.writeFileSync(filePath, modified, 'utf8');
            console.log(`✅ ${path.basename(filePath)}: ${changes.join(', ')}`);
            return true;
        }
    } catch (error) {
        console.error(`❌ Hata (${path.basename(filePath)}):`, error.message);
    }
    return false;
}

// Tüm JSON dosyalarını işle
const files = fs.readdirSync(questionsDir).filter(f => f.endsWith('.json'));
let totalChanges = 0;

console.log('🔍 "and" → "ve" değişiklikleri aranıyor...\n');

files.forEach(file => {
    const filePath = path.join(questionsDir, file);
    if (processFile(filePath)) {
        totalChanges++;
    }
});

console.log(`\n✅ Toplam ${totalChanges} dosya güncellendi.`);
