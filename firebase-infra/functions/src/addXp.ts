/**
 * addXpCallable — Güvenli XP kazanım callable Cloud Function.
 *
 * Neden bu yaklaşım?
 *   İstemci (Flutter) uygulaması RTDB'ye doğrudan XP yazarsa, kodu
 *   manipüle eden veya araya giren bir saldırgan kendi uid'si üzerinden
 *   istediği XP değerini yazabilir. Bu fonksiyon sunucu tarafında:
 *     1. Kaynağa (source) göre tek çağrıda eklenebilecek maksimum XP'yi sınırlar.
 *     2. Ardışık çağrı hızını sınırlar (rate-limit: min 800 ms).
 *     3. XP'nin sadece artmasına izin verir (geri alınamaz).
 *     4. Tüm tier hesaplamalarını sunucu tarafında yapar.
 *   İstemci RTDB `xp_counters/{uid}` noduna yazma yetkisine artık sahip değil.
 */
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// ── Kaynak başına tek çağrıda eklenebilecek maksimum XP ───────────────────
// Hesaplama: quiz için 30 soru × 10 + 50 tamamlama + 100 mükemmel = 450 → 500
const MAX_XP_PER_SOURCE: Record<string, number> = {
  quiz: 500,
  quiz_timeup: 500,
  story: 10,
  matching: 40,
  flashcard: 30,
  daily_streak: 600, // 30 gün × 20 = 600
  topic_complete: 100,
  glossary: 50,
  general: 100,
};

// Minimum ms iki ardışık XP çağrısı arasında (tüm kaynaklar için ortak)
const MIN_INTERVAL_MS = 800;

// ── Rank kademeleri (XpConfig ile eşleşmeli) ─────────────────────────────
const RANK_TIERS = [
  {id: "apprentice", minXp: 0},
  {id: "student", minXp: 500},
  {id: "determined", minXp: 2000},
  {id: "master", minXp: 5000},
  {id: "champion", minXp: 15000},
];

// ── Aylık lig kademeleri (LeagueTier.all ile eşleşmeli) ──────────────────
const LEAGUE_TIERS = [
  {id: "iron_4", minXP: 0},
  {id: "iron_3", minXP: 50},
  {id: "iron_2", minXP: 120},
  {id: "iron_1", minXP: 220},
  {id: "bronze_4", minXP: 350},
  {id: "bronze_3", minXP: 520},
  {id: "bronze_2", minXP: 730},
  {id: "bronze_1", minXP: 1000},
  {id: "silver_4", minXP: 1350},
  {id: "silver_3", minXP: 1750},
  {id: "silver_2", minXP: 2200},
  {id: "silver_1", minXP: 2700},
  {id: "gold_4", minXP: 3250},
  {id: "gold_3", minXP: 3850},
  {id: "gold_2", minXP: 4500},
  {id: "gold_1", minXP: 5200},
  {id: "platinum_4", minXP: 5950},
  {id: "platinum_3", minXP: 6750},
  {id: "platinum_2", minXP: 7600},
  {id: "platinum_1", minXP: 8500},
  {id: "emerald_4", minXP: 9500},
  {id: "emerald_3", minXP: 10600},
  {id: "emerald_2", minXP: 11800},
  {id: "emerald_1", minXP: 13100},
  {id: "diamond_4", minXP: 14500},
  {id: "diamond_3", minXP: 16000},
  {id: "diamond_2", minXP: 17600},
  {id: "diamond_1", minXP: 19500},
];

function rankTierForXp(xp: number): string {
  for (let i = RANK_TIERS.length - 1; i >= 0; i--) {
    if (xp >= RANK_TIERS[i].minXp) return RANK_TIERS[i].id;
  }
  return "apprentice";
}

function leagueTierForMonthlyXp(xp: number): string {
  for (let i = LEAGUE_TIERS.length - 1; i >= 0; i--) {
    if (xp >= LEAGUE_TIERS[i].minXP) return LEAGUE_TIERS[i].id;
  }
  return "iron_4";
}

function currentMonthLabel(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

interface AddXpRequest {
  amount: number;
  source: string;
  displayName?: string;
  avatarId?: string;
}

interface AddXpResponse {
  ok: boolean;
  xp: number;
  monthlyXp: number;
  leagueTier: string;
  rankTier: string;
}

/**
 * Güvenli XP ekleme. İstemci yalnızca bu callable'ı çağırır;
 * RTDB'ye doğrudan yazma yetkisi yoktur.
 */
export const addXpCallable = onCall<AddXpRequest, Promise<AddXpResponse>>(
  {memory: "256MiB", timeoutSeconds: 30},
  async (request): Promise<AddXpResponse> => {
    // ── 1. Kimlik doğrulama ────────────────────────────────────────────
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Giriş gerekli");
    }
    const uid = request.auth.uid;

    // ── 2. Girdi doğrulama ────────────────────────────────────────────
    const {amount, source, displayName, avatarId} = request.data;

    if (typeof amount !== "number" || !Number.isInteger(amount) || amount <= 0) {
      throw new HttpsError("invalid-argument", "amount pozitif tam sayı olmalı");
    }

    const knownSource = Object.keys(MAX_XP_PER_SOURCE).includes(source)
      ? source
      : "general";
    const maxAllowed = MAX_XP_PER_SOURCE[knownSource];

    if (amount > maxAllowed) {
      throw new HttpsError(
        "invalid-argument",
        `'${knownSource}' için tek seferlik maksimum XP ${maxAllowed} (istenen: ${amount})`
      );
    }

    // ── 3 + 4. Atomic RTDB transaction — rate-limit kontrolü transaction içinde ──
    // Neden transaction içinde? Ayrı bir read ile sonra transaction yapmak race
    // condition'a yol açar: eş zamanlı 2 istek her ikisi de kontrolü geçebilir.
    // Transaction callback RTDB'de serileştirilir, dolayısıyla rate-limit atomik
    // olur ve fazladan 1 okuma maliyeti ortadan kalkar.
    const db = admin.database();
    const ref = db.ref(`xp_counters/${uid}`);
    const currentMonth = currentMonthLabel();

    let rateLimited = false;

    const txResult = await ref.transaction((current) => {
      const data: Record<string, unknown> =
        current != null && typeof current === "object"
          ? {...(current as Record<string, unknown>)}
          : {};

      // Rate-limit: son güncelleme 800ms'den daha az önce mi?
      const lastAt = (data["updatedAt"] as number | null) ?? 0;
      const now = Date.now();
      if (now - lastAt < MIN_INTERVAL_MS) {
        rateLimited = true;
        return; // undefined döndürmek transaction'ı abort eder
      }

      const storedMonth = data["monthlyXpMonth"] as string | undefined;
      const prevMonthlyXp =
        storedMonth === currentMonth
          ? ((data["monthlyXp"] as number | null) ?? 0)
          : 0;

      const newXp = ((data["xp"] as number | null) ?? 0) + amount;
      const newMonthlyXp = prevMonthlyXp + amount;

      data["xp"] = newXp;
      data["monthlyXp"] = newMonthlyXp;
      data["monthlyXpMonth"] = currentMonth;
      data["leagueTier"] = leagueTierForMonthlyXp(newMonthlyXp);
      data["rankTier"] = rankTierForXp(newXp);
      data["updatedAt"] = now;

      if (typeof displayName === "string" && displayName.trim().length > 0) {
        data["displayName"] = displayName.trim().slice(0, 48);
      }
      if (typeof avatarId === "string" && avatarId.trim().length > 0) {
        data["avatarId"] = avatarId.trim().slice(0, 32);
      }

      return data;
    });

    if (!txResult.committed) {
      if (rateLimited) {
        throw new HttpsError(
          "resource-exhausted",
          "Çok sık XP isteği. Lütfen bekleyin."
        );
      }
      throw new HttpsError("internal", "RTDB transaction commit edilemedi");
    }
    if (txResult.snapshot.val() == null) {
      throw new HttpsError("internal", "RTDB snapshot boş döndü");
    }

    const committed = txResult.snapshot.val() as Record<string, unknown>;

    console.log(
      `addXp OK uid=${uid} source=${source} amount=${amount} ` +
        `xp=${committed["xp"]} monthly=${committed["monthlyXp"]}`
    );

    return {
      ok: true,
      xp: (committed["xp"] as number) ?? 0,
      monthlyXp: (committed["monthlyXp"] as number) ?? 0,
      leagueTier: (committed["leagueTier"] as string) ?? "iron_4",
      rankTier: (committed["rankTier"] as string) ?? "apprentice",
    };
  }
);
