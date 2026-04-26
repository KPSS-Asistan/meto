const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');
const { sendJSON, parseBody } = require('../utils/helper');

require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const ROOT_DIR = path.join(__dirname, '../../../..');
const AUDIO_DIR = path.join(require('os').tmpdir(), 'kpss_tts');

if (!fsSync.existsSync(AUDIO_DIR)) {
    fsSync.mkdirSync(AUDIO_DIR, { recursive: true });
}

async function uploadToFirebaseStorage(localFilePath, fileName) {
    const { admin } = require('../firebase-admin');
    if (!admin) throw new Error('Firebase Admin SDK başlatılamadı');

    const bucket = admin.storage().bucket();
    const storagePath = `audio/generated_tts/${fileName}`;

    await bucket.upload(localFilePath, {
        destination: storagePath,
        metadata: { contentType: 'audio/mpeg' },
    });

    // Public download URL - storage.rules'da public read tanımlı
    const encodedPath = encodeURIComponent(storagePath);
    const bucketName = bucket.name;
    return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodedPath}?alt=media`;
}

// Helper: Microsoft Edge TTS (ücretsiz, kota yok)
async function callOpenRouterTTS({ text, voice = 'alloy' }) {
    if (!text || text.trim() === '') throw new Error('Metin boş olamaz');

    const { MsEdgeTTS, OUTPUT_FORMAT } = require('msedge-tts');

    // voice parametresini Edge sesine eşleştir
    const voiceMap = {
        alloy: 'tr-TR-AhmetNeural',
        echo:  'tr-TR-AhmetNeural',
        fable: 'tr-TR-AhmetNeural',
        onyx:  'tr-TR-AhmetNeural',
        nova:  'tr-TR-EmelNeural',
        shimmer: 'tr-TR-GülNilüferNeural',
    };
    const voiceName = voiceMap[voice] || 'tr-TR-AhmetNeural';

    const tts = new MsEdgeTTS();
    await tts.setMetadata(voiceName, OUTPUT_FORMAT.AUDIO_24KHZ_48KBITRATE_MONO_MP3);

    return new Promise((resolve, reject) => {
        const { audioStream } = tts.toStream(text.slice(0, 5000));
        const chunks = [];
        audioStream.on('data', chunk => chunks.push(chunk));
        audioStream.on('end', () => resolve(Buffer.concat(chunks)));
        audioStream.on('error', reject);
    });
}

// Helper: Update a story JSON file to include the audioUrl
// itemId format: "topicId_index" e.g. "4GUvpqBBImcLmN2eh1HK_2"
async function updateStoryAudioUrl(itemId, url) {
    // itemId'yi topicId ve index'e ayır (son _ den böl)
    const lastUnderscore = itemId.lastIndexOf('_');
    if (lastUnderscore === -1) {
        console.warn(`[TTS] updateStoryAudioUrl: geçersiz itemId=${itemId}`);
        return;
    }
    const topicId = itemId.substring(0, lastUnderscore);
    const index = parseInt(itemId.substring(lastUnderscore + 1), 10);
    if (isNaN(index)) {
        console.warn(`[TTS] updateStoryAudioUrl: index parse edilemedi itemId=${itemId}`);
        return;
    }

    const pubPath = path.join(ROOT_DIR, 'assets', 'data', 'stories', `${topicId}.json`);
    const devPath = path.join(ROOT_DIR, 'stories', `${topicId}.json`);
    
    for (const file of [pubPath, devPath]) {
        if (!fsSync.existsSync(file)) continue;
        try {
            const content = await fs.readFile(file, 'utf8');
            const data = JSON.parse(content);
            if (Array.isArray(data)) {
                if (data[index] !== undefined) {
                    data[index].audioUrl = url;
                    await fs.writeFile(file, JSON.stringify(data, null, 2), 'utf8');
                    console.log(`[TTS] JSON güncellendi (array): ${file} [${index}].audioUrl`);
                }
            } else if (data[String(index)] !== undefined) {
                data[String(index)].audioUrl = url;
                await fs.writeFile(file, JSON.stringify(data, null, 2), 'utf8');
                console.log(`[TTS] JSON güncellendi (object): ${file} ["${index}"].audioUrl`);
            } else {
                console.warn(`[TTS] JSON güncelleme başarısız: ${file} index=${index} geçersiz`);
            }
        } catch (e) {
            console.error(`[TTS] Seste güncellenirken hata: ${file}`, e);
        }
    }
}

async function handleTTSRoutes(req, res, pathname) {
    if (pathname === '/tts/delete' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { audioUrl } = body;
            if (!audioUrl) return sendJSON(res, { error: 'audioUrl zorunlu' }, 400);

            // Firebase Storage'dan sil
            if (audioUrl.startsWith('https://firebasestorage.googleapis.com')) {
                const { admin } = require('../firebase-admin');
                try {
                    // URL'den dosya path'ini çıkar
                    const match = audioUrl.match(/\/o\/([^?]+)/);
                    if (match) {
                        const storagePath = decodeURIComponent(match[1]);
                        await admin.storage().bucket().file(storagePath).delete();
                        console.log(`[TTS] Firebase Storage'dan silindi: ${storagePath}`);
                    }
                } catch (e) {
                    console.warn('[TTS] Firebase Storage silme hatası:', e.message);
                }
                return sendJSON(res, { success: true });
            }

            return sendJSON(res, { success: true });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    if (pathname === '/tts/generate-all' && req.method === 'POST') {
        const body = await parseBody(req);
        const { topicId, voice = 'alloy', skipExisting = true } = body;

        const STORIES_DIR = path.join(ROOT_DIR, 'stories');
        const fsSync2 = require('fs');

        try {
            const files = topicId
                ? [`${topicId}.json`]
                : fsSync2.readdirSync(STORIES_DIR).filter(f => f.endsWith('.json'));

            const results = [];

            for (const file of files) {
                const filePath = path.join(STORIES_DIR, file);
                if (!fsSync2.existsSync(filePath)) continue;

                const tId = path.basename(file, '.json');
                let storyData;
                try {
                    storyData = JSON.parse(await fs.readFile(filePath, 'utf8'));
                } catch { continue; }

                // JSON ya dizi ya da {0:{...}, 1:{...}} şeklinde obje olabilir
                const storyArr = Array.isArray(storyData)
                    ? storyData
                    : Object.keys(storyData).sort((a, b) => Number(a) - Number(b)).map(k => storyData[k]);

                if (!storyArr.length) continue;

                for (let i = 0; i < storyArr.length; i++) {
                    const section = storyArr[i];
                    if (!section.content) continue;
                    if (skipExisting && section.audioUrl && section.audioUrl.startsWith('https://firebasestorage')) {
                        results.push({ topicId: tId, index: i, status: 'skipped' });
                        continue;
                    }

                    const fileName = `story_${tId}_${i}.mp3`;
                    const tmpPath = path.join(AUDIO_DIR, fileName);
                    try {
                        console.log(`[TTS-ALL] ${tId} bölüm ${i + 1}/${storyArr.length}`);
                        const buf = await callOpenRouterTTS({ text: section.content, voice });
                        await fs.writeFile(tmpPath, buf);
                        const url = await uploadToFirebaseStorage(tmpPath, fileName);
                        await updateStoryAudioUrl(`${tId}_${i}`, url);
                        fs.unlink(tmpPath).catch(() => {});
                        results.push({ topicId: tId, index: i, status: 'ok', url });
                    } catch (e) {
                        fs.unlink(tmpPath).catch(() => {});
                        results.push({ topicId: tId, index: i, status: 'error', error: e.message });
                        console.error(`[TTS-ALL] Hata ${tId}[${i}]:`, e.message);
                    }
                }
            }

            const ok = results.filter(r => r.status === 'ok').length;
            const skipped = results.filter(r => r.status === 'skipped').length;
            const errors = results.filter(r => r.status === 'error').length;
            return sendJSON(res, { success: true, ok, skipped, errors, results });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    if (pathname === '/tts/generate' && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { text, type, itemId, voice = 'alloy' } = body;

            if (!text || !type || !itemId) {
                return sendJSON(res, { error: 'text, type (ör: story, glossary) ve itemId zorunlu' }, 400);
            }

            const fileName = `${type}_${itemId}.mp3`;
            const filePath = path.join(AUDIO_DIR, fileName);

            console.log(`[TTS] Üretiliyor (Edge TTS): ${fileName} (${text.length} karakter)`);
            const audioBuffer = await callOpenRouterTTS({ text, voice });
            
            await fs.writeFile(filePath, audioBuffer);
            console.log(`[TTS] Geçici dosya oluşturuldu: ${filePath}`);

            // Firebase Storage'a yükle → kalıcı URL al
            let audioUrl;
            try {
                audioUrl = await uploadToFirebaseStorage(filePath, fileName);
                console.log(`[TTS] Firebase Storage'a yüklendi: ${audioUrl}`);
            } catch (storageErr) {
                console.warn(`[TTS] Firebase Storage'a yüklenemedi, local path kullanılıyor: ${storageErr.message}`);
                // Hata fırlatma! Fallback olarak local dev yolunu yaz
                audioUrl = `assets/audio/generated_tts/${fileName}`;
                
                // assets kopyasını yerleştirmeliyiz (local kullanım için server static dizinine de düşmesi için)
                const fallbackDest = path.join(ROOT_DIR, 'assets', 'audio', 'generated_tts', fileName);
                const destDir = path.dirname(fallbackDest);
                if (!fsSync.existsSync(destDir)) fsSync.mkdirSync(destDir, { recursive: true });
                await fs.copyFile(filePath, fallbackDest);
            } finally {
                // Geçici dosyayı her durumda sil
                fs.unlink(filePath).catch(() => {});
            }

            // Story JSON dosyasına audioUrl'i yaz
            if (type === 'story') {
                await updateStoryAudioUrl(itemId, audioUrl);
            }

            return sendJSON(res, { 
                success: true, 
                message: 'Ses başarıyla üretildi ve kaydedildi.',
                file: fileName,
                path: audioUrl
            });

        } catch (e) {
            console.error('[TTS] Hata:', e.message);
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
}

module.exports = handleTTSRoutes;