# 黑白数字档案馆 · 设计参考

## 1. 风格定义

关键词：**数字档案馆、编辑部排版、私人博物馆、文学化数据展示、硬朗极简**。

它不是常规后台，也不是圆润 SaaS 仪表盘。页面以内容时间性为主线，通过衬线大标题、等宽日期、发丝线和留白建立秩序。界面应当安静，交互精致但不抢戏。

## 2. 设计 Token

```css
:root {
  --bg: #fff;
  --fg: #0a0a0a;
  --muted: #767676;
  --faint: #f6f6f6;
  --line: #e6e6e6;
  --line-2: #d4d4d4;
  --shadow: 0 24px 60px -20px rgb(0 0 0 / 28%);
  --font-serif: "Noto Serif SC", Georgia, "Songti SC", serif;
  --font-sans: "Noto Sans SC", system-ui, "PingFang SC", sans-serif;
  --font-mono: "SFMono-Regular", "Cascadia Code", Consolas, monospace;
  --content-width: 940px;
  --ease: cubic-bezier(.2, .7, .2, 1);
}

[data-theme="dark"] {
  --bg: #0b0b0c;
  --fg: #f1f1f1;
  --muted: #8b8b8b;
  --faint: #161618;
  --line: #262629;
  --line-2: #34343a;
  --shadow: 0 24px 60px -20px rgb(0 0 0 / 70%);
}
```

规则：组件只引用 token。除图片灯箱遮罩外，不在组件中散落色值。

## 3. 排版角色

| 内容 | 字体 | 典型表现 |
|---|---|---|
| Hero、年份、文章标题、长文 | serif | 轻至中等字重，宽松行高 |
| 导航、按钮、标签、说明 | sans | 清晰克制，不用粗黑字 |
| 日期、数字、计数、元信息 | mono | 小字号、低对比、稳定列宽 |

Hero 可使用 `clamp(40px, 9vw, 82px)`；正文 14-17px；章节标签约 12px，并使用 `.18-.22em` 字距。不要把所有中文都做成稀疏大字距。

## 4. 页面骨架

```text
┌ sticky 顶栏：品牌                    搜索  设置  主题 ┐
├───────────────────────────────────────────────┤
│                                                │
│             超大衬线主题标题                    │
│          一句档案说明 · 时间范围                │
│                                                │
├ 概览 ── 时间轴 ── 内容 ── 长文 ── 分析 ────────┤
│               active underline                 │
│                                                │
│                 当前视图内容                    │
│                                                │
├───────────────────────────────────────────────┤
│                    元信息页脚                   │
└───────────────────────────────────────────────┘
```

顶栏与 Tab 可 sticky；两者使用半透明背景和轻量 `backdrop-filter`，底部保留 1px 边线。Hero 负责情绪，内容区负责秩序。

## 5. Tab 切换

### 视觉

- Tab 居中横排，文字常态 muted，激活态 fg + 500 字重。
- 导航底部一条通栏发丝线。
- 激活指示器是 2px 实线，宽度与按钮实际宽度一致。
- 切换时视图 `opacity 0→1`，并由 `translateY(8px)` 回到原位。

### 行为

```js
function moveUnderline() {
  const active = document.querySelector('.tab.is-active');
  const line = document.querySelector('.tab-underline');
  if (!active || !line) return;
  line.style.left = `${active.offsetLeft}px`;
  line.style.width = `${active.offsetWidth}px`;
}
```

在切换、窗口 resize、字体加载完成后调用。视图用 `hidden` 或路由切换；同步 URL hash，使刷新和返回键行为合理。窄屏 Tab 过多时优先允许横向滚动，不强行挤压文字。

## 6. 时间轴

### 结构

- 按年份分组，年份标题 sticky。
- 年份标题：serif 30px；记录数：mono 12px；余下空间是一条横线。
- 每条记录使用 `grid-template-columns: 60px 22px 1fr`。
- 日期右对齐；中栏为 1px 轨道；正文留足行间距。
- 普通记录用 7px 实心点；文章记录用 9px 空心点，建立内容类型差异。

### 内容形态

短内容直接展示，长文以小型硬边卡片嵌入轴线。卡片 hover 只增强边框并横移 2px。不要给每个普通时间点都套卡片。

## 7. 概览与列表

- 叙事引言居中，serif 18-23px，像展览前言。
- 统计区可四等分，但整个网格只有一个外框，单元之间用线分隔，不做四张漂浮卡。
- 年度图用单色实心/空心条区分数据系列，数字放 mono 列。
- 内容列表按年份分组，以底边线和日期列建立节奏。
- 空态可用 `∅`，但保持安静，不配大型插画。

## 8. 控件语言

- 图标按钮：34×34px，1px 边框，999px 圆角。
- Chip：`padding: 5px 13px`，mono 12.5px；激活态黑白反转。
- 普通面板：2-3px 圆角；禁止常见的 12/16/24px 大圆角。
- 阴影只用于阅读器、设置面板、灯箱等浮层。
- 图标首选简洁 SVG `stroke="currentColor"`，不混用多套图标风格。
- focus-visible 至少应有明确 outline 或前景色边框，不可只设计 hover。

## 9. 动效

```css
.view { animation: fade .5s var(--ease); }
@keyframes fade {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: none; }
}

.panel { animation: pop .4s var(--ease); }
@keyframes pop {
  from { opacity: 0; transform: translateY(16px) scale(.98); }
  to { opacity: 1; transform: none; }
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: .01ms !important;
    transition-duration: .01ms !important;
    scroll-behavior: auto !important;
  }
}
```

动效优先使用 opacity 与 transform。不要使用大幅弹簧、发光追踪、粒子或持续漂浮动画。

## 10. 响应式

以 720px 为核心断点：

- 页面横向 padding 24→16px。
- 品牌可隐藏文字但保留标记。
- 统计区 4→2 列。
- 时间轴日期栏 60→48px。
- 文章列表由三列降为单列并隐藏箭头。
- 阅读浮层减小 padding，最大高度提升到约 92vh。
- 复杂双栏模块变单栏。
- Tab 若超宽，应提供 `overflow-x: auto` 与可见焦点，而非溢出屏幕。

## 11. 应避免的偏差

- 彩色渐变、霓虹光晕、玻璃卡片海洋。
- 每个模块都有独立圆角、阴影、背景的 SaaS dashboard 感。
- 大量 emoji 当图标；少量语义符号可用，但需克制。
- 所有文字都居中；Hero 居中，内容列表应左对齐。
- 为“高级感”压低对比到无法阅读。
- 只做视觉稿，不实现 hash、键盘、focus、空态和移动端行为。

## 12. 精简版提示词

```text
制作一个黑白极简的数字档案馆网页：中文编辑部排版，大量留白，衬线大标题，
无衬线 UI，等宽日期与数据；sticky 顶栏和 sticky Tab，Tab 有测量真实宽度的滑动下划线；
提供叙事概览、单色统计、按年分组的纵向时间轴、归档列表和阅读浮层。
只用语义化黑白灰 token、1px 发丝线、胶囊控件和 2-3px 硬圆角；阴影仅用于浮层。
交互克制流畅，支持暗色、hash、键盘、reduced motion 与移动端。避免彩色渐变、卡片海洋、
厚重阴影和炫技动画。先给信息架构与 token，再输出完整可运行代码。
```
