# write-skills 仓库开发指南

本仓库是 write-skills 的独立仓库（事实源）。所有改动在这里完成，再通过 git subtree 同步到合集仓库。

## 仓库结构

```text
write-skills/              # 独立仓库根（Emotion04/write-skills）
├── SKILL.md               # skill 核心
├── references/
│   ├── instruction-audit.md
│   └── behavior-validation.md
├── agents/
│   └── openai.yaml
├── LICENSE
└── README.md
```

## 提交规范

### 提交前检查

- 提交消息用中文，说明"做了什么"，不写 `Co-Authored-By`
- 只提交与本次改动相关的文件，不要 `git add -A` 无差别提交
- LICENSE 保留 `Copyright (c) 2026 Matt Pocock` + `Copyright (c) 2026 Emotion04` 两行

### 提交命令

```bash
git add <具体文件>
git commit -m "中文描述：做了什么"
git push origin main
```

## Subtree 同步到合集仓库

写完并 push 独立仓库后，在**合集仓库**（`D:\CCode\Skills\skills-collection`）同步：

```bash
# 在合集仓库目录执行
cd /d/CCode/Skills/skills-collection

# write-skills 同步
git subtree pull --prefix skills/meta/write-skills https://github.com/Emotion04/write-skills.git main

# agentfetch 同步
git subtree pull --prefix skills/search/agentfetch https://github.com/yuhan-skill/agentfetch.git main

# 推合集
git push origin main
```

### 同步规则（重要）

1. **改东西只改独立仓库**，合集永远是被 `subtree pull` 拉进来的副本。
2. **绝不在合集仓库里直接改 `skills/meta/write-skills/`、`skills/search/agentfetch/` 下的文件**——改动会在下次 pull 时被覆盖。
3. 普通 `git push` 只推当前所在仓库，不会自动同步到另一处。
4. 反向同步（合集 → 独立仓库）用 `git subtree push`，容易产生历史分叉/冲突，避免使用。

## 当前依赖的 subtree

| 独立仓库 | 合集位置 |
|---|---|
| Emotion04/write-skills | `skills/meta/write-skills` |
| yuhan-skill/agentfetch | `skills/search/agentfetch` |
