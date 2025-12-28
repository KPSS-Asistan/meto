const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(serverPath, 'utf8');

// require('./typo_helper') satırından sonra topics.js'i ekle
const typoLine = "const { analyzeTypos } = require('./typo_helper');";
const topicsLine = "const { TOPICS, LESSON_TARGETS } = require('./topics');";

if (!content.includes(topicsLine)) {
    if (content.includes(typoLine)) {
        content = content.replace(typoLine, typoLine + '\n' + topicsLine);
    } else {
        // exec satırından sonra ekle
        const execLine = "const { exec } = require('child_process');";
        if (content.includes(execLine)) {
            content = content.replace(execLine, execLine + '\n' + topicsLine);
        }
    }
    fs.writeFileSync(serverPath, content, 'utf8');
    console.log('topics.js import added!');
} else {
    console.log('topics.js import already exists');
}
