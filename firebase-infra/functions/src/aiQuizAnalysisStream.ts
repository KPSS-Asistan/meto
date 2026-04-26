/**
 * Quiz analysis endpoint (SSE streaming). Reuses the same rate-limit /
 * cost-cap pipeline as {@link aiChatStream} but under the `analysis` bucket.
 */
import {onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {verifyRequestAuth, AuthError} from "./lib/auth";
import {
  reserveRequest,
  finalizeUsage,
  RateLimitError,
  estimateTokens,
} from "./lib/rateLimit";
import {streamChat, UpstreamError, ChatMessage} from "./lib/openRouter";
import {openSseStream, writeEvent, closeSseStream} from "./lib/sse";

const openRouterApiKey = defineSecret("OPENROUTER_API_KEY");

const models = [
  "google/gemini-2.5-flash-lite",
  "google/gemini-3.1-flash-lite-preview",
  "x-ai/grok-4.1-fast",
  "deepseek/deepseek-v3.2",
];

const systemPrompt = `GÖREV: KPSS Test Analizi.
KURALLAR:
1. Asla ** kullanma, düz metin yaz.
2. 4 madde halinde (Durum:, Odak:, Öneri:, Motivasyon:) yaz.
3. Her madde kısa ve net.`;

interface AnalysisRequestBody {
  prompt?: string;
}

export const aiQuizAnalysisStream = onRequest(
  {
    secrets: [openRouterApiKey],
    cors: true,
    concurrency: 20,
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (req, res): Promise<void> => {
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).json({error: "method-not-allowed"});
      return;
    }

    let auth;
    try {
      auth = await verifyRequestAuth(req);
    } catch (err) {
      if (err instanceof AuthError) {
        res.status(err.status).json({error: err.code, message: err.message});
        return;
      }
      throw err;
    }

    const body = (req.body ?? {}) as AnalysisRequestBody;
    const prompt = (body.prompt ?? "").toString().trim();
    if (prompt.length === 0 || prompt.length > 4000) {
      res
        .status(400)
        .json({error: "invalid-prompt", message: "Prompt 1-4000 karakter olmalı"});
      return;
    }

    let handle;
    try {
      handle = await reserveRequest(auth.uid, "analysis", auth.isPremiumClaim);
    } catch (err) {
      if (err instanceof RateLimitError) {
        if (typeof err.retryAfterSeconds === "number") {
          res.setHeader("Retry-After", err.retryAfterSeconds.toString());
        }
        res.status(err.status).json({error: err.code, message: err.message});
        return;
      }
      throw err;
    }

    const apiKey = openRouterApiKey.value();
    if (!apiKey) {
      console.error("OPENROUTER_API_KEY secret not configured");
      res.status(500).json({error: "server-misconfigured"});
      return;
    }

    const messages: ChatMessage[] = [
      {role: "system", content: systemPrompt},
      {role: "user", content: prompt},
    ];
    const promptTokens = messages.reduce(
      (sum, m) => sum + estimateTokens(m.content),
      0
    );

    const abort = new AbortController();
    req.on("close", () => abort.abort());

    openSseStream(res);
    let completionText = "";

    try {
      for await (const chunk of streamChat({
        apiKey,
        models,
        messages,
        maxTokens: handle.tier.perRequestMaxTokens,
        temperature: 0.4,
        signal: abort.signal,
      })) {
        const clean = chunk.delta.replace(/\*\*/g, "").replace(/\*/g, "");
        completionText += clean;
        writeEvent(res, "chunk", {text: clean});
      }
      writeEvent(res, "done", {ok: true});
    } catch (err) {
      const status = err instanceof UpstreamError ? err.status : 500;
      const message = err instanceof Error ? err.message : String(err);
      console.error("aiQuizAnalysisStream upstream error:", message);
      writeEvent(res, "error", {code: "upstream", status, message});
    } finally {
      closeSseStream(res);
      await finalizeUsage(
        handle,
        estimateTokens(completionText),
        promptTokens
      );
    }
  }
);
