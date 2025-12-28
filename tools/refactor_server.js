const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'question_server.js');
let content = fs.readFileSync(filePath, 'utf8');

// 1. Add Import
if (!content.includes("require('./topics')")) {
    const importMarker = "const { exec } = require('child_process');";
    const importPos = content.indexOf(importMarker);
    if (importPos !== -1) {
        const insertPos = content.indexOf('\n', importPos) + 1;
        content = content.slice(0, insertPos) + "const { TOPICS, LESSON_TARGETS } = require('./topics');\n" + content.slice(insertPos);
    }
}

// 2. Remove old TOPICS definition
const startTopics = content.indexOf('const TOPICS = {');
const startLesson = content.indexOf('const LESSON_TARGETS = {');

if (startTopics !== -1 && startLesson !== -1) {
    // Remove from TOPICS start up to LESSON_TARGETS start
    // But keeps comments above LESSON_TARGETS if any? Usually text between them is comments or whitespace.
    content = content.slice(0, startTopics) + content.slice(startLesson);
}

// 3. Remove old LESSON_TARGETS definition
// Now find LESSON_TARGETS again because indices changed
const startLesson2 = content.indexOf('const LESSON_TARGETS = {');
if (startLesson2 !== -1) {
    // Find the next big block marker or utility function
    const helperMarker = "const sendJSON";
    const endLesson = content.indexOf(helperMarker, startLesson2);

    if (endLesson !== -1) {
        // Find the start of the comment block before sendJSON if possible to keep it clean
        // Search backwards from endLesson for "//" or just cut to endLesson
        // Let's just cut to endLesson, might leave some empty lines, no big deal.
        content = content.slice(0, startLesson2) + content.slice(endLesson);
    }
}

fs.writeFileSync(filePath, content, 'utf8');
console.log('Fixed question_server.js structure.');
