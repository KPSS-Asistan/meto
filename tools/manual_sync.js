const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const SOURCE = path.join(__dirname, '../questions');
const META_DIR = path.join(__dirname, '../../meto-data');
const META_QUESTIONS = path.join(META_DIR, 'questions');
const VERSION_FILE = path.join(META_DIR, 'version.json');
const WRONG_TOOLS_QUESTIONS = path.join(__dirname, 'questions');

console.log('Syncing from:', SOURCE);
console.log('To:', META_QUESTIONS);

// 1. Yanlis klasoru temizle
if (fs.existsSync(WRONG_TOOLS_QUESTIONS)) {
    console.log('Cleaning up tools/questions...');
    try { fs.rmSync(WRONG_TOOLS_QUESTIONS, { recursive: true, force: true }); } catch (e) { console.log('Cleanup error', e.message); }
}

// 2. Kopyalama
if (!fs.existsSync(META_QUESTIONS)) fs.mkdirSync(META_QUESTIONS, { recursive: true });

const files = fs.readdirSync(SOURCE).filter(f => f.endsWith('.json'));

let versionData = { questions: {} };
if (fs.existsSync(VERSION_FILE)) {
    try { versionData = JSON.parse(fs.readFileSync(VERSION_FILE, 'utf8')); } catch (e) { }
}
if (!versionData.questions) versionData.questions = {};

let count = 0;
files.forEach(f => {
    const src = path.join(SOURCE, f);
    const dst = path.join(META_QUESTIONS, f);
    fs.copyFileSync(src, dst);

    const id = f.replace('.json', '');
    versionData.questions[id] = (versionData.questions[id] || 0) + 1;
    count++;
});

versionData.lastUpdated = new Date().toISOString().split('T')[0];
fs.writeFileSync(VERSION_FILE, JSON.stringify(versionData, null, 2));

console.log(count + ' dosya kopyalandi.');

// 3. Git Push
try {
    console.log('Pushing to GitHub...');
    execSync('git add . && git commit -m "Bulk update from Dashboard" && git push', { cwd: META_DIR, stdio: 'inherit' });
    console.log('GitHub Push SUCCESS!');
} catch (e) {
    console.log('Git ops complete (might be no changes).');
}
