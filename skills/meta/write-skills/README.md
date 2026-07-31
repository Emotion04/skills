# write-skills

写出更高质量的 Skills。基于 Claude Code 之父 Thariq Shihipar 的核心观点——Claude Code 移除了 80% system prompt 后 coding eval 无性能损失——最好的 Skill 是最短但仍守住契约的那一个。

信任模型已有能力，只写目标、硬边界与可验证的完成条件；模型已知的不写，环境可查的不写，没失败过的不预防。

## 安装

```bash
npx skills add Emotion04/write-skills --skill write-skills
```

## 原则

- **信任模型**：不写模型已知的默认行为，不写环境可查的事实
- **只写目标与硬边界**：目的地 + 护栏，不编排每一步
- **证据门槛**：每条指令必须保护一项不可推断约束，或防止一次已观察到的失败
- **验证驱动删减**：删后跑 eval，不回退就保持删除

## 文件

| 文件 | 用途 |
|---|---|
| `SKILL.md` | 核心入口，写 Skill 的完整工作流 |
| `references/instruction-audit.md` | 指令审计手册，保留/删除判据 |
| `references/behavior-validation.md` | 行为验证方法 |

## 许可

MIT — 基于 [mattpocock/skills](https://github.com/mattpocock/skills) 修改。

原始版权 © 2026 Matt Pocock。
