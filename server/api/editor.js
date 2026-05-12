/**
 * Editor Panel API
 * GET  /editor/topics                           — Topic listesi + inceleme istatistikleri
 * GET  /editor/stats                            — Genel inceleme istatistikleri
 * GET  /editor/next-question?skip=...&topicId=  — İşaretlenmemiş sonraki soru
 * POST /editor/mark                             — Soruyu işaretle (+ opsiyonel düzenle)
 * POST /editor/unmark                           — Son işareti geri al
 * POST /editor/reset-reviewed                   — Toplu işaret sıfırla (admin only)
 * GET  /editor/search?q=metin                   — İşaretlenen sorularda metin arama
 */
const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const { QUESTIONS_DIR, DATA_DIR } = require('../config');
const { sendJSON, parseBody } = require('../utils/helper');
const { loadQuestions, saveQuestions } = require('../services/questionService');

/** version.json güncelle */
function bumpVersion(topicId) {
    const versionPath = path.join(DATA_DIR, 'version.json');
    try {
        let v = {};
        try { v = JSON.parse(fsSync.readFileSync(versionPath, 'utf8')); } catch { v = {}; }
        if (!v.questions) v.questions = {};
        v.questions[topicId] = (v.questions[topicId] || 0) + 1;
        const today = new Date().toISOString().split('T')[0];
        v.lastUpdated = today;
        v.last_updated = today;
        fsSync.writeFileSync(versionPath, JSON.stringify(v, null, 2), 'utf8');
    } catch (e) {
        console.error('version.json bump hatası:', e.message);
    }
}

/** Topics.json'dan id→name map */
function loadTopicsMap() {
    try {
        const raw = fsSync.readFileSync(path.join(DATA_DIR, 'topics.json'), 'utf8');
        const arr = JSON.parse(raw);
        const map = {};
        for (const t of arr) map[t.id] = t.name || t.id;
        return map;
    } catch {
        return {};
    }
}

/** Tüm topic JSON dosya isimlerini sıralı döndür */
async function getTopicFiles() {
    try {
        const files = await fs.readdir(QUESTIONS_DIR);
        return files.filter(f => f.endsWith('.json')).sort();
    } catch {
        return [];
    }
}

module.exports = async function handleEditorRoutes(req, res, pathname, searchParams) {

    // ─── GET /editor/topics ──────────────────────────────────────────────────
    if (pathname === '/editor/topics' && req.method === 'GET') {
        try {
            const files = await getTopicFiles();
            const topicsMap = loadTopicsMap();
            const result = await Promise.all(files.map(async (file) => {
                const topicId = path.basename(file, '.json');
                const questions = await loadQuestions(topicId);
                const reviewedCount = questions.filter(q => q._reviewed === true).length;
                return {
                    id: topicId,
                    name: topicsMap[topicId] || topicId,
                    total: questions.length,
                    reviewed: reviewedCount,
                    remaining: questions.length - reviewedCount
                };
            }));
            return sendJSON(res, result);
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ─── GET /editor/stats ───────────────────────────────────────────────────
    if (pathname === '/editor/stats' && req.method === 'GET') {
        try {
            const files = await getTopicFiles();
            let total = 0, reviewed = 0;
            await Promise.all(files.map(async (file) => {
                const topicId = path.basename(file, '.json');
                const questions = await loadQuestions(topicId);
                total += questions.length;
                reviewed += questions.filter(q => q._reviewed === true).length;
            }));
            return sendJSON(res, { total, reviewed, remaining: total - reviewed });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ─── GET /editor/next-question ───────────────────────────────────────────
    if (pathname === '/editor/next-question' && req.method === 'GET') {
        try {
            const skipParam = searchParams.get('skip') || '';
            const filterTopicId = searchParams.get('topicId') || '';
            const skipSet = new Set(
                skipParam ? skipParam.split(',').map(s => s.trim()).filter(Boolean) : []
            );
            const topicsMap = loadTopicsMap();

            const files = await getTopicFiles();
            let foundQuestion = null;
            let foundTopicId = null;
            let total = 0;
            let reviewed = 0;

            for (const file of files) {
                const topicId = path.basename(file, '.json');
                if (filterTopicId && topicId !== filterTopicId) continue;
                const questions = await loadQuestions(topicId);

                total += questions.length;
                reviewed += questions.filter(q => q._reviewed === true).length;

                if (!foundQuestion) {
                    const candidate = questions.find(
                        q => q._reviewed !== true && !skipSet.has(String(q.id))
                    );
                    if (candidate) {
                        foundQuestion = candidate;
                        foundTopicId = topicId;
                    }
                }
            }

            const remaining = total - reviewed;

            if (!foundQuestion) {
                return sendJSON(res, { done: true, stats: { total, reviewed, remaining: 0 } });
            }

            return sendJSON(res, {
                question: foundQuestion,
                topicId: foundTopicId,
                topicName: topicsMap[foundTopicId] || foundTopicId,
                stats: { total, reviewed, remaining }
            });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ─── POST /editor/mark ───────────────────────────────────────────────────
    if (pathname === '/editor/mark' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { questionId, topicId, edits } = body;

            if (!questionId || !topicId) {
                return sendJSON(res, { error: 'questionId ve topicId zorunlu' }, 400);
            }

            if (edits) {
                if (edits.o !== undefined) {
                    if (!Array.isArray(edits.o) || edits.o.length !== 5) {
                        return sendJSON(res, { error: 'edits.o 5 elemanlı array olmalı' }, 400);
                    }
                }
                if (edits.a !== undefined) {
                    const aNum = Number(edits.a);
                    if (!Number.isInteger(aNum) || aNum < 0 || aNum > 4) {
                        return sendJSON(res, { error: 'edits.a 0-4 arasında tam sayı olmalı' }, 400);
                    }
                }
            }

            const questions = await loadQuestions(topicId);
            const idx = questions.findIndex(q => String(q.id) === String(questionId));

            if (idx === -1) {
                return sendJSON(res, { error: 'Soru bulunamadı' }, 404);
            }

            questions[idx]._reviewed = true;
            questions[idx]._reviewedAt = new Date().toISOString();

            let hasEdits = false;
            if (edits) {
                if (edits.q !== undefined) { questions[idx].q = edits.q; hasEdits = true; }
                if (edits.o !== undefined) { questions[idx].o = edits.o; hasEdits = true; }
                if (edits.a !== undefined) { questions[idx].a = Number(edits.a); hasEdits = true; }
                if (edits.e !== undefined) { questions[idx].e = edits.e; hasEdits = true; }
            }

            await saveQuestions(topicId, questions);
            if (hasEdits) bumpVersion(topicId);

            return sendJSON(res, { success: true, questionId, reviewed: true });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ─── POST /editor/unmark ─────────────────────────────────────────────────
    if (pathname === '/editor/unmark' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { questionId, topicId } = body;

            if (!questionId || !topicId) {
                return sendJSON(res, { error: 'questionId ve topicId zorunlu' }, 400);
            }

            const questions = await loadQuestions(topicId);
            const idx = questions.findIndex(q => String(q.id) === String(questionId));

            if (idx === -1) {
                return sendJSON(res, { error: 'Soru bulunamadı' }, 404);
            }

            delete questions[idx]._reviewed;
            delete questions[idx]._reviewedAt;
            await saveQuestions(topicId, questions);

            return sendJSON(res, { success: true, questionId, reviewed: false });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ─── POST /editor/reset-reviewed  (admin only) ───────────────────────────
    if (pathname === '/editor/reset-reviewed' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { topicId, questionIds } = body;
            // questionIds varsa sadece onları sıfırla, yoksa topicId'nin tamamını sıfırla

            const filesToProcess = topicId
                ? [topicId + '.json']
                : await getTopicFiles();

            let resetCount = 0;

            for (const fileOrId of filesToProcess) {
                const tId = path.basename(fileOrId, '.json');
                const questions = await loadQuestions(tId);
                let changed = false;

                for (const q of questions) {
                    const shouldReset = !questionIds || questionIds.includes(String(q.id));
                    if (shouldReset && q._reviewed === true) {
                        delete q._reviewed;
                        delete q._reviewedAt;
                        resetCount++;
                        changed = true;
                    }
                }

                if (changed) await saveQuestions(tId, questions);
            }

            return sendJSON(res, { success: true, resetCount });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ─── GET /editor/search ──────────────────────────────────────────────────
    if (pathname === '/editor/search' && req.method === 'GET') {
        try {
            const q = (searchParams.get('q') || '').trim();
            if (q.length < 2) {
                return sendJSON(res, { error: 'En az 2 karakter gerekli' }, 400);
            }

            const topicsMap = loadTopicsMap();
            const searchTerm = q.toLowerCase();
            const files = await getTopicFiles();
            const results = [];

            await Promise.all(files.map(async (file) => {
                const topicId = path.basename(file, '.json');
                const questions = await loadQuestions(topicId);
                for (const question of questions) {
                    if (question._reviewed === true && (question.q || '').toLowerCase().includes(searchTerm)) {
                        results.push({
                            id: question.id,
                            topicId,
                            topicName: topicsMap[topicId] || topicId,
                            q: question.q,
                            o: question.o,
                            a: question.a,
                            e: question.e
                        });
                    }
                }
            }));

            const limited = results.slice(0, 100);
            return sendJSON(res, { results: limited, total: limited.length });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
};
