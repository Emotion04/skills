---
name: streaming-typing-effect
description: Typewriter-style character-by-character rendering for AI streaming (SSE) output. Covers multi-panel concurrent streaming, auto-scroll, and pulse-dot loading indicators. Use when user wants a typewriter effect or SSE token-by-token display. Pair with plug-ai for the SSE parser.
---

# Streaming Typing Effect

Turn SSE/streaming AI output into a typewriter effect — characters appear one at a time with auto-scroll and loading indicators.

> **Pairs with plug-ai** (provides the SSE parser). Install both for the full pipeline.

## Architecture

```
AI Response ──SSE──► Parser (plug-ai) ──onToken──► UI Render
                                                      │
                                         typewriter + animation + scroll
```

## Three Layers

### 1. State Management

```tsx
const [text, setText] = useState("");
const [streaming, setStreaming] = useState(false);
const abortRef = useRef<AbortController | null>(null);

const start = () => {
  setText(""); setStreaming(true);
  abortRef.current = createStream("/api/chat", { prompt },
    { onToken: t => setText(p => p + t),
      onDone: () => setStreaming(false),
      onError: () => setStreaming(false) }
  );
};
const stop = () => abortRef.current?.abort();
```

### 2. Render States

| State | Opacity | Indicator |
|-------|---------|-----------|
| Streaming | `opacity: 0.25` | Pulsing dot (blue, 8px) |
| Complete | `opacity: 1` | None |
| Auto-scroll | `scrollIntoView({behavior:"smooth"})` | Scroll anchor div |

```tsx
<div style={{ maxHeight: 256, overflow: "auto" }}>
  {streaming && <span className="pulse-dot" />}
  <pre style={{ opacity: streaming ? 0.25 : 1, whiteSpace: "pre-wrap" }}>
    {text}
  </pre>
  <div ref={bottomRef} />
</div>
```

**Monospace font is mandatory.** Non-monospace causes horizontal layout jitter as characters appear.

### 3. Multi-Panel Concurrent Streaming

Each `fetch` is an independent TCP connection. Fire N requests simultaneously — no WebSocket or Worker needed:

```tsx
items.forEach((item, i) => {
  createStream("/api/chat", { prompt: item.prompt }, {
    onToken: t => setPanels(p => p.map((p, j) => j === i ? {...p, text: p.text + t} : p)),
    onDone:  () => setPanels(p => p.map((p, j) => j === i ? {...p, streaming: false} : p)),
  });
});
```

## Pulsing Dot CSS

```css
@keyframes pulse-dot {
  0%, 100% { opacity: 0.3; }
  50% { opacity: 0.8; }
}
.pulse-dot {
  display: inline-block; width: 8px; height: 8px;
  border-radius: 50%; background: #3b82f6;
  animation: pulse-dot 1.2s ease-in-out infinite;
}
```

## Framework Implementations

See [streaming-parser.md](references/streaming-parser.md) for complete code in React, Vue 3, and Vanilla JS.
