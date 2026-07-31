---
name: write-skills
description: 写出精简、可预测的 Skills。设定目标、硬约束与可验证的完成条件，信任模型已有能力，删除模型已知、环境可推断的一切。在创建或编辑 Skill 时使用。
disable-model-invocation: true
---

# Write Skills

## 工作流

1. **定义契约。** 明确任务、调用方式、产出物、硬边界和可检查的完成条件。只问目标项目或引用文件中查不到的信息。
2. **检查环境。** 不要用文字缓存代码、配置、命令和已有 Skill 中已经可发现的事实。
3. **写出最小草案。** `SKILL.md` 里只放每次运行都需要的指令。优先写目标和约束，不要编排每一步。确定性工作写成脚本而非文字。
4. **披露分支。** 仅特定分支需要的参考内容，放到一层引用文件后面，并精确写明何时读取。
5. **用证据做删减审计。** 用 [`references/instruction-audit.md`](references/instruction-audit.md) 逐条审查。
6. **用行为验证。** 用 [`references/behavior-validation.md`](references/behavior-validation.md) 在代表性案例上对比精简版与原版。回归恢复协议见 behavior-validation.md。

## 调用方式

- **模型调用**：仅当 Agent 或其他 Skill 需要自动发现时使用。保留 description，写明能力和不同触发分支。
- **用户调用**：当人工判断应选择此 Skill 时使用。设置 `disable-model-invocation: true`，description 只写简短摘要给人看。
- 拆分 Skill 的唯一理由：某个分支需要独立触发，或后续步骤遮挡当前步骤导致过早完成。

## 产出物

Skill 是一个文件夹，结构必须只用官方认可的名字：

```text
skill-name/
├── SKILL.md           # 必需：frontmatter + 指令
├── scripts/           # 可选：可执行代码（py/sh/二进制）
├── references/        # 可选：按需加载的文档
├── assets/            # 可选：模板、图片、数据
└── examples/          # 可选：使用示例
```

frontmatter 规则：

- `name` 必须等于文件夹名，全小写 kebab-case；
- `description` 写能力 + 触发条件；
- 需要脚本时，引用一律用 `${CLAUDE_SKILL_DIR}` 开头，与运行目录无关；
- 带编译产物时声明平台兼容（如"仅 Windows x64"）。

其余材料（本 Skill 的审计手册、验证方法）放 `references/`，按需加载。

## 信息层级

每个含义只存一处。每个指针同时说清楚：后面是什么、何时读取。

## 写作原则

- 用正向行为描述目标。禁止式只留给硬边界，并配对说明该做什么。
- 在模糊已导致失败的地方，用具体输入、输出和检查替代抽象描述；示例需要为它所占的上下文买单。
- 避免堆砌绝对性修饰词，把强调性词汇留给真正的不变量。
- 不要追求百分比缩减指标。

## 完成标准

Skill 在以下条件全部满足时才算完成：

- frontmatter 与调用行为一致；
- 每条保留的指令保护了一个不可推断的约束，或防止了一次已观察到的失败；
- 通用材料在文件内，条件材料有精确的一层引用指针；
- 五类案例（见 references/behavior-validation.md）均无行为回退；
- 缩短后的表述没有削弱输出契约、安全边界或完成条件。
