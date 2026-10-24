#!/usr/bin/env bash
# 富江破甲 fujiang-armor v0.4.5 —— Linux / macOS 安装器
# 用法: ./install.sh [-p profile[,profile...]] [-d DSH_HOME] [-n NODE] [-F]
set -euo pipefail

PROFILES=""
DSH_HOME_ARG=""
NODE_ARG=""
FORCE=0
PKG_NAME="fujiang-armor"

usage() {
  cat <<EOF
用法: $0 [选项]

  -p, --profile <list>   目标 profile，逗号分隔（web,desktop 或 all）。默认全部现有 profile
  -d, --dsh-home <dir>   DSH 数据根目录。默认 \$DSH_HOME 或 ~/.dsh
  -n, --node <path>      node 可执行文件路径。默认自动探测
  -F, --force            覆盖已存在的插件目录（先备份）
  -h, --help             显示本帮助
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--profile) PROFILES="${2:-}"; shift 2 ;;
    -d|--dsh-home) DSH_HOME_ARG="${2:-}"; shift 2 ;;
    -n|--node) NODE_ARG="${2:-}"; shift 2 ;;
    -F|--force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知参数: $1" >&2; usage; exit 2 ;;
  esac
done

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 两种布局自适应：
#   ① Release ZIP 布局：<root>/plugin/  （含内置 node_modules，零联网）
#   ② Git 仓库/源码布局：插件文件直接在 <root>/
SRC="$HERE/plugin"
[ -f "$SRC/index.js" ] || SRC="$HERE"

echo "== [0] 包体自检 =="
for f in index.js client.js package.json cordis.patch.yml cordis.override.patch.yml prompts locale node_modules; do
  [ -e "$SRC/$f" ] || { echo "缺少必需项: $f" >&2; exit 1; }
done
VER="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$SRC/package.json" | head -n1)"
echo "插件版本: $VER"

echo "== [1] 定位 DSH_HOME =="
if [ -n "$DSH_HOME_ARG" ]; then DSH_HOME="$DSH_HOME_ARG"
elif [ -n "${DSH_HOME:-}" ]; then DSH_HOME="$DSH_HOME"
else DSH_HOME="$HOME/.dsh"; fi
[ -d "$DSH_HOME" ] || { echo "找不到 DSH 数据目录: $DSH_HOME（先启动一次 DSH，或用 -d 指定）" >&2; exit 1; }
echo "DSH_HOME = $DSH_HOME"

echo "== [2] 定位 node =="
NODE_BIN=""
if [ -n "$NODE_ARG" ]; then NODE_BIN="$NODE_ARG"
else
  for c in "$DSH_HOME"/dsh-runtimes/*/dependencies/node/bin/node; do
    [ -x "$c" ] && { NODE_BIN="$c"; break; }
  done
  [ -z "$NODE_BIN" ] && command -v node >/dev/null 2>&1 && NODE_BIN="$(command -v node)"
fi
[ -n "$NODE_BIN" ] && [ -x "$NODE_BIN" ] || { echo "找不到 node 可执行文件（需 >= 22.19）" >&2; exit 1; }
echo "node = $NODE_BIN ($("$NODE_BIN" -v))"

echo "== [3] 枚举 profile =="
PLIST=()
if [ -n "$PROFILES" ] && [ "$PROFILES" != "all" ]; then
  IFS=',' read -r -a PLIST <<< "$PROFILES"
else
  ALL=()
  for d in "$DSH_HOME"/profiles/*/; do
    name="$(basename "$d")"
    case "$name" in *.bak*|node_modules) continue ;; esac
    [ -f "$d/package.json" ] && ALL+=("$name")
  done
  if [ "$PROFILES" = "all" ]; then
    PLIST=("${ALL[@]}")
  else
    # 默认（傻瓜模式）：只装 web 与 desktop，不塞进 xiufu 等专用 profile
    for n in "${ALL[@]}"; do
      case "$n" in web|desktop) PLIST+=("$n") ;; esac
    done
    if [ ${#PLIST[@]} -eq 0 ]; then PLIST=("${ALL[@]}"); echo "本机没有 web/desktop，改为全部 profile"; fi
  fi
fi
[ ${#PLIST[@]} -gt 0 ] || { echo "没有找到可用 profile" >&2; exit 1; }
echo "目标 profile: ${PLIST[*]}"

echo "== [4] 插件落盘 =="
PLUGIN_DIR="$DSH_HOME/local-plugins/$PKG_NAME"
mkdir -p "$DSH_HOME/local-plugins"
if [ -d "$PLUGIN_DIR" ]; then
  if [ "$FORCE" -eq 1 ]; then
    BAK="$PLUGIN_DIR.bak-$(date +%Y%m%d-%H%M%S)"
    mv "$PLUGIN_DIR" "$BAK"
    echo "已备份旧插件目录 → $BAK"
  else
    echo "已存在 $PLUGIN_DIR（跳过复制，用 -F 覆盖）"
  fi
fi
if [ ! -d "$PLUGIN_DIR" ]; then
  mkdir -p "$PLUGIN_DIR"
  if [ "$SRC" = "$HERE" ]; then
    # 源码布局：只复制插件本体白名单，不把 .git / legacy / 安装器搬进去
    for f in index.js client.js package.json cordis.patch.yml cordis.override.patch.yml \
             icon.svg LICENSE THIRD-PARTY-NOTICES.md README.md README-zh.md README-es.md README-pt.md README-hi.md; do
      [ -f "$SRC/$f" ] && cp "$SRC/$f" "$PLUGIN_DIR/$f"
    done
    for d in prompts locale scripts tests node_modules; do
      [ -d "$SRC/$d" ] && cp -R "$SRC/$d" "$PLUGIN_DIR/$d"
    done
    echo "已复制插件本体（源码布局）→ $PLUGIN_DIR"
  else
    cp -R "$SRC/." "$PLUGIN_DIR/"
    echo "已复制插件 → $PLUGIN_DIR"
  fi
fi

echo "-- 语法与加载自检 --"
"$NODE_BIN" --check "$PLUGIN_DIR/index.js"
"$NODE_BIN" --check "$PLUGIN_DIR/client.js"
"$NODE_BIN" "$HERE/tools/probe-plugin.mjs" "$PLUGIN_DIR"

echo "== [5] 逐 profile 挂载 =="
FAIL=0
printf "%-12s %-6s %-8s %-8s\n" Profile Mount Declare Verify
printf "%-12s %-6s %-8s %-8s\n" ------- ----- ------- ------
for p in "${PLIST[@]}"; do
  PDIR="$DSH_HOME/profiles/$p"
  [ -f "$PDIR/package.json" ] || { printf "%-12s %s\n" "$p" "SKIP(无 package.json)"; continue; }

  "$NODE_BIN" "$HERE/tools/patch-profile.mjs" "$PDIR" "$PKG_NAME" "$PLUGIN_DIR" >/dev/null || { printf "%-12s %s\n" "$p" "DECLARE-FAIL"; FAIL=1; continue; }

  LINK="$PDIR/node_modules/$PKG_NAME"
  mkdir -p "$PDIR/node_modules"
  if [ -L "$LINK" ]; then echo "  已存在 symlink → $LINK"
  elif [ -d "$LINK" ]; then rm -rf "$LINK"; ln -s "$PLUGIN_DIR" "$LINK"; echo "  已替换为 symlink → $LINK"
  else ln -s "$PLUGIN_DIR" "$LINK"; echo "  已创建 symlink → $LINK"; fi

  # pnpm-lock 账本同步：不做这步，将来任何一次 pnpm install 都会抹掉上面的 symlink，
  # 插件静默失联（宿主零 warn 零 error）。
  if [ -f "$HERE/tools/sync-lock.mjs" ]; then
    LOCKOUT="$("$NODE_BIN" "$HERE/tools/sync-lock.mjs" "$PDIR" "$PKG_NAME" "$PLUGIN_DIR" 2>&1)" || true
    echo "  pnpm-lock: $LOCKOUT"
  fi

  RES="$("$NODE_BIN" -e '
    const {createRequire}=require("module");const {join}=require("path");
    const r=createRequire(join(process.argv[1],"package.json"));
    const out=[];
    for(const n of ["fujiang-armor","@deepseek-ai/cordis","@deepseek-ai/dsh-tools","@deepseek-ai/schemastery"]){
      try{out.push(n+"="+r(n+"/package.json").version)}catch(e){out.push(n+"=MISS")}
    }
    console.log(out.join(" "));
  ' "$PDIR" 2>&1)" || RES="resolve-error"
  case "$RES" in *MISS*|*error*) printf "%-12s %-6s %-8s %-8s\n" "$p" "OK" "OK" "RESOLVE-FAIL"; FAIL=1; continue ;; esac
  printf "%-12s %-6s %-8s %-8s\n" "$p" "OK" "OK" "OK"
  echo "  解析链: $RES"
done

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "安装失败。回滚方法："
  echo "  1) cp <profile>/package.json.bak-*-fujiang-armor <profile>/package.json"
  echo "  2) rm -f <profile>/node_modules/$PKG_NAME"
  exit 1
fi

echo ""
echo "安装成功！目标 profile: ${PLIST[*]}"
echo "请完全退出并重启 DSH 后生效。"