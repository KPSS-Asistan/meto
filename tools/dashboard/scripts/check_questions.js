#!/usr/bin/env node
/**
 * check_questions.js
 * 
 * GitHub'daki (veya local assets) soru JSON dosyalarını tarayıp olası hataları raporlar:
 *  - Encoding bozukluğu (? karakteri)
 *  - Şıklarda prefix (A) B- C. gibi)
 *  - Eksik zorunlu alanlar (id, q, o, a)
 *  - Yanlış şık sayısı (5'ten az/fazla)
 *  - Geçersiz correctAnswer index
 *  - Yinelenen soru ID'leri
 * 
 * KULLANIM:
 *   node tools/dashboard/scripts/check_questions.js              # local assets
 *   node tools/dashboard/scripts/check_questions.js --github     # GitHub'dan indir
 *   node tools/dashboard/scripts/check_questions.js --topic XYZ  # tek topic
 *   node tools/dashboard/scripts/check_questions.js --fix        # prefix'leri otomatik temizle (local)
 */

const fs   = require('fs');
const path = require('path');
const https = require('https');

// ─── Config ──────────────────────────────────────────────────────────────────

const ROOT_DIR    = path.join(__dirname, '..', '..', '..');
const ASSETS_DIR  = path.join(ROOT_DIR, 'assets', 'data', 'questions');
const GITHUB_BASE = 'https://raw.githubusercontent.com/mertcanasdf/meto/main/questions';
const OPTION_PREFIX_RE = /^[A-Ea-e][).–\-]\s*/;
const ENCODING_BROKEN_RE = /[^\u0000-\u00FF\u011E\u011F\u0130\u0131\u015E\u015F\u00C7\u00E7\u00D6\u00F6\u00DC\u00FC]/; // beklenmedik unicode

const args       = process.argv.slice(2);
const useGitHub  = args.includes('--github');
const autoFix    = args.includes('--fix');
const topicArg   = args.includes('--topic') ? args[args.indexOf('--topic') + 1] : null;

// ─── Helpers ─────────────────────────────────────────────────────────────────

function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, res => {
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end', () => {
        if (res.statusCode !== 200) return reject(new Error(`HTTP ${res.statusCode}: ${url}`));
        resolve(Buffer.concat(chunks).toString('utf8'));
      });
    });
    req.on('error', reject);
    req.setTimeout(15000, () => { req.destroy(); reject(new Error(`Timeout: ${url}`)); });
  });
}

function readLocal(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

function getLocalTopicIds() {
  return fs.readdirSync(ASSETS_DIR)
    .filter(f => f.endsWith('.json'))
    .map(f => path.basename(f, '.json'));
}

// ─── Checker ─────────────────────────────────────────────────────────────────

const COLORS = {
  reset: '\x1b[0m',
  red:   '\x1b[31m',
  yellow:'\x1b[33m',
  green: '\x1b[32m',
  cyan:  '\x1b[36m',
  bold:  '\x1b[1m',
  dim:   '\x1b[2m',
};
const c = (color, text) => `${COLORS[color]}${text}${COLORS.reset}`;

function checkQuestions(topicId, jsonString) {
  const issues = [];
  let data;

  try {
    data = JSON.parse(jsonString);
  } catch (e) {
    return [{ severity: 'ERROR', msg: `JSON parse hatası: ${e.message}` }];
  }

  if (!Array.isArray(data)) {
    return [{ severity: 'ERROR', msg: 'JSON array değil' }];
  }

  const seenIds = new Set();

  data.forEach((q, idx) => {
    const loc = `[${idx}]`;

    // Zorunlu alanlar
    if (!q.id)  issues.push({ severity: 'WARN',  msg: `${loc} id eksik` });
    if (!q.q)   issues.push({ severity: 'ERROR', msg: `${loc} q (soru metni) eksik` });
    if (!q.o)   issues.push({ severity: 'ERROR', msg: `${loc} o (şıklar) eksik` });
    if (q.a === undefined || q.a === null) issues.push({ severity: 'ERROR', msg: `${loc} a (cevap index) eksik` });

    // Yinelenen ID
    if (q.id) {
      if (seenIds.has(q.id)) {
        issues.push({ severity: 'ERROR', msg: `${loc} Yinelenen ID: ${q.id}` });
      }
      seenIds.add(q.id);
    }

    // Soru metni encoding
    if (q.q && q.q.includes('\uFFFD')) {
      issues.push({ severity: 'ERROR', msg: `${loc} Soru metni encoding bozuk (replacement char): ${q.q.substring(0, 60)}` });
    }
    if (q.q && /\?{2,}/.test(q.q)) {
      issues.push({ severity: 'WARN',  msg: `${loc} Soru metninde ardışık ?? var (encoding?): ${q.q.substring(0, 60)}` });
    }

    // Şık sayısı
    if (q.o) {
      if (!Array.isArray(q.o)) {
        issues.push({ severity: 'ERROR', msg: `${loc} o (şıklar) array değil` });
      } else {
        if (q.o.length < 5) {
          issues.push({ severity: 'ERROR', msg: `${loc} Şık sayısı ${q.o.length} (5 olmalı)` });
        }
        if (q.o.length > 5) {
          issues.push({ severity: 'WARN',  msg: `${loc} Şık sayısı ${q.o.length} (5'ten fazla)` });
        }

        // Prefix kontrol
        const prefixedOpts = q.o
          .map((opt, i) => ({ i, opt: String(opt) }))
          .filter(({ opt }) => OPTION_PREFIX_RE.test(opt));
        if (prefixedOpts.length > 0) {
          prefixedOpts.forEach(({ i, opt }) => {
            issues.push({ severity: 'WARN', msg: `${loc} Şık[${i}] prefix içeriyor: "${opt.substring(0, 50)}"` });
          });
        }

        // Şık encoding
        q.o.forEach((opt, i) => {
          const s = String(opt);
          if (s.includes('\uFFFD')) {
            issues.push({ severity: 'ERROR', msg: `${loc} Şık[${i}] encoding bozuk: "${s.substring(0, 50)}"` });
          }
        });
      }
    }

    // Cevap index geçerliliği
    if (q.a !== undefined && q.o && Array.isArray(q.o)) {
      if (typeof q.a !== 'number' || q.a < 0 || q.a >= q.o.length) {
        issues.push({ severity: 'ERROR', msg: `${loc} Geçersiz cevap index: a=${q.a}, şık sayısı=${q.o.length}` });
      }
    }
  });

  return issues;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log(c('bold', '\n🔍 KPSS Soru Kalite Kontrol\n') + c('dim', `Kaynak: ${useGitHub ? 'GitHub' : 'Local assets'}\n`));

  const topicIds = topicArg ? [topicArg] : getLocalTopicIds();
  console.log(`${topicIds.length} topic taranıyor...\n`);

  let totalQuestions = 0;
  let totalErrors    = 0;
  let totalWarns     = 0;
  let cleanTopics    = 0;
  let fixedTopics    = 0;

  if (autoFix && useGitHub) {
    console.log(c('red', '❌ --fix yalnızca local assets ile çalışır (--github ile kullanılamaz)\n'));
    process.exit(1);
  }

  for (const topicId of topicIds) {
    let jsonString;
    try {
      if (useGitHub) {
        jsonString = await fetchUrl(`${GITHUB_BASE}/${topicId}.json`);
      } else {
        jsonString = readLocal(path.join(ASSETS_DIR, `${topicId}.json`));
      }
    } catch (e) {
      console.log(c('red', `✗ ${topicId}: ${e.message}`));
      totalErrors++;
      continue;
    }

    const issues = checkQuestions(topicId, jsonString);
    const errors = issues.filter(i => i.severity === 'ERROR');
    const warns  = issues.filter(i => i.severity === 'WARN');
    const prefixWarns = warns.filter(w => w.msg.includes('prefix'));

    totalErrors += errors.length;
    totalWarns  += warns.length;

    // Soru sayısı (hızlı)
    try {
      const data = JSON.parse(jsonString);
      const count = data.length;
      totalQuestions += count;

      // --fix modunda prefix'leri temizle
      if (autoFix && prefixWarns.length > 0 && !useGitHub) {
        let fixed = 0;
        data.forEach(q => {
          if (q.o && Array.isArray(q.o)) {
            q.o = q.o.map(opt => {
              const s = String(opt);
              const stripped = s.replace(OPTION_PREFIX_RE, '').trim();
              if (stripped !== s) fixed++;
              return stripped;
            });
          }
          // Son eleman boş obje ise çıkar
          if (!q.id && !q.q && !q.o) return null;
        });
        // Boş objeleri filtrele
        const cleaned = data.filter(q => q.id || q.q || q.o);
        const filePath = path.join(ASSETS_DIR, `${topicId}.json`);
        fs.writeFileSync(filePath, JSON.stringify(cleaned, null, 2), 'utf8');
        console.log(c('cyan', `🔧 ${topicId}`) + ` ${fixed} prefix temizlendi, ${data.length - cleaned.length} boş obje silindi`);
        fixedTopics++;
        return;
      }

      if (issues.length === 0) {
        console.log(c('green', `✓`) + ` ${topicId} ${c('dim', `(${count} soru)`)}`);
        cleanTopics++;
      } else {
        const label = errors.length > 0 ? c('red', `✗ ${topicId}`) : c('yellow', `⚠ ${topicId}`);
        console.log(`${label} ${c('dim', `(${count} soru, ${errors.length} hata, ${warns.length} uyarı)`)}`);
        issues.forEach(({ severity, msg }) => {
          const icon = severity === 'ERROR' ? c('red', '  ❌') : c('yellow', '  ⚠️ ');
          console.log(`${icon} ${msg}`);
        });
      }
    } catch (_) {
      console.log(c('red', `✗ ${topicId}: parse hatası`));
    }
  }

  // Özet
  console.log('\n' + '─'.repeat(60));
  console.log(c('bold', '📊 ÖZET'));
  console.log(`  Toplam topic  : ${topicIds.length}`);
  console.log(`  Toplam soru   : ${totalQuestions}`);
  console.log(c('green',  `  Temiz topic   : ${cleanTopics}`));
  if (fixedTopics > 0) console.log(c('cyan', `  Düzeltilen     : ${fixedTopics}`));
  console.log(c('red',    `  Hata sayısı   : ${totalErrors}`));
  console.log(c('yellow', `  Uyarı sayısı  : ${totalWarns}`));
  console.log('─'.repeat(60) + '\n');

  if (totalErrors > 0) process.exit(1);
}

main().catch(e => { console.error(e); process.exit(1); });
