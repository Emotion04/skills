---
name: sizeflow-liquid-glass
description: 液态玻璃视觉设计系统 —— 毛玻璃卡片、莫兰迪渐变背景、鼠标追光、胶囊选择器。Use when user asks for glassmorphism UI, frosted glass design, liquid glass aesthetic, soft blur panels, or Morandi color schemes.
---

# 液态玻璃设计系统

清冷、克制、干净——像透过结霜的玻璃看世界。所有面板都有不同程度的磨砂模糊，低饱和色彩，没有刺眼的阴影。一切轻盈地浮在背景之上。

## 调色盘

```css
深色文字:  #1a2332
灰色文字:  #5a6b7f
主色蓝:    #4f6ef6    深蓝: #3b5ce0
危险红:    #e0556a    成功绿: #2ea87a
```

颜色从不在纯白或纯黑背景上出现——它们始终放在半透明玻璃面板上，所以实际呈现的颜色会比色值略淡，背后的模糊环境光会透过来。

## 玻璃材质等级

核心原理：**越靠近用户的界面，模糊越少、越通透。** 远景重度磨砂，近景轻微模糊。

| 模糊 | 视觉感受 | 适用位置 |
|------|--------|-----|
| `blur(32px)` | 重度磨砂，几乎看不清背后 | 大面积上传区 |
| `blur(20px)` | 明显毛玻璃 | 导航栏、闪屏遮罩 |
| `blur(12px)` | 半透雾面 | 可选卡片、hover 状态 |
| `blur(8px)` | 微透 | 通用面板 |
| `blur(4px)` | 极轻雾 | 输入框、表头 |
| `blur(2px)` | 若有若无 | 迷你胶囊 |

所有玻璃面板共享：`background: rgba(255,255,255,0.1)` + `border: 1px solid rgba(255,255,255,0.2)` + `inset 0 1px 0 rgba(255,255,255,0.5)` 顶部内发光。

## 标准玻璃面板

```css
border-radius: 14px;
background: rgba(255,255,255,.1);
backdrop-filter: blur(8px);
border: 1px solid rgba(255,255,255,.2);
box-shadow: 0 8px 32px rgba(0,0,0,.05), 0 1px 2px rgba(0,0,0,.04),
            inset 0 1px 0 rgba(255,255,255,.5);
```

`inset` 1px 白色高光是玻璃切割面的光学模拟。hover 时阴影带上一丝主色蓝：`rgba(79,110,246,.08)`。

**选中态**：边框变主色蓝 `#4f6ef6`，外围 4px 淡蓝光晕 `rgba(79,110,246,.15)`，轻微放大 `scale(1.03)`。

## 极致液态面板（液体边缘）

在标准面板基础上加两个伪元素：
- **`::before`**：顶部 1px 高光线，左右 10% 位置渐入渐出，白色 85% 透明度
- **`::after`**：`inset: -1px` 渐变边框，`mask-composite: exclude` 只露出边框区域形成折射感

hover 变换：模糊从 32px 降到 12px（磨砂→通透），面板微微上浮 `translateY(-3px)`。这是整个系统中最精致的玻璃效果，用于核心交互区。

## 页面背景

默认：四段渐变，蓝灰色调，固定背景。

```css
background: linear-gradient(135deg, #e8eef5, #dce3ed, #e2e8f2, #d5dfea);
background-attachment: fixed;
```

> **开始实现前，先读 [references/REFERENCE.md](references/REFERENCE.md)**，里面有全部 19 套莫兰迪背景渐变、装饰元素（彩虹文字、像素网格、弹簧动画）、暗色模式玻璃和迷你胶囊模式。

备选背景全部是莫兰迪低饱和渐变（5 个停靠点，125°~160° 角，相邻色差仅 4-8 亮度值）。

## 按钮

```css
border-radius: 6px; padding: 8px 16px; font-size: 13px; font-weight: 500;
transition: all .15s;
```

- **实心蓝底**：`background: #4f6ef6; color: #fff` → hover `#3b5ce0`
- **白色描边**：`background: #fff; border: 1px solid #4f6ef6; color: #4f6ef6` → hover `#f0f4ff`
- **小号**：padding 4px/10px，字号 12px

## 导航胶囊

浮动的圆角条，内部等宽文字选项，选中项被亮白色方块高亮包围。整条有轻微磨砂 + 淡白描边。高亮方块带弹簧动效（`cubic-bezier(.34,1.56,.64,1)`）在选项间滑动——先过冲再回弹。鼠标在胶囊内移动时，暖色柔光光球跟随光标。

## 鼠标光晕

两个固定定位的径向渐变圆跟随光标。主光：220px，白色→透明，快速跟随（0.6s）。环境光：340px，overlay 混合模式，慢速跟随（1.2s）。形成光标周围的柔和光场。

## 文字排版

```css
font: 14px/1.6 -apple-system, "Microsoft YaHei", "PingFang SC", sans-serif;
```

标题：18px/700，副标题：15px/700。图标用 emoji 或 Unicode，不用 SVG 图标库。空心文字徽章：彩色文字 12px，放在 20px 圆角药丸里，背景用文字色的 12-15% 透明度。
