/**
 * Mevcut local WAV dosyalarını Firebase Storage'a yükler
 * ve ilgili story JSON dosyalarındaki audioUrl'leri günceller.
 * 
 * Kullanım: node tools/upload_audio_to_firebase.js
 */

const path = require('path');
const fs = require('fs');
const fsP = require('fs').promises;

const ROOT_DIR = path.join(__dirname, '..');
const AUDIO_DIR = path.join(ROOT_DIR, 'assets', 'audio', 'generated_tts');
const STORIES_ASSET_DIR = path.join(ROOT_DIR, 'assets', 'data', 'stories');
const STORIES_DEV_DIR = path.join(ROOT_DIR, 'stories');

// Firebase Admin
let admin;
try {
    admin = require('firebase-admin');
    const keyPath = path.join(__dirname, 'serviceAccountKey.json');
    if (!admin.apps.length) {
        const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            storageBucket: 'kpss-c5cad.firebasestorage.app',
        });
    }
    console.log('✅ Firebase Admin başlatıldı');
} catch (e) {
    console.error('❌ Firebase Admin başlatılamadı:', e.message);
    process.exit(1);
}

async function uploadToStorage(localFilePath, fileName) {
    const bucket = admin.storage().bucket();
    const destination = `audio/generated_tts/${fileName}`;
    await bucket.upload(localFilePath, {
        destination,
        metadata: { contentType: 'audio/wav' },
    });
    const file = bucket.file(destination);
    const [url] = await file.getSignedUrl({
        action: 'read',
        expires: '01-01-2099',
    });
    return url;
}

async function updateJsonAudioUrl(topicId, index, newUrl) {
    const files = [
        path.join(STORIES_ASSET_DIR, `${topicId}.json`),
        path.join(STORIES_DEV_DIR, `${topicId}.json`),
    ];
    for (const file of files) {
        if (!fs.existsSync(file)) continue;
        const data = JSON.parse(await fsP.readFile(file, 'utf8'));
        if (Array.isArray(data) && data[index] !== undefined) {
            data[index].audioUrl = newUrl;
            await fsP.writeFile(file, JSON.stringify(data, null, 2), 'utf8');
            console.log(`  ✅ JSON güncellendi: ${path.basename(file)} [${index}]`);
        }
    }
}

async function main() {
    const wavFiles = fs.readdirSync(AUDIO_DIR).filter(f => f.endsWith('.wav'));
    if (wavFiles.length === 0) {
        console.log('Yüklenecek WAV dosyası yok.');
        return;
    }

    console.log(`\n${wavFiles.length} dosya yüklenecek:\n`);

    for (const fileName of wavFiles) {
        // Dosya adı formatı: story_<topicId>_<index>.wav
        const match = fileName.match(/^story_(.+)_(\d+)\.wav$/);
        if (!match) {
            console.log(`⚠️ Tanınmayan dosya formatı, atlandı: ${fileName}`);
            continue;
        }
        const topicId = match[1];
        const index = parseInt(match[2], 10);
        const localPath = path.join(AUDIO_DIR, fileName);

        console.log(`📤 ${fileName} yükleniyor...`);
        try {
            const url = await uploadToStorage(localPath, fileName);
            console.log(`  🔗 URL: ${url.substring(0, 80)}...`);
            await updateJsonAudioUrl(topicId, index, url);
        } catch (e) {
            console.error(`  ❌ Hata: ${e.message}`);
        }
    }

    console.log('\n✅ Tamamlandı.');
}

main();
