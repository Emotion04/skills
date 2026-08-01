---
name: floating-glow-tabbar
description: 移动端底部导航栏，带暖白色触控追踪光球、呼吸收缩动画和拖拽切换导航。浮动胶囊外形，玻璃拟态背景模糊。Use when user wants a mobile tab bar, bottom navigation, touch glow effect, floating nav, glass navigation bar, or interactive tab animation.
---

# 浮动光球 TabBar

移动端底部导航栏，带 4500K 暖白色触控追踪光球。浮动胶囊外形 + 玻璃拟态背景模糊 + 指数缓动追踪 + 呼吸收缩动画 + 拖拽切换导航。

## 视觉效果

```
┌──────────────────────────────────────────────────┐
│          (页面内容)                                │
│  ┌──────────────────────────────────────────┐    │
│  │  ✦ 光球（200px，暖白，                    │    │
│  │    lerp 追踪，约束在 bar 内）               │    │
│  │  ── 活跃指示器（贝塞尔回弹）                │    │
│  │  [Tab1]  [Tab2]  [Tab3]  [Tab4]          │    │
│  └── 左右 12px 边距，底部安全区 ──────────────┘    │
└──────────────────────────────────────────────────┘
```

**关键视觉**：胶囊 `border-radius: 28px`，玻璃 `rgba(255,255,255,0.16)` + `backdrop-filter: blur(6px)`，光球 200px 暖白径向渐变，`mix-blend-mode: plus-lighter`。

## 核心架构：分层指针捕获

Tab 链接元素会拦截指针事件，破坏触控追踪。解决方案：胶囊内部分层。

| 层 | z-index | 作用 |
|--------|---------|---------|
| 捕获层 | 30 | 透明 `touch-action: none` 的 div，处理所有指针事件 |
| 光球层 | 25 | 绝对定位径向渐变，lerp 追踪 |
| 指示器 | 20 | 横向条，显示激活 Tab 位置 |
| Tab 导航 | 10 | 导航项，所有子元素 `pointer-events: none` |

捕获层提供干净无过滤的坐标。Tab 点击通过计算手指抬起时的 X 坐标落在哪个 Tab 索引来模拟。

## 指针处理

**按下**：客户端坐标 → bar 相对坐标 → 约束在边界内 → 重置渐隐状态 → 渲染位置初始化到手指位置 → 启动动画循环。不要立即激活拖拽指示器（防止点击闪烁）。

**移动**：更新光球目标（lerp 循环追踪）。仅当手指移动超过 bar 宽度的 1% 时才激活拖拽指示器。追踪手指悬停在哪个 Tab 上。

**抬起**：取消拖拽。设置 `fading = true` → CSS 收缩动画启动。2100ms 后清理：隐藏光球，停止循环。导航到手指所在的 Tab（如果与当前不同）。

**边界约束**：手指拖出 bar 外时光球保持在边缘，不飞出屏幕。

## 指数缓动追踪

```
LERP = 0.10，每帧：
  renderX += (targetX - renderX) * 0.10
  renderY += (targetY - renderY) * 0.10
```

60fps 下：~63% 在 10 帧达成（167ms），~95% 在 30 帧（500ms），视觉上 ~380ms 稳定。用 `requestAnimationFrame` + inline style 修改——留在合成线程，不触发布局。

## 呼吸收缩动画（2 秒）

```css
@keyframes orb-breathe-out {
  0%   { transform: scale(1);    opacity: 1;   filter: blur(8px)  brightness(1); }
  10%  { transform: scale(1.08); opacity: 0.9; filter: blur(9px)  brightness(1.05); }
  100% { transform: scale(0.05); opacity: 0;   filter: blur(20px) brightness(1.8); }
}
```

0-10%：短暂吸气（微微变大）。10-100%：呼气至消失（收缩、模糊扩散、变亮）。`forwards` 保持最终状态。通过 `pointerup` 时添加 `.glow-shrink` class 触发。

## 玻璃参数

| 级别 | 背景 | 背景模糊 | Tab 文字 |
|-------|-----------|---------------|----------|
| 低（无效果） | `#fff` 纯色 | 无 | gray-500 |
| 中/高 | `rgba(255,255,255,0.16)` | `blur(6px)` | `#000` |
| 暗色模式 | `rgba(17,24,39,0.16)` | `blur(6px)` | gray-300 |

## 快速开始

> **开始实现前，先读 [references/REFERENCE.md](references/REFERENCE.md)**，里面有完整的 4500K CSS 渐变配方、可调光球参数、拖拽指示器细节、指针处理伪代码和常见陷阱。

参考实现：`FloatingGlowTabBar.vue`——Vue 3 + Tailwind CSS v4，生产可用。

生成 React/Svelte/SwiftUI/Vanilla JS 版本：把本 SKILL.md 给 AI，说"用 [框架] 实现 FloatingGlowTabBar"。
