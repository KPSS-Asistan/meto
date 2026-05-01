/**
 * Merkezi Firebase Admin başlatıcı
 * Railway: FIREBASE_SERVICE_ACCOUNT env variable (JSON string)
 * Local:   serviceAccountKey.json dosyası
 */
const path = require('path');
const fs = require('fs');

let admin = null;
let db = null;

try {
    admin = require('firebase-admin');

    if (!admin.apps.length) {
        let credential;

        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
            // Railway / Production: env variable'dan al
            const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
            credential = admin.credential.cert(serviceAccount);
            console.log('✅ Firebase Admin SDK başlatıldı (env variable)');
        } else {
            // Local: dosyadan al
            const serviceAccountPath = path.join(__dirname, '../../serviceAccountKey.json');
            if (fs.existsSync(serviceAccountPath)) {
                const serviceAccount = require(serviceAccountPath);
                credential = admin.credential.cert(serviceAccount);
                console.log('✅ Firebase Admin SDK başlatıldı (serviceAccountKey.json)');
            } else {
                console.log('⚠️ Firebase credentials bulunamadı — mock modda çalışıyor');
            }
        }

        if (credential) {
            admin.initializeApp({ credential });
            db = admin.firestore();
        }
    } else {
        db = admin.firestore();
    }
} catch (e) {
    console.log('⚠️ Firebase Admin yüklenemedi:', e.message);
}

module.exports = { admin, db };
