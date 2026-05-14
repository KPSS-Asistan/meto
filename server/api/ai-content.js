/**
 * AI Content API - OpenRouter Entegrasyonlu
 * Explanations, Stories, Flashcards, Matching Games üretimi
 * Onaylı üretim sistemi: Taslak → Onay → Canlıya Al
 */
const fs = require('fs');
const path = require('path');
const https = require('https');
const { sendJSON, parseBody } = require('../utils/helper');
const { pushAllRemotes } = require('./sync');
const { DATA_DIR, EXPLANATIONS_DIR, STORIES_DIR, FLASHCARDS_DIR, MATCHING_GAMES_DIR, PRODUCTIVITY_DIR, QUESTIONS_DIR, DRAFT_BASE, COST_LOG_FILE, NIGHTLY_CONFIG_FILE, GECMIS_SORULAR_PATH, TOPICS_FILE } = require('../config');


// ─── Async Job Queue ───
const _activeJobs = new Map();

// ─── Maliyet Takibi ───
// Fallback sırası: Kalite > Fiyat dengesi (2026 Nisan)
// 1. DeepSeek V3.2 — GPT-5 sınıfı, çok ucuz, instruction-following güçlü
// 2. Gemini 3 Flash Preview — Pro seviyesi reasoning, hızlı
// 3. Gemini 2.5 Flash — kararlı, thinking modu
// 4. Grok 4.1 Fast — 2M context agentic, ucuz
// 5. Gemini 2.5 Flash Lite — son çare, hızlı+ucuz
// Hız/kalite dengesi için sıralanmış fallback listesi.
// Test sonuçları (10 soru üretimi, 2026-04-16):
//   gemini-2.5-flash        : 451ms ✓ 10/10 soru  ← EN HIZLI & GÜVENİLİR
//   grok-4.1-fast           : 580ms (bazen JSON bozuk)
//   gemini-3-flash-preview  : 968ms ✓ 10/10 soru
//   gemini-2.5-flash-lite   : 1155ms ✓ 10/10 soru
//   deepseek-v3.2           : 1942ms ✓ 10/10 soru (reasoning OFF'ta kesilir → ON tutulur)
const FALLBACK_MODELS = [
    'openai/gpt-5-nano',
    'openai/gpt-5.4-nano',
    'openai/gpt-5-mini',
    'google/gemini-2.5-flash',
    'google/gemini-3-flash-preview',
    'deepseek/deepseek-v3.2',
    'google/gemini-2.5-flash-lite',
];

// $/M token (input/output) — 2026 Nisan güncel OpenRouter fiyatları
const MODEL_PRICES = {
    // ⭐ TOP TIER — KPSS için önerilenler (kalite + fiyat)
    'deepseek/deepseek-v3.2': { input: 0.26, output: 0.38 }, // EN İYİ DEĞER
    'google/gemini-3-flash-preview': { input: 0.50, output: 3.00 }, // Yüksek kalite
    'minimax/minimax-m2.5': { input: 0.118, output: 0.99 }, // Coding+ofis
    'minimax/minimax-m2.7': { input: 0.30, output: 1.20 }, // Agentic SOTA
    'google/gemini-2.5-flash': { input: 0.30, output: 2.50 }, // Kararlı
    'x-ai/grok-4.1-fast': { input: 0.20, output: 0.50 }, // 2M context

    // 🆓 ÜCRETSİZ
    'nvidia/nemotron-3-super-120b-a12b:free': { input: 0, output: 0 }, // 120B MoE

    // 💰 BUDGET (hızlı, ucuz ama instruction-following orta)
    'google/gemini-2.5-flash-lite': { input: 0.10, output: 0.40 },
    'google/gemini-3.1-flash-lite-preview': { input: 0.25, output: 1.50 },
    'moonshotai/kimi-k2.5': { input: 0.38, output: 1.72 },
    'openai/gpt-5-nano': { input: 0.05, output: 0.40 },
    'openai/gpt-5.4-nano': { input: 0.20, output: 1.25 },
    'openai/gpt-5-mini': { input: 0.25, output: 2.00 },
    'openai/gpt-4o-mini': { input: 0.15, output: 0.60 },

    // 👑 PREMIUM
    'openai/gpt-5.2': { input: 1.75, output: 14.00 },
    'google/gemini-3.1-pro-preview': { input: 2.00, output: 12.00 },
    'anthropic/claude-haiku-4.5': { input: 1.00, output: 5.00 },
    'anthropic/claude-sonnet-4.6': { input: 3.00, output: 15.00 },

    // 📦 ESKİ (geriye uyumluluk)
    'anthropic/claude-3.5-sonnet': { input: 3.00, output: 15.00 },
    'anthropic/claude-3-haiku': { input: 0.25, output: 1.25 },
    'anthropic/claude-3.5-haiku': { input: 0.80, output: 4.00 },
    'openai/gpt-4o': { input: 5.00, output: 15.00 },
    'google/gemini-2.0-flash-001': { input: 0.10, output: 0.40 },
    'google/gemini-flash-1.5': { input: 0.075, output: 0.30 },
    'meta-llama/llama-3.3-70b-instruct': { input: 0.59, output: 0.79 },
};
const USD_TO_TL = 38.5;

function logApiCost(model, promptTokens, completionTokens, context = {}) {
    const prices = MODEL_PRICES[model] || { input: 2.0, output: 8.0 };
    const costUsd = (promptTokens * prices.input + completionTokens * prices.output) / 1_000_000;
    const costTl = costUsd * USD_TO_TL;
    const entry = {
        timestamp: new Date().toISOString(),
        model,
        promptTokens,
        completionTokens,
        costUsd: parseFloat(costUsd.toFixed(6)),
        costTl: parseFloat(costTl.toFixed(4)),
        ...context
    };
    let log = [];
    try { if (fs.existsSync(COST_LOG_FILE)) log = JSON.parse(fs.readFileSync(COST_LOG_FILE, 'utf8')); } catch { }
    log.unshift(entry);
    fs.writeFileSync(COST_LOG_FILE, JSON.stringify(log.slice(0, 2000), null, 2), 'utf8');
    return entry;
}

function readNightlyConfig() {
    try { if (fs.existsSync(NIGHTLY_CONFIG_FILE)) return JSON.parse(fs.readFileSync(NIGHTLY_CONFIG_FILE, 'utf8')); } catch { }
    return { enabled: false, hour: 2, modules: ['explanations'], count: 5, model: 'anthropic/claude-3.5-haiku', minThreshold: 5 };
}

// ─── Modül Dizinleri ───
const MODULE_DIRS = {
    explanations: EXPLANATIONS_DIR,
    stories: STORIES_DIR,
    flashcards: FLASHCARDS_DIR,
    matching_games: MATCHING_GAMES_DIR,
    questions: QUESTIONS_DIR,
    productivity: PRODUCTIVITY_DIR,
};

// Draft dizini
if (!fs.existsSync(DRAFT_BASE)) fs.mkdirSync(DRAFT_BASE, { recursive: true });

const VALID_MODULES = Object.keys(MODULE_DIRS);

// ─── Referans Soru Yardımcısı ───
/**
 * Önce KPSS çıkmış soru veri setini (kpss-tarih-gecmis-sorular.js) tarar.
 * Burada eşleşme bulunamazsa mevcut soru bankasına döner.
 * Her iki kaynaktan da sonuç gönderir.
 * @param {string} topicId
 * @param {string} topicName
 * @param {number} limit
 * @returns {string}
 */
let _gecmisSorular = null;

function _loadGecmisSorular() {
    if (_gecmisSorular !== null) return _gecmisSorular;
    try {
        if (fs.existsSync(GECMIS_SORULAR_PATH)) {
            _gecmisSorular = require(GECMIS_SORULAR_PATH);
        } else {
            _gecmisSorular = [];
        }
    } catch { _gecmisSorular = []; }
    return _gecmisSorular;
}

/**
 * Bir metni normalize edip anahtar kelimelere çevirir.
 * @param {string} text
 * @returns {string[]}
 */
function _extractKeywords(text) {
    if (!text) return [];
    return text
        .toLowerCase()
        .replace(/[İı]/g, 'i').replace(/[Şş]/g, 's')
        .replace(/[Üü]/g, 'u').replace(/[Öö]/g, 'o')
        .replace(/[Çç]/g, 'c').replace(/[Ğğ]/g, 'g')
        .split(/[\s\-_,.]+/)
        .filter(w => w.length > 2);
}

function getReferenceQuestions(topicId, topicName = '', limit = 12) {
    const gecmis = _loadGecmisSorular();
    let matched = [];

    if (gecmis.length > 0) {
        const idKeywords = _extractKeywords(topicId);
        const nameKeywords = _extractKeywords(topicName);
        const allKeywords = [...new Set([...idKeywords, ...nameKeywords])];

        // Her soruya puan ver: kaç anahtar kelime tags ile örtüşüyor?
        const scored = gecmis.map(q => {
            const qTags = (q.tags || []).join(' ');
            const score = allKeywords.reduce((acc, kw) => acc + (qTags.includes(kw) ? 1 : 0), 0);
            return { q, score };
        }).filter(x => x.score > 0)
            .sort((a, b) => b.score - a.score);

        matched = scored.slice(0, limit).map(x => x.q);
    }

    // Çıkmış sorulardan yeterli eşleşme yoksa soru bankasından tamamla
    const remaining = limit - matched.length;
    if (remaining > 0) {
        try {
            const qFile = path.join(MODULE_DIRS.questions, `${topicId}.json`);
            if (fs.existsSync(qFile)) {
                const data = JSON.parse(fs.readFileSync(qFile, 'utf8'));
                const bankQuestions = Array.isArray(data) ? data : (data.questions || []);
                const sample = bankQuestions.sort(() => Math.random() - 0.5).slice(0, remaining);
                const bankMatched = sample
                    .map(q => ({ q: q.q || q.question || q.text || '', a: q.a || q.answer || '' }))
                    .filter(x => x.q);
                matched = [...matched, ...bankMatched.map(x => ({ q: x.q, a: x.a, year: null, tags: [] }))];
            }
        } catch { /* sessizce devam et */ }
    }

    if (!matched.length) return '';

    const header = matched.some(x => x.year)
        ? 'KPSS ÇIKMIŞ SORU ÖRNEKLERİ (Gerçek sınav soruları — bu soru tarzı ve konu odaklarına dikkat et):'
        : 'REFERANS SORULAR (Bu konudaki soru örnekleri — benzer kurgu ve odakta üret):';

    const lines = matched.map((item, i) => {
        const yilTag = item.year ? ` [${item.year}]` : '';
        const cevap = item.a ? `\n   → Cevap: ${item.a}` : '';
        return `${i + 1}.${yilTag} ${item.q}${cevap}`;
    });

    return `\n\n---\n${header}\n${lines.join('\n')}\n---`;
}


// ─── Draft Yönetimi ───
function getDraftPath(moduleType, topicId) {
    const dir = path.join(DRAFT_BASE, moduleType);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    return path.join(dir, `${topicId}.json`);
}

function readDraft(moduleType, topicId) {
    const draftFile = getDraftPath(moduleType, topicId);
    if (!fs.existsSync(draftFile)) return [];
    try {
        const parsed = JSON.parse(fs.readFileSync(draftFile, 'utf8'));
        // Boş/geçersiz draft dosyalarını opportunistically temizle — "bekleyen taslak" false positive'ini önler.
        if (!Array.isArray(parsed) || parsed.length === 0) {
            try { fs.unlinkSync(draftFile); } catch { }
            return [];
        }
        return parsed;
    } catch {
        try { fs.unlinkSync(draftFile); } catch { }
        return [];
    }
}

function writeDraft(moduleType, topicId, items) {
    fs.writeFileSync(getDraftPath(moduleType, topicId), JSON.stringify(items, null, 2), 'utf8');
}

// ─── Mevcut yayınlanmış içeriği oku ───
function readPublished(moduleType, topicId) {
    const dir = MODULE_DIRS[moduleType];
    if (!dir) return [];
    const filePath = path.join(dir, `${topicId}.json`);
    if (!fs.existsSync(filePath)) return [];
    try {
        const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
        return Array.isArray(data) ? data : [];
    } catch { return []; }
}

// ─── Yayınlanmış İçeriği Sil (Dosyayı Tamamen Sil) ───
function deletePublishedContent(moduleType, topicId, topicName) {
    const dir = MODULE_DIRS[moduleType];
    if (!dir) throw new Error('Geçersiz modül: ' + moduleType);

    const filePath = path.join(dir, `${topicId}.json`);
    const assetsPath = path.join(DATA_DIR, moduleType, `${topicId}.json`);
    let deletedCount = 0;

    // Ana klasörden sil
    if (fs.existsSync(filePath)) {
        try {
            const rawContent = fs.readFileSync(filePath, 'utf8');
            if (rawContent && rawContent.trim()) {
                try {
                    const content = JSON.parse(rawContent);
                    deletedCount = Array.isArray(content) ? content.length : 1;
                } catch (parseErr) {
                    console.error(`⚠️ JSON parse hatası (silme): ${filePath} - ${parseErr.message}`);
                    deletedCount = 1; // Dosya var ama parse edilemiyor, yine de sil
                }
            }
            fs.unlinkSync(filePath);
            fileExisted = true;
        } catch (readErr) {
            console.error(`⚠️ Dosya okuma hatası (silme): ${filePath} - ${readErr.message}`);
        }
    }

    if (fs.existsSync(assetsPath)) {
        try {
            fs.unlinkSync(assetsPath);
        } catch (e) {
            console.error(`⚠️ Assets silme hatası: ${assetsPath} - ${e.message}`);
        }
    }

    return { deleted: deletedCount };
}

// ─── Dosyaya Kaydet ───
function saveToFile(moduleType, topicId, data) {
    const dir = MODULE_DIRS[moduleType];
    if (!dir) throw new Error('Geçersiz modül: ' + moduleType);

    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

    const filePath = path.join(dir, `${topicId}.json`);
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');

    // Assets klasörüne de kaydet
    const assetsDir = path.join(DATA_DIR, moduleType);
    if (!fs.existsSync(assetsDir)) fs.mkdirSync(assetsDir, { recursive: true });
    const assetsPath = path.join(assetsDir, `${topicId}.json`);
    fs.writeFileSync(assetsPath, JSON.stringify(data, null, 2), 'utf8');

    return { filePath, assetsPath, count: data.length };
}

// ─── version.json Bump Helper ───
function bumpVersionJson(moduleType, topicId) {
    const versionPath = path.join(DATA_DIR, 'version.json');
    let v = {};
    try {
        const raw = fs.readFileSync(versionPath, 'utf8');
        // Yaz öncesi mevcut dosyanın geçerli JSON olduğunu doğrula
        v = JSON.parse(raw);
    } catch (e) {
        console.error('⚠️ version.json okunamadı, sıfırdan oluşturuluyor:', e.message);
        v = {};
    }
    const key = moduleType === 'matching_games' ? 'matching_games' : moduleType;
    if (!v[key]) v[key] = {};
    v[key][topicId] = (v[key][topicId] || 0) + 1;
    const today = new Date().toISOString().split('T')[0];
    v.lastUpdated = today;
    v.last_updated = today;

    const newContent = JSON.stringify(v, null, 2);

    // Yaz öncesi üretilen JSON'ı doğrula (yarım yazma koruması)
    try {
        JSON.parse(newContent);
    } catch (e) {
        throw new Error(`version.json güncelleme hatası — geçersiz JSON üretildi: ${e.message}`);
    }

    fs.writeFileSync(versionPath, newContent, 'utf8');
}

// ─── Local Publish Helper ───
// Sadece version.json bump edilir.
function publishLocal(moduleType, topicId, topicName) {
    return new Promise((resolve) => {
        try {
            bumpVersionJson(moduleType, topicId);
            aiLog('publish', `✅ Local publish başarılı (version.json güncellendi): ${moduleType}/${topicId}`);
            resolve({ success: true });
        } catch (e) {
            aiLog('error', `version.json bump error: ${e.message}`);
            resolve({ success: false, error: e.message });
        }
    });
}

// ─── Konu Listesi ───
function getTopicsList() {
    try {
        const data = JSON.parse(fs.readFileSync(TOPICS_FILE, 'utf8'));
        return data.map(m => ({
            id: m.id,
            name: m.name
        }));
    } catch (e) {
        console.error('Topics parse error:', e);
        return [];
    }
}

// ─── AI Prompt Builders ───
function buildExplanationPrompt(topicName, topicId, part, totalParts = 30, previousContext = '') {
    const p = { start: part, count: 1, range: `${part}` };
    const ts = Date.now();

    const contextSection = previousContext
        ? `\n\n🚫 YASAKLILAR LİSTESİ - BU KONULARI TEKRAR ETME:\n${previousContext}\n\n⚠️ KURAL: Yukarıdaki konular hakkında HİÇBİR BİLGİ tekrar etme.`
        : '';

    return `Sen, MEB müfredatına ve ÖSYM'nin KPSS soru tarzına son derece hakim uzman bir eğitim içerik üreticisisin.
Görev: "${topicName}" konusu hakkında JSON formatında konu anlatımı üret.

ÜRETİM ODAĞI:
Bu parçada SADECE ${p.count} BÖLÜM üret. Bölüm numarası KESİNLİKLE: ${p.range}.
${part > 1 ? `Bu ${part}. bölüm. Önceki konuları ASLA tekrar etme.` : 'Bu 1. bölüm. Konunun başından başla.'}${contextSection}

TEKNİK KURALLAR:
1. Tam ${p.count} bölüm üret.
2. Her bölümde 6-8 content bloğu.
3. 'text' blokları 3-5 cümle.
4. 'bulletList' blokları 4-6 madde.

BEKLENEN JSON FORMATI:
[{
  "topicId": "${topicId}",
  "title": "Bölüm ${p.start}: [Konu Başlığı]",
  "content": [
    {"type": "heading", "text": "..."},
    {"type": "text", "text": "..."},
    {"type": "bulletList", "text": "• ...\\n• ..."},
    {"type": "warning", "text": "..."},
    {"type": "highlighted", "text": "..."}
  ],
  "type": "detailed",
  "difficulty": "medium",
  "id": "exp_${ts}_${topicId.substring(0, 4)}_0",
  "createdAt": "${new Date().toISOString()}",
  "updatedAt": "${new Date().toISOString()}"
}]

KURALLAR:
1. SADECE JSON DİZİSİ döndür.
2. "type" değerleri: heading, text, bulletList, warning, highlighted
3. Her bölümün title'ı "Bölüm X: [Başlık]" formatında olsun.`;
}

// ─── Ana Handler ───
async function handleAIContentRoutes(req, res, pathname, searchParams) {
    // GET /api/ai-content/productivity-categories - Flutter kategori ID'leri + mevcut içerik sayısı.
    // Productivity üretimi için topic listesi bu endpoint'ten gelir; KPSS konularından ayrıdır.
    if (pathname === '/api/ai-content/productivity-categories' && req.method === 'GET') {
        const categories = [
            { id: 'timeManagement', name: 'Zaman Yönetimi' },
            { id: 'motivation', name: 'Motivasyon' },
            { id: 'studyPlanning', name: 'Çalışma Planlama' },
            { id: 'concentration', name: 'Odaklanma' },
            { id: 'breakGuide', name: 'Mola Rehberi' },
            { id: 'examFastLearning', name: 'Sınav & Hızlı Öğrenme' },
            { id: 'noteMemory', name: 'Not & Hafıza Teknikleri' },
        ];
        const enriched = categories.map(c => {
            const fp = path.join(MODULE_DIRS.productivity, `${c.id}.json`);
            let count = 0;
            try {
                if (fs.existsSync(fp)) {
                    const data = JSON.parse(fs.readFileSync(fp, 'utf8'));
                    count = Array.isArray(data) ? data.length : 0;
                }
            } catch { }
            const drafts = readDraft('productivity', c.id).length;
            return { ...c, status: { productivity: count }, drafts };
        });
        return sendJSON(res, { success: true, categories: enriched });
    }

    // GET /api/ai-content/topics - Konu listesi
    if (pathname === '/api/ai-content/topics' && req.method === 'GET') {
        const topics = getTopicsList();

        const enriched = topics.map(t => {
            const status = {};
            for (const mod of Object.keys(MODULE_DIRS)) {
                const fp = path.join(MODULE_DIRS[mod], `${t.id}.json`);
                try {
                    if (fs.existsSync(fp)) {
                        const data = JSON.parse(fs.readFileSync(fp, 'utf8'));
                        status[mod] = Array.isArray(data) ? data.length : 0;
                    } else {
                        status[mod] = 0;
                    }
                } catch { status[mod] = 0; }
            }
            return { ...t, status };
        });

        return sendJSON(res, { success: true, topics: enriched });
    }

    // POST /api/ai-content/delete-published - Yayınlanmış içeriği sil
    if (pathname === '/api/ai-content/delete-published' && req.method === 'POST') {
        try {
            const { moduleType, topicId, topicName } = await parseBody(req);
            if (!moduleType || !topicId)
                return sendJSON(res, { error: 'moduleType ve topicId gerekli' }, 400);
            if (!VALID_MODULES.includes(moduleType))
                return sendJSON(res, { error: 'Geçersiz modül' }, 400);

            const pubResult = deletePublishedContent(moduleType, topicId, topicName);
            const draftResult = readDraft(moduleType, topicId);
            const draftFile = getDraftPath(moduleType, topicId);
            if (fs.existsSync(draftFile)) {
                fs.unlinkSync(draftFile);
            }

            const totalDeleted = (pubResult.deleted || 0) + (draftResult?.length || 0);
            return sendJSON(res, { success: true, deleted: totalDeleted, published: pubResult.deleted, drafts: draftResult?.length || 0 });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }
    // POST /api/ai-content/generate - YZ ile içerik üret (async job)
    if (pathname === '/api/ai-content/generate' && req.method === 'POST') {
        console.log('🚨 /api/ai-content/generate isteği:', new Date().toISOString());

        let body;
        try { body = await parseBody(req); }
        catch (e) { return sendJSON(res, { error: 'Body parse hatası: ' + e.message }, 400); }

        const {
            moduleType, topicId, topicName, count = 30,
            model = 'google/gemini-2.5-flash',
            enableQualityCheck = false, maxRetries = 2,
            useReferenceQuestions = false,
            difficulty = 'medium'
        } = body;

        if (!moduleType || !topicId || !topicName)
            return sendJSON(res, { error: 'moduleType, topicId ve topicName gerekli' }, 400);
        if (!VALID_MODULES.includes(moduleType))
            return sendJSON(res, { error: 'Geçersiz modül' }, 400);

        // Productivity modülünde topicId, Flutter kategori ID'si olmak zorunda —
        // aksi hâlde üretilen içerik uygulamaya entegre olamaz.
        if (moduleType === 'productivity') {
            const VALID_PROD_CATEGORIES = ['timeManagement', 'motivation', 'studyPlanning', 'concentration', 'breakGuide', 'examFastLearning', 'noteMemory'];
            if (!VALID_PROD_CATEGORIES.includes(topicId)) {
                return sendJSON(res, {
                    error: `Productivity üretimi için topicId Flutter kategori ID'si olmalı. Geçerli ID'ler: ${VALID_PROD_CATEGORIES.join(', ')}. Verilen: '${topicId}'`,
                    hint: 'Dashboard\'da "Verimlilik Kategorileri" panelini kullanın veya /api/ai-content/productivity-categories endpointinden ID alın.'
                }, 400);
            }
        }

        const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
        if (!OPENROUTER_API_KEY)
            return sendJSON(res, { error: 'OpenRouter API anahtarı tanımlanmamış' }, 500);

        const safeMaxRetries = Math.max(1, Math.min(5, Number(maxRetries) || 2));
        const safeCount = Math.max(1, Math.min(100, Number(count) || 30));
        const requestTimeoutMs = Number(process.env.OPENROUTER_TIMEOUT_MS) || 240000;

        // Job oluştur ve hemen yanıt dön
        const jobId = `job_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
        const requestLogs = [];
        _activeJobs.set(jobId, {
            status: 'running', progress: 0, total: safeCount,
            generated: 0, total_drafts: 0, error: null,
            logs: requestLogs, startedAt: Date.now()
        });

        // Eski jobları temizle (10 dk+)
        for (const [id, j] of _activeJobs.entries()) {
            if (Date.now() - j.startedAt > 600000) _activeJobs.delete(id);
        }

        // Async üretim başlat - await YOK
        setImmediate(async () => {
            const job = _activeJobs.get(jobId);
            try {
                aiLog('generate', `🚀 Job başladı: ${topicName} - ${moduleType} (${safeCount} bölüm)`, requestLogs);

                let startPart = 1;
                let existingDrafts = readDraft(moduleType, topicId);

                // Sorular modülü için mevcut veriyi ASLA silme (kümülatif ekleme yapılır)
                if (moduleType !== 'questions') {
                    // Mevcut yayınlanmış içeriği otomatik sil (sorular hariç)
                    const existingPublished = readPublished(moduleType, topicId);
                    if (existingPublished.length > 0) {
                        deletePublishedContent(moduleType, topicId, topicName);
                        aiLog('generate', `🗑️ Mevcut yayınlanmış ${existingPublished.length} içerik silindi, yeniden üretiliyor`, requestLogs);
                    }

                    // Mevcut taslakları da temizle (taze üretim)
                    const draftFile = getDraftPath(moduleType, topicId);
                    if (existingDrafts.length > 0) {
                        if (fs.existsSync(draftFile)) fs.unlinkSync(draftFile);
                        aiLog('generate', `🗑️ Mevcut ${existingDrafts.length} taslak silindi, baştan üretiliyor`, requestLogs);
                        existingDrafts = [];
                    }
                    startPart = 1;
                    aiLog('generate', `📁 Bölüm 1'den başlıyor (temiz üretim)`, requestLogs);
                } else {
                    startPart = existingDrafts.length + 1;
                    aiLog('generate', `📁 Mevcut taslak: ${existingDrafts.length} | Bölüm ${startPart}'den devam ediyor`, requestLogs);
                }

                const safeDifficulty = ['easy', 'medium', 'hard'].includes(difficulty) ? difficulty : 'medium';
                aiLog('generate', `⚙️ Ayarlar: zorluk=${safeDifficulty} · kaliteKontrol=${enableQualityCheck} · referans=${useReferenceQuestions} · retry=${safeMaxRetries}`, requestLogs);

                const generated = await generateWithAI(
                    moduleType, topicName, topicId, startPart, safeCount, model, requestLogs,
                    {
                        maxRetries: safeMaxRetries, enableQualityCheck,
                        useReferenceQuestions,
                        difficulty: safeDifficulty,
                        requestTimeoutMs,
                        onProgress: (done, total) => { if (job) job.progress = done; }
                    }
                );

                const allDrafts = [...existingDrafts, ...generated];
                writeDraft(moduleType, topicId, allDrafts);
                aiLog('generate', `✅ TAMAMLANDI: ${generated.length} bölüm taslağa yazıldı`, requestLogs);
                if (job) { job.status = 'done'; job.generated = generated.length; job.total_drafts = allDrafts.length; }
            } catch (e) {
                aiLog('error', `❌ Job hatası: ${e.message}`, requestLogs);
                if (job) { job.status = 'error'; job.error = e.message; }
            }
        });

        return sendJSON(res, { success: true, jobId, message: 'Üretim başladı, jobId ile takip edin.' });
    }

    // GET /api/ai-content/job-status - Job durumu sorgula
    if (pathname === '/api/ai-content/job-status' && req.method === 'GET') {
        const jobId = searchParams.get('jobId');
        const since = parseInt(searchParams.get('since') || '0', 10);
        if (!jobId) return sendJSON(res, { error: 'jobId gerekli' }, 400);
        const job = _activeJobs.get(jobId);
        if (!job) return sendJSON(res, { error: 'Job bulunamadı' }, 404);

        // Eski job'u otomatik timeout yap (10 dk+)
        if (job.status === 'running' && Date.now() - job.startedAt > 600000) {
            job.status = 'error';
            job.error = 'İşlem zaman aşımına uğradı (10 dakika)';
            aiLog('timeout', `Job ${jobId} 10 dakika timeout`, job.logs);
        }

        const newLogs = job.logs.slice(since);
        return sendJSON(res, {
            success: true, status: job.status,
            progress: job.progress, total: job.total,
            generated: job.generated, total_drafts: job.total_drafts,
            error: job.error, logs: newLogs, logOffset: job.logs.length
        });
    }

    // GET /api/ai-content/job-stream - SSE ile canlı job takibi
    if (pathname === '/api/ai-content/job-stream' && req.method === 'GET') {
        const jobId = searchParams.get('jobId');
        if (!jobId) {
            res.writeHead(400, { 'Content-Type': 'text/plain' });
            res.end('jobId gerekli');
            return true;
        }
        const job = _activeJobs.get(jobId);
        if (!job) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('Job bulunamadı');
            return true;
        }

        res.writeHead(200, {
            'Content-Type': 'text/event-stream; charset=utf-8',
            'Cache-Control': 'no-cache, no-store',
            'Connection': 'keep-alive',
            'X-Accel-Buffering': 'no',
        });
        res.write('retry: 3000\n\n');

        let logOffset = 0;
        let lastProgress = -1;

        function sendSSE(type, data) {
            try {
                res.write(`event: ${type}\ndata: ${JSON.stringify(data)}\n\n`);
            } catch { /* bağlantı kapandı */ }
        }

        // İlk durum bilgisi
        sendSSE('init', {
            status: job.status,
            progress: job.progress,
            total: job.total,
            generated: job.generated,
            total_drafts: job.total_drafts
        });

        // Mevcut logları ilk seferde gönder
        if (job.logs.length > 0) {
            job.logs.forEach(log => sendSSE('log', log));
            logOffset = job.logs.length;
        }

        const tick = setInterval(() => {
            const j = _activeJobs.get(jobId);
            if (!j) { clearInterval(tick); try { res.end(); } catch { } return; }

            // Yeni logları gönder
            if (j.logs.length > logOffset) {
                const newLogs = j.logs.slice(logOffset);
                logOffset = j.logs.length;
                newLogs.forEach(log => sendSSE('log', log));
            }

            // İlerleme güncellemesi
            if (j.progress !== lastProgress) {
                lastProgress = j.progress;
                sendSSE('progress', { progress: j.progress, total: j.total });
            }

            if (j.status === 'done') {
                sendSSE('done', { generated: j.generated, total_drafts: j.total_drafts });
                clearInterval(tick);
                setTimeout(() => { try { res.end(); } catch { } }, 300);
            } else if (j.status === 'error') {
                sendSSE('error', { error: j.error });
                clearInterval(tick);
                setTimeout(() => { try { res.end(); } catch { } }, 300);
            }
        }, 500);

        req.on('close', () => clearInterval(tick));
        return true;
    }

    // GET /api/ai-content/drafts - Taslakları listele
    if (pathname === '/api/ai-content/drafts' && req.method === 'GET') {
        const topicId = searchParams.get('topicId');
        const moduleType = searchParams.get('moduleType');
        if (!topicId || !moduleType)
            return sendJSON(res, { error: 'topicId ve moduleType gerekli' }, 400);
        const drafts = readDraft(moduleType, topicId);
        return sendJSON(res, { success: true, drafts, count: drafts.length });
    }

    // POST /api/ai-content/add-draft - Taslağa yeni öğe ekle
    if (pathname === '/api/ai-content/add-draft' && req.method === 'POST') {
        try {
            const { moduleType, topicId, items } = await parseBody(req);
            if (!moduleType || !topicId || !items || !Array.isArray(items) || items.length === 0)
                return sendJSON(res, { error: 'moduleType, topicId ve items[] gerekli' }, 400);
            if (!VALID_MODULES.includes(moduleType))
                return sendJSON(res, { error: `Geçersiz moduleType: ${moduleType}` }, 400);
            const existing = readDraft(moduleType, topicId);
            const withTs = items.map(item => ({ ...item, _draftAddedAt: new Date().toISOString() }));
            writeDraft(moduleType, topicId, [...existing, ...withTs]);
            return sendJSON(res, { success: true, added: items.length, total: existing.length + items.length });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /api/ai-content/update-draft - Tek taslağı güncelle
    if (pathname === '/api/ai-content/update-draft' && req.method === 'POST') {
        try {
            const { moduleType, topicId, index, updatedDraft } = await parseBody(req);
            if (!moduleType || !topicId || index === undefined || !updatedDraft)
                return sendJSON(res, { error: 'moduleType, topicId, index ve updatedDraft gerekli' }, 400);
            const drafts = readDraft(moduleType, topicId);
            if (index < 0 || index >= drafts.length)
                return sendJSON(res, { error: `Geçersiz index: ${index}` }, 400);
            drafts[index] = { ...drafts[index], ...updatedDraft, updatedAt: new Date().toISOString() };
            writeDraft(moduleType, topicId, drafts);
            return sendJSON(res, { success: true });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /api/ai-content/delete-draft - Taslak sil (yayınlamadan)
    if (pathname === '/api/ai-content/delete-draft' && req.method === 'POST') {
        try {
            const { moduleType, topicId, indices } = await parseBody(req);
            if (!moduleType || !topicId)
                return sendJSON(res, { error: 'moduleType ve topicId gerekli' }, 400);

            const drafts = readDraft(moduleType, topicId);
            const remaining = (indices && indices.length > 0)
                ? drafts.filter((_, i) => !indices.includes(i))
                : [];

            const draftFile = getDraftPath(moduleType, topicId);
            if (remaining.length > 0) {
                writeDraft(moduleType, topicId, remaining);
            } else if (fs.existsSync(draftFile)) {
                fs.unlinkSync(draftFile);
            }

            return sendJSON(res, { success: true, deleted: drafts.length - remaining.length, remaining: remaining.length });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /api/ai-content/approve-draft - Taslağı onayla (canlıya al)
    if (pathname === '/api/ai-content/approve-draft' && req.method === 'POST') {
        try {
            const { moduleType, topicId, topicName, indices } = await parseBody(req);

            if (!moduleType || !topicId)
                return sendJSON(res, { error: 'moduleType ve topicId gerekli' }, 400);

            const drafts = readDraft(moduleType, topicId);
            if (!drafts || drafts.length === 0)
                return sendJSON(res, { error: 'Onaylanacak taslak bulunamadı' }, 400);

            // Belirli indeksler seçilmişse filtrele, yoksa hepsini al
            const toPublish = indices && indices.length > 0
                ? drafts.filter((_, i) => indices.includes(i))
                : drafts;

            // Mevcut yayınlanmış içeriği oku
            const existing = readPublished(moduleType, topicId);

            // Birleştir (yenileri sona ekle)
            const merged = [...existing, ...toPublish];

            // Title bazlı dedup: aynı başlıklı varsa yeniyi tut
            const seen = new Map();
            for (const item of merged) {
                const key = (item.title || item.question || item.front || item.left || JSON.stringify(item).substring(0, 80)).toLowerCase().trim();
                seen.set(key, item);
            }
            // _part yeniden indexle + title'ı tekrar eden ilk heading'i temizle
            const combined = Array.from(seen.values()).map((item, i) => {
                const cleaned = { ...item, _part: i + 1 };
                if (Array.isArray(cleaned.content) && cleaned.content.length > 0) {
                    const titleNorm = (cleaned.title || '').toLowerCase().trim();
                    if (cleaned.content[0].type === 'heading' &&
                        (cleaned.content[0].text || '').toLowerCase().trim() === titleNorm) {
                        cleaned.content = cleaned.content.slice(1);
                    }
                }
                return cleaned;
            });

            // Kaydet
            const result = saveToFile(moduleType, topicId, combined);

            aiLog('publish', `Local publish başlatılıyor: ${moduleType}/${topicId}`);
            const publishResult = await publishLocal(moduleType, topicId, topicName);

            if (!indices || indices.length === 0) {
                fs.unlinkSync(getDraftPath(moduleType, topicId));
            } else {
                const remaining = drafts.filter((_, i) => !indices.includes(i));
                if (remaining.length > 0) {
                    writeDraft(moduleType, topicId, remaining);
                } else {
                    fs.unlinkSync(getDraftPath(moduleType, topicId));
                }
            }

            aiLog('publish', `✅ ${toPublish.length} bölüm canlıya alındı: ${topicName}`);

            // Arka planda git push (origin + meto/main + mobile assets) — response'u bloklamaz
            pushAllRemotes(moduleType)
                .then(({ committed, results }) => {
                    if (committed) aiLog('publish', `✅ Git push tamamlandı: ${JSON.stringify(results)}`);
                    else aiLog('publish', 'Git push: commit edilecek değişiklik yoktu');
                })
                .catch(e => aiLog('error', `Git push arka plan hatası: ${e.message}`));

            return sendJSON(res, {
                success: true,
                published: toPublish.length,
                total: combined.length,
                publishResult: publishResult,
                message: `${toPublish.length} bölüm başarıyla yayınlandı!`
            });
        } catch (e) {
            aiLog('error', `Onay hatası: ${e.message}`);
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // GET /api/content-stats - Konu başına içerik sayıları
    if (pathname === '/api/content-stats' && req.method === 'GET') {
        const topics = getTopicsList();
        const stats = topics.map(t => {
            const counts = {};
            for (const [mod, dir] of Object.entries(MODULE_DIRS)) {
                const file = path.join(dir, `${t.id}.json`);
                if (fs.existsSync(file)) {
                    try { const d = JSON.parse(fs.readFileSync(file, 'utf8')); counts[mod] = Array.isArray(d) ? d.length : 0; } catch { counts[mod] = 0; }
                } else { counts[mod] = 0; }
            }
            let drafts = 0;
            for (const mod of Object.keys(MODULE_DIRS)) drafts += readDraft(mod, t.id).length;
            return { id: t.id, name: t.name, ...counts, drafts };
        });
        return sendJSON(res, { success: true, stats });
    }

    // GET /api/cost-log - Maliyet logu
    if (pathname === '/api/cost-log' && req.method === 'GET') {
        let log = [];
        try { if (fs.existsSync(COST_LOG_FILE)) log = JSON.parse(fs.readFileSync(COST_LOG_FILE, 'utf8')); } catch { }
        const total = log.reduce((s, e) => ({ usd: s.usd + e.costUsd, tl: s.tl + e.costTl, tokens: s.tokens + (e.promptTokens || 0) + (e.completionTokens || 0) }), { usd: 0, tl: 0, tokens: 0 });
        return sendJSON(res, { success: true, log: log.slice(0, 200), total: { usd: parseFloat(total.usd.toFixed(4)), tl: parseFloat(total.tl.toFixed(2)), tokens: total.tokens } });
    }

    // DELETE /api/cost-log - Logu temizle
    if (pathname === '/api/cost-log' && req.method === 'DELETE') {
        try { fs.writeFileSync(COST_LOG_FILE, '[]', 'utf8'); } catch { }
        return sendJSON(res, { success: true });
    }

    // GET /api/cost-log/summary - Gün/model/modül bazlı özet
    if (pathname === '/api/cost-log/summary' && req.method === 'GET') {
        let log = [];
        try { if (fs.existsSync(COST_LOG_FILE)) log = JSON.parse(fs.readFileSync(COST_LOG_FILE, 'utf8')); } catch { }

        const byDay = {};    // { '2026-04-16': { usd, tl, calls, tokens } }
        const byModel = {};  // { 'google/gemini-2.5-flash': { usd, tl, calls, tokens } }
        const byModule = {}; // { 'productivity': { usd, tl, calls, tokens } }
        let totalUsd = 0, totalTl = 0, totalTokens = 0;
        const DAY_MS = 24 * 60 * 60 * 1000;
        const now = Date.now();
        let last24hUsd = 0, last7dUsd = 0;

        for (const e of log) {
            const usd = e.costUsd || 0;
            const tl = e.costTl || 0;
            const toks = (e.promptTokens || 0) + (e.completionTokens || 0);
            totalUsd += usd; totalTl += tl; totalTokens += toks;

            const day = (e.timestamp || '').slice(0, 10);
            if (day) {
                const d = byDay[day] || (byDay[day] = { usd: 0, tl: 0, calls: 0, tokens: 0 });
                d.usd += usd; d.tl += tl; d.calls++; d.tokens += toks;
            }

            const model = e.model || 'unknown';
            const m = byModel[model] || (byModel[model] = { usd: 0, tl: 0, calls: 0, tokens: 0 });
            m.usd += usd; m.tl += tl; m.calls++; m.tokens += toks;

            const modu = e.moduleType || e.module || 'unknown';
            const mo = byModule[modu] || (byModule[modu] = { usd: 0, tl: 0, calls: 0, tokens: 0 });
            mo.usd += usd; mo.tl += tl; mo.calls++; mo.tokens += toks;

            if (e.timestamp) {
                const age = now - new Date(e.timestamp).getTime();
                if (age <= DAY_MS) last24hUsd += usd;
                if (age <= 7 * DAY_MS) last7dUsd += usd;
            }
        }

        const round = (obj) => Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, {
            usd: parseFloat(v.usd.toFixed(4)),
            tl: parseFloat(v.tl.toFixed(2)),
            calls: v.calls,
            tokens: v.tokens,
        }]));

        return sendJSON(res, {
            success: true,
            total: {
                usd: parseFloat(totalUsd.toFixed(4)),
                tl: parseFloat(totalTl.toFixed(2)),
                tokens: totalTokens,
                calls: log.length,
            },
            window: {
                last24hUsd: parseFloat(last24hUsd.toFixed(4)),
                last7dUsd: parseFloat(last7dUsd.toFixed(4)),
            },
            byDay: round(byDay),
            byModel: round(byModel),
            byModule: round(byModule),
        });
    }

    // GET /api/content-search - İçerik arama
    if (pathname === '/api/content-search' && req.method === 'GET') {
        const q = searchParams.get('q')?.toLowerCase().trim();
        const scope = searchParams.get('scope') || 'all';
        if (!q || q.length < 2) return sendJSON(res, { success: true, results: [], q });
        const results = [];
        const topics = getTopicsList();
        outer: for (const topic of topics) {
            for (const mod of Object.keys(MODULE_DIRS)) {
                if (scope !== 'drafts') {
                    const items = readPublished(mod, topic.id);
                    items.forEach((item, idx) => {
                        if (results.length >= 60) return;
                        if (JSON.stringify(item).toLowerCase().includes(q))
                            results.push({
                                type: 'published', moduleType: mod, topicId: topic.id, topicName: topic.name, index: idx,
                                title: item.title || item.front || item.left || `#${idx + 1}`
                            });
                    });
                }
                if (scope !== 'published') {
                    const drafts = readDraft(mod, topic.id);
                    drafts.forEach((item, idx) => {
                        if (results.length >= 60) return;
                        if (JSON.stringify(item).toLowerCase().includes(q))
                            results.push({
                                type: 'draft', moduleType: mod, topicId: topic.id, topicName: topic.name, index: idx,
                                title: item.title || item.front || item.left || `Taslak #${idx + 1}`
                            });
                    });
                }
                if (results.length >= 60) break outer;
            }
        }
        return sendJSON(res, { success: true, results, q });
    }

    // POST /api/ai-content/update-published - Yayınlanmış içeriği güncelle
    if (pathname === '/api/ai-content/update-published' && req.method === 'POST') {
        try {
            const { moduleType, topicId, index, updatedItem } = await parseBody(req);
            if (!moduleType || !topicId || index === undefined || !updatedItem)
                return sendJSON(res, { error: 'moduleType, topicId, index ve updatedItem gerekli' }, 400);
            const items = readPublished(moduleType, topicId);
            if (index < 0 || index >= items.length)
                return sendJSON(res, { error: `Geçersiz index: ${index}` }, 400);
            items[index] = { ...items[index], ...updatedItem, updatedAt: new Date().toISOString() };
            saveToFile(moduleType, topicId, items);
            return sendJSON(res, { success: true });
        } catch (e) { return sendJSON(res, { error: e.message }, 500); }
    }

    // GET /api/nightly-config
    if (pathname === '/api/nightly-config' && req.method === 'GET') {
        return sendJSON(res, { success: true, config: readNightlyConfig() });
    }

    // POST /api/nightly-config
    if (pathname === '/api/nightly-config' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const current = readNightlyConfig();
            const updated = { ...current, ...body };
            fs.writeFileSync(NIGHTLY_CONFIG_FILE, JSON.stringify(updated, null, 2), 'utf8');
            return sendJSON(res, { success: true, config: updated });
        } catch (e) { return sendJSON(res, { error: e.message }, 500); }
    }

    // GET /api/topics - Serve topics.json for lesson/topic name mapping
    if (pathname === '/api/topics' && req.method === 'GET') {
        const topicsFile = path.join(DATA_DIR, 'topics.json');
        try {
            const topics = fs.existsSync(topicsFile)
                ? JSON.parse(fs.readFileSync(topicsFile, 'utf8'))
                : [];
            return sendJSON(res, { success: true, topics });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MODULE FILE MANAGEMENT - Plain Text Editing
    // ═══════════════════════════════════════════════════════════════════════════

    // GET /api/ai-content/files?module={module} - List files in module directory
    if (pathname === '/api/ai-content/files' && req.method === 'GET') {
        const moduleType = searchParams.get('module');
        if (!moduleType || !MODULE_DIRS[moduleType]) {
            return sendJSON(res, { error: 'Geçersiz module tipi' }, 400);
        }

        const dirPath = MODULE_DIRS[moduleType];
        try {
            if (!fs.existsSync(dirPath)) {
                return sendJSON(res, { success: true, files: [] });
            }
            const files = fs.readdirSync(dirPath)
                .filter(f => f.endsWith('.json'))
                .map(f => ({ name: f, size: fs.statSync(path.join(dirPath, f)).size }));
            return sendJSON(res, { success: true, files });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // GET /api/ai-content/file?module={module}&filename={filename} - Get file content as plain text
    if (pathname === '/api/ai-content/file' && req.method === 'GET') {
        const moduleType = searchParams.get('module');
        const filename = searchParams.get('filename');

        if (!moduleType || !MODULE_DIRS[moduleType]) {
            return sendJSON(res, { error: 'Geçersiz module tipi' }, 400);
        }
        if (!filename || !filename.endsWith('.json')) {
            return sendJSON(res, { error: 'Geçersiz dosya adı (.json gerekli)' }, 400);
        }

        const filePath = path.join(MODULE_DIRS[moduleType], filename);
        try {
            if (!fs.existsSync(filePath)) {
                return sendJSON(res, { error: 'Dosya bulunamadı' }, 404);
            }
            const content = fs.readFileSync(filePath, 'utf8');
            return sendJSON(res, { success: true, content });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /api/ai-content/file - Save file content (plain text)
    if (pathname === '/api/ai-content/file' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { module: moduleType, filename, content } = body;

            if (!moduleType || !MODULE_DIRS[moduleType]) {
                return sendJSON(res, { error: 'Geçersiz module tipi' }, 400);
            }
            if (!filename || !filename.endsWith('.json')) {
                return sendJSON(res, { error: 'Geçersiz dosya adı (.json gerekli)' }, 400);
            }
            if (content === undefined || content === null) {
                return sendJSON(res, { error: 'İçerik gerekli' }, 400);
            }

            const dirPath = MODULE_DIRS[moduleType];
            if (!fs.existsSync(dirPath)) {
                fs.mkdirSync(dirPath, { recursive: true });
            }

            const filePath = path.join(dirPath, filename);
            fs.writeFileSync(filePath, content, 'utf8');

            return sendJSON(res, { success: true, message: 'Dosya kaydedildi' });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // DELETE /api/ai-content/file?module={module}&filename={filename} - Delete file
    if (pathname === '/api/ai-content/file' && req.method === 'DELETE') {
        const moduleType = searchParams.get('module');
        const filename = searchParams.get('filename');

        if (!moduleType || !MODULE_DIRS[moduleType]) {
            return sendJSON(res, { error: 'Geçersiz module tipi' }, 400);
        }
        if (!filename || !filename.endsWith('.json')) {
            return sendJSON(res, { error: 'Geçersiz dosya adı (.json gerekli)' }, 400);
        }

        const filePath = path.join(MODULE_DIRS[moduleType], filename);
        try {
            if (!fs.existsSync(filePath)) {
                return sendJSON(res, { error: 'Dosya bulunamadı' }, 404);
            }
            fs.unlinkSync(filePath);
            return sendJSON(res, { success: true, message: 'Dosya silindi' });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /api/ai-content/check-duplicates - Draft soruları yayınlananlarla karşılaştır
    if (pathname === '/api/ai-content/check-duplicates' && req.method === 'POST') {
        try {
            const { moduleType, topicId } = await parseBody(req);
            if (!moduleType || !topicId)
                return sendJSON(res, { error: 'moduleType ve topicId gerekli' }, 400);
            if (moduleType !== 'questions')
                return sendJSON(res, { error: 'Sadece questions modülü desteklenir' }, 400);

            const drafts = readDraft(moduleType, topicId);
            if (!drafts || drafts.length === 0)
                return sendJSON(res, { success: true, results: [] });

            const publishedFile = path.join(QUESTIONS_DIR, `${topicId}.json`);
            let published = [];
            if (fs.existsSync(publishedFile)) {
                try { published = JSON.parse(fs.readFileSync(publishedFile, 'utf8')); } catch {}
            }
            if (!Array.isArray(published)) published = [];

            function normQ(text) {
                return (text || '').toLowerCase()
                    .replace(/[^\w\sğüşöçıa-z]/gi, ' ')
                    .replace(/\s+/g, ' ').trim();
            }
            function jaccard(a, b) {
                const sa = new Set(a.split(' ').filter(w => w.length > 2));
                const sb = new Set(b.split(' ').filter(w => w.length > 2));
                if (sa.size === 0 || sb.size === 0) return 0;
                const inter = [...sa].filter(w => sb.has(w)).length;
                return inter / new Set([...sa, ...sb]).size;
            }

            const results = drafts.map((draft, i) => {
                const draftText = normQ(draft.q || draft.question || '');
                if (!draftText) return { draftIndex: i, status: 'unknown', score: 0, matchedQuestion: null };
                let bestScore = 0, bestMatch = null;
                for (const pub of published) {
                    const score = jaccard(draftText, normQ(pub.q || pub.question || ''));
                    if (score > bestScore) { bestScore = score; bestMatch = (pub.q || pub.question || '').substring(0, 80); }
                }
                const status = bestScore >= 0.7 ? 'duplicate' : bestScore >= 0.4 ? 'similar' : 'clean';
                return { draftIndex: i, status, score: Math.round(bestScore * 100), matchedQuestion: bestMatch };
            });

            return sendJSON(res, { success: true, results });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
}

// ═══════════════════════════════════════════════════════════════════════════
// OPENROUTER AI GENERATION
// ═══════════════════════════════════════════════════════════════════════════

async function callWithModelFallback(prompt, primaryModel, apiKey, jsonMode, requestLogs, requestTimeoutMs, maxRetries = 2, maxTokens = undefined) {
    const modelsToTry = [primaryModel, ...FALLBACK_MODELS.filter(m => m !== primaryModel)];
    let lastError;
    for (const model of modelsToTry) {
        try {
            aiLog('fallback', `🔄 Model deneniyor: ${model}`, requestLogs);
            const result = await callOpenRouterWithRetry(prompt, model, apiKey, jsonMode, maxRetries, requestLogs, requestTimeoutMs, maxTokens);
            if (maxTokens) {
                aiLog('fallback', `   📏 max_tokens=${maxTokens}`, requestLogs);
            } else {
                aiLog('fallback', `   📏 Token limiti kaldırıldı (model varsayılanı kullanılıyor)`, requestLogs);
            }
            aiLog('fallback', `✅ Model başarılı: ${model}`, requestLogs);
            return result;
        } catch (e) {
            lastError = e;
            aiLog('fallback', `❌ Model başarısız: ${model} — ${e.message}`, requestLogs);
        }
    }
    throw new Error(`Tüm modeller başarısız: ${lastError?.message}`);
}

// ═══════════════════════════════════════════════════════════════════════════
// SYLLABUS-FIRST CONTENT GENERATION
// ═══════════════════════════════════════════════════════════════════════════

async function generateWithAI(moduleType, topicName, topicId, startPart, count, model, requestLogs = null, options = {}) {
    const {
        maxRetries = 2,
        enableQualityCheck = false,
        useReferenceQuestions = false,
        difficulty = 'medium',
        requestTimeoutMs = 240000,
        onProgress = null,
    } = options;

    // Referans soruları hazırla (istenirse)
    const refBlock = useReferenceQuestions ? getReferenceQuestions(topicId, topicName) : '';
    if (refBlock) aiLog('generate', `📚 Referans sorular eklendi (${refBlock.split('\n').length - 4} soru)`, requestLogs);

    const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
    if (!OPENROUTER_API_KEY) throw new Error('OPENROUTER_API_KEY çevre değişkeni tanımlanmamış!');

    aiLog('generate', `🔄 generateWithAI() BAŞLATILIYOR`, requestLogs);
    aiLog('generate', `   📋 Konu: ${topicName} | 🤖 Model: ${model} | 🎯 Zorluk: ${difficulty}`, requestLogs);

    // ── Tek API çağrılı modüller: questions / flashcards / matching_games / productivity ──
    if (moduleType === 'flashcards' || moduleType === 'matching_games' || moduleType === 'questions' || moduleType === 'productivity') {
        return _generateDirectAll(moduleType, topicName, topicId, count, model, OPENROUTER_API_KEY, requestLogs, { maxRetries, requestTimeoutMs, onProgress, refBlock, difficulty });
    }

    // ── Anlatım & Hikaye: Syllabus + batch içerik ─────────────────────────────
    aiLog('generate', `📋 ADIM 1: Syllabus oluşturuluyor (${count} bölüm)...`, requestLogs);
    const syllabusPrompt = buildSyllabusPrompt(moduleType, topicName, topicId, count) + refBlock;
    let syllabus;
    try {
        const syllabusContent = await callWithModelFallback(syllabusPrompt, model, OPENROUTER_API_KEY, true, requestLogs, requestTimeoutMs, maxRetries);
        syllabus = parseSyllabusResponse(syllabusContent, requestLogs);
        aiLog('generate', `✅ Syllabus oluşturuldu: ${syllabus.length} bölüm`, requestLogs);
        syllabus.slice(0, 3).forEach((s, i) => aiLog('generate', `   ${i + 1}. ${s.title}`, requestLogs));
        if (syllabus.length > 3) aiLog('generate', `   ... ve ${syllabus.length - 3} bölüm daha`, requestLogs);
    } catch (e) {
        throw new Error('Konu outline\'ı oluşturulamadı: ' + e.message);
    }

    const total = Math.min(count, syllabus.length);
    // explanations: max 4 içerik çağrısı → toplam 5 (1 syllabus + 4 içerik)
    const BATCH_SIZE = moduleType === 'explanations'
        ? Math.max(5, Math.ceil(total / 4))
        : 3;
    const results = [];
    let successCount = 0;
    let failCount = 0;

    aiLog('generate', `📝 ADIM 2: İçerik üretimi başlıyor (${total} bölüm, ${BATCH_SIZE}'li batch)`, requestLogs);

    for (let i = 0; i < total; i += BATCH_SIZE) {
        const batch = syllabus.slice(i, Math.min(i + BATCH_SIZE, total));
        const batchNums = batch.map((_, j) => startPart + i + j);
        aiLog('generate', `⏳ Batch [${batchNums[0]}-${batchNums[batchNums.length - 1]}]: ${batch.map(s => s.title?.substring(0, 30)).join(' | ')}`, requestLogs);

        const contentPrompt = _buildBatchContentPrompt(moduleType, topicName, topicId, batch, batchNums, syllabus, difficulty) + refBlock;
        try {
            const content = await callWithModelFallback(contentPrompt, model, OPENROUTER_API_KEY, true, requestLogs, requestTimeoutMs, maxRetries);
            const parsed = parseAIResponse(content, moduleType, topicId, batchNums[0], requestLogs);

            if (enableQualityCheck && parsed.length > 0) {
                const qc = await performQualityCheck(parsed, topicName, moduleType, model, OPENROUTER_API_KEY);
                aiLog('generate', `🔍 Kalite: ${qc.passed ? `OK (${qc.score}/10)` : `⚠️ ${qc.issues?.join(', ')}`}`, requestLogs);
            }

            results.push(...parsed);
            successCount += batch.length;
            if (onProgress) onProgress(successCount + failCount, total);
            aiLog('success', `✅ Batch tamamlandı (${parsed.length} item)`, requestLogs);
        } catch (e) {
            aiLog('error', `❌ Batch hatası: ${e.message} — bölümler tek tek deneniyor`, requestLogs);
            for (let j = 0; j < batch.length; j++) {
                const singlePrompt = buildDetailedContentPrompt(moduleType, topicName, topicId, batchNums[j], batch[j], syllabus, difficulty);
                try {
                    const content = await callWithModelFallback(singlePrompt, model, OPENROUTER_API_KEY, true, requestLogs, requestTimeoutMs, maxRetries);
                    const parsed = parseAIResponse(content, moduleType, topicId, batchNums[j], requestLogs);
                    results.push(...parsed);
                    successCount++;
                    if (onProgress) onProgress(successCount + failCount, total);
                    aiLog('success', `✅ Tekrar deneme başarılı: Bölüm ${batchNums[j]}`, requestLogs);
                } catch (e2) {
                    failCount++;
                    aiLog('error', `❌ Bölüm ${batchNums[j]} tekrar deneme başarısız: ${e2.message}`, requestLogs);
                }
            }
        }
    }

    aiLog('generate', `════════════════════════════════════`, requestLogs);
    aiLog('generate', `✅ ÜRETİM ÖZETİ: ${successCount} başarılı / ${failCount} başarısız | ${results.length} item`, requestLogs);
    aiLog('generate', `════════════════════════════════════`, requestLogs);
    return results;
}

// Flashcard, matching_games, questions ve productivity için tek API çağrısıyla toplu üretim
async function _generateDirectAll(moduleType, topicName, topicId, count, model, apiKey, requestLogs, options) {
    const { maxRetries, requestTimeoutMs, onProgress, refBlock = '', difficulty = 'medium' } = options;
    const ts = Date.now();
    const difficultyGuide = buildDifficultyGuide(difficulty, moduleType);

    // Bu topic/kategori için daha önce üretilmiş (yayınlanmış + taslak) içerik başlık/ID'leri —
    // AI'a tekrar üretmemesi için "YASAK LİSTE" olarak enjekte edeceğiz. Özellikle productivity
    // modülünde aynı tekniği tekrar tekrar üretme sorununu önler.
    const existingItems = [...readPublished(moduleType, topicId), ...readDraft(moduleType, topicId)];
    const existingSummary = _buildExistingItemsBlock(moduleType, existingItems);

    const prompts = {
        flashcards: `KPSS flashcard üret. Konu: "${topicName}".
${difficultyGuide}
${existingSummary}
🎯 ZORUNLU GÖREV: Tam ${count} adet flashcard üret. 1 eksik veya 1 fazla olursa geçersiz sayılır.

KURALLAR:
- question: 5-15 kelime, somut cevabı olan bir soru. Soru türünü değiştir (Hangi/Ne zaman/Kim/Nerede/Neden).
- answer: 2-5 kelime veya tek cümle. Tarih/isim net olsun.
- additionalInfo: 1-2 cümle bağlam veya mnemonik (asla boş bırakma).
- ${count} kartın hepsi FARKLI alt-konu. Aynı tarih/isim 2'den fazla tekrar etmesin.
- Müfredat odaklı, sınavda çıkabilecek bilgi (trivia değil).

⚠️ KESİN YASAKLAR: Eksik sayı (örn: 9 veya 11 yerine 10), \uFFFD/◆ karakter, boş alan, kod bloğu, önsöz/sonsöz.

JSON çıktısı (DİKKAT: Tam ${count} öğe, sayıyı kontrol et):
[{"topicId":"${topicId}","question":"Osmanlı'da ilk matbaa hangi padişah döneminde kuruldu?","answer":"III. Ahmet (1727)","additionalInfo":"İbrahim Müteferrika tarafından Lâle Devri'nde kuruldu.","id":"flash_${ts}_1"}]${refBlock}`,

        matching_games: `KPSS eşleştirme çifti üret. Konu: "${topicName}".
${difficultyGuide}
${existingSummary}
🎯 ZORUNLU GÖREV: Tam ${count} adet eşleştirme çifti üret. 1 eksik veya 1 fazla olursa geçersiz sayılır.

KURALLAR:
- question (sol): 1-4 kelime — kavram/tarih/isim/antlaşma/eser.
- answer (sağ): 3-12 kelime — kısa tanım, EŞSİZ olsun (başka sol tarafla karışmasın).
- Tür çeşitliliği: Kavram↔Tanım, Olay↔Tarih, Eser↔Yazar, Antlaşma↔Sonuç. En az 3 tür karıştır.
- Aynı kategori art arda 3'ten fazla kullanılamaz.
- Müfredat odaklı; karıştırılabilen kavramlar tercih.

⚠️ KESİN YASAKLAR: Eksik sayı (örn: 9 veya 11 yerine 10), \uFFFD/◆, genel "Osmanlı" gibi belirsiz sol taraf, tekrar eden kavram, kod bloğu.

JSON çıktısı (DİKKAT: Tam ${count} öğe, sayıyı kontrol et):
[{"topicId":"${topicId}","question":"Tanzimat Fermanı","answer":"1839'da Abdülmecid döneminde ilan edildi","id":"match_${ts}_1"}]${refBlock}`,

        productivity: (() => {
            // Flutter kategori ID'si bekleniyor (timeManagement, motivation, ...).
            // Geri uyumluluk için eski TR topic ID'lerini de haritalayalım.
            const categoryMap = {
                timeManagement: {
                    label: 'Zaman Yönetimi',
                    focus: 'Pomodoro, time-blocking, Eisenhower matrisi, Parkinson yasası, 2-dakika kuralı, Deep Work slotları, Ivy Lee metodu, Eat the Frog'
                },
                motivation: {
                    label: 'Motivasyon',
                    focus: 'SMART hedefler, erteleme ile mücadele, zincir kırmama (Seinfeld), küçük kazanım, ritüel oluşturma, görselleştirme, why-ladder'
                },
                studyPlanning: {
                    label: 'Çalışma Planlama',
                    focus: 'Haftalık/günlük plan, aralıklı tekrar (SRS), Leitner, konu rotasyonu, deneme sınavı programı, zayıf konu önceliklendirme'
                },
                concentration: {
                    label: 'Odaklanma',
                    focus: 'Deep work, dikkat dağıtıcı sindirimi, Flow durumu, dijital detoks, 90 dk ultradiyen ritmi, mindful breath, single-tasking'
                },
                breakGuide: {
                    label: 'Mola Rehberi',
                    focus: 'NSDR/Yoga Nidra, 20-20-20 kuralı, Niksen, aktif dinlenme, doğa yürüyüşü, uyku-performans, güneş ışığı molası'
                },
                examFastLearning: {
                    label: 'Sınav & Hızlı Öğrenme',
                    focus: 'Feynman tekniği, aralıklı tekrar, çekirdek kavram çıkarma, sorudan başlama, deneme analizi, zor soru bankası, net hesabı taktikleri'
                },
                noteMemory: {
                    label: 'Not & Hafıza Teknikleri',
                    focus: 'Hafıza sarayı (method of loci), bağdaştırma, görselleştirme, akronim, Cornell notları, zihin haritası, chunking, mnemonic'
                },
                // Eski TR ID'ler (geri uyumluluk)
                'zaman-yonetimi': { label: 'Zaman Yönetimi', focus: 'Pomodoro, time-blocking, Eisenhower, Parkinson yasası' },
                'motivasyon': { label: 'Motivasyon', focus: 'SMART hedefler, erteleme ile mücadele' },
                'calisma-planlama': { label: 'Çalışma Planlama', focus: 'Haftalık plan, SRS, deneme programı' },
                'odaklanma': { label: 'Odaklanma', focus: 'Deep work, Flow, dijital detoks' },
                'mola-rehberi': { label: 'Mola Rehberi', focus: 'NSDR, 20-20-20, aktif dinlenme' },
                'sinav-hizli-ogrenme': { label: 'Sınav & Hızlı Öğrenme', focus: 'Feynman, hızlı okuma' },
                'hafiza-teknikleri': { label: 'Not & Hafıza Teknikleri', focus: 'Hafıza sarayı, mnemonik, Cornell' },
            };
            const cat = categoryMap[topicId] || { label: topicName, focus: '[bu kategoriye özgü teknikler]' };
            // Flutter category alanı MUTLAKA kategori ID'si olmalı
            const flutterCategoryId = topicId;

            return `KPSS adayları için "${cat.label}" kategorisinde ${count} adet DERİN, UYGULANABİLİR ve BİRBİRİNDEN FARKLI çalışma tekniği üret.
Odak alanlar (ilham): ${cat.focus}
${difficultyGuide}
${existingSummary}

ÇEŞİTLİLİK (zorunlu):
- Her teknik FARKLI mekanizma üzerine kurulu (zamanlama / aralıklı tekrar / görselleştirme / ritüel / çevre tasarımı / biyolojik ritim...).
- Farklı süre profilleri karışık: 2-5 dk mikro teknikler, 25 dk seanslar, haftalık/aylık sistemler.
- Farklı kaynaklar: Francesco Cirillo, Cal Newport, Barbara Oakley, Andrew Huberman, Tony Buzan, James Clear, David Allen, Leitner, klasik hafıza sarayı (Simonides), Feynman, Ivy Lee, Eisenhower, Seinfeld vb.
- AYNI MEKANİZMA TEKRAR YOK: "Pomodoro" ile "25 dk odak" aynı şey — tek sefer. "Time-blocking" ile "takvim blokları" aynı — tek sefer.

ŞEMA (Flutter StudyTechnique — HER ALAN ZORUNLU ve DOLU):
- id: kısa-ingilizce-tire (ör. "pomodoro", "feynman-technique", "time-blocking"). Yasak listedekini tekrar etme.
- title: Türkçe ad + parantez içinde çarpıcı kısa tanım (ör. "Pomodoro Tekniği (25 dk odak + 5 dk mola döngüsü)"). 4-12 kelime.
- category: TAM OLARAK "${flutterCategoryId}".
- shortDescription: 1 cümle, 8-16 kelime, tekniğin ÖZÜNÜ anlatır (genel laf değil).
- fullDescription: 220-380 kelime, 2-3 paragraf. ŞU SIRAYLA:
    (1) Teknik nedir + kim geliştirdi + hangi yıl/bağlam (1 paragraf, ~80-120 kelime).
    (2) Bilimsel/psikolojik temeli + neden işe yarar — mümkünse bir çalışma/kavrama atfet (aralıklı tekrar → Ebbinghaus unutma eğrisi, akış → Csikszentmihalyi vb.) (~80-130 kelime).
    (3) KPSS adayına UYARLANMIŞ pratik: hangi ders tipinde, günün hangi saatinde, hangi konu türünde en verimli (~60-100 kelime).
- steps: 5-8 sıralı adım. Her adım FİİL ile başlar, 15-35 kelime, ÇOK SOMUT (zamanı/aracı/sayıyı belirt). "Odaklan" DEĞİL "Telefonu başka odaya koy ve 25 dakikalık sayaç başlat".
- benefits: 5-7 somut fayda. Her biri 8-20 kelime. Ölçülebilir/gözlemlenebilir olsun ("dikkat süresi 3 hafta içinde belirgin artar", "genel yetenek net ortalaması yükselir"). "İyi hissettirir" GİBİ BELİRSİZ İFADE YOK.
- tips: 4-6 pratik ipucu, her biri 10-25 kelime. Yaygın hatalara/tuzağa değinsin ("İlk hafta 25 dk uzun gelebilir, 15 dk ile başlayıp artır").
- example: ZORUNLU, 2-4 cümle (50-100 kelime). GERÇEK KPSS senaryosu: "Ayşe Tarih çalışırken... şöyle uyguladı... şu sonucu aldı..." Somut ders/konu/süre geçsin.

KALİTE FİLTRESİ:
- Genel-geçer laflar, klişe öğütler ("motive ol", "erken yat", "çok çalış") YASAK.
- Psödo-bilim (Mozart etkisi, sağ-sol beyin, renkli kalem "şifresi") YASAK.
- Her teknik PROFESYONEL bir çalışma koçu tarafından yazılmış gibi ciddi ve kaynaklı olsun.
- Boş dizi/alan YASAK. Kod bloğu, önsöz/sonsöz, markdown başlık YASAK. \uFFFD/◆ karakter YASAK.

JSON çıktı (tam ${count} öğe, yalnız JSON dizisi):
[{"id":"pomodoro","title":"Pomodoro Tekniği (25 dk odak + 5 dk mola döngüsü)","category":"${flutterCategoryId}","shortDescription":"25 dakika kesintisiz odaklanma ve 5 dakika mola ile çalışmayı yönetir.","fullDescription":"...220-380 kelime, 3 paragraf...","steps":["Telefonu başka odaya koy ve 25 dakikalık sayaç kur...","..."],"benefits":["Dikkat süresi 3 haftada belirgin artar...","..."],"tips":["İlk hafta 25 dk uzun gelebilir; 15 dk ile başla...","..."],"example":"Ahmet Anayasa çalışırken 4 pomodoro (2 saat) yaptı. İlk iki seans maddeleri okudu, üçüncüde not çıkardı, dördüncüde deneme sorusu çözdü. Bir haftada o konudan net ortalaması 4'ten 7'ye çıktı."}]${refBlock}`;
        })(),

        questions: `ÖSYM standardında KPSS sorusu üret. Konu: "${topicName}".
${difficultyGuide}
${existingSummary}
🎯 ZORUNLU GÖREV: Tam ${count} adet soru üret. 1 eksik veya 1 fazla olursa geçersiz sayılır. Her soru farklı kavram/olay içermeli.

SORU KÖKÜ (q):
- Min 5 kelime; türe göre 15-55 kelime.
- Akademik Türkçe, ipucu yok.
- En az 4 FARKLI türü karıştır (art arda aynı tür max 2 kez):
  1) Klasik bilgi (15-25 kelime) — "... hangi padişah / hangi tarihte ..."
  2) Bağlamsal/yorum (30-55 kelime) — 1-2 cümle bağlam + çıkarım.
  3) Öncüllü (I, II, III) — "Yalnız I", "I ve II", "II ve III" şıklarıyla.
  4) Olumsuz kök ("...değildir/yanlıştır") — toplam %15-25.
  5) Karşılaştırma/sebep-sonuç.
  6) Tanım↔kavram eşleştirme.
  7) Görsel-tarifli (metinde tarif — gerçek görsel yok).
Hedef dağılım: ~%25 klasik · %30 bağlamsal · %15 öncüllü · %15 olumsuz · %15 diğer.

ŞIKLAR (o):
- Tam 5 şık, hiçbiri boş değil, 2-10 kelime, dramatik uzunluk farkı yok.
- Gramatik uyum, çeldiriciler makul ve anlamca örtüşmesin.
- YASAK çeldiriciler: "Hepsi", "Hiçbiri", "Yukarıdakilerin tümü", "Doğru cevap yok".
- ŞIK PREFIX'İ KESİNLİKLE YOK: "A)", "B)", "1.", "a)" gibi ek KOYMA. Yalnız içerik.
  YANLIŞ: ["A) Osmanlı", "B) Selçuklu"]  DOĞRU: ["Osmanlı", "Selçuklu"]
- İstisna: Öncüllü (Tür 3) sorularda "Yalnız I", "I ve II" şık içeriğidir — normaldir.
- Doğru cevap yeri ${count} soruda dengeli dağılsın.

CEVAP (a): 0-4 index (A=0..E=4). Tartışmasız kaynaklı.
AÇIKLAMA (e): 100-220 karakter. Format: "Doğru cevap [HARF]. [Gerekçe + çeldirici notu]."
YASAK: Düşünce süreci, seçenek analizi ("Seçenekleri inceleyelim:", "Şıkları analiz edelim:", "Sözcüklerin yapısını inceleyelim:" vb.) veya iç monolog ifadeleri KESİNLİKLE yazma. Sadece tek cümle özet.
ALT KONU: subtopic (TR, büyük harfle) + subtopicId (küçük harf, tire). En az 3-5 farklı subtopic.

${count} sorunun hepsi FARKLI kavram/olay. Zamansız (2024 Cumhurbaşkanı gibi güncel YOK).
YASAK: \uFFFD/◆, 80+ kelime kök, bilgi hatası, kod bloğu, önsöz.

JSON şablonu (tam ${count} öğe):
[{"id":"${topicId.substring(0, 6)}_${ts}_1","topicId":"${topicId}","subtopicId":"alt-konu","subtopic":"Alt Konu Başlığı","q":"... min 15 kelime soru ...","o":["Şık1","Şık2","Şık3","Şık4","Şık5"],"a":2,"e":"Doğru cevap C. [gerekçe, 100-220 karakter]."}]${refBlock}`
    };

    // Modül + count'a göre dinamik max_tokens — kısa çıktı/truncation sorununu önler
    //  questions: ~400 tok/soru · flashcards: ~200 tok · matching: ~120 tok · productivity: ~1500 tok (derin içerik)
    //  Her durumda %40 buffer ekliyoruz; alt sınır 4000, üst sınır 48000
    //  NOT: productivity öğeleri fullDescription 220-380 kelime + 5-8 step + 5-7 benefit + 4-6 tip + example içerir;
    //  her öğe ~1400 token kadar çıkabilir. Kısa kesilmemesi için bu modülde özellikle yüksek tutuyoruz.
    // Token limiti kaldırıldı - model kendi varsayılan limitini kullanacak
    const maxTokens = undefined;

    aiLog('generate', `⚡ DOĞRUDAN TOPLU ÜRETİM: ${count} ${moduleType} → 1 API çağrısı (token limiti: yok)`, requestLogs);
    const content = await callWithModelFallback(prompts[moduleType], model, apiKey, true, requestLogs, requestTimeoutMs, maxRetries, maxTokens);
    const parsed = parseAIResponse(content, moduleType, topicId, 1, requestLogs);
    if (onProgress) onProgress(count, count);
    aiLog('success', `✅ ${parsed.length} ${moduleType} üretildi (1 API çağrısı)`, requestLogs);
    return parsed;
}

// Birden fazla bölümü tek promptta birleştir (explanations / stories)
function _buildBatchContentPrompt(moduleType, topicName, topicId, batch, partNums, allSections, difficulty = 'medium') {
    const batchList = batch.map((s, i) =>
        `Bölüm ${partNums[i]}: ${s.title} | Anahtar noktalar: ${s.key_points?.join(', ') || '-'}`
    ).join('\n');
    const difficultyGuide = buildDifficultyGuide(difficulty, moduleType);

    if (moduleType === 'explanations') {
        const now = new Date().toISOString();
        return `Sen, MEB müfredatına ve ÖSYM'nin KPSS soru tarzına hakim uzman bir eğitim içeriği editörüsün.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
KONU: "${topicName}"
GÖREV: Aşağıdaki ${batch.length} bölümü EKSİKSİZ olarak JSON dizisi olarak üret.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${difficultyGuide}

BÖLÜMLER:
${batchList}

🎯 HER BÖLÜM İÇİN KALİTE KURALLARI

1. İÇERİK YAPISI (content dizisi):
   • 6-9 blok — zengin ve çeşitli
   • Blok tipleri: heading, text, bulletList, warning, highlighted
   • Her bölüm en az 1 "highlighted" (kritik bilgi vurgusu) içersin
   • İdeal sıralama: heading → text (giriş) → bulletList → text (detay) → highlighted (özet)

2. METİN KALİTESİ:
   • "text" blokları: 3-5 cümle, akademik-anlaşılır dil
   • "bulletList" blokları: 4-7 madde, "• " ile başlayan, "\\n" ile ayrılan
   • "warning": nadir kullan, yaygın hatalara karşı uyarı (max 1 per bölüm)
   • "highlighted": KPSS'te sıkça sorulan püf nokta

3. KPSS ODAĞI:
   • Tarih-isim-yer üçlüsünü net ve doğru ver
   • Sebep-sonuç ilişkilerini somutlaştır
   • "Bu konudan çıkacak tipik sınav sorusu" zihniyetiyle yaz
   • Marjinal bilgi değil, müfredat çekirdeği

4. BÖLÜMLER ARASI:
   • Her bölüm kendi başına anlamlı (ama akış bozulmasın)
   • Önceki/sonraki bölüme açık referans VERME ("önceki bölümde..." YASAK)
   • Tekrar YOK — her bölüm FARKLI alt konuyu işler

⚠️ KESİN YASAKLAR:
• "..." ile yarım bırakma YASAK — TÜM metinler dolu
• Replacement karakter (\uFFFD, ◆, ?) YASAK
• Kod bloğu (\`\`\`) veya önsöz/sonsöz YASAK

BEKLENEN JSON (TAM ${batch.length} ÖĞE, EKSİKSİZ İÇERİKLE):
[
${batch.map((s, i) => `  {
    "topicId": "${topicId}",
    "title": "Bölüm ${partNums[i]}: ${s.title}",
    "content": [
      {"type": "heading", "text": "${s.title}"},
      {"type": "text", "text": "[Giriş — 3-5 cümle]"},
      {"type": "bulletList", "text": "• [madde 1]\\n• [madde 2]\\n• [madde 3]\\n• [madde 4]"},
      {"type": "text", "text": "[Detay — 3-5 cümle]"},
      {"type": "highlighted", "text": "[KPSS'te sıkça sorulan püf nokta]"}
    ],
    "type": "detailed",
    "difficulty": "${difficulty}",
    "id": "exp_${Date.now() + i}_${topicId.substring(0, 4)}_${partNums[i]}",
    "createdAt": "${now}",
    "updatedAt": "${now}"
  }`).join(',\n')}
]

ÇIKTI: SADECE JSON dizisi. Tüm ${batch.length} bölümü eksiksiz doldur — "[...]" yer tutucularının yerini gerçek içerikle değiştir.`;
    }

    // stories
    const now = new Date().toISOString();
    return `Sen, tarihi olayları, kavramları ve süreçleri CANLI HİKAYE formatında anlatan uzman bir eğitim içeriği editörüsün. Amacın kuru bilgiyi akılda kalıcı bir anlatıya çevirmek.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
KONU: "${topicName}"
GÖREV: Aşağıdaki ${batch.length} bölümü AKICI HİKAYE formatında üret.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${difficultyGuide}

BÖLÜMLER:
${batchList}

🎯 HİKAYE KALİTE KURALLARI

1. İÇERİK (content):
   • 200-400 kelime arası akıcı anlatı
   • BAŞLANGIÇ: Bir sahne/zaman/karakter ile aç (örn. "1299 yılının soğuk bir kış sabahında...")
   • ORTA: Olayın gelişimi, sebep-sonuç zinciri, aktörlerin kararları
   • SON: Sonuç ve tarihî önemi (eğitsel vurguya bağlan)
   • 3. tekil şahıs, geçmiş zaman — akademik ama canlı
   • Tarih, isim ve yer bilgileri DOĞRU ve net

2. ANAHTAR NOKTALAR (key_points):
   • 3-5 madde, her biri KISA (5-12 kelime)
   • KPSS'te sınava girebilecek bilgiler
   • Hikayenin "özet kartı" niteliğinde

3. EĞİTSEL VURGU:
   • Hikayede "neden önemli?" sorusu cevaplanmalı
   • Müfredat bilgisini hikayeye ÖRÜLMÜŞ şekilde ver
   • Spekülasyon/kurgusal diyalog YASAK — sadece tarihî gerçek

⚠️ KESİN YASAKLAR:
• "Hikaye içeriği..." gibi yer tutucu YASAK — gerçek içerik zorunlu
• Kurgu karakter/diyalog YASAK (gerçek tarihî kişiler evet)
• Replacement karakter (\uFFFD, ◆) YASAK
• Kod bloğu veya önsöz YASAK

BEKLENEN JSON (TAM ${batch.length} öğe):
[
${batch.map((s, i) => `  {
    "topicId": "${topicId}",
    "title": "Bölüm ${part}: ${s.title}",
    "content": "[200-400 kelimelik akıcı tarihî/kavramsal anlatı]",
    "key_points": ["[madde 1]", "[madde 2]", "[madde 3]"],
    "type": "story",
    "id": "story_${Date.now() + i}_${topicId.substring(0, 4)}_${part}",
    "createdAt": "${now}",
    "updatedAt": "${now}"
  }`).join(',\n')}
]

ÇIKTI: SADECE JSON dizisi. Tüm ${batch.length} bölümü gerçek içerikle doldur.`;
}

// Syllabus (Konu outline) oluşturma promptu
// ═════════════════════════════════════════════════════════════════════════════
// MEVCUT İÇERİK ÖZETİ — AI'ın tekrar üretmemesi için yasak liste
// ═════════════════════════════════════════════════════════════════════════════
/**
 * Bir modül + topicId için halihazırda mevcut (yayınlanmış + taslak) içerikleri özetler
 * ve AI'ın TEKRAR ÜRETMEMESİ gereken ID/başlık listesini prompta enjekte edilecek
 * formatta döndürür. En çok productivity için kritik — aynı tekniği tekrar tekrar üretme
 * sorununu önler.
 */
function _buildExistingItemsBlock(moduleType, items) {
    if (!Array.isArray(items) || items.length === 0) return '';

    let header, lines;
    const seen = new Set();

    if (moduleType === 'productivity') {
        lines = items.map(it => {
            const id = (it.id || '').toString().trim();
            const title = (it.title || '').toString().trim();
            const key = (id || title).toLowerCase();
            if (!key || seen.has(key)) return null;
            seen.add(key);
            return `- ${id}${title ? ` (${title.length > 50 ? title.substring(0, 47) + '...' : title})` : ''}`;
        }).filter(Boolean);
        header = 'ZATEN VAR (bunları tekrar etme — id ve benzer mekanizma yasak):';
    } else if (moduleType === 'flashcards' || moduleType === 'matching_games') {
        lines = items.slice(0, 30).map(it => {
            const q = (it.question || it.left || it.front || '').toString().trim();
            if (!q || seen.has(q.toLowerCase())) return null;
            seen.add(q.toLowerCase());
            return `- ${q.length > 70 ? q.substring(0, 67) + '...' : q}`;
        }).filter(Boolean);
        header = 'ZATEN VAR (aynı konuyu tekrar etme):';
    } else if (moduleType === 'questions') {
        lines = items.slice(0, 25).map(it => {
            const q = (it.q || it.question || '').toString().trim();
            if (!q || seen.has(q.toLowerCase())) return null;
            seen.add(q.toLowerCase());
            return `- ${q.length > 80 ? q.substring(0, 77) + '...' : q}`;
        }).filter(Boolean);
        header = 'ZATEN VAR (aynı soruyu/konuyu tekrar etme):';
    } else {
        return '';
    }

    if (lines.length === 0) return '';
    return `\n${header}\n${lines.join('\n')}\n`;
}

// ZORLUK KILAVUZU — tüm promptlara enjekte edilen ortak blok
// ═════════════════════════════════════════════════════════════════════════════
function buildDifficultyGuide(difficulty, moduleType) {
    const base = {
        easy: 'Zorluk: KOLAY — doğrudan bilgi hatırlama, bağlam max 1 cümle, çıkarım yok. Dağılım: %80 olgu · %20 basit eşleştirme.',
        medium: 'Zorluk: ORTA (standart KPSS) — 1-2 cümle bağlam + çıkarım. Dağılım: %25 kolay · %50 orta · %25 zor.',
        hard: 'Zorluk: ZOR — 2-3 cümle bağlam + çok adımlı çıkarım, yakın çeldiriciler. Dağılım: %15 kolay · %35 orta · %50 zor.',
    };
    return base[difficulty] || base.medium;
}

function buildSyllabusPrompt(moduleType, topicName, topicId, count) {
    return `Sen, MEB müfredatına ve KPSS sınavına hakim bir eğitim uzmanısın.

GÖREV: "${topicName}" konusu için ${count} adet alt-başlık/alt-konu içeren bir İÇİNDEKİLER (Outline/Syllabus) oluştur.

ÖNEMLİ KURALLAR:
1. Başlıklar sıralı ve mantıklı bir akışta olmalı (girişten ileri seviyeye)
2. Her başlık birbirini tekrar ETMEMELİ - tamamen benzersiz içerikler
3. Başlıklar KPSS müfredatına uygun, akademik ve anlaşılır olmalı
4. Konu bütünlüğü sağlanmalı - tüm başlıklar bir arada anlamlı bir bütün oluşturmalı

BEKLENEN JSON FORMATI:
{
  "sections": [
    {"index": 1, "title": "Bölüm 1: [Başlık]", "key_points": ["Nokta 1", "Nokta 2"]},
    {"index": 2, "title": "Bölüm 2: [Başlık]", "key_points": ["Nokta 1", "Nokta 2"]},
    ...${count} adet
  ]
}

SADECE JSON döndür, başka açıklama ekleme.`;
}

// Parse syllabus response
function parseSyllabusResponse(content, requestLogs = null) {
    try {
        aiLog('syllabus', `📋 Syllabus parse ediliyor... (${content.length} karakter)`, requestLogs);

        // JSON'ı temizle
        let cleanContent = content.trim();

        // Markdown code block içindeyse çıkar
        if (cleanContent.includes('```json')) {
            cleanContent = cleanContent.split('```json')[1].split('```')[0].trim();
        } else if (cleanContent.includes('```')) {
            cleanContent = cleanContent.split('```')[1].split('```')[0].trim();
        }

        // JSON kısmını bul
        const jsonMatch = cleanContent.match(/\[[\s\S]*\]|\{[\s\S]*\}/);
        if (jsonMatch) {
            cleanContent = jsonMatch[0];
        }

        // Common JSON hatalarını düzelt
        cleanContent = cleanContent
            .replace(/,\s*([}\]])/g, '$1')  // Trailing commas
            .replace(/\n/g, ' ')
            .replace(/\r/g, ' ')
            .replace(/\t/g, ' ');

        const parsed = JSON.parse(cleanContent);

        if (parsed.sections && Array.isArray(parsed.sections)) {
            aiLog('syllabus', `✅ Syllabus parse edildi: ${parsed.sections.length} bölüm`, requestLogs);
            return parsed.sections;
        }

        // Eğer direkt array döndüyse
        if (Array.isArray(parsed)) {
            aiLog('syllabus', `✅ Syllabus parse edildi (array): ${parsed.length} bölüm`, requestLogs);
            return parsed;
        }

        throw new Error('Geçersiz syllabus formatı: sections array bulunamadı');
    } catch (e) {
        aiLog('error', `❌ Syllabus parse hatası: ${e.message}`, requestLogs);
        aiLog('error', `📝 Ham içerik (ilk 500 karakter): ${content.substring(0, 500)}`, requestLogs);
        throw new Error('Syllabus parse hatası: ' + e.message);
    }
}

// Detaylı içerik üretim promptu (Syllabus tabanlı — tek bölüm fallback)
function buildDetailedContentPrompt(moduleType, topicName, topicId, part, sectionInfo, allSections, difficulty = 'medium') {
    const contextInfo = allSections.map((s, i) =>
        `${i + 1}. ${s.title}${i + 1 === part ? ' (ŞU AN BU BÖLÜMÜ ÜRETİYORSUN)' : ''}`
    ).join('\n');
    const difficultyGuide = buildDifficultyGuide(difficulty, moduleType);

    const basePrompt = {
        explanations: `Sen, MEB müfredatına ve ÖSYM'nin KPSS soru tarzına hakim uzman bir eğitim içeriği editörüsün.

${difficultyGuide}

KONU: "${topicName}"

TÜM BÖLÜMLER (bağlam için):
${contextInfo}

ŞU AN ÜRETİLECEK BÖLÜM:
• Bölüm No: ${part}
• Başlık: ${sectionInfo.title}
• Anahtar Noktalar: ${sectionInfo.key_points?.join(', ') || 'Belirtilmemiş'}

🎯 KURALLAR:
1. SADECE bu bölümü üret — diğerlerine dokunma
2. Başlık formatı: "Bölüm ${part}: [Başlık]"
3. 6-9 content bloğu: heading, text, bulletList, warning, highlighted
4. 'text': 3-5 cümle, akademik-anlaşılır
5. 'bulletList': 4-7 madde, "• " prefix, "\\n" ayraç
6. En az 1 "highlighted" (KPSS'te sıkça sorulan püf nokta) içermeli
7. Önceki/sonraki bölüme referans YASAK

⚠️ YASAKLAR: "..." ile yarım bırakma, replacement karakter, kod bloğu, önsöz.

BEKLENEN JSON:
[{
  "topicId": "${topicId}",
  "title": "Bölüm ${part}: ${sectionInfo.title}",
  "content": [
    {"type": "heading", "text": "[başlık]"},
    {"type": "text", "text": "[giriş 3-5 cümle]"},
    {"type": "bulletList", "text": "• [madde 1]\\n• [madde 2]\\n• [madde 3]\\n• [madde 4]"},
    {"type": "text", "text": "[detay 3-5 cümle]"},
    {"type": "highlighted", "text": "[KPSS püf noktası]"}
  ],
  "type": "detailed",
  "difficulty": "${difficulty}",
  "id": "exp_${Date.now() + i}_${topicId.substring(0, 4)}_${part}",
  "createdAt": "${new Date().toISOString()}",
  "updatedAt": "${new Date().toISOString()}"
}]

ÇIKTI: SADECE JSON.`,

        stories: `Sen, tarihi olayları ve kavramları CANLI HİKAYE formatında anlatan uzman bir editörsün.

${difficultyGuide}

KONU: "${topicName}"
BÖLÜM ${part}: ${sectionInfo.title}
ANAHTAR NOKTALAR: ${sectionInfo.key_points?.join(', ') || '-'}

🎯 KURALLAR:
• 200-400 kelime akıcı anlatı
• BAŞLANGIÇ: Bir sahne/zaman/karakter ile aç
• ORTA: Sebep-sonuç zinciri, aktörlerin kararları
• SON: Sonuç ve tarihî önemi
• 3. tekil şahıs, geçmiş zaman — akademik ama canlı
• Tarih/isim/yer DOĞRU — kurgu karakter YASAK

key_points: 3-5 KISA madde (5-12 kelime), KPSS odaklı.

BEKLENEN JSON:
[{
  "topicId": "${topicId}",
  "title": "Bölüm ${part}: ${sectionInfo.title}",
  "content": "[200-400 kelimelik gerçek anlatı]",
  "key_points": ["[madde 1]", "[madde 2]", "[madde 3]"],
  "type": "story",
  "id": "story_${Date.now() + i}_${topicId.substring(0, 4)}_${part}",
  "createdAt": "${new Date().toISOString()}",
  "updatedAt": "${new Date().toISOString()}"
}]

ÇIKTI: SADECE JSON.`
    };

    return basePrompt[moduleType] || basePrompt.explanations;
}

// ═══════════════════════════════════════════════════════════════════════════
// QUALITY CONTROL (Self-Reflection)
// ═══════════════════════════════════════════════════════════════════════════

async function performQualityCheck(content, topicName, moduleType, model, apiKey) {
    // Hızlı/kaliteli kontrol için ucuz model kullan (gemini flash)
    const checkModel = model.includes('gemini') ? model : 'google/gemini-2.5-flash-lite';

    const contentPreview = JSON.stringify(content).substring(0, 500);

    const checkPrompt = `Sen bir eğitim içeriği denetçisisin. Aşağıdaki KPSS içeriğini kontrol et:

KONU: ${topicName}
MODÜL: ${moduleType}
İÇERİK ÖZET: ${contentPreview}

KONTROL KRİTERLERİ:
1. MEB müfredatına uygun mu?
2. Tarihsel/akademik hata var mı?
3. KPSS sorusu olarak uygun mu?
4. Tekrar eden/çoğaltılmış içerik var mı?

SONUÇ JSON:
{"passed": true/false, "issues": ["varsa hata 1", "hata 2"], "score": 1-10}

SADECE JSON döndür.`;

    try {
        const result = await callOpenRouterWithRetry(checkPrompt, checkModel, apiKey, true);
        const parsed = JSON.parse(result);
        return {
            passed: parsed.passed !== false && (parsed.score || 0) >= 6,
            issues: parsed.issues || [],
            score: parsed.score || 0
        };
    } catch (e) {
        // Kalite kontrolü başarısız olsa bile içeriği kabul et
        return { passed: true, issues: [], score: 7 };
    }
}

// Auto-Retry wrapper for API calls
async function callOpenRouterWithRetry(prompt, model, apiKey, jsonMode = false, maxRetries = 3, requestLogs = null, requestTimeoutMs = 240000, maxTokens = undefined) {
    let lastError;

    aiLog('retry', `🔄 callOpenRouterWithRetry başlatıldı: ${maxRetries} deneme hakkı`, requestLogs);

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            aiLog('retry', `⏳ Deneme ${attempt}/${maxRetries}...`, requestLogs);
            const startTime = Date.now();
            const result = await callOpenRouter(prompt, model, apiKey, jsonMode, requestLogs, requestTimeoutMs, maxTokens);
            const duration = Date.now() - startTime;
            aiLog('success', `✅ Deneme ${attempt} başarılı! (${duration}ms)`, requestLogs);
            return result;
        } catch (e) {
            lastError = e;
            aiLog('error', `❌ Deneme ${attempt} başarısız: ${e.message}`, requestLogs);
            aiLog('error', `   Hata tipi: ${e.code || 'N/A'}`, requestLogs);

            if (attempt < maxRetries) {
                const delay = Math.min(1000 * Math.pow(2, attempt - 1), 5000); // Exponential backoff
                aiLog('retry', `⏱️ ${delay}ms sonra yeniden deneniyor...`, requestLogs);
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }
    }

    aiLog('error', `❌ ${maxRetries} deneme sonrası başarısız`, requestLogs);
    throw new Error(`${maxRetries} deneme sonrası başarısız: ${lastError.message}`);
}

// Enhanced OpenRouter call with JSON Mode support
function callOpenRouter(prompt, model, apiKey, jsonMode = false, requestLogs = null, requestTimeoutMs = 240000, maxTokens = undefined) {
    return new Promise((resolve, reject) => {
        // Terminal'de görünmesi için console.log
        console.log('══════════════════════════════════════════════════');
        console.log('📤 OpenRouter API isteği hazırlanıyor...');
        console.log('   🤖 Model:', model);
        console.log('   📊 JSON Mode:', jsonMode ? 'Aktif' : 'Pasif');
        console.log('   📝 Prompt uzunluğu:', prompt.length, 'karakter');
        console.log('   🔑 API Key başlangıcı:', apiKey ? apiKey.substring(0, 10) + '...' : 'YOK!');

        // Dashboard loglarına da ekle
        aiLog('api', `══════════════════════════════════════════════════`, requestLogs);
        aiLog('api', `📤 OpenRouter API isteği hazırlanıyor...`, requestLogs);
        aiLog('api', `   🤖 Model: ${model}`, requestLogs);
        aiLog('api', `   📊 JSON Mode: ${jsonMode ? 'Aktif' : 'Pasif'}`, requestLogs);
        aiLog('api', `   📝 Prompt uzunluğu: ${prompt.length} karakter`, requestLogs);
        aiLog('api', `   🔑 API Key: ${apiKey ? apiKey.substring(0, 15) + '...' : 'YOK!'}`, requestLogs);

        const requestBody = {
            model: model,
            messages: [
                { role: 'system', content: 'Sen profesyonel bir eğitim içeriği üreticisisin. KURAL: Promptta belirtilen sayıda öğeyi TAM ve EKSİKSİZ üretmek ZORUNLUDUR. Örnek: "10 adet" denildiyse JSON dizisinde tam 10 öğe olmalı, 9 veya 11 olmamalı. Sadece geçerli JSON döndür. Kod bloğu, önsöz, açıklama YAZMA.' },
                { role: 'user', content: prompt }
            ],
            temperature: 0.7,
            ...(maxTokens && { max_tokens: maxTokens })
        };

        // JSON Mode desteği
        if (jsonMode) {
            requestBody.response_format = { type: "json_object" };
        }

        // OpenAI GPT-5 serisi reasoning token'ları çok kullanıyor, yanıt boş kalabilir.
        // Onlarda reasoning'i kapat. DeepSeek ve Grok'ta `reasoning: false` yanıtı KISA kesiyor
        // (tespit edildi — DeepSeek reasoning OFF → 620 char vs. reasoning ON → 7700 char).
        // NOT: gpt-5-nano ve gpt-5.4-nano reasoning'i ZORUNLU tutuyor, disabled desteklemiyor.
        const disableReasoningFor = [
            'openai/gpt-5-mini',
            'openai/gpt-5-pro',
            'openai/gpt-5.2',
            'openai/gpt-5.1',
            'openai/gpt-5',
        ];
        if (disableReasoningFor.includes(model)) {
            requestBody.reasoning = { enabled: false };
        }

        const data = JSON.stringify(requestBody);

        const options = {
            hostname: 'openrouter.ai',
            port: 443,
            path: '/api/v1/chat/completions',
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
                'HTTP-Referer': 'http://localhost:3456',
                'X-Title': 'KPSS Dashboard AI Content Generator'
            },
            timeout: requestTimeoutMs
        };

        console.log('📡 API isteği gönderiliyor...');
        aiLog('api', `📡 API isteği gönderiliyor...`, requestLogs);

        const req = https.request(options, (res) => {
            console.log('📥 HTTP Yanıt:', res.statusCode, res.statusMessage);
            aiLog('api', `📥 HTTP Yanıt: ${res.statusCode} ${res.statusMessage}`, requestLogs);

            let chunks = [];

            res.on('data', (chunk) => {
                // Buffer olarak topla - Türkçe karakterler chunk sınırında bölünmesin
                chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
            });

            res.on('end', () => {
                // Tüm chunk'ları birleştirip UTF-8 olarak decode et
                const responseData = Buffer.concat(chunks).toString('utf8');
                aiLog('api', `📄 Yanıt boyutu: ${responseData.length} karakter`, requestLogs);

                try {

                    const parsedResponse = JSON.parse(responseData);

                    if (res.statusCode && res.statusCode >= 400) {
                        const errorMessage = parsedResponse.error?.message || `HTTP ${res.statusCode} ${res.statusMessage || ''}`.trim();
                        aiLog('error', `❌ OpenRouter HTTP hatası: ${errorMessage}`, requestLogs);
                        reject(new Error(`OpenRouter HTTP hatası: ${errorMessage}`));
                        return;
                    }

                    if (parsedResponse.error) {
                        aiLog('error', `❌ OpenRouter hatası: ${JSON.stringify(parsedResponse.error)}`, requestLogs);
                        reject(new Error(`OpenRouter hatası: ${parsedResponse.error.message || JSON.stringify(parsedResponse.error)}`));
                        return;
                    }

                    const content = parsedResponse.choices?.[0]?.message?.content;
                    if (!content) {
                        aiLog('error', `❌ AI yanıtı boş: ${JSON.stringify(parsedResponse).substring(0, 200)}`, requestLogs);
                        reject(new Error('AI yanıtı boş'));
                        return;
                    }

                    aiLog('api', `✅ İçerik alındı: ${content.length} karakter`, requestLogs);
                    // Token kullanımını logla
                    const usage = parsedResponse.usage;
                    if (usage && usage.prompt_tokens) {
                        logApiCost(model, usage.prompt_tokens, usage.completion_tokens || 0);
                        aiLog('api', `💰 Token: ${usage.prompt_tokens} giriş + ${usage.completion_tokens || 0} çıkış`, requestLogs);
                    }
                    resolve(content);
                } catch (e) {
                    aiLog('error', `❌ JSON parse hatası: ${e.message}`, requestLogs);
                    aiLog('error', `   Ham yanıt: ${responseData.substring(0, 200)}`, requestLogs);
                    reject(new Error(`JSON parse hatası: ${e.message}`));
                }
            });
        });

        req.on('error', (e) => {
            console.log('❌ HTTP HATASI:', e.message);
            console.log('   Hata kodu:', e.code || 'N/A');
            aiLog('error', `❌ HTTP hatası: ${e.message}`, requestLogs);
            aiLog('error', `   Hata kodu: ${e.code || 'N/A'}`, requestLogs);
            reject(new Error(`HTTP hatası: ${e.message}`));
        });

        req.on('timeout', () => {
            const timeoutSec = Math.floor(requestTimeoutMs / 1000);
            console.log(`⏱️ TIMEOUT: API ${timeoutSec} saniye içinde yanıt vermedi!`);
            aiLog('error', `⏱️ Request timeout - API ${timeoutSec} saniye içinde yanıt vermedi`, requestLogs);
            req.destroy();
            reject(new Error(`Request timeout - API ${timeoutSec} saniyede yanıt vermedi`));
        });

        aiLog('api', `⏳ İstek gönderildi, yanıt bekleniyor...`, requestLogs);

        req.write(data);
        req.end();
    });
}

// NOT: Eski `buildPrompt()` fonksiyonu kaldırıldı — hiçbir yerden çağrılmıyordu.
// Tüm modüller artık `_generateDirectAll` (tek çağrılı) veya
// `_buildBatchContentPrompt` / `buildDetailedContentPrompt` üzerinden üretilir.

function parseAIResponse(content, moduleType, topicId, part, requestLogs = null) {
    try {
        aiLog('parse', `🔍 JSON parse ediliyor... (${content.length} karakter)`, requestLogs);

        // JSON'ı temizle (markdown code block içinde olabilir)
        let cleanContent = content.trim();

        // Markdown code block içindeyse çıkar
        if (cleanContent.includes('```json')) {
            cleanContent = cleanContent.split('```json')[1].split('```')[0].trim();
        } else if (cleanContent.includes('```')) {
            cleanContent = cleanContent.split('```')[1].split('```')[0].trim();
        }

        // Yanıt direkt JSON array veya obje değilse, JSON kısmını bul
        const jsonMatch = cleanContent.match(/\[[\s\S]*\]|\{[\s\S]*\}/);
        if (jsonMatch) {
            cleanContent = jsonMatch[0];
        }

        // Eksik/truncated JSON'ı tespit et ve tamamla
        // Eğer içerik } veya ] ile bitmiyorsa, eksik olabilir
        const lastChar = cleanContent.trim().slice(-1);
        const needsCompletion = !['}', ']'].includes(lastChar);

        if (needsCompletion) {
            aiLog('parse', `⚠️ Eksik JSON tespit edildi, tamamlanmaya çalışılıyor...`, requestLogs);

            // Önce trailing comma'ları kaldır
            cleanContent = cleanContent.replace(/,\s*$/, '');

            // Eksik string alanlarını kapat - daha akıllı tespit
            // Açık string'i bul: tek sayıda " varsa ve son karakter " değilse
            const quoteMatches = cleanContent.match(/"/g) || [];
            const openQuotes = quoteMatches.length;

            // Son " ile bitiyor mu kontrol et
            const endsWithQuote = cleanContent.trim().endsWith('"');

            if (openQuotes % 2 !== 0 && !endsWithQuote) {
                // Açık string var - kapat
                cleanContent += '"';
                aiLog('parse', `🔧 Açık string kapatıldı`, requestLogs);
            }

            // Eksik array/obje kapatma - önce içerik yapısını analiz et
            // Eğer array içindeysek ve son item string ise, array'i kapat
            const openBrackets = (cleanContent.match(/\[/g) || []).length - (cleanContent.match(/\]/g) || []).length;
            const openBraces = (cleanContent.match(/\{/g) || []).length - (cleanContent.match(/\}/g) || []).length;

            // Array içinde string item varsa ve kapanmamışsa
            if (openBrackets > 0 && cleanContent.match(/:\s*\[([^\]]*)$/)) {
                // Array içindeyiz ve kapanmamış
                // Son item string ise kapat, değilse sadece array'i kapat
                const lastArrayMatch = cleanContent.match(/:\s*\[([^\]]*)$/);
                if (lastArrayMatch) {
                    const insideArray = lastArrayMatch[1];
                    // Son item string mi kontrol et
                    const lastItemMatch = insideArray.match(/"[^"]*$/);
                    if (lastItemMatch && !insideArray.trim().endsWith('"')) {
                        // String açık kalmış
                        cleanContent += '"';
                    }
                }
            }

            // Kalan açık yapıları kapat
            const finalBrackets = (cleanContent.match(/\[/g) || []).length - (cleanContent.match(/\]/g) || []).length;
            const finalBraces = (cleanContent.match(/\{/g) || []).length - (cleanContent.match(/\}/g) || []).length;

            for (let i = 0; i < finalBraces; i++) cleanContent += '}';
            for (let i = 0; i < finalBrackets; i++) cleanContent += ']';

            aiLog('parse', `🔧 Tamamlanmış içerik (son 100): ${cleanContent.substring(cleanContent.length - 100)}`, requestLogs);
        }

        // Common JSON hatalarını düzelt
        cleanContent = cleanContent
            .replace(/,\s*([}\]])/g, '$1')  // Trailing commas
            .replace(/\n/g, ' ')             // Newlines
            .replace(/\r/g, ' ')             // Carriage returns
            .replace(/\t/g, ' ');            // Tabs

        aiLog('parse', `📝 Temizlenmiş içerik: ${cleanContent.substring(0, 100)}...`, requestLogs);

        let parsed;
        try {
            parsed = JSON.parse(cleanContent);
        } catch (parseErr) {
            // Hala parse edilemiyorsa, son çare: satır satır dene
            aiLog('parse', `⚠️ İlk parse başarısız, recovery deneniyor...`, requestLogs);

            // JSON array içindeki her objeyi ayrı ayrı parse etmeyi dene
            if (cleanContent.trim().startsWith('[')) {
                const items = [];

                // Daha akıllı obje çıkarma: nested objeleri de handle et
                // Array içindeki objeleri bul - { ile başlayıp } ile bitenleri
                let depth = 0;
                let start = -1;
                let inString = false;
                let escapeNext = false;

                for (let i = 0; i < cleanContent.length; i++) {
                    const char = cleanContent[i];
                    const prev = cleanContent[i - 1];

                    if (escapeNext) {
                        escapeNext = false;
                        continue;
                    }

                    if (char === '\\') {
                        escapeNext = true;
                        continue;
                    }

                    if (char === '"' && !escapeNext) {
                        inString = !inString;
                        continue;
                    }

                    if (!inString) {
                        if (char === '{') {
                            if (depth === 0) start = i;
                            depth++;
                        } else if (char === '}') {
                            depth--;
                            if (depth === 0 && start !== -1) {
                                const objStr = cleanContent.substring(start, i + 1);
                                try {
                                    const item = JSON.parse(objStr);
                                    if (item && (item.q || item.question || item.front || item.left || item.title || item.id)) {
                                        items.push(item);
                                    }
                                } catch (e) {
                                    // Tek obje parse edilemezse atla
                                }
                                start = -1;
                            }
                        }
                    }
                }

                // Fallback: Basit regex ile deneme (nested olmayan objeler için)
                if (items.length === 0) {
                    const objMatches = cleanContent.match(/\{[^{}]*\}/g);
                    if (objMatches) {
                        for (const objStr of objMatches) {
                            try {
                                const item = JSON.parse(objStr);
                                if (item && (item.q || item.question || item.front || item.left || item.title || item.id)) {
                                    items.push(item);
                                }
                            } catch (e) {
                                // Tek obje parse edilemezse atla
                            }
                        }
                    }
                }

                if (items.length > 0) {
                    aiLog('parse', `✅ Recovery ile ${items.length} item çıkarıldı`, requestLogs);
                    parsed = items;
                } else {
                    throw parseErr;
                }
            } else {
                throw parseErr;
            }
        }

        // Her item'a part numarası ekle
        if (Array.isArray(parsed)) {
            parsed.forEach((item, index) => {
                item._part = part;
                item._generatedAt = new Date().toISOString();
            });
            aiLog('parse', `✅ ${parsed.length} item parse edildi`, requestLogs);
        } else {
            parsed._part = part;
            parsed._generatedAt = new Date().toISOString();
            aiLog('parse', `✅ 1 obje parse edildi`, requestLogs);
        }

        const items = Array.isArray(parsed) ? parsed : [parsed];
        // Kaydetmeden önce sanitize et (prefix temizle, encoding bozukları çıkar, duplicate'leri dedupe et)
        const sanitized = sanitizeAIItems(items, moduleType, requestLogs, { topicId });
        return sanitized;
    } catch (e) {
        aiLog('error', `❌ JSON parse hatası: ${e.message}`, requestLogs);
        aiLog('error', `📝 Ham içerik (ilk 500 karakter): ${content.substring(0, 500)}`, requestLogs);
        throw new Error(`AI yanıtı parse edilemedi: ${e.message}`);
    }
}

/**
 * AI çıktısını kaydedilmeden önce temizler:
 *  - Sorularda şık prefix'lerini siler  ("A) metin" → "metin")
 *  - Encoding bozuk soruları filtreler  (\uFFFD içeren satırlar)
 *  - Boş zorunlu alan içeren soruları filtreler
 */
function sanitizeAIItems(items, moduleType, requestLogs = null, opts = {}) {
    const { topicId } = opts;
    const OPTION_PREFIX_RE = /^[A-Ea-e][).–\-]\s*/;
    const hasBroken = str => typeof str === 'string' && str.includes('\uFFFD');
    const wordCount = str => (String(str || '').trim().match(/\S+/g) || []).length;

    // Minimum uzunluk — sadece çöp/boş soruları filtrelemek için
    const MIN_Q_WORDS = 5;    // soru kökü en az 5 kelime
    const MIN_Q_CHARS = 25;   // veya en az 25 karakter

    let prefixFixed = 0;
    let encodingRemoved = 0;
    let emptyRemoved = 0;
    let tooShortRemoved = 0;
    let dedupRemoved = 0;

    // Duplicate tespiti için:
    //  - Bu batch içinde tekrar eden ID/başlıkları atmak (productivity)
    //  - Zaten kaydedilmiş içerikle çakışanları atmak (productivity + flashcards + matching_games)
    const batchSeenKeys = new Set();
    const existingKeys = new Set();
    if (topicId && moduleType) {
        const prior = [...readPublished(moduleType, topicId), ...readDraft(moduleType, topicId)];
        for (const p of prior) {
            if (moduleType === 'productivity') {
                if (p?.id) existingKeys.add(String(p.id).toLowerCase().trim());
                if (p?.title) existingKeys.add('T:' + String(p.title).toLowerCase().trim());
            } else if (moduleType === 'flashcards' || moduleType === 'matching_games') {
                const q = p?.question || p?.left || p?.front;
                if (q) existingKeys.add(String(q).toLowerCase().trim());
            }
        }
    }

    // Genel encoding kontrolü — tüm string alanlarda bozuk karakter varsa
    const itemHasBrokenEncoding = (item) => {
        for (const v of Object.values(item || {})) {
            if (typeof v === 'string' && hasBroken(v)) return true;
            if (Array.isArray(v)) {
                for (const x of v) {
                    if (typeof x === 'string' && hasBroken(x)) return true;
                    if (x && typeof x === 'object') {
                        for (const v2 of Object.values(x)) {
                            if (typeof v2 === 'string' && hasBroken(v2)) return true;
                        }
                    }
                }
            }
        }
        return false;
    };

    const cleaned = items.filter(item => {
        // Tüm modüller: encoding bozukları at
        if (itemHasBrokenEncoding(item)) { encodingRemoved++; return false; }

        if (moduleType === 'questions') {
            if (!item.q || !item.o || item.a === undefined) { emptyRemoved++; return false; }
            const qStr = String(item.q).trim();
            if (wordCount(qStr) < MIN_Q_WORDS && qStr.length < MIN_Q_CHARS) {
                tooShortRemoved++;
                return false;
            }
            if (Array.isArray(item.o)) {
                item.o = item.o.map(opt => {
                    const s = String(opt);
                    const stripped = s.replace(OPTION_PREFIX_RE, '').trim();
                    if (stripped !== s) prefixFixed++;
                    return stripped;
                });
            }
        } else if (moduleType === 'flashcards') {
            if (!item.question || !item.answer) { emptyRemoved++; return false; }
            // Duplicate kontrol (aynı soru)
            const key = String(item.question).toLowerCase().trim();
            if (existingKeys.has(key) || batchSeenKeys.has(key)) { dedupRemoved++; return false; }
            batchSeenKeys.add(key);
        } else if (moduleType === 'matching_games') {
            if ((!item.question && !item.left) || (!item.answer && !item.right)) {
                emptyRemoved++; return false;
            }
            const key = String(item.question || item.left).toLowerCase().trim();
            if (existingKeys.has(key) || batchSeenKeys.has(key)) { dedupRemoved++; return false; }
            batchSeenKeys.add(key);
        } else if (moduleType === 'productivity') {
            // Flutter StudyTechnique şeması: id, title, category, shortDescription, fullDescription, steps[], benefits[], tips[], example
            if (item.content && !item.fullDescription) item.fullDescription = item.content;
            if (!item.title || !item.fullDescription) { emptyRemoved++; return false; }

            // id yoksa title'dan oluştur (Türkçe karakterleri ASCII'ye çevir)
            if (!item.id) {
                item.id = String(item.title)
                    .toLowerCase()
                    .replace(/[çğıöşüÇĞIİÖŞÜ]/g, c => ({ ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u', 'Ç': 'c', 'Ğ': 'g', 'I': 'i', 'İ': 'i', 'Ö': 'o', 'Ş': 's', 'Ü': 'u' }[c] || c))
                    .replace(/\(.*?\)/g, '')
                    .replace(/[^a-z0-9]+/g, '-')
                    .replace(/^-|-$/g, '')
                    .substring(0, 40);
            }

            // Duplicate kontrol: hem ID hem başlık
            const idKey = String(item.id).toLowerCase().trim();
            const titleKey = 'T:' + String(item.title).toLowerCase().trim();
            if (existingKeys.has(idKey) || batchSeenKeys.has(idKey) ||
                existingKeys.has(titleKey) || batchSeenKeys.has(titleKey)) {
                dedupRemoved++;
                return false;
            }
            batchSeenKeys.add(idKey);
            batchSeenKeys.add(titleKey);

            if (!item.shortDescription) {
                const firstSentence = String(item.fullDescription).split(/[.!?]/)[0].trim();
                item.shortDescription = firstSentence.length > 80 ? firstSentence.substring(0, 77) + '...' : firstSentence;
            }
            // Flutter beklentisi: category ID'si (timeManagement vb.) — topic ID ile doldur
            if (topicId && (!item.category || item.category !== topicId)) {
                item.category = topicId;
            }
            if (!Array.isArray(item.steps)) item.steps = [];
            if (!Array.isArray(item.benefits)) item.benefits = [];
            if (!Array.isArray(item.tips)) item.tips = [];

            // Kalite filtreleri: derin/zengin içerik şartı
            // fullDescription en az ~140 kelime (~900 karakter) olmalı — prompt 220-380 hedefliyor
            const fdWords = String(item.fullDescription).trim().split(/\s+/).filter(Boolean).length;
            if (fdWords < 120) {
                tooShortRemoved++;
                aiLog('warn', `  ↳ ${item.id}: fullDescription çok kısa (${fdWords} kelime, min 120)`, requestLogs);
                return false;
            }
            // steps en az 4 madde olmalı
            if (item.steps.length < 4) {
                tooShortRemoved++;
                aiLog('warn', `  ↳ ${item.id}: steps yetersiz (${item.steps.length} adım, min 4)`, requestLogs);
                return false;
            }
            // benefits en az 4 madde
            if (item.benefits.length < 4) {
                tooShortRemoved++;
                aiLog('warn', `  ↳ ${item.id}: benefits yetersiz (${item.benefits.length} madde, min 4)`, requestLogs);
                return false;
            }
            // tips en az 3 madde
            if (item.tips.length < 3) {
                tooShortRemoved++;
                aiLog('warn', `  ↳ ${item.id}: tips yetersiz (${item.tips.length} madde, min 3)`, requestLogs);
                return false;
            }
            // example varsa en az 30 kelime; yoksa uyar ama atma (AI bazen atlar)
            if (item.example) {
                const exWords = String(item.example).trim().split(/\s+/).filter(Boolean).length;
                if (exWords < 25) {
                    aiLog('warn', `  ↳ ${item.id}: example kısa (${exWords} kelime) — kabul edildi ama zayıf`, requestLogs);
                }
            } else {
                aiLog('warn', `  ↳ ${item.id}: example alanı eksik — prompt'ta zorunlu`, requestLogs);
            }
        } else if (moduleType === 'explanations') {
            if (!item.title || !Array.isArray(item.content) || item.content.length === 0) {
                emptyRemoved++; return false;
            }
        } else if (moduleType === 'stories') {
            if (!item.title || !item.content) { emptyRemoved++; return false; }
        }
        return true;
    });

    if (prefixFixed > 0) aiLog('sanitize', `🔧 ${prefixFixed} şık prefix'i otomatik temizlendi`, requestLogs);
    if (encodingRemoved > 0) aiLog('warn', `⚠️ ${encodingRemoved} encoding bozuk öğe filtrelendi`, requestLogs);
    if (emptyRemoved > 0) aiLog('warn', `⚠️ ${emptyRemoved} eksik alanlı öğe filtrelendi`, requestLogs);
    if (tooShortRemoved > 0) aiLog('warn', `⚠️ ${tooShortRemoved} çok kısa öğe filtrelendi (<${MIN_Q_WORDS} kelime)`, requestLogs);
    if (dedupRemoved > 0) aiLog('warn', `⚠️ ${dedupRemoved} tekrar eden öğe filtrelendi (aynı ID/başlık)`, requestLogs);
    if (prefixFixed === 0 && encodingRemoved === 0 && emptyRemoved === 0 && tooShortRemoved === 0 && dedupRemoved === 0) {
        aiLog('sanitize', `✅ Sanitize: tüm içerik temiz (${items.length} öğe)`, requestLogs);
    }

    return cleaned;
}

// Audit logging - optional logs array for dashboard
function aiLog(type, message, logsArray = null) {
    const timestamp = new Date().toISOString();
    const logLine = `[${timestamp}] [${type.toUpperCase()}] ${message}`;
    console.log(logLine);
    if (logsArray) {
        logsArray.push({ type, message, time: timestamp });
    }
}

// ─── Gece Otomatik Üretim Scheduler ───
let _nightlyTimer = null;

function startNightlyScheduler() {
    if (_nightlyTimer) clearInterval(_nightlyTimer);
    _nightlyTimer = setInterval(async () => {
        const cfg = readNightlyConfig();
        if (!cfg.enabled) return;
        const now = new Date();
        if (now.getHours() !== cfg.hour || now.getMinutes() > 5) return;

        const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
        if (!OPENROUTER_API_KEY) return;

        aiLog('nightly', `🌙 Gece otomatik üretimi başlatıldı (saat ${cfg.hour}:00)`);
        const topics = getTopicsList();
        for (const topic of topics) {
            for (const mod of cfg.modules || []) {
                const existing = readPublished(mod, topic.id);
                if (existing.length >= (cfg.minThreshold || 5)) continue;
                const count = cfg.count || 5;
                aiLog('nightly', `  → ${topic.name} / ${mod}: ${existing.length} mevcut, ${count} üretiliyor`);
                try {
                    const generated = await generateWithAI(mod, topic.name, topic.id, existing.length + 1, count, cfg.model, null, { maxRetries: 2 });
                    const allDrafts = [...readDraft(mod, topicId), ...generated];
                    writeDraft(mod, topicId, allDrafts);
                    aiLog('nightly', `  ✅ ${generated.length} taslak oluşturuldu: ${topic.name}`);
                } catch (e) {
                    aiLog('nightly', `  ❌ Üretim hatası: ${topic.name} / ${mod}: ${e.message}`);
                }
            }
        }
        aiLog('nightly', `🌙 Gece üretimi tamamlandı`);
    }, 5 * 60 * 1000); // Her 5 dakikada kontrol et
    aiLog('nightly', `⏰ Gece üretim scheduler aktif (her 5 dk kontrol)`);
}

module.exports = handleAIContentRoutes;
module.exports.startNightlyScheduler = startNightlyScheduler;
