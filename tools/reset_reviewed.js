const fs = require('fs');
const path = require('path');

const QUESTIONS_DIR = path.join(__dirname, '..', 'assets', 'data', 'questions');

async function resetAllReviewedFlags() {
    const files = fs.readdirSync(QUESTIONS_DIR).filter(f => f.endsWith('.json'));
    let totalReset = 0;

    for (const file of files) {
        const filePath = path.join(QUESTIONS_DIR, file);
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            const questions = JSON.parse(content);

            let modified = false;
            questions.forEach(q => {
                if (q.aiReviewed) {
                    delete q.aiReviewed;
                    modified = true;
                    totalReset++;
                }
            });

            if (modified) {
                fs.writeFileSync(filePath, JSON.stringify(questions, null, 4), 'utf8');
                console.log(`${file}: aiReviewed temizlendi`);
            }
        } catch (e) {
            console.log(`${file}: Hata - ${e.message}`);
        }
    }

    console.log(`\n✅ Toplam ${totalReset} sorunun aiReviewed flag'i temizlendi!`);
    console.log('Artık tüm sorular tekrar analiz edilebilir.');
}

resetAllReviewedFlags();
