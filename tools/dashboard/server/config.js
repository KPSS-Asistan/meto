const path = require('path');
const fs = require('fs');

const ROOT_DIR = path.resolve(__dirname, '../../../');
const DATA_DIR = path.join(ROOT_DIR, 'assets/data');
const QUESTIONS_DIR = path.join(DATA_DIR, 'questions');
const TOOLS_DIR = path.join(ROOT_DIR, 'tools');
const PUBLIC_DIR = path.join(__dirname, '../client'); // New client dir

// Data Files
const REPORTS_FILE = path.join(DATA_DIR, 'reports.json');
const FEEDBACK_FILE = path.join(DATA_DIR, 'feedback.json');
const HISTORY_FILE = path.join(DATA_DIR, 'history.json');
const TEMPLATES_FILE = path.join(DATA_DIR, 'templates.json');

// Ensure directories exist
if (!fs.existsSync(QUESTIONS_DIR)) {
    try { fs.mkdirSync(QUESTIONS_DIR, { recursive: true }); } catch (e) { }
}

module.exports = {
    PORT: process.env.PORT || 3456,
    ROOT_DIR,
    DATA_DIR,
    QUESTIONS_DIR,
    TOOLS_DIR,
    PUBLIC_DIR,
    REPORTS_FILE,
    FEEDBACK_FILE,
    HISTORY_FILE,
    TEMPLATES_FILE
};
