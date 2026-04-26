/**
 * Tüm story bölümleri için paralel TTS üretimi
 * Kullanım: node tools/generate_story_tts.js [--concurrency 8] [--topic <topicId>] [--force]
 */
const fs = require('fs');
const path = require('path');
const os = require('os');

require('dotenv').config({ path: path.join(__dirname, '.env') });

const ROOT_DIR = path.join(__dirname, '..');
const STORIES_DIR = path.join(ROOT_DIR, 'stories');
const ASSETS_DIR = path.join(ROOT_DIR, 'assets', 'data', 'stories');
const TMP_DIR = path.join(os.tmpdir(), 'kpss_story_tts');

const args = process.argv.slice(2);
const CONCURRENCY = parseInt(args[args.indexOf('--concurrency') + 1] || '8', 10);
const ONLY_TOPIC = args.includes('--topic') ? args[args.indexOf('--topic') + 1] : null;
const SKIP_EXISTING = !args.includes('--force');

if (!fs.existsSync(TMP_DIR)) fs.mkdirSync(TMP_DIR, { recursive: true });

const admin = require('firebase-admin');
if (!admin.apps.length) {
  const keyPath = path.join(__dirname, 'serviceAccountKey.json');
  if (!fs.existsSync(keyPath)) { console.error('❌ tools/serviceAccountKey.json bulunamadı'); process.exit(1); }
  admin.initializeApp({
    credential: admin.credential.cert(require(keyPath)),
    storageBucket: 'kpss-c5cad.firebasestorage.app',
  });
}

async function uploadToFirebase(localPath, fileName) {
  const bucket = admin.storage().bucket();
  const storagePath = `audio/generated_tts/${fileName}`;
  await bucket.upload(localPath, { destination: storagePath, metadata: { contentType: 'audio/mpeg' } });
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(storagePath)}?alt=media`;
}

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

function writeAudioUrl(filePath, key, url) {
  if (!fs.existsSync(filePath)) return;
  try {
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    if (data[key] !== undefined) {
      data[key].audioUrl = url;
      fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
    }
  } catch (e) { console.warn(`  ⚠️ JSON yazma hatası: ${filePath}[${key}]: ${e.message}`); }
}

function collectTasks() {
  const files = fs.readdirSync(STORIES_DIR).filter(f => f.endsWith('.json'));
  const tasks = [];
  for (const file of files) {
    const topicId = path.basename(file, '.json');
    if (ONLY_TOPIC && topicId !== ONLY_TOPIC) continue;
    let data;
    try { data = JSON.parse(fs.readFileSync(path.join(STORIES_DIR, file), 'utf8')); } catch { continue; }
    for (const key of Object.keys(data)) {
      const section = data[key];
      if (!section || !section.content) continue;
      if (SKIP_EXISTING && section.audioUrl && section.audioUrl.startsWith('https://firebasestorage')) continue;
      tasks.push({ topicId, key, file, text: section.content.slice(0, 4500) });
    }
  }
  return tasks;
}

async function runWithConcurrency(tasks, limit) {
  let i = 0, ok = 0, errors = 0;
  const total = tasks.length;
  async function worker() {
    while (i < tasks.length) {
      const idx = i++;
      const { topicId, key, file, text } = tasks[idx];
      const fileName = `story_${topicId}_${key}.mp3`;
      const tmpPath = path.join(TMP_DIR, fileName);
      try {
        const buf = await generateTTS(text);
        fs.writeFileSync(tmpPath, buf);
        const url = await uploadToFirebase(tmpPath, fileName);
        writeAudioUrl(path.join(STORIES_DIR, file), key, url);
        writeAudioUrl(path.join(ASSETS_DIR, file), key, url);
        fs.unlinkSync(tmpPath);
        ok++;
        console.log(`  ✅ [${ok+errors}/${total}] ${topicId}[${key}]`);
      } catch (e) {
        errors++;
        try { if (fs.existsSync(tmpPath)) fs.unlinkSync(tmpPath); } catch {}
        console.error(`  ❌ [${ok+errors}/${total}] ${topicId}[${key}]: ${e.message}`);
      }
    }
  }
  await Promise.all(Array.from({ length: limit }, () => worker()));
  return { ok, errors, total };
}

async function main() {
  console.log(`\n🎵 Story TTS Üretimi Başlıyor`);
  console.log(`  Concurrency: ${CONCURRENCY} | Skip existing: ${SKIP_EXISTING}${ONLY_TOPIC ? ' | Konu: ' + ONLY_TOPIC : ''}\n`);
  const tasks = collectTasks();
  if (!tasks.length) { console.log('✅ Üretilecek bölüm yok'); process.exit(0); }
  console.log(`📋 ${tasks.length} bölüm üretilecek...\n`);
  const start = Date.now();
  const { ok, errors, total } = await runWithConcurrency(tasks, CONCURRENCY);
  console.log(`\n✅ Tamamlandı: ${ok} başarılı, ${errors} hatalı / ${total} toplam (${((Date.now()-start)/1000).toFixed(1)}s)`);
  process.exit(errors > 0 ? 1 : 0);
}

main().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
