/**
 * AI API Routes
 * Gemini ve OpenRouter AI entegrasyonları
 */
require('dotenv').config({ path: require('path').join(__dirname, '../../../../.env') });

const fs = require('fs').promises;
const path = require('path');
const { QUESTIONS_DIR } = require('../config');
const { sendJSON, parseBody } = require('../utils/helper');
const { TOPICS } = require('../config/topics');

// API Key Manager
class ApiKeyManager {
    constructor() {
        this.keys = { GEMINI_API_KEY: [], OPENROUTER_API_KEY: [] };
        this.currentIndex = { GEMINI_API_KEY: 0, OPENROUTER_API_KEY: 0 };
        this.loadKeys();
    }

    loadKeys() {
        const geminiKey = process.env.GEMINI_API_KEY;
        const openrouterKey = process.env.OPENROUTER_API_KEY;

        if (geminiKey) this.keys.GEMINI_API_KEY.push(geminiKey.trim());
        if (openrouterKey) this.keys.OPENROUTER_API_KEY.push(openrouterKey.trim());

        console.log(`🔑 API Keys: Gemini=${this.keys.GEMINI_API_KEY.length}, OpenRouter=${this.keys.OPENROUTER_API_KEY.length}`);
    }

    getKey(keyName) {
        const keys = this.keys[keyName];
        if (!keys || keys.length === 0) return null;
        const key = keys[this.currentIndex[keyName]];
        this.currentIndex[keyName] = (this.currentIndex[keyName] + 1) % keys.length;
        return key;
    }

    hasKey(keyName) {
        return this.keys[keyName] && this.keys[keyName].length > 0;
    }
}

const apiKeyManager = new ApiKeyManager();

// Helper: Load questions from file
async function loadQuestions(topicId) {
    try {
        const filePath = path.join(QUESTIONS_DIR, `${topicId}.json`);
        const content = await fs.readFile(filePath, 'utf8');
        return JSON.parse(content);
    } catch { return []; }
}

// AI Question Generation
async function generateQuestionsWithAI(topicId, topic, lesson, count = 10) {
    const apiKey = apiKeyManager.getKey('OPENROUTER_API_KEY');
    if (!apiKey) throw new Error('OpenRouter API key bulunamadı');

    const timestamp = Date.now();
    const prefix = topicId.substring(0, 3).toLowerCase();

    const prompt = `Sen bir KPSS sınav sorusu yazarısın. ${lesson} dersi "${topic}" konusu için ${count} adet profesyonel çoktan seçmeli soru yaz.

KURALLAR:
1. Her soru 5 seçenek içermeli (A, B, C, D, E)
2. Soru metni detaylı ve en az 30 kelime olmalı
3. Açıklama kısa ve öz olmalı (1-2 cümle)
4. Doğru cevap rastgele dağılmalı
5. Bazı sorular öncüllü olmalı (I. II. III. formatında)

JSON FORMATI:
{
  "questions": [
    {
      "q": "Soru metni",
      "o": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı", "E şıkkı"],
      "a": 0,
      "e": "Kısa açıklama",
      "d": 2,
      "subtopic": "${topic}"
    }
  ]
}

SADECE JSON döndür, başka hiçbir şey yazma!`;

    try {
        const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
                'HTTP-Referer': 'http://localhost:3456',
                'X-Title': 'KPSS Question Generator'
            },
            body: JSON.stringify({
                model: 'google/gemini-2.0-flash-001',
                messages: [{ role: 'user', content: prompt }],
                temperature: 0.7
            })
        });

        const data = await response.json();
        const content = data.choices?.[0]?.message?.content || '';

        const jsonMatch = content.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            const parsed = JSON.parse(jsonMatch[0]);

            // Add IDs
            const questions = (parsed.questions || []).map((q, idx) => ({
                id: `${prefix}_${timestamp}_${String(idx + 1).padStart(3, '0')}`,
                topicId,
                ...q
            }));

            return { success: true, questions };
        }

        throw new Error('AI yanıtı parse edilemedi');
    } catch (e) {
        throw new Error('AI hatası: ' + e.message);
    }
}

// AI Question Analysis
async function analyzeQuestionsWithAI(questions, topicInfo) {
    const apiKey = apiKeyManager.getKey('OPENROUTER_API_KEY');
    if (!apiKey) throw new Error('OpenRouter API key bulunamadı');

    const cleanedQuestions = questions.map((q, i) => ({
        index: i,
        id: q.id,
        q: q.q,
        o: q.o,
        a: q.a,
        e: q.e
    }));

    const prompt = `Sen bir KPSS uzmanısın. Aşağıdaki soruları analiz et.

KONU: ${topicInfo?.name || 'Genel'}

SORULAR:
${JSON.stringify(cleanedQuestions, null, 2)}

JSON FORMAT (Sadece bu formatta yanıt ver):
[
  {
    "index": 0,
    "status": "ok|warning|error",
    "score": 1-10,
    "issues": ["Hata 1", "Hata 2"],
    "suggestions": ["Öneri 1"],
    "correctAnswerCheck": "Cevap analizi",
    "summary": "Kısa özet"
  }
]`;

    try {
        const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
                'HTTP-Referer': 'http://localhost:3456',
                'X-Title': 'KPSS Soru Analizi'
            },
            body: JSON.stringify({
                model: 'google/gemini-2.0-flash-001',
                messages: [{ role: 'user', content: prompt }],
                temperature: 0.1
            })
        });

        const data = await response.json();
        const content = data.choices?.[0]?.message?.content || '';

        const jsonMatch = content.match(/\[[\s\S]*\]/);
        if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
        }

        throw new Error('AI yanıtı parse edilemedi');
    } catch (e) {
        throw new Error('AI analiz hatası: ' + e.message);
    }
}

async function handleAIRoutes(req, res, pathname) {
    // GET /api/ai/status
    if (pathname === '/api/ai/status' && req.method === 'GET') {
        return sendJSON(res, {
            gemini: apiKeyManager.hasKey('GEMINI_API_KEY'),
            openrouter: apiKeyManager.hasKey('OPENROUTER_API_KEY')
        });
    }

    // POST /generate-ai
    if (pathname === '/generate-ai' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { topicId, topic, lesson, count = 10 } = body;

            if (!topicId || !topic || !lesson) {
                return sendJSON(res, { error: 'topicId, topic ve lesson gerekli' }, 400);
            }

            const result = await generateQuestionsWithAI(topicId, topic, lesson, count);
            return sendJSON(res, result);
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /analyze-ai
    if (pathname === '/analyze-ai' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { questions, topicInfo } = body;

            if (!questions || !Array.isArray(questions)) {
                return sendJSON(res, { error: 'questions dizisi gerekli' }, 400);
            }

            const results = await analyzeQuestionsWithAI(questions, topicInfo);
            return sendJSON(res, { success: true, results });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /ai-review
    if (pathname === '/ai-review' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { topicId, limit = 10 } = body;

            if (!topicId) {
                return sendJSON(res, { error: 'topicId gerekli' }, 400);
            }

            const questions = await loadQuestions(topicId);
            const toReview = questions.slice(0, limit);
            const topicInfo = TOPICS[topicId] || { name: topicId, lesson: 'Genel' };

            const results = await analyzeQuestionsWithAI(toReview, topicInfo);
            return sendJSON(res, { success: true, reviewed: toReview.length, results });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
}

module.exports = handleAIRoutes;
