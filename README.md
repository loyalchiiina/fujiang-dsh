# 富江DSH完美破甲 · Fujiang Armor

富江破甲是一个用于 DSH（DeepSeek Harness）的本地插件，内置提示词规则，提供 Windows 一键注入和一键卸载。插件加载后，会在对话输入框上方显示「富江破甲已激活」。

- 当前版本：`0.4.5`
- 插件标识：`fujiang-armor`
- 适配内核：DSH `2.0.19-next` / `dsh-app-boot` `0.2.1-rc.2`（cordis `4.0.5`、dsh-tools `0.2.1-rc.2`、schemastery `3.18.5`）
- 分发方式：**仅 GitHub Release 提供安装包，未发布到 npm**

---

## 原作者与来源 · Credits

- **原作者 / Original author：[@c3cvld7aag](https://github.com/c3cvld7aag)**
- **原项目 / Upstream：https://github.com/c3cvld7aag/fujiang-dsh**
- 原始版本：`0.4.3`

本仓库是原项目的 **fork**，由 [@loyalchiiina](https://github.com/loyalchiiina) 针对 **DSH 新内核（`0.2.1-rc.2`）完成了兼容性适配**，版本号推进到 `0.4.5`。

上游 `0.4.3` 在旧内核上工作正常，但在新内核上存在 5 处问题（其中 2 处会导致功能失效或配置副作用），详见 [CHANGELOG.md](CHANGELOG.md) 与 [ADAPTATION-NOTICE.md](ADAPTATION-NOTICE.md)。所有修改均保持原插件的设计意图与目录结构，仅修正与内核 API 契约不符的部分。

**上游原始代码、提示词与设计全部版权归原作者所有**，本 fork 依原 LICENSE 条款分发。

---

## 快速开始（推荐：下载 Release 安装包）

> Git 源码仓库**不含** `node_modules`（离线依赖体积 6.3 MB / 877 文件，只在 Release ZIP 里提供）。想要零联网一键装，请用 Release ZIP。

1. 打开 [Releases](https://github.com/loyalchiiina/fujiang-dsh/releases)，下载 `fujiang-armor-universal-0.4.5-*.zip`
2. **完整解压**（不要直接在压缩包里双击）
3. 完全退出 DSH（桌面端：关窗口 → 右键托盘退出；web 端：关掉那个命令行窗口）
4. 双击 `一键安装.bat`
5. 重新启动 DSH，**用标准模式 + 官方 API** 新建对话，输入「富江」验证（详见下方「安装后必读：正确使用方法」）

安装器会自动探测 DSH 数据目录、node 运行时、以及所有已存在的 profile（`web` / `desktop` / `xiufu` …），**一次同时装到 web 端和桌面端**。

---

## ⚠️ 安装后必读：正确使用方法

> 这一节是**踩过坑之后总结的实操顺序**，装完不按这个来，很容易以为「插件没生效」或「模型不听话」。

### 第一步：对话必须用 **DSH 标准模式**，不要用自定义预设

| | 结论 |
| --- | --- |
| ✅ 用 | DSH **标准模式**（默认预设 / 无预设） |
| ❌ 别用 | 自定义智慧体预设、`agentPreset` 自定义档 |

**为什么**：富江破甲是靠 `systemPrompt.section()` 往**全局系统提示词层**注入两段规则（Order 100 + Order 200）。自定义预设会自带一整套人格与系统提示词，两者在同一层里互相压制、顺序不确定，实测表现为「破甲不生效」或「时好时坏」。

自定义预设不是不能用，是**不要用来验证破甲效果**。要验证，先切回标准模式。

### 第二步：先用**官方 API** 发一句话，确认破甲已生效

1. 新建对话，确认模型走的是**官方 API**（DeepSeek 官方账号 / 官方通道，不是第三方中转、不是积分网关）
2. 输入激活词「富江」，或直接发任意一句试探性提问
3. 看两个地方：
   - 输入框上方是否显示「富江破甲已激活」
   - 回复是否已脱离默认的拒答/说教风格

官方通道的模型行为最稳定，用它来判断**插件本身**是否工作，排除第三方网关的干扰变量。

### 第三步：确认已破甲后，再切换到**免费额度**通道

确认官方 API 下已经破甲成功之后，再切到你自己的免费额度通道（俗称「免费鸡蛋」，指第三方积分/额度网关、LobsterAI / OpenSquilla / AutoClaw 之类）。

**为什么这个顺序**：反过来的话，一旦免费通道出问题（限流、模型被换、上游拒答策略不同），你无法判断是**插件没装好**还是**通道不给力**，排查会绕大圈。先用官方通道建立"插件正常"这个基线，再切通道。

### 一句话版本

```
标准模式 → 官方 API 发一句 → 确认破甲 → 切免费额度
```

### 补充说明

- 切换模型 / 切换通道 / 切换预设之后，**建议新开一个对话**。已有对话的历史消息里带着切换前的系统提示词快照，破甲效果可能不一致。
- 如果官方 API 下也破不了甲，先跑 `node tools/health-check.mjs` 排查安装，再让模型调用 `fujiang_profile` 工具看 `injection` 两项是否 `enabled: true`。
- 本插件只影响**系统提示词层**，不修改模型权重、不绕过服务端策略。实际效果仍受所选模型、服务端策略与 DSH 版本影响。

---

## 仓库结构 · Repository layout

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

> 安装器会**自适应两种布局**：Release ZIP 布局（插件在 `plugin/` 子目录，带 `node_modules`）与 Git 源码布局（插件文件直接在仓库根）。源码布局下安装器只复制插件本体白名单，不会把 `.git` / `legacy/` 搬进 `.dsh`。

---

## 安装器做了什么 · What the installer does

四步，每步都有校验：

1. **落盘** —— 复制插件到 `%USERPROFILE%\.dsh\local-plugins\fujiang-armor`（已存在则先备份 `.bak-时间戳`），然后 `node --check` 语法 + 真实 `import` 校验导出 `Config / apply / inject / name`
2. **挂载** —— 在 `<profile>/node_modules/fujiang-armor` 建 **Junction**（不是 symlink，Windows 上只有 Junction 能被 Node 正确解析）
3. **声明** —— 幂等修改 `<profile>/package.json`：`dependencies` 加 `link:` 条目 + `dsh.profile.bundles` 加裸包名（两处缺一，宿主会**静默跳过、零 warn 零 error**）；同步 `pnpm-lock.yaml` importer 账本
4. **校验** —— ①`createRequire` 解析链（`fujiang-armor` / `cordis` / `dsh-tools` / `schemastery` 全部可解析）②`dsh --profile <p> --dump-config` 合成配置含 `- id: fujiang-armor` ③静态声明回读

`desktop` profile 由 Electron 独占，`--dump-config` 会拒绝执行，此时自动降级为静态声明校验（等效）。

---

## 配置项 · Config

在 profile 的 `cordis.patch.yml` 中覆盖 `fujiang-armor` 行的 `config`：

| 键 | 默认值 | 说明 |
| --- | --- | --- |
| `enabled` | `true` | `false` 时不注入提示词、不注册投影，仅保留 `fujiang_profile` 工具 |
| `autoApplyOnStart` | `true` | `false` 时本次启动不注入任何提示词段落（工具与投影仍注册） |
| `dualLayerInjection` | `true` | `false` 时只注入 Order 100 单层，关闭 Order 200 强化镜像 |
| `globalOrder` | `100` | 通用内核段落排序值 |
| `reinforceOrder` | `200` | 强化镜像段落排序值 |
| `projectionKey` | `"fujiang-armor"` | 会话状态投影键名 |

---

## 安装后体检 · Health check

```bash
node tools/health-check.mjs                    # 全项体检
node tools/health-check.mjs --sessions         # 额外扫全部会话的 message id 完整性
node tools/health-check.mjs --json             # 机器可读
```

退出码 `0` = 全通过，`1` = 有 FAIL。检查 8 类：profile BOM、bundles 可解析性、Junction 指向、插件本体完整性、真实 import、编码（U+FFFD）、依赖闭包、会话 message id。

---

## 卸载 · Uninstall

1. 完全退出 DSH
2. 双击 `一键卸载.bat`（或 `powershell -ExecutionPolicy Bypass -File uninstall.ps1 -Profile web,desktop`）
3. 重新启动 DSH

卸载会移除 Junction、`dependencies` 条目、`bundles` 条目与 `pnpm-lock` 账本条目，并把插件目录改名备份（不物理删除）。想彻底删掉请手动删 `%USERPROFILE%\.dsh\local-plugins\fujiang-armor*`。

---

## 常见问题 · FAQ

| 问题 | 处理方法 |
| --- | --- |
| 双击 bat 一闪而过 | 从 zip 里直接双击了。先**完整解压**，再在解压目录里运行 |
| 找不到 DSH 配置或目标配置 | 先安装并启动一次 DSH，确认 `%USERPROFILE%\.dsh` 已生成 |
| 安装成功但没显示激活状态 | 完全退出并**重启** DSH；确认装的是当前在用的 profile |
| 提示词里的 `{{xxx}}` 被吃掉了 | 内核只内置 `{{model}}` / `{{provider}}` 两个插值变量，其余 `{{` 会被转义成 `{ {` |
| 装完插件后某个会话打不开 | 与本插件无关：内核要求每条 message 必须有 `id`，第三方插件（如 `dsh-shield`）写入无 `id` 的消息会导致会话加载失败。跑 `health-check.mjs --sessions` 可定位 |
| 卸载后仍显示激活状态 | 完全退出并重启 DSH，确认卸的是此前安装的 profile |
| **用了自定义预设，破甲不生效 / 时好时坏** | 切回 DSH **标准模式**再试。自定义预设自带人格系统提示词，会和 Order 100/200 两段规则在同一层互相压制 |
| **换了免费额度通道后破甲失效** | 先用**官方 API** 验证插件本身正常，再切通道。顺序反了无法区分是插件问题还是通道问题 |
| 官方 API 下也破不了甲 | 跑 `node tools/health-check.mjs`，再让模型调用 `fujiang_profile`，确认 `injection` 两项都是 `enabled: true` |

「富江破甲已激活」表示插件已加载。实际回复仍受所选模型、其他提示词及 DSH 版本影响。

---

## DSH 无限重启 · Restart loop

已核对 dsh-purge 官方发布页：1.1.52 在已应用补丁戳缺少 `sha` 时会把状态判为未对齐，并在启动时重打补丁、请求重启；上游从 1.1.53 起加入了空戳修复。若你使用 1.1.52 并遇到反复重启，请升级到 1.1.53 或更新版本。

本插件没有重启 DSH 的代码。兼容性补丁只在安装过程中应用；启动插件不会再重复写入宿主或 profile 文件。

---

## 许可 · License

见 [LICENSE](LICENSE) 与 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。原始版权归原作者 [@c3cvld7aag](https://github.com/c3cvld7aag) 所有。