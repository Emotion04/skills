---
name: plug-ai
description: 在自有项目中接入 AI 聊天能力：多供应商路由代理、API Key 管理、模型选择器、SSE 流式输出，覆盖 DeepSeek/Qwen/MiMo/Step 并支持生图。需要添加 AI 对话、切换模型供应商或搭建服务端 AI 代理时使用。
---

# Plug AI

多供应商 AI 接入——路由代理、API Key 管理、流式解析、供应商切换 UI。按需取用。

## 模块

| 需求 | 文件 | 必读 |
|------|------|:----:|
| 多供应商路由 + API Key 管理 | [provider-config.md](references/provider-config.md) | ✓ |
| 浮动供应商卡片 UI | [provider-card-ui.md](references/provider-card-ui.md) | |
| SSE 流式解析 | [streaming.md](references/streaming.md) | |
| Qwen/Wan 生图 | [image-generation.md](references/image-generation.md) | |
| 核实模型 ID / 端点是否已过期 | [provider-docs.md](references/provider-docs.md) | |

> 要打字机效果 → `streaming-typing-effect` skill。要算 Token → `token-counter` skill。

## 快速开始

### 后端：一个路由打通所有供应商

```ts
// api/chat/route.ts
const PROVIDERS = {
  deepseek: { url: "https://api.deepseek.com", header: "Authorization", prefix: "Bearer " },
  qwen:     { url: "https://dashscope.aliyuncs.com/compatible-mode", header: "Authorization", prefix: "Bearer " },
  mimo-token-plan: { url: "https://token-plan-cn.xiaomimomo.com", header: "api-key", prefix: "" },
  mimo-api: { url: "https://api.xiaomimomo.com", header: "api-key", prefix: "" },
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

### 前端：流式 Hook + 供应商卡片

```ts
// 流式 Hook（见 streaming.md）
const { text, streaming, stream, abort } = useStreamChat();

// 供应商卡片（见 provider-card-ui.md）
<ProviderCard />
```

## 模型 ID 时效性

厂商的模型 ID 和端点会变——本合集就踩过 MiMo V2 系列整个废弃。下面的表是快照，不是事实来源。

**写代码前**，命中任一情况先读 [provider-docs.md](references/provider-docs.md) 核实：

- 用户点名了某个具体模型
- 用户报错提到模型不存在、404 或 invalid model
- 要新增表里没有的供应商

没命中就直接按表写，不用每次触发都查一遍。

## 支持的供应商

| 供应商 | Base URL | 默认模型 |
|--------|----------|----------|
| DeepSeek | `https://api.deepseek.com` | `deepseek-v4-flash` |
| MiMo (Token Plan) | `https://token-plan-cn.xiaomimimo.com` | `mimo-v2.5-pro` |
| MiMo (API) | `https://api.xiaomimomo.com` | `mimo-v2.5-pro` |
| Qwen (文本) | `https://dashscope.aliyuncs.com/compatible-mode` | `qwen3.7-flash` |
| Qwen (生图) | `https://dashscope.aliyuncs.com` | `qwen-image-2.0-pro` |
| Step Plan | `https://api.stepfun.com/step_plan` | `step-3.7-flash` |

完整模型列表、Step Plan 推理参数、生图见 [provider-config.md](references/provider-config.md) 和 [image-generation.md](references/image-generation.md)。
