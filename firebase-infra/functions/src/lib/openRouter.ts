/**
 * Thin OpenRouter client with model fallback + SSE passthrough.
 *
 * We stream raw delta text chunks back through an async generator so the
 * HTTP endpoint can forward them over a server-sent-events connection
 * without buffering the whole response.
 */

export interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

export interface OpenRouterOptions {
  apiKey: string;
  models: string[];
  messages: ChatMessage[];
  maxTokens: number;
  temperature?: number;
  /** Aborts the upstream request when the client disconnects. */
  signal?: AbortSignal;
}

export interface StreamChunk {
  delta: string;
}

export class UpstreamError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = "UpstreamError";
  }
}

const endpoint = "https://openrouter.ai/api/v1/chat/completions";

/**
 * Calls OpenRouter with fallback across the supplied model list.
 * Yields {@link StreamChunk} objects until the upstream signals done.
 */
export async function* streamChat(
  opts: OpenRouterOptions
): AsyncGenerator<StreamChunk, void, void> {
  let lastError: unknown = null;

  for (const model of opts.models) {
    try {
      yield* callModel(model, opts);
      return;
    } catch (err) {
      lastError = err;
      console.warn(`OpenRouter model failed (${model}):`, err);
      if (opts.signal?.aborted) {
        throw new UpstreamError(499, "Client aborted");
      }
    }
  }

  const message =
    lastError instanceof Error ? lastError.message : String(lastError);
  throw new UpstreamError(502, `Tüm modeller başarısız: ${message}`);
}

async function* callModel(
  model: string,
  opts: OpenRouterOptions
): AsyncGenerator<StreamChunk, void, void> {
  const response = await fetch(endpoint, {
    method: "POST",
    signal: opts.signal,
    headers: {
      "Authorization": `Bearer ${opts.apiKey}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://kpssasistan.app",
      "X-Title": "KPSS KOC (Cloud Function Proxy)",
    },
    body: JSON.stringify({
      model,
      messages: opts.messages,
      stream: true,
      temperature: opts.temperature ?? 0.7,
      max_tokens: opts.maxTokens,
    }),
  });

  if (!response.ok || !response.body) {
    const detail = await safeReadError(response);
    throw new UpstreamError(
      response.status,
      `OpenRouter ${response.status}: ${detail}`
    );
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder("utf-8");
  let buffer = "";

  try {
    while (true) {
      const {value, done} = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, {stream: true});

      // SSE frames end with \n\n. Process complete frames only.
      let frameEnd = buffer.indexOf("\n\n");
      while (frameEnd !== -1) {
        const frame = buffer.slice(0, frameEnd);
        buffer = buffer.slice(frameEnd + 2);
        const chunk = parseFrame(frame);
        if (chunk === "[DONE]") {
          return;
        }
        if (chunk !== null && chunk.length > 0) {
          yield {delta: chunk};
        }
        frameEnd = buffer.indexOf("\n\n");
      }
    }
  } finally {
    try {
      reader.releaseLock();
    } catch {
      /* ignore */
    }
  }
}

function parseFrame(frame: string): string | "[DONE]" | null {
  const lines = frame.split(/\r?\n/);
  let payload = "";
  for (const line of lines) {
    if (line.startsWith("data: ")) {
      payload = line.slice(6).trim();
    }
  }
  if (!payload) return null;
  if (payload === "[DONE]") return "[DONE]";

  try {
    const obj = JSON.parse(payload) as {
      choices?: Array<{delta?: {content?: string}}>;
    };
    const delta = obj.choices?.[0]?.delta?.content;
    return typeof delta === "string" ? delta : null;
  } catch {
    return null;
  }
}

async function safeReadError(response: Response): Promise<string> {
  try {
    const text = await response.text();
    return text.slice(0, 400);
  } catch {
    return "<no-body>";
  }
}
