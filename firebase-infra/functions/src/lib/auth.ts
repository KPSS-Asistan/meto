/**
 * Firebase Auth helper for HTTP onRequest functions.
 *
 * onCall functions get `request.auth` for free; onRequest ones do not.
 * This module extracts the bearer token and verifies it with Firebase Admin.
 */
import type {Request} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export interface AuthContext {
  uid: string;
  email?: string;
  emailVerified: boolean;
  isAnonymous: boolean;
  /**
   * Premium tier bilgisi token custom claim'inden geliyorsa doludur.
   * Null ise rate-limit katmanı Firestore'dan okuyacaktır.
   */
  isPremiumClaim: boolean | null;
}

export class AuthError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string
  ) {
    super(message);
    this.name = "AuthError";
  }
}

/**
 * Verify Firebase ID token from the Authorization header and return a
 * lightweight auth context. Throws {@link AuthError} on any failure so
 * callers can translate it to an HTTP status code.
 *
 * @param req - Firebase v2 onRequest Request object
 * @returns resolved auth context
 */
export async function verifyRequestAuth(req: Request): Promise<AuthContext> {
  const header = req.header("Authorization") ?? req.header("authorization");
  if (!header || !header.startsWith("Bearer ")) {
    throw new AuthError(401, "missing-token", "Authorization header gerekli");
  }

  const idToken = header.substring("Bearer ".length).trim();
  if (idToken.length === 0) {
    throw new AuthError(401, "empty-token", "Boş token kabul edilmez");
  }

  try {
    const decoded = await admin.auth().verifyIdToken(idToken, true);
    const claim = decoded["isPremium"];
    const isPremiumClaim = typeof claim === "boolean" ? claim : null;
    return {
      uid: decoded.uid,
      email: decoded.email,
      emailVerified: decoded.email_verified === true,
      isAnonymous: decoded.firebase?.sign_in_provider === "anonymous",
      isPremiumClaim,
    };
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    throw new AuthError(401, "invalid-token", `Token doğrulanamadı: ${message}`);
  }
}
