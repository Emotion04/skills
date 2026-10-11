# Emotion04 Skills

我日常在用的 Agent Skills 合集——AI 接入、前端界面、视频处理、搜索,每一样都在真实项目里跑过、修过。

它让「写代码」变成:

```text
装一个 skill → 在项目里触发 → skill 按既定结构和边界干活 → 拿到可直接用的结果
```

## Skills 目录

### AI 接入
| Skill | 干什么 |
|---|---|
| plug-ai | 多供应商 AI 接入:路由代理、API Key 管理、模型切换、SSE 流式输出、生图(模型 ID 自动核实) |
| streaming-typing-effect | AI 流式输出的打字机效果 |
| token-counter | 数 Token(读 API usage 字段,或按字符估算) |

### 前端界面
| Skill | 干什么 |
|---|---|
| floating-glow-tabbar | 移动端底部导航,触控光球动画 |
| sizeflow-liquid-glass | 液态玻璃前端界面 |
| monochrome-archive-editorial | 黑白极简 / 编辑部风格网页 |

### 视频
| Skill | 干什么 |
|---|---|
| custom-voiceover | 自定义口播视频编辑 |

### 搜索
| Skill | 干什么 | 独立仓库 |
|---|---|---|
| agentfetch | 浏览器驱动的多引擎搜索 + 网页读取 | [yuhan-skill/agentfetch](https://github.com/yuhan-skill/agentfetch) |

### 元技能
| Skill | 干什么 | 独立仓库 |
|---|---|---|
| write-skills | 写出精简、可预测的 Skills | [Emotion04/write-skills](https://github.com/Emotion04/write-skills) |

## 安装

```bash
# 交互式勾选（推荐）
npx skills add Emotion04/skills

# 只安装某一个
npx skills add Emotion04/skills --skill <skill-name>
```

装完在项目里 `/skill-name` 就能用。


## 目录结构

```text
skills/
├── ai/              # AI 接入、流式输出、Token 计数
├── frontend/        # 前端界面
├── video/           # 视频处理
├── search/          # 搜索工具
└── meta/            # 写 Skill 的 Skill
```

## 关于独立仓库

`agentfetch` 和 `write-skills` 有各自的独立仓库。其余 skill 只住在这里。独立仓库的改动通过 `git subtree pull` 同步进来:

```bash
git subtree pull --prefix skills/meta/write-skills https://github.com/Emotion04/write-skills.git main
```

## 许可

MIT
