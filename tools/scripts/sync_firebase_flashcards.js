/**
 * Firebase Flashcards Sync Script
 * Firebase'deki flashcard'ları yerel dosyalara senkronize eder
 */
const admin = require('firebase-admin');
const fs = require('fs').promises;
const path = require('path');

// Firebase Admin SDK başlatma
const serviceAccountPath = path.join(__dirname, '../serviceAccountKey.json');

if (!require('fs').existsSync(serviceAccountPath)) {
    console.error('❌ serviceAccountKey.json bulunamadı!');
    process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log('✅ Firebase Admin SDK başlatıldı');
}

const db = admin.firestore();
const FLASHCARDS_DIR = path.join(__dirname, '../flashcards');

// Türkçe başlık mapping (dashboard'daki ile aynı)
const FLASHCARD_TITLES = {
    '1FEcPsGduhjcQARpaGBk': 'Coğrafya - Genel Konum',
    '4GUvpqBBImcLmN2eh1HK': 'Atatürk İlkeleri ve İnkılap Tarihi',
    '80e0wkTLvaTQzPD6puB7': 'Türk Dili ve Edebiyatı',
    '9Hg8tuMRdMTuVY7OZ9HL': 'Tarih - Osmanlı Dönemi',
    'DlT19snCttf5j5RUAXLz': 'Matematik - Temel Kavramlar',
    'JnFbEQt0uA8RSEuy22SQ': 'Tarih - Cumhuriyet Dönemi',
    'n4OjWupHmouuybQzQ1Fc': 'Vatandaşlık',
    'onwrfsH02TgIhlyRUh56': 'Tarih - Dünya Savaşları',
    'qBFhnVl9E4oNj8MsBqnB': 'Coğrafya - Beşeri Coğrafya',
    'rl2xQTfv1iUaCyhFzp5V': 'Çağdaş Türk ve Dünya Tarihi'
};

async function syncFlashcardsFromFirebase() {
    try {
        console.log('🔄 Firebase\'den flashcard\'lar senkronize ediliyor...');
        
        // Tüm koleksiyonları listele
        const collections = await db.listCollections();
        console.log('📋 Mevcut koleksiyonlar:');
        collections.forEach(col => console.log(`   - ${col.id}`));
        
        // Flashcard ile ilgili olabilecek koleksiyonları kontrol et
        const possibleNames = ['flashcards', 'flashcard_sets', 'flashcardData', 'flashcard_data', 'cards'];
        
        for (const name of possibleNames) {
            console.log(`\n🔍 '${name}' koleksiyonu kontrol ediliyor...`);
            const snapshot = await db.collection(name).limit(1).get();
            
            if (!snapshot.empty) {
                console.log(`✅ '${name}' koleksiyonu bulundu!`);
                
                // Tüm verileri al
                const fullSnapshot = await db.collection(name).get();
                console.log(`📦 Toplam ${fullSnapshot.size} kayıt bulundu`);
                
                // İlk birkaç kaydın yapısını incele
                console.log('\n📝 İlk kayıt örnekleri:');
                let count = 0;
                for (const doc of fullSnapshot.docs) {
                    if (count >= 3) break;
                    console.log(`   Doküman ID: ${doc.id}`);
                    console.log(`   Veri:`, Object.keys(doc.data()));
                    count++;
                }
                
                // Eğer bu doğru koleksiyon ise senkronize et
                if (fullSnapshot.size > 0 && fullSnapshot.docs[0].data().cards) {
                    console.log('\n✅ Bu flashcard koleksiyonu! Senkronize ediliyor...');
                    
                    for (const doc of fullSnapshot.docs) {
                        const flashcardData = doc.data();
                        const fileId = doc.id;
                        const cards = flashcardData.cards || [];
                        
                        const filename = `${fileId}.json`;
                        const filePath = path.join(FLASHCARDS_DIR, filename);
                        
                        await fs.writeFile(filePath, JSON.stringify(cards, null, 2), 'utf8');
                        
                        const title = FLASHCARD_TITLES[fileId] || fileId;
                        console.log(`   ✅ ${title} (${filename}): ${cards.length} kart`);
                    }
                    return;
                }
            }
        }
        
        // Sorular içinde flashcard formatını kontrol et
        console.log('\n🔍 Sorular koleksiyonu kontrol ediliyor...');
        const questionsSnapshot = await db.collection('questions').get();
        
        if (!questionsSnapshot.empty) {
            console.log(`✅ Questions koleksiyonu bulundu! ${questionsSnapshot.size} kayıt`);
            
            // Flashcard formatında olanları bul
            for (const doc of questionsSnapshot.docs) {
                const data = doc.data();
                
                // Eğer içinde questions dizisi varsa ve her biri soru-cevap formatındaysa
                if (data.questions && Array.isArray(data.questions)) {
                    console.log(`\n📝 Doküman: ${doc.id}`);
                    console.log(`   Başlık: ${data.title || 'N/A'}`);
                    console.log(`   Soru sayısı: ${data.questions.length}`);
                    
                    // Flashcard formatına çevir
                    const cards = data.questions.map(q => ({
                        question: q.question || q.text,
                        answer: q.answer || q.correctAnswer || q.explanation,
                        additionalInfo: q.explanation || q.additionalInfo || ''
                    }));
                    
                    // Dosya olarak kaydet
                    const filename = `${doc.id}.json`;
                    const filePath = path.join(FLASHCARDS_DIR, filename);
                    
                    await fs.writeFile(filePath, JSON.stringify(cards, null, 2), 'utf8');
                    
                    const title = FLASHCARD_TITLES[doc.id] || data.title || doc.id;
                    console.log(`   ✅ ${title} olarak kaydedildi: ${cards.length} kart`);
                    
                    // Özellikle İslamiyet Öncesi için kontrol
                    if (data.title && data.title.toLowerCase().includes('islamiyet')) {
                        console.log(`   🎯 İSLAMIYET ÖNCESİ BULUNDU! ${cards.length} kart`);
                    }
                }
            }
        }
        
    } catch (error) {
        console.error('❌ Senkronizasyon hatası:', error);
    } finally {
        process.exit(0);
    }
}

// Script'i çalıştır
syncFlashcardsFromFirebase();
