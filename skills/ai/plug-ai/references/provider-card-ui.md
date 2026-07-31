# Provider Card UI

浮动卡片 —— 供应商切换、API Key 管理、连接测试、配置方案。

> **可选模块。** 如果你只需要后端路由 + API Key 存储，不需要可视化切换界面，可以跳过本章。核心逻辑在 [provider-config.md](provider-config.md)。

## 结构

```
[供应商切换按钮] [设置⚙️]
         │
    ┌────▼────┐
    │ 卡片    │
    │ · 模型选择
    │ · API Key 输入
    │ · 连接测试
    │ · 方案管理
    └─────────┘
```

核心交互：
1. 用户点击触发按钮 → 卡片展开/收起
2. 点击卡片外部 → 卡片关闭
3. 切换供应商 tab → 切换该供应商的 API Key / 模型 / Base URL
4. 保存 Key → 写入 localStorage
5. 测试连接 → 发最小请求确认可用

## 状态

```
perProvider:
  apiKey        — 当前输入的 key
  saved         — 是否已保存（持久化）
  modelVersion  — 选中的模型版本
  baseUrl       — 自定义 endpoint（留空=默认）

global:
  activeProvider  — 当前 tab
  profiles[]      — 已保存的完整配置方案
  showAdvanced    — 主面板 / 进阶面板切换
```

## 定位

卡片必须出现在触发按钮附近。四种常见布局：

```
① 下方弹出（默认）
   [⚙️]
   [Card]  ← absolute, bottom: calc(100% + 8px)

② 悬浮球（固定在角落）
   ┌──────────┐
   │          │
   │  [Card]  │  ← fixed, bottom/right
   └──────────┘

③ 居中弹窗（全屏覆盖时）
         [Card]  ← fixed, inset: 0, center

④ 侧边抽屉
   [Card]         ← fixed, left/right, full height
```

约束：卡片始终在触发元素的**可视范围内**，不飞到屏幕外。

## localStorage

```
key 格式:     app-api-key-{provider}     → key 值
             app-active-model            → 当前供应商
             app-model-version-{provider} → 模型版本
             app-base-url-{provider}     → 自定义 URL
             app-config-profiles         → JSON 数组
```

## API Key 流向

```
Client → Server:
  Header: x-api-key + x-provider

Server 解析:
  1. req.headers["x-api-key"]  ← 客户端优先
  2. process.env.{PROVIDER}_API_KEY  ← 服务端 fallback
  3. 都没有 → 报错

Server 转发:
  fetch(providerUrl, {
    headers: { [authHeader]: prefix + apiKey }
  })
```

## 参考实现

以下是完整 React 组件，拿来即用。其他框架按相同逻辑重写即可。

```tsx
type Provider = "deepseek" | "mimo" | "qwen" | "step";
interface Profile { id: string; name: string; provider: Provider; baseUrl?: string; apiKey: string; model: string; }

const PROVIDERS: { id: Provider; label: string; helpUrl: string }[] = [
  { id: "deepseek", label: "DeepSeek", helpUrl: "https://platform.deepseek.com/api_keys" },
  { id: "mimo", label: "MiMo", helpUrl: "https://platform.xiaomimimo.com/" },
  { id: "qwen", label: "通义千问", helpUrl: "https://dashscope.console.aliyun.com/apiKey" },
  { id: "step", label: "Step Plan", helpUrl: "https://platform.stepfun.com/docs/zh/step-plan/integrations/reasoning-api" },
];

export function ProviderCard({ onClose }: { onClose?: () => void }) {
  const [open, setOpen] = useState(false);
  const [tab, setTab] = useState<Provider>("deepseek");
  const [keys, setKeys] = useState<Record<Provider, string>>({});
  const [saved, setSaved] = useState<Record<Provider, boolean>>({});
  const [showKey, setShowKey] = useState(false);
  const [models, setModels] = useState<Record<Provider, string>>({});
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [advanced, setAdvanced] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  // Init
  useEffect(() => {
    const k: Record<Provider, string> = {} as any, s: Record<Provider, boolean> = {}, m: Record<Provider, string> = {};
    PROVIDERS.forEach(p => {
      k[p.id] = localStorage.getItem(`app-api-key-${p.id}`) || "";
      s[p.id] = !!k[p.id];
      m[p.id] = localStorage.getItem(`app-model-version-${p.id}`) || "";
    });
    setKeys(k); setSaved(s); setModels(m);
    setProfiles(JSON.parse(localStorage.getItem("app-config-profiles") || "[]"));
  }, []);

  // Outside click
  useEffect(() => {
    if (!open) return;
    const h = (e: MouseEvent) => { if (ref.current && !ref.current.contains(e.target as Node)) { setOpen(false); onClose?.(); } };
    document.addEventListener("mousedown", h);
    return () => document.removeEventListener("mousedown", h);
  }, [open]);

  const saveKey = () => {
    localStorage.setItem(`app-api-key-${tab}`, keys[tab]);
    setSaved(p => ({ ...p, [tab]: !!keys[tab] }));
  };

  return (
    <div ref={ref}>
      {/* Trigger */}
      <button onClick={() => setOpen(!open)}>⚙️ 模型设置</button>

      {/* Card */}
      {open && (
        <div className="card">
          {/* Tabs */}
          <div className="tabs">
            {PROVIDERS.map(p => (
              <button key={p.id} className={tab === p.id ? "active" : ""} onClick={() => setTab(p.id)}>
                {p.label}
              </button>
            ))}
          </div>

          {/* Model selector */}
          <label>模型版本</label>
          <div className="model-btns">
            {getModels(tab).map(m => (
              <button key={m.value} className={models[tab] === m.value ? "active" : ""}
                onClick={() => { setModels(p => ({ ...p, [tab]: m.value })); localStorage.setItem(`app-model-version-${tab}`, m.value); }}>
                {m.label}
              </button>
            ))}
          </div>

          {/* API Key */}
          <label>{PROVIDERS.find(p => p.id === tab)!.label} API Key</label>
          <div className="key-row">
            <input type={showKey ? "text" : "password"} value={keys[tab]}
              onChange={e => setKeys(p => ({ ...p, [tab]: e.target.value }))}
              placeholder="sk-..." onKeyDown={e => e.key === "Enter" && saveKey()} />
            <button onClick={() => setShowKey(!showKey)}>{showKey ? "🙈" : "👁"}</button>
            <button onClick={saveKey} disabled={!keys[tab].trim()}>✓</button>
          </div>
          <a href={PROVIDERS.find(p => p.id === tab)!.helpUrl} target="_blank">获取 API Key →</a>

          {/* Status dots */}
          <div className="status">
            {PROVIDERS.map(p => (
              <span key={p.id} className={`dot ${saved[p.id] ? "green" : "gray"}`}>{p.label}</span>
            ))}
            <button onClick={testConnection}>测试连接</button>
          </div>

          {/* Advanced toggle */}
          <button onClick={() => setAdvanced(!advanced)}>{advanced ? "← 返回" : "进阶 →"}</button>
          {advanced && <AdvancedPanel ... />}
        </div>
      )}
    </div>
  );
}
```

样式部分由用户根据自己项目自行处理。逻辑不变。
