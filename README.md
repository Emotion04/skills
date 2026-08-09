# Write-Skills | 把你的工作、经验写成一个规范的中文Skills
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code Skill](https://img.shields.io/badge/Claude_Code-Skill-orange?logo=claude&logoColor=white)](https://claude.ai/code)
[![npx install](https://img.shields.io/badge/npx_skills_add-write--skills-blue?logo=npm)](https://www.npmjs.com/package/skills)
[![GitHub last commit](https://img.shields.io/github/last-commit/Emotion04/write-skills?color=teal)](https://github.com/Emotion04/write-skills/commits)

写出更高质量的 Skills。基于 Thariq Shihipar 的核心观点——Claude Code 移除了 80% system prompt 后 coding eval 无性能损失——最好的 Skill 是最短但仍守住契约的那一个。这个 Skill 遵循了这种做法，在为你撰写 Skills 的时候，信任模型已有能力，只写目标、硬边界与可验证的完成条件；模型已知的不写，环境可查的不写，没失败过的不提前预防，帮助你把重复工作写成简洁规范的 Skills。

## 针对中文使用者本土化
当下热门的 Skills 普遍存在一个痛点：国外开发者编写的 Skills 大多为英文，导致生成的内容同样是英文，逐渐形成了英文生态甚至壁垒。对很多用户来说，通篇英文难以审查、不易读懂——一个动辄数百上千个单词的英文 Skill，就像黑盒一样，你很难弄清楚，这个 Skill 究竟做了什么？
`write-skills` 正是为了解决这一问题而生。它几乎完全基于中文设计，同时产出的 Skills 也是中文，你可以轻松看懂它是如何实现的。例如，在我整理完照片后，用 `write-skills` 把这次工作的所有内容做成一个用于整理照片的 Skill，你可以非常直观地了解它的实现逻辑和完整工作流程。
更关键的是，`write-skills` 使用中文写 Skills，你可以基于自身理解，方便地对技能进行审核、修改，——甚至是 `write-skills` 本身。这让你离打造出心仪的、真正可用的、具有可维护性的 Skills 更近一步。

## 安装

```bash
npx skills add Emotion04/write-skills --skill write-skills
```

或者对你的 Agent 说
```bash
帮我安装：npx skills add Emotion04/write-skills --skill write-skills
```

## 原则

- **信任模型**：不写模型已知的默认行为，不写环境可查的事实
- **只写目标与硬边界**：只写目的 + 护栏，不编排每一步
- **证据门槛**：每条指令必须保护一项不可推断约束，或防止一次已观察到的失败

## 文件

```bash

  skill-name/
  ├── SKILL.md             # 必需：技能入口，frontmatter + 指令
  ├── scripts/             # 可选：可执行代码（py/exe等）
  ├── references/          
  ├── assets/              
  ├── examples/            
  └── agents/
      └── openai.yaml

```

## 提示
1. 经过测试，中文并不会降低 Skills 的效果，如果你一直使用中文与 Agent 会话，反而可能会取得更好的表现。
2. 使用 [write-skills](https://github.com/Emotion04/write-skills) 写下你的中文技能，共同完善中文 Skills 生态。

## 许可

MIT License · Copyright © 2026 Emotion04
