/**
 * Eksik konular için 100 kavram üretir (Gemini 2.5 Flash Lite via OpenRouter)
 * Kullanım: node tools/generate_glossary.js [--count 100] [--topic <id>] [--force]
 */
require('dotenv').config({ path: require('path').join(__dirname, '.env') });

const fs = require('fs');
const https = require('https');
const path = require('path');

const ROOT_DIR = path.join(__dirname, '..');
const GLOSSARY_DIR = path.join(__dirname, 'glossary');
const ASSETS_DIR = path.join(ROOT_DIR, 'assets', 'data', 'glossary');

[GLOSSARY_DIR, ASSETS_DIR].forEach(d => { if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true }); });

const args = process.argv.slice(2);
const COUNT = parseInt(args[args.indexOf('--count') + 1] || '100', 10);
const ONLY_TOPIC = args.includes('--topic') ? args[args.indexOf('--topic') + 1] : null;
const FORCE = args.includes('--force');
const MODEL = 'google/gemini-2.5-flash-lite';
const BATCH_SIZE = 20;

const OPENROUTER_KEY = process.env.OPENROUTER_API_KEY;
if (!OPENROUTER_KEY) { console.error('❌ OPENROUTER_API_KEY .env\'de yok'); process.exit(1); }

const TOPIC_TITLES = {
  '1FEcPsGduhjcQARpaGBk': "Coğrafya - Türkiye'nin Coğrafi Konumu",
  '1JZAYECyEn7farNNyGyx': 'Vatandaşlık - Devlet Organları',
  '6e0Thsz2RRNHFcwqQXso': 'Coğrafya - İklim ve Bitki Örtüsü',
  'AQ0Zph76dzPdr87H1uKa': 'Vatandaşlık - Hukuka Giriş',
  'Bo3qqooJsqtIZrK5zc9S': 'Vatandaşlık - Temel Hak ve Özgürlükler',
  'GdpN8uxJNGtexWrkoL1T': "Coğrafya - Türkiye'nin Coğrafi Bölgeleri",
  'GUNCEL_BM_KURULUS': 'Güncel - BM ve Uluslararası Kuruluşlar',
  'GUNCEL_BOLGESEL_KURULUS': 'Güncel - Bölgesel Uluslararası Kuruluşlar',
  'GUNCEL_NATO_AB': 'Güncel - NATO ve AB',
  'GUNCEL_ONEMLI_TARIHLER': 'Güncel - Önemli Tarihler ve Olaylar',
  'GUNCEL_TURKIYE_KURULUS': "Güncel - Türkiye'nin Üye Olduğu Kuruluşlar",
  'kbs0Ffved9pCP3Hq9M9k': "Coğrafya - Türkiye'nin Fiziki Özellikleri",
  'lv93cmhwq7RmOFM5WxWD': 'Vatandaşlık - İdari Yapı',
  'MAT_ASAL_EBOB_EKOK': 'Matematik - Asal Sayılar, EBOB ve EKOK',
  'MAT_BOLUNEEBILME': 'Matematik - Bölünebilme Kuralları',
  'MAT_ESITSIZLIK_MUTLAK': 'Matematik - Eşitsizlik ve Mutlak Değer',
  'MAT_KUMELER': 'Matematik - Kümeler',
  'MAT_RASYONEL_SAYILAR': 'Matematik - Rasyonel Sayılar',
  'MAT_TEMEL_KAVRAMLAR': 'Matematik - Temel Kavramlar ve Sayı Sistemleri',
  'MAT_USLU_SAYILAR': 'Matematik - Üslü Sayılar',
  'n4OjWupHmouuybQzQ1Fc': 'Vatandaşlık - Anayasa Hukuku',
  'uYDrMlBCEAho5776WZi8': 'Coğrafya - Beşeri Coğrafya',
  'WxrtQ26p2My4uJa0h1kk': 'Coğrafya - Ekonomik Coğrafya',
  'xXGXiqx2TkCtI4C7GMQg': 'Vatandaşlık - 1982 Anayasası Temel İlkeleri',
};

function callOpenRouter(prompt, maxTokens = 10000) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      model: MODEL,
      messages: [
        { role: 'system', content: 'Sen KPSS sınav hazırlık uzmanısın. Sadece geçerli JSON dizisi döndür. Kod bloğu, önsöz, açıklama YAZMA.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.5,
      max_tokens: maxTokens
    });
    const options = {
      hostname: 'openrouter.ai', port: 443, path: '/api/v1/chat/completions', method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'http://localhost:3456',
        'X-Title': 'KPSS Glossary Generator'
      },
      timeout: 120000
    };
    const req = https.request(options, (res) => {
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end', () => {
        try {
          const data = JSON.parse(Buffer.concat(chunks).toString('utf8'));
          if (res.statusCode !== 200) return reject(new Error(`OpenRouter ${res.statusCode}: ${data.error?.message || ''}`));
          resolve(data.choices?.[0]?.message?.content || '');
        } catch (e) { reject(e); }
      });
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('Timeout')); });
    req.write(body);
    req.end();
  });
}

function extractJson(text) {
  let clean = text.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '').trim();
  const arrStart = clean.indexOf('[');
  if (arrStart > 0) clean = clean.slice(arrStart);
  try { return JSON.parse(clean); } catch {}
  // Kısmi kurtarma
  let depth = 0, lastEnd = -1, inStr = false, esc = false;
  for (let i = 0; i < clean.length; i++) {
    const c = clean[i];
    if (esc) { esc = false; continue; }
    if (c === '\\' && inStr) { esc = true; continue; }
    if (c === '"') { inStr = !inStr; continue; }
    if (inStr) continue;
    if (c === '{') depth++;
    else if (c === '}') { depth--; if (depth === 0) lastEnd = i; }
  }
  if (lastEnd !== -1) {
    try { const r = JSON.parse(clean.slice(0, lastEnd + 1) + ']'); if (Array.isArray(r)) return r; } catch {}
  }
  throw new Error('JSON parse edilemedi');
}

function normalizeKey(v) {
  return String(v || '').toLowerCase()
    .replace(/[İı]/g, 'i').replace(/[Şş]/g, 's').replace(/[Üü]/g, 'u')
    .replace(/[Öö]/g, 'o').replace(/[Çç]/g, 'c').replace(/[Ğğ]/g, 'g')
    .replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
}

async function generateBatch(topicName, lessonName, batchCount, avoidTerms) {
  const avoidBlock = avoidTerms.length > 0
    ? `\n⚠️ MEVCUT KAVRAMLAR (bunları TEKRAR YAZMA):\n${avoidTerms.slice(-50).map((t, i) => `${i+1}. ${t}`).join('\n')}\n`
    : '';
  const prompt = `Sen KPSS hazırlık uzmanısın.
"${lessonName}" dersinin "${topicName}" konusu için ${batchCount} adet KPSS sınavında sıkça sorulan temel kavramı üret.
${avoidBlock}
Kurallar:
- Kavramlar sınav odaklı, kısa ve net olmalı
- Tanım max 3 cümle
- examples: 1-3 somut örnek
- relatedTerms: 2-4 ilgili kavram
- Tekrar eden kavram OLMASIN
- Yukarıdaki mevcut kavramlarla çakışma

SADECE JSON dizisi döndür:
[
  {
    "id": "snake_case_id",
    "term": "Kavram Adı",
    "definition": "Tanım",
    "examples": ["Örnek 1"],
    "relatedTerms": ["İlgili Kavram"],
    "order": 1
  }
]`;
  const text = await callOpenRouter(prompt, BATCH_SIZE * 300 + 1024);
  return extractJson(text);
}

async function generateForTopic(topicId, topicTitle, targetCount) {
  const [lessonName, topicName] = topicTitle.split(' - ').map(s => s.trim());
  const fp = path.join(GLOSSARY_DIR, `${topicId}.json`);
  const existing = fs.existsSync(fp) ? JSON.parse(fs.readFileSync(fp, 'utf8')) : [];

  if (!FORCE && existing.length >= targetCount) {
    console.log(`  ⏭️  ${topicId}: zaten ${existing.length} kavram var (atlandı)`);
    return 0;
  }

  const needed = targetCount - existing.length;
  console.log(`  🔄 ${topicId}: ${existing.length} mevcut → ${needed} yeni kavram üretilecek`);

  const collected = [];
  const seenNorm = new Set(existing.map(t => normalizeKey(t.term)));
  const seenIds = new Set(existing.map(t => (t.id || '').toLowerCase()));
  let attempts = 0;

  while (collected.length < needed && attempts < 5) {
    attempts++;
    const batchSize = Math.min(BATCH_SIZE, needed - collected.length + 3);
    const avoidTerms = [...existing, ...collected].map(t => t.term);
    try {
      const batch = await generateBatch(topicName, lessonName || 'KPSS', batchSize, avoidTerms);
      let added = 0;
      for (const t of batch) {
        if (!t?.term) continue;
        const nk = normalizeKey(t.term);
        const ik = (t.id || '').toLowerCase().trim();
        if (seenNorm.has(nk) || (ik && seenIds.has(ik))) continue;
        seenNorm.add(nk);
        if (ik) seenIds.add(ik);
        collected.push(t);
        added++;
        if (collected.length >= needed) break;
      }
      console.log(`    Batch ${attempts}: ${batch.length} üretildi, ${added} eklendi (toplam: ${collected.length}/${needed})`);
    } catch (e) {
      console.warn(`    ⚠️ Batch ${attempts} hata: ${e.message}`);
    }
  }

  const finalTerms = [...existing, ...collected].slice(0, existing.length + collected.length).map((t, i) => ({ ...t, order: i + 1 }));
  const json = JSON.stringify(finalTerms, null, 2);
  fs.writeFileSync(fp, json, 'utf8');
  fs.writeFileSync(path.join(ASSETS_DIR, `${topicId}.json`), json, 'utf8');
  console.log(`  ✅ ${topicId}: ${finalTerms.length} kavram yazıldı`);
  return collected.length;
}

async function main() {
  const topics = ONLY_TOPIC
    ? [[ONLY_TOPIC, TOPIC_TITLES[ONLY_TOPIC] || ONLY_TOPIC]]
    : Object.entries(TOPIC_TITLES).filter(([id]) => {
        if (FORCE) return true;
        const fp = path.join(GLOSSARY_DIR, `${id}.json`);
        if (!fs.existsSync(fp)) return true;
        const count = JSON.parse(fs.readFileSync(fp, 'utf8')).length;
        return count < COUNT;
      });

  console.log(`\n📚 Glossary Üretimi Başlıyor`);
  console.log(`  Model: ${MODEL} | Hedef: ${COUNT} kavram/konu | ${topics.length} konu işlenecek\n`);

  let totalAdded = 0;
  for (const [topicId, topicTitle] of topics) {
    const added = await generateForTopic(topicId, topicTitle, COUNT);
    totalAdded += added;
  }

  console.log(`\n✅ Tamamlandı: ${totalAdded} yeni kavram eklendi`);
}

main().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
