const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'question_server.js');
const snippetPath = path.join(__dirname, 'ai_review_endpoint.js');

let content = fs.readFileSync(serverPath, 'utf8');
const newSnippet = fs.readFileSync(snippetPath, 'utf8');

// Eski versiyonu bul ve değiştir
const oldPattern = /\/\/ AI Soru Kontrolcusu[\s\S]*?async function reviewQuestionsWithAI\(questions[\s\S]*?\n\}/;
const newFuncPattern = /\/\/ AI Soru Kontrolcusu[\s\S]*?async function reviewQuestionsWithAI_Batch\(questions[\s\S]*?\n\}/;

if (content.match(newFuncPattern)) {
    console.log('Batch version already exists. Replacing...');
    content = content.replace(newFuncPattern, newSnippet.trim());
} else if (content.match(oldPattern)) {
    console.log('Replacing old version with batch version...');
    content = content.replace(oldPattern, newSnippet.trim());
} else {
    console.log('Could not find old version. Check manually.');
}

fs.writeFileSync(serverPath, content, 'utf8');
console.log('AI Review endpoint updated to batch version!');
