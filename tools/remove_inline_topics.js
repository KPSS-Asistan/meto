const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(serverPath, 'utf8');

// Bozuk inline TOPICS tanımını bul ve sil (satır 65-130 civarı)
// "// TÜM KONULAR" yorumundan "// YARDIMCI" yorumuna kadar olan kısmı sil

// Pattern: // TÜM KONULAR ... const LESSON_TARGETS = { ... };
const startPattern = /\/\/ [^\n]*TÜM KONULAR[^\n]*\n/;
const startMatch = content.match(startPattern);

if (!startMatch) {
    // Bozuk encoding versiyonu dene
    const altPattern = /\/\/ [^\n]*M KONULAR[^\n]*\n/;
    const altMatch = content.match(altPattern);
    if (altMatch) {
        console.log('Found with alt pattern');
    }
}

// Daha güvenilir: const TOPICS = { satırını bul
const topicsStart = content.indexOf('const TOPICS = {');
const helperStart = content.indexOf('// YARDIMCI');

if (topicsStart > 50 && helperStart > topicsStart) {
    // Satır 65-66'daki yorumları da bulalım
    let cutStart = topicsStart;

    // 2 satır öncesini kontrol et (yorum satırları)
    const before = content.substring(0, topicsStart);
    const lines = before.split('\n');
    // Son 3 satırı kontrol et
    for (let i = Math.max(0, lines.length - 4); i < lines.length; i++) {
        if (lines[i].includes('KONULAR') || lines[i].trim().startsWith('//')) {
            cutStart = before.lastIndexOf('\n' + lines[i]);
            break;
        }
    }

    // LESSON_TARGETS'ın sonunu bul
    const targetsEnd = content.indexOf('};', content.indexOf('const LESSON_TARGETS'));

    if (targetsEnd > topicsStart) {
        // Sil
        const newContent = content.substring(0, cutStart) + '\n' + content.substring(targetsEnd + 3);
        fs.writeFileSync(serverPath, newContent, 'utf8');
        console.log(`Removed inline TOPICS from position ${cutStart} to ${targetsEnd + 3}`);
    }
} else {
    console.log('Could not find inline TOPICS definition');
    console.log('topicsStart:', topicsStart, 'helperStart:', helperStart);
}
