#!/usr/bin/env bash
# 富江破甲 fujiang-armor v0.4.5 —— Linux / macOS 卸载器
# 用法: ./uninstall.sh [-p profile[,profile...]] [-d DSH_HOME] [-P]
set -euo pipefail

PROFILES=""
DSH_HOME_ARG=""
PURGE=0
PKG_NAME="fujiang-armor"

usage() {
  cat <<EOF
用法: $0 [选项]

  -p, --profile <list>   目标 profile，逗号分隔（web,desktop 或 all）。默认全部
  -d, --dsh-home <dir>   DSH 数据根目录。默认 \$DSH_HOME 或 ~/.dsh
  -P, --purge            同时删除插件目录（改名备份）
  -h, --help             显示本帮助
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--profile) PROFILES="${2:-}"; shift 2 ;;
    -d|--dsh-home) DSH_HOME_ARG="${2:-}"; shift 2 ;;
    -P|--purge) PURGE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知参数: $1" >&2; usage; exit 2 ;;
  esac
done

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "$DSH_HOME_ARG" ]; then DSH_HOME="$DSH_HOME_ARG"
elif [ -n "${DSH_HOME:-}" ]; then DSH_HOME="$DSH_HOME"
else DSH_HOME="$HOME/.dsh"; fi
[ -d "$DSH_HOME" ] || { echo "找不到 DSH 数据目录: $DSH_HOME" >&2; exit 1; }

NODE_BIN=""
for c in "$DSH_HOME"/dsh-runtimes/*/dependencies/node/bin/node; do
  [ -x "$c" ] && { NODE_BIN="$c"; break; }
done
[ -z "$NODE_BIN" ] && command -v node >/dev/null 2>&1 && NODE_BIN="$(command -v node)"
[ -n "$NODE_BIN" ] || { echo "找不到 node" >&2; exit 1; }

PLIST=()
if [ -n "$PROFILES" ] && [ "$PROFILES" != "all" ]; then
  IFS=',' read -r -a PLIST <<< "$PROFILES"
else
  for d in "$DSH_HOME"/profiles/*/; do
    name="$(basename "$d")"
    case "$name" in *.bak*|node_modules) continue ;; esac
    [ -f "$d/package.json" ] && PLIST+=("$name")
  done
fi

echo "== 逐 profile 摘除 =="
for p in "${PLIST[@]}"; do
  PDIR="$DSH_HOME/profiles/$p"
  [ -f "$PDIR/package.json" ] || continue
  echo "-- $p"
  "$NODE_BIN" "$HERE/tools/patch-profile.mjs" "$PDIR" "$PKG_NAME" "" --remove || echo "  声明摘除失败"
  if [ -f "$HERE/tools/sync-lock.mjs" ]; then
    LOCKOUT="$("$NODE_BIN" "$HERE/tools/sync-lock.mjs" "$PDIR" "$PKG_NAME" "" --remove 2>&1)" || true
    echo "  pnpm-lock: $LOCKOUT"
  fi
  LINK="$PDIR/node_modules/$PKG_NAME"
  if [ -L "$LINK" ]; then rm -f "$LINK"; echo "  symlink 已删除"
  elif [ -d "$LINK" ]; then echo "  警告：$LINK 是实体目录，未删除，请人工确认"; fi
done

if [ "$PURGE" -eq 1 ]; then
  PLUGIN_DIR="$DSH_HOME/local-plugins/$PKG_NAME"
  if [ -d "$PLUGIN_DIR" ]; then
    BAK="$PLUGIN_DIR.bak-$(date +%Y%m%d-%H%M%S)"
    mv "$PLUGIN_DIR" "$BAK"
    echo "插件目录已改名备份 → $BAK"
  fi
fi

echo ""
echo "卸载完成。重启 DSH 后生效。"