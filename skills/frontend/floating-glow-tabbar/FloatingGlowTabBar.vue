<template>
  <!-- 悬浮椭圆底栏：不接触屏幕边缘，大圆角 -->
  <div
    ref="navRef"
    class="fixed bottom-0 left-0 right-0 z-50 px-3 select-none"
    style="padding-bottom: calc(0.75rem + env(safe-area-inset-bottom, 0px))"
  >
    <!-- 光球层（被 overflow-hidden 裁剪在圆角内） -->
    <div class="relative rounded-[28px] overflow-hidden shadow-xl shadow-black/5" :class="glassClass">
      <!-- 光球 -->
      <div class="absolute inset-0 pointer-events-none z-25">
        <div
          v-show="orb.visible"
          class="absolute glow-orb"
          :class="{ 'glow-shrink': orb.fading }"
          :style="orbStyle"
        ></div>
      </div>

      <!-- 指示器 -->
      <div
        v-if="dragActive"
        class="absolute top-1 h-0.5 rounded-full bg-white/80 pointer-events-none z-20"
        :style="dragIndicatorStyle"
      ></div>
      <div
        v-else
        class="absolute top-1 h-0.5 rounded-full bg-white/80 pointer-events-none z-20"
        :style="indicatorStyle"
        style="transition: left 0.5s cubic-bezier(0.34, 1.56, 0.64, 1), width 0.5s cubic-bezier(0.34, 1.56, 0.64, 1);"
      ></div>

      <!-- 指针捕获层：只响应 pointerup，不响应 leave/cancel -->
      <div
        class="absolute inset-0 z-30 touch-none"
        @pointerdown="onDown"
        @pointermove="onMove"
        @pointerup="onUp"
      ></div>

      <!-- Tab 按钮 -->
      <nav class="relative flex items-center justify-around py-2 z-10">
        <div
          v-for="(tab, idx) in visibleTabs"
          :key="tab.path"
          class="relative flex flex-col items-center justify-center gap-0.5 py-1 px-1 min-w-0 flex-1 transition-colors duration-200"
          :class="tabTextClass(tab)"
        >
          <span class="text-xl leading-none pointer-events-none" v-html="tab.icon"></span>
          <span class="text-[10px] leading-tight font-medium truncate max-w-full pointer-events-none">{{ tab.label }}</span>
        </div>
      </nav>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, reactive, inject, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useGlass } from '@/composables/useGlass'

const route = useRoute()
const router = useRouter()
const effectsLevel = inject('effectsLevel', ref('medium'))
const colorMode = inject('colorMode', ref('light'))
const navRef = ref(null)
let animFrame = null
const { tabBarClass } = useGlass()

const glassClass = computed(() => {
  if (colorMode.value === 'dark') return 'bg-gray-900/16 backdrop-blur-[6px]'
  return tabBarClass.value
})

const role = computed(() => localStorage.getItem('user_role') || 'viewer')

const allTabs = [
  { path: '/dashboard', label: 'AI助手',
    icon: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-6 h-6"><path d="M6 17.25L3.75 19.5V6.75C3.75 5.51 4.76 4.5 6 4.5H18C19.24 4.5 20.25 5.51 20.25 6.75V15.75C20.25 16.99 19.24 18 18 18H6.9"/><path d="M8.25 9H15.75"/><path d="M8.25 12.75H13.5"/></svg>',
    roles: ['admin', 'operator', 'viewer'] },
  { path: '/data-center', label: '数据中心',
    icon: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-6 h-6"><path d="M6.75 18.75H17.25"/><path d="M8.25 16.5V11.25"/><path d="M12 16.5V8.25"/><path d="M15.75 16.5V5.25"/><path d="M4.5 4.5V18C4.5 18.41 4.84 18.75 5.25 18.75H19.5"/></svg>',
    roles: ['admin', 'operator', 'viewer'] },
  { path: '/operation-assistant', label: '运营助手',
    icon: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-6 h-6"><path d="M8.25 8.25C8.25 6.59 9.59 5.25 11.25 5.25C12.01 5.25 12.71 5.53 13.25 6"/><path d="M10.75 18.08C10.75 19.14 11.61 20 12.67 20H11.33C12.39 20 13.25 19.14 13.25 18.08V11.75C13.25 11.06 12.69 10.5 12 10.5C11.31 10.5 10.75 11.06 10.75 11.75V18.08Z"/></svg>',
    roles: ['admin', 'operator'] },
  { path: '/admin-center', label: '管理中心',
    icon: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-6 h-6"><path d="M12 3.75L18.75 6.75V11.58C18.75 15.52 15.92 19.03 12 19.88C8.08 19.03 5.25 15.52 5.25 11.58V6.75L12 3.75Z"/><path d="M9.75 11.75L11.25 13.25L14.75 9.75"/></svg>',
    roles: ['admin'] },
]

const visibleTabs = computed(() => allTabs.filter(t => t.roles.includes(role.value)))

function tabTextClass(tab) {
  const active = route.path === tab.path && !dragActive.value
  if (active) return 'text-emerald-500'
  return colorMode.value === 'dark' ? 'text-gray-300' : 'text-black'
}

// ── 光球（overflow-hidden 自动裁剪） ──
const orb = reactive({ visible: false, fading: false, renderX: 0, renderY: 0, targetX: 0, targetY: 0 })

const orbStyle = computed(() => ({
  left: `${orb.renderX}px`, top: `${orb.renderY}px`,
  width: '200px', height: '200px',
  background: `radial-gradient(circle at center,
    rgba(255,255,255,1) 0%, rgba(255,253,250,.9) 5%, rgba(255,251,245,.6) 12%,
    rgba(255,249,240,.3) 25%, rgba(255,247,235,.1) 45%, transparent 65%)`,
  borderRadius: '50%',
  filter: 'blur(8px)',
  mixBlendMode: 'plus-lighter',
  opacity: orb.visible ? 1 : 0,
  transition: 'opacity .15s ease-out',
}))

function getBarPos(e) {
  if (!navRef.value) return { x: 0, y: 0 }
  const r = navRef.value.querySelector('.rounded-\\[28px\\]')?.getBoundingClientRect() || navRef.value.getBoundingClientRect()
  return { x: e.clientX - r.left, y: e.clientY - r.top }
}

function clampToBar(pos) {
  if (!navRef.value) return pos
  const el = navRef.value.querySelector('.rounded-\\[28px\\]')
  const r = el ? el.getBoundingClientRect() : navRef.value.getBoundingClientRect()
  const w = r.width; const h = r.height
  return { x: Math.max(0, Math.min(pos.x, w)), y: Math.max(0, Math.min(pos.y, h)) }
}

function getTabIdxAt(x) {
  if (!navRef.value) return -1
  const el = navRef.value.querySelector('.rounded-\\[28px\\]')
  const w = el ? el.getBoundingClientRect().width : navRef.value.offsetWidth
  const c = visibleTabs.value.length
  return c ? Math.max(0, Math.min(c - 1, Math.floor((x / w) * c))) : -1
}

const LERP = 0.10

function startLoop() {
  if (animFrame) return
  function tick() {
    orb.renderX += (orb.targetX - orb.renderX) * LERP
    orb.renderY += (orb.targetY - orb.renderY) * LERP
    animFrame = requestAnimationFrame(tick)
  }
  animFrame = requestAnimationFrame(tick)
}
function stopLoop() {
  if (animFrame) { cancelAnimationFrame(animFrame); animFrame = null }
}
// 页面隐藏时停止循环，切回时恢复
function onVisibility() {
  if (document.hidden) { stopLoop(); orb.visible = false }
}
document.addEventListener('visibilitychange', onVisibility)
onUnmounted(() => { stopLoop(); document.removeEventListener('visibilitychange', onVisibility) })

// ── 拖拽 ──
const dragActive = ref(false)
const dragX = ref(0)
const dragTargetIdx = ref(-1)

const dragIndicatorStyle = computed(() => {
  const c = visibleTabs.value.length
  if (!c) return { display: 'none' }
  const w = 100 / c
  return { left: `${dragX.value}%`, width: `${w}%`, transform: 'translateX(-50%)' }
})

function onDown(e) {
  const p = clampToBar(getBarPos(e))
  orb.fading = false; orb.visible = true
  orb.targetX = p.x; orb.renderX = p.x
  orb.targetY = p.y; orb.renderY = p.y
  startLoop()
  // 不立即激活拖拽指示器——等 onMove 确认有位移再显示
  prevDragX = null
  dragTargetIdx.value = getTabIdxAt(p.x)
}

let prevDragX = null

function onMove(e) {
  const p = clampToBar(getBarPos(e))
  orb.targetX = p.x; orb.targetY = p.y
  // 有实际位移时才激活拖拽指示器
  if (!dragActive.value && prevDragX !== null) {
    const el = navRef.value?.querySelector('.rounded-\\[28px\\]')
    const w = el ? el.getBoundingClientRect().width : navRef.value?.offsetWidth || 1
    const currPct = (p.x / w) * 100
    if (Math.abs(currPct - prevDragX) > 1) {
      dragActive.value = true
    }
  }
  const el = navRef.value?.querySelector('.rounded-\\[28px\\]')
  const w = el ? el.getBoundingClientRect().width : navRef.value?.offsetWidth || 1
  const currPct = (p.x / w) * 100
  prevDragX = currPct
  if (dragActive.value) {
    dragX.value = currPct
  }
  dragTargetIdx.value = getTabIdxAt(p.x)
}

function onUp() {
  dragActive.value = false
  orb.fading = true
  setTimeout(() => { orb.visible = false; orb.fading = false; stopLoop() }, 2100)
  const idx = dragTargetIdx.value
  if (idx >= 0 && idx < visibleTabs.value.length) {
    const p = visibleTabs.value[idx].path
    if (p !== route.path) setTimeout(() => router.push(p), 120)
  }
}

const activeIdx = computed(() => visibleTabs.value.findIndex(t => t.path === route.path))
const indicatorStyle = computed(() => {
  if (activeIdx.value < 0 || !visibleTabs.value.length) return { display: 'none' }
  const c = visibleTabs.value.length; const w = 100 / c
  return { left: `${activeIdx.value * w + w / 2}%`, width: `calc(${w}% - 16px)`, transform: 'translateX(-50%)' }
})
</script>

<style scoped>
.glow-orb {
  will-change: left, top;
  transform: translate(-50%, -50%);
}
.glow-shrink {
  animation: orb-breathe-out 2s cubic-bezier(.4,0,.2,1) forwards;
}
@keyframes orb-breathe-out {
  0%   { transform: translate(-50%,-50%) scale(1);    opacity: 1;   filter: blur(8px) brightness(1); }
  10%  { transform: translate(-50%,-50%) scale(1.08); opacity: .9;  filter: blur(9px) brightness(1.05); }
  100% { transform: translate(-50%,-50%) scale(.05);  opacity: 0;   filter: blur(20px) brightness(1.8); }
}
</style>
