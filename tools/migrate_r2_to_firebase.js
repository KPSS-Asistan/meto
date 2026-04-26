/**
 * R2'deki TTS ses dosyalarını Firebase Storage'a migrate eder
 * Kullanım: node tools/migrate_r2_to_firebase.js
 */
const path = require('path');
const fs = require('fs');
const os = require('os');

require('dotenv').config({ path: path.join(__dirname, '.env') });

const FILES = [
    'story_JnFbEQt0uA8RSEuy22SQ_0.wav',
    'story_JnFbEQt0uA8RSEuy22SQ_1.wav',
    'story_JnFbEQt0uA8RSEuy22SQ_2.wav',
    'story_JnFbEQt0uA8RSEuy22SQ_3.wav',
];

async function downloadFromR2(fileName) {
    const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
    const client = new S3Client({
        region: 'auto',
        endpoint: process.env.R2_ENDPOINT,
        credentials: {
            accessKeyId: process.env.R2_ACCESS_KEY_ID,
            secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
        },
    });

    const result = await client.send(new GetObjectCommand({
        Bucket: process.env.R2_BUCKET,
        Key: `audio/generated_tts/${fileName}`,
    }));

    const chunks = [];
    for await (const chunk of result.Body) {
        chunks.push(chunk);
    }
    return Buffer.concat(chunks);
}

async function uploadToFirebaseStorage(buffer, fileName) {
    const admin = require('firebase-admin');

    if (!admin.apps.length) {
        const keyPath = path.join(__dirname, 'serviceAccountKey.json');
        const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            storageBucket: 'kpss-c5cad.firebasestorage.app',
        });
    }

    const bucket = admin.storage().bucket();
    const storagePath = `audio/generated_tts/${fileName}`;
    const tmpFile = path.join(os.tmpdir(), fileName);

    fs.writeFileSync(tmpFile, buffer);
    await bucket.upload(tmpFile, {
        destination: storagePath,
        metadata: { contentType: 'audio/wav' },
    });
    fs.unlinkSync(tmpFile);

    const encodedPath = encodeURIComponent(storagePath);
    return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media`;
}

async function main() {
    console.log('🔄 R2 → Firebase Storage migrasyonu başlıyor...\n');

    for (const fileName of FILES) {
        try {
            console.log(`⬇️  R2'den indiriliyor: ${fileName}`);
            const buffer = await downloadFromR2(fileName);
            console.log(`   ${(buffer.length / 1024).toFixed(1)} KB indirildi`);

            console.log(`⬆️  Firebase Storage'a yükleniyor...`);
            const url = await uploadToFirebaseStorage(buffer, fileName);
            console.log(`✅ Tamamlandı: ${url}\n`);
        } catch (e) {
            console.error(`❌ Hata (${fileName}): ${e.message}\n`);
        }
    }

    console.log('🎉 Migrasyon tamamlandı!');
    console.log('Story JSON dosyaları aşağıdaki URL formatında güncellenmeli:');
    console.log('https://firebasestorage.googleapis.com/v0/b/kpss-c5cad.firebasestorage.app/o/audio%2Fgenerated_tts%2F{fileName}?alt=media');
}

main().catch(console.error);
