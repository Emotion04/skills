---
name: token-counter
description: Token counting and cost estimation for streaming AI API responses. Reads API usage fields for precision or estimates by character count. Covers DeepSeek, Qwen, MiMo, and Step Plan pricing. Use when user wants to track AI API costs, count tokens, estimate LLM expenses, or monitor token usage in streaming responses.
---

# Token Counter

Track token usage and estimate costs for AI API responses.

## Two Approaches

### A. Precise: Read API `usage` field

Most providers return usage in the last SSE event:

```
data: {"choices":[...],"usage":{"prompt_tokens":120,"completion_tokens":85,"total_tokens":205}}
```

```ts
let promptTokens = 0, completionTokens = 0;

function parseUsage(line: string) {
  try {
    const data = JSON.parse(line.slice(6));
    if (data.usage) {
      promptTokens = data.usage.prompt_tokens ?? 0;
      completionTokens = data.usage.completion_tokens ?? 0;
    }
  } catch {}
}
```

### B. Estimate: Character-based

When the API doesn't return usage:

```
English: 1 token ≈ 4 characters
Chinese: 1 token ≈ 1.5 characters
```

```ts
function estimateTokens(text: string): number {
  const cjk = (text.match(/[一-鿿]/g) || []).length;
  const other = text.length - cjk;
  return Math.ceil(cjk / 1.5 + other / 4);
}
```

## Cost Calculation

```ts
function calcCost(promptTokens: number, completionTokens: number, prices: { in: number; out: number }): number {
  return (promptTokens * prices.in + completionTokens * prices.out) / 1_000_000;
}
```

## Pricing Reference (¥/1M tokens)

| Provider | Model | Input | Output |
|----------|-------|------:|-------:|
| DeepSeek | deepseek-v4-flash | 1 | 2 |
| DeepSeek | deepseek-v4-pro | 5 | 20 |
| Qwen | qwen3.7-flash | 1 | 2 |
| Qwen | qwen3.7-max | 12 | 36 |
| MiMo | mimo-v2.5-pro | see website | see website |
| Step Plan | step-3.7-flash | Credit-based | Credit-based |

> Prices change. Check provider websites for current rates.

## UI Display

```tsx
function TokenDisplay({ promptTokens, completionTokens, prices }: Props) {
  const cost = calcCost(promptTokens, completionTokens, prices);
  return (
    <span className="text-xs text-gray-400">
      {promptTokens} → {completionTokens} tokens · ¥{cost.toFixed(4)}
    </span>
  );
}
```

Place below the streaming output area, shown when streaming completes.
