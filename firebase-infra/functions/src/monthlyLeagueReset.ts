/**
 * Aylık lig sıfırlama Cloud Function'ı.
 *
 * Her ayın 1'inde 00:05 Europe/Istanbul'da çalışır ve tüm
 * `public_profiles/{uid}` ile `users/{uid}` dokümanlarındaki `monthlyXp`
 * değerlerini sıfırlar. Kullanıcıların kariyer/lifetime `xp` alanına
 * dokunmaz — sadece ayın lig sıralaması sıfırlanır.
 *
 * Sıfırlama sonrası leaderboard snapshot da yeniden oluşturulur ki
 * istemciler eski ayın tablosunu görmesin.
 *
 * Ayrıca admin-only bir callable (`resetMonthlyLeagueNow`) test / acil
 * durum senaryoları için sağlanır.
 */
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const BATCH_SIZE = 400; // Firestore limit 500 — güvenli marj.

async function resetCollection(collection: string): Promise<number> {
  const db = admin.firestore();
  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  let total = 0;

  // Sayfa sayfa ilerle, her sayfayı tek batch commit ile sıfırla.
  // eslint-disable-next-line no-constant-condition
  while (true) {
    let q: FirebaseFirestore.Query = db
      .collection(collection)
      .where("monthlyXp", ">", 0)
      .orderBy("monthlyXp", "desc")
      .limit(BATCH_SIZE);
    if (lastDoc) q = q.startAfter(lastDoc);

    const snap = await q.get();
    if (snap.empty) break;

    const batch = db.batch();
    const resetAt = admin.firestore.Timestamp.now();
    for (const doc of snap.docs) {
      batch.set(
        doc.ref,
        {
          monthlyXp: 0,
          leagueTier: "iron_4",
          monthlyXpResetAt: resetAt,
        },
        {merge: true}
      );
    }
    await batch.commit();

    total += snap.size;
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < BATCH_SIZE) break;
  }

  return total;
}

async function rebuildEmptySnapshot(): Promise<void> {
  // Reset sonrası hiç kimsenin monthlyXp'si > 0 olmayacağından snapshot
  // boş olur — sadece dizi ve metadata yazıyoruz ki istemciler eski
  // verileri görmesin.
  await admin.firestore().collection("leaderboards").doc("top50").set({
    entries: [],
    count: 0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    resetMonth: new Date().toISOString().slice(0, 7),
  });
}

/**
 * RTDB `/xp_counters/{uid}.monthlyXp` ve `leagueTier` sıfırla.
 * Firestore reset ile eş zamanlı çalışır; tek multi-path update ile
 * tüm kullanıcıları O(1) yazımla sıfırlar.
 */
async function resetRtdbCounters(): Promise<number> {
  const db = admin.database();
  const snap = await db.ref("xp_counters").get();
  if (!snap.exists()) return 0;

  const raw = snap.val() as Record<string, {monthlyXp?: number}>;
  const uids = Object.keys(raw).filter((uid) => (raw[uid].monthlyXp ?? 0) > 0);
  if (uids.length === 0) return 0;

  // Tek multi-path update — Firestore batch'in RTDB karşılığı.
  const updates: Record<string, unknown> = {};
  for (const uid of uids) {
    updates[`xp_counters/${uid}/monthlyXp`] = 0;
    updates[`xp_counters/${uid}/leagueTier`] = "iron_4";
  }
  await db.ref().update(updates);
  return uids.length;
}

/**
 * Her ayın 1'inde 00:05 Europe/Istanbul — aylık lig sıfırlama.
 */
export const resetMonthlyLeague = onSchedule(
  {
    schedule: "5 0 1 * *", // dakika saat gün ay haftagünü
    timeZone: "Europe/Istanbul",
    memory: "512MiB",
    timeoutSeconds: 540,
  },
  async () => {
    try {
      // Firestore public_profiles + users sıfırla (geriye dönük uyumluluk).
      const publicReset = await resetCollection("public_profiles");
      const usersReset = await resetCollection("users");
      // RTDB xp_counters sıfırla (yeni mimari — asıl kayıt burası).
      const rtdbReset = await resetRtdbCounters();
      await rebuildEmptySnapshot();
      console.log(
        `Monthly league reset OK — public_profiles: ${publicReset}, ` +
          `users: ${usersReset}, rtdb: ${rtdbReset}`
      );
    } catch (err) {
      console.error("Monthly league reset failed:", err);
      throw err;
    }
  }
);

/**
 * Admin callable — sıfırlamayı manuel tetikler. Sadece
 * `users/{uid}.role == 'admin'` kullanıcıları çalıştırabilir.
 */
export const resetMonthlyLeagueNow = onCall(
  {memory: "512MiB", timeoutSeconds: 540},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Giriş gerekli");
    }
    const uid = request.auth.uid;
    const userSnap = await admin
      .firestore()
      .collection("users")
      .doc(uid)
      .get();
    const role = (userSnap.data()?.role as string | undefined) ?? "";
    if (role !== "admin") {
      throw new HttpsError("permission-denied", "Admin yetkisi gerekir");
    }

    const publicReset = await resetCollection("public_profiles");
    const usersReset = await resetCollection("users");
    const rtdbReset = await resetRtdbCounters();
    await rebuildEmptySnapshot();
    return {
      ok: true,
      publicProfilesReset: publicReset,
      usersReset: usersReset,
      rtdbReset: rtdbReset,
    };
  }
);
