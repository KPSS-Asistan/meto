/**
 * Minimal server-sent-events helper for Firebase onRequest handlers.
 */
import type {Response} from "express";

export function openSseStream(res: Response): void {
  res.status(200);
  res.setHeader("Content-Type", "text/event-stream; charset=utf-8");
  res.setHeader("Cache-Control", "no-cache, no-transform");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("X-Accel-Buffering", "no");
  // Flush headers immediately so clients start receiving.
  res.flushHeaders?.();
}

export function writeEvent(
  res: Response,
  event: "chunk" | "done" | "error",
  data: unknown
): void {
  if (res.writableEnded) return;
  const payload = typeof data === "string" ? data : JSON.stringify(data);
  res.write(`event: ${event}\n`);
  res.write(`data: ${payload}\n\n`);
}

export function closeSseStream(res: Response): void {
  if (res.writableEnded) return;
  try {
    res.end();
  } catch {
    /* ignore */
  }
}
