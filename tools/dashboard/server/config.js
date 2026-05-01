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
const TOPICS_FILE = path.join(DATA_DIR, 'topics.json');

// Ensure directories exist
if (!fs.existsSync(QUESTIONS_DIR)) {
    try { fs.mkdirSync(QUESTIONS_DIR, { recursive: true }); } catch (e) { }
}

const EXPLANATIONS_DIR = path.join(DATA_DIR, 'explanations');
const FLASHCARDS_DIR = path.join(DATA_DIR, 'flashcards');
const GLOSSARY_DIR = path.join(DATA_DIR, 'glossary');
const MATCHING_GAMES_DIR = path.join(DATA_DIR, 'matching_games');
const PRODUCTIVITY_DIR = path.join(DATA_DIR, 'productivity');
const STORIES_DIR = path.join(DATA_DIR, 'stories');
const NOTIFICATIONS_FILE = path.join(DATA_DIR, 'notifications.json');
const DRAFT_BASE = path.join(DATA_DIR, 'drafts');
const COST_LOG_FILE = path.join(TOOLS_DIR, 'dashboard', 'server', 'cost-log.json');
const NIGHTLY_CONFIG_FILE = path.join(TOOLS_DIR, 'dashboard', 'server', 'nightly-config.json');
const GECMIS_SORULAR_PATH = path.join(DATA_DIR, 'kpss-tarih-gecmis-sorular.js');

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
    TEMPLATES_FILE,
    EXPLANATIONS_DIR,
    FLASHCARDS_DIR,
    GLOSSARY_DIR,
    MATCHING_GAMES_DIR,
    PRODUCTIVITY_DIR,
    STORIES_DIR,
    NOTIFICATIONS_FILE,
    DRAFT_BASE,
    COST_LOG_FILE,
    NIGHTLY_CONFIG_FILE,
    GECMIS_SORULAR_PATH,
    TOPICS_FILE
};
