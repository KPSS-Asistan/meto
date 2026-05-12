/**
 * AI API Routes
 * Gemini ve OpenRouter AI entegrasyonları
 */

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
        if (geminiKey) this.keys.GEMINI_API_KEY.push(geminiKey.trim());

        // OPENROUTER_API_KEY, OPENROUTER_API_KEY_2, OPENROUTER_API_KEY_3 ... hepsini topla
        const base = process.env.OPENROUTER_API_KEY;
        if (base) this.keys.OPENROUTER_API_KEY.push(base.trim());
        for (let i = 2; i <= 20; i++) {
            const k = process.env[`OPENROUTER_API_KEY_${i}`];
            if (k) this.keys.OPENROUTER_API_KEY.push(k.trim());
            else break;
        }

        console.log(`🔑 API Keys: Gemini=${this.keys.GEMINI_API_KEY.length}, OpenRouter=${this.keys.OPENROUTER_API_KEY.length} (paralel kapasite: ${this.keys.OPENROUTER_API_KEY.length})`);
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

// AI Deep Analysis - 10 Kriter (Tek Soru)
async function analyzeQuestionDeep(question, topicInfo, model = 'google/gemini-3.1-flash-lite-preview') {
    const apiKey = apiKeyManager.getKey('OPENROUTER_API_KEY');
    if (!apiKey) throw new Error('OpenRouter API key bulunamadı');

    const correctOption = Array.isArray(question.o) ? question.o[question.a] : 'bilinmiyor';

    const prompt = `Sen bir KPSS sınav sorusu kalite uzmanısın. Aşağıdaki soruyu 12 kriterde analiz et.

KONU: ${topicInfo?.name || 'Genel'} (${topicInfo?.lesson || ''})

SORU:
${question.q}

ŞIKLAR:
${Array.isArray(question.o) ? question.o.map((o, i) => `${String.fromCharCode(65 + i)}) ${o}`).join('\n') : 'Yok'}

DOĞRU CEVAP: ${String.fromCharCode(65 + (question.a || 0))}) ${correctOption}

AÇIKLAMA: ${question.e || 'Yok'}

---

Aşağıdaki 10 kriterde TÜRKÇE analiz yap. SADECE JSON döndür, başka hiçbir şey yazma:

{
  "criteria": [
    { "id": 1, "name": "Doğru Cevap Doğruluğu", "hasError": false, "explanation": "Doğru cevabın gerçekten doğru olup olmadığını değerlendir", "suggestion": "" },
    { "id": 2, "name": "Soru Kökü Açıklığı", "hasError": false, "explanation": "Soru kökünün net, anlaşılır ve tek anlamlı olup olmadığını değerlendir", "suggestion": "" },
    { "id": 3, "name": "Yazım, Noktalama ve Anlatım Hataları", "hasError": false, "explanation": "Yazım/dil/noktalama hatalarını belirt", "suggestion": "" },
    { "id": 4, "name": "Mantık ve Tutarlılık", "hasError": false, "explanation": "Sorunun iç tutarlılığını ve mantıksal bütünlüğünü değerlendir", "suggestion": "" },
    { "id": 5, "name": "KPSS Müfredat ve Seviye Uygunluğu", "hasError": false, "explanation": "KPSS müfredatına ve sınav düzeyine uygunluğunu değerlendir", "suggestion": "" },
    { "id": 6, "name": "Ölçme-Değerlendirme Kalitesi", "hasError": false, "explanation": "Sorunun gerçek bir bilgi/beceriyi ölçüp ölçmediğini değerlendir", "suggestion": "" },
    { "id": 7, "name": "Şıkların ve Çeldiricilerin Kalitesi", "hasError": false, "explanation": "Yanlış şıkların makul, çeldirici ve homojen olup olmadığını değerlendir", "suggestion": "" },
    { "id": 8, "name": "Teknik Biçim Hataları", "hasError": false, "explanation": "Şık sayısı (5 olmalı), format, id eksikliği gibi teknik sorunları kontrol et", "suggestion": "" },
    { "id": 9, "name": "Açıklama Kalitesi", "hasError": false, "explanation": "Açıklamanın doğru, yeterli ve anlaşılır olup olmadığını değerlendir. Yoksa veya yetersizse hata say.", "suggestion": "" },
    { "id": 10, "name": "Tarafsızlık ve Etik Uygunluk", "hasError": false, "explanation": "Önyargı, ayrımcılık veya etik sorun olup olmadığını değerlendir", "suggestion": "" },
    { "id": 11, "name": "Konu Uygunluğu", "hasError": false, "explanation": "Sorunun belirtilen konu ve ders alanına uygunluğunu değerlendir. Soru yanlış konuya atanmışsa veya konuyla ilgisizse hata say.", "suggestion": "" },
    { "id": 12, "name": "Genel Karar", "hasError": false, "explanation": "Sorunun genel kullanılabilirlik değerlendirmesi", "suggestion": "" }
  ],
  "verdict": "Geçerli",
  "score": 8,
  "summary": "Kısa genel özet (1-2 cümle)"
}

KURALLAR:
- verdict SADECE: "Geçerli" | "Küçük düzeltme gerekli" | "Revizyon gerekli" | "Hatalı"
- hasError true ise explanation ve suggestion doldur
- hasError false ise suggestion boş bırakabilirsin
- score 1-10 arası tam sayı
- SADECE JSON döndür`;

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
            'HTTP-Referer': 'http://localhost:3456',
            'X-Title': 'KPSS Soru Derin Analiz'
        },
        body: JSON.stringify({
            model,
            messages: [{ role: 'user', content: prompt }],
            temperature: 0.1
        })
    });

    if (!response.ok) {
        const errText = await response.text();
        throw new Error(`OpenRouter hatası: ${response.status} — ${errText.substring(0, 200)}`);
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content || '';

    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
    }

    throw new Error('AI yanıtı parse edilemedi: ' + content.substring(0, 300));
}

async function handleAIRoutes(req, res, pathname) {
    // GET /api/ai/status
    if (pathname === '/api/ai/status' && req.method === 'GET') {
        return sendJSON(res, {
            gemini: apiKeyManager.hasKey('GEMINI_API_KEY'),
            openrouter: apiKeyManager.hasKey('OPENROUTER_API_KEY'),
            openrouterKeyCount: apiKeyManager.keys['OPENROUTER_API_KEY'].length
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

    // POST /api/ai/deep-analyze
    if (pathname === '/api/ai/deep-analyze' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { question, topicInfo, model } = body;

            if (!question || !question.q) {
                return sendJSON(res, { error: 'question objesi gerekli (q alanı içermeli)' }, 400);
            }

            const result = await analyzeQuestionDeep(question, topicInfo, model);
            return sendJSON(res, { success: true, ...result });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /api/ai/analyze-report
    if (pathname === '/api/ai/analyze-report' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { report, question, topicInfo } = body;
            if (!report) return sendJSON(res, { error: 'report objesi gerekli' }, 400);

            const apiKey = apiKeyManager.getKey('OPENROUTER_API_KEY');
            if (!apiKey) return sendJSON(res, { error: 'OpenRouter API key bulunamadı' }, 400);

            const typeLabels = {
                wrong_answer: 'Yanlış Cevap',
                typo: 'Yazım/Dil Hatası',
                wrong_topic: 'Yanlış Konu',
                unclear: 'Belirsiz Soru',
                duplicate: 'Mükerrer Soru',
                other: 'Diğer'
            };

            const reportTypeTr = typeLabels[report.type] || report.type || 'Bilinmiyor';

            const questionSection = question && question.q ? `
SORU METNİ:
${question.q}

ŞIKLAR:
${Array.isArray(question.o) ? question.o.map((o, i) => `${String.fromCharCode(65 + i)}) ${o}`).join('\n') : 'Yok'}
DOĞRU CEVAP: ${question.a !== undefined ? String.fromCharCode(65 + question.a) + ') ' + (question.o?.[question.a] || '') : 'Belirtilmemiş'}
AÇIKLAMA: ${question.e || 'Yok'}
KONU: ${topicInfo?.name || 'Bilinmiyor'} (${topicInfo?.lesson || ''})` : '(Soru içeriği bulunamadı, sadece rapor bilgisiyle değerlendir)';

            const prompt = `Sen bir KPSS sınav sorusu kalite uzmanısın. Bir kullanıcı raporu inceliyorsun.

RAPOR BİLGİLERİ:
- Rapor Türü: ${reportTypeTr}
- Soru ID: ${report.questionId || 'Bilinmiyor'}
- Kullanıcı Açıklaması: ${report.description || '(Açıklama yok)'}
${questionSection}

Bu raporu değerlendir ve SADECE aşağıdaki JSON formatını döndür:

{
  "valid": true,
  "verdict": "Geçerli rapor",
  "action": "resolved",
  "summary": "Kısa değerlendirme (2-3 cümle)",
  "details": "Detaylı analiz — raporlanan sorun gerçekten var mı, soru ne durumda, ne yapılmalı",
  "confidence": 85
}

KURALLAR:
- valid: Kullanıcı raporunun haklı/geçerli olup olmadığı (true/false)
- verdict: "Geçerli rapor" | "Kısmen geçerli" | "Geçersiz rapor" | "Sorun tespit edilemedi"
- action: "resolved" (düzelt ve çözüldü say) | "rejected" (rapor hatalı, reddet) | "review" (daha fazla inceleme gerekiyor)
- summary: 1-2 cümle özet
- details: Kapsamlı Türkçe analiz
- confidence: 0-100 arasında güven skoru
- SADECE JSON döndür`;

            const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${apiKey}`,
                    'Content-Type': 'application/json',
                    'HTTP-Referer': 'http://localhost:8001',
                    'X-Title': 'KPSS Rapor Analiz'
                },
                body: JSON.stringify({
                    model: 'google/gemini-3.1-flash-lite-preview',
                    messages: [{ role: 'user', content: prompt }],
                    temperature: 0.15
                })
            });

            if (!response.ok) {
                const errText = await response.text();
                throw new Error(`OpenRouter hatası: ${response.status} — ${errText.substring(0, 200)}`);
            }

            const data = await response.json();
            const content = data.choices?.[0]?.message?.content || '';
            const jsonMatch = content.match(/\{[\s\S]*\}/);
            if (!jsonMatch) throw new Error('AI yanıtı parse edilemedi: ' + content.substring(0, 300));
            const result = JSON.parse(jsonMatch[0]);
            return sendJSON(res, { success: true, ...result });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /api/ai/generate-one - Tek soru üret
    if (pathname === '/api/ai/generate-one' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { topicId, topicName, lesson, subtopic, difficulty, model } = body;
            if (!topicName) return sendJSON(res, { error: 'topicName gerekli' }, 400);

            const apiKey = apiKeyManager.getKey('OPENROUTER_API_KEY');
            if (!apiKey) return sendJSON(res, { error: 'OpenRouter API key bulunamadı' }, 400);

            const diffLabel = ['', 'Çok Kolay', 'Kolay', 'Orta', 'Zor', 'Çok Zor'][difficulty || 3] || 'Orta';

            const prompt = `Sen bir KPSS sınav uzmanısın. ${lesson || 'KPSS'} dersi, "${topicName}" konusu${subtopic ? ', alt konu: "' + subtopic + '"' : ''} için zorluk seviyesi ${diffLabel} olan 1 adet özgün çoktan seçmeli soru yaz.

KURALLAR:
- 5 şık olmalı (A-E)
- Soru kökü KPSS sınav diline uygun, net ve tek anlamlı
- Yanlış şıklar makul ve çeldirici
- Açıklama doğru cevabı kısaca gerekçelendirmeli
- Tamamen Türkçe

SADECE aşağıdaki JSON formatını döndür:
{
  "q": "Soru metni...",
  "o": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı", "E şıkkı"],
  "a": 0,
  "e": "Açıklama...",
  "d": ${difficulty || 3},
  "subtopic": "${subtopic || topicName}"
}`;

            const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${apiKey}`,
                    'Content-Type': 'application/json',
                    'HTTP-Referer': 'http://localhost:8002',
                    'X-Title': 'KPSS Akilli Soru Uretici'
                },
                body: JSON.stringify({
                    model: model || 'google/gemini-3.1-flash-lite-preview',
                    messages: [{ role: 'user', content: prompt }],
                    temperature: 0.8
                })
            });

            if (!response.ok) {
                const errText = await response.text();
                throw new Error(`OpenRouter: ${response.status} — ${errText.substring(0, 200)}`);
            }

            const data = await response.json();
            const content = data.choices?.[0]?.message?.content || '';
            const jsonMatch = content.match(/\{[\s\S]*\}/);
            if (!jsonMatch) throw new Error('AI yanıtı parse edilemedi: ' + content.substring(0, 300));
            const q = JSON.parse(jsonMatch[0]);
            if (!q.q || !Array.isArray(q.o) || q.o.length !== 5) throw new Error('Geçersiz soru formatı');
            return sendJSON(res, { success: true, question: q });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
}

module.exports = handleAIRoutes;
