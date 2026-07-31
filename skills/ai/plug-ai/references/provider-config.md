# Provider Configuration

多供应商路由 + API Key 管理。

## 供应商配置

| 供应商 | Base URL | Auth | 默认模型 |
|--------|----------|------|----------|
| DeepSeek | `https://api.deepseek.com` | `Bearer` | `deepseek-v4-flash` |
| 小米 MiMo | `https://api.xiaomimimo.com` | `api-key` | `mimo-v2.5-pro` |
| 通义千问 | `https://dashscope.aliyuncs.com/compatible-mode` | `Bearer` | `qwen3.7-flash` |
| Step Plan | `https://api.stepfun.com/step_plan` | `Bearer` | `step-3.7-flash` |

新增供应商：在 `PROVIDERS` 数组里加一条即可。

## 后端：路由代理

所有供应商统一走 OpenAI 兼容的 Chat Completions 协议。

```ts
const PROVIDERS = {
  deepseek: { url: "https://api.deepseek.com", header: "Authorization", prefix: "Bearer " },
  mimo:     { url: "https://api.xiaomimimo.com", header: "api-key", prefix: "" },
  qwen:     { url: "https://dashscope.aliyuncs.com/compatible-mode", header: "Authorization", prefix: "Bearer " },
  step:     { url: "https://api.stepfun.com/step_plan", header: "Authorization", prefix: "Bearer " },
};

export async function POST(req: Request) {
  const { provider, model, baseUrl, messages } = await req.json();
  const cfg = PROVIDERS[provider] || PROVIDERS.deepseek;
  const apiUrl = baseUrl || `${cfg.url}/v1/chat/completions`;

  // 客户端 Key 优先，服务端环境变量兜底
  const apiKey = req.headers.get("x-api-key") || process.env[`${provider.toUpperCase()}_API_KEY`];
  if (!apiKey) return new Response(JSON.stringify({ error: "缺少 API Key" }), { status: 401 });

  const upstream = await fetch(apiUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      [cfg.header]: `${cfg.prefix}${apiKey}`,
    },
    body: JSON.stringify({ model: model || cfg.defaultModel, messages, stream: true }),
  });

  return new Response(upstream.body, {
    headers: { "Content-Type": "text/event-stream", "Cache-Control": "no-cache" },
  });
}
```

## 模型列表

每个供应商保留核心模型：

| 供应商 | 模型 | 定位 |
|--------|------|------|
| DeepSeek | `deepseek-v4-flash` | 快速，性价比 |
| DeepSeek | `deepseek-v4-pro` | 高质量 |
| 小米 MiMo | `mimo-v2.5` | 标准版 |
| 小米 MiMo | `mimo-v2.5-pro` | 旗舰版 |
| 通义千问 | `qwen3.7-flash` | 快速响应 |
| 通义千问 | `qwen3.7-plus` | 均衡 |
| 通义千问 | `qwen3.7-max` | 旗舰 |
| Step Plan | `step-3.7-flash` | 多模态推理 |

> MiMo V2 系列已于 2025 年 6 月 30 日废弃，请使用 V2.5 系列。

## Step Plan 特殊参数

Step Plan 的 `step-3.7-flash` 支持推理强度调节：

```ts
// OpenAI 协议
body: {
  model: "step-3.7-flash",
  reasoning_effort: "medium",  // "low" | "medium" | "high"
  messages: [...]
}
```

| 强度 | 适用场景 |
|------|----------|
| `low` | 简单问答、摘要、改写 |
| `medium` | 默认，一般推理和多步骤任务 |
| `high` | 复杂推理、数学、规划、代码分析 |

## 前端：API Key 存储

所有 Key 存在 localStorage，不经过服务端（用户自担安全责任）。

```ts
const KEY_PREFIX = "app-api-key";

function getKey(provider: string): string {
  return localStorage.getItem(`${KEY_PREFIX}-${provider}`) || "";
}
function setKey(provider: string, key: string) {
  localStorage.setItem(`${KEY_PREFIX}-${provider}`, key);
}

// 请求时携带
const headers: Record<string, string> = { "Content-Type": "application/json" };
const key = getKey("deepseek");
if (key) headers["x-api-key"] = key;
headers["x-provider"] = "deepseek";
```

## 请求流向

```
浏览器 → 你的后端 → AI 供应商
  │           │           │
  │  x-api-key           │
  │  x-provider          │
  │──────────────────────>│  Authorization: Bearer xxx
  │                       │──────────────────────────────>
  │                       │     text/event-stream
  │<──────────────────────│<──────────────────────────────
  │<──────────────────────│
```

1. 浏览器把用户存的 Key 放在 `x-api-key` header 里发到你后端
2. 后端优先用这个 Key，没有就 fallback 到 `process.env.{PROVIDER}_API_KEY`
3. 后端把 Key 拼上供应商要求的 auth 格式，转发请求
4. SSE 流原样透传回浏览器

## 切换 UI

浮动卡片的完整实现见 [provider-card-ui.md](provider-card-ui.md)。该文件依赖本文件的 `PROVIDERS` 列表。

## 流式输出

后端路由里 `stream: true` 透传 SSE 流。前端的解析逻辑见 [streaming.md](references/streaming.md)。如果你暂时不需要流式输出，把 `stream: true` 改成 `false`，返回普通 JSON 即可。
