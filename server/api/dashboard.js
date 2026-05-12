const fs = require('fs').promises;
const path = require('path');
const { QUESTIONS_DIR, HISTORY_FILE, FLASHCARDS_DIR, STORIES_DIR, MATCHING_GAMES_DIR } = require('../config');
const { sendJSON } = require('../utils/helper');
const { TOPICS } = require('../config/topics');

async function countJsonFiles(dir) {
    try {
        const files = await fs.readdir(dir);
        let total = 0;
        for (const f of files) {
            if (!f.endsWith('.json')) continue;
            try {
                const content = await fs.readFile(path.join(dir, f), 'utf8');
                const data = JSON.parse(content);
                total += Array.isArray(data) ? data.length : 1;
            } catch { }
        }
        return total;
    } catch { return 0; }
}

// ─── /stats cache ─────────────────────────────────────────────────────────
// /stats 225+ JSON dosyasını tarıyor; dashboard açıkken her N saniyede bir
// yenilenen bir ekran için 30 sn cache yeterli. Bypass: ?nocache=1
const STATS_CACHE_TTL_MS = 30 * 1000;
let _statsCache = null; // { data, ts }

async function handleDashboardRoutes(req, res, pathname, searchParams) {
    // GET /stats
    if (pathname === '/stats' && req.method === 'GET') {
        const bypass = searchParams && searchParams.get && searchParams.get('nocache') === '1';
        if (!bypass && _statsCache && (Date.now() - _statsCache.ts) < STATS_CACHE_TTL_MS) {
            return sendJSON(res, { ..._statsCache.data, _cached: true });
        }
        try {
            const files = await fs.readdir(QUESTIONS_DIR);
            const jsonFiles = files.filter(f => f.endsWith('.json'));

            let totalQuestions = 0;
            let byLesson = {};

            // Count flashcards, stories, matching games in parallel
            const [totalFlashcards, totalStories, totalGames] = await Promise.all([
                countJsonFiles(FLASHCARDS_DIR),
                countJsonFiles(STORIES_DIR),
                countJsonFiles(MATCHING_GAMES_DIR),
            ]);

            await Promise.all(jsonFiles.map(async file => {
                try {
                    const content = await fs.readFile(path.join(QUESTIONS_DIR, file), 'utf8');
                    const data = JSON.parse(content);
                    const count = Array.isArray(data) ? data.length : 0;
                    totalQuestions += count;

                    const id = path.basename(file, '.json');
                    let lessonName = 'Diğer';

                    if (TOPICS[id]) {
                        // Convert TARİH -> Tarih for nicer display
                        const l = TOPICS[id].lesson;
                        const map = {
                            'TARİH': 'Tarih', 'COĞRAFYA': 'Coğrafya', 'VATANDAŞLIK': 'Vatandaşlık',
                            'TÜRKÇE': 'Türkçe', 'MATEMATİK': 'Matematik', 'EĞİTİM BİLİMLERİ': 'Eğitim Bilimleri',
                            'ÖABT': 'ÖABT', 'GÜNCEL BİLGİLER': 'Güncel Bilgiler'
                        };
                        lessonName = map[l] || l;
                    } else {
                        // Fallback
                        if (id.startsWith('tarih')) lessonName = 'Tarih';
                        else if (id.startsWith('cog')) lessonName = 'Coğrafya';
                        else if (id.startsWith('vat')) lessonName = 'Vatandaşlık';
                        else if (id.startsWith('tur')) lessonName = 'Türkçe';
                        else if (id.startsWith('mat')) lessonName = 'Matematik';
                    }

                    if (!byLesson[lessonName]) byLesson[lessonName] = { count: 0, target: 1000 };
                    byLesson[lessonName].count += count;
                } catch { }
            }));

            let recentActivity = [];
            // İnceleme istatistikleri
            let reviewedQuestions = 0;
            try {
                const qFiles = await fs.readdir(QUESTIONS_DIR);
                await Promise.all(qFiles.filter(f => f.endsWith('.json')).map(async (file) => {
                    try {
                        const content = await fs.readFile(path.join(QUESTIONS_DIR, file), 'utf8');
                        const data = JSON.parse(content);
                        if (Array.isArray(data)) {
                            reviewedQuestions += data.filter(q => q._reviewed === true).length;
                        }
                    } catch { }
                }));
            } catch { }
            try {
                const historyContent = await fs.readFile(HISTORY_FILE, 'utf8');
                const rawHistory = JSON.parse(historyContent);

                recentActivity = rawHistory.slice(0, 10).map(h => {
                    let name = h.action;
                    let lesson = h.topicId || '';

                    if (h.action === 'add') {
                        name = 'Soru Eklendi';
                        lesson = `${h.count || 0} soru - ${h.topicId || '?'}`;
                    }
                    else if (h.action === 'auto_sync' || h.action === 'sync') {
                        name = 'Senkronizasyon';
                        lesson = `${h.changedCount || 0} dosya güncellendi`;
                    }
                    else if (h.action === 'delete') {
                        name = 'Soru Silindi';
                        lesson = h.questionId || h.topicId;
                    }
                    else if (h.action === 'edit') {
                        name = 'Soru Düzenlendi';
                        lesson = h.questionId;
                    }
                    else if (h.action === 'notification') {
                        name = 'Bildirim';
                        lesson = h.title;
                    }

                    return {
                        ...h,
                        time: h.timestamp,
                        name: name,
                        lesson: lesson
                    };
                });
            } catch { }

            const payload = {
                totalQuestions,
                reviewedQuestions,
                totalFlashcards,
                totalStories,
                totalGames,
                totalTopics: jsonFiles.length,
                activeTopics: jsonFiles.length,
                quality: 100,
                missingExplanations: 0,
                byLesson,
                recentActivity
            };
            _statsCache = { data: payload, ts: Date.now() };
            return sendJSON(res, payload);
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // GET /activities
    if (pathname === '/activities' && req.method === 'GET') {
        try {
            try {
                const content = await fs.readFile(HISTORY_FILE, 'utf8');
                return sendJSON(res, JSON.parse(content));
            } catch {
                return sendJSON(res, []);
            }
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
}

module.exports = handleDashboardRoutes;
