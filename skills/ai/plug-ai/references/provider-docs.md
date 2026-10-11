# Provider Docs 核实指南

模型 ID、Base URL、端点路径都会随厂商更新而变动。本文件是**核实方法**，不是事实快照——
快照在 [provider-config.md](provider-config.md)，那个会过期。

## 何时需要核实

| 情况 | 是否核实 |
|---|---|
| 用默认模型、用户没点名 | 否，按 provider-config.md 直接写 |
| 用户点名了某个具体模型 | 是，先确认 ID 还在 |
| 用户报错提到模型不存在 / 404 / invalid model | 是 |
| 要新增表里没有的供应商 | 是 |
| 生图的尺寸枚举、`prompt_extend` 支持范围 | 是，厂商间差异大且常变 |

## 第一步：优先问官方端点（不用搜索）

模型列表端点比搜索可靠，能问到就优先用，拿已有的 Key 直接调：

```bash
# DeepSeek（404 就试 https://api.deepseek.com/v1/models）
curl https://api.deepseek.com/models \
  -H "Authorization: Bearer $DEEPSEEK_API_KEY"

# 通义千问 / DashScope —— 文本和图片模型都在这一个端点里
curl https://dashscope.aliyuncs.com/compatible-mode/v1/models \
  -H "Authorization: Bearer $DASHSCOPE_API_KEY"
```

返回标准 OpenAI 格式 `{ data: [{ id: "..." }] }`，直接拿 `id` 用。

MiMo 和 Step 的模型列表端点以各自文档为准——这两家对 OpenAI 协议改动较多，
不要照抄 `/models` 路径猜，猜错的代价是一份看着对、调不通的代码。

## 第二步：端点问不到再搜索

没有 Key、端点不通、或要确认参数语义时，搜官方文档。用当前环境里可用的搜索或
网页读取工具（WebSearch / WebFetch / 浏览器类搜索 skill，任一即可，都没有就跳到第三步）。

按厂商取关键词：

| 厂商 | 搜索关键词 |
|---|---|
| DeepSeek | `DeepSeek API 模型列表 models 官方文档` |
| 通义千问 | `DashScope 百炼 模型列表 qwen-image 模型广场` |
| MiMo | `小米 MiMo API 平台 模型列表 官方文档` |
| Step | `阶跃星辰 Step API 模型列表 官方文档` |

认准官方域名，别采信技术博客的转载：

- DeepSeek → `api-docs.deepseek.com`、`platform.deepseek.com`
- 通义千问 → `help.aliyun.com/zh/model-studio/`、`bailian.console.aliyun.com`
- MiMo → `platform.xiaomimomo.com`、`token-plan-cn.xiaomimomo.com`
- Step → `platform.stepfun.com`

## 第三步：搜索也不可用时

明确告诉用户「以下模型 ID 未经核实，可能已更新」，并指给他该去哪个文档页自己确认。
不要静默按过期 ID 生成代码——那样的代码一调就 404，比当场报错难排查得多。

## 已知容易变的字段

按实际踩坑频率排：

1. **模型 ID 版本号** — `qwen3.7` → `qwen3.8` 这种小版本号跳得最勤，也最容易被硬编码进项目
2. **生图尺寸枚举** — Qwen 用 `1728*2368`，Wan 用 `2K`，两家不通用，且会加新档位
3. **参数支持范围** — Wan 不支持 `prompt_extend` / `negative_prompt`，用 `thinking_mode` 代替；
   这条边界移动过，每次生图前值得重新确认
4. **Base URL 地域后缀** — 北京 `cn-beijing`、新加坡 `ap-southeast-1`，Key 和域名不互通，
   跨区调用返回 401（详见 [image-generation.md](image-generation.md)）
5. **Step 的推理参数名** — `reasoning_effort` 是 OpenAI 风格，Step 是否长期兼容需确认

## 核实完怎么落地

把确认结果写回 [provider-config.md](provider-config.md) 的表格，别只留在当次对话里——
下次触发这个 skill 的会话读不到你这次的结论，等于白查。
