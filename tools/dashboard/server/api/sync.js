/**
 * Git Sync API Routes
 * GitHub senkronizasyonu ve auto-sync özellikleri
 */
const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const { exec, execSync } = require('child_process');
const { QUESTIONS_DIR, TOOLS_DIR, HISTORY_FILE } = require('../config');
const { sendJSON, parseBody } = require('../utils/helper');

// Auto-sync state
// NOT: Bu scheduler "meto-data" adında ayrı bir repo klasörünü kök repo yanında bulup
// oraya kopyala-push yapan ESKİ mimariye ait. Yeni akışta ai-content.js doğrudan kök
// repo içinden push ediyor (pushToGitHub helper). Bu yüzden default OFF.
// Kullanıcı açıkça /auto-sync/toggle ile açarsa ve meto-data klasörü varsa çalışır.
let autoSyncEnabled = false;
let lastAutoSyncTime = null;
const AUTO_SYNC_INTERVAL = 20 * 60 * 1000; // 20 dakika

// meto-data paths
const getMetoDir = () => path.join(TOOLS_DIR, '..', '..', 'meto-data');
const getMetoQuestionsDir = () => path.join(getMetoDir(), 'questions');

// History logger
async function logHistory(action, details) {
    let history = [];
    try {
        const data = await fs.readFile(HISTORY_FILE, 'utf8');
        history = JSON.parse(data);
    } catch { }

    history.unshift({
        timestamp: new Date().toISOString(),
        action,
        ...details
    });

    history = history.slice(0, 1000);
    await fs.writeFile(HISTORY_FILE, JSON.stringify(history, null, 2), 'utf8');
}

// Auto Git Sync function
async function performAutoGitSync() {
    if (!autoSyncEnabled) {
        return { success: false, reason: 'disabled' };
    }

    const metoDir = getMetoDir();
    const metoQuestionsDir = getMetoQuestionsDir();

    console.log('\n🔄 [AUTO-SYNC] Otomatik GitHub senkronizasyonu başlatılıyor...');

    try {
        if (!fsSync.existsSync(metoDir)) {
            console.log('   ⚠️  meto-data klasörü bulunamadı.');
            return { success: false, reason: 'no_meto_dir' };
        }

        if (!fsSync.existsSync(metoQuestionsDir)) {
            fsSync.mkdirSync(metoQuestionsDir, { recursive: true });
        }

        const localFiles = fsSync.readdirSync(QUESTIONS_DIR).filter(f => f.endsWith('.json'));
        let changedCount = 0;

        for (const file of localFiles) {
            try {
                const srcPath = path.join(QUESTIONS_DIR, file);
                const destPath = path.join(metoQuestionsDir, file);
                const localContent = fsSync.readFileSync(srcPath, 'utf8');
                const localQuestions = JSON.parse(localContent);

                if (!localQuestions || localQuestions.length === 0) continue;

                let needsCopy = true;
                if (fsSync.existsSync(destPath)) {
                    const remoteContent = fsSync.readFileSync(destPath, 'utf8');
                    if (localContent === remoteContent) needsCopy = false;
                }

                if (needsCopy) {
                    fsSync.writeFileSync(destPath, localContent, 'utf8');
                    changedCount++;
                }
            } catch (e) {
                console.log(`   ⚠️  ${file} kopyalanamadı:`, e.message);
            }
        }

        if (changedCount === 0) {
            console.log('   ✅ Değişiklik yok, sync atlanıyor.');
            lastAutoSyncTime = new Date();
            return { success: true, reason: 'no_changes', changedCount: 0 };
        }

        // version.json güncelle
        const versionPath = path.join(metoDir, 'version.json');
        let versionData = { questions: {}, lastUpdated: '' };
        if (fsSync.existsSync(versionPath)) {
            try { versionData = JSON.parse(fsSync.readFileSync(versionPath, 'utf8')); } catch { }
        }
        versionData.lastUpdated = new Date().toISOString().split('T')[0];
        fsSync.writeFileSync(versionPath, JSON.stringify(versionData, null, 2), 'utf8');

        // Git commit ve push
        const commitMsg = `🤖 Otomatik sync: ${changedCount} dosya güncellendi`;
        try {
            execSync('git add .', { cwd: metoDir, stdio: 'pipe' });
            execSync(`git commit -m "${commitMsg}"`, { cwd: metoDir, stdio: 'pipe' });
        } catch (e) {
            if (!e.message.includes('nothing to commit')) {
                console.log('   ⚠️  Commit hatası:', e.message);
            }
        }

        try {
            try { execSync('git pull --rebase origin main', { cwd: metoDir, stdio: 'pipe' }); } catch { }
            execSync('git push origin main', { cwd: metoDir, stdio: 'pipe' });
            console.log('   🚀 GitHub\'a başarıyla gönderildi!');
        } catch (pushError) {
            console.log('   ❌ Push hatası:', pushError.message);
            return { success: false, reason: 'push_error', error: pushError.message };
        }

        lastAutoSyncTime = new Date();
        await logHistory('auto_sync', { changedCount, timestamp: lastAutoSyncTime.toISOString() });

        return { success: true, changedCount, timestamp: lastAutoSyncTime };

    } catch (e) {
        console.log('   ❌ Otomatik sync hatası:', e.message);
        return { success: false, reason: 'error', error: e.message };
    }
}

// Start auto-sync scheduler
// meto-data klasörü yoksa scheduler'ı hiç başlatma — eski mimari artık kullanılmıyor.
// ai-content.js kendi push'unu yaptığı için bu katmana ihtiyaç kalmadı.
function startAutoSyncScheduler() {
    const metoDir = getMetoDir();
    if (!fsSync.existsSync(metoDir)) {
        console.log('ℹ️  Auto-sync scheduler atlandı (meto-data klasörü yok, yeni akışta gerek yok).');
        return;
    }

    if (!autoSyncEnabled) {
        console.log('ℹ️  Auto-sync default OFF. Açmak için POST /auto-sync/toggle.');
        return;
    }

    console.log(`⏰ Otomatik GitHub Sync aktif: Her ${AUTO_SYNC_INTERVAL / 60000} dakikada bir`);

    setTimeout(async () => {
        console.log('🔄 İlk otomatik sync başlatılıyor...');
        await performAutoGitSync();
    }, 60 * 1000);

    setInterval(async () => {
        await performAutoGitSync();
    }, AUTO_SYNC_INTERVAL);
}

async function handleSyncRoutes(req, res, pathname) {
    // GET /auto-sync/status
    if (pathname === '/auto-sync/status' && req.method === 'GET') {
        return sendJSON(res, {
            enabled: autoSyncEnabled,
            interval: AUTO_SYNC_INTERVAL / 60000 + ' dakika',
            lastSync: lastAutoSyncTime ? lastAutoSyncTime.toLocaleString('tr-TR') : 'Henüz yapılmadı',
            nextSync: lastAutoSyncTime
                ? new Date(lastAutoSyncTime.getTime() + AUTO_SYNC_INTERVAL).toLocaleString('tr-TR')
                : 'Bilinmiyor'
        });
    }

    // POST /auto-sync/toggle
    if (pathname === '/auto-sync/toggle' && req.method === 'POST') {
        autoSyncEnabled = !autoSyncEnabled;
        return sendJSON(res, {
            success: true,
            enabled: autoSyncEnabled,
            message: autoSyncEnabled ? 'Otomatik sync aktifleştirildi' : 'Otomatik sync devre dışı bırakıldı'
        });
    }

    // POST /auto-sync/now
    if (pathname === '/auto-sync/now' && req.method === 'POST') {
        const result = await performAutoGitSync();
        return sendJSON(res, result);
    }

    // POST /publish-to-github
    if (pathname === '/publish-to-github' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const module = body.module || 'questions'; // 'questions', 'flashcards', 'stories', 'explanations', 'matching-games'
            
            const metoDir = getMetoDir();
            const metoQuestionsDir = getMetoQuestionsDir();

            if (!fsSync.existsSync(metoDir)) {
                return sendJSON(res, { error: 'meto-data klasörü bulunamadı' }, 404);
            }

            if (!fsSync.existsSync(metoQuestionsDir)) {
                fsSync.mkdirSync(metoQuestionsDir, { recursive: true });
            }

            let sourceDir, targetDir, filePrefix, commitMessage;
            
            switch (module) {
                case 'flashcards':
                    sourceDir = path.join(TOOLS_DIR, '..', 'flashcards');
                    targetDir = path.join(metoDir, 'flashcards');
                    filePrefix = 'Flashcard';
                    commitMessage = 'Flashcards güncellendi';
                    break;
                case 'stories':
                    sourceDir = path.join(TOOLS_DIR, '..', 'stories');
                    targetDir = path.join(metoDir, 'stories');
                    filePrefix = 'Story';
                    commitMessage = 'Stories güncellendi';
                    break;
                case 'explanations':
                    sourceDir = path.join(TOOLS_DIR, '..', 'explanations');
                    targetDir = path.join(metoDir, 'explanations');
                    filePrefix = 'Explanation';
                    commitMessage = 'Explanations güncellendi';
                    break;
                case 'matching-games':
                    sourceDir = path.join(TOOLS_DIR, '..', 'matching_games');
                    targetDir = path.join(metoDir, 'matching_games');
                    filePrefix = 'Matching Game';
                    commitMessage = 'Matching games güncellendi';
                    break;
                default: // questions
                    sourceDir = QUESTIONS_DIR;
                    targetDir = metoQuestionsDir;
                    filePrefix = 'Soru';
                    commitMessage = 'Sorular güncellendi';
            }

            // Ensure target directory exists
            if (!fsSync.existsSync(targetDir)) {
                fsSync.mkdirSync(targetDir, { recursive: true });
            }

            if (!fsSync.existsSync(sourceDir)) {
                return sendJSON(res, { error: `${module} klasörü bulunamadı` }, 404);
            }

            const localFiles = fsSync.readdirSync(sourceDir).filter(f => f.endsWith('.json'));
            let copiedCount = 0;
            const updatedFiles = [];

            for (const file of localFiles) {
                const srcPath = path.join(sourceDir, file);
                const destPath = path.join(targetDir, file);
                const content = fsSync.readFileSync(srcPath, 'utf8');
                
                // Validate JSON
                try {
                    const data = JSON.parse(content);
                    if (Array.isArray(data) ? data.length > 0 : Object.keys(data).length > 0) {
                        fsSync.writeFileSync(destPath, content, 'utf8');
                        copiedCount++;
                        updatedFiles.push(file.replace('.json', ''));
                    }
                } catch (e) {
                    console.error(`Invalid JSON in ${file}:`, e.message);
                }
            }

            // Update version.json for ALL modules
            const versionPath = path.join(metoDir, 'version.json');
            let versionData = { questions: {}, flashcards: {}, stories: {}, explanations: {}, matching_games: {}, lastUpdated: '' };
            if (fsSync.existsSync(versionPath)) {
                try { versionData = JSON.parse(fsSync.readFileSync(versionPath, 'utf8')); } catch { }
            }

            // Map module name → version.json key
            const moduleVersionKey = {
                questions: 'questions',
                flashcards: 'flashcards',
                stories: 'stories',
                explanations: 'explanations',
                'matching-games': 'matching_games',
            }[module] || module;

            if (!versionData[moduleVersionKey]) versionData[moduleVersionKey] = {};

            for (const fileId of updatedFiles) {
                const current = versionData[moduleVersionKey][fileId] || 0;
                versionData[moduleVersionKey][fileId] = current + 1;
            }

            versionData.lastUpdated = new Date().toISOString().split('T')[0];
            versionData.last_updated = versionData.lastUpdated;
            fsSync.writeFileSync(versionPath, JSON.stringify(versionData, null, 2), 'utf8');

            // Git commit and push
            const gitCommand = `cd "${metoDir}" && git add . && git commit -m "${commitMessage}: ${updatedFiles.length} dosya" && git push`;
            exec(gitCommand, (error) => {
                if (error) console.log('Git push error:', error.message);
            });

            const response = {
                success: true,
                message: `${copiedCount} ${module} dosyası GitHub'a aktarıldı`,
                module,
                updatedFiles,
                copiedCount
            };

            if (module === 'questions') {
                response.versionData = versionData.questions;
            }

            return sendJSON(res, response);

        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // GET /git/status
    if (pathname === '/git/status' && req.method === 'GET') {
        const metoDir = getMetoDir();

        if (!fsSync.existsSync(metoDir)) {
            return sendJSON(res, { configured: false, error: 'meto-data klasörü bulunamadı' });
        }

        try {
            const statusOutput = execSync('git status --porcelain', { cwd: metoDir, encoding: 'utf8' });
            const files = statusOutput.trim().split('\n').filter(l => l.trim());

            return sendJSON(res, {
                configured: true,
                hasChanges: files.length > 0,
                changedFiles: files.map(line => ({
                    status: line.substring(0, 2).trim(),
                    file: line.substring(3)
                }))
            });
        } catch (e) {
            return sendJSON(res, { configured: false, error: e.message });
        }
    }

    // POST /git/push
    if (pathname === '/git/push' && req.method === 'POST') {
        const metoDir = getMetoDir();

        if (!fsSync.existsSync(metoDir)) {
            return sendJSON(res, { success: false, error: 'meto-data klasörü bulunamadı' });
        }

        try {
            try { execSync('git pull --rebase origin main', { cwd: metoDir, stdio: 'pipe' }); } catch { }
            execSync('git push origin main', { cwd: metoDir, stdio: 'pipe' });
            return sendJSON(res, { success: true, message: 'GitHub\'a başarıyla gönderildi!' });
        } catch (pushError) {
            return sendJSON(res, { success: false, error: pushError.message });
        }
    }

    // GET /git/log
    if (pathname === '/git/log' && req.method === 'GET') {
        const metoDir = getMetoDir();
        if (!fsSync.existsSync(metoDir)) {
            return sendJSON(res, { success: false, error: 'meto-data klasörü bulunamadı' });
        }
        try {
            const logOutput = execSync('git log --format="%h|||%ar|||%s" -25', { cwd: metoDir, encoding: 'utf8' });
            const commits = logOutput.trim().split('\n').filter(Boolean).map(line => {
                const [hash, time, ...msg] = line.split('|||');
                return { hash, time, message: msg.join('|||') };
            });
            return sendJSON(res, { success: true, commits });
        } catch (e) {
            return sendJSON(res, { success: false, error: e.message });
        }
    }

    return false;
}

module.exports = { handleSyncRoutes, startAutoSyncScheduler };
