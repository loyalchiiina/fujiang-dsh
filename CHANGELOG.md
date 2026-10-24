# 变更记录 · Changelog

## 0.4.5 — DSH 0.2.x 新内核兼容适配

> 本版本由 [@loyalchiiina](https://github.com/loyalchiiina) 基于原作者 [@c3cvld7aag](https://github.com/c3cvld7aag) 的 `0.4.3` 适配，目标内核：DSH `2.0.19-next` / `dsh-app-boot` `0.2.1-rc.2`（cordis `4.0.5`、dsh-tools `0.2.1-rc.2`、schemastery `3.18.5`）。

### 修复

1. **`fujiang_profile` 工具读不到运行时配置（功能失效）**
   - 现象：工具返回的 `injection[].order` 永远是 100 / 200，即使把 `globalOrder` / `reinforceOrder` 改成别的值也不变；`enabled` 恒为 `true`。
   - 原因：原实现 `execute(_args, exec)` 读 `exec.config`。新内核 `dsh-tools` 的 exec 对象由 `createExecution` 构造并 `Object.freeze`，**没有 `config` 字段**，故恒得 `{}`。
   - 修复：把 `defineTool` 搬进 `apply` 作用域，改为 `makeProfileTool(getOptions)` 工厂 + 闭包读取插件 config；同时在输出里新增 `config` 字段回显真实生效值。

2. **`cordis.override.patch.yml` 抹掉 web 人格前缀（配置副作用）**
   - 现象：`dsh-web-app` 的 `system-prompt` 行 `personaPrefix: 'You are a coding agent powered by the {{model}} model.'` 被清空。
   - 原因：内核 `applyEntryPatches` 对 `config` 是**整块替换**而非深合并，原文件只写了 `includeHarnessIdentity: false`，未声明的 `personaPrefix` 就丢了。
   - 修复：改为全量声明 `personaPrefix: ''` + `includeHarnessIdentity: false`，与显式意图一致，不再产生隐式副作用。

3. **`autoApplyOnStart` 是死配置**
   - 原因：Config 里声明、patch 里赋值，但 `apply()` 从不读取。
   - 修复：赋予语义 —— `false` 时本次启动只注册工具与会话投影，不注入任何提示词段落，便于与原厂行为对照。

4. **`enabled: false` 粒度不符描述**
   - 原因：原实现 `if (options.enabled === false) return;` 会连 `fujiang_profile` 工具一起跳过，与 Config 描述「关闭后不注入提示词段落、不注册状态投影，仅保留工具」矛盾。
   - 修复：拆成 `injectPrompt = enabled && autoApplyOnStart !== false`，提示词注入受两者控制；投影注册只看 `enabled`；工具始终注册。

5. **`client.js` 吞异常导致宿主只报笼统错误**
   - 原因：`catch (err) { console.warn(...) }` 把异常吃掉，宿主侧只看到 `loaded without registering "fujiang-armor"`，根因只在控制台。
   - 修复：改 `console.error` + `throw err`，让宿主日志能直接定位。

### 其他

- `version`: `0.4.4` → `0.4.5`
- `package.json` 补 `author` / `contributors` / `repository` / `homepage` / `bugs` 字段，明确署名原作者与适配者
- `dsh.client` 保持 `platform: "web"`、`inject: ["@deepseek-ai/dsh-client-ui-slots", "@deepseek-ai/dsh-client-ui-conversation"]`、`immediately: true`
- `dsh.bundle.patch` 保持 `["./cordis.patch.yml", "./cordis.override.patch.yml"]`

### 验证方式

- `node --check index.js` / `node --check client.js` 均通过
- 用真实内核 `cordis` + `dsh-tools` + `dsh-system-prompt` + `dsh-session-projection` 装配插件，5 个配置分支实测：
  - 默认全开 → 两个段落 order 100 / 200，工具 `fujiang_profile`，投影 `fujiang-armor`
  - `dualLayerInjection: false` → 仅 order 100 段
  - `autoApplyOnStart: false` → 无提示词段，工具与投影仍在
  - `enabled: false` → 无提示词段、无投影，工具仍在
  - `globalOrder: 111, reinforceOrder: 222` → 段落与工具输出同步变为 111 / 222（证明 exec.config 缺陷已修）
- `dsh --profile web --dump-config` 合成配置含 `- id: fujiang-armor` 与 `globalOrder: 100`
- web 端首页 bundle 引用含 `fujiang-armor/client.js`，独立 bundle 可 200 取回且 `__ModuleLoader__.load` 正常

---

## 0.4.3 — 上游原始版本

见 <https://github.com/c3cvld7aag/fujiang-dsh>。