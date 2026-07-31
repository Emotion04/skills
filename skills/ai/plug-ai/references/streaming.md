# Streaming Reference

SSE 解析引擎 —— Agent 内部参考。不需要展示层（打字机效果）时读这个。

## 通用解析器（零依赖）

```js
function createStream(url, body, { onToken, onDone, onError }) {
  const ctrl = new AbortController();
  (async () => {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: ctrl.signal,
    });
    const reader = res.body.getReader();
    const dec = new TextDecoder();
    let full = "", buf = "";
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buf += dec.decode(value, { stream: true });
      const lines = buf.split("\n");
      buf = lines.pop() || "";
      for (const l of lines) {
        if (!l.startsWith("data: ") || l.slice(6) === "[DONE]") continue;
        try {
          const t = JSON.parse(l.slice(6)).choices?.[0]?.delta?.content || "";
          if (t) { full += t; onToken(t); }
        } catch {}
      }
    }
    onDone(full);
  })().catch(e => { if (!ctrl.signal.aborted) onError(e); });
  return () => ctrl.abort();
}
```

**关键机制：**
- `TextDecoder({ stream: true })` — 跨 chunk 正确处理 UTF-8 多字节
- `buf = lines.pop()` — 半行留在 buffer 等下一块
- 返回 `abort()` 用于取消

## React Hook

```tsx
import { useState, useCallback, useRef } from "react";

export function useStreamChat() {
  const [text, setText] = useState("");
  const [streaming, setStreaming] = useState(false);
  const abortRef = useRef<AbortController | null>(null);

  const stream = useCallback(async (url: string, body: unknown) => {
    const ctrl = new AbortController();
    abortRef.current = ctrl;
    setText(""); setStreaming(true);
    try {
      const res = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body), signal: ctrl.signal });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const reader = res.body!.getReader();
      const dec = new TextDecoder();
      let full = "", buf = "";
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buf += dec.decode(value, { stream: true });
        const lines = buf.split("\n"); buf = lines.pop() || "";
        for (const l of lines) {
          if (!l.startsWith("data: ") || l.slice(6) === "[DONE]") continue;
          try { const t = JSON.parse(l.slice(6)).choices?.[0]?.delta?.content || ""; if (t) { full += t; setText(p => p + t); } } catch {}
        }
      }
    } catch (e) { if (!ctrl.signal.aborted) console.error(e); }
    finally { setStreaming(false); }
  }, []);
  const abort = () => abortRef.current?.abort();
  return { text, streaming, stream, abort };
}
```

## 服务端：SSE 转发

```ts
// Next.js App Router
export async function POST(req: Request) {
  const body = await req.json();
  const upstream = await fetch("https://api.deepseek.com/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json", "Authorization": `Bearer ${process.env.API_KEY}` },
    body: JSON.stringify({ ...body, stream: true }),
  });
  return new Response(upstream.body, { headers: { "Content-Type": "text/event-stream", "Cache-Control": "no-cache" } });
}
```

Python / Go / Express 等其他后端框架：按同样的 `setContentType("text/event-stream")` + `pipe reader to response` 逻辑重写即可。

## 需要打字机动画效果？

装 `streaming-typing-effect` skill：
```bash
npx skills add yuhan-skill/plug-ai --skill streaming-typing-effect
```
