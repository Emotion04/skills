# DashScope Qwen/Wan 图片生成

> 与文本 Chat 完全不同的端点和协议。文本模型走 `/compatible-mode/v1/chat/completions`，图片模型走异步多模态生成端点。

## 端点和鉴权

文本和图片共用同一个 `DASHSCOPE_API_KEY`，不存在 Key 冲突。

| 模式 | Endpoint | 兼容协议 |
|------|----------|----------|
| **文本 Chat** | `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions` | OpenAI |
| **图片生成** | `https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation` | DashScope 原生 |

Workspace 专属域名（可选，生产环境推荐）：

```text
https://{WorkspaceId}.cn-beijing.maas.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation
```

## 文本 vs 图片请求对比

```ts
// ❌ 错误：用 Chat 端点请求图片
fetch("https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions", {
  body: JSON.stringify({ model: "qwen-image-2.0", messages: [...] })
});

// ✅ 正确：图片走多模态生成端点
fetch("https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation", {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${apiKey}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    model: "qwen-image-2.0-pro",
    input: {
      messages: [{ role: "user", content: [{ text: "一只红色狐狸，水彩风格" }] }],
    },
    parameters: {
      size: "1728*2368",       // 3:4 比例
      n: 1,                     // 1-6 张
      prompt_extend: true,      // 自动扩写 Prompt
      negative_prompt: "低画质，模糊，变形",
      watermark: false,
      seed: 42,
    },
  }),
});
```

## 可用模型

### Qwen Image（同步）

| upstreamModelId | 定位 | 特点 |
|---|---|---|
| `qwen-image-2.0` | 标准版 | 兼顾效果和速度，1–6 张输出 |
| `qwen-image-2.0-pro` | 专业版 | 文本渲染最强，中英文海报/图表 |

Qwen 专属参数：`prompt_extend`（默认 true）、`negative_prompt`（最多 500 字符）。

### Wan（同步 + 异步）

| upstreamModelId | 定位 | 特点 |
|---|---|---|
| `wan2.7-image-pro` | 专业版 | 最高 4K，`thinking_mode` 质量控制 |
| `wan2.7-image` | 标准版 | 速度更快 |

Wan **不支持** `prompt_extend` 和 `negative_prompt`。使用 `thinking_mode: true` 代替。

### 尺寸映射

| 比例 | Qwen 尺寸 | Wan 尺寸 |
|------|-----------|----------|
| 1:1 | `2048*2048` | `2K` |
| 3:4 | `1728*2368` | `2K` |
| 16:9 | `2688*1536` | — |

## 返回结果

```ts
type DashScopeImageResponse = {
  output: {
    choices: Array<{
      finish_reason: "stop";
      message: {
        content: Array<{ image: string }>;  // 图片 URL，24h 有效
        role: "assistant";
      };
    }>;
  };
  usage: { image_count: number; };
  request_id: string;  // 建议记录，排查问题用
};

// 提取所有图片
const images = payload.output.choices
  .flatMap(c => c.message.content)
  .filter(item => item.image)
  .map(item => item.image);
```

> 图片 URL 24 小时后失效。生产环境应服务端立即下载并转存到对象存储。

## 完整 Adapter 示例

```ts
// lib/providers/dashscope-image.ts
const QWEN_SIZE: Record<string, string> = { "1:1":"2048*2048", "3:4":"1728*2368", "4:3":"2368*1728" };

function dashScopeHost() {
  const region = process.env.DASHSCOPE_REGION ?? "cn-beijing";
  const ws = process.env.DASHSCOPE_WORKSPACE_ID;
  return ws
    ? `${ws}.${region}.maas.aliyuncs.com`
    : region === "ap-southeast-1" ? "dashscope-intl.aliyuncs.com" : "dashscope.aliyuncs.com";
}

async function generateImage(params: {
  prompt: string;
  model: string;           // upstream model ID
  aspectRatio?: string;
  negativePrompt?: string;
  count?: number;
  seed?: number;
}) {
  const apiKey = process.env.DASHSCOPE_API_KEY!;
  const isWan = params.model.startsWith("wan");

  const parameters: Record<string, unknown> = {};
  if (isWan) {
    parameters.size = params.aspectRatio === "1:1" ? "2K" : "2K";
    parameters.thinking_mode = true;
  } else {
    if (params.aspectRatio && QWEN_SIZE[params.aspectRatio]) parameters.size = QWEN_SIZE[params.aspectRatio];
    parameters.prompt_extend = true;
    if (params.negativePrompt) parameters.negative_prompt = params.negativePrompt.slice(0, 500);
  }
  parameters.watermark = false;
  if (params.count) parameters.n = Math.min(params.count, isWan ? 4 : 6);
  if (params.seed != null) parameters.seed = params.seed;

  const res = await fetch(
    `https://${dashScopeHost()}/api/v1/services/aigc/multimodal-generation/generation`,
    {
      method: "POST",
      headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: params.model,
        input: { messages: [{ role: "user", content: [{ text: params.prompt }] }] },
        parameters: Object.keys(parameters).length ? parameters : undefined,
      }),
    },
  );

  if (!res.ok) {
    const err = await res.json();
    throw new Error(`DashScope ${err.code}: ${err.message} (${err.request_id})`);
  }

  const data = await res.json();
  return (data.output.choices ?? [])
    .flatMap((c: any) => c.message?.content ?? [])
    .filter((item: any) => item.image)
    .map((item: any) => item.image);
}
```

## 环境变量

```bash
DASHSCOPE_API_KEY=           # 必填，文本和图片共用
DASHSCOPE_REGION=cn-beijing  # 可选，默认北京。新加坡填 ap-southeast-1
DASHSCOPE_WORKSPACE_ID=      # 可选，填写后使用专属域名（性能更好）
```

## 模型列表发现

DashScope 的 OpenAI 兼容端点也支持模型列表：

```bash
curl https://dashscope.aliyuncs.com/compatible-mode/v1/models \
  -H "Authorization: Bearer $DASHSCOPE_API_KEY"
```

返回标准 OpenAI 格式 `{ data: [{ id: "qwen-plus" }, { id: "qwen-image-2.0-pro" }, ...] }`。

## 注意事项

- **Region 隔离**：北京和新加坡的 API Key 不互通，跨区域调用返回 401
- **URL 时效**：生成结果 24h 后清理，务必及时下载转存
- **错误码**：`InvalidApiKey`（Key 无效）、`Throttling`（限流）、`DataInspectionFailed`（内容审核拦截）
- **不计费的**：参数错误、审核拦截、网络异常
- **计费的**：成功生成的图片，按张数计费（`n` 参数会影响费用）
