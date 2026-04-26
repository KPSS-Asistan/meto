/**
 * Glossary API Routes
 * Kavram Sözlüğü için CRUD + AI (OpenRouter) üretimi + draft sistemi
 */
const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const https = require('https');
const { exec } = require('child_process');
const { sendJSON, parseBody } = require('../utils/helper');

require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const ROOT_DIR = path.join(__dirname, '../../../..');
const GLOSSARY_DIR = path.join(ROOT_DIR, 'tools', 'glossary');
const ASSETS_GLOSSARY_DIR = path.join(ROOT_DIR, 'assets', 'data', 'glossary');
const DRAFT_DIR = path.join(ROOT_DIR, 'tools', 'dashboard', 'drafts', 'glossary');

// Dizinleri oluştur
[GLOSSARY_DIR, ASSETS_GLOSSARY_DIR, DRAFT_DIR].forEach(d => {
    if (!fsSync.existsSync(d)) fsSync.mkdirSync(d, { recursive: true });
});

// ─── Draft yardımcıları ───
function getDraftPath(topicId) { return path.join(DRAFT_DIR, `${topicId}.json`); }

function readDraft(topicId) {
    const fp = getDraftPath(topicId);
    if (!fsSync.existsSync(fp)) return null;
    try {
        const parsed = JSON.parse(fsSync.readFileSync(fp, 'utf8'));
        return Array.isArray(parsed) && parsed.length > 0 ? parsed : null;
    } catch { return null; }
}

function writeDraft(topicId, terms) {
    fsSync.writeFileSync(getDraftPath(topicId), JSON.stringify(terms, null, 2), 'utf8');
}

function deleteDraft(topicId) {
    const fp = getDraftPath(topicId);
    if (fsSync.existsSync(fp)) fsSync.unlinkSync(fp);
}

// ─── Git push ───
function pushGlossaryToGitHub(topicId, topicName) {
    return new Promise((resolve) => {
        const commands = [
            `cd "${ROOT_DIR}"`,
            `git add assets/data/glossary/${topicId}.json`,
            `git commit -m "AI Content: glossary for ${topicName || topicId} [auto-commit]" || true`,
            'git push origin main',
        ].join(' && ');
        exec(commands, { cwd: ROOT_DIR, timeout: 60000 }, (err, stdout, stderr) => {
            if (err && !err.message.includes('nothing to commit')) {
                return resolve({ pushed: false, error: err.message });
            }
            resolve({ pushed: true });
        });
    });
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
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
                'HTTP-Referer': 'http://localhost:3456',
                'X-Title': 'KPSS Glossary Generator'
            },
            timeout: 120000
        };

        const req = https.request(options, (res) => {
            let chunks = [];
            res.on('data', c => chunks.push(c));
            res.on('end', () => {
                try {
                    const raw = Buffer.concat(chunks).toString('utf8');
                    const data = JSON.parse(raw);
                    if (res.statusCode !== 200) {
                        return reject(new Error(`OpenRouter ${res.statusCode}: ${data.error?.message || raw.slice(0, 200)}`));
                    }
                    const text = data.choices?.[0]?.message?.content || '';
                    resolve({ text, usage: data.usage });
                } catch (e) {
                    reject(new Error('OpenRouter yanıtı parse edilemedi: ' + e.message));
                }
            });
        });

        req.on('error', reject);
        req.on('timeout', () => { req.destroy(); reject(new Error('OpenRouter zaman aşımı (120s)')); });
        req.write(body);
        req.end();
    });
}

function extractJson(text) {
    // ```json ... ``` veya ``` ... ``` bloğunu temizle
    let clean = text.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '').trim();
    // Bazen model açıklama sonrası JSON yazar — ilk '[' den başlat
    const arrStart = clean.indexOf('[');
    if (arrStart > 0) clean = clean.slice(arrStart);

    // 1. Normal parse
    try { return JSON.parse(clean); } catch (e1) {
        console.warn(`[extractJson] Normal parse failed (len=${clean.length}): ${e1.message.slice(0, 80)}`);
    }

    // 2. Truncated JSON recovery: find last complete object ending with }
    let depth = 0;
    let lastCompleteEnd = -1;
    let inString = false;
    let escape = false;
    for (let i = 0; i < clean.length; i++) {
        const c = clean[i];
        if (escape) { escape = false; continue; }
        if (c === '\\' && inString) { escape = true; continue; }
        if (c === '"') { inString = !inString; continue; }
        if (inString) continue;
        if (c === '{') depth++;
        else if (c === '}') {
            depth--;
            if (depth === 0) lastCompleteEnd = i;
        }
    }

    console.warn(`[extractJson] Salvage: lastCompleteEnd=${lastCompleteEnd}, inString=${inString}, depth=${depth}`);

    if (lastCompleteEnd !== -1) {
        const salvaged = clean.slice(0, lastCompleteEnd + 1) + ']';
        try {
            const result = JSON.parse(salvaged);
            if (Array.isArray(result) && result.length > 0) {
                console.warn(`[extractJson] Truncated JSON salvaged: ${result.length} terms recovered`);
                return result;
            }
        } catch (e2) {
            console.warn(`[extractJson] Salvage parse also failed: ${e2.message.slice(0, 80)}`);
        }
    }

    throw new Error('Model geçersiz veya kesilebilir JSON döndürdü — kurtarılamadı.');
}

const BATCH_SIZE = 15; // conservative — fits within ~4k output token models

async function _generateBatch({ topicName, lessonName, batchCount, batchNum, totalBatches, model, apiKey, avoidTerms }) {
    // Cap avoid list to last 40 to keep prompt size manageable
    const cappedAvoid = avoidTerms.slice(-40);
    const avoidBlock = cappedAvoid.length > 0
        ? `\n⚠️ ZATEN MEVCUT KAVRAMLAR (bunları TEKRAR ÜRETME, tamamen farklı kavramlar seç):\n${cappedAvoid.map((t, i) => `${i + 1}. ${t}`).join('\n')}\n`
        : '';

    const batchNote = totalBatches > 1 ? ` (Grup ${batchNum}/${totalBatches})` : '';

    const prompt = `Sen KPSS (Kamu Personeli Seçme Sınavı) hazırlık uzmanısın.
"${lessonName}" dersinin "${topicName}" konusu için ${batchCount} adet KPSS sınavında sıkça sorulan, mutlaka bilinmesi gereken temel kavramı üret${batchNote}.
${avoidBlock}
Kurallar:
- Kavramlar KPSS sınavına doğrudan yönelik, sınav odaklı olmalı
- Tanımlar kısa, net ve ezberlenebilir olmalı (max 3 cümle)
- examples: gerçek sınav sorusu bağlamında somut örnekler
- relatedTerms: aynı konudaki ilişkili kavramlar (cross-reference için)
- Tekrar eden kavram OLMASIN, ${batchCount} farklı kavram üret
- Yukarıdaki mevcut kavramlarla çakışan hiçbir kavram üretme

Her kavram için:
- id: Kısa Türkçe snake_case (ör: "temel_hak", "hicret_donemi")
- term: Kavramın tam adı (Türkçe)
- definition: KPSS odaklı açık tanım (2-3 cümle)
- examples: 1-3 somut örnek (dizi, her biri max 1 cümle)
- relatedTerms: 2-4 ilgili kavram adı (dizi)
- order: Sıra numarası (1'den başla)

SADECE JSON dizisi döndür, başka hiçbir şey yazma:
[
  {
    "id": "kisa_id",
    "term": "Kavram Adı",
    "definition": "Tanım burada.",
    "examples": ["Örnek 1"],
    "relatedTerms": ["İlgili Kavram"],
    "order": 1
  }
]`;

    const maxTokens = Math.min(batchCount * 250 + 1024, 16384);
    const { text } = await callOpenRouter(prompt, model, apiKey, maxTokens);
    const terms = extractJson(text);
    if (!Array.isArray(terms)) throw new Error('Model geçersiz format döndürdü.');
    return terms;
}

async function generateGlossaryTerms({ topicId, topicName, lessonName, count, model, apiKey, existingTerms = [] }) {
    const totalBatches = Math.ceil(count / BATCH_SIZE);

    // Build batch sizes
    const batchSizes = Array.from({ length: totalBatches }, (_, i) =>
        i === totalBatches - 1 ? count - i * BATCH_SIZE : BATCH_SIZE
    );

    console.log(`[Glossary AI] ${totalBatches} batch paralel başlatılıyor (${count} kavram, mevcut: ${existingTerms.length})`);

    // Run all batches in parallel — dedup handles cross-batch duplicates
    const batchPromises = batchSizes.map((batchCount, i) => {
        console.log(`[Glossary AI] Batch ${i + 1}/${totalBatches}: ${batchCount} kavram`);
        return _generateBatch({
            topicName, lessonName, batchCount,
            batchNum: i + 1, totalBatches,
            model, apiKey,
            avoidTerms: existingTerms.map(t => typeof t === 'string' ? t : t.term || ''),
        });
    });

    const results = await Promise.all(batchPromises);
    return results.flat();
}

// Kavram anahtarını normalize ederek yazım/noktalama farklarını tekilleştir
function normalizeTermKey(value) {
    return String(value || '')
        .toLowerCase()
        .replace(/[İIı]/g, 'i')
        .replace(/[Şş]/g, 's')
        .replace(/[Üü]/g, 'u')
        .replace(/[Öö]/g, 'o')
        .replace(/[Çç]/g, 'c')
        .replace(/[Ğğ]/g, 'g')
        .replace(/['`’"]/g, '')
        .replace(/[^a-z0-9\s]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

// Mevcut + yeni batch içindeki kavram adlarını normalize ederek çakışma kontrolü
function deduplicateTerms(newTerms, existingTerms) {
    const existingNorm = new Set(
        existingTerms
            .map(t => normalizeTermKey(typeof t === 'string' ? t : t?.term || ''))
            .filter(Boolean)
    );
    const existingIds = new Set(
        existingTerms
            .map(t => (typeof t === 'object' ? String(t?.id || '').toLowerCase().trim() : ''))
            .filter(Boolean)
    );

    const seenNorm = new Set(existingNorm);
    const seenIds = new Set(existingIds);
    const unique = [];

    for (const t of (Array.isArray(newTerms) ? newTerms : [])) {
        if (!t || typeof t !== 'object') continue;

        const termKey = normalizeTermKey(t.term || '');
        const idKey = String(t.id || '').toLowerCase().trim();

        if (!termKey) continue;
        if (idKey && seenIds.has(idKey)) continue;
        if (seenNorm.has(termKey)) continue;

        if (idKey) seenIds.add(idKey);
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

// Yayınlı + taslak kavramları birleştir (dedupe için kaynak listesi)
function _collectExisting(topicId) {
    const published = (() => {
        const fp = path.join(GLOSSARY_DIR, `${topicId}.json`);
        if (!fsSync.existsSync(fp)) return [];
        try { return JSON.parse(fsSync.readFileSync(fp, 'utf8')); } catch { return []; }
    })();
    const draft = readDraft(topicId) || [];
    // Birleştir, taslak öncelikli (aynı id varsa taslak geçer)
    const map = new Map(published.map(t => [t.id, t]));
    draft.forEach(t => map.set(t.id, t));
    return [...map.values()];
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
                    const draftTerms = readDraft(topicId);
                    sets.push({
                        id: topicId,
                        filename: file,
                        title: TOPIC_TITLES[topicId] || topicId,
                        count: Array.isArray(terms) ? terms.length : 0,
                        draftCount: draftTerms ? draftTerms.length : 0,
                        preview: Array.isArray(terms) && terms[0] ? terms[0].term : ''
                    });
                } catch {}
            }
            // Taslağı olan ama henüz yayınlanmamış konuları da ekle
            const draftFiles = fsSync.existsSync(DRAFT_DIR) ? fsSync.readdirSync(DRAFT_DIR).filter(f => f.endsWith('.json')) : [];
            for (const df of draftFiles) {
                const topicId = path.basename(df, '.json');
                if (!sets.find(s => s.id === topicId)) {
                    const draftTerms = readDraft(topicId);
                    if (draftTerms) {
                        sets.push({
                            id: topicId,
                            filename: null,
                            title: TOPIC_TITLES[topicId] || topicId,
                            count: 0,
                            draftCount: draftTerms.length,
                            preview: draftTerms[0] ? draftTerms[0].term : ''
                        });
                    }
                }
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

    // ── POST /glossary/ai-generate — AI ile kavram üret (kaydetme yok) ──
    if (pathname === '/glossary/ai-generate' && req.method === 'POST') {
        if (!OPENROUTER_KEY) return sendJSON(res, { error: 'OPENROUTER_API_KEY .env\'de tanımlı değil' }, 500);
        try {
            const body = await parseBody(req);
            const { topicId, topicName, lessonName, count = 10, model = 'google/gemini-2.5-flash' } = body;
            if (!topicId || !topicName) return sendJSON(res, { error: 'topicId ve topicName zorunlu' }, 400);

            // Mevcut kavramları topla (yayınlı + taslak)
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
            console.log(`[Glossary AI] ${terms.length} eşsiz kavram hazır (${duplicatesRemoved} çakışma elendi)`);
            return sendJSON(res, { success: true, terms, duplicatesRemoved });
        } catch (e) {
            console.error('[Glossary AI] Hata:', e.message);
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ── POST /glossary/ai-generate-save — AI ile üret + taslağa kaydet ──
    if (pathname === '/glossary/ai-generate-save' && req.method === 'POST') {
        if (!OPENROUTER_KEY) return sendJSON(res, { error: 'OPENROUTER_API_KEY .env\'de tanımlı değil' }, 500);
        try {
            const body = await parseBody(req);
            const { topicId, topicName, lessonName, count = 10, model = 'google/gemini-2.5-flash', append = true } = body;
            if (!topicId || !topicName) return sendJSON(res, { error: 'topicId ve topicName zorunlu' }, 400);

            // Mevcut kavramları topla (yayınlı + taslak)
            const existingTerms = _collectExisting(topicId);
            const batches = Math.ceil(count / BATCH_SIZE);
            console.log(`[Glossary AI] Üret+Taslak: ${topicName} (${count} kavram, ${batches} batch, mevcut: ${existingTerms.length})`);

            const { terms: newTerms, duplicatesRemoved: removed } = await generateUniqueGlossaryTerms({
                topicId, topicName, lessonName: lessonName || 'KPSS', count, model,
                apiKey: OPENROUTER_KEY,
                existingTerms,
            });

            // AI üretiminde mevcut kavramları asla ezme. Temiz başlamak gerekiyorsa
            // kullanıcı mevcut taslağı / dosyayı silip sonra yeniden üretebilir.
            const finalTerms = [...existingTerms, ...newTerms];
            finalTerms = finalTerms.map((t, i) => ({ ...t, order: i + 1 }));

            writeDraft(topicId, finalTerms);
            return sendJSON(res, { success: true, terms: finalTerms, count: finalTerms.length, draft: true, duplicatesRemoved: removed, batches });
        } catch (e) {
            console.error('[Glossary AI] Hata:', e.message);
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ── GET /glossary/draft/:topicId — taslağı getir ──
    if (pathname.match(/^\/glossary\/draft\/[^/]+$/) && req.method === 'GET') {
        const topicId = pathname.split('/')[3];
        const terms = readDraft(topicId);
        if (!terms) return sendJSON(res, { success: true, draft: null });
        return sendJSON(res, { success: true, draft: terms, count: terms.length });
    }

    // ── POST /glossary/draft/:topicId — taslağı manuel kaydet ──
    if (pathname.match(/^\/glossary\/draft\/[^/]+$/) && req.method === 'POST') {
        const topicId = pathname.split('/')[3];
        try {
            const body = await parseBody(req);
            const terms = Array.isArray(body) ? body : body.terms;
            if (!Array.isArray(terms)) return sendJSON(res, { error: 'terms dizisi bekleniyor' }, 400);
            const ordered = terms.map((t, i) => ({ ...t, order: i + 1 }));
            writeDraft(topicId, ordered);
            return sendJSON(res, { success: true, count: ordered.length });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // ── POST /glossary/publish/:topicId — taslağı yayınla ──
    if (pathname.match(/^\/glossary\/publish\/[^/]+$/) && req.method === 'POST') {
        const topicId = pathname.split('/')[3];
        const body = await parseBody(req);
        const topicName = body.topicName || topicId;
        const terms = readDraft(topicId);
        if (!terms) return sendJSON(res, { error: 'Yayınlanacak taslak bulunamadı' }, 404);
        console.log(`[Glossary] Yayınlanıyor: ${topicId} (${terms.length} kavram)`);
        await saveGlossary(topicId, terms);
        deleteDraft(topicId);
        const pushResult = await pushGlossaryToGitHub(topicId, topicName);
        return sendJSON(res, { success: true, count: terms.length, github: pushResult });
    }

    // ── DELETE /glossary/draft/:topicId — taslağı sil ──
    if (pathname.match(/^\/glossary\/draft\/[^/]+$/) && req.method === 'DELETE') {
        const topicId = pathname.split('/')[3];
        deleteDraft(topicId);
        return sendJSON(res, { success: true });
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
            const ap = path.join(ASSETS_GLOSSARY_DIR, `${topicId}.json`);
            if (fsSync.existsSync(fp)) await fs.unlink(fp);
            if (fsSync.existsSync(ap)) await fs.unlink(ap);
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
    await fs.writeFile(path.join(ASSETS_GLOSSARY_DIR, `${topicId}.json`), json, 'utf8');
}

module.exports = handleGlossaryRoutes;
