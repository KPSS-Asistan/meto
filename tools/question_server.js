/**
 * ===========================================================================
 * KPSS QUESTION MANAGEMENT SYSTEM v6.0 - ULTIMATE EDITION
 * ===========================================================================
 * 
 * YENÝ ÖZELLÝKLER:
 * ? Toplu Açýklama Ekleme
 * ? Soru Taþýma/Kopyalama
 * ? Toplu Düzenleme
 * ? Zorluk Tahmini
 * ? Detaylý PDF Rapor
 * ? Trend Grafiði
 * ? Eksik Ýçerik Listesi
 * ? Soru Þablonlarý
 * ? Otomatik Yedekleme
 * ? Flutter Sync Status
 * ? API Dökümantasyonu
 */

const http = require('http');
const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { TOPICS, LESSON_TARGETS } = require('./topics');

// ===========================================================================
// GEMINI AI ENTEGRASYonu
// ===========================================================================
let GoogleGenerativeAI;
try {
    GoogleGenerativeAI = require('@google/generative-ai').GoogleGenerativeAI;
} catch (e) {
    console.log('?? @google/generative-ai paketi yüklü deðil. npm install @google/generative-ai');
}

// API Key - Environment variable veya hardcoded (geliþtirme için)
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || 'AIzaSyAp0eyAWPw7o1Mn9d8ZoA_hNcwiur0TIY8';

// ===========================================================================
// AYARLAR
// ===========================================================================
const PORT = 3456;
const QUESTIONS_DIR = path.join(__dirname, '..', 'assets', 'data', 'questions');
const BACKUP_DIR = path.join(__dirname, 'backups');
const PUBLIC_DIR = path.join(__dirname, 'public');
const TEMPLATES_FILE = path.join(__dirname, 'templates.json');
const HISTORY_FILE = path.join(__dirname, 'history.json');

// Klasörleri oluþtur
[BACKUP_DIR].forEach(dir => {
    if (!fsSync.existsSync(dir)) fsSync.mkdirSync(dir, { recursive: true });
});

const MIME_TYPES = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.ico': 'image/x-icon'
};

// ===========================================================================
// TÜM KONULAR


// ===========================================================================
// YARDIMCI FONKSÝYONLAR
// ===========================================================================

const sendJSON = (res, data, status = 200) => {
    res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(data));
};

const parseBody = (req) => new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
        try { resolve(body ? JSON.parse(body) : {}); }
        catch (e) { reject(new Error('JSON parse hatasý')); }
    });
});

// GitHub repo URL
const GITHUB_RAW_URL = 'https://raw.githubusercontent.com/mertcanasdf/meto/main/questions';

const loadQuestions = async (topicId) => {
    // Önce lokal dosyayý oku
    let localData = [];
    try {
        const localContent = await fs.readFile(path.join(QUESTIONS_DIR, `${topicId}.json`), 'utf8');
        localData = JSON.parse(localContent);
    } catch { }

    // GitHub'dan çekmeyi dene
    try {
        const response = await fetch(`${GITHUB_RAW_URL}/${topicId}.json`);
        if (response.ok) {
            const githubData = await response.json();

            // GitHub boþ ama lokal doluysa, lokal'i kullan
            if ((!githubData || githubData.length === 0) && localData.length > 0) {
                console.log(`GitHub boþ, lokal veri kullanýlýyor (${topicId}): ${localData.length} soru`);
                return localData;
            }

            // GitHub doluysa, lokal'e cache'le ve döndür
            if (githubData && githubData.length > 0) {
            if (localData && localData.length > githubData.length) { console.log(' KORUMA: Lokal veri daha kapsamlý, GitHub ezilmedi.'); return localData; }
                await fs.writeFile(path.join(QUESTIONS_DIR, `${topicId}.json`), JSON.stringify(githubData, null, 4), 'utf8').catch(() => { });
                return githubData;
            }
        }
    } catch (e) {
        console.log(`GitHub'dan çekilemedi (${topicId}), lokal dosya kullanýlýyor...`);
    }

    // GitHub baþarýsýz veya boþsa lokal'i döndür
    return localData;
};

const saveQuestions = async (topicId, questions) => {
    await fs.writeFile(
        path.join(QUESTIONS_DIR, `${topicId}.json`),
        JSON.stringify(questions, null, 4),
        'utf8'
    );
};

const createBackup = async (topicId, questions) => {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupPath = path.join(BACKUP_DIR, `${topicId}_${timestamp}.json`);
    await fs.writeFile(backupPath, JSON.stringify(questions, null, 2), 'utf8');
    return backupPath;
};

// History kaydet
const logHistory = async (action, details) => {
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

    // Son 1000 kaydý tut
    history = history.slice(0, 1000);
    await fs.writeFile(HISTORY_FILE, JSON.stringify(history, null, 2), 'utf8');
};

// ===========================================================================
// KALÝTE & ZORLUK SKORU
// ===========================================================================

function calculateQualityScore(q) {
    let score = 0;
    const details = [];

    const qLen = (q.q || '').length;
    if (qLen >= 100) { score += 20; details.push('? Detaylý soru'); }
    else if (qLen >= 50) { score += 15; }
    else if (qLen >= 20) { score += 10; }

    if (q.e && q.e.length >= 50) { score += 25; details.push('? Detaylý açýklama'); }
    else if (q.e && q.e.length >= 20) { score += 15; }

    if (q.o && q.o.length === 5) {
        const lengths = q.o.map(o => (o || '').length);
        const avg = lengths.reduce((a, b) => a + b, 0) / 5;
        const variance = lengths.reduce((sum, l) => sum + Math.pow(l - avg, 2), 0) / 5;
        if (variance < 100) { score += 20; }
        else if (variance < 500) { score += 10; }
    }

    if (/[.?!:]$/.test((q.q || '').trim())) { score += 10; }

    const negatives = ['deðildir', 'yoktur', 'olamaz', 'olmaz'];
    const hasNegative = negatives.some(n => (q.q || '').toLowerCase().includes(n));
    const hasEmphasis = negatives.some(n => (q.q || '').includes(n.toUpperCase()));
    if (!hasNegative || hasEmphasis) { score += 10; }

    if (q.o && q.o.every(o => o && o.trim().length >= 2)) { score += 15; }

    return { score, maxScore: 100, percentage: score, details };
}

function calculateDifficultyScore(q) {
    let difficulty = 50; // Orta baþlangýç
    const factors = [];

    const qLen = (q.q || '').length;
    if (qLen > 200) { difficulty += 15; factors.push('Uzun soru metni'); }
    else if (qLen > 100) { difficulty += 5; }
    else if (qLen < 50) { difficulty -= 10; factors.push('Kýsa soru'); }

    // Öncüllü soru kontrolü
    if (/\b(I|II|III|IV|V)\./g.test(q.q || '')) {
        difficulty += 10;
        factors.push('Öncüllü soru');
    }

    // Olumsuz kök
    const negatives = ['deðildir', 'yoktur', 'olamaz', 'yanlýþ'];
    if (negatives.some(n => (q.q || '').toLowerCase().includes(n))) {
        difficulty += 5;
        factors.push('Olumsuz kök');
    }

    // Þýk uzunluklarý
    if (q.o) {
        const avgOptLen = q.o.reduce((s, o) => s + (o || '').length, 0) / 5;
        if (avgOptLen > 50) { difficulty += 10; factors.push('Uzun þýklar'); }
        else if (avgOptLen < 10) { difficulty -= 5; }
    }

    // "Hangisi/hangileri" kontrolü
    if (/hangile?ri?/i.test(q.q || '')) {
        difficulty += 5;
    }

    difficulty = Math.max(10, Math.min(100, difficulty));

    let level = 'Orta';
    if (difficulty >= 70) level = 'Zor';
    else if (difficulty <= 40) level = 'Kolay';

    return { score: difficulty, level, factors };
}

// ===========================================================================
// ÝSTATÝSTÝKLER & ANALÝZ
// ===========================================================================

async function calculateStats() {
    const stats = {
        totalQuestions: 0,
        totalTopics: Object.keys(TOPICS).length,
        byLesson: {},
        byTopic: [],
        qualityDistribution: { excellent: 0, good: 0, average: 0, poor: 0 },
        difficultyDistribution: { easy: 0, medium: 0, hard: 0 },
        missingExplanations: 0,
        avgQualityScore: 0
    };

    let totalQuality = 0;

    for (const [topicId, topicInfo] of Object.entries(TOPICS)) {
        const questions = await loadQuestions(topicId);
        const count = questions.length;
        stats.totalQuestions += count;

        if (!stats.byLesson[topicInfo.lesson]) {
            stats.byLesson[topicInfo.lesson] = {
                count: 0,
                topics: 0,
                target: LESSON_TARGETS[topicInfo.lesson]?.target || 100,
                weight: LESSON_TARGETS[topicInfo.lesson]?.weight || 0.1
            };
        }
        stats.byLesson[topicInfo.lesson].count += count;
        stats.byLesson[topicInfo.lesson].topics++;

        let topicQuality = 0;
        let noExplanation = 0;
        let easyCount = 0, mediumCount = 0, hardCount = 0;

        questions.forEach(q => {
            const qs = calculateQualityScore(q);
            const ds = calculateDifficultyScore(q);
            topicQuality += qs.score;

            if (!q.e || q.e.length < 10) noExplanation++;

            if (qs.score >= 80) stats.qualityDistribution.excellent++;
            else if (qs.score >= 60) stats.qualityDistribution.good++;
            else if (qs.score >= 40) stats.qualityDistribution.average++;
            else stats.qualityDistribution.poor++;

            if (ds.level === 'Kolay') { easyCount++; stats.difficultyDistribution.easy++; }
            else if (ds.level === 'Zor') { hardCount++; stats.difficultyDistribution.hard++; }
            else { mediumCount++; stats.difficultyDistribution.medium++; }
        });

        stats.missingExplanations += noExplanation;
        totalQuality += topicQuality;

        stats.byTopic.push({
            id: topicId,
            name: topicInfo.name,
            lesson: topicInfo.lesson,
            count,
            avgQuality: count > 0 ? Math.round(topicQuality / count) : 0,
            missingExplanations: noExplanation,
            difficulty: { easy: easyCount, medium: mediumCount, hard: hardCount }
        });
    }

    stats.avgQualityScore = stats.totalQuestions > 0
        ? Math.round(totalQuality / stats.totalQuestions)
        : 0;

    stats.byTopic.sort((a, b) => b.count - a.count);

    return stats;
}

// Eksik içerik analizi
async function analyzeGaps() {
    const gaps = [];

    for (const [lesson, target] of Object.entries(LESSON_TARGETS)) {
        const lessonTopics = Object.entries(TOPICS).filter(([_, t]) => t.lesson === lesson);
        let totalQuestions = 0;
        const topicGaps = [];

        for (const [topicId, topicInfo] of lessonTopics) {
            const questions = await loadQuestions(topicId);
            totalQuestions += questions.length;

            const topicTarget = Math.ceil(target.target / lessonTopics.length);
            const gap = topicTarget - questions.length;

            if (gap > 0) {
                topicGaps.push({
                    topicId,
                    name: topicInfo.name,
                    current: questions.length,
                    target: topicTarget,
                    gap,
                    priority: gap > topicTarget * 0.5 ? 'high' : gap > topicTarget * 0.25 ? 'medium' : 'low'
                });
            }
        }

        gaps.push({
            lesson,
            current: totalQuestions,
            target: target.target,
            gap: Math.max(0, target.target - totalQuestions),
            percentage: Math.round((totalQuestions / target.target) * 100),
            topics: topicGaps.sort((a, b) => b.gap - a.gap)
        });
    }

    return gaps.sort((a, b) => b.gap - a.gap);
}

// Trend analizi
async function getTrends() {
    let history = [];
    try {
        const data = await fs.readFile(HISTORY_FILE, 'utf8');
        history = JSON.parse(data);
    } catch { }

    // Son 30 günlük veri
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const recentHistory = history.filter(h => new Date(h.timestamp) > thirtyDaysAgo);

    // Günlük ekleme sayýlarý
    const dailyAdds = {};
    recentHistory.filter(h => h.action === 'add').forEach(h => {
        const day = h.timestamp.split('T')[0];
        dailyAdds[day] = (dailyAdds[day] || 0) + (h.count || 1);
    });

    return {
        totalActions: recentHistory.length,
        addedLast30Days: recentHistory.filter(h => h.action === 'add').reduce((s, h) => s + (h.count || 1), 0),
        editedLast30Days: recentHistory.filter(h => h.action === 'edit').length,
        deletedLast30Days: recentHistory.filter(h => h.action === 'delete').length,
        dailyAdds,
        recentActivity: recentHistory.slice(0, 20)
    };
}

// ===========================================================================
// ÞABLONLAR
// ===========================================================================

async function loadTemplates() {
    try {
        const data = await fs.readFile(TEMPLATES_FILE, 'utf8');
        return JSON.parse(data);
    } catch {
        // Varsayýlan þablonlar
        return [
            {
                id: 'standard',
                name: 'Standart Soru',
                template: { q: '', o: ['', '', '', '', ''], a: 0, e: '' }
            },
            {
                id: 'oncul',
                name: 'Öncüllü Soru (I, II, III)',
                template: {
                    q: 'I. Birinci madde\nII. Ýkinci madde\nIII. Üçüncü madde\n\nYukarýdakilerden hangileri doðrudur?',
                    o: ['Yalnýz I', 'Yalnýz II', 'I ve II', 'II ve III', 'I, II ve III'],
                    a: 4,
                    e: ''
                }
            },
            {
                id: 'dogruyanlýþ',
                name: 'Doðru/Yanlýþ Analizi',
                template: {
                    q: 'Aþaðýdaki ifadelerden hangisi yanlýþtýr?',
                    o: ['', '', '', '', ''],
                    a: 0,
                    e: ''
                }
            },
            {
                id: 'paragraf',
                name: 'Paragraf Sorusu',
                template: {
                    q: '[PARAGRAF]\n\nYukarýdaki paragrafta anlatýlmak istenen nedir?',
                    o: ['', '', '', '', ''],
                    a: 0,
                    e: ''
                }
            }
        ];
    }
}

async function saveTemplates(templates) {
    await fs.writeFile(TEMPLATES_FILE, JSON.stringify(templates, null, 2), 'utf8');
}

// ===========================================================================
// TOPLU ÝÞLEMLER
// ===========================================================================

// Toplu açýklama ekleme
async function bulkAddExplanations(topicId, explanations) {
    const questions = await loadQuestions(topicId);
    await createBackup(topicId, questions);

    let updated = 0;
    explanations.forEach(({ id, explanation }) => {
        const q = questions.find(q => q.id === id);
        if (q && explanation) {
            q.e = explanation;
            updated++;
        }
    });

    await saveQuestions(topicId, questions);
    await logHistory('bulk_explanation', { topicId, count: updated });

    return { updated, total: questions.length };
}

// Soru taþýma
async function moveQuestion(fromTopicId, toTopicId, questionId) {
    const fromQuestions = await loadQuestions(fromTopicId);
    const toQuestions = await loadQuestions(toTopicId);

    const idx = fromQuestions.findIndex(q => q.id === questionId);
    if (idx === -1) throw new Error('Soru bulunamadý');

    await createBackup(fromTopicId, fromQuestions);
    await createBackup(toTopicId, toQuestions);

    const question = fromQuestions.splice(idx, 1)[0];

    // Yeni ID oluþtur
    const toTopic = TOPICS[toTopicId];
    let maxNum = 0;
    toQuestions.forEach(q => {
        if (q.id?.startsWith(toTopic.prefix + '_')) {
            const num = parseInt(q.id.split('_').pop());
            if (!isNaN(num)) maxNum = Math.max(maxNum, num);
        }
    });

    question.id = `${toTopic.prefix}_${String(maxNum + 1).padStart(3, '0')}`;
    question.topicId = toTopicId;

    toQuestions.push(question);

    await saveQuestions(fromTopicId, fromQuestions);
    await saveQuestions(toTopicId, toQuestions);
    await logHistory('move', { fromTopicId, toTopicId, questionId, newId: question.id });

    return { success: true, newId: question.id };
}

// Soru kopyalama
async function copyQuestion(fromTopicId, toTopicId, questionId) {
    const fromQuestions = await loadQuestions(fromTopicId);
    const toQuestions = await loadQuestions(toTopicId);

    const original = fromQuestions.find(q => q.id === questionId);
    if (!original) throw new Error('Soru bulunamadý');

    await createBackup(toTopicId, toQuestions);

    const toTopic = TOPICS[toTopicId];
    let maxNum = 0;
    toQuestions.forEach(q => {
        if (q.id?.startsWith(toTopic.prefix + '_')) {
            const num = parseInt(q.id.split('_').pop());
            if (!isNaN(num)) maxNum = Math.max(maxNum, num);
        }
    });

    const copy = {
        ...original,
        id: `${toTopic.prefix}_${String(maxNum + 1).padStart(3, '0')}`,
        topicId: toTopicId
    };

    toQuestions.push(copy);
    await saveQuestions(toTopicId, toQuestions);
    await logHistory('copy', { fromTopicId, toTopicId, questionId, newId: copy.id });

    return { success: true, newId: copy.id };
}

// Toplu silme
async function bulkDelete(topicId, questionIds) {
    const questions = await loadQuestions(topicId);
    await createBackup(topicId, questions);

    const remaining = questions.filter(q => !questionIds.includes(q.id));
    const deleted = questions.length - remaining.length;

    await saveQuestions(topicId, remaining);
    await logHistory('bulk_delete', { topicId, count: deleted });

    return { deleted, remaining: remaining.length };
}

// ===========================================================================
// VALÝDASYON
// ===========================================================================

function levenshtein(a, b) {
    if (!a.length) return b.length;
    if (!b.length) return a.length;
    const matrix = [];
    for (let i = 0; i <= b.length; i++) matrix[i] = [i];
    for (let j = 0; j <= a.length; j++) matrix[0][j] = j;
    for (let i = 1; i <= b.length; i++) {
        for (let j = 1; j <= a.length; j++) {
            if (b.charAt(i - 1) === a.charAt(j - 1)) {
                matrix[i][j] = matrix[i - 1][j - 1];
            } else {
                matrix[i][j] = Math.min(matrix[i - 1][j - 1] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j] + 1);
            }
        }
    }
    return matrix[b.length][a.length];
}

function normalizeText(text) {
    return (text || '').toLowerCase().replace(/[^a-z0-9þðüöçýÝ\s]/gi, '').replace(/\s+/g, ' ').trim();
}

function calculateSimilarity(text1, text2) {
    const norm1 = normalizeText(text1);
    const norm2 = normalizeText(text2);
    if (!norm1.length || !norm2.length) return 0;
    const distance = levenshtein(norm1, norm2);
    return Math.round((1 - distance / Math.max(norm1.length, norm2.length)) * 100);
}

function validateQuestions(questions, existingQuestions = []) {
    const results = [];
    const seenInBatch = new Set();

    questions.forEach((q, index) => {
        const errors = [];
        const warnings = [];
        const qText = (q.q || '').trim();

        if (!qText) errors.push({ field: 'q', msg: 'Soru metni boþ!' });
        else if (qText.length < 20) errors.push({ field: 'q', msg: `Soru çok kýsa (${qText.length} kar.)` });

        if (!q.o || !Array.isArray(q.o) || q.o.length !== 5) {
            errors.push({ field: 'o', msg: '5 seçenek olmalý!' });
        } else {
            q.o.forEach((opt, i) => {
                if (!opt || opt.trim().length === 0) {
                    errors.push({ field: `o[${i}]`, msg: `${['A', 'B', 'C', 'D', 'E'][i]} þýkký boþ!` });
                }
            });
        }

        if (q.a === undefined || q.a < 0 || q.a > 4) {
            errors.push({ field: 'a', msg: 'Doðru cevap 0-4 arasý olmalý!' });
        }

        const normQ = normalizeText(qText);
        if (seenInBatch.has(normQ)) {
            errors.push({ field: 'q', msg: 'Batch içinde tekrar!' });
        } else {
            seenInBatch.add(normQ);
        }

        for (const existing of existingQuestions) {
            const sim = calculateSimilarity(qText, existing.q);
            if (sim >= 90) {
                errors.push({ field: 'q', msg: `Mevcut soruyla %${sim} ayný!` });
                break;
            } else if (sim >= 75) {
                warnings.push({ field: 'q', msg: `Mevcut soruyla %${sim} benzer` });
                break;
            }
        }

        const quality = calculateQualityScore(q);
        const difficulty = calculateDifficultyScore(q);

        results.push({
            index,
            status: errors.length > 0 ? 'error' : warnings.length > 0 ? 'warning' : 'valid',
            errors,
            warnings,
            canSave: errors.length === 0,
            quality,
            difficulty,
            data: q
        });
    });

    const stats = {
        total: questions.length,
        valid: results.filter(r => r.status === 'valid').length,
        warnings: results.filter(r => r.status === 'warning').length,
        errors: results.filter(r => r.status === 'error').length,
        avgQuality: Math.round(results.reduce((sum, r) => sum + r.quality.score, 0) / results.length) || 0
    };

    return { results, stats };
}

function generateIds(questions, topicId, existing) {
    const topic = TOPICS[topicId];
    if (!topic) return questions;

    const prefix = topic.prefix || 'q';
    let maxNum = 0;

    existing.forEach(q => {
        if (q.id?.startsWith(prefix + '_')) {
            const num = parseInt(q.id.split('_').pop());
            if (!isNaN(num)) maxNum = Math.max(maxNum, num);
        }
    });

    return questions.map(q => {
        maxNum++;
        return { ...q, id: `${prefix}_${String(maxNum).padStart(3, '0')}`, topicId };
    });
}

// ===========================================================================
// CSV PARSER
// ===========================================================================

function parseCSV(csvText) {
    const lines = csvText.trim().split('\n');
    if (lines.length < 2) return [];

    const headers = lines[0].split(',').map(h => h.trim().toLowerCase());
    const questions = [];

    for (let i = 1; i < lines.length; i++) {
        const values = parseCSVLine(lines[i]);
        if (values.length < 7) continue;

        const q = {};
        headers.forEach((h, idx) => {
            const val = values[idx] || '';
            if (h === 'q' || h === 'soru' || h === 'question') q.q = val;
            else if (h === 'a' || h === 'cevap' || h === 'answer') q.a = parseInt(val) || 0;
            else if (h === 'e' || h === 'aciklama' || h === 'explanation') q.e = val;
            else if (h.match(/^(o[1-5]|sik[1-5]|option[1-5])$/)) {
                if (!q.o) q.o = [];
                const idx = parseInt(h.match(/\d/)[0]) - 1;
                q.o[idx] = val;
            }
        });

        if (!q.o && values.length >= 7) {
            q.q = values[0];
            q.o = [values[1], values[2], values[3], values[4], values[5]];
            q.a = parseInt(values[6]) || 0;
            q.e = values[7] || '';
        }

        if (q.q && q.o && q.o.length === 5) {
            questions.push(q);
        }
    }

    return questions;
}

function parseCSVLine(line) {
    const result = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
        const char = line[i];
        if (char === '"') {
            inQuotes = !inQuotes;
        } else if (char === ',' && !inQuotes) {
            result.push(current.trim());
            current = '';
        } else {
            current += char;
        }
    }
    result.push(current.trim());

    return result;
}
// ===========================================================================
// v7.0 YENÝ ÖZELLÝKLER
// ===========================================================================

// TARGETS dosyasý
const TARGETS_FILE = path.join(__dirname, 'targets.json');

// Hedefleri yükle
async function loadTargets() {
    try {
        const data = await fs.readFile(TARGETS_FILE, 'utf8');
        return JSON.parse(data);
    } catch {
        // Varsayýlan hedefler
        return {
            'TARÝH': 300,
            'COÐRAFYA': 150,
            'VATANDAÞLIK': 150,
            'TÜRKÇE': 300,
            'MATEMATÝK': 300,
            'GÜNCEL BÝLGÝLER': 100
        };
    }
}

// Hedefleri kaydet
async function saveTargets(targets) {
    await fs.writeFile(TARGETS_FILE, JSON.stringify(targets, null, 2), 'utf8');
}

// Duplicate Finder - OPTIMIZED (word overlap instead of Levenshtein)
async function findDuplicates(threshold = 75) {
    const allQuestions = [];

    // Tüm sorularý yükle
    for (const [topicId, topicInfo] of Object.entries(TOPICS)) {
        const questions = await loadQuestions(topicId);
        questions.forEach(q => {
            // Kelimeleri önceden hesapla
            const words = new Set(
                normalizeText(q.q || '')
                    .split(/\s+/)
                    .filter(w => w.length > 2)
            );
            allQuestions.push({
                id: q.id,
                topicId,
                topicName: topicInfo.name,
                text: (q.q || '').substring(0, 100),
                words
            });
        });
    }

    const duplicates = [];
    const maxComparisons = 50000; // Limit for performance
    let comparisons = 0;

    for (let i = 0; i < allQuestions.length && comparisons < maxComparisons; i++) {
        for (let j = i + 1; j < allQuestions.length && comparisons < maxComparisons; j++) {
            comparisons++;

            const q1 = allQuestions[i];
            const q2 = allQuestions[j];

            // Hýzlý word overlap similarity
            const intersection = [...q1.words].filter(w => q2.words.has(w)).length;
            const union = new Set([...q1.words, ...q2.words]).size;
            const sim = union > 0 ? Math.round((intersection / union) * 100) : 0;

            if (sim >= threshold) {
                duplicates.push({
                    similarity: sim,
                    question1: { id: q1.id, topicId: q1.topicId, topicName: q1.topicName, text: q1.text },
                    question2: { id: q2.id, topicId: q2.topicId, topicName: q2.topicName, text: q2.text }
                });
            }
        }
    }

    return duplicates.sort((a, b) => b.similarity - a.similarity).slice(0, 50);
}

// Word Cloud - En çok geçen kelimeler
async function generateWordCloud(topicId = null, limit = 50) {
    const stopWords = new Set([
        've', 'veya', 'ile', 'için', 'bir', 'bu', 'þu', 'o', 'de', 'da', 'den', 'dan',
        'ne', 'mi', 'mý', 'mu', 'mü', 'ki', 'gibi', 'kadar', 'daha', 'en', 'çok',
        'olan', 'olarak', 'ise', 'ya', 'hem', 'ama', 'fakat', 'ancak', 'çünkü',
        'hangisi', 'hangisinde', 'hangileri', 'aþaðýdakilerden', 'yukarýdakilerden',
        'aþaðýda', 'yukarýda', 'verilen', 'verilenlerden', 'göre', 'doðru', 'yanlýþ',
        'i', 'ii', 'iii', 'iv', 'v', 'a', 'b', 'c', 'd', 'e'
    ]);

    const wordCounts = {};
    const topics = topicId ? [[topicId, TOPICS[topicId]]] : Object.entries(TOPICS);

    for (const [tid, topicInfo] of topics) {
        if (!topicInfo) continue;
        const questions = await loadQuestions(tid);

        questions.forEach(q => {
            const text = (q.q || '') + ' ' + (q.o || []).join(' ');
            const words = text.toLowerCase()
                .replace(/[^a-zþðüöçý\s]/gi, '')
                .split(/\s+/)
                .filter(w => w.length > 2 && !stopWords.has(w));

            words.forEach(word => {
                wordCounts[word] = (wordCounts[word] || 0) + 1;
            });
        });
    }

    const sorted = Object.entries(wordCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, limit)
        .map(([word, count]) => ({ word, count }));

    return sorted;
}

// Flutter Sync Check - JSON dosyalarýnýn Flutter app ile uyumluluðunu kontrol et
async function checkFlutterSync() {
    const issues = [];
    const summary = { totalQuestions: 0, validQuestions: 0, invalidQuestions: 0 };

    for (const [topicId, topicInfo] of Object.entries(TOPICS)) {
        const questions = await loadQuestions(topicId);
        summary.totalQuestions += questions.length;

        questions.forEach((q, idx) => {
            const qIssues = [];

            // Required fields check
            if (!q.id) qIssues.push('id eksik');
            if (!q.q || typeof q.q !== 'string') qIssues.push('q (soru) geçersiz');
            if (!q.o || !Array.isArray(q.o) || q.o.length !== 5) qIssues.push('o (seçenekler) 5 elemanlý dizi olmalý');
            if (q.a === undefined || typeof q.a !== 'number' || q.a < 0 || q.a > 4) qIssues.push('a (cevap) 0-4 arasý sayý olmalý');

            // Type checks
            if (q.e && typeof q.e !== 'string') qIssues.push('e (açýklama) string olmalý');
            if (q.topicId && q.topicId !== topicId) qIssues.push('topicId uyumsuz');

            // Turkish character check
            const hasInvalidChars = /[\x00-\x08\x0B\x0C\x0E-\x1F]/.test(q.q || '');
            if (hasInvalidChars) qIssues.push('Geçersiz karakter içeriyor');

            if (qIssues.length > 0) {
                summary.invalidQuestions++;
                issues.push({
                    topicId,
                    topicName: topicInfo.name,
                    questionId: q.id || `index-${idx}`,
                    issues: qIssues
                });
            } else {
                summary.validQuestions++;
            }
        });
    }

    return {
        summary,
        syncStatus: summary.invalidQuestions === 0 ? 'OK' : 'ISSUES_FOUND',
        issues: issues.slice(0, 50) // Ýlk 50 sorunu göster
    };
}

// Hatalý format sorularý bul (þýklar soru metninde olanlar)
async function findMalformedQuestions() {
    const malformed = [];

    // Daha geniþ pattern'ler - A), A., A-, A: formatlarý
    const optionPatterns = [
        /\bA\)/gi, /\bB\)/gi, /\bC\)/gi, /\bD\)/gi, /\bE\)/gi,
        /\bA\./g, /\bB\./g, /\bC\./g, /\bD\./g, /\bE\./g,
        /\bA-\s/gi, /\bB-\s/gi, /\bC-\s/gi, /\bD-\s/gi, /\bE-\s/gi,
        /\bA:\s/gi, /\bB:\s/gi, /\bC:\s/gi, /\bD:\s/gi, /\bE:\s/gi
    ];

    for (const [topicId, topicInfo] of Object.entries(TOPICS)) {
        const questions = await loadQuestions(topicId);

        questions.forEach((q, idx) => {
            const issues = [];

            // Soru metninde þýk var mý?
            for (const pattern of optionPatterns) {
                if (pattern.test(q.q || '')) {
                    issues.push('Soru metninde þýk harfi var (A), B), vs.)');
                    break;
                }
            }

            // Soru metni çok kýsa mý?
            const wordCount = (q.q || '').split(/\s+/).length;
            if (wordCount < 10) {
                issues.push(`Soru metni çok kýsa (${wordCount} kelime)`);
            }

            // Þýklar eksik veya yanlýþ mý?
            if (!q.o || q.o.length !== 5) {
                issues.push('Þýk sayýsý 5 deðil');
            }

            if (issues.length > 0) {
                malformed.push({
                    topicId,
                    topicName: topicInfo.name,
                    questionId: q.id,
                    questionPreview: (q.q || '').substring(0, 100) + '...',
                    issues
                });
            }
        });
    }

    return malformed;
}

// Bulk Edit - Toplu düzenleme
async function bulkEdit(topicId, edits) {
    const questions = await loadQuestions(topicId);
    await createBackup(topicId, questions);

    let updated = 0;
    edits.forEach(edit => {
        const q = questions.find(q => q.id === edit.id);
        if (q) {
            if (edit.q !== undefined) q.q = edit.q;
            if (edit.o !== undefined) q.o = edit.o;
            if (edit.a !== undefined) q.a = edit.a;
            if (edit.e !== undefined) q.e = edit.e;
            updated++;
        }
    });

    await saveQuestions(topicId, questions);
    await logHistory('bulk_edit', { topicId, count: updated });

    return { updated, total: questions.length };
}

// ===========================================================================
// GEMINI AI SORU URETIMI
// ===========================================================================

const SUBJECT_PREFIXES = {
    'TARÝH': 'tarih',
    'COÐRAFYA': 'cog',
    'TÜRKÇE': 'turkce',
    'VATANDAÞLIK': 'vat',
    'MATEMATÝK': 'mat',
    'GÜNCEL BÝLGÝLER': 'guncel'
};

async function generateQuestionsWithAI(topicId, topic, lesson, count = 10, difficulty = 'Orta', cognitiveLevel = 'Karma') {
    const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY || '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';

    if (!OPENROUTER_API_KEY || OPENROUTER_API_KEY === 'YOUR_OPENROUTER_API_KEY') {
        throw new Error('OpenRouter API key ayarlanmamis. Lutfen API key girin.');
    }

    const prefix = SUBJECT_PREFIXES[lesson] || 'kpss';
    const timestamp = Date.now();

    // Biliþsel düzey açýklamalarý
    const cognitiveLevelGuide = {
        'Bilgi': `SORU TÝPÝ: BÝLGÝ & KAVRAMA
    - Doðrudan bilgi sorularý (kim, ne, ne zaman, nerede)
    - Taným ve kavram sorularý
    - Sýralama ve eþleþtirme sorularý
    - "Aþaðýdakilerden hangisi...?" formatý`,
        'Analiz': `SORU TÝPÝ: ANALÝZ & YORUM
    - Öncüllü sorular ("I. ... II. ... III. ... Yukarýdakilerden hangileri doðrudur?")
    - Karþýlaþtýrma sorularý
    - Neden-sonuç iliþkisi sorularý
    - "Buna göre..." ile baþlayan yorumlama sorularý`,
        'Senaryo': `SORU TÝPÝ: SENARYO & UYGULAMA
    - Durum/olay senaryolarý ("Tarih öðretmeni Ahmet Bey...")
    - Güncel hayat örnekleri
    - Problem çözme sorularý
    - "Bu durumda..." formatý
    - Öðrenci/vatandaþ perspektifli sorular`,
        'Karma': `SORU TÝPLERÝ: KARMA (TÜM TÝPLER)
    Aþaðýdaki tiplerin karýþýmýný kullan:
    1. Bilgi sorusu (2-3 adet): Doðrudan bilgi
    2. Öncüllü soru (2-3 adet): "I. II. III. Yukarýdakilerden hangileri..."
    3. Analiz sorusu (2-3 adet): Karþýlaþtýrma ve yorum
    4. Senaryo sorusu (2-3 adet): Durumsal, uygulamalý`
    };

    // Zorluk seviyesi açýklamalarý
    const difficultyGuide = {
        'Kolay': `ZORLUK: KOLAY (Baþlangýç)
    - Temel ve bilinen kavramlar
    - Direkt hatýrlama gerektiren sorular  
    - Karýþtýrýcý þýklar az
    - Net ve anlaþýlýr ifadeler`,
        'Orta': `ZORLUK: ORTA (ÖSYM Standart)
    - ÖSYM sýnav standardýnda
    - Dikkatli okuma gerektiren
    - Bazý þýklar birbirine yakýn
    - Detay bilgisi gerektiren`,
        'Zor': `ZORLUK: ZOR (Seçici/Ayýrt Edici)
    - Derin analiz gerektiren
    - Çoklu bilgi sentezi
    - Þýklar çok yakýn ve yanýltýcý
    - Ýstisna ve özel durumlar
    - "Hangisi yanlýþtýr?" formatlarý`
    };

    const prompt = `ROL: Sen ÖSYM'de 20 yýl çalýþmýþ, binlerce KPSS sorusu yazmýþ kýdemli bir soru yazarýsýn.

    GÖREV: ${lesson} dersi - "${topic}" konusu için ${count} adet PROFESYONEL KPSS sýnavý sorusu yaz.

    ===========================================================
    ${difficultyGuide[difficulty] || difficultyGuide['Orta']}
    ===========================================================
    ${cognitiveLevelGuide[cognitiveLevel] || cognitiveLevelGuide['Karma']}
    ===========================================================

    ÖSYM SORU YAZIM STANDARTLARI:
    1. SORU KÖKLERÝ:
    - "Aþaðýdakilerden hangisi ... deðildir?"
    - "Buna göre aþaðýdakilerden hangisi söylenebilir?"
    - "Yukarýdaki bilgilere göre..."
    - "I. ... II. ... III. ... Yukarýdakilerden hangileri doðrudur?"

    2. SEÇENEK YAPISI:
    - 5 seçenek ZORUNLU (A, B, C, D, E)
    - Seçenekler birbirine yakýn uzunlukta
    - En az 2 seçenek yanýltýcý (plausible)
    - Doðru cevap rastgele daðýlmalý (A=2, B=2, C=2, D=2, E=2 gibi)

    3. ÖNCÜLLÜ SORULAR:
    - En az ${Math.floor(count / 3)} soru öncüllü olmalý
    - Format: "I. [ifade] II. [ifade] III. [ifade]"
    - Þýklar: "Yalnýz I", "I ve II", "I ve III", "II ve III", "I, II ve III"

    4. AÇIKLAMALAR (KPSS HOCASI GÝBÝ KISA VE ÖZ):
    - 1-2 cümle ile doðru cevabý açýkla
    - Gereksiz detay verme, sadece öðrencinin bilmesi gereken bilgiyi yaz
    - Örnek: "Doðru cevap C. Kavimler Göçü 375'te baþlamýþtýr."
    - Yanlýþ þýklarý tek tek açýklama, sadece doðruyu belirt

    YASAKLAR:
    ? Çok basit veya ezber sorular
    ? Ayný þýk yapýsýnýn tekrarý
    ? Mantýksýz veya alakasýz þýklar
    ? Hep ayný doðru cevap (A veya D gibi)
    ? SORU METNÝNDE (q alanýnda) ÞIK YAZMA! Þýklar SADECE "o" array'inde olmalý!
    ? Kýsa soru metni yazma - en az 2-3 cümle olmalý

    ÖNEMLÝ FORMAT KURALLARI:
    - "q" alaný: SADECE soru metni (A), B), C) vb. OLMAMALI!)
    - "o" alaný: 5 þýk array olarak ["þýk1", "þýk2", "þýk3", "þýk4", "þýk5"]
    - Soru metni uzun ve detaylý olmalý (en az 30 kelime)

    JSON FORMATI (SADECE bu formatta, baþka bir þey yazma):
    {
    "questions": [
        {
        "id": "${prefix}_${timestamp}_001",
        "topicId": "${topicId}",
        "subtopicId": "alt-konu-slug-formati",
        "subtopic": "Alt Konu Baþlýðý",
        "q": "1071 yýlýnda gerçekleþen Malazgirt Savaþý, Türk tarihinde önemli bir dönüm noktasýdýr. Bu savaþta Selçuklu Sultaný Alparslan, Bizans Ýmparatoru Romen Diyojen'i yenilgiye uðratmýþtýr. Bu zafer sonucunda Anadolu'nun kapýlarý Türklere açýlmýþtýr. Malazgirt Savaþý'nýn sonuçlarý ile ilgili aþaðýdakilerden hangisi yanlýþtýr?",
        "o": ["Anadolu'ya Türk göçleri hýzlanmýþtýr", "Bizans Ýmparatorluðu zayýflamýþtýr", "Haçlý Seferleri baþlamýþtýr", "Türkiye Selçuklu Devleti kurulmuþtur", "Anadolu'da ilk Türk beylikleri kurulmuþtur"],
        "a": 2,
        "e": "Doðru cevap C. Haçlý Seferleri 1096'da baþlamýþ olup Malazgirt'in doðrudan sonucu deðildir."
        }
    ]
    }`;

    // Model listesi - ilki baþarýsýz olursa sonrakini dene
    const models = ['x-ai/grok-4.1-fast', 'x-ai/grok-4-fast', 'google/gemini-2.5-flash-preview-05-20'];
    let lastError = null;

    for (const modelName of models) {
        try {
            console.log(`AI soru uretimi deneniyor: ${modelName}`);

            const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
                    'Content-Type': 'application/json',
                    'HTTP-Referer': 'http://localhost:3456',
                    'X-Title': 'KPSS Question Generator'
                },
                body: JSON.stringify({
                    model: modelName,
                    messages: [
                        { role: 'user', content: prompt }
                    ],
                    temperature: 0.8,
                    max_tokens: 8192
                })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(`${modelName} hatasi: ${errorData.error?.message || response.statusText}`);
            }

            const result = await response.json();
            let text = result.choices[0]?.message?.content || '';

            // JSON'u temizle (bazen markdown code block icinde geliyor)
            text = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

            const data = JSON.parse(text);

            if (!data.questions || !Array.isArray(data.questions)) {
                throw new Error('Gecersiz AI yaniti - questions array bulunamadi');
            }

            // ID'leri duzelt ve eksik alanlari tamamla
            const questions = data.questions.map((q, idx) => ({
                id: q.id || `${prefix}_${timestamp}_${(idx + 1).toString().padStart(3, '0')}`,
                topicId: topicId,
                subtopicId: q.subtopicId || 'genel',
                subtopic: q.subtopic || topic,
                q: q.q,
                o: q.o,
                a: typeof q.a === 'number' ? q.a : 0,
                e: q.e || ''
            }));

            console.log(`${modelName} ile ${questions.length} soru uretildi!`);
            return questions;

        } catch (modelError) {
            console.error(`${modelName} basarisiz:`, modelError.message);
            lastError = modelError;
            // Sonraki modeli dene
        }
    }

    // Tüm modeller baþarýsýz
    throw new Error('Tum modeller basarisiz: ' + lastError?.message);
}

// ===========================================================================
// API DÖKÜMANTASYONU
// ===========================================================================

const API_DOCS = {
    info: {
        title: 'KPSS Question Management API',
        version: '7.0',
        description: 'KPSS soru yönetim sistemi API\'si - Ultimate Edition'
    },
    endpoints: [
        { method: 'GET', path: '/topics', desc: 'Tüm konularý listeler' },
        { method: 'GET', path: '/stats', desc: 'Genel istatistikleri döner' },
        { method: 'GET', path: '/gaps', desc: 'Eksik içerik analizini döner' },
        { method: 'GET', path: '/trends', desc: 'Son 30 günlük trend verisi' },
        { method: 'GET', path: '/questions/:topicId', desc: 'Konuya ait sorularý döner' },
        { method: 'POST', path: '/validate', desc: 'Sorularý valide eder' },
        { method: 'POST', path: '/add', desc: 'Yeni sorular ekler' },
        { method: 'PUT', path: '/questions/:topicId/:id', desc: 'Soru günceller' },
        { method: 'DELETE', path: '/questions/:topicId/:id', desc: 'Soru siler' },
        { method: 'POST', path: '/move', desc: 'Soruyu baþka konuya taþýr' },
        { method: 'POST', path: '/copy', desc: 'Soruyu baþka konuya kopyalar' },
        { method: 'POST', path: '/bulk-delete', desc: 'Toplu soru siler' },
        { method: 'POST', path: '/bulk-explanation', desc: 'Toplu açýklama ekler' },
        { method: 'POST', path: '/bulk-edit', desc: 'Toplu soru düzenler' },
        { method: 'GET', path: '/templates', desc: 'Soru þablonlarýný döner' },
        { method: 'POST', path: '/templates', desc: 'Yeni þablon ekler' },
        { method: 'GET', path: '/backups/:topicId', desc: 'Backup listesini döner' },
        { method: 'POST', path: '/restore/:filename', desc: 'Backup\'tan geri yükler' },
        { method: 'GET', path: '/search', desc: 'Soru arar (?q=...&lesson=...)' },
        { method: 'POST', path: '/import-csv', desc: 'CSV\'den import eder' },
        { method: 'GET', path: '/api-docs', desc: 'Bu API dökümantasyonu' },
        { method: 'GET', path: '/duplicates', desc: 'Benzer sorularý bulur (?threshold=75)' },
        { method: 'GET', path: '/wordcloud', desc: 'Kelime bulutu (?topicId=...&limit=50)' },
        { method: 'GET', path: '/flutter-sync', desc: 'Flutter uyumluluk kontrolü' },
        { method: 'GET', path: '/targets', desc: 'Hedef soru sayýlarýný döner' },
        { method: 'POST', path: '/targets', desc: 'Hedef soru sayýlarýný günceller' }
    ]
};

// ===========================================================================
// HTTP SERVER
// ===========================================================================

const server = http.createServer(async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        return res.end();
    }

    const url = new URL(req.url, `http://localhost:${PORT}`);
    const pathname = url.pathname;

    console.log(`[${req.method}] ${pathname}`);

    try {
        // GET /topics
        if (pathname === '/topics' && req.method === 'GET') {
            const result = await Promise.all(
                Object.entries(TOPICS).map(async ([id, info]) => {
                    const questions = await loadQuestions(id);
                    return { id, ...info, count: questions.length };
                })
            );
            return sendJSON(res, result);
        }


        // GET /all-questions - Tum sorular (Zorluk filtreleme icin)
        if (pathname === '/all-questions' && req.method === 'GET') {
            try {
                const allQuestions = {};
                const topicsInfo = {};

                for (const [topicId, topicInfo] of Object.entries(TOPICS)) {
                    const questions = await loadQuestions(topicId);

                    // Her soruya zorluk ekle
                    allQuestions[topicId] = questions.map(q => ({
                        ...q,
                        difficulty: calculateDifficultyScore(q)
                    }));

                    topicsInfo[topicId] = {
                        name: topicInfo.name,
                        lesson: topicInfo.lesson
                    };
                }

                return sendJSON(res, {
                    questions: allQuestions,
                    topics: topicsInfo,
                    total: Object.values(allQuestions).reduce((sum, arr) => sum + arr.length, 0)
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }


        // GET /ai-review - AI ile konu sorularý kontrol et
        if (pathname === '/ai-review' && req.method === 'GET') {
            const topicId = url.searchParams.get('topicId');
            const limit = parseInt(url.searchParams.get('limit')) || 50;
            const skipReviewed = url.searchParams.get('skipReviewed') !== 'false'; // Default: true

            if (!topicId) {
                return sendJSON(res, { error: 'topicId gerekli' }, 400);
            }

            try {
                const questions = await loadQuestions(topicId);
                const topicInfo = TOPICS[topicId];

                if (!topicInfo) {
                    return sendJSON(res, { error: 'Konu bulunamadi' }, 404);
                }

                // Sorulari batch halinde analiz et
                // Daha önce kontrol edilenleri atla
                const unreviewedQuestions = skipReviewed
                    ? questions.filter(q => !q.aiReviewed)
                    : questions;
                const questionsToReview = unreviewedQuestions.slice(0, limit);
                const issues = await reviewQuestionsWithAI_Batch(questionsToReview, topicInfo);

                return sendJSON(res, {
                    topicId,
                    topicName: topicInfo.name,
                    reviewed: questionsToReview.length,
                    total: questions.length,
                    issues,
                    reviewedQuestionIds: questionsToReview.map(q => q.id)
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }


        // POST /mark-reviewed - Soruyu kontrol edildi olarak iþaretle
        if (pathname === '/mark-reviewed' && req.method === 'POST') {
            try {
                const { topicId, questionIds } = await parseBody(req);

                if (!topicId || !questionIds || !questionIds.length) {
                    return sendJSON(res, { error: 'topicId ve questionIds gerekli' }, 400);
                }

                const questions = await loadQuestions(topicId);
                let markedCount = 0;

                questions.forEach(q => {
                    if (questionIds.includes(q.id)) {
                        q.aiReviewed = new Date().toISOString();
                        markedCount++;
                    }
                });

                if (markedCount > 0) {
                    await saveQuestions(topicId, questions);
                }

                return sendJSON(res, {
                    success: true,
                    markedCount,
                    message: markedCount + ' soru kontrol edildi olarak iþaretlendi'
                });
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }

        // GET /stats
        if (pathname === '/stats' && req.method === 'GET') {
            const stats = await calculateStats();
            return sendJSON(res, stats);
        }

        // GET /gaps
        if (pathname === '/gaps' && req.method === 'GET') {
            const gaps = await analyzeGaps();
            return sendJSON(res, gaps);
        }

        // GET /trends
        if (pathname === '/trends' && req.method === 'GET') {
            const trends = await getTrends();
            return sendJSON(res, trends);
        }

        // GET /api-docs
        if (pathname === '/api-docs' && req.method === 'GET') {
            return sendJSON(res, API_DOCS);
        }

        // GET /templates
        if (pathname === '/templates' && req.method === 'GET') {
            const templates = await loadTemplates();
            return sendJSON(res, templates);
        }

        // POST /templates
        if (pathname === '/templates' && req.method === 'POST') {
            const { name, template } = await parseBody(req);
            const templates = await loadTemplates();
            const newTemplate = {
                id: 'custom_' + Date.now(),
                name,
                template
            };
            templates.push(newTemplate);
            await saveTemplates(templates);
            return sendJSON(res, { success: true, template: newTemplate });
        }

        // GET /questions/:topicId
        if (pathname.startsWith('/questions/') && req.method === 'GET') {
            const topicId = pathname.split('/')[2];
            const questions = await loadQuestions(topicId);

            const withScores = questions.map(q => ({
                ...q,
                _quality: calculateQualityScore(q),
                _difficulty: calculateDifficultyScore(q)
            }));

            return sendJSON(res, {
                topicId,
                topic: TOPICS[topicId],
                count: questions.length,
                questions: withScores
            });
        }

        // PUT /questions/:topicId/:questionId
        if (pathname.match(/^\/questions\/[^/]+\/[^/]+$/) && req.method === 'PUT') {
            const parts = pathname.split('/');
            const topicId = parts[2];
            const questionId = parts[3];
            const updates = await parseBody(req);

            const questions = await loadQuestions(topicId);
            const idx = questions.findIndex(q => q.id === questionId);

            if (idx === -1) {
                return sendJSON(res, { success: false, error: 'Soru bulunamadý' }, 404);
            }

            await createBackup(topicId, questions);
            questions[idx] = { ...questions[idx], ...updates, id: questionId, topicId };
            await saveQuestions(topicId, questions);
            await logHistory('edit', { topicId, questionId });

            return sendJSON(res, {
                success: true,
                message: 'Soru güncellendi',
                question: questions[idx],
                quality: calculateQualityScore(questions[idx]),
                difficulty: calculateDifficultyScore(questions[idx])
            });
        }

        // DELETE /questions/:topicId/:questionId
        if (pathname.match(/^\/questions\/[^/]+\/[^/]+$/) && req.method === 'DELETE') {
            const parts = pathname.split('/');
            const topicId = parts[2];
            const questionId = parts[3];

            const questions = await loadQuestions(topicId);
            const idx = questions.findIndex(q => q.id === questionId);

            if (idx === -1) {
                return sendJSON(res, { success: false, error: 'Soru bulunamadý' }, 404);
            }

            await createBackup(topicId, questions);
            questions.splice(idx, 1);
            await saveQuestions(topicId, questions);
            await logHistory('delete', { topicId, questionId });

            return sendJSON(res, { success: true, message: 'Soru silindi', remaining: questions.length });
        }

        // POST /validate
        if (pathname === '/validate' && req.method === 'POST') {
            const { topicId, questions } = await parseBody(req);
            const existing = topicId ? await loadQuestions(topicId) : [];
            const validation = validateQuestions(questions, existing);
            return sendJSON(res, validation);
        }

        // POST /add
        if (pathname === '/add' && req.method === 'POST') {
            const { topicId, questions } = await parseBody(req);

            if (!topicId || !TOPICS[topicId]) {
                return sendJSON(res, { success: false, error: 'Geçersiz konu ID' }, 400);
            }

            const existing = await loadQuestions(topicId);

            if (existing.length > 0) {
                await createBackup(topicId, existing);
            }

            const validation = validateQuestions(questions, existing);

            if (validation.stats.errors > 0) {
                return sendJSON(res, {
                    success: false,
                    error: `${validation.stats.errors} soru hatalý!`,
                    validation
                }, 400);
            }

            const withIds = generateIds(questions, topicId, existing);
            const merged = [...existing, ...withIds];
            await saveQuestions(topicId, merged);
            await logHistory('add', { topicId, count: questions.length });

            return sendJSON(res, {
                success: true,
                message: `${questions.length} soru baþarýyla eklendi!`,
                total: merged.length,
                addedIds: withIds.map(q => q.id)
            });
        }

        // POST /move
        if (pathname === '/move' && req.method === 'POST') {
            const { fromTopicId, toTopicId, questionId } = await parseBody(req);
            const result = await moveQuestion(fromTopicId, toTopicId, questionId);
            return sendJSON(res, result);
        }

        // POST /copy
        if (pathname === '/copy' && req.method === 'POST') {
            const { fromTopicId, toTopicId, questionId } = await parseBody(req);
            const result = await copyQuestion(fromTopicId, toTopicId, questionId);
            return sendJSON(res, result);
        }

        // POST /bulk-delete
        if (pathname === '/bulk-delete' && req.method === 'POST') {
            const { topicId, questionIds } = await parseBody(req);
            const result = await bulkDelete(topicId, questionIds);
            return sendJSON(res, result);
        }

        // POST /bulk-explanation
        if (pathname === '/bulk-explanation' && req.method === 'POST') {
            const { topicId, explanations } = await parseBody(req);
            const result = await bulkAddExplanations(topicId, explanations);
            return sendJSON(res, result);
        }

        // POST /import-csv
        if (pathname === '/import-csv' && req.method === 'POST') {
            const { topicId, csvData } = await parseBody(req);

            if (!topicId || !TOPICS[topicId]) {
                return sendJSON(res, { success: false, error: 'Geçersiz konu ID' }, 400);
            }

            const questions = parseCSV(csvData);

            if (questions.length === 0) {
                return sendJSON(res, { success: false, error: 'CSV\'den soru parse edilemedi' }, 400);
            }

            const existing = await loadQuestions(topicId);
            const validation = validateQuestions(questions, existing);

            return sendJSON(res, {
                success: true,
                parsed: questions.length,
                questions,
                validation
            });
        }

        // GET /backups/:topicId
        if (pathname.startsWith('/backups/') && req.method === 'GET') {
            const topicId = pathname.split('/')[2];

            try {
                const files = await fs.readdir(BACKUP_DIR);
                const backups = files
                    .filter(f => f.startsWith(topicId + '_'))
                    .map(f => {
                        const match = f.match(/_(\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2})/);
                        return {
                            file: f,
                            date: match ? match[1].replace(/-/g, ':').replace('T', ' ') : 'Unknown'
                        };
                    })
                    .sort((a, b) => b.file.localeCompare(a.file));

                return sendJSON(res, { backups });
            } catch {
                return sendJSON(res, { backups: [] });
            }
        }

        // POST /restore/:filename
        if (pathname.startsWith('/restore/') && req.method === 'POST') {
            const filename = pathname.split('/')[2];
            const topicId = filename.split('_')[0];

            try {
                const backupPath = path.join(BACKUP_DIR, filename);
                const data = await fs.readFile(backupPath, 'utf8');
                const questions = JSON.parse(data);

                const current = await loadQuestions(topicId);
                if (current.length > 0) {
                    await createBackup(topicId, current);
                }

                await saveQuestions(topicId, questions);
                await logHistory('restore', { topicId, filename });

                return sendJSON(res, {
                    success: true,
                    message: `${questions.length} soru geri yüklendi`,
                    count: questions.length
                });
            } catch (e) {
                return sendJSON(res, { success: false, error: e.message }, 500);
            }
        }

        // GET /malformed - Hatalý format sorularý bul
        if (pathname === '/malformed' && req.method === 'GET') {
            const malformed = await findMalformedQuestions();
            return sendJSON(res, {
                count: malformed.length,
                malformed: malformed.slice(0, 100)
            });
        }

        // POST /replace-text - Toplu Metin Deðiþtirme
        if (pathname === '/replace-text' && req.method === 'POST') {
            const body = await parseBody(req);
            const { find, replace, isRegex, dryRun } = body;

            if (!find) {
                return sendJSON(res, { error: 'Find pattern is required' }, 400);
            }

            try {
                const results = await bulkReplaceText(find, replace, isRegex, dryRun);
                return sendJSON(res, results);
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }

        // GET /analyze-typos - Yazým Hatasý Analizi
        if (pathname === '/analyze-typos' && req.method === 'GET') {
            try {
                const results = await analyzeTypos();
                return sendJSON(res, results);
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }

        // GET /search
        if (pathname === '/search' && req.method === 'GET') {
            const query = url.searchParams.get('q') || '';
            const lesson = url.searchParams.get('lesson') || '';

            if (query.length < 3) {
                return sendJSON(res, { results: [], message: 'En az 3 karakter girin' });
            }

            const results = [];
            const queryLower = query.toLowerCase();

            for (const [topicId, topicInfo] of Object.entries(TOPICS)) {
                if (lesson && topicInfo.lesson !== lesson) continue;

                const questions = await loadQuestions(topicId);
                questions.forEach(q => {
                    if ((q.q || '').toLowerCase().includes(queryLower)) {
                        results.push({
                            ...q,
                            topicId,
                            topicName: topicInfo.name,
                            lesson: topicInfo.lesson,
                            _quality: calculateQualityScore(q),
                            _difficulty: calculateDifficultyScore(q)
                        });
                    }
                });
            }

            return sendJSON(res, { results, count: results.length });
        }

        // ===================================================================
        // v7.0 NEW ENDPOINTS
        // ===================================================================

        // GET /duplicates
        if (pathname === '/duplicates' && req.method === 'GET') {
            const threshold = parseInt(url.searchParams.get('threshold')) || 75;
            const duplicates = await findDuplicates(threshold);
            return sendJSON(res, {
                threshold,
                count: duplicates.length,
                duplicates: duplicates.slice(0, 100)
            });
        }

        // GET /wordcloud
        if (pathname === '/wordcloud' && req.method === 'GET') {
            const topicId = url.searchParams.get('topicId') || null;
            const limit = parseInt(url.searchParams.get('limit')) || 50;
            const words = await generateWordCloud(topicId, limit);
            return sendJSON(res, { topicId, count: words.length, words });
        }

        // GET /flutter-sync
        if (pathname === '/flutter-sync' && req.method === 'GET') {
            const syncResult = await checkFlutterSync();
            return sendJSON(res, syncResult);
        }

        // GET /targets
        if (pathname === '/targets' && req.method === 'GET') {
            const targets = await loadTargets();
            return sendJSON(res, targets);
        }

        // POST /targets
        if (pathname === '/targets' && req.method === 'POST') {
            const newTargets = await parseBody(req);
            await saveTargets(newTargets);
            return sendJSON(res, { success: true, targets: newTargets });
        }

        // POST /bulk-edit
        if (pathname === '/bulk-edit' && req.method === 'POST') {
            const { topicId, edits } = await parseBody(req);
            if (!topicId || !edits || !Array.isArray(edits)) {
                return sendJSON(res, { success: false, error: 'topicId ve edits gerekli' }, 400);
            }
            const result = await bulkEdit(topicId, edits);
            return sendJSON(res, { success: true, ...result });
        }

        // ===================================================================
        // AI SORU URETIMI ENDPOINTS
        // ===================================================================

        // GET /ai-status - AI durumunu kontrol et
        if (pathname === '/ai-status' && req.method === 'GET') {
            const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY || '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';
            const hasApiKey = !!OPENROUTER_API_KEY && OPENROUTER_API_KEY !== 'YOUR_OPENROUTER_API_KEY';
            return sendJSON(res, {
                available: hasApiKey,
                hasPackage: true,
                hasApiKey: hasApiKey,
                provider: 'OpenRouter (Grok 4.1 Fast)',
                message: hasApiKey
                    ? 'AI hazir! (OpenRouter - Grok 4.1 Fast)'
                    : 'OPENROUTER_API_KEY environment variable gerekli'
            });
        }

        // POST /generate-ai - AI ile soru uret
        if (pathname === '/generate-ai' && req.method === 'POST') {
            const { topicId, topic, lesson, count, difficulty, cognitiveLevel } = await parseBody(req);

            if (!topicId || !topic || !lesson) {
                return sendJSON(res, {
                    success: false,
                    error: 'topicId, topic ve lesson gerekli'
                }, 400);
            }

            try {
                const questions = await generateQuestionsWithAI(
                    topicId,
                    topic,
                    lesson,
                    count || 10,
                    difficulty || 'Orta',
                    cognitiveLevel || 'Karma'
                );

                return sendJSON(res, {
                    success: true,
                    count: questions.length,
                    questions,
                    message: `${questions.length} soru basariyla uretildi!`
                });
            } catch (error) {
                return sendJSON(res, {
                    success: false,
                    error: error.message
                }, 500);
            }
        }

        // POST /generate-ai-add - AI ile soru uret VE direkt ekle
        if (pathname === '/generate-ai-add' && req.method === 'POST') {
            const { topicId, topic, lesson, count, difficulty, cognitiveLevel } = await parseBody(req);

            if (!topicId || !TOPICS[topicId]) {
                return sendJSON(res, {
                    success: false,
                    error: 'Gecerli bir topicId gerekli'
                }, 400);
            }

            const topicInfo = TOPICS[topicId];

            try {
                const questions = await generateQuestionsWithAI(
                    topicId,
                    topic || topicInfo.name,
                    lesson || topicInfo.lesson,
                    count || 10,
                    difficulty || 'Orta',
                    cognitiveLevel || 'Karma'
                );

                // Mevcut sorulara ekle
                const existing = await loadQuestions(topicId);
                await createBackup(topicId, existing);
                const merged = [...existing, ...questions];
                await saveQuestions(topicId, merged);
                await logHistory('ai_generate', {
                    topicId,
                    count: questions.length,
                    topic: topic || topicInfo.name
                });

                return sendJSON(res, {
                    success: true,
                    generated: questions.length,
                    total: merged.length,
                    questions,
                    message: `${questions.length} soru uretildi ve eklendi! Toplam: ${merged.length}`
                });
            } catch (error) {
                return sendJSON(res, {
                    success: false,
                    error: error.message
                }, 500);
            }
        }

        // GIT SYNC ENDPOINTS (meto repo - public soru verileri)
        // ===================================================================

        // GET /git-status - meto reposundaki Git durumunu kontrol et
        if (pathname === '/git-status' && req.method === 'GET') {
            const metoDir = path.join(__dirname, '..', '..', 'meto-data');

            try {
                // Önce meto klasörü var mý kontrol et
                if (!fsSync.existsSync(metoDir)) {
                    return sendJSON(res, {
                        success: false,
                        error: 'meto-data klasörü bulunamadý. Lütfen önce repoyu klonlayýn.'
                    }, 400);
                }

                const status = await new Promise((resolve, reject) => {
                    exec('git status --porcelain', { cwd: metoDir }, (error, stdout, stderr) => {
                        if (error) reject(error);
                        else resolve(stdout.trim());
                    });
                });

                const branch = await new Promise((resolve, reject) => {
                    exec('git branch --show-current', { cwd: metoDir }, (error, stdout, stderr) => {
                        if (error) reject(error);
                        else resolve(stdout.trim());
                    });
                });

                const changes = status.split('\n').filter(line => line.trim()).map(line => {
                    const [type, ...pathParts] = line.trim().split(/\s+/);
                    return { type, path: pathParts.join(' ') };
                });

                return sendJSON(res, {
                    success: true,
                    branch,
                    hasChanges: changes.length > 0,
                    totalChanges: changes.length,
                    changes: changes.slice(0, 50),
                    repo: 'meto (public soru verileri)'
                });
            } catch (e) {
                return sendJSON(res, { success: false, error: e.message }, 500);
            }
        }

        
        // POST /publish-to-github - Sorularý GitHub'a yayýnla
        if (pathname === '/publish-to-github' && req.method === 'POST') {
            try {
                const metoDir = path.join(__dirname, '..', '..', 'meto-data');
                const metoQuestionsDir = path.join(metoDir, 'questions');
                
                // meto-data klasörü var mý?
                if (!fsSync.existsSync(metoDir)) {
                    return sendJSON(res, { error: 'meto-data klasörü bulunamadý' }, 404);
                }
                
                // questions klasörünü oluþtur
                if (!fsSync.existsSync(metoQuestionsDir)) {
                    fsSync.mkdirSync(metoQuestionsDir, { recursive: true });
                }
                
                // Lokal sorulardan meto-data'ya kopyala
                const localQuestions = fsSync.readdirSync(QUESTIONS_DIR).filter(f => f.endsWith('.json'));
                let copiedCount = 0;
                const updatedTopics = [];
                
                for (const file of localQuestions) {
                    const srcPath = path.join(QUESTIONS_DIR, file);
                    const destPath = path.join(metoQuestionsDir, file);
                    const content = fsSync.readFileSync(srcPath, 'utf8');
                    const questions = JSON.parse(content);
                    
                    // Sadece dolu dosyalarý kopyala
                    if (questions.length > 0) {
                        fsSync.writeFileSync(destPath, content, 'utf8');
                        copiedCount++;
                        updatedTopics.push(file.replace('.json', ''));
                    }
                }
                
                // version.json güncelle
                const versionPath = path.join(metoDir, 'version.json');
                let versionData = { questions: {}, flashcards: {}, stories: {}, explanations: {}, matching_games: {}, lastUpdated: '' };
                
                if (fsSync.existsSync(versionPath)) {
                    try {
                        versionData = JSON.parse(fsSync.readFileSync(versionPath, 'utf8'));
                    } catch {}
                }
                
                // Her güncelenen topic için version artýr
                for (const topicId of updatedTopics) {
                    const currentVersion = versionData.questions?.[topicId] || 0;
                    if (!versionData.questions) versionData.questions = {};
                    versionData.questions[topicId] = currentVersion + 1;
                }
                
                versionData.lastUpdated = new Date().toISOString().split('T')[0];
                fsSync.writeFileSync(versionPath, JSON.stringify(versionData, null, 2), 'utf8');
                
                // Git push
                const { exec } = require('child_process');
                const gitCommands = `cd "${metoDir}" && git add . && git commit -m "?? Sorular güncellendi: ${updatedTopics.length} konu" && git push`;
                
                exec(gitCommands, (error, stdout, stderr) => {
                    if (error) {
                        console.log('Git push error:', error.message);
                    } else {
                        console.log('Git push success:', stdout);
                    }
                });
                
                return sendJSON(res, {
                    success: true,
                    message: `${copiedCount} dosya GitHub'a aktarýldý`,
                    updatedTopics,
                    versionData: versionData.questions
                });
                
            } catch (e) {
                return sendJSON(res, { error: e.message }, 500);
            }
        }

        // POST /git-push - Sorularý meto reposuna gönder
        if (pathname === '/git-push' && req.method === 'POST') {
            const metoDir = path.join(__dirname, '..', '..', 'meto-data');
            const sourceDir = QUESTIONS_DIR;
            const targetDir = path.join(metoDir, 'questions');
            const { message } = await parseBody(req);
            const commitMsg = message || `Soru guncelleme - ${new Date().toLocaleDateString('tr-TR')}`;

            try {
                // 1. Soru dosyalarýný meto klasörüne kopyala
                if (!fsSync.existsSync(targetDir)) {
                    await fs.mkdir(targetDir, { recursive: true });
                }

                const files = await fs.readdir(sourceDir);
                let copiedCount = 0;
                for (const file of files) {
                    if (file.endsWith('.json') && !file.endsWith('.bak')) {
                        await fs.copyFile(
                            path.join(sourceDir, file),
                            path.join(targetDir, file)
                        );
                        copiedCount++;
                    }
                }

                // 2. Git add
                await new Promise((resolve, reject) => {
                    exec('git add .', { cwd: metoDir }, (error, stdout, stderr) => {
                        if (error) reject(new Error('Git add hatasý: ' + error.message));
                        else resolve(stdout);
                    });
                });

                // 3. Git commit
                const commitResult = await new Promise((resolve, reject) => {
                    exec(`git commit -m "${commitMsg}"`, { cwd: metoDir }, (error, stdout, stderr) => {
                        const output = (stdout || '') + (stderr || '') + (error?.message || '');
                        if (output.includes('nothing to commit') || output.includes('working tree clean')) {
                            resolve('Zaten guncel - degisiklik yok');
                        } else if (error) {
                            reject(new Error('Git commit hatasi: ' + error.message));
                        } else {
                            resolve(stdout || 'Commit yapildi');
                        }
                    });
                });

                // 4. Git push
                const pushResult = await new Promise((resolve, reject) => {
                    exec('git push origin main --force --force', { cwd: metoDir }, (error, stdout, stderr) => {
                        if (error) reject(new Error('Git push hatasý: ' + error.message));
                        else resolve(stdout || stderr || 'Push baþarýlý');
                    });
                });

                await logHistory('git_push', { message: commitMsg, copiedFiles: copiedCount });

                return sendJSON(res, {
                    success: true,
                    message: 'meto reposuna baþarýyla gönderildi! ??',
                    commitMessage: commitMsg,
                    copiedFiles: copiedCount,
                    repo: 'github.com/mertcanasdf/meto'
                });
            } catch (e) {
                return sendJSON(res, { success: false, error: e.message }, 500);
            }
        }

        // Static files
        if (req.method === 'GET') {
            let filePath = pathname === '/' ? 'index.html' : pathname.slice(1);
            filePath = path.join(PUBLIC_DIR, filePath);
            if (!path.extname(filePath)) filePath += '.html';

            try {
                const content = await fs.readFile(filePath);
                res.writeHead(200, { 'Content-Type': MIME_TYPES[path.extname(filePath)] || 'text/plain' });
                return res.end(content);
            } catch { }
        }

        res.writeHead(404);
        res.end('Not found');

    } catch (error) {
        console.error('[ERROR]', error.message);
        sendJSON(res, { error: error.message }, 500);
    }
});

// ===========================================================================
// START
// ===========================================================================

server.listen(PORT, () => {
    console.log(`
-===========================================================================¬
¦  ?? KPSS QUESTION MANAGEMENT SYSTEM v7.0 - ULTIMATE                       ¦
¦  =======================================================================  ¦
¦                                                                           ¦
¦  ?? http://localhost:${PORT}                                                ¦
¦                                                                           ¦
¦  ?? v7.0 YENÝ ÖZELLÝKLER:                                                  ¦
¦     • Duplicate Finder (/duplicates)                                      ¦
¦     • Word Cloud (/wordcloud)                                             ¦
¦     • Flutter Sync Check (/flutter-sync)                                  ¦
¦     • Custom Targets (/targets)                                           ¦
¦     • Bulk Edit Mode (/bulk-edit)                                         ¦
¦                                                                           ¦
L===========================================================================-
    `);
});



async function bulkReplaceText(find, replace, isRegex, dryRun) {
    const files = await fs.readdir(QUESTIONS_DIR);
    const jsonFiles = files.filter(f => f.endsWith('.json'));

    let totalMatches = 0;
    let changedFilesCount = 0;
    const results = [];

    for (const file of jsonFiles) {
        const filePath = path.join(QUESTIONS_DIR, file);
        const content = await fs.readFile(filePath, 'utf8');
        let questions;
        try { questions = JSON.parse(content); } catch (e) { continue; }

        let fileChanged = false;
        let fileMatches = 0;
        const changes = [];

        const processValue = (val, pathStr, qId) => {
            if (typeof val === 'string') {
                let newVal = val;
                if (isRegex) {
                    try {
                        const regex = new RegExp(find, 'g');
                        if (regex.test(val)) newVal = val.replace(regex, replace);
                    } catch (e) { return val; }
                } else {
                    if (val.includes(find)) newVal = val.replaceAll(find, replace);
                }

                if (newVal !== val) {
                    changes.push({ id: qId, path: pathStr, old: val, new: newVal });
                    return newVal;
                }
            }
            return val;
        };

        const newQuestions = questions.map(q => {
            let qChanged = false;
            const newQ = processValue(q.q, 'q', q.id);
            if (newQ !== q.q) { q.q = newQ; qChanged = true; fileMatches++; }
            if (q.e) {
                const newE = processValue(q.e, 'e', q.id);
                if (newE !== q.e) { q.e = newE; qChanged = true; fileMatches++; }
            }
            if (q.subtopic) {
                const newS = processValue(q.subtopic, 'subtopic', q.id);
                if (newS !== q.subtopic) { q.subtopic = newS; qChanged = true; fileMatches++; }
            }
            if (q.o && Array.isArray(q.o)) {
                q.o = q.o.map((opt, idx) => {
                    const newOpt = processValue(opt, `o[${idx}]`, q.id);
                    if (newOpt !== opt) { qChanged = true; fileMatches++; return newOpt; }
                    return opt;
                });
            }
            if (q.options && typeof q.options === 'object') {
                for (const key in q.options) {
                    const newOpt = processValue(q.options[key], `options.${key}`, q.id);
                    if (newOpt !== q.options[key]) {
                        q.options[key] = newOpt;
                        qChanged = true;
                        fileMatches++;
                    }
                }
            }
            if (qChanged) fileChanged = true;
            return q;
        });

        if (fileMatches > 0) {
            totalMatches += fileMatches;
            if (!dryRun) {
                await fs.writeFile(filePath, JSON.stringify(newQuestions, null, 4), 'utf8');
                changedFilesCount++;
                results.push({ file, matches: fileMatches, status: 'Updated' });
            } else {
                results.push({ file, matches: fileMatches, changes });
            }
        }
    }
    return { success: true, totalMatches, changedFilesCount: dryRun ? 0 : changedFilesCount, dryRun, results };
}

async function analyzeTypos() {
    const files = await fs.readdir(QUESTIONS_DIR);
    const jsonFiles = files.filter(f => f.endsWith('.json'));
    const wordCounts = {};
    const wordFiles = {};
    for (const file of jsonFiles) {
        const filePath = path.join(QUESTIONS_DIR, file);
        const content = await fs.readFile(filePath, 'utf8');
        let questions;
        try { questions = JSON.parse(content); } catch { continue; }

        const extractWords = (text) => {
            if (!text) return;
            const clean = text.replace(/<[^>]*>/g, ' ').replace(/[0-9]/g, ' ').replace(/[.,;:"'?!()\[\]{}\-\/\\|]/g, ' ').toLowerCase();
            const words = clean.split(/\s+/);
            words.forEach(w => {
                if (w.length < 5) return;
                if (/^[a-z??????]+$/.test(w)) {
                    wordCounts[w] = (wordCounts[w] || 0) + 1;
                    if (!wordFiles[w]) wordFiles[w] = new Set();
                    wordFiles[w].add(file);
                }
            });
        };
        questions.forEach(q => {
            extractWords(q.q); extractWords(q.e);
            if (q.o && Array.isArray(q.o)) q.o.forEach(o => extractWords(o));
        });
    }
    const typos = Object.entries(wordCounts).filter(([vals, count]) => count === 1).map(([word, count]) => ({ word, files: Array.from(wordFiles[word]) })).sort((a, b) => a.word.localeCompare(b.word));
    return { totalWords: Object.keys(wordCounts).length, typos };
}

// ===================================================================
// AI SORU KONTROLCUSU (BATCH) - Grok 4.1 Fast
// ===================================================================

async function reviewQuestionsWithAI_Batch(questions, topicInfo) {
    const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY || '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';

    const allIssues = [];
    const BATCH_SIZE = 10;

    for (let i = 0; i < questions.length; i += BATCH_SIZE) {
        const batch = questions.slice(i, i + BATCH_SIZE);

        let questionsText = '';
        batch.forEach((q, idx) => {
            questionsText += `
--- SORU ${idx + 1} (ID: ${q.id}) ---
Metin: ${q.q}
A) ${q.o?.[0] || ''}
B) ${q.o?.[1] || ''}
C) ${q.o?.[2] || ''}
D) ${q.o?.[3] || ''}
E) ${q.o?.[4] || ''}
Dogru: ${['A', 'B', 'C', 'D', 'E'][q.a]}
Aciklama: ${q.e || 'YOK'}
`;
        });

        const prompt = `KPSS soru kalite kontrolcususun. ${batch.length} soruyu analiz et.

KONU: ${topicInfo.name} (${topicInfo.lesson})

${questionsText}

KONTROL: yazim hatasi, mantik hatasi, yanlis cevap, eksik aciklama

SADECE HATA OLAN SORULARI RAPORLA!

JSON FORMAT:
[{"id":"soru_id","hasIssue":true,"severity":"low/medium/high","issues":[{"type":"yazim/mantik/aciklama","description":"..."}],"suggestion":"..."}]

Hata yoksa bos array dondur: []
SADECE JSON dondur, baska bir sey yazma!`;

        try {
            const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
                    'Content-Type': 'application/json',
                    'HTTP-Referer': 'http://localhost:3456',
                    'X-Title': 'KPSS Question Review'
                },
                body: JSON.stringify({
                    model: 'x-ai/grok-4.1-fast',
                    messages: [{ role: 'user', content: prompt }],
                    temperature: 0.1,
                    max_tokens: 2000
                })
            });

            const data = await response.json();
            const aiContent = data.choices?.[0]?.message?.content || '';

            try {
                const jsonMatch = aiContent.match(/\[[\s\S]*\]/);
                if (jsonMatch) {
                    const results = JSON.parse(jsonMatch[0]);
                    results.forEach(r => {
                        if (r.hasIssue && r.id) {
                            const originalQ = batch.find(q => q.id === r.id);
                            allIssues.push({
                                questionId: r.id,
                                questionPreview: (originalQ?.q || '').substring(0, 80) + '...',
                                severity: r.severity || 'medium',
                                issues: r.issues || [],
                                suggestion: r.suggestion || ''
                            });
                        }
                    });
                }
            } catch (e) { console.log('JSON parse error:', e.message); }
        } catch (e) { console.log('API error:', e.message); }

        // Rate limiting
        if (i + BATCH_SIZE < questions.length) {
            await new Promise(r => setTimeout(r, 500));
        }
    }

    return allIssues;
}
