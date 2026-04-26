#!/usr/bin/env node
/**
 * AI tabanlı encoding düzeltici.
 * fix_encoding.js'den sonra çalıştır — kalan U+FFFD içeren kelimeleri OpenRouter'a gönderir.
 *
 * Strateji:
 * 1. Tüm JSON dosyalarını tara, FFFD içeren benzersiz kelimeleri topla
 * 2. AI'a batch gönder ("bu bozuk Türkçe kelimeleri düzelt")
 * 3. Sözlük olarak uygula
 *
 * Kullanım: node tools/scripts/fix_encoding_ai.js [--dry]
 * Env: OPENROUTER_API_KEY gerekli (.env'den okunur)
 */
const path0 = require('path');
// Env'i root'tan yükle (OPENROUTER_API_KEY)
require('dotenv').config({ path: path0.join(__dirname, '../../.env') });
require('dotenv').config({ path: path0.join(__dirname, '../.env') });
const fs = require('fs');
const path = require('path');
const https = require('https');

const ROOT = path.resolve(__dirname, '../..');
const ASSETS_DIR = path.join(ROOT, 'assets', 'data');
const QUESTIONS_DIR = path.join(ROOT, 'questions');
const DRY_RUN = process.argv.includes('--dry');
const API_KEY = process.env.OPENROUTER_API_KEY;
const BATCH_SIZE = 50; // Kelime / request
const MODEL = 'google/gemini-2.5-flash-lite';
const FFFD_DISPLAY = '\uFFFD';

if (!API_KEY) {
    console.error('❌ OPENROUTER_API_KEY gerekli (.env)');
    process.exit(1);
}

function scanDir(dir) {
    const files = [];
    if (!fs.existsSync(dir)) return files;
    for (const f of fs.readdirSync(dir)) {
        const full = path.join(dir, f);
        const st = fs.statSync(full);
        if (st.isDirectory()) files.push(...scanDir(full));
        else if (f.endsWith('.json')) files.push(full);
    }
    return files;
}

function extractBrokenWords(text) {
    const words = new Set();
    const matches = text.matchAll(/[^\s\r\n",{}\[\]:]*\uFFFD+[^\s\r\n",{}\[\]:]*/g);
    for (const m of matches) {
        const w = m[0];
        if (w.length >= 2 && w.length <= 50) words.add(w);
    }
    return words;
}

function callOpenRouter(brokenWords) {
    return new Promise((resolve, reject) => {
        const wordList = brokenWords.map((w, i) => `${i + 1}. ${w}`).join('\n');
        const prompt = `Aşağıdaki Türkçe kelimelerde ? ile işaretli karakterler bozuk. Her kelimeyi DOĞRU TÜRKÇE haline getir.

ÇIKTI FORMATI: Her satırda sadece "numara. düzeltilmiş_kelime" yaz. Açıklama YAZMA.

ÖRNEK INPUT:
1. T??rk
2. te?kilat
3. Sel??uklu
4. a??a??daki

ÖRNEK OUTPUT:
1. Türk
2. teşkilat
3. Selçuklu
4. aşağıdaki

ŞIMDI DÜZELT (? karakteri ? yerine ${FFFD_DISPLAY} kullanılıyor):
${wordList}`;

        const body = JSON.stringify({
            model: MODEL,
            messages: [
                { role: 'system', content: 'Sen Türkçe karakter encoding uzmanısın. SADECE istenen formatta çıktı ver, başka açıklama yok.' },
                { role: 'user', content: prompt }
            ],
            temperature: 0.1,
            max_tokens: 4000,
        });

        const req = https.request({
            hostname: 'openrouter.ai',
            path: '/api/v1/chat/completions',
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${API_KEY}`,
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://kpssasistan.com',
                'X-Title': 'KPSS KOC Encoding Fixer',
                'Content-Length': Buffer.byteLength(body),
            }
        }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const json = JSON.parse(data);
                    const content = json.choices?.[0]?.message?.content || '';
                    resolve(content);
                } catch (e) {
                    reject(new Error(`Parse error: ${e.message}\n${data.substring(0, 300)}`));
                }
            });
        });
        req.on('error', reject);
        req.setTimeout(60000, () => { req.destroy(); reject(new Error('Timeout')); });
        req.write(body);
        req.end();
    });
}

function parseResponse(content, inputWords) {
    const map = new Map();
    const lines = content.split('\n');
    for (const line of lines) {
        const m = line.match(/^\s*(\d+)[\.\)]\s*(.+?)\s*$/);
        if (!m) continue;
        const idx = parseInt(m[1], 10) - 1;
        const fixed = m[2].trim();
        if (idx >= 0 && idx < inputWords.length && fixed && !fixed.includes('\uFFFD')) {
            map.set(inputWords[idx], fixed);
        }
    }
    return map;
}

async function main() {
    console.log('🔍 Bozuk kelimeler taranıyor...');
    const files = [
        ...scanDir(ASSETS_DIR),
        ...scanDir(QUESTIONS_DIR),
    ];

    const allWords = new Set();
    for (const file of files) {
        const content = fs.readFileSync(file, 'utf8');
        for (const w of extractBrokenWords(content)) allWords.add(w);
    }

    const wordArray = [...allWords];
    console.log(`📊 ${wordArray.length} benzersiz bozuk kelime bulundu`);

    if (wordArray.length === 0) {
        console.log('✅ Düzeltilecek kelime yok');
        return;
    }

    console.log(`🤖 OpenRouter (${MODEL}) ile ${Math.ceil(wordArray.length / BATCH_SIZE)} batch'te düzeltilecek...`);

    const fixMap = new Map();
    for (let i = 0; i < wordArray.length; i += BATCH_SIZE) {
        const batch = wordArray.slice(i, i + BATCH_SIZE);
        const batchNum = Math.floor(i / BATCH_SIZE) + 1;
        const totalBatches = Math.ceil(wordArray.length / BATCH_SIZE);
        process.stdout.write(`  Batch ${batchNum}/${totalBatches} (${batch.length} kelime)... `);
        try {
            const response = await callOpenRouter(batch);
            if (batchNum === 1) {
                console.log(`\n=== DEBUG: İlk batch yanıtı ===\n${response}\n=== SON ===\n`);
            }
            const partialMap = parseResponse(response, batch);
            for (const [k, v] of partialMap) fixMap.set(k, v);
            console.log(`✓ ${partialMap.size} eşleşme`);
        } catch (e) {
            console.log(`✗ Hata: ${e.message}`);
        }
        // Rate limit koruması
        if (i + BATCH_SIZE < wordArray.length) {
            await new Promise(r => setTimeout(r, 1000));
        }
    }

    console.log(`\n📝 Toplam ${fixMap.size} / ${wordArray.length} kelime AI'dan alındı`);

    // Sözlüğü JSON olarak kaydet (gelecekte kullanım için)
    const dictPath = path.join(__dirname, 'ai_encoding_dict.json');
    const dictObj = Object.fromEntries(fixMap);
    fs.writeFileSync(dictPath, JSON.stringify(dictObj, null, 2), 'utf8');
    console.log(`💾 Sözlük kaydedildi: ${dictPath}`);

    // Dosyaları güncelle
    let filesUpdated = 0;
    let totalReplacements = 0;
    for (const file of files) {
        let content = fs.readFileSync(file, 'utf8');
        let changed = false;
        let fileReplacements = 0;
        // Uzun kelimelerden kısaya doğru sırala (overlap önleme)
        const sorted = [...fixMap.entries()].sort((a, b) => b[0].length - a[0].length);
        for (const [broken, fixed] of sorted) {
            if (content.includes(broken)) {
                const escaped = broken.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
                const re = new RegExp(escaped, 'g');
                const matches = content.match(re);
                if (matches) {
                    content = content.replace(re, fixed);
                    changed = true;
                    fileReplacements += matches.length;
                }
            }
        }
        if (changed) {
            filesUpdated++;
            totalReplacements += fileReplacements;
            if (!DRY_RUN) {
                fs.writeFileSync(file, content, 'utf8');
            }
        }
    }

    console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`✅ Dosya: ${filesUpdated}, Toplam değişim: ${totalReplacements}`);
    console.log(DRY_RUN ? '🔍 DRY RUN (yazılmadı)' : '💾 Dosyalar güncellendi');
}

main().catch(e => {
    console.error('❌ Hata:', e);
    process.exit(1);
});
