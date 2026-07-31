# Emotion04 Skills

个人的 Agent Skills 合集，每个 skill 同时保留独立仓库以获取独立曝光和 Stars。

## 安装

```bash
# 交互式勾选（推荐）
npx skills add Emotion04/skills

# 精确安装一个
npx skills add Emotion04/skills --skill <skill-name>
```

## Skill 列表

### AI
| Skill | 描述 | 独立仓库 |
|---|---|---|
| plug-ai | 多供应商 AI 接入 — 路由代理、API Key 管理、浮动卡片 UI | — |
| streaming-typing-effect | AI 流式输出打字机效果 | — |
| token-counter | Token 计数和费用估算 | — |

### 前端界面
| Skill | 描述 |
|---|---|
| floating-glow-tabbar | 移动端底部导航栏，触控追踪光球、呼吸动画 |
| sizeflow-liquid-glass | 液态玻璃视觉设计系统 |
| monochrome-archive-editorial | 极简黑白数字档案馆与编辑部风格 |

### 视频
| Skill | 描述 |
|---|---|
| custom-voiceover | 自定义口播视频编辑 |

### 搜索
| Skill | 描述 | 独立仓库 |
|---|---|---|
| agentfetch | 浏览器驱动的多引擎搜索和页面读取 | [yuhan-skill/agentfetch](https://github.com/yuhan-skill/agentfetch) |

### 元技能
| Skill | 描述 | 独立仓库 |
|---|---|---|
| write-skills | 写出精简、可预测的 Skills | [Emotion04/write-skills](https://github.com/Emotion04/write-skills) |

## 结构

```text
skills/
├── ai/              # AI 相关
├── frontend/        # 前端界面设计
├── video/           # 视频处理
├── search/          # 搜索工具
└── meta/            # 元技能
```

## 同步

独立仓库的更新通过 `git subtree pull` 同步到本仓库：

```bash
git subtree pull --prefix skills/meta/write-skills https://github.com/Emotion04/write-skills.git main
```

## 许可

MIT
