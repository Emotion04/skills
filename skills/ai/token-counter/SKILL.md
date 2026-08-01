---
name: token-counter
description: Token counting for streaming AI API responses. Reads API usage fields for precision or estimates by character count. Covers DeepSeek, Qwen, MiMo, and Step Plan. Use when user wants to count tokens or monitor token usage in streaming responses.
---

# Token Counter

Track token usage for AI API responses.

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

## UI Display

```tsx
function TokenDisplay({ promptTokens, completionTokens }: Props) {
  return (
    <span className="text-xs text-gray-400">
      {promptTokens} → {completionTokens} tokens
    </span>
  );
}
```

Place below the streaming output area, shown when streaming completes.
