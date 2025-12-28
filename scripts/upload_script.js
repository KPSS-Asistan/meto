/**
 * KPSS 2026 - Firestore Soru Yükleme Script'i
 * 
 * Kullanım:
 * 1. npm install firebase-admin
 * 2. serviceAccountKey.json dosyasını scripts/ klasörüne koy
 * 3. node upload_script.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Firebase Admin SDK'yı service account ile başlat
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// JSON dosyasını oku (sorular_*.json formatında)
function loadQuestionsFromFile() {
  const files = fs.readdirSync(path.join(__dirname, '..')).filter(f => f.startsWith('sorular_') && f.endsWith('.json'));
  
  if (files.length === 0) {
    console.error('❌ Soru dosyası bulunamadı! (sorular_*.json)');
    process.exit(1);
  }
  
  const filePath = path.join(__dirname, '..', files[0]);
  console.log(`📂 Dosya okunuyor: ${files[0]}`);
  
  const rawData = fs.readFileSync(filePath, 'utf8');
  const jsonData = JSON.parse(rawData);
  
  // JSON formatını kontrol et
  if (jsonData.questions && Array.isArray(jsonData.questions)) {
    return jsonData.questions;
  } else if (Array.isArray(jsonData)) {
    return jsonData;
  } else {
    console.error('❌ Geçersiz JSON formatı!');
    process.exit(1);
  }
}

// Random index üret (0 - 1,000,000)
function generateRandomIndex() {
  return Math.floor(Math.random() * 1000001);
}

// Ana yükleme fonksiyonu
async function uploadQuestions() {
  const questions = loadQuestionsFromFile();
  const batchSize = 400; // Firestore batch limiti 500, güvenli tarafta kalıyoruz
  
  let batch = db.batch();
  let batchCount = 0;
  let totalUploaded = 0;
  let batchNumber = 1;

  console.log(`\n🚀 Yükleme başlıyor...`);
  console.log(`📊 Toplam soru sayısı: ${questions.length}`);
  console.log(`📦 Batch boyutu: ${batchSize}\n`);

  const startTime = Date.now();

  for (let i = 0; i < questions.length; i++) {
    const question = questions[i];
    
    // Yeni alanları ekle
    const enhancedQuestion = {
      question_text: question.question_text,
      options: question.options,
      correct_answer: question.correct_answer,
      explanation: question.explanation || '',
      random_index: generateRandomIndex(),
      version: 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Firestore'da auto-generated ID ile doküman oluştur
    const docRef = db.collection('questions').doc();
    
    // Batch'e ekle
    batch.set(docRef, enhancedQuestion);
    batchCount++;
    totalUploaded++;

    // Batch dolunca commit et
    if (batchCount >= batchSize) {
      process.stdout.write(`⏳ Batch ${batchNumber} commit ediliyor (${batchCount} soru)...`);
      await batch.commit();
      console.log(` ✅`);
      
      // Progress bar
      const progress = Math.round((totalUploaded / questions.length) * 100);
      console.log(`📈 İlerleme: ${totalUploaded}/${questions.length} (${progress}%)\n`);
      
      // Yeni batch başlat
      batch = db.batch();
      batchCount = 0;
      batchNumber++;
    }
  }

  // Kalan soruları commit et
  if (batchCount > 0) {
    process.stdout.write(`⏳ Son batch commit ediliyor (${batchCount} soru)...`);
    await batch.commit();
    console.log(` ✅`);
  }

  const endTime = Date.now();
  const duration = ((endTime - startTime) / 1000).toFixed(2);

  console.log(`\n${'='.repeat(50)}`);
  console.log(`🎉 YÜKLEME TAMAMLANDI!`);
  console.log(`${'='.repeat(50)}`);
  console.log(`📊 Toplam yüklenen: ${totalUploaded} soru`);
  console.log(`⏱️  Süre: ${duration} saniye`);
  console.log(`📦 Batch sayısı: ${batchNumber}`);
  console.log(`${'='.repeat(50)}\n`);
}

// Script'i çalıştır
uploadQuestions()
  .then(() => {
    console.log('✨ Script başarıyla tamamlandı.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Hata oluştu:', error);
    process.exit(1);
  });
