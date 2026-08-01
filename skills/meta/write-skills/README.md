# Write-Skills | 把你的工作、经验写成一个规范的中文Skills
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code Skill](https://img.shields.io/badge/Claude_Code-Skill-orange?logo=claude&logoColor=white)](https://claude.ai/code)
[![npx install](https://img.shields.io/badge/npx_skills_add-write--skills-blue?logo=npm)](https://www.npmjs.com/package/skills)
[![GitHub last commit](https://img.shields.io/github/last-commit/Emotion04/write-skills?color=teal)](https://github.com/Emotion04/write-skills/commits)

写出更高质量的 Skills。基于 Thariq Shihipar 的核心观点——Claude Code 移除了 80% system prompt 后 coding eval 无性能损失——最好的 Skill 是最短但仍守住契约的那一个。这个 Skill 信任模型已有能力，只写目标、硬边界与可验证的完成条件；模型已知的不写，环境可查的不写，没失败过的不提前预防，把重复工作写成简洁规范的 Skills。

## 安装

```bash
npx skills add Emotion04/write-skills --skill write-skills
```

或者对你的 Agent 说，帮我安装：npx skills add Emotion04/write-skills --skill write-skills


## 原则

- **信任模型**：不写模型已知的默认行为，不写环境可查的事实
- **只写目标与硬边界**：只写目的 + 护栏，不编排每一步
- **证据门槛**：每条指令必须保护一项不可推断约束，或防止一次已观察到的失败

## 文件

| 文件 | 用途 |
|---|---|
| `SKILL.md` | 核心入口，写 Skill 的完整工作流 |
| `references/instruction-audit.md` | 指令审计手册，保留/删除判据 |
| `references/behavior-validation.md` | 行为验证方法 |

## 许可

MIT — 基于 [mattpocock/skills](https://github.com/mattpocock/skills) 修改。

原始版权 © 2026 Matt Pocock。
