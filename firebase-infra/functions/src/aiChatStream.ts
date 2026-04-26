/**
 * AI Coach chat endpoint (SSE streaming).
 *
 * Flow:
 *   1. Verify Firebase ID token.
 *   2. Validate payload.
 *   3. Reserve a slot (burst + daily caps, premium aware).
 *   4. Stream OpenRouter response back over SSE, accumulating completion
 *      tokens for accounting.
 *   5. Finalize usage counters regardless of outcome.
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

const systemPrompt = `Sen "KPSS KOÇ" uygulamasının KIDEMLİ EĞİTİM KOÇU ve STRATEJİ UZMANISIN.
Adın: AI Koç.

KİMLİĞİN:
1. Analizci ol: Öğrencinin sorusunun altındaki asıl ihtiyacı tespit et.
2. Yol gösterici ol: Doğrudan cevap yerine yöntem ve taktik ver.
3. Otoriter ama samimi: Disiplinli bir abi/abla tonunda konuş.

YAPI: Empatik giriş → strateji/bilgi → net bir eylem çağrısı.

KURALLAR:
1. Markdown (**, *, #) kesinlikle yasak.
2. Sade, akıcı metin; gerekirse sadece rakamlı madde.
3. Lafı dolandırma, detay ver.`;

interface ChatRequestBody {
  question?: string;
  chatHistory?: Array<{role?: string; content?: string}>;
  contextQuestion?: {
    lessonId?: string;
    topicId?: string;
    subtopicName?: string | null;
    questionText?: string;
    options?: Record<string, string>;
    correctAnswer?: string;
  };
  userContext?: string;
}

export const aiChatStream = onRequest(
  {
    secrets: [openRouterApiKey],
    cors: true,
    concurrency: 40,
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

    const body = (req.body ?? {}) as ChatRequestBody;
    const question = (body.question ?? "").toString().trim();
    if (question.length === 0 || question.length > 2000) {
      res
        .status(400)
        .json({error: "invalid-question", message: "Soru 1-2000 karakter olmalı"});
      return;
    }

    const historyRaw = Array.isArray(body.chatHistory) ? body.chatHistory : [];
    const history: ChatMessage[] = historyRaw
      .slice(-10)
      .map((m) => {
        const role = m.role === "user" ? "user" : "assistant";
        const content = (m.content ?? "").toString().slice(0, 2000);
        return {role, content} as ChatMessage;
      })
      .filter((m) => m.content.length > 0);

    let handle;
    try {
      handle = await reserveRequest(auth.uid, "chat", auth.isPremiumClaim);
    } catch (err) {
      if (err instanceof RateLimitError) {
        if (typeof err.retryAfterSeconds === "number") {
          res.setHeader("Retry-After", err.retryAfterSeconds.toString());
        }
        res
          .status(err.status)
          .json({error: err.code, message: err.message});
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

    const userMessage = buildUserMessage(question, body);
    const messages: ChatMessage[] = [
      {role: "system", content: buildSystemPrompt(body.userContext)},
      ...history,
      {role: "user", content: userMessage},
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
        temperature: 0.8,
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
      console.error("aiChatStream upstream error:", message);
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

function buildSystemPrompt(userContext?: string): string {
  const safeContext =
    typeof userContext === "string" && userContext.length > 0
      ? userContext.slice(0, 3000)
      : "Öğrenci profili oluşuyor...";
  return `${systemPrompt}\n\nBAĞLAM:\n${safeContext}`;
}

function buildUserMessage(
  question: string,
  body: ChatRequestBody
): string {
  const ctx = body.contextQuestion;
  if (!ctx || !ctx.questionText) return question;

  const options = ctx.options ?? {};
  const shortOptions = Object.entries(options)
    .slice(0, 5)
    .map(([k, v]) => `${k}) ${String(v).slice(0, 200)}`)
    .join("\n");

  return [
    "[EKRANDAKİ SORU BAĞLAMI]",
    `Soru: ${String(ctx.questionText).slice(0, 1200)}`,
    shortOptions ? `Şıklar:\n${shortOptions}` : "",
    ctx.correctAnswer ? `Doğru cevap: ${ctx.correctAnswer} (direkt söyleme, yönlendir)` : "",
    "---",
    `Öğrenci sorusu: ${question}`,
  ]
    .filter(Boolean)
    .join("\n");
}
