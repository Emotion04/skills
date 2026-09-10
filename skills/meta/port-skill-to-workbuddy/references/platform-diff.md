# 平台差异映射表

改造 Skill 时，把源平台（Claude Code / 通用 agentskills / OpenAI Agents / skills.sh）的专属内容按本表处理。WorkBuddy 不消费这些平台文件，残留会导致发现失败或加载噪音。

## 字段与文件映射

| 源（Claude Code / agentskills） | WorkBuddy 处理 |
|---|---|
| `${CLAUDE_SKILL_DIR}/scripts/x.py` | 改为 `scripts/x.py`（相对路径，WorkBuddy 以 Skill 目录为基准解析） |
| `allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/*)` | 删除；用 Bash 工具直接执行相对路径脚本，无需声明免弹窗 |
| `disable-model-invocation: true` | WorkBuddy 无此开关；改为可自动发现 + 可手动调用，在 `description` 写清触发条件 |
| `agents/openai.yaml`（`allow_implicit_invocation` 等） | 删除；WorkBuddy 不消费 OpenAI Agents 平台元数据 |
| `skills.sh.json`（市场分组 / groupings） | 删除；WorkBuddy 不消费 skills.sh 分组描述 |
| README 里的 `npx skills add ...` 安装说明 | 改为「把文件夹放到 `~/.workbuddy/skills/<name>/` 或 `<项目根>/.workbuddy/skills/<name>/`」 |
| 正文 "Claude Code" / "Claude token 计数端点" / "agentskills 标准" | 改写为 WorkBuddy 或中立表述（如「对应平台的 token 计数端点」「官方认可目录名」） |

## 需保留不改的内容

- 与平台无关的**方法论**（如指令审计、行为验证、写作原则）——跨平台通用，原样保留。
- `references/`、`scripts/`、`assets/` 里的实质内容，只要不依赖平台专属路径或环境变量。
- `LICENSE`、`README.md` 中通用的原则与设计动机说明。

## 需确认而非臆测的点

- 源 Skill 若依赖本地守护进程、浏览器扩展或外部服务（如 kimi-webbridge、agentfetch），WorkBuddy 是否能跑通要单独评估，不要假装可用；在交付说明里如实标注限制。
- 用户要的是用户级还是项目级安装——默认用户级，除非明确要求随仓库共享。
