---
name: agentfetch
description: Browser-powered search and direct URL reading through the user's real Chrome session. Use direct page reading for explicit URLs; use search only when discovering sources or answering topic-based questions.
compatibility: Windows x64. Google, Bing, WeChat, and page reading require Chrome plus a running kimi-webbridge daemon and connected extension. GitHub repository search uses its public API.
allowed-tools:
  - Bash(bash "${CLAUDE_SKILL_DIR}/scripts/agentfetch.sh" *)
---

# agentfetch

Always invoke the bundled CLI through:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/agentfetch.sh" <command> [args]
```

Do not call a PATH-installed `agentfetch`. This Skill includes one executable containing all search engines and page reading.

## Choose the operation

Use this simple rule before running the CLI:

- An explicit `http://` or `https://` URL → call `result` directly. Do not search the URL.
- A topic, question, or request to discover sources without a URL → call `search`.
- A URL plus a question → call `result` first, then answer from the returned page content.

Correct:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/agentfetch.sh" result "https://example.com/article"
```

Incorrect:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/agentfetch.sh" search "https://example.com/article"
```

`result` is the direct page-reading primitive. It uses the user's real Chrome session through kimi-webbridge, so rendered JavaScript content and existing browser login state can be available. Its stdout is one JSON object; the readable page content is in the `text` field. JSON is only the stable machine-readable envelope, not a replacement for the page content.

## Search

Search is for discovering sources, not for opening a URL that the user already supplied.

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/agentfetch.sh" search "query"          # Google + Bing
bash "${CLAUDE_SKILL_DIR}/scripts/agentfetch.sh" search "query" -n 5     # simple lookup
bash "${CLAUDE_SKILL_DIR}/scripts/agentfetch.sh" search "query" -m cn    # Chinese-local results
bash "${CLAUDE_SKILL_DIR}/scripts/agentfetch.sh" search "query" -e github
bash "${CLAUDE_SKILL_DIR}/scripts/agentfetch.sh" search "query" -e weixin
```

Useful flags: `-e google,bing`, `-a`, `-m us|cn`, `-n 1..50`, `-o OFFSET`, `-u`.

## Engine selection

- Default search uses Google + Bing in parallel.
- Use `-e weixin` when the user asks for WeChat/public-account material or Chinese local/community coverage.
- Use `-e github` for repositories, SDKs, code, issues, or implementation examples.
- Use `-a` only for an explicitly broad/deep investigation that needs multiple ecosystems; do not use it for every query.

`-n` is the per-engine candidate budget. With the default Google + Bing search, `-n 5` asks each engine for up to 5 candidates; the merged output can contain up to 10 non-duplicate results, rather than silently limiting the whole response to 5. The Agent should usually start with `-n 5`, then increase it for broad research.

## Adaptive workflow

Search `title` and `snippet` identify candidate sources; they do not replace page content.

1. Use `-n 5` for simple facts, `-n 10` for explanations/comparisons, and 15+ only for broad research.
2. Check whether results identify the same object, include primary sources, and cover the question.
3. For comparisons, verification, summaries, changing facts, ambiguous terms, or details with qualifications, start with the 2 most relevant sources in parallel when possible. Continue with a third or fourth source only if the first two are insufficient, conflicting, or not independent. For broad/deep research, expand the candidate set and read more sources as needed, but do not mechanically read every result:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/agentfetch.sh" result "URL"
```

4. If `truncated` is true and the missing portion matters, continue from the returned position:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/agentfetch.sh" result "URL" -o 20000
```

5. Refine and search again only when ambiguity, missing primary sources, conflicts, or incomplete coverage remain.
6. Cross-check important or disputed claims with two independent sources when practical, then stop once the evidence supports the answer.

## Output

`search` returns a JSON array:

```json
[{"title":"...","url":"...","snippet":"...","source":"..."}]
```

`result` uses kimi-webbridge and the real Chrome session to read filtered text from the rendered DOM, not raw HTML. Each invocation owns an isolated browser session/tab so concurrent reads do not overwrite one another. It returns up to 20,000 characters by default:

```json
{"url":"...","title":"...","description":"...","text":"...","text_length":24000,"returned_length":20000,"offset":0,"truncated":true}
```

For a long page when the user asks about a specific term, use the single optional page-search flag to return nearby context from the rendered page:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/agentfetch.sh" result "URL" --find "rate limit"
```

Use `--find` to improve relevance, not as a mandatory token-saving step. It returns matching context rather than the whole page; if the surrounding context is insufficient, use normal `result` or another focused term. Do not invent complex selector, click, or interaction arguments.

```json
{"url":"...","title":"...","text":"...","find":"rate limit","match_count":2,"text_length":1800,"returned_length":1800,"offset":0,"truncated":false}
```

For normal page reading, omit `--find`.

Use `result -n 50000` only when the initial page content is insufficient (maximum 100,000). If `truncated` is true and the missing portion matters, call `result` again with `-o` set to the previous `offset + returned_length`; do not continue mechanically when the returned content is already sufficient.

## Runtime failures

If browser search or `result` reports that kimi-webbridge or its extension is unavailable, tell the user to start kimi-webbridge, open Chrome, and connect the extension. Do not silently fall back to another search tool. GitHub search with `-e github` remains available without WebBridge.
