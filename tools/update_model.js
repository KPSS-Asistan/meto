const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(serverPath, 'utf8');

// Eski modeli yenisiyle değiştir
const oldModel = "model: 'google/gemini-2.0-flash-001'";
const newModel = "model: 'x-ai/grok-4.1-fast'";

if (content.includes(oldModel)) {
    content = content.replace(new RegExp(oldModel.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g'), newModel);
    console.log('Model updated to x-ai/grok-4.1-fast');
} else {
    // Alternatif patternler dene
    const patterns = [
        "model: 'google/gemini-2.0-flash-exp:free'",
        'model: "google/gemini-2.0-flash-001"',
        'model: "google/gemini-2.0-flash-exp:free"'
    ];

    let found = false;
    for (const p of patterns) {
        if (content.includes(p)) {
            content = content.replace(new RegExp(p.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g'), newModel);
            console.log('Model updated from alternative pattern');
            found = true;
            break;
        }
    }

    if (!found) {
        console.log('Model pattern not found, checking reviewQuestionsWithAI_Batch...');
    }
}

fs.writeFileSync(serverPath, content, 'utf8');
console.log('Done!');
