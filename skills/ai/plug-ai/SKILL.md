---
name: plug-ai
description: Multi-provider AI integration with API key management, server-side routing proxy, floating provider card UI, and SSE streaming parser. Covers DeepSeek, Qwen, MiMo, and Step Plan. Use when user wants to add AI chat to a web app, switch between AI providers, manage API keys in the browser, or set up a server-side AI proxy route.
---

# Plug AI

Multi-provider AI integration — routing proxy, API key management, streaming parser, and provider switching UI. Pick the modules you need.

## Modules

| Need | File | Required |
|------|------|:--------:|
| Multi-provider routing + API keys | [provider-config.md](references/provider-config.md) | ✓ |
| Floating provider card UI | [provider-card-ui.md](references/provider-card-ui.md) | |
| SSE stream parser | [streaming.md](references/streaming.md) | |
| Qwen/Wan image generation | [image-generation.md](references/image-generation.md) | |

> Want the typing animation? → `streaming-typing-effect` skill. Want cost tracking? → `token-counter` skill.

## Quick Start

### Backend: One route for all providers

```ts
// api/chat/route.ts
const PROVIDERS = {
  deepseek: { url: "https://api.deepseek.com", header: "Authorization", prefix: "Bearer " },
  qwen:     { url: "https://dashscope.aliyuncs.com/compatible-mode", header: "Authorization", prefix: "Bearer " },
  mimo:     { url: "https://token-plan-cn.xiaomimomo.com", header: "api-key", prefix: "" },
  step:     { url: "https://api.stepfun.com/step_plan", header: "Authorization", prefix: "Bearer " },
};

export async function POST(req: Request) {
  const { provider, model, messages } = await req.json();
  const cfg = PROVIDERS[provider] || PROVIDERS.deepseek;
  const apiKey = req.headers.get("x-api-key") || process.env[`${provider.toUpperCase()}_API_KEY`];
  if (!apiKey) return Response.json({ error: "Missing API Key" }, { status: 401 });

  const res = await fetch(`${cfg.url}/v1/chat/completions`, {
    method: "POST",
    headers: { "Content-Type": "application/json", [cfg.header]: `${cfg.prefix}${apiKey}` },
    body: JSON.stringify({ model, messages, stream: true }),
  });
  return new Response(res.body, { headers: { "Content-Type": "text/event-stream" } });
}
```

### Frontend: Stream hook + provider card

```ts
// Streaming hook (from streaming.md)
const { text, streaming, stream, abort } = useStreamChat();

// Provider card (from provider-card-ui.md)
<ProviderCard />
```

## Supported Providers

| Provider | Base URL | Default Model |
|----------|----------|---------------|
| DeepSeek | `https://api.deepseek.com` | `deepseek-v4-flash` |
| MiMo | `https://token-plan-cn.xiaomimomo.com` | `mimo-v2.5-pro` |
| Qwen (Text) | `https://dashscope.aliyuncs.com/compatible-mode` | `qwen3.7-flash` |
| Qwen (Image) | `https://dashscope.aliyuncs.com` | `qwen-image-2.0-pro` |
| Step Plan | `https://api.stepfun.com/step_plan` | `step-3.7-flash` |

Full model lists, Step Plan reasoning parameters, and image generation in [provider-config.md](references/provider-config.md) and [image-generation.md](references/image-generation.md).
