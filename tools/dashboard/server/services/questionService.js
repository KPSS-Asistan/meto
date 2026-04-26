const fs = require('fs').promises;
const path = require('path');
const { QUESTIONS_DIR } = require('../config');

async function loadQuestions(topicId) {
    try {
        const filePath = path.join(QUESTIONS_DIR, `${topicId}.json`);
        const content = await fs.readFile(filePath, 'utf8');
        return JSON.parse(content);
    } catch { return []; }
}

async function saveQuestions(topicId, questions) {
    const filePath = path.join(QUESTIONS_DIR, `${topicId}.json`);
    await fs.writeFile(filePath, JSON.stringify(questions, null, 4), 'utf8');
}

module.exports = { loadQuestions, saveQuestions };
