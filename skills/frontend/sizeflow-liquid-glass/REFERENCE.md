# Reference: Liquid Glass Design System

## 19 Morandi Background Gradients

```
晨雾: linear-gradient(155deg, #c9d9e0, #b8c9d4, #d4cfd8, #c2bbc9, #d5dbe3)
苔色: linear-gradient(140deg, #c5cdc0, #bcc4b6, #d4cfc2, #c9c5b8, #dbd7ce)
蓟花: linear-gradient(130deg, #cbc5d4, #d1c9d9, #c4becb, #dcd5e0, #c8c3cf)
贝母: radial-gradient(ellipse at 40% 30%, #e4dcd5, #dbd2ca, #e0d9d2, #d6cec7, #e8e2dc)
薄暮: linear-gradient(160deg, #c0c7d4, #c8c5d2, #d4ccd6, #cbc5d0, #cfcdd9)
烟柳: linear-gradient(145deg, #ccd5ca, #c8d2c5, #d5d9cf, #cbd2c6, #d8ded3)
石楠: linear-gradient(125deg, #d0cbd6, #c9c2d1, #d6ced8, #ccc5d3, #d9d3dc)
流沙: linear-gradient(150deg, #dcd5cb, #d7cfc4, #e0d9cf, #d9d1c7, #e4ddd4)
燕麦: linear-gradient(135deg, #e2d9c8, #ddd3c0, #e8dfd0, #dcd2c2, #e5ddd0)
青石: linear-gradient(148deg, #c8cdc8, #c2c7c2, #cdd2cc, #c4c9c4, #d0d5cf)
薰衣: linear-gradient(142deg, #d0c9d9, #cbc4d5, #d6d0de, #cec7d7, #d9d3e2)
鼠尾: linear-gradient(138deg, #c8cfc0, #c2cab9, #cdd4c5, #c5cdbc, #d0d7c8)
板岩: linear-gradient(155deg, #bbc0c8, #b5bac3, #c1c5cd, #b8bdc5, #c4c8d0)
尘玫: linear-gradient(132deg, #d6c9cb, #d1c3c6, #dbcfd1, #d3c6c9, #ded3d5)
象牙: linear-gradient(145deg, #e8e2d8, #e3dcd0, #ebe6dc, #e5ded4, #eee9e0)
卷云: linear-gradient(160deg, #dde1e4, #d7dbe0, #e2e5e8, #d9dde2, #e5e8eb)
亚麻: linear-gradient(140deg, #ddd6c5, #d8d0be, #e2dcc9, #dad3c2, #e5dfce)
锡灰: linear-gradient(152deg, #c5c5c5, #bfbfbf, #cacaca, #c2c2c2, #cdcdcd)
苔痕: linear-gradient(143deg, #c4ccba, #bec6b3, #c9d1bf, #c1c9b6, #ccd4c2)
```

## Decorative Elements

### Rainbow Gradient Text

Background clipped to text (`background-clip: text`), 6-color gradient cycling every 3s: dark red → gold → emerald → sky blue → violet → rose.

### Pixel Grid Background

```css
background: repeating-linear-gradient(0deg, transparent, transparent 3px, rgba(79,110,246,.04) 3px, rgba(79,110,246,.04) 4px),
            repeating-linear-gradient(90deg, transparent, transparent 3px, rgba(79,110,246,.04) 3px, rgba(79,110,246,.04) 4px);
```

Laid under panels as a subtle texture.

### Spring Animation

```css
transition: all 0.4s cubic-bezier(.34,1.56,.64,1);
```

For popup elements (badges, tooltips) — overshoots then settles back.

## Mini Capsules

Tiny rounded bars (`border-radius: 20px`), monospace numbers inside, nearly transparent background (`rgba(255,255,255,.05)`), only 2px blur, 70% opacity for the whole bar. Hover reveals a semi-transparent white stats panel below.

## Two-Column Layout

`flex:2` + `flex:1`, 16px gap. Left: panel stack. Right: action area. ≤900px: stack vertically. Panels separated by `margin-bottom: 18px` — no dividers.

## Dark Mode Glass

| Element | Background | Text |
|---------|-----------|------|
| Panel | `rgba(17,24,39,0.16)` | gray-300 |
| Backdrop | `blur(6px)` | — |
