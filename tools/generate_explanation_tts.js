/**
 * Tüm explanation bölümleri için paralel TTS üretimi
 * Kullanım: node tools/generate_explanation_tts.js [--concurrency 8] [--topic <topicId>]
 */
const fs = require('fs');
const path = require('path');
const os = require('os');

require('dotenv').config({ path: path.join(__dirname, '.env') });

const ROOT_DIR = path.join(__dirname, '..');
const EXPLANATIONS_DIR = path.join(ROOT_DIR, 'explanations');
const ASSETS_DIR = path.join(ROOT_DIR, 'assets', 'data', 'explanations');
const TMP_DIR = path.join(os.tmpdir(), 'kpss_exp_tts');

// Argümanları parse et
const args = process.argv.slice(2);
const CONCURRENCY = parseInt(args[args.indexOf('--concurrency') + 1] || '8', 10);
const ONLY_TOPIC = args.includes('--topic') ? args[args.indexOf('--topic') + 1] : null;
const SKIP_EXISTING = !args.includes('--force');

if (!fs.existsSync(TMP_DIR)) fs.mkdirSync(TMP_DIR, { recursive: true });

// Firebase Admin başlat
const admin = require('firebase-admin');
if (!admin.apps.length) {
  const keyPath = path.join(__dirname, 'serviceAccountKey.json');
  if (!fs.existsSync(keyPath)) {
    console.error('❌ tools/serviceAccountKey.json bulunamadı');
    process.exit(1);
  }
  admin.initializeApp({
    credential: admin.credential.cert(require(keyPath)),
    storageBucket: 'kpss-c5cad.firebasestorage.app',
  });
}

// İçerik öğelerini düz metne çevir
function contentToText(title, contentItems) {
  let parts = [title];
  for (const item of contentItems) {
    if (!item) continue;
    if (item.text && item.type !== 'table') parts.push(item.text);
    else if (item.items && Array.isArray(item.items)) parts.push(item.items.join('. '));
  }
  return parts.join('. ').replace(/\s+/g, ' ').trim().slice(0, 4500);
}

// Firebase Storage'a yükle
async function uploadToFirebase(localPath, fileName) {
  const bucket = admin.storage().bucket();
  const storagePath = `audio/generated_tts/${fileName}`;
  await bucket.upload(localPath, {
    destination: storagePath,
    metadata: { contentType: 'audio/mpeg' },
  });
  const encoded = encodeURIComponent(storagePath);
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encoded}?alt=media`;
}

// Edge TTS ile MP3 üret
async function generateTTS(text) {
  const { MsEdgeTTS, OUTPUT_FORMAT } = require('msedge-tts');
  const tts = new MsEdgeTTS();
  await tts.setMetadata('tr-TR-AhmetNeural', OUTPUT_FORMAT.AUDIO_24KHZ_48KBITRATE_MONO_MP3);
  return new Promise((resolve, reject) => {
    const { audioStream } = tts.toStream(text);
    const chunks = [];
    audioStream.on('data', c => chunks.push(c));
    audioStream.on('end', () => resolve(Buffer.concat(chunks)));
    audioStream.on('error', reject);
  });
}

// JSON dosyasına audioUrl yaz
function writeAudioUrl(filePath, sectionKey, url) {
  if (!fs.existsSync(filePath)) return;
  try {
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    if (data[sectionKey] !== undefined) {
      data[sectionKey].audioUrl = url;
      fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
    }
  } catch (e) {
    console.warn(`  ⚠️ JSON yazma hatası: ${filePath} [${sectionKey}]: ${e.message}`);
  }
}

// Tüm görevleri topla
function collectTasks() {
  const files = fs.readdirSync(EXPLANATIONS_DIR).filter(f => f.endsWith('.json'));
  const tasks = [];

  for (const file of files) {
    const topicId = path.basename(file, '.json');
    if (ONLY_TOPIC && topicId !== ONLY_TOPIC) continue;

    const filePath = path.join(EXPLANATIONS_DIR, file);
    let data;
    try { data = JSON.parse(fs.readFileSync(filePath, 'utf8')); } catch { continue; }

    for (const key of Object.keys(data)) {
      const section = data[key];
      if (!section || !section.title) continue;
      if (SKIP_EXISTING && section.audioUrl && section.audioUrl.startsWith('https://firebasestorage')) continue;

      const text = contentToText(section.title, section.content || []);
      if (!text.trim()) continue;

      tasks.push({ topicId, key, file, text, title: section.title });
    }
  }
  return tasks;
}

// Concurrency limiti ile paralel çalıştır
async function runWithConcurrency(tasks, limit) {
  let i = 0, ok = 0, skipped = 0, errors = 0;
  const total = tasks.length;

  async function worker() {
    while (i < tasks.length) {
      const idx = i++;
      const task = tasks[idx];
      const fileName = `explanation_${task.topicId}_${task.key}.mp3`;
      const tmpPath = path.join(TMP_DIR, fileName);

      try {
        const buf = await generateTTS(task.text);
        fs.writeFileSync(tmpPath, buf);
        const url = await uploadToFirebase(tmpPath, fileName);

        // Her iki dizini güncelle
        writeAudioUrl(path.join(EXPLANATIONS_DIR, task.file), task.key, url);
        writeAudioUrl(path.join(ASSETS_DIR, task.file), task.key, url);

        fs.unlinkSync(tmpPath);
        ok++;
        console.log(`  ✅ [${ok+errors}/${total}] ${task.topicId}[${task.key}] → ${fileName}`);
      } catch (e) {
        errors++;
        try { if (fs.existsSync(tmpPath)) fs.unlinkSync(tmpPath); } catch {}
        console.error(`  ❌ [${ok+errors}/${total}] ${task.topicId}[${task.key}]: ${e.message}`);
      }
    }
  }

  const workers = Array.from({ length: limit }, () => worker());
  await Promise.all(workers);

  return { ok, errors, total };
}

async function main() {
  console.log(`\n🎵 Explanation TTS Üretimi Başlıyor`);
  console.log(`  Concurrency: ${CONCURRENCY} | Skip existing: ${SKIP_EXISTING}${ONLY_TOPIC ? ' | Konu: ' + ONLY_TOPIC : ''}\n`);

  const tasks = collectTasks();
  if (tasks.length === 0) {
    console.log('✅ Üretilecek bölüm yok (hepsi zaten var veya dosya bulunamadı)');
    process.exit(0);
  }

  console.log(`📋 ${tasks.length} bölüm üretilecek...\n`);
  const start = Date.now();

  const { ok, errors, total } = await runWithConcurrency(tasks, CONCURRENCY);
  const elapsed = ((Date.now() - start) / 1000).toFixed(1);

  console.log(`\n✅ Tamamlandı: ${ok} başarılı, ${errors} hatalı / ${total} toplam (${elapsed}s)`);
  process.exit(errors > 0 ? 1 : 0);
}

main().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
