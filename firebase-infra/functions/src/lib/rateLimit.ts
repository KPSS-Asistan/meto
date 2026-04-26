/**
 * Centralised rate-limit and cost-cap logic for AI endpoints.
 *
 * Two independent limits are enforced against Firestore:
 *   - Burst: rolling 60s window with a small request cap (DoS shield).
 *   - Daily: per-endpoint request count + completion-token budget.
 *
 * Premium status is read from `users/{uid}.isPremium` (set by the
 * RevenueCat webhook).
 */
import * as admin from "firebase-admin";

export type AiEndpoint = "chat" | "analysis";

export interface UsageTier {
  /** Max requests in the rolling `burstWindowSeconds` window. */
  burstLimit: number;
  /** Max daily requests for this endpoint. */
  dailyRequestLimit: number;
  /** Daily output-token budget shared across endpoints. */
  dailyTokenLimit: number;
  /** Soft ceiling applied to `max_tokens` for each request. */
  perRequestMaxTokens: number;
}

export const burstWindowSeconds = 60;

const freeTier: Record<AiEndpoint, UsageTier> = {
  chat: {
    burstLimit: 5,
    dailyRequestLimit: 10,
    dailyTokenLimit: 20_000,
    perRequestMaxTokens: 1500,
  },
  analysis: {
    burstLimit: 2,
    dailyRequestLimit: 3,
    dailyTokenLimit: 20_000,
    perRequestMaxTokens: 800,
  },
};

const premiumTier: Record<AiEndpoint, UsageTier> = {
  chat: {
    burstLimit: 20,
    dailyRequestLimit: 200,
    dailyTokenLimit: 500_000,
    perRequestMaxTokens: 2500,
  },
  analysis: {
    burstLimit: 10,
    dailyRequestLimit: 30,
    dailyTokenLimit: 500_000,
    perRequestMaxTokens: 1500,
  },
};

export function getTier(isPremium: boolean, endpoint: AiEndpoint): UsageTier {
  return (isPremium ? premiumTier : freeTier)[endpoint];
}

/**
 * In-memory premium cache. Cloud Function instance yaşadığı sürece
 * (tipik 15 dk) aynı uid için tekrar Firestore okunmaz. Soğuk başlangıç
 * sonrası ilk istek Firestore'a düşer; sonraki isteklerde 0 read.
 */
const premiumCache = new Map<string, {value: boolean; expiresAt: number}>();
const premiumCacheTtlMs = 5 * 60 * 1000; // 5 dk

/**
 * Premium durumunu sırasıyla şu kaynaklardan çözer:
 *   1. Token custom claim (0 read) — en hızlı ve güncel yol.
 *   2. In-memory cache (0 read) — aynı instance'da tekrarlayan çağrılar.
 *   3. Firestore `users/{uid}.isPremium` (1 read) — son çare.
 *
 * Claim null ise webhook henüz set etmemiş olabilir; bu durumda
 * Firestore sonucunu cache'leyerek sonraki isteklerde 0 read'e ineriz.
 */
export async function resolvePremium(
  uid: string,
  isPremiumClaim: boolean | null
): Promise<boolean> {
  if (isPremiumClaim !== null) return isPremiumClaim;

  const cached = premiumCache.get(uid);
  const now = Date.now();
  if (cached && cached.expiresAt > now) {
    return cached.value;
  }

  let value = false;
  try {
    const snap = await admin.firestore().collection("users").doc(uid).get();
    const data = snap.data() ?? {};
    value = data.isPremium === true || data.is_premium === true;
  } catch (err) {
    console.warn("resolvePremium Firestore read failed:", err);
  }

  premiumCache.set(uid, {value, expiresAt: now + premiumCacheTtlMs});
  return value;
}

/** UTC date key used for daily counters: `YYYY-MM-DD`. */
export function todayKey(now: Date = new Date()): string {
  const y = now.getUTCFullYear();
  const m = String(now.getUTCMonth() + 1).padStart(2, "0");
  const d = String(now.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export class RateLimitError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public retryAfterSeconds?: number
  ) {
    super(message);
    this.name = "RateLimitError";
  }
}

export interface ReservationHandle {
  uid: string;
  endpoint: AiEndpoint;
  dateKey: string;
  tier: UsageTier;
  isPremium: boolean;
}

/**
 * Atomically verifies burst + daily request caps and reserves a request
 * slot. Throws {@link RateLimitError} with a retry hint if any cap is
 * exceeded. The caller is expected to call {@link finalizeUsage} once
 * the request completes so the token-usage counter is updated.
 *
 * @param uid - authenticated user id
 * @param endpoint - chat | analysis bucket
 * @param isPremiumClaim - premium bayrağı ID token claim'inden, bilinmiyorsa null
 */
export async function reserveRequest(
  uid: string,
  endpoint: AiEndpoint,
  isPremiumClaim: boolean | null
): Promise<ReservationHandle> {
  const isPremium = await resolvePremium(uid, isPremiumClaim);
  const tier = getTier(isPremium, endpoint);
  const dateKey = todayKey();

  const db = admin.firestore();
  const ref = db.collection("ai_usage_v2").doc(`${uid}_${dateKey}`);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() ?? {};
    const endpointData = (data[endpoint] ?? {}) as {
      requestCount?: number;
      completionTokens?: number;
      burstWindowStart?: FirebaseFirestore.Timestamp;
      burstCount?: number;
    };

    const now = new Date();
    const requestCount = endpointData.requestCount ?? 0;
    const completionTokens = (data.completionTokens as number | undefined) ?? 0;

    // Daily request cap
    if (requestCount >= tier.dailyRequestLimit) {
      throw new RateLimitError(
        429,
        "daily-request-exhausted",
        `Günlük ${endpoint} limitin doldu (${tier.dailyRequestLimit})`,
        secondsUntilTomorrow()
      );
    }

    // Daily token cap (soft — request is allowed to start, finalize may
    // still exceed by a single response, but this cap blocks the next one).
    if (completionTokens >= tier.dailyTokenLimit) {
      throw new RateLimitError(
        429,
        "daily-tokens-exhausted",
        "Günlük yapay zeka kullanım bütçen doldu",
        secondsUntilTomorrow()
      );
    }

    // Burst limit (rolling 60s window)
    const windowStart = endpointData.burstWindowStart?.toDate();
    const burstCount = endpointData.burstCount ?? 0;
    const withinWindow =
      windowStart !== undefined &&
      now.getTime() - windowStart.getTime() < burstWindowSeconds * 1000;

    if (withinWindow && burstCount >= tier.burstLimit) {
      const wait =
        burstWindowSeconds -
        Math.floor((now.getTime() - windowStart!.getTime()) / 1000);
      throw new RateLimitError(
        429,
        "burst-limit",
        `Çok fazla istek. ${wait} sn sonra tekrar dene`,
        Math.max(1, wait)
      );
    }

    const nextBurstCount = withinWindow ? burstCount + 1 : 1;
    const nextWindowStart = withinWindow ? windowStart! : now;

    tx.set(
      ref,
      {
        uid,
        dateKey,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        [endpoint]: {
          requestCount: requestCount + 1,
          burstWindowStart:
            admin.firestore.Timestamp.fromDate(nextWindowStart),
          burstCount: nextBurstCount,
          lastRequestAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      },
      {merge: true}
    );
  });

  return {uid, endpoint, dateKey, tier, isPremium};
}

/**
 * Updates the daily token counter once the upstream response size is
 * known. Swallows any Firestore error because accounting must not break
 * an otherwise successful user response.
 */
export async function finalizeUsage(
  handle: ReservationHandle,
  completionTokens: number,
  promptTokens: number
): Promise<void> {
  try {
    const db = admin.firestore();
    const ref = db
      .collection("ai_usage_v2")
      .doc(`${handle.uid}_${handle.dateKey}`);
    await ref.set(
      {
        completionTokens: admin.firestore.FieldValue.increment(
          Math.max(0, completionTokens)
        ),
        promptTokens: admin.firestore.FieldValue.increment(
          Math.max(0, promptTokens)
        ),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
  } catch (err) {
    console.warn("finalizeUsage failed (non-fatal):", err);
  }
}

/** Roughly estimates token count for a string. */
export function estimateTokens(text: string): number {
  if (!text) return 0;
  // Mixed TR/EN heuristic: ~4 chars per token
  return Math.ceil(text.length / 4);
}

function secondsUntilTomorrow(now: Date = new Date()): number {
  const tomorrow = new Date(
    Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate() + 1,
      0,
      0,
      0
    )
  );
  return Math.max(1, Math.floor((tomorrow.getTime() - now.getTime()) / 1000));
}
