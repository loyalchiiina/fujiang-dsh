# 适配说明 · Adaptation Notice

## 一句话

本仓库是 [c3cvld7aag/fujiang-dsh](https://github.com/c3cvld7aag/fujiang-dsh)（原始版本 `0.4.3`）的 fork，
由 [@loyalchiiina](https://github.com/loyalchiiina) 适配 **DSH 新内核 `0.2.1-rc.2`**，版本推进至 `0.4.5`。

## 为什么需要适配

原作者发布 `0.4.3` 时的内核版本线较早。当前 DSH 桌面端（`2.0.19-next`）内置的内核包为：

| 包 | 版本 |
| --- | --- |
| `@deepseek-ai/dsh-app-boot` | `0.2.1-rc.2` |
| `@deepseek-ai/cordis` | `4.0.5` |
| `@deepseek-ai/dsh-tools` | `0.2.1-rc.2` |
| `@deepseek-ai/schemastery` | `3.18.5` |
| `@deepseek-ai/dsh-session-projection` | `0.2.1-rc.2` |

`0.4.3` 在该内核上能加载、提示词也能注入，但存在 5 处契约/语义偏差，详见 [CHANGELOG.md](CHANGELOG.md)。
最严重的一处是 `fujiang_profile` 工具读 `exec.config` —— 新内核的 exec 对象没有这个字段，导致工具返回的
排序值永远硬编码，配置项形同虚设。第二严重的是 override patch 的 `config` 整块替换语义，
会静默抹掉 `dsh-web-app` 的 `personaPrefix`。

## 改了什么 / 没改什么

**改了**：与内核 API 契约不符的 5 处实现细节 + 版本号 + package.json 署名元数据。
**没改**：提示词内容（`prompts/*.md` 三份 4772 B 原样保留）、判定评分逻辑、UI 呈现、
目录结构、安装/卸载脚本、LICENSE。

## 内核侧的关键事实（供后续维护者参考）

1. **exec 对象无 `config`**：`dsh-tools` 的 `createExecution` 构造 exec 后 `Object.freeze`，插件配置只能通过
   `apply(ctx, config)` 的闭包拿到，不能从工具 execute 的第二个参数取。
2. **patch 的 `config` 是整块替换**：`applyEntryPatches` 直接赋值，不做深合并。覆盖某行的 config 时，
   必须把该行**全部**键写全，否则未写的键会被丢弃。
3. **`ctx.effect(fn, label)` 返回 disposer**；`ctx.tools.register` 返回 disposer；
   `ctx.systemPrompt.section({name, order, text})` 中 `name` 在同一 layer 内必须唯一。
4. **`{{变量}}` 插值只支持 `{{model}}` 与 `{{provider}}`**。提示词里其它 `{{xxx}}` 会在每次模型请求时抛错，
   插件已用 `SAFE_VARIABLES = /\{\{(?!(?:model|provider)\}\})/g` 把它们转义成 `{ {`。
5. **挂载必须四件套齐全**：profile 的 `dependencies` 加 link、`dsh.profile.bundles` 加裸包名、
   `node_modules/<name>` 建 Junction、`pnpm-lock.yaml` importer 补条目。
   少任何一项宿主可能**静默跳过、零 warn 零 error**。

## 许可

原始代码、提示词、设计的版权归原作者 [@c3cvld7aag](https://github.com/c3cvld7aag) 所有。
本 fork 依原项目 LICENSE（`CC-BY-NC-SA-4.0`）条款分发。若原作者认为本 fork 有任何不当之处，
请在本仓库提 Issue，我会立即处理。