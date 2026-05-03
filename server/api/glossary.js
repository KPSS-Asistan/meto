/**
 * Glossary API Routes
 * Kavram Sözlüğü için CRUD + AI (OpenRouter) üretimi
 */
const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const https = require('https');
const { sendJSON, parseBody } = require('../utils/helper');
const { DATA_DIR, GLOSSARY_DIR } = require('../config');


if (!fsSync.existsSync(GLOSSARY_DIR)) {
    fsSync.mkdirSync(GLOSSARY_DIR, { recursive: true });
}

// Konu başlıkları (stories/flashcards ile aynı ID'ler)
const TOPIC_TITLES = {
    'JnFbEQt0uA8RSEuy22SQ': 'Tarih - İslamiyet Öncesi Türk Tarihi',
    '9Hg8tuMRdMTuVY7OZ9HL': 'Tarih - İlk Müslüman Türk Devletleri',
    '8aIrKLvItXrwvOHq1L34': 'Tarih - Türkiye Selçuklu Devleti',
    'JU0iGKNhR7NQzA8M77vt': 'Tarih - Osmanlı Devleti (Siyasi)',
    '9WTotPoDW5OuWxsCf4Li': 'Tarih - Osmanlı Devleti (Kültür)',
    'DlT19snCttf5j5RUAXLz': 'Tarih - Kurtuluş Savaşı Dönemi',
    '4GUvpqBBImcLmN2eh1HK': 'Tarih - Atatürk İlke ve İnkılapları',
    'onwrfsH02TgIhlyRUh56': 'Tarih - Cumhuriyet Dönemi',
    'xQWHl1hBYAKM96X4deR8': 'Tarih - Çağdaş Türk ve Dünya Tarihi',
    '80e0wkTLvaTQzPD6puB7': 'Türkçe - Ses Bilgisi',
    'yWlh5C6jB7lzuJOodr2t': 'Türkçe - Yapı Bilgisi',
    'ICNDiSlTmmjWEQPT6rmT': 'Türkçe - Sözcük Türleri',
    'JmyiPxf3n96Jkxqsa9jY': 'Türkçe - Sözcükte Anlam',
    'AJNLHhhaG2SLWOvxDYqW': 'Türkçe - Cümlede Anlam',
    'nN8JOTR7LZm01AN2i3sQ': 'Türkçe - Paragrafta Anlam',
    'jXcsrl5HEb65DmfpfqqI': 'Türkçe - Anlatım Bozuklukları',
    'qSEqigIsIEBAkhcMTyCE': 'Türkçe - Yazım Kuralları ve Noktalama',
    'wnt2zWaV1pX8p8s8BBc9': 'Türkçe - Sözel Mantık ve Akıl Yürütme',
    '1FEcPsGduhjcQARpaGBk': 'Coğrafya - Türkiye\'nin Coğrafi Konumu',
    'kbs0Ffved9pCP3Hq9M9k': 'Coğrafya - Türkiye\'nin Fiziki Özellikleri',
    '6e0Thsz2RRNHFcwqQXso': 'Coğrafya - İklim ve Bitki Örtüsü',
    'uYDrMlBCEAho5776WZi8': 'Coğrafya - Beşeri Coğrafya',
    'WxrtQ26p2My4uJa0h1kk': 'Coğrafya - Ekonomik Coğrafya',
    'GdpN8uxJNGtexWrkoL1T': 'Coğrafya - Türkiye\'nin Coğrafi Bölgeleri',
    'AQ0Zph76dzPdr87H1uKa': 'Vatandaşlık - Hukuka Giriş',
    'n4OjWupHmouuybQzQ1Fc': 'Vatandaşlık - Anayasa Hukuku',
    'xXGXiqx2TkCtI4C7GMQg': 'Vatandaşlık - 1982 Anayasası Temel İlkeleri',
    '1JZAYECyEn7farNNyGyx': 'Vatandaşlık - Devlet Organları',
    'lv93cmhwq7RmOFM5WxWD': 'Vatandaşlık - İdari Yapı',
    'Bo3qqooJsqtIZrK5zc9S': 'Vatandaşlık - Temel Hak ve Özgürlükler',
};

// ─── OpenRouter ile Kavram Üret ───
function callOpenRouter(prompt, model, apiKey, maxTokens = 8192) {
    return new Promise((resolve, reject) => {
        const body = JSON.stringify({
            model,
            messages: [
                {
                    role: 'system',
                    content: 'Sen KPSS sınav hazırlık uzmanısın. Sadece geçerli JSON döndür, başka hiçbir şey yazma. Kod bloğu, önsöz, açıklama YAZMA.'
                },
                { role: 'user', content: prompt }
            ],
            temperature: 0.5,
            max_tokens: maxTokens
        });

        const options = {
            hostname: 'openrouter.ai',
            port: 443,
            path: '/api/v1/chat/completions',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${apiKey}`,
                'HTTP-Referer': 'https://github.com/KPSS-Asistan',
                'X-Title': 'KPSS Asistan Admin'
            }
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode >= 400) {
                    return reject(new Error(`OpenRouter Error ${res.statusCode}: ${data}`));
                }
                try {
                    const json = JSON.parse(data);
                    const content = json.choices[0].message.content.trim();
                    const cleanJson = content.replace(/^```json\n?/, '').replace(/\n?```$/, '');
                    resolve(JSON.parse(cleanJson));
                } catch (e) {
                    reject(new Error('JSON parse error: ' + e.message + '\nData: ' + data));
                }
            });
        });

        req.on('error', reject);
        req.write(body);
        req.end();
    });
}

async function generateGlossaryTerms({ topicId, topicName, lessonName, count, model, apiKey, existingTerms = [] }) {
    const existingList = existingTerms.map(t => t.term).join(', ');
    const prompt = `
        KPSS ${lessonName} dersi "${topicName}" konusu için ${count} adet önemli kavram ve açıklamasını üret.
        
        KURALLAR:
        1. Daha önce üretilmiş şu kavramları ASLA tekrar etme: ${existingList}
        2. Her kavram benzersiz ve sınav odaklı olmalı.
        3. Açıklamalar net, akademik ama anlaşılır olmalı (20-50 kelime).
        4. "term", "description", "id" (benzersiz uuid/slug) alanlarını içeren bir JSON dizisi döndür.
        
        FORMAT ÖRNEĞİ:
        [
          { "id": "monderos-ateskesi", "term": "Mondros Ateşkesi", "description": "1. Dünya Savaşı sonrası Osmanlı Devleti ile İtilaf Devletleri arasında imzalanan..." }
        ]
    `;

    return await callOpenRouter(prompt, model, apiKey);
}

function deduplicateTerms(newTerms, existingTerms) {
    const existingNorm = new Set(existingTerms.map(t => t.term.toLowerCase().trim()));
    const seenNorm = new Set();
    const unique = [];

    for (const t of newTerms) {
        const termKey = t.term.toLowerCase().trim();
        if (existingNorm.has(termKey) || seenNorm.has(termKey)) continue;
        seenNorm.add(termKey);
        unique.push(t);
    }

    return unique;
}

// Hedef adede ulaşmak için gerektiğinde tekrar üretim yapar; her aşamada dedupe uygular
async function generateUniqueGlossaryTerms({ topicId, topicName, lessonName, count, model, apiKey, existingTerms = [] }) {
    const targetCount = Math.max(1, Number(count) || 1);
    const maxAttempts = 3;
    const collected = [];
    let generatedTotal = 0;

    for (let attempt = 1; attempt <= maxAttempts && collected.length < targetCount; attempt++) {
        const remaining = targetCount - collected.length;
        const roundTerms = await generateGlossaryTerms({
            topicId,
            topicName,
            lessonName,
            count: remaining,
            model,
            apiKey,
            existingTerms: [...existingTerms, ...collected],
        });

        generatedTotal += roundTerms.length;
        const accepted = deduplicateTerms(roundTerms, [...existingTerms, ...collected]);

        if (accepted.length === 0) {
            console.warn(`[Glossary AI] Attempt ${attempt}: yeni benzersiz kavram üretilemedi`);
            break;
        }

        collected.push(...accepted);
    }

    const terms = collected.slice(0, targetCount);
    return {
        terms,
        duplicatesRemoved: Math.max(0, generatedTotal - terms.length),
    };
}

// Mevcut yayınlı kavramları topla
function _collectExisting(topicId) {
    const fp = path.join(GLOSSARY_DIR, `${topicId}.json`);
    if (!fsSync.existsSync(fp)) return [];
    try {
        return JSON.parse(fsSync.readFileSync(fp, 'utf8'));
    } catch {
        return [];
    }
}

async function handleGlossaryRoutes(req, res, pathname, searchParams) {
    const OPENROUTER_KEY = process.env.OPENROUTER_API_KEY;

    // ── GET /glossary — tüm dosyaları listele ──
    if (pathname === '/glossary' && req.method === 'GET') {
        try {
            const files = await fs.readdir(GLOSSARY_DIR);
            const jsonFiles = files.filter(f => f.endsWith('.json'));
            const sets = [];
            for (const file of jsonFiles) {
                try {
                    const topicId = path.basename(file, '.json');
                    const content = await fs.readFile(path.join(GLOSSARY_DIR, file), 'utf8');
                    const terms = JSON.parse(content);
                    sets.push({
                        id: topicId,
                        filename: file,
                        title: TOPIC_TITLES[topicId] || topicId,
                        count: Array.isArray(terms) ? terms.length : 0,
                        preview: Array.isArray(terms) && terms[0] ? terms[0].term : ''
                    });
                } catch { }
            }
            return sendJSON(res, { success: true, glossary: sets });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ── GET /glossary/:topicId — tek dosyayı getir ──
    if (pathname.match(/^\/glossary\/[^/]+$/) && req.method === 'GET') {
        const topicId = pathname.split('/')[2];
        const fp = path.join(GLOSSARY_DIR, `${topicId}.json`);
        if (!fsSync.existsSync(fp)) return sendJSON(res, { error: 'Dosya bulunamadı' }, 404);
        try {
            const terms = JSON.parse(await fs.readFile(fp, 'utf8'));
            return sendJSON(res, { success: true, topicId, title: TOPIC_TITLES[topicId] || topicId, terms });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ── POST /glossary/ai-generate — AI ile kavram üret ──
    if (pathname === '/glossary/ai-generate' && req.method === 'POST') {
        if (!OPENROUTER_KEY) return sendJSON(res, { error: 'OPENROUTER_API_KEY .env\'de tanımlı değil' }, 500);
        try {
            const body = await parseBody(req);
            const { topicId, topicName, lessonName, count = 10, model = 'google/gemini-2.5-flash' } = body;
            if (!topicId || !topicName) return sendJSON(res, { error: 'topicId ve topicName zorunlu' }, 400);

            const existingTerms = _collectExisting(topicId);
            console.log(`[Glossary AI] Üretiliyor: ${topicName} (${count} kavram, mevcut: ${existingTerms.length})`);

            const { terms, duplicatesRemoved } = await generateUniqueGlossaryTerms({
                topicId,
                topicName,
                lessonName: lessonName || 'KPSS',
                count,
                model,
                apiKey: OPENROUTER_KEY,
                existingTerms,
            });
            return sendJSON(res, { success: true, terms, duplicatesRemoved });
        } catch (e) {
            console.error('[Glossary AI] Hata:', e.message);
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ── PUT /glossary/:topicId — kaydet (tüm listeyi yaz) ──
    if (pathname.match(/^\/glossary\/[^/]+$/) && req.method === 'PUT') {
        const topicId = pathname.split('/')[2];
        try {
            const body = await parseBody(req);
            const terms = Array.isArray(body) ? body : body.terms;
            if (!Array.isArray(terms)) return sendJSON(res, { error: 'terms dizisi bekleniyor' }, 400);
            const ordered = terms.map((t, i) => ({ ...t, order: i + 1 }));
            await saveGlossary(topicId, ordered);
            return sendJSON(res, { success: true, count: ordered.length });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ── DELETE /glossary/:topicId — dosyayı sil ──
    if (pathname.match(/^\/glossary\/[^/]+$/) && req.method === 'DELETE') {
        const topicId = pathname.split('/')[2];
        try {
            const fp = path.join(GLOSSARY_DIR, `${topicId}.json`);
            if (fsSync.existsSync(fp)) await fs.unlink(fp);
            return sendJSON(res, { success: true });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
}

async function saveGlossary(topicId, terms) {
    const json = JSON.stringify(terms, null, 2);
    await fs.writeFile(path.join(GLOSSARY_DIR, `${topicId}.json`), json, 'utf8');
}

module.exports = handleGlossaryRoutes;
