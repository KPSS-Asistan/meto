import {onCall, onRequest, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";

// Firebase'i başlat (v2 fonksiyonlar admin SDK'yı paylaşır)
if (!admin.apps.length) {
  admin.initializeApp();
}

// Firebase Secrets - Güvenli API anahtarları
const openRouterApiKey = defineSecret("OPENROUTER_API_KEY");
// RevenueCat webhook Authorization header'ı — panelden girilen ortak sır.
// Deploy öncesi: firebase functions:secrets:set REVENUECAT_WEBHOOK_TOKEN
const revenueCatWebhookSecret = defineSecret("REVENUECAT_WEBHOOK_TOKEN");

// Yeni SSE streaming endpoint'leri (Flutter istemcisinin kullandığı)
export {aiChatStream} from "./aiChatStream";
export {aiQuizAnalysisStream} from "./aiQuizAnalysisStream";

// Leaderboard snapshot (maliyet kontrolü için tek doküman)
export {
  rebuildLeaderboardScheduled,
  rebuildLeaderboardNow,
} from "./leaderboardSnapshot";

// Aylık lig sıfırlama (her ayın 1'i 00:05 Europe/Istanbul)
export {
  resetMonthlyLeague,
  resetMonthlyLeagueNow,
} from "./monthlyLeagueReset";

// Güvenli XP callable (istemci doğrudan RTDB yazmak yerine bunu çağırır)
export {addXpCallable} from "./addXp";

// OpenRouter API çağrısı için helper
async function callOpenRouter(apiKey: string, systemPrompt: string, userPrompt: string): Promise<string> {
  const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://kpssasistan.app",
      "X-Title": "KPSS Asistan AI Coach",
    },
    body: JSON.stringify({
      model: "tngtech/deepseek-r1t2-chimera:free",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      max_tokens: 1000,
      temperature: 0.7,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error("OpenRouter API Error:", errorText);
    throw new Error(`OpenRouter API error: ${response.status}`);
  }

  const data = await response.json();
  return data.choices[0]?.message?.content || "";
}

const SYSTEM_INSTRUCTION = `Sen KPSS öğrencilerine yardımcı olan bir AI koçsun.

KPSS hakkında bilmen gerekenler:
- 120 soru, 120 dakika
- Net hesaplaması: doğru - (yanlış/4)
- Pomodoro tekniği: 50 dakika çalış, 10 dakika mola
- Aralıklı tekrar: 1-3-7-14 gün aralıklarla tekrar et

Öğrenciye yardımcı ol:
- Samimi ve motive edici konuş
- Kısa ve öz cevaplar ver (5-8 cümle)
- Mantıklı gerekçeler sun
- Her cevabın sonuna uygun emoji koy

Emoji anlamları:
👊 güç ver, 💥 şaşırt, 🚀 hızlandır, ⚠️ dikkat, 🎯 hedef, 💪 kararlılık, 🔥 motivasyon, 🧠 öğrenme, 📚 çalışma, ⚡ enerji`;

export const askAICoach = onCall({ secrets: [openRouterApiKey] }, async (request) => {
  console.log("🚀 AI Coach çağrıldı");

  // 1. Güvenlik Kontrolü
  if (!request.auth) {
    console.error("❌ Auth hatası: Kullanıcı giriş yapmamış");
    throw new HttpsError("unauthenticated", "Giriş yapmalısın");
  }

  const userId = request.auth.uid;
  const question = request.data.question as string;

  if (!question || question.length > 200) {
    console.error("❌ Soru validasyon hatası: Çok uzun veya boş");
    throw new HttpsError("invalid-argument", "Soru çok uzun");
  }

  // 2. API Anahtarı Kontrolü (OpenRouter - Firebase Secret)
  const apiKey = openRouterApiKey.value();

  if (!apiKey) {
    console.error("❌ OpenRouter API Key eksik!");
    throw new HttpsError("internal", "Sunucu yapılandırma hatası: API Key");
  }

  // 3. Rate Limiting (Günlük 10 Soru)
  const today = new Date();
  const dateKey = `${today.getFullYear()}-${String(
    today.getMonth() + 1
  ).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;

  console.log(`📅 Tarih anahtarı: ${dateKey}`);

  const usageRef = admin
    .firestore()
    .collection("ai_coach_usage")
    .doc(`${userId}_${dateKey}`);
  const usageSnap = await usageRef.get();
  const currentCount = usageSnap.exists ? (usageSnap.data()?.count || 0) : 0;

  console.log(`📊 Mevcut kullanım: ${currentCount}/10`);

  if (currentCount >= 10) {
    console.warn("⚠️ Günlük limit doldu");
    throw new HttpsError(
      "resource-exhausted",
      "Günlük soru limitin doldu (10/10). Yarın gel!"
    );
  }

  try {
    // 4. Soruyu Analiz Et - Performans analizi mi istiyor?
    console.log("🔍 Soru analiz ediliyor...");
    
    const questionLower = question.toLowerCase();
    const needsAnalysis = 
      questionLower.includes("zayıf") ||
      questionLower.includes("güçlü") ||
      questionLower.includes("performans") ||
      questionLower.includes("analiz") ||
      questionLower.includes("hangi konu") ||
      questionLower.includes("odaklan") ||
      questionLower.includes("ilerleme") ||
      questionLower.includes("başarı") ||
      (questionLower.includes("net") && questionLower.includes("artır")) ||
      (questionLower.includes("yanlış") && questionLower.includes("yapıyorum"));

    console.log(`📊 Analiz gerekli mi: ${needsAnalysis}`);

    let userContext = "";

    if (needsAnalysis) {
      // Kullanıcı İlerleme Verisini Çek
      console.log("📚 Kullanıcı progress verisi çekiliyor...");

      const allProgressSnap = await admin
        .firestore()
        .collection("user_progress")
        .where("userId", "==", userId)
        .orderBy("timestamp", "desc")
        .limit(200)
        .get();

      console.log(`📊 Toplam çözülen: ${allProgressSnap.size}`);

      // Minimum 50 soru kontrolü (sadece analiz istediğinde)
      if (allProgressSnap.size < 50) {
        console.log("⚠️ Yetersiz veri: 50 sorudan az çözülmüş");
        
        const prompt = `ÖĞRENCİNİN SANA SORDUĞU SORU:
"${question}"

ÖNEMLİ: Bu öğrenci henüz yeterli soru çözmemiş (${allProgressSnap.size} soru). Performans analizi yapamam. "Henüz yeterli soru çözmedin, en az 50 soru çöz sonra analiz yapabilirim" de. Kısa ve net ol.`;

        const responseText = await callOpenRouter(apiKey, SYSTEM_INSTRUCTION, prompt);

        await usageRef.set(
          {
            userId,
            date: dateKey,
            count: admin.firestore.FieldValue.increment(1),
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        return {
          success: true,
          response: responseText,
          remaining: Math.max(0, 9 - currentCount),
        };
      }

      // Yanlış cevapları çek
      const wrongProgressSnap = await admin
        .firestore()
        .collection("user_progress")
        .where("userId", "==", userId)
        .where("isCorrect", "==", false)
        .orderBy("timestamp", "desc")
        .limit(50)
        .get();

      console.log(`📊 Yanlış: ${wrongProgressSnap.size}`);

      // İstatistikler
      const totalSolved = allProgressSnap.size;
      const totalWrong = wrongProgressSnap.size;
      const totalCorrect = totalSolved - totalWrong;
      const successRate = Math.round((totalCorrect / totalSolved) * 100);

      // En çok yanlış yapılan konuları bul
      const topicFrequency: {[key: string]: number} = {};
      wrongProgressSnap.forEach((doc) => {
        const data = doc.data();
        const name = data.topicName || data.topicId || "Bilinmeyen Konu";
        topicFrequency[name] = (topicFrequency[name] || 0) + 1;
      });

      // En çok yanlış yapılan 3 konu
      const topWrongTopics = Object.entries(topicFrequency)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3)
        .map(([name, count]) => `${name} (${count} yanlış)`)
        .join(", ");

      // Son aktivite
      const lastActivity = allProgressSnap.docs[0]?.data().timestamp;
      const lastActivityDate = lastActivity
        ? new Date(lastActivity.seconds * 1000)
        : null;
      const daysSinceActivity = lastActivityDate
        ? Math.floor(
            (Date.now() - lastActivityDate.getTime()) / (1000 * 60 * 60 * 24)
          )
        : null;

      console.log(`📊 Başarı oranı: ${successRate}%`);
      console.log(`🎯 En çok yanlış yapılan konular: ${topWrongTopics}`);

      userContext = `

MEVCUT ÖĞRENCİ İSTATİSTİKLERİ (Kullanıcı performans analizi istediği için bunları kullan):
- Toplam Çözülen Soru: ${totalSolved}
- Doğru: ${totalCorrect}, Yanlış: ${totalWrong}
- Başarı Oranı: %${successRate}
- En Çok Hata Yapılan Konular: ${topWrongTopics || "Yok"}
- Son Aktivite: ${daysSinceActivity !== null ? `${daysSinceActivity} gün önce` : "Bilinmiyor"}
- Genel Durum: ${successRate < 50 ? "KRİTİK (Düşük Başarı)" : successRate < 70 ? "ORTA (Gelişmeli)" : "İYİ (Yüksek Başarı)"}`;

      console.log(`📋 User Context:\n${userContext}`);
    } else {
      console.log("ℹ️ Genel soru - istatistik kullanılmayacak");
    }

    // 5. OpenRouter API Çağır
    console.log("🤖 OpenRouter API çağrılıyor...");

    const prompt = `ÖĞRENCİNİN SANA SORDUĞU SORU:
"${question}"${userContext}`;

    console.log("📤 Prompt gönderiliyor...");

    const responseText = await callOpenRouter(apiKey, SYSTEM_INSTRUCTION, prompt);

    console.log(`✅ OpenRouter cevap verdi: ${responseText.substring(0, 50)}...`);

    // 6. Kullanımı Artır
    console.log("💾 Kullanım sayacı güncelleniyor...");

    await usageRef.set(
      {
        userId,
        date: dateKey,
        count: admin.firestore.FieldValue.increment(1),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    console.log("✅ İşlem başarılı!");

    // Hızlı sorular oluştur
    const quickQuestionsPrompt = `Kullanıcı şu soruyu sordu: "${question}"

Şimdi bu soruyla alakalı 3 KISA takip sorusu öner. Her soru MAX 6 kelime olsun. Sadece soruları yaz, numara koyma, açıklama yapma.

Format:
Soru 1 buraya
Soru 2 buraya  
Soru 3 buraya`;

    const quickQuestionsText = await callOpenRouter(apiKey, "Sadece 3 kısa soru yaz, başka bir şey yazma.", quickQuestionsPrompt);
    const quickQuestions = quickQuestionsText.split('\n').filter(q => q.trim().length > 0).slice(0, 3);

    return {
      success: true,
      response: responseText,
      remaining: Math.max(0, 9 - currentCount),
      quickQuestions: quickQuestions,
    };
  } catch (error: any) {
    console.error("❌ HATA:", error);
    console.error("❌ Hata mesajı:", error.message);
    console.error("❌ Hata stack:", error.stack);

    if (error.message?.includes("API key")) {
      console.error("❌ API Key hatası tespit edildi!");
    }

    throw new HttpsError("internal", "Koç şu an meşgul, sonra tekrar dene.");
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// REVENUECAT WEBHOOK INTEGRATION
// ═══════════════════════════════════════════════════════════════════════════
export const revenueCatWebhook = onRequest(
  {secrets: [revenueCatWebhookSecret]},
  async (req, res) => {
  try {
    // Güvenlik: RevenueCat panelinden gelen Authorization header'ı
    // Firebase Secret (REVENUECAT_WEBHOOK_TOKEN) ile karşılaştırılır.
    // Hardcoded sır kullanma — secret değeri deploy'dan ayrı ayarlanır.
    const authHeader = req.headers.authorization;
    const expected = `Bearer ${revenueCatWebhookSecret.value()}`;

    if (!authHeader || authHeader !== expected) {
      console.warn("⚠️ Yetkisiz Webhook İsteği");
      res.status(401).send("Unauthorized");
      return;
    }

    const payload = req.body;
    
    // RevenueCat event objesini kontrol et
    if (!payload || !payload.event) {
      console.error("❌ Geçersiz webhook payload:", payload);
      res.status(400).send("Bad Request: Missing event data");
      return;
    }

    const event = payload.event;
    const uid = event.app_user_id; // Mobil tarafta RevenueCat'e login olurken verdiğin uid (user.uid)
    const eventType = event.type;
    
    console.log(`[RevenueCat] Event: ${eventType} | UID: ${uid}`);

    let isPremium: boolean | null = null;
    let premiumType: string | null = null;

    // Premium'u başlatan/yenileyen olaylar
    if (["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "NON_RENEWING_PURCHASE"].includes(eventType)) {
      isPremium = true;
      premiumType = event.product_id; // (Örn: "kpss_premium_1_month")
    } 
    // Premium'u tamamen bitiren olaylar
    else if (["EXPIRATION"].includes(eventType)) {
      isPremium = false;
      premiumType = null;
    }
    // CANCELLATION: Kullanıcı iptal etti ancak süresi dolana kadar Premium kalmaya devam etmeli.
    // O yüzden isPremium false yapmıyoruz, sadece logluyoruz.
    else if (eventType === "CANCELLATION") {
      console.log(`ℹ️ User ${uid} cancelled subscription, but premium stays active until expiration.`);
    }

    // Yalnızca durum değişmişse Firestore'u güncelle
    if (isPremium !== null && uid) {
      await admin.firestore().collection("users").doc(uid).set({
        is_premium: isPremium, // Eski uyumluluk
        isPremium: isPremium,  // Dashboard uyumluluğu
        premiumType: premiumType,
        premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        latestWebhookEvent: eventType
      }, { merge: true });

      // 🚀 ID token custom claim — AI proxy premium kontrolünü Firestore
      // okumadan yapabilsin. Kullanıcı yeni token aldığında etkin olur
      // (FirebaseAuth.currentUser.getIdToken(true) veya 1 saatlik refresh).
      try {
        await admin.auth().setCustomUserClaims(uid, { isPremium });
        console.log(`🔐 Custom claim set: ${uid} -> isPremium=${isPremium}`);
      } catch (claimErr) {
        console.warn(`⚠️ Custom claim set edilemedi (uid=${uid}):`, claimErr);
      }

      console.log(`✅ [RevenueCat] UID: ${uid} -> isPremium: ${isPremium} olarak güncellendi.`);
    }

    // RevenueCat 200 OK yanıtını almazsa isteği tekrar tekrar dener, o yüzden başarılı dönüyoruz.
    res.status(200).send("OK");
  } catch (error) {
    console.error("❌ Webhook İşleme Hatası:", error);
    // Hatalı olsa bile 500 dönersek RevenueCat 10 defa daha dener.
    // Çok kritik değilse 200 dönmek daha iyi olabilir ama şimdilik standart bırakıyoruz.
    res.status(500).send("Internal Server Error");
  }
});
