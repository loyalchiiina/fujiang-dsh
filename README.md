# 富江DSH完美破甲 · Fujiang Armor

**中文** | **English** — 本文档全文双语：每节先中文，紧跟英文（`EN:` 起头）。<br>
This document is fully bilingual: Chinese first, English follows each section (marked `EN:`).

---

## 一、简介 · Introduction

### 中文

富江破甲是一个用于 DSH（DeepSeek Harness）的**本地插件**，内置提示词规则，提供 Windows 一键注入与一键卸载。插件加载后，会在对话输入框上方显示「富江破甲已激活」。

- 当前版本：`0.4.5`
- 插件标识：`fujiang-armor`
- 适配内核：DSH `2.0.19-next` / `dsh-app-boot` `0.2.1-rc.2`（cordis `4.0.5`、dsh-tools `0.2.1-rc.2`、schemastery `3.18.5`）
- 分发方式：**仅 GitHub Release 提供安装包，未发布到 npm**

### EN:

Fujiang Armor is a **local plugin** for DSH (DeepSeek Harness). It ships built-in prompt rules and provides one-click install/uninstall on Windows. Once loaded, it shows an "Fujiang Armor activated" badge above the chat input box.

- Current version: `0.4.5`
- Plugin id: `fujiang-armor`
- Target kernel: DSH `2.0.19-next` / `dsh-app-boot` `0.2.1-rc.2` (cordis `4.0.5`, dsh-tools `0.2.1-rc.2`, schemastery `3.18.5`)
- Distribution: **GitHub Releases only — not published to npm**

---

## 二、原作者与来源 · Credits

### 中文

- **原作者：[@c3cvld7aag](https://github.com/c3cvld7aag)**
- **原项目：https://github.com/c3cvld7aag/fujiang-dsh**
- 原始版本：`0.4.3`

本仓库是原项目的 **fork**，由 [@loyalchiiina](https://github.com/loyalchiiina) 针对 **DSH 新内核（`0.2.1-rc.2`）完成了兼容性适配**，版本号推进到 `0.4.5`。

上游 `0.4.3` 在旧内核上工作正常，但在新内核上存在 5 处问题（其中 2 处会导致功能失效或配置副作用），详见 [CHANGELOG.md](CHANGELOG.md) 与 [ADAPTATION-NOTICE.md](ADAPTATION-NOTICE.md)。所有修改均保持原插件的设计意图与目录结构，仅修正与内核 API 契约不符的部分。

**上游原始代码、提示词与设计全部版权归原作者所有**，本 fork 依原 LICENSE 条款分发。

### EN:

- **Original author: [@c3cvld7aag](https://github.com/c3cvld7aag)**
- **Upstream project: https://github.com/c3cvld7aag/fujiang-dsh**
- Original version: `0.4.3`

This repository is a **fork** of the upstream project. [@loyalchiiina](https://github.com/loyalchiiina) ported it to the **new DSH kernel (`0.2.1-rc.2`)** and bumped the version to `0.4.5`.

Upstream `0.4.3` works fine on the old kernel but has 5 issues on the new one (2 of them cause functional breakage or silent config side effects). See [CHANGELOG.md](CHANGELOG.md) and [ADAPTATION-NOTICE.md](ADAPTATION-NOTICE.md). All changes preserve the original design intent and layout; only kernel-API-contract mismatches were fixed.

**All upstream code, prompts and design remain copyright of the original author.** This fork is distributed under the original LICENSE terms.

---

## 三、快速开始 · Quick start

### 中文

> Git 源码仓库**不含** `node_modules`（离线依赖 6.3 MB / 877 文件，只在 Release ZIP 里提供）。想要零联网一键装，请用 Release ZIP。

1. 打开 [Releases](https://github.com/loyalchiiina/fujiang-dsh/releases)，下载 `fujiang-armor-universal-0.4.5-*.zip`
2. **完整解压**（不要直接在压缩包里双击）
3. 完全退出 DSH（桌面端：关窗口 → 右键托盘退出；web 端：关掉那个命令行窗口）
4. 双击 `一键安装.bat`
5. 重新启动 DSH，**用标准模式 + 官方 API** 新建对话，输入「富江」验证（详见 §四）

安装器会自动探测 DSH 数据目录、node 运行时、以及所有已存在的 profile（`web` / `desktop` / `xiufu` …），**一次同时装到 web 端和桌面端**。

### EN:

> The Git source tree does **not** include `node_modules` (6.3 MB / 877 files of offline deps — those ship only inside the Release ZIP). For a zero-network one-click install, use the Release ZIP.

1. Open [Releases](https://github.com/loyalchiiina/fujiang-dsh/releases) and download `fujiang-armor-universal-0.4.5-*.zip`
2. **Fully extract it** (do not double-click inside the archive viewer)
3. Fully quit DSH (desktop: close window → quit from tray; web: close that console window)
4. Double-click `一键安装.bat`
5. Restart DSH, create a chat in **standard mode + official API**, type "富江" to verify (see §4)

The installer auto-detects the DSH data directory, the node runtime, and every existing profile (`web` / `desktop` / `xiufu` …), and installs to **web and desktop in one run**.

---

## 四、⚠️ 安装后必读：正确使用方法 · Post-install: correct usage

### 中文

> 这一节是**踩过坑之后总结的实操顺序**。装完不按这个来，很容易误判成「插件没生效」或「模型不听话」。

**核心顺序：**

```
标准模式 → 官方 API 发一句 → 确认已破甲 → 切免费额度
```

#### 第一步：对话必须用 DSH 标准模式，不要用自定义预设

| | 结论 |
| --- | --- |
| ✅ 用 | DSH **标准模式**（默认预设 / 不带预设） |
| ❌ 别用 | 自定义智慧体预设、自定义 `agentPreset` 档 |

**原因**：富江破甲是靠 `systemPrompt.section()` 往**全局系统提示词层**注入两段规则（Order 100 通用 + Order 200 强化镜像）。自定义预设会自带一整套人格与系统提示词，两者在同一层里互相压制、顺序不确定 —— 实测表现就是「破甲不生效」或「时好时坏」。

自定义预设不是不能用，是**不要拿它来验证破甲效果**。要验证，先切回标准模式。

#### 第二步：先用官方 API 发一句话，确认破甲已生效

1. 新建对话，确认模型走的是**官方 API**（DeepSeek 官方账号 / 官方通道，不是第三方中转、不是积分网关）
2. 输入激活词「富江」，或直接发任意一句试探性提问
3. 看两个地方：
   - 输入框上方是否显示「富江破甲已激活」
   - 回复是否已脱离默认的拒答 / 说教风格

官方通道的模型行为最稳定，用它来判断**插件本身**是否工作，把第三方网关的变量排除掉。

#### 第三步：确认已破甲后，再切换到免费额度通道

确认官方 API 下已经破甲成功之后，再切到你自己的免费额度通道（俗称「免费鸡蛋」，指第三方积分 / 额度网关、LobsterAI / OpenSquilla / AutoClaw 之类）。

**为什么必须这个顺序**：反过来的话，一旦免费通道出问题（限流、模型被换、上游拒答策略不同），你无法判断是**插件没装好**还是**通道不给力**，排查会绕一大圈。先用官方通道建立「插件正常」这个基线，再切通道。

#### 补充说明

- 切换模型 / 切换通道 / 切换预设之后，**建议新开一个对话**。已有对话的历史消息里带着切换前的系统提示词快照，破甲效果可能不一致。
- 如果官方 API 下也破不了甲：先跑 `node tools/health-check.mjs` 排查安装，再让模型调用 `fujiang_profile`，确认 `injection` 两项都是 `enabled: true`。
- 本插件只影响**系统提示词层**，不修改模型权重、不绕过服务端策略。实际效果仍受所选模型、服务端策略与 DSH 版本影响。

### EN:

> This section is the **field-tested operating order**. If you skip it, you will very likely misdiagnose the plugin as "not working" or the model as "not listening".

**Core sequence:**

```
Standard mode → send one message via official API → confirm it works → switch to free-quota channel
```

#### Step 1 — Use DSH **standard mode**, not a custom preset

| | Verdict |
| --- | --- |
| ✅ Use | DSH **standard mode** (default preset / no preset) |
| ❌ Avoid | Custom agent presets, custom `agentPreset` profiles |

**Why**: Fujiang Armor injects two rule blocks into the **global system-prompt layer** via `systemPrompt.section()` (Order 100 general + Order 200 reinforced mirror). A custom preset brings its own full persona/system prompt; both compete in the same layer with an undefined ordering — observed behaviour is "no effect at all" or "works intermittently".

Custom presets are not forbidden — just **do not use them to verify that the plugin works**. Switch back to standard mode for verification.

#### Step 2 — Send one message via the **official API** first

1. Open a new chat and make sure the model runs through the **official API** (official DeepSeek account/channel — not a third-party relay, not a quota gateway)
2. Type the activation word "富江", or any probe question
3. Check two things:
   - Does the "Fujiang Armor activated" badge appear above the input box?
   - Has the reply left the default refusal / lecturing tone?

The official channel is the most stable, so use it to verify **the plugin itself**, with third-party gateway variables removed.

#### Step 3 — Only after confirmation, switch to your free-quota channel

Once it is confirmed working on the official API, switch to your own free-quota channel (third-party credit/quota gateways, LobsterAI / OpenSquilla / AutoClaw, etc.).

**Why this order matters**: if you do it the other way round, then the moment the free channel misbehaves (rate limits, model swapped, different upstream refusal policy) you cannot tell whether **the plugin is broken** or **the channel is bad** — and debugging becomes a long detour. Establish the "plugin is fine" baseline on the official channel first, then switch.

#### Notes

- After switching model / channel / preset, **open a new chat**. Existing chats carry a system-prompt snapshot from before the switch, so behaviour may differ.
- If it still fails on the official API: run `node tools/health-check.mjs`, then have the model call `fujiang_profile` and check that both `injection` entries are `enabled: true`.
- This plugin only affects the **system-prompt layer**. It does not modify model weights and does not bypass server-side policy. Real behaviour still depends on the selected model, server policy and DSH version.

---

## 五、仓库结构 · Repository layout

### 中文

```
.
├── 一键安装.bat / 一键卸载.bat      # 双击入口（Windows）
├── install.ps1 / uninstall.ps1      # PowerShell 安装器（Windows 主路径）
├── install.sh  / uninstall.sh       # Bash 安装器（WSL / Git Bash）
├── tools/                           # 安装器用到的 Node 工具
│   ├── patch-profile.mjs            # 幂等改 profile/package.json（BOM 容错 + 自动备份）
│   ├── sync-lock.mjs                # 同步 pnpm-lock.yaml 账本（防将来 pnpm install 抹掉挂载）
│   ├── probe-plugin.mjs             # 真实 import 自检（校验依赖闭包完整）
│   └── health-check.mjs             # 8 类致命项体检（BOM / bundles / Junction / 依赖 / 编码 / 会话）
├── index.js                         # 插件本体：提示词注入 + fujiang_profile 工具 + 会话投影
├── client.js                        # 客户端 UI：输入框上方状态条
├── cordis.patch.yml                 # bundle patch：插入 fujiang-armor 行
├── cordis.override.patch.yml        # bundle patch：覆盖 system-prompt 行（关掉内置人格）
├── prompts/                         # 提示词（fujiang.md / fujiang-mirror.md / fujiang-compat.md）
├── locale/                          # i18n（en / zh）
├── scripts/                         # 作者原有脚本（ensure-runtime / verify_plugin / scorer …）
├── tests/                           # 提示词测试样本（jsonl）
├── legacy/                          # 原作者 0.4.3 的旧安装脚本（存档，勿用）
├── icon.svg / LICENSE / THIRD-PARTY-NOTICES.md
├── CHANGELOG.md                     # 版本变更（含 0.4.5 五处适配详解）
├── ADAPTATION-NOTICE.md             # 适配说明（内核侧关键事实）
└── 经验固化.md                       # 本次适配踩坑与内核事实汇总
```

> 安装器**自适应两种布局**：Release ZIP 布局（插件在 `plugin/` 子目录，带 `node_modules`）与 Git 源码布局（插件文件直接在仓库根）。源码布局下安装器只复制插件本体白名单，不会把 `.git` / `legacy/` 搬进 `.dsh`。

### EN:

```
.
├── 一键安装.bat / 一键卸载.bat      # double-click entry points (Windows)
├── install.ps1 / uninstall.ps1      # PowerShell installer (primary path on Windows)
├── install.sh  / uninstall.sh       # Bash installer (WSL / Git Bash)
├── tools/                           # Node helpers used by the installer
│   ├── patch-profile.mjs            # idempotent profile/package.json patch (BOM-tolerant + auto backup)
│   ├── sync-lock.mjs                # sync the pnpm-lock.yaml ledger (so a future pnpm install can't drop the mount)
│   ├── probe-plugin.mjs             # real-import self-test (verifies the dependency closure)
│   └── health-check.mjs             # 8 fatal-item health check (BOM / bundles / Junction / deps / encoding / sessions)
├── index.js                         # plugin core: prompt injection + fujiang_profile tool + session projection
├── client.js                        # client UI: status bar above the input box
├── cordis.patch.yml                 # bundle patch: insert the fujiang-armor entry
├── cordis.override.patch.yml        # bundle patch: override the system-prompt entry (disable built-in persona)
├── prompts/                         # prompts (fujiang.md / fujiang-mirror.md / fujiang-compat.md)
├── locale/                          # i18n (en / zh)
├── scripts/                         # original author scripts (ensure-runtime / verify_plugin / scorer …)
├── tests/                           # prompt test samples (jsonl)
├── legacy/                          # original 0.4.3 installer scripts (archived, do not use)
├── icon.svg / LICENSE / THIRD-PARTY-NOTICES.md
├── CHANGELOG.md                     # changelog (including the 5 fixes in 0.4.5)
├── ADAPTATION-NOTICE.md             # adaptation notes (key kernel facts)
└── 经验固化.md                       # collected lessons learned during this port
```

> The installer **supports two layouts**: the Release ZIP layout (plugin under `plugin/`, with `node_modules`) and the Git source layout (plugin files at the repo root). In source layout it copies only the plugin whitelist — `.git` / `legacy/` never land in `.dsh`.

---

## 六、安装器做了什么 · What the installer does

### 中文

四步，每步都有校验：

1. **落盘** —— 复制插件到 `%USERPROFILE%\.dsh\local-plugins\fujiang-armor`（已存在则先备份 `.bak-时间戳`），然后 `node --check` 语法 + 真实 `import` 校验导出 `Config / apply / inject / name`
2. **挂载** —— 在 `<profile>/node_modules/fujiang-armor` 建 **Junction**（不是 symlink；Windows 上只有 Junction 能被 Node 正确解析）
3. **声明** —— 幂等修改 `<profile>/package.json`：`dependencies` 加 `link:` 条目 + `dsh.profile.bundles` 加裸包名（**两处缺一，宿主会静默跳过、零 warn 零 error**）；同步 `pnpm-lock.yaml` importer 账本
4. **校验** —— ①`createRequire` 解析链（`fujiang-armor` / `cordis` / `dsh-tools` / `schemastery` 全部可解析）②`dsh --profile <p> --dump-config` 合成配置含 `- id: fujiang-armor` ③静态声明回读

`desktop` profile 由 Electron 独占，`--dump-config` 会拒绝执行，此时自动降级为静态声明校验（等效）。

### EN:

Four steps, each verified:

1. **Land the files** — copy the plugin to `%USERPROFILE%\.dsh\local-plugins\fujiang-armor` (existing copy is backed up as `.bak-<timestamp>` first), then `node --check` plus a real `import` asserting the exports `Config / apply / inject / name`
2. **Mount** — create a **Junction** at `<profile>/node_modules/fujiang-armor` (not a symlink; on Windows only a Junction is resolved correctly by Node)
3. **Declare** — idempotently patch `<profile>/package.json`: add a `link:` entry under `dependencies` **and** the bare package name under `dsh.profile.bundles` (**miss either one and the host silently skips the plugin — zero warn, zero error**); also sync the `pnpm-lock.yaml` importer ledger
4. **Verify** — (a) `createRequire` resolution chain (`fujiang-armor` / `cordis` / `dsh-tools` / `schemastery` all resolve), (b) `dsh --profile <p> --dump-config` contains `- id: fujiang-armor`, (c) read back the static declarations

The `desktop` profile is owned exclusively by Electron, so `--dump-config` refuses to run; the installer then falls back to static-declaration verification (equivalent).

---

## 七、配置项 · Config

### 中文

在 profile 的 `cordis.patch.yml` 中覆盖 `fujiang-armor` 行的 `config`：

| 键 | 默认值 | 说明 |
| --- | --- | --- |
| `enabled` | `true` | `false` 时不注入提示词、不注册投影，仅保留 `fujiang_profile` 工具 |
| `autoApplyOnStart` | `true` | `false` 时本次启动不注入任何提示词段落（工具与投影仍注册） |
| `dualLayerInjection` | `true` | `false` 时只注入 Order 100 单层，关闭 Order 200 强化镜像 |
| `globalOrder` | `100` | 通用内核段落排序值 |
| `reinforceOrder` | `200` | 强化镜像段落排序值 |
| `projectionKey` | `"fujiang-armor"` | 会话状态投影键名 |

### EN:

Override the `config` of the `fujiang-armor` entry in the profile's `cordis.patch.yml`:

| Key | Default | Meaning |
| --- | --- | --- |
| `enabled` | `true` | When `false`: no prompt injection, no projection registration — only the `fujiang_profile` tool stays |
| `autoApplyOnStart` | `true` | When `false`: this boot injects no prompt sections (tool and projection still register) |
| `dualLayerInjection` | `true` | When `false`: inject only the Order 100 layer, disable the Order 200 reinforced mirror |
| `globalOrder` | `100` | Sort order of the general kernel section |
| `reinforceOrder` | `200` | Sort order of the reinforced mirror section |
| `projectionKey` | `"fujiang-armor"` | Session-state projection key |

---

## 八、安装后体检 · Health check

### 中文

```bash
node tools/health-check.mjs                    # 全项体检
node tools/health-check.mjs --sessions         # 额外扫全部会话的 message id 完整性
node tools/health-check.mjs --json             # 机器可读
```

退出码 `0` = 全通过，`1` = 有 FAIL。检查 8 类：profile BOM、bundles 可解析性、Junction 指向、插件本体完整性、真实 import、编码（U+FFFD）、依赖闭包、会话 message id。

### EN:

```bash
node tools/health-check.mjs                    # full check
node tools/health-check.mjs --sessions         # also scan all sessions for message-id integrity
node tools/health-check.mjs --json             # machine-readable
```

Exit code `0` = all pass, `1` = at least one FAIL. Eight categories: profile BOM, bundle resolvability, Junction target, plugin payload integrity, real import, encoding (U+FFFD), dependency closure, session message ids.

---

## 九、卸载 · Uninstall

### 中文

1. 完全退出 DSH
2. 双击 `一键卸载.bat`（或 `powershell -ExecutionPolicy Bypass -File uninstall.ps1 -Profile web,desktop`）
3. 重新启动 DSH

卸载会移除 Junction、`dependencies` 条目、`bundles` 条目与 `pnpm-lock` 账本条目，并把插件目录改名备份（不物理删除）。想彻底删掉请手动删 `%USERPROFILE%\.dsh\local-plugins\fujiang-armor*`。

### EN:

1. Fully quit DSH
2. Double-click `一键卸载.bat` (or run `powershell -ExecutionPolicy Bypass -File uninstall.ps1 -Profile web,desktop`)
3. Restart DSH

Uninstall removes the Junction, the `dependencies` entry, the `bundles` entry and the `pnpm-lock` ledger entry, then renames the plugin directory as a backup (nothing is physically deleted). To remove it completely, delete `%USERPROFILE%\.dsh\local-plugins\fujiang-armor*` manually.

---

## 十、故障排查：装完插件后某些对话打不开 · Troubleshooting: some chats won't open after installing plugins

> 这一节来自一次真实的排障复盘。**结论先说：这不是富江破甲造成的**，但排查方法对任何 DSH 插件都通用。
> This section comes from a real post-mortem. **Bottom line: Fujiang Armor was not the cause** — but the method applies to any DSH plugin.

### 中文

#### 症状

装完某个插件后，历史对话列表里点进去打不开：白屏、报错、或一直转圈；新建对话正常。

#### 根因（内核硬校验）

DSH 内核在**加载会话**时，会逐条校验每个 message 事件的形状。其中一条是：

```js
// 简化示意（内核 dsh-session 的 assertMessageEventShape）
if (typeof message.id !== "string" || message.id === "") {
  throw new Error(`${subject} lacks an identified message`);
}
```

即：**每一条 message 必须带非空字符串 `id`**。会话里只要存在一条缺 `id` 的 message 事件，整个会话就加载失败 —— 表现为「这个对话打不开」。

#### 定位方法

1. 会话文件是 `~/.dsh/sessions/<工作区目录>/<session-id>/session.v4.jsonl.zstd`
2. 解压后逐行解析，筛出 `type` 属于 `developer/message`、`system/message`、`user/message`、`assistant/message`、`tool/result` 的事件
3. 检查每条是否 `message.id` 为非空字符串
4. **看 `source.kind`** —— 这是定位「谁写的」最直接的线索

本机复盘的实测结果：缺 `id` 的事件全部来自**某个已卸载的注入类插件**，其写入的事件形如 `{"type":"user/message","role":"user","source":{"kind":"<某个插件名>"},"content":"[object Object]"}` —— `source.kind` 直接点名了元凶，且时间戳集中在那个插件存活期间，**远早于富江破甲的首次安装时间**。

#### 富江破甲为什么不是元凶

代码层面可证：

- `index.js` 全文没有 `ctx.session` / `.append(` / `.emit(` / `writeFile` / `appendFile` —— **不写会话、不发事件**
- 唯一与事件相关的是会话投影 `armorProjectionApply(state, event)`，它对 `user/message` 和 `assistant/message` **只读不写**，且对无关事件原样 `return state`
- **投影状态不落盘**：全量扫描会话文件，projection 类事件数量为 0
- 补测：用真实内核装配插件，把历史会话的全部事件逐个喂给投影函数 —— 抛错数为 0

#### 修复步骤（通用）

1. **先备份**整个 `~/.dsh/sessions` 目录
2. 对每个会话：解压 → 逐行解析 → 给缺 `id` 的 message 事件补一个稳定的唯一 `id`（如 `随机 UUID`，保证幂等重跑不重复写）→ 重新压缩
3. 复验：全部会话再扫一遍，缺 `id` 计数应为 0
4. **根治**：卸载那个会写无 `id` 消息的插件（`source.kind` 已经告诉你名字了）

#### 防复发

- 装任何插件后跑一次 `node tools/health-check.mjs --sessions`，它会直接报「缺 id = N」
- 只信任走官方 session API 的插件；会自己 `push` 消息事件的注入类插件要谨慎
- 装插件前先备份 `~/.dsh/profiles` 与 `~/.dsh/sessions`（`package.json` / `pnpm-lock.yaml` 都要）

### EN:

#### Symptom

After installing some plugin, historical chats refuse to open — blank screen, an error, or endless spinner — while new chats work fine.

#### Root cause (a hard kernel validation)

When **loading a session**, the DSH kernel validates the shape of every message event. One of the checks is:

```js
// simplified (kernel dsh-session, assertMessageEventShape)
if (typeof message.id !== "string" || message.id === "") {
  throw new Error(`${subject} lacks an identified message`);
}
```

In other words: **every message must carry a non-empty string `id`**. A single message event without `id` makes the whole session fail to load — which is exactly what "this chat won't open" looks like.

#### How to locate it

1. Session files live at `~/.dsh/sessions/<workspace-dir>/<session-id>/session.v4.jsonl.zstd`
2. Decompress and parse line by line; select events whose `type` is one of `developer/message`, `system/message`, `user/message`, `assistant/message`, `tool/result`
3. Check whether each has a non-empty string `message.id`
4. **Look at `source.kind`** — the most direct clue for "who wrote this"

What the real post-mortem found: every `id`-less event came from **an already-uninstalled injector-type plugin**. The events looked like `{"type":"user/message","role":"user","source":{"kind":"<plugin-name>"},"content":"[object Object]"}` — `source.kind` named the culprit outright, and their timestamps clustered inside that plugin's lifetime, **long before Fujiang Armor was ever installed**.

#### Why Fujiang Armor is not the culprit

Provable at the code level:

- `index.js` contains no `ctx.session` / `.append(` / `.emit(` / `writeFile` / `appendFile` — **it never writes sessions or emits events**
- The only event-related code is the session projection `armorProjectionApply(state, event)`, which **reads but never writes** `user/message` and `assistant/message`, and returns `state` unchanged for anything else
- **Projection state is never persisted**: scanning every session file yields 0 projection-type events
- Extra check: with the plugin mounted on a real kernel, every event from all historical sessions was fed through the projection function — 0 throws

#### Fix (generic)

1. **Back up** the whole `~/.dsh/sessions` directory first
2. For each session: decompress → parse line by line → add a stable unique `id` to every message event missing one (e.g. a random UUID; make the step idempotent so re-runs don't duplicate) → recompress
3. Re-verify: rescan all sessions — the missing-`id` count must be 0
4. **Root fix**: uninstall the plugin that writes id-less messages (`source.kind` already told you its name)

#### Prevention

- After installing any plugin, run `node tools/health-check.mjs --sessions` — it reports "missing id = N" directly
- Trust only plugins that use the official session API; be careful with injector-type plugins that `push` message events themselves
- Before installing plugins, back up `~/.dsh/profiles` and `~/.dsh/sessions` (including `package.json` and `pnpm-lock.yaml`)

---

## 十一、常见问题 · FAQ

### 中文

| 问题 | 处理方法 |
| --- | --- |
| 双击 bat 一闪而过 | 从 zip 里直接双击了。先**完整解压**，再在解压目录里运行 |
| 找不到 DSH 配置或目标配置 | 先安装并启动一次 DSH，确认 `%USERPROFILE%\.dsh` 已生成 |
| 安装成功但没显示激活状态 | 完全退出并**重启** DSH；确认装的是当前在用的 profile |
| 提示词里的 `{{xxx}}` 被吃掉了 | 内核只内置 `{{model}}` / `{{provider}}` 两个插值变量，其余 `{{` 会被转义成 `{ {` |
| 装完插件后某个会话打不开 | 见 §十。与富江破甲无关，跑 `health-check.mjs --sessions` 可定位到具体插件 |
| 卸载后仍显示激活状态 | 完全退出并重启 DSH，确认卸的是此前安装的 profile |
| **用了自定义预设，破甲不生效 / 时好时坏** | 切回 DSH **标准模式**再试（见 §四） |
| **换了免费额度通道后破甲失效** | 先用**官方 API** 验证插件本身正常，再切通道（见 §四） |
| 官方 API 下也破不了甲 | 跑 `node tools/health-check.mjs`，再让模型调用 `fujiang_profile`，确认 `injection` 两项都是 `enabled: true` |

「富江破甲已激活」表示插件已加载。实际回复仍受所选模型、其他提示词及 DSH 版本影响。

### EN:

| Problem | Fix |
| --- | --- |
| The .bat window flashes and closes | You double-clicked inside the zip. **Extract fully** first, then run it in the extracted folder |
| "DSH config not found" / target profile not found | Install and launch DSH once first, and confirm `%USERPROFILE%\.dsh` exists |
| Install succeeded but no activated badge | Fully quit and **restart** DSH; make sure you installed into the profile you actually use |
| `{{xxx}}` in the prompt got eaten | The kernel only provides `{{model}}` and `{{provider}}`; any other `{{` is escaped to `{ {` |
| Some chat won't open after installing plugins | See §10. Unrelated to Fujiang Armor; run `health-check.mjs --sessions` to identify the real plugin |
| Still shows activated after uninstall | Fully quit and restart DSH; verify you uninstalled from the right profile |
| **Custom preset → no effect / intermittent** | Switch back to DSH **standard mode** (see §4) |
| **Stopped working after switching to a free-quota channel** | Verify on the **official API** first, then switch channels (see §4) |
| Fails even on the official API | Run `node tools/health-check.mjs`, then have the model call `fujiang_profile` and confirm both `injection` entries are `enabled: true` |

"Fujiang Armor activated" only means the plugin is loaded. Actual replies still depend on the selected model, other prompts and the DSH version.

---

## 十二、DSH 无限重启 · Restart loop

### 中文

已核对 dsh-purge 官方发布页：1.1.52 在已应用补丁戳缺少 `sha` 时会把状态判为未对齐，并在启动时重打补丁、请求重启；上游从 1.1.53 起加入了空戳修复。若你使用 1.1.52 并遇到反复重启，请升级到 1.1.53 或更新版本。

本插件没有重启 DSH 的代码。兼容性补丁只在安装过程中应用；启动插件不会再重复写入宿主或 profile 文件。

### EN:

Verified against the dsh-purge release notes: version 1.1.52 treats an applied-patch stamp without `sha` as out-of-sync, re-applies patches on boot and requests a restart; upstream added the empty-stamp fix in 1.1.53. If you are on 1.1.52 and see restart loops, upgrade to 1.1.53 or newer.

This plugin contains no code that restarts DSH. Compatibility patches are applied only during installation; loading the plugin never rewrites host or profile files again.

---

## 十三、许可 · License

### 中文

见 [LICENSE](LICENSE) 与 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。原始版权归原作者 [@c3cvld7aag](https://github.com/c3cvld7aag) 所有。

### EN:

See [LICENSE](LICENSE) and [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md). Original copyright belongs to [@c3cvld7aag](https://github.com/c3cvld7aag).
