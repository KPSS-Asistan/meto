/**
 * Leaderboard snapshot builder.
 *
 * RTDB `/xp_counters` nodundan top-N kullanıcıyı alıp tek bir Firestore
 * dokümanı (`leaderboards/top{N}`) içinde dizi olarak yazar. Bu sayede
 * istemci her leaderboard açılışında **tek** doküman okur.
 *
 * Neden RTDB? Yüksek frekanslı XP yazımları RTDB'ye gidiyor; `public_profiles`
 * artık güncellenmediğinden kaynak RTDB olmalı.
 *
 * Stratejiler:
 *   - `rebuildLeaderboardScheduled` — 15 dakikada bir otomatik yeniden
 *     hesaplama. Admin SDK kullanır, istemciden read maliyeti 0.
 *   - `rebuildLeaderboardNow` — manuel tetikleme için admin callable
 *     (sadece admin rolündeki kullanıcı çalıştırabilir). İlk deploy
 *     sonrası backfill veya acil güncelleme senaryoları içindir.
 */
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const topN = 50;
const docId = `top${topN}`;

/** RTDB `/xp_counters/{uid}` node şeması. */
interface RtdbCounter {
  xp?: number;
  monthlyXp?: number;
  monthlyXpMonth?: string;
  displayName?: string;
  avatarId?: string;
  leagueTier?: string;
  rankTier?: string;
  updatedAt?: number;
}

interface LeaderboardEntryDoc {
  uid: string;
  displayName: string;
  avatarId: string;
  xp: number;
  monthlyXp: number;
  leagueTier: string;
  rankTier: string;
  isPremium: boolean;
}

/** Mevcut ay etiketini döner — "2026-04" formatında. */
function currentMonthLabel(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

async function buildSnapshot(): Promise<LeaderboardEntryDoc[]> {
  // RTDB sadece top-N sonucu indirsin. `database.rules.json`'da
  // `xp_counters/.indexOn: ["monthlyXp"]` tanımlı — sunucu indeks kullanıp
  // bize yalnızca en yüksek `topN * 2` kaydı döndürür. Bu sayede 10K
  // kullanıcılık bir veri setinde bile transfer ~22 KB ile sınırlı kalır.
  //
  // `limitToLast` yüksekten düşüğe değil, en yüksek N'yi verir (ascending
  // sort sonrasında son N). Client tarafında descending'e çeviriyoruz.
  //
  // Buffer (topN * 2): monthly reset başarısız geçmiş bir kullanıcı kalırsa
  // filtrelendikten sonra en az topN kadar girdi bulabilmek için.
  const buffer = topN * 2;
  const snap = await admin
    .database()
    .ref("xp_counters")
    .orderByChild("monthlyXp")
    .limitToLast(buffer)
    .get();

  if (!snap.exists()) return [];

  const raw = snap.val() as Record<string, RtdbCounter>;
  const month = currentMonthLabel();

  return Object.entries(raw)
    .filter(([, v]) => {
      const mXp = typeof v.monthlyXp === "number" ? v.monthlyXp : 0;
      return mXp > 0 && (v.monthlyXpMonth ?? "") === month;
    })
    .sort(([, a], [, b]) => (b.monthlyXp ?? 0) - (a.monthlyXp ?? 0))
    .slice(0, topN)
    .map(([uid, v]) => ({
      uid,
      displayName: (v.displayName ?? "Öğrenci").toString().slice(0, 48),
      avatarId: (v.avatarId ?? "chick").toString().slice(0, 32),
      xp: typeof v.xp === "number" ? v.xp : 0,
      monthlyXp: typeof v.monthlyXp === "number" ? v.monthlyXp : 0,
      leagueTier: (v.leagueTier ?? "iron_4").toString().slice(0, 32),
      rankTier: (v.rankTier ?? "apprentice").toString().slice(0, 32),
      isPremium: false, // RTDB'de isPremium tutulmuyor; leaderboard için gerekli değil
    }));
}

async function writeSnapshot(entries: LeaderboardEntryDoc[]): Promise<void> {
  await admin
    .firestore()
    .collection("leaderboards")
    .doc(docId)
    .set({
      entries,
      count: entries.length,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

/**
 * 15 dakikada bir çalışıp leaderboard snapshot'ı yeniler.
 * Pubsub Scheduler (Cloud Scheduler) API'sinin açık olması gerekir —
 * Blaze projelerde otomatik etkinleşir.
 */
export const rebuildLeaderboardScheduled = onSchedule(
  {
    schedule: "every 15 minutes",
    timeZone: "Europe/Istanbul",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async () => {
    try {
      const entries = await buildSnapshot();
      await writeSnapshot(entries);
      console.log(`Leaderboard snapshot updated: ${entries.length} entries`);
    } catch (err) {
      console.error("Leaderboard snapshot failed:", err);
      throw err;
    }
  }
);

/**
 * Admin callable — snapshot'ı manuel tetikler. Sadece
 * `users/{uid}.role == 'admin'` kullanıcıları çalıştırabilir.
 */
export const rebuildLeaderboardNow = onCall(
  {memory: "256MiB", timeoutSeconds: 60},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Giriş gerekli");
    }

    const uid = request.auth.uid;
    const userSnap = await admin.firestore().collection("users").doc(uid).get();
    const role = (userSnap.data()?.role as string | undefined) ?? "";
    if (role !== "admin") {
      throw new HttpsError("permission-denied", "Admin yetkisi gerekir");
    }

    const entries = await buildSnapshot();
    await writeSnapshot(entries);
    return {ok: true, count: entries.length};
  }
);
