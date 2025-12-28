"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.askAICoach = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const admin = __importStar(require("firebase-admin"));
// Firebase Secret - Güvenli API Key
const openRouterApiKey = (0, params_1.defineSecret)("OPENROUTER_API_KEY");
// Firebase'i başlat
if (!admin.apps.length) {
    admin.initializeApp();
}
// OpenRouter API çağrısı için helper
async function callOpenRouter(apiKey, systemPrompt, userPrompt) {
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
exports.askAICoach = (0, https_1.onCall)({ secrets: [openRouterApiKey] }, async (request) => {
    console.log("🚀 AI Coach çağrıldı");
    // 1. Güvenlik Kontrolü
    if (!request.auth) {
        console.error("❌ Auth hatası: Kullanıcı giriş yapmamış");
        throw new https_1.HttpsError("unauthenticated", "Giriş yapmalısın");
    }
    const userId = request.auth.uid;
    const question = request.data.question;
    console.log(`👤 User ID: ${userId}`);
    console.log(`❓ Soru: ${question}`);
    if (!question || question.length > 200) {
        console.error("❌ Soru validasyon hatası: Çok uzun veya boş");
        throw new https_1.HttpsError("invalid-argument", "Soru çok uzun");
    }
    // 2. API Anahtarı Kontrolü (OpenRouter - Firebase Secret)
    const apiKey = openRouterApiKey.value();
    console.log(`🔑 OpenRouter API Key var mı: ${!!apiKey}`);
    console.log(`🔑 API Key ilk 15 karakter: ${apiKey?.substring(0, 15)}...`);
    if (!apiKey) {
        console.error("❌ OpenRouter API Key eksik!");
        throw new https_1.HttpsError("internal", "Sunucu yapılandırma hatası: API Key");
    }
    // 3. Rate Limiting (Günlük 10 Soru)
    const today = new Date();
    const dateKey = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;
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
        throw new https_1.HttpsError("resource-exhausted", "Günlük soru limitin doldu (10/10). Yarın gel!");
    }
    try {
        // 4. Soruyu Analiz Et - Performans analizi mi istiyor?
        console.log("🔍 Soru analiz ediliyor...");
        const questionLower = question.toLowerCase();
        const needsAnalysis = questionLower.includes("zayıf") ||
            questionLower.includes("güçlü") ||
            questionLower.includes("performans") ||
            questionLower.includes("analiz") ||
            questionLower.includes("hangi konu") ||
            questionLower.includes("odaklan") ||
            questionLower.includes("ilerleme") ||
            questionLower.includes("başarı") ||
            questionLower.includes("net") && questionLower.includes("artır") ||
            questionLower.includes("yanlış") && questionLower.includes("yapıyorum");
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
                await usageRef.set({
                    userId,
                    date: dateKey,
                    count: admin.firestore.FieldValue.increment(1),
                    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
                return {
                    success: true,
                    response: responseText,
                    remaining: 9 - currentCount,
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
            const topicFrequency = {};
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
                ? Math.floor((Date.now() - lastActivityDate.getTime()) / (1000 * 60 * 60 * 24))
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
        }
        else {
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
        await usageRef.set({
            userId,
            date: dateKey,
            count: admin.firestore.FieldValue.increment(1),
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
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
            remaining: 9 - currentCount,
            quickQuestions: quickQuestions,
        };
    }
    catch (error) {
        console.error("❌ HATA:", error);
        console.error("❌ Hata mesajı:", error.message);
        console.error("❌ Hata stack:", error.stack);
        if (error.message?.includes("API key")) {
            console.error("❌ API Key hatası tespit edildi!");
        }
        throw new https_1.HttpsError("internal", "Koç şu an meşgul, sonra tekrar dene.");
    }
});
//# sourceMappingURL=index.js.map