/**
 * â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
 * KPSS QUESTION MANAGEMENT SYSTEM v6.0 - ULTIMATE EDITION
 * â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
 * 
 * YENÄ° Ã–ZELLÄ°KLER:
 * âœ… Toplu AÃ§Ä±klama Ekleme
 * âœ… Soru TaÅŸÄ±ma/Kopyalama
 * âœ… Toplu DÃ¼zenleme
 * âœ… Zorluk Tahmini
 * âœ… DetaylÄ± PDF Rapor
 * âœ… Trend GrafiÄŸi
 * âœ… Eksik Ä°Ã§erik Listesi
 * âœ… Soru ÅablonlarÄ±
 * âœ… Otomatik Yedekleme
 * âœ… Flutter Sync Status
 * âœ… API DÃ¶kÃ¼mantasyonu
 */

const http = require('http');
const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { analyzeTypos } = require('./typo_helper');

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// GEMINI AI ENTEGRASYonu
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
let GoogleGenerativeAI;
try {
    GoogleGenerativeAI = require('@google/generative-ai').GoogleGenerativeAI;
} catch (e) {
    console.log('âš ï¸ @google/generative-ai paketi yÃ¼klÃ¼ deÄŸil. npm install @google/generative-ai');
}

// API Key - Environment variable veya hardcoded (geliÅŸtirme iÃ§in)
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || 'AIzaSyAp0eyAWPw7o1Mn9d8ZoA_hNcwiur0TIY8';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// AYARLAR
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
const PORT = 3456;
const QUESTIONS_DIR = path.join(__dirname, '..', 'assets', 'data', 'questions');
const BACKUP_DIR = path.join(__dirname, 'backups');
const PUBLIC_DIR = path.join(__dirname, 'public');
const TEMPLATES_FILE = path.join(__dirname, 'templates.json');
const HISTORY_FILE = path.join(__dirname, 'history.json');

// KlasÃ¶rleri oluÅŸtur
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TÃœM KONULAR
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
const TOPICS = {
    // MATEMATÄ°K (9 konu)
    'mat_temel_001': { name: 'Temel Kavramlar ve SayÄ±lar', lesson: 'MATEMATÄ°K', prefix: 'mat', order: 0 },
    'mat_rasyonel_001': { name: 'Rasyonel ve OndalÄ±klÄ± SayÄ±lar', lesson: 'MATEMATÄ°K', prefix: 'mat', order: 1 },
    'mat_esitsizlik_001': { name: 'Basit EÅŸitsizlikler ve Mutlak DeÄŸer', lesson: 'MATEMATÄ°K', prefix: 'mat', order: 2 },
    'mat_uslu_001': { name: 'ÃœslÃ¼ ve KÃ¶klÃ¼ SayÄ±lar', lesson: 'MATEMATÄ°K', prefix: 'mat', order: 3 },
    'mat_carpan_001': { name: 'Ã‡arpanlara AyÄ±rma', lesson: 'MATEMATÄ°K', prefix: 'mat', order: 4 },
    'mat_prob_001': { name: 'Problemler', lesson: 'MATEMATÄ°K', prefix: 'mat', order: 5 },
    'mat_kume_001': { name: 'KÃ¼meler ve Fonksiyonlar', lesson: 'MATEMATÄ°K', prefix: 'mat', order: 6 },
    'mat_olasilik_001': { name: 'PKOB', lesson: 'MATEMATÄ°K', prefix: 'mat', order: 7 },
    'mat_mantik_001': { name: 'SayÄ±sal MantÄ±k', lesson: 'MATEMATÄ°K', prefix: 'mat', order: 8 },
    // TARÄ°H (9 konu)
    'JnFbEQt0uA8RSEuy22SQ': { name: 'Ä°slamiyet Ã–ncesi TÃ¼rk Tarihi', lesson: 'TARÄ°H', prefix: 'tarih', order: 0 },
    '9Hg8tuMRdMTuVY7OZ9HL': { name: 'Ä°lk MÃ¼slÃ¼man TÃ¼rk Devletleri', lesson: 'TARÄ°H', prefix: 'tarih', order: 1 },
    '8aIrKLvItXrwvOHq1L34': { name: 'TÃ¼rkiye SelÃ§uklu Devleti', lesson: 'TARÄ°H', prefix: 'tarih', order: 2 },
    'JU0iGKNhR7NQzA8M77vt': { name: 'OsmanlÄ± Devleti Tarihi (Siyasi)', lesson: 'TARÄ°H', prefix: 'tarih', order: 3 },
    '9WTotPoDW5OuWxsCf4Li': { name: 'OsmanlÄ± Devleti Tarihi (KÃ¼ltÃ¼r)', lesson: 'TARÄ°H', prefix: 'tarih', order: 4 },
    'DlT19snCttf5j5RUAXLz': { name: 'KurtuluÅŸ SavaÅŸÄ± DÃ¶nemi', lesson: 'TARÄ°H', prefix: 'tarih', order: 5 },
    '4GUvpqBBImcLmN2eh1HK': { name: 'AtatÃ¼rk Ä°lke ve Ä°nkÄ±laplarÄ±', lesson: 'TARÄ°H', prefix: 'tarih', order: 6 },
    'onwrfsH02TgIhlyRUh56': { name: 'Cumhuriyet DÃ¶nemi', lesson: 'TARÄ°H', prefix: 'tarih', order: 7 },
    'xQWHl1hBYAKM96X4deR8': { name: 'Ã‡aÄŸdaÅŸ TÃ¼rk ve DÃ¼nya Tarihi', lesson: 'TARÄ°H', prefix: 'tarih', order: 8 },
    // TÃœRKÃ‡E (9 konu)
    '80e0wkTLvaTQzPD6puB7': { name: 'Ses Bilgisi', lesson: 'TÃœRKÃ‡E', prefix: 'turkce', order: 0 },
    'yWlh5C6jB7lzuJOodr2t': { name: 'YapÄ± Bilgisi', lesson: 'TÃœRKÃ‡E', prefix: 'turkce', order: 1 },
    'ICNDiSlTmmjWEQPT6rmT': { name: 'SÃ¶zcÃ¼k TÃ¼rleri', lesson: 'TÃœRKÃ‡E', prefix: 'turkce', order: 2 },
    'JmyiPxf3n96Jkxqsa9jY': { name: 'SÃ¶zcÃ¼kte Anlam', lesson: 'TÃœRKÃ‡E', prefix: 'turkce', order: 3 },
    'AJNLHhhaG2SLWOvxDYqW': { name: 'CÃ¼mlede Anlam', lesson: 'TÃœRKÃ‡E', prefix: 'turkce', order: 4 },
    'nN8JOTR7LZm01AN2i3sQ': { name: 'Paragrafta Anlam', lesson: 'TÃœRKÃ‡E', prefix: 'turkce', order: 5 },
    'jXcsrl5HEb65DmfpfqqI': { name: 'AnlatÄ±m BozukluklarÄ±', lesson: 'TÃœRKÃ‡E', prefix: 'turkce', order: 6 },
    'qSEqigIsIEBAkhcMTyCE': { name: 'YazÄ±m KurallarÄ±', lesson: 'TÃœRKÃ‡E', prefix: 'turkce', order: 7 },
    'wnt2zWaV1pX8p8s8BBc9': { name: 'SÃ¶zel MantÄ±k', lesson: 'TÃœRKÃ‡E', prefix: 'turkce', order: 8 },
    // COÄRAFYA (6 konu)
    '1FEcPsGduhjcQARpaGBk': { name: "TÃ¼rkiye'nin CoÄŸrafi Konumu", lesson: 'COÄRAFYA', prefix: 'cog', order: 0 },
    'kbs0Ffved9pCP3Hq9M9k': { name: "TÃ¼rkiye'nin Fiziki Ã–zellikleri", lesson: 'COÄRAFYA', prefix: 'cog', order: 1 },
    '6e0Thsz2RRNHFcwqQXso': { name: "TÃ¼rkiye'nin Ä°klimi", lesson: 'COÄRAFYA', prefix: 'cog', order: 2 },
    'uYDrMlBCEAho5776WZi8': { name: 'BeÅŸeri CoÄŸrafya', lesson: 'COÄRAFYA', prefix: 'cog', order: 3 },
    'WxrtQ26p2My4uJa0h1kk': { name: 'Ekonomik CoÄŸrafya', lesson: 'COÄRAFYA', prefix: 'cog', order: 4 },
    'GdpN8uxJNGtexWrkoL1T': { name: "TÃ¼rkiye'nin CoÄŸrafi BÃ¶lgeleri", lesson: 'COÄRAFYA', prefix: 'cog', order: 5 },
    // VATANDAÅLIK (6 konu)
    'AQ0Zph76dzPdr87H1uKa': { name: 'Hukuka GiriÅŸ', lesson: 'VATANDAÅLIK', prefix: 'vat', order: 0 },
    'n4OjWupHmouuybQzQ1Fc': { name: 'Anayasa Hukuku', lesson: 'VATANDAÅLIK', prefix: 'vat', order: 1 },
    'xXGXiqx2TkCtI4C7GMQg': { name: '1982 AnayasasÄ±', lesson: 'VATANDAÅLIK', prefix: 'vat', order: 2 },
    '1JZAYECyEn7farNNyGyx': { name: 'Devlet OrganlarÄ±', lesson: 'VATANDAÅLIK', prefix: 'vat', order: 3 },
    'lv93cmhwq7RmOFM5WxWD': { name: 'Ä°dari YapÄ±', lesson: 'VATANDAÅLIK', prefix: 'vat', order: 4 },
    'Bo3qqooJsqtIZrK5zc9S': { name: 'Temel Hak ve Ã–zgÃ¼rlÃ¼kler', lesson: 'VATANDAÅLIK', prefix: 'vat', order: 5 },
    // GÃœNCEL BÄ°LGÄ°LER (6 konu)
    'GUNCEL_BM_KURULUS': { name: 'BM ve BaÄŸlÄ± KuruluÅŸlar', lesson: 'GÃœNCEL BÄ°LGÄ°LER', prefix: 'guncel', order: 0 },
    'GUNCEL_NATO_AB': { name: 'NATO ve Avrupa BirliÄŸi', lesson: 'GÃœNCEL BÄ°LGÄ°LER', prefix: 'guncel', order: 1 },
    'GUNCEL_BOLGESEL_KURULUS': { name: 'BÃ¶lgesel KuruluÅŸlar', lesson: 'GÃœNCEL BÄ°LGÄ°LER', prefix: 'guncel', order: 2 },
    'GUNCEL_TURKIYE_KURULUS': { name: "TÃ¼rkiye'nin Ãœyelikleri", lesson: 'GÃœNCEL BÄ°LGÄ°LER', prefix: 'guncel', order: 3 },
    'GUNCEL_ONEMLI_TARIHLER': { name: 'Ã–nemli Tarihler', lesson: 'GÃœNCEL BÄ°LGÄ°LER', prefix: 'guncel', order: 4 },
    'GUNCEL_OLAYLAR': { name: 'GÃ¼ncel Olaylar', lesson: 'GÃœNCEL BÄ°LGÄ°LER', prefix: 'guncel', order: 5 }
};

// KPSS Hedef Soru SayÄ±larÄ±
const LESSON_TARGETS = {
    'TARÄ°H': { target: 300, weight: 0.20 },
    'COÄRAFYA': { target: 150, weight: 0.10 },
    'VATANDAÅLIK': { target: 150, weight: 0.10 },
    'TÃœRKÃ‡E': { target: 300, weight: 0.20 },
    'MATEMATÄ°K': { target: 300, weight: 0.20 },
    'GÃœNCEL BÄ°LGÄ°LER': { target: 100, weight: 0.10 }
};

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// YARDIMCI FONKSÄ°YONLAR
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

const sendJSON = (res, data, status = 200) => {
    res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(data));
};

const parseBody = (req) => new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
        try { resolve(body ? JSON.parse(body) : {}); }
        catch (e) { reject(new Error('JSON parse hatasÄ±')); }
    });
});

const loadQuestions = async (topicId) => {
    try {
        const data = await fs.readFile(path.join(QUESTIONS_DIR, `${topicId}.json`), 'utf8');
        return JSON.parse(data);
    } catch { return []; }
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

    // Son 1000 kaydÄ± tut
    history = history.slice(0, 1000);
    await fs.writeFile(HISTORY_FILE, JSON.stringify(history, null, 2), 'utf8');
};

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// KALÄ°TE & ZORLUK SKORU
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

function calculateQualityScore(q) {
    let score = 0;
    const details = [];

    const qLen = (q.q || '').length;
    if (qLen >= 100) { score += 20; details.push('âœ“ DetaylÄ± soru'); }
    else if (qLen >= 50) { score += 15; }
    else if (qLen >= 20) { score += 10; }

    if (q.e && q.e.length >= 50) { score += 25; details.push('âœ“ DetaylÄ± aÃ§Ä±klama'); }
    else if (q.e && q.e.length >= 20) { score += 15; }

    if (q.o && q.o.length === 5) {
        const lengths = q.o.map(o => (o || '').length);
        const avg = lengths.reduce((a, b) => a + b, 0) / 5;
        const variance = lengths.reduce((sum, l) => sum + Math.pow(l - avg, 2), 0) / 5;
        if (variance < 100) { score += 20; }
        else if (variance < 500) { score += 10; }
    }

    if (/[.?!:]$/.test((q.q || '').trim())) { score += 10; }

    const negatives = ['deÄŸildir', 'yoktur', 'olamaz', 'olmaz'];
    const hasNegative = negatives.some(n => (q.q || '').toLowerCase().includes(n));
    const hasEmphasis = negatives.some(n => (q.q || '').includes(n.toUpperCase()));
    if (!hasNegative || hasEmphasis) { score += 10; }

    if (q.o && q.o.every(o => o && o.trim().length >= 2)) { score += 15; }

    return { score, maxScore: 100, percentage: score, details };
}

function calculateDifficultyScore(q) {
    let difficulty = 50; // Orta baÅŸlangÄ±Ã§
    const factors = [];

    const qLen = (q.q || '').length;
    if (qLen > 200) { difficulty += 15; factors.push('Uzun soru metni'); }
    else if (qLen > 100) { difficulty += 5; }
    else if (qLen < 50) { difficulty -= 10; factors.push('KÄ±sa soru'); }

    // Ã–ncÃ¼llÃ¼ soru kontrolÃ¼
    if (/\b(I|II|III|IV|V)\./g.test(q.q || '')) {
        difficulty += 10;
        factors.push('Ã–ncÃ¼llÃ¼ soru');
    }

    // Olumsuz kÃ¶k
    const negatives = ['deÄŸildir', 'yoktur', 'olamaz', 'yanlÄ±ÅŸ'];
    if (negatives.some(n => (q.q || '').toLowerCase().includes(n))) {
        difficulty += 5;
        factors.push('Olumsuz kÃ¶k');
    }

    // ÅÄ±k uzunluklarÄ±
    if (q.o) {
        const avgOptLen = q.o.reduce((s, o) => s + (o || '').length, 0) / 5;
        if (avgOptLen > 50) { difficulty += 10; factors.push('Uzun ÅŸÄ±klar'); }
        else if (avgOptLen < 10) { difficulty -= 5; }
    }

    // "Hangisi/hangileri" kontrolÃ¼
    if (/hangile?ri?/i.test(q.q || '')) {
        difficulty += 5;
    }

    difficulty = Math.max(10, Math.min(100, difficulty));

    let level = 'Orta';
    if (difficulty >= 70) level = 'Zor';
    else if (difficulty <= 40) level = 'Kolay';

    return { score: difficulty, level, factors };
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Ä°STATÄ°STÄ°KLER & ANALÄ°Z
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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

// Eksik iÃ§erik analizi
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

    // Son 30 gÃ¼nlÃ¼k veri
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const recentHistory = history.filter(h => new Date(h.timestamp) > thirtyDaysAgo);

    // GÃ¼nlÃ¼k ekleme sayÄ±larÄ±
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// ÅABLONLAR
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

async function loadTemplates() {
    try {
        const data = await fs.readFile(TEMPLATES_FILE, 'utf8');
        return JSON.parse(data);
    } catch {
        // VarsayÄ±lan ÅŸablonlar
        return [
            {
                id: 'standard',
                name: 'Standart Soru',
                template: { q: '', o: ['', '', '', '', ''], a: 0, e: '' }
            },
            {
                id: 'oncul',
                name: 'Ã–ncÃ¼llÃ¼ Soru (I, II, III)',
                template: {
                    q: 'I. Birinci madde\nII. Ä°kinci madde\nIII. ÃœÃ§Ã¼ncÃ¼ madde\n\nYukarÄ±dakilerden hangileri doÄŸrudur?',
                    o: ['YalnÄ±z I', 'YalnÄ±z II', 'I ve II', 'II ve III', 'I, II ve III'],
                    a: 4,
                    e: ''
                }
            },
            {
                id: 'dogruyanlÄ±ÅŸ',
                name: 'DoÄŸru/YanlÄ±ÅŸ Analizi',
                template: {
                    q: 'AÅŸaÄŸÄ±daki ifadelerden hangisi yanlÄ±ÅŸtÄ±r?',
                    o: ['', '', '', '', ''],
                    a: 0,
                    e: ''
                }
            },
            {
                id: 'paragraf',
                name: 'Paragraf Sorusu',
                template: {
                    q: '[PARAGRAF]\n\nYukarÄ±daki paragrafta anlatÄ±lmak istenen nedir?',
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TOPLU Ä°ÅLEMLER
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

// Toplu aÃ§Ä±klama ekleme
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

// Soru taÅŸÄ±ma
async function moveQuestion(fromTopicId, toTopicId, questionId) {
    const fromQuestions = await loadQuestions(fromTopicId);
    const toQuestions = await loadQuestions(toTopicId);

    const idx = fromQuestions.findIndex(q => q.id === questionId);
    if (idx === -1) throw new Error('Soru bulunamadÄ±');

    await createBackup(fromTopicId, fromQuestions);
    await createBackup(toTopicId, toQuestions);

    const question = fromQuestions.splice(idx, 1)[0];

    // Yeni ID oluÅŸtur
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
    if (!original) throw new Error('Soru bulunamadÄ±');

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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// VALÄ°DASYON
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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
    return (text || '').toLowerCase().replace(/[^a-z0-9ÅŸÄŸÃ¼Ã¶Ã§Ä±Ä°\s]/gi, '').replace(/\s+/g, ' ').trim();
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

        if (!qText) errors.push({ field: 'q', msg: 'Soru metni boÅŸ!' });
        else if (qText.length < 20) errors.push({ field: 'q', msg: `Soru Ã§ok kÄ±sa (${qText.length} kar.)` });

        if (!q.o || !Array.isArray(q.o) || q.o.length !== 5) {
            errors.push({ field: 'o', msg: '5 seÃ§enek olmalÄ±!' });
        } else {
            q.o.forEach((opt, i) => {
                if (!opt || opt.trim().length === 0) {
                    errors.push({ field: `o[${i}]`, msg: `${['A', 'B', 'C', 'D', 'E'][i]} ÅŸÄ±kkÄ± boÅŸ!` });
                }
            });
        }

        if (q.a === undefined || q.a < 0 || q.a > 4) {
            errors.push({ field: 'a', msg: 'DoÄŸru cevap 0-4 arasÄ± olmalÄ±!' });
        }

        const normQ = normalizeText(qText);
        if (seenInBatch.has(normQ)) {
            errors.push({ field: 'q', msg: 'Batch iÃ§inde tekrar!' });
        } else {
            seenInBatch.add(normQ);
        }

        for (const existing of existingQuestions) {
            const sim = calculateSimilarity(qText, existing.q);
            if (sim >= 90) {
                errors.push({ field: 'q', msg: `Mevcut soruyla %${sim} aynÄ±!` });
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// CSV PARSER
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// v7.0 YENÄ° Ã–ZELLÄ°KLER
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

// TARGETS dosyasÄ±
const TARGETS_FILE = path.join(__dirname, 'targets.json');

// Hedefleri yÃ¼kle
async function loadTargets() {
    try {
        const data = await fs.readFile(TARGETS_FILE, 'utf8');
        return JSON.parse(data);
    } catch {
        // VarsayÄ±lan hedefler
        return {
            'TARÄ°H': 300,
            'COÄRAFYA': 150,
            'VATANDAÅLIK': 150,
            'TÃœRKÃ‡E': 300,
            'MATEMATÄ°K': 300,
            'GÃœNCEL BÄ°LGÄ°LER': 100
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

    // TÃ¼m sorularÄ± yÃ¼kle
    for (const [topicId, topicInfo] of Object.entries(TOPICS)) {
        const questions = await loadQuestions(topicId);
        questions.forEach(q => {
            // Kelimeleri Ã¶nceden hesapla
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

            // HÄ±zlÄ± word overlap similarity
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

// Word Cloud - En Ã§ok geÃ§en kelimeler
async function generateWordCloud(topicId = null, limit = 50) {
    const stopWords = new Set([
        've', 'veya', 'ile', 'iÃ§in', 'bir', 'bu', 'ÅŸu', 'o', 'de', 'da', 'den', 'dan',
        'ne', 'mi', 'mÄ±', 'mu', 'mÃ¼', 'ki', 'gibi', 'kadar', 'daha', 'en', 'Ã§ok',
        'olan', 'olarak', 'ise', 'ya', 'hem', 'ama', 'fakat', 'ancak', 'Ã§Ã¼nkÃ¼',
        'hangisi', 'hangisinde', 'hangileri', 'aÅŸaÄŸÄ±dakilerden', 'yukarÄ±dakilerden',
        'aÅŸaÄŸÄ±da', 'yukarÄ±da', 'verilen', 'verilenlerden', 'gÃ¶re', 'doÄŸru', 'yanlÄ±ÅŸ',
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
                .replace(/[^a-zÅŸÄŸÃ¼Ã¶Ã§Ä±\s]/gi, '')
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

// Flutter Sync Check - JSON dosyalarÄ±nÄ±n Flutter app ile uyumluluÄŸunu kontrol et
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
            if (!q.q || typeof q.q !== 'string') qIssues.push('q (soru) geÃ§ersiz');
            if (!q.o || !Array.isArray(q.o) || q.o.length !== 5) qIssues.push('o (seÃ§enekler) 5 elemanlÄ± dizi olmalÄ±');
            if (q.a === undefined || typeof q.a !== 'number' || q.a < 0 || q.a > 4) qIssues.push('a (cevap) 0-4 arasÄ± sayÄ± olmalÄ±');

            // Type checks
            if (q.e && typeof q.e !== 'string') qIssues.push('e (aÃ§Ä±klama) string olmalÄ±');
            if (q.topicId && q.topicId !== topicId) qIssues.push('topicId uyumsuz');

            // Turkish character check
            const hasInvalidChars = /[\x00-\x08\x0B\x0C\x0E-\x1F]/.test(q.q || '');
            if (hasInvalidChars) qIssues.push('GeÃ§ersiz karakter iÃ§eriyor');

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
        issues: issues.slice(0, 50) // Ä°lk 50 sorunu gÃ¶ster
    };
}

// HatalÄ± format sorularÄ± bul (ÅŸÄ±klar soru metninde olanlar)
async function findMalformedQuestions() {
    const malformed = [];

    // Daha geniÅŸ pattern'ler - A), A., A-, A: formatlarÄ±
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

            // Soru metninde ÅŸÄ±k var mÄ±?
            for (const pattern of optionPatterns) {
                if (pattern.test(q.q || '')) {
                    issues.push('Soru metninde ÅŸÄ±k harfi var (A), B), vs.)');
                    break;
                }
            }

            // Soru metni Ã§ok kÄ±sa mÄ±?
            const wordCount = (q.q || '').split(/\s+/).length;
            if (wordCount < 10) {
                issues.push(`Soru metni Ã§ok kÄ±sa (${wordCount} kelime)`);
            }

            // ÅÄ±klar eksik veya yanlÄ±ÅŸ mÄ±?
            if (!q.o || q.o.length !== 5) {
                issues.push('ÅÄ±k sayÄ±sÄ± 5 deÄŸil');
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

// Bulk Edit - Toplu dÃ¼zenleme
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// GEMINI AI SORU URETIMI
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

const SUBJECT_PREFIXES = {
    'TARÄ°H': 'tarih',
    'COÄRAFYA': 'cog',
    'TÃœRKÃ‡E': 'turkce',
    'VATANDAÅLIK': 'vat',
    'MATEMATÄ°K': 'mat',
    'GÃœNCEL BÄ°LGÄ°LER': 'guncel'
};

async function generateQuestionsWithAI(topicId, topic, lesson, count = 10, difficulty = 'Orta', cognitiveLevel = 'Karma') {
    const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY || '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';

    if (!OPENROUTER_API_KEY || OPENROUTER_API_KEY === 'YOUR_OPENROUTER_API_KEY') {
        throw new Error('OpenRouter API key ayarlanmamis. Lutfen API key girin.');
    }

    const prefix = SUBJECT_PREFIXES[lesson] || 'kpss';
    const timestamp = Date.now();

    // BiliÅŸsel dÃ¼zey aÃ§Ä±klamalarÄ±
    const cognitiveLevelGuide = {
        'Bilgi': `SORU TÄ°PÄ°: BÄ°LGÄ° & KAVRAMA
    - DoÄŸrudan bilgi sorularÄ± (kim, ne, ne zaman, nerede)
    - TanÄ±m ve kavram sorularÄ±
    - SÄ±ralama ve eÅŸleÅŸtirme sorularÄ±
    - "AÅŸaÄŸÄ±dakilerden hangisi...?" formatÄ±`,
        'Analiz': `SORU TÄ°PÄ°: ANALÄ°Z & YORUM
    - Ã–ncÃ¼llÃ¼ sorular ("I. ... II. ... III. ... YukarÄ±dakilerden hangileri doÄŸrudur?")
    - KarÅŸÄ±laÅŸtÄ±rma sorularÄ±
    - Neden-sonuÃ§ iliÅŸkisi sorularÄ±
    - "Buna gÃ¶re..." ile baÅŸlayan yorumlama sorularÄ±`,
        'Senaryo': `SORU TÄ°PÄ°: SENARYO & UYGULAMA
    - Durum/olay senaryolarÄ± ("Tarih Ã¶ÄŸretmeni Ahmet Bey...")
    - GÃ¼ncel hayat Ã¶rnekleri
    - Problem Ã§Ã¶zme sorularÄ±
    - "Bu durumda..." formatÄ±
    - Ã–ÄŸrenci/vatandaÅŸ perspektifli sorular`,
        'Karma': `SORU TÄ°PLERÄ°: KARMA (TÃœM TÄ°PLER)
    AÅŸaÄŸÄ±daki tiplerin karÄ±ÅŸÄ±mÄ±nÄ± kullan:
    1. Bilgi sorusu (2-3 adet): DoÄŸrudan bilgi
    2. Ã–ncÃ¼llÃ¼ soru (2-3 adet): "I. II. III. YukarÄ±dakilerden hangileri..."
    3. Analiz sorusu (2-3 adet): KarÅŸÄ±laÅŸtÄ±rma ve yorum
    4. Senaryo sorusu (2-3 adet): Durumsal, uygulamalÄ±`
    };

    // Zorluk seviyesi aÃ§Ä±klamalarÄ±
    const difficultyGuide = {
        'Kolay': `ZORLUK: KOLAY (BaÅŸlangÄ±Ã§)
    - Temel ve bilinen kavramlar
    - Direkt hatÄ±rlama gerektiren sorular  
    - KarÄ±ÅŸtÄ±rÄ±cÄ± ÅŸÄ±klar az
    - Net ve anlaÅŸÄ±lÄ±r ifadeler`,
        'Orta': `ZORLUK: ORTA (Ã–SYM Standart)
    - Ã–SYM sÄ±nav standardÄ±nda
    - Dikkatli okuma gerektiren
    - BazÄ± ÅŸÄ±klar birbirine yakÄ±n
    - Detay bilgisi gerektiren`,
        'Zor': `ZORLUK: ZOR (SeÃ§ici/AyÄ±rt Edici)
    - Derin analiz gerektiren
    - Ã‡oklu bilgi sentezi
    - ÅÄ±klar Ã§ok yakÄ±n ve yanÄ±ltÄ±cÄ±
    - Ä°stisna ve Ã¶zel durumlar
    - "Hangisi yanlÄ±ÅŸtÄ±r?" formatlarÄ±`
    };

    const prompt = `ROL: Sen Ã–SYM'de 20 yÄ±l Ã§alÄ±ÅŸmÄ±ÅŸ, binlerce KPSS sorusu yazmÄ±ÅŸ kÄ±demli bir soru yazarÄ±sÄ±n.

    GÃ–REV: ${lesson} dersi - "${topic}" konusu iÃ§in ${count} adet PROFESYONEL KPSS sÄ±navÄ± sorusu yaz.

    â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    ${difficultyGuide[difficulty] || difficultyGuide['Orta']}
    â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    ${cognitiveLevelGuide[cognitiveLevel] || cognitiveLevelGuide['Karma']}
    â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    Ã–SYM SORU YAZIM STANDARTLARI:
    1. SORU KÃ–KLERÄ°:
    - "AÅŸaÄŸÄ±dakilerden hangisi ... deÄŸildir?"
    - "Buna gÃ¶re aÅŸaÄŸÄ±dakilerden hangisi sÃ¶ylenebilir?"
    - "YukarÄ±daki bilgilere gÃ¶re..."
    - "I. ... II. ... III. ... YukarÄ±dakilerden hangileri doÄŸrudur?"

    2. SEÃ‡ENEK YAPISI:
    - 5 seÃ§enek ZORUNLU (A, B, C, D, E)
    - SeÃ§enekler birbirine yakÄ±n uzunlukta
    - En az 2 seÃ§enek yanÄ±ltÄ±cÄ± (plausible)
    - DoÄŸru cevap rastgele daÄŸÄ±lmalÄ± (A=2, B=2, C=2, D=2, E=2 gibi)

    3. Ã–NCÃœLLÃœ SORULAR:
    - En az ${Math.floor(count / 3)} soru Ã¶ncÃ¼llÃ¼ olmalÄ±
    - Format: "I. [ifade] II. [ifade] III. [ifade]"
    - ÅÄ±klar: "YalnÄ±z I", "I ve II", "I ve III", "II ve III", "I, II ve III"

    4. AÃ‡IKLAMALAR (KPSS HOCASI GÄ°BÄ° KISA VE Ã–Z):
    - 1-2 cÃ¼mle ile doÄŸru cevabÄ± aÃ§Ä±kla
    - Gereksiz detay verme, sadece Ã¶ÄŸrencinin bilmesi gereken bilgiyi yaz
    - Ã–rnek: "DoÄŸru cevap C. Kavimler GÃ¶Ã§Ã¼ 375'te baÅŸlamÄ±ÅŸtÄ±r."
    - YanlÄ±ÅŸ ÅŸÄ±klarÄ± tek tek aÃ§Ä±klama, sadece doÄŸruyu belirt

    YASAKLAR:
    âŒ Ã‡ok basit veya ezber sorular
    âŒ AynÄ± ÅŸÄ±k yapÄ±sÄ±nÄ±n tekrarÄ±
    âŒ MantÄ±ksÄ±z veya alakasÄ±z ÅŸÄ±klar
    âŒ Hep aynÄ± doÄŸru cevap (A veya D gibi)
    âŒ SORU METNÄ°NDE (q alanÄ±nda) ÅIK YAZMA! ÅÄ±klar SADECE "o" array'inde olmalÄ±!
    âŒ KÄ±sa soru metni yazma - en az 2-3 cÃ¼mle olmalÄ±

    Ã–NEMLÄ° FORMAT KURALLARI:
    - "q" alanÄ±: SADECE soru metni (A), B), C) vb. OLMAMALI!)
    - "o" alanÄ±: 5 ÅŸÄ±k array olarak ["ÅŸÄ±k1", "ÅŸÄ±k2", "ÅŸÄ±k3", "ÅŸÄ±k4", "ÅŸÄ±k5"]
    - Soru metni uzun ve detaylÄ± olmalÄ± (en az 30 kelime)

    JSON FORMATI (SADECE bu formatta, baÅŸka bir ÅŸey yazma):
    {
    "questions": [
        {
        "id": "${prefix}_${timestamp}_001",
        "topicId": "${topicId}",
        "subtopicId": "alt-konu-slug-formati",
        "subtopic": "Alt Konu BaÅŸlÄ±ÄŸÄ±",
        "q": "1071 yÄ±lÄ±nda gerÃ§ekleÅŸen Malazgirt SavaÅŸÄ±, TÃ¼rk tarihinde Ã¶nemli bir dÃ¶nÃ¼m noktasÄ±dÄ±r. Bu savaÅŸta SelÃ§uklu SultanÄ± Alparslan, Bizans Ä°mparatoru Romen Diyojen'i yenilgiye uÄŸratmÄ±ÅŸtÄ±r. Bu zafer sonucunda Anadolu'nun kapÄ±larÄ± TÃ¼rklere aÃ§Ä±lmÄ±ÅŸtÄ±r. Malazgirt SavaÅŸÄ±'nÄ±n sonuÃ§larÄ± ile ilgili aÅŸaÄŸÄ±dakilerden hangisi yanlÄ±ÅŸtÄ±r?",
        "o": ["Anadolu'ya TÃ¼rk gÃ¶Ã§leri hÄ±zlanmÄ±ÅŸtÄ±r", "Bizans Ä°mparatorluÄŸu zayÄ±flamÄ±ÅŸtÄ±r", "HaÃ§lÄ± Seferleri baÅŸlamÄ±ÅŸtÄ±r", "TÃ¼rkiye SelÃ§uklu Devleti kurulmuÅŸtur", "Anadolu'da ilk TÃ¼rk beylikleri kurulmuÅŸtur"],
        "a": 2,
        "e": "DoÄŸru cevap C. HaÃ§lÄ± Seferleri 1096'da baÅŸlamÄ±ÅŸ olup Malazgirt'in doÄŸrudan sonucu deÄŸildir."
        }
    ]
    }`;

    // Model listesi - ilki baÅŸarÄ±sÄ±z olursa sonrakini dene
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

    // TÃ¼m modeller baÅŸarÄ±sÄ±z
    throw new Error('Tum modeller basarisiz: ' + lastError?.message);
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// API DÃ–KÃœMANTASYONU
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

const API_DOCS = {
    info: {
        title: 'KPSS Question Management API',
        version: '7.0',
        description: 'KPSS soru yÃ¶netim sistemi API\'si - Ultimate Edition'
    },
    endpoints: [
        { method: 'GET', path: '/topics', desc: 'TÃ¼m konularÄ± listeler' },
        { method: 'GET', path: '/stats', desc: 'Genel istatistikleri dÃ¶ner' },
        { method: 'GET', path: '/gaps', desc: 'Eksik iÃ§erik analizini dÃ¶ner' },
        { method: 'GET', path: '/trends', desc: 'Son 30 gÃ¼nlÃ¼k trend verisi' },
        { method: 'GET', path: '/questions/:topicId', desc: 'Konuya ait sorularÄ± dÃ¶ner' },
        { method: 'POST', path: '/validate', desc: 'SorularÄ± valide eder' },
        { method: 'POST', path: '/add', desc: 'Yeni sorular ekler' },
        { method: 'PUT', path: '/questions/:topicId/:id', desc: 'Soru gÃ¼nceller' },
        { method: 'DELETE', path: '/questions/:topicId/:id', desc: 'Soru siler' },
        { method: 'POST', path: '/move', desc: 'Soruyu baÅŸka konuya taÅŸÄ±r' },
        { method: 'POST', path: '/copy', desc: 'Soruyu baÅŸka konuya kopyalar' },
        { method: 'POST', path: '/bulk-delete', desc: 'Toplu soru siler' },
        { method: 'POST', path: '/bulk-explanation', desc: 'Toplu aÃ§Ä±klama ekler' },
        { method: 'POST', path: '/bulk-edit', desc: 'Toplu soru dÃ¼zenler' },
        { method: 'GET', path: '/templates', desc: 'Soru ÅŸablonlarÄ±nÄ± dÃ¶ner' },
        { method: 'POST', path: '/templates', desc: 'Yeni ÅŸablon ekler' },
        { method: 'GET', path: '/backups/:topicId', desc: 'Backup listesini dÃ¶ner' },
        { method: 'POST', path: '/restore/:filename', desc: 'Backup\'tan geri yÃ¼kler' },
        { method: 'GET', path: '/search', desc: 'Soru arar (?q=...&lesson=...)' },
        { method: 'POST', path: '/import-csv', desc: 'CSV\'den import eder' },
        { method: 'GET', path: '/api-docs', desc: 'Bu API dÃ¶kÃ¼mantasyonu' },
        { method: 'GET', path: '/duplicates', desc: 'Benzer sorularÄ± bulur (?threshold=75)' },
        { method: 'GET', path: '/wordcloud', desc: 'Kelime bulutu (?topicId=...&limit=50)' },
        { method: 'GET', path: '/flutter-sync', desc: 'Flutter uyumluluk kontrolÃ¼' },
        { method: 'GET', path: '/targets', desc: 'Hedef soru sayÄ±larÄ±nÄ± dÃ¶ner' },
        { method: 'POST', path: '/targets', desc: 'Hedef soru sayÄ±larÄ±nÄ± gÃ¼nceller' }
    ]
};

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// HTTP SERVER
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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
                return sendJSON(res, { success: false, error: 'Soru bulunamadÄ±' }, 404);
            }

            await createBackup(topicId, questions);
            questions[idx] = { ...questions[idx], ...updates, id: questionId, topicId };
            await saveQuestions(topicId, questions);
            await logHistory('edit', { topicId, questionId });

            return sendJSON(res, {
                success: true,
                message: 'Soru gÃ¼ncellendi',
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
                return sendJSON(res, { success: false, error: 'Soru bulunamadÄ±' }, 404);
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
                return sendJSON(res, { success: false, error: 'GeÃ§ersiz konu ID' }, 400);
            }

            const existing = await loadQuestions(topicId);

            if (existing.length > 0) {
                await createBackup(topicId, existing);
            }

            const validation = validateQuestions(questions, existing);

            if (validation.stats.errors > 0) {
                return sendJSON(res, {
                    success: false,
                    error: `${validation.stats.errors} soru hatalÄ±!`,
                    validation
                }, 400);
            }

            const withIds = generateIds(questions, topicId, existing);
            const merged = [...existing, ...withIds];
            await saveQuestions(topicId, merged);
            await logHistory('add', { topicId, count: questions.length });

            return sendJSON(res, {
                success: true,
                message: `${questions.length} soru baÅŸarÄ±yla eklendi!`,
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
                return sendJSON(res, { success: false, error: 'GeÃ§ersiz konu ID' }, 400);
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
                    message: `${questions.length} soru geri yÃ¼klendi`,
                    count: questions.length
                });
            } catch (e) {
                return sendJSON(res, { success: false, error: e.message }, 500);
            }
        }

        // GET /malformed - HatalÄ± format sorularÄ± bul
        if (pathname === '/malformed' && req.method === 'GET') {
            const malformed = await findMalformedQuestions();
            return sendJSON(res, {
                count: malformed.length,
                malformed: malformed.slice(0, 100)
            });
        }

        // POST /replace-text - Toplu Metin DeÄŸiÅŸtirme
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

        // GET /analyze-typos - YazÄ±m HatasÄ± Analizi
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

        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // v7.0 NEW ENDPOINTS
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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

        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
        // AI SORU URETIMI ENDPOINTS
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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
        // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

        // GET /git-status - meto reposundaki Git durumunu kontrol et
        if (pathname === '/git-status' && req.method === 'GET') {
            const metoDir = path.join(__dirname, '..', '..', 'meto-data');

            try {
                // Ã–nce meto klasÃ¶rÃ¼ var mÄ± kontrol et
                if (!fsSync.existsSync(metoDir)) {
                    return sendJSON(res, {
                        success: false,
                        error: 'meto-data klasÃ¶rÃ¼ bulunamadÄ±. LÃ¼tfen Ã¶nce repoyu klonlayÄ±n.'
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

        // POST /git-push - SorularÄ± meto reposuna gÃ¶nder
        if (pathname === '/git-push' && req.method === 'POST') {
            const metoDir = path.join(__dirname, '..', '..', 'meto-data');
            const sourceDir = QUESTIONS_DIR;
            const targetDir = path.join(metoDir, 'questions');
            const { message } = await parseBody(req);
            const commitMsg = message || `Soru guncelleme - ${new Date().toLocaleDateString('tr-TR')}`;

            try {
                // 1. Soru dosyalarÄ±nÄ± meto klasÃ¶rÃ¼ne kopyala
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
                        if (error) reject(new Error('Git add hatasÄ±: ' + error.message));
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
                    exec('git push origin main', { cwd: metoDir }, (error, stdout, stderr) => {
                        if (error) reject(new Error('Git push hatasÄ±: ' + error.message));
                        else resolve(stdout || stderr || 'Push baÅŸarÄ±lÄ±');
                    });
                });

                await logHistory('git_push', { message: commitMsg, copiedFiles: copiedCount });

                return sendJSON(res, {
                    success: true,
                    message: 'meto reposuna baÅŸarÄ±yla gÃ¶nderildi! ğŸš€',
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// START
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

server.listen(PORT, () => {
    console.log(`
â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
â•‘  ğŸ“š KPSS QUESTION MANAGEMENT SYSTEM v7.0 - ULTIMATE                       â•‘
â•‘  â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•  â•‘
â•‘                                                                           â•‘
â•‘  ğŸ“ http://localhost:${PORT}                                                â•‘
â•‘                                                                           â•‘
â•‘  ğŸ†• v7.0 YENÄ° Ã–ZELLÄ°KLER:                                                  â•‘
â•‘     â€¢ Duplicate Finder (/duplicates)                                      â•‘
â•‘     â€¢ Word Cloud (/wordcloud)                                             â•‘
â•‘     â€¢ Flutter Sync Check (/flutter-sync)                                  â•‘
â•‘     â€¢ Custom Targets (/targets)                                           â•‘
â•‘     â€¢ Bulk Edit Mode (/bulk-edit)                                         â•‘
â•‘                                                                           â•‘
â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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


