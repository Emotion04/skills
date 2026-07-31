# Streaming Parser

流式输出的前端实现示例。SSE 解析引擎来自 plug-ai，这里只做展示层。

## 前提

确保已装 plug-ai（提供后端路由 + SSE 解析器）：
```bash
npx skills add yuhan-skill/plug-ai --skill plug-ai
```

## React (TypeScript)

```tsx
import { useState, useCallback, useRef, useEffect } from "react";

// SSE 解析器（来自 plug-ai）
function createStream(url: string, body: unknown, opts: {
  onToken: (t: string) => void;
  onDone?: (full: string) => void;
  onError?: (e: Error) => void;
}) {
  const ctrl = new AbortController();
  (async () => {
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
        try { const t = JSON.parse(l.slice(6)).choices?.[0]?.delta?.content || ""; if (t) { full += t; opts.onToken(t); } } catch {}
      }
    }
    opts.onDone?.(full);
  })().catch(e => { if (!ctrl.signal.aborted) opts.onError?.(e as Error); });
  return () => ctrl.abort();
}

// Hook
export function useStreamChat() {
  const [text, setText] = useState("");
  const [streaming, setStreaming] = useState(false);
  const abortRef = useRef<AbortController | null>(null);

  const stream = useCallback(async (url: string, body: unknown) => {
    const ctrl = new AbortController();
    abortRef.current = ctrl;
    setText(""); setStreaming(true);
    createStream(url, body, {
      onToken: t => setText(p => p + t),
      onDone: () => setStreaming(false),
      onError: () => setStreaming(false),
    });
  }, []);

  const abort = () => abortRef.current?.abort();
  return { text, streaming, stream, abort };
}

// 组件
export function StreamPanel({ apiUrl, body }: { apiUrl: string; body: unknown }) {
  const { text, streaming, stream, abort } = useStreamChat();
  const bottomRef = useRef<HTMLDivElement>(null);
  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: "smooth" }); }, [text]);

  return (
    <div>
      <button onClick={() => stream(apiUrl, body)} disabled={streaming}>
        {streaming ? "生成中..." : "发送"}
      </button>
      {streaming && <button onClick={abort}>停止</button>}
      <div style={{ maxHeight: 256, overflow: "auto" }}>
        <pre style={{ opacity: streaming ? 0.25 : 1, whiteSpace: "pre-wrap" }}>{text}</pre>
        <div ref={bottomRef} />
      </div>
    </div>
  );
}
```

## Vue 3 (Composition API)

```vue
<script setup lang="ts">
import { ref, watch, nextTick } from "vue";
const props = defineProps<{ query: string }>();
const text = ref(""); const streaming = ref(false);
const bottomRef = ref<HTMLElement | null>(null);
let controller: AbortController | null = null;

watch(text, () => nextTick(() => bottomRef.value?.scrollIntoView({ behavior: "smooth" })));

async function start() {
  text.value = ""; streaming.value = true;
  controller = new AbortController();
  const res = await fetch("/api/chat", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ query: props.query }), signal: controller.signal });
  const reader = res.body!.getReader(); const dec = new TextDecoder(); let buf = "";
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buf += dec.decode(value, { stream: true });
    const lines = buf.split("\n"); buf = lines.pop() || "";
    for (const line of lines) {
      if (!line.startsWith("data: ")) continue;
      const data = line.slice(6);
      if (data === "[DONE]") continue;
      try { text.value += JSON.parse(data).choices?.[0]?.delta?.content || ""; } catch {}
    }
  }
  streaming.value = false;
}
function stop() { controller?.abort(); }
</script>

<template>
  <div>
    <button @click="start" :disabled="streaming">{{ streaming ? "生成中..." : "发送" }}</button>
    <button v-if="streaming" @click="stop">停止</button>
    <div style="max-height: 256px; overflow: auto;">
      <pre :style="{ opacity: streaming ? 0.25 : 1, whiteSpace: 'pre-wrap' }">{{ text }}</pre>
      <div ref="bottomRef" />
    </div>
  </div>
</template>
```

## Vanilla JS

```js
function createStreamingPanel(container, apiUrl, body) {
  const wrapper = document.createElement("div");
  wrapper.innerHTML = `
    <button class="start">发送</button>
    <button class="stop" disabled>停止</button>
    <pre class="output"></pre>
  `;
  container.appendChild(wrapper);

  const output = wrapper.querySelector(".output");
  const startBtn = wrapper.querySelector(".start");
  const stopBtn = wrapper.querySelector(".stop");
  let ctrl = null;

  startBtn.onclick = async () => {
    output.textContent = ""; output.style.opacity = "0.3";
    startBtn.disabled = true; stopBtn.disabled = false;
    ctrl = new AbortController();

    try {
      const res = await fetch(apiUrl, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body), signal: ctrl.signal });
      const reader = res.body.getReader(); const dec = new TextDecoder(); let buf = "";
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buf += dec.decode(value, { stream: true });
        const lines = buf.split("\n"); buf = lines.pop() || "";
        for (const line of lines) {
          if (!line.startsWith("data: ")) continue;
          const d = line.slice(6);
          if (d === "[DONE]") continue;
          try { output.textContent += JSON.parse(d).choices?.[0]?.delta?.content || ""; output.scrollTop = output.scrollHeight; } catch {}
        }
      }
    } catch (e) {
      if (e.name !== "AbortError") output.textContent += "\n[Error]";
    } finally {
      output.style.opacity = "1";
      startBtn.disabled = false; stopBtn.disabled = true;
    }
  };
  stopBtn.onclick = () => ctrl?.abort();
}
```
