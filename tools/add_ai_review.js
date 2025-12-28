const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
const snippetPath = path.join(__dirname, 'ai_review_endpoint.js');

let content = fs.readFileSync(serverPath, 'utf8');
const snippet = fs.readFileSync(snippetPath, 'utf8');

// Find the /ai-status endpoint and insert before it
const searchPattern = "// GET /ai-status";
const idx = content.indexOf(searchPattern);

if (idx !== -1) {
    // Check if already added
    if (!content.includes("/ai-review")) {
        const before = content.substring(0, idx);
        const after = content.substring(idx);
        content = before + "        " + snippet.replace(/\n/g, '\n        ') + "\n\n        " + after;
        fs.writeFileSync(serverPath, content, 'utf8');
        console.log('AI Review endpoint added successfully!');
    } else {
        console.log('AI Review endpoint already exists.');
    }
} else {
    console.log('Could not find insertion point. Adding at end of routes.');

    // Alternatif: /duplicates'den önce ekle
    const altPattern = "// GET /duplicates";
    const altIdx = content.indexOf(altPattern);
    if (altIdx !== -1 && !content.includes("/ai-review")) {
        const before = content.substring(0, altIdx);
        const after = content.substring(altIdx);
        content = before + "        " + snippet.replace(/\n/g, '\n        ') + "\n\n        " + after;
        fs.writeFileSync(serverPath, content, 'utf8');
        console.log('AI Review endpoint added (alternative location)!');
    }
}
