# Reference: Floating Glow TabBar

## Glow Orb: 4500K Warm-White CSS Gradient

```css
width: 200px; height: 200px;
border-radius: 50%;
mix-blend-mode: plus-lighter;
filter: blur(8px);
transform: translate(-50%, -50%);
background: radial-gradient(circle at center,
  rgba(255,255,255,1)     0%,   /* pure white center */
  rgba(255,253,250,0.9)   5%,   /* barely warm */
  rgba(255,251,245,0.6)  12%,
  rgba(255,249,240,0.3)  25%,
  rgba(255,247,235,0.1)  45%,
  transparent             65%
);
```

4500K = neutral daylight white. Pure `rgb(255,255,255)` feels cold — warm undertones (255,251,245) make it organic.

## Tunable Orb Parameters

| Parameter | Default | Note |
|-----------|---------|------|
| Diameter | 200px | Larger = softer glow |
| LERP | 0.10 | 0.05 = floaty, 0.20 = snappy |
| Center color | `rgb(255,255,255)` | Shift R/G for warm/cool |
| Edge blur | 8px | Keep 6-10px for crisp core |
| Shrink duration | 2000ms | Longer = more dramatic |
| Blend mode | `plus-lighter` | Works over any background |

## Drag-to-Switch Indicator

### During drag (active, following finger)
```css
/* indicator position = finger X as percentage of bar width */
left: X%; width: calc(100%/tabCount - 16px);
```

### After release (static, Bezier snap)
```css
transition: left 0.5s cubic-bezier(0.34, 1.56, 0.64, 1),
            width 0.5s cubic-bezier(0.34, 1.56, 0.64, 1);
```
`cubic-bezier(0.34, 1.56, 0.64, 1)` overshoots then settles — a spring-like bounce.

## Pointer Handling Pseudocode

```
onDown:
  1. Convert client coords → bar-relative
  2. Clamp to bar bounds
  3. Reset fading, set visible, init renderX/Y = targetX/Y = clamped pos
  4. Start animation loop
  5. Don't activate drag indicator yet (prevents click flash)

onMove:
  1. Update orb target (lerp loop chases it)
  2. Only activate drag indicator if finger moved >1% of bar width
  3. Track which tab finger is over

onUp:
  1. Deactivate drag
  2. Set fading = true → CSS animation kicks in
  3. After 2100ms cleanup: hide orb, stop loop
  4. Navigate to tab under finger (if different from current)

clampToBar(pos, barRect):
  return {
    x: max(0, min(pos.x, barRect.width)),
    y: max(0, min(pos.y, barRect.height))
  }
```

## Common Pitfalls

1. **Orb invisible**: z-index too low. Orb must be above bar background but below capture layer.
2. **Orb clipped wrong**: Pill container has `overflow: hidden` — good. Orb's direct parent MUST have `overflow: visible`.
3. **Tab links steal touches**: All tab children need `pointer-events: none`.
4. **Click flash**: Don't show drag indicator on `pointerdown` — only after `pointermove` exceeds 1% threshold.
5. **Glass doesn't blur**: Background must be semi-transparent. Solid `#fff` shows zero blur. Minimum 5% opacity.
6. **Memory leak**: Stop the animation loop when page is hidden (`visibilitychange` event). Clean up in `onUnmounted`.

## Dependencies

- **Runtime**: None beyond the target framework (Vue/React/Svelte)
- **CSS**: `backdrop-filter` support (all modern browsers, iOS 9+)
- **No npm packages required**
