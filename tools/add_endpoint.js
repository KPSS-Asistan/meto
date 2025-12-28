const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
const snippetPath = path.join(__dirname, 'all_questions_endpoint.js');

let content = fs.readFileSync(serverPath, 'utf8');
const snippet = fs.readFileSync(snippetPath, 'utf8');

// Find the /search endpoint and insert before it
const searchPattern = "// GET /search";
const idx = content.indexOf(searchPattern);

if (idx !== -1) {
    // Check if already added
    if (!content.includes("/all-questions")) {
        const before = content.substring(0, idx);
        const after = content.substring(idx);
        content = before + "        " + snippet.replace(/\n/g, '\n        ') + "\n\n        " + after;
        fs.writeFileSync(serverPath, content, 'utf8');
        console.log('Endpoint added successfully!');
    } else {
        console.log('Endpoint already exists.');
    }
} else {
    console.log('Could not find insertion point.');
}
