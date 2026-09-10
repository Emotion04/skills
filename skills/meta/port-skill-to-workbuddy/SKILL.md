---
name: port-skill-to-workbuddy
version: "1.0.0"
description: 把来自其它平台（Claude Code、OpenAI Agents、skills.sh 等 agentskills 兼容技能）的现有 Skill 改造成 WorkBuddy 适用的技能。当用户要求"迁移""移植""转换""适配"某个 Skill 到 WorkBuddy，或要把 Claude Code / agentskills 的 SKILL.md 改成 WorkBuddy 格式时使用。产出即可被 WorkBuddy 自动发现的技能目录，不逐字翻译。
license: MIT. See LICENSE
agent_created: true
metadata:
  author: infpc
display_name: "Port Skill to WorkBuddy"
display_name_en: "Port Skill to WorkBuddy"
description_zh: "把第三方/其它 Agent 平台的 Skill（Claude Code、OpenAI Agents、skills.sh 等）改造成 WorkBuddy 适用的技能，剥离平台专属文件与字段，保留跨平台方法论。"
description_en: "Convert a Skill from another agent platform (Claude Code, OpenAI Agents, skills.sh) into a WorkBuddy-ready skill: strip platform-specific files/fields, keep portable methodology."
visibility: "public"
---

# Port Skill to WorkBuddy

把第三方 / 其它 Agent 平台的 Skill 改造成 WorkBuddy 格式。目标是产出一份 WorkBuddy 能自动发现、能正常加载引用的技能，而不是逐字翻译。平台专属差异的逐条映射见 [`references/platform-diff.md`](references/platform-diff.md)。

## 工作流

1. **定位源 Skill 并确认范围。** 找到源 `SKILL.md` 及附属目录（`scripts/`、`references/`、`assets/`、`agents/` 等），向用户确认迁移哪个 Skill、落到用户级还是项目级。
   - 用户级：`~/.workbuddy/skills/<name>/`（跨所有项目可用）
   - 项目级：`<项目根>/.workbuddy/skills/<name>/`（随仓库共享）
2. **复制通用内容。** 把与平台无关的正文、`references/` 文档、`scripts/` 脚本、`assets/` 模板按原结构搬入目标目录。脚本继续用相对路径 `scripts/<名>.<ext>` 引用，不要硬编码绝对路径。
3. **重写 frontmatter。** 按下方硬规则补齐 / 改写 YAML。保留 `name`、`description`、`license`；补 `agent_created: true`；按需补 `version`、`display_name`、`visibility`。
4. **剥离平台专属产物。** 删除 WorkBuddy 不消费的文件与字段（完整清单见 references/platform-diff.md）：`${CLAUDE_SKILL_DIR}` 前缀、`allowed-tools` 声明、`agents/openai.yaml`、`skills.sh.json` 及其它平台元数据。
5. **改写平台措辞。** 把正文里 "Claude Code"、"Claude token 计数端点"、"agentskills 标准"、"npx skills add" 等平台专属表述改成 WorkBuddy 或中立说法；保留纯粹的方法论、审计 / 验证逻辑不动。
6. **校验。** 确认 `name` 等于目录名、frontmatter 为合法 YAML、`agent_created: true` 存在、脚本引用均为相对路径、无遗留的 `${...}` 或平台专属文件。

## frontmatter 硬规则

- `name` 必须等于文件夹名，全小写 kebab-case；
- `description` 写能力 + 触发条件，供 WorkBuddy 自动发现；
- 模型自建技能必须带 `agent_created: true`，否则 Skill 管理工具无法识别与维护；
- 引用脚本 / 文件一律相对路径，WorkBuddy 以 Skill 目录为基准解析，无需 `${...}` 前缀；
- 带编译产物时声明平台兼容（如"仅 Windows x64"）。

## 边界（铁律）

- 不凭空编造 WorkBuddy 不支持的字段或能力。遇到源平台独有特性（如 `disable-model-invocation`），改写为 WorkBuddy 等价语义，或显式标注「WorkBuddy 暂不支持，已改为 X」并说明取舍。
- 不改动与平台无关的核心方法论、审计 / 验证逻辑——它们跨平台通用，逐字保留即可。
- 不在正文中写死用户目录、操作系统或安装路径；外部依赖在运行时探测。

## 完成标准

Skill 在以下条件全部满足时才算完成：

- 目标目录下存在合法 SKILL.md，`name` == 目录名，`agent_created: true` 为真；
- 无 `${CLAUDE_SKILL_DIR}` / `allowed-tools` / `agents/` / `skills.sh.json` 等平台残留；
- 所有脚本 / 文件引用为相对路径，无绝对路径硬编码；
- 正文无 "Claude Code" 等平台专属硬依赖表述（已中立改写或标注）；
- 复用的 `references/` 与脚本保持可读、可被 WorkBuddy 加载引用。
