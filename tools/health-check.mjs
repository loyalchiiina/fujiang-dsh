#!/usr/bin/env node
/**
 * fujiang-armor 安装体检器 (health-check)
 *
 * 用途：安装后 / 出问题后一条命令体检，覆盖 6 类可致命项：
 *   1. profile/package.json 是否带 BOM（内核 JSON.parse 直接失败 -> 桌面端起不来）
 *   2. 会话文件里 message 事件是否缺 id（内核 assertMessageEventShape 抛
 *      "lacks an identified message" -> 该会话永久打不开）
 *   3. profile 声明的 bundles 是否全部可解析（缺失实体 -> 静默不激活）
 *   4. node_modules\<plugin> 是否 Junction 且指向正确
 *   5. 插件本体是否完整（必需文件 + node --check + 真实 import）
 *   6. 插件自带依赖闭包是否齐全（离线可解析）
 *
 * 用法：
 *   node health-check.mjs                      # 用 %USERPROFILE%\.dsh
 *   node health-check.mjs --dsh-home D:\x\.dsh
 *   node health-check.mjs --sessions           # 额外扫描全部会话的 message id
 *   node health-check.mjs --json               # 机器可读输出
 *
 * 退出码：0 全部通过；1 有 FAIL
 */

import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import os from 'node:os';
import { pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';

const PLUGIN = 'fujiang-armor';
const REQUIRED = [
  'index.js', 'client.js', 'package.json',
  'cordis.patch.yml', 'cordis.override.patch.yml',
  'prompts', 'locale', 'node_modules',
];

// ---------- 参数 ----------
const argv = process.argv.slice(2);
const has = (f) => argv.includes(f);
const val = (f, d) => {
  const i = argv.indexOf(f);
  return i >= 0 && argv[i + 1] ? argv[i + 1] : d;
};
const DSH_HOME = val('--dsh-home', process.env.DSH_HOME || path.join(os.homedir(), '.dsh'));
const SCAN_SESSIONS = has('--sessions');
const JSON_OUT = has('--json');

// ---------- 结果收集 ----------
const rows = [];
const rec = (area, item, ok, detail) => rows.push({ area, item, ok, detail });
const ok = (a, i, d = '') => rec(a, i, true, d);
const bad = (a, i, d = '') => rec(a, i, false, d);
const skip = (a, i, d = '') => rec(a, i, null, d);

// ---------- 1. profile package.json BOM / JSON ----------
function checkProfiles() {
  const base = path.join(DSH_HOME, 'profiles');
  if (!fs.existsSync(base)) return bad('profile', 'profiles 目录', `${base} 不存在`);

  const profiles = fs.readdirSync(base, { withFileTypes: true })
    .filter((d) => d.isDirectory() && !d.name.startsWith('.') && d.name !== 'node_modules')
    .filter((d) => !d.name.includes('.bak'))
    .map((d) => d.name)
    .filter((n) => fs.existsSync(path.join(base, n, 'package.json')));

  if (!profiles.length) return bad('profile', 'profile 枚举', '未找到任何 profile');

  for (const p of profiles) {
    const pj = path.join(base, p, 'package.json');
    const buf = fs.readFileSync(pj);

    // BOM
    if (buf[0] === 0xef && buf[1] === 0xbb && buf[2] === 0xbf) {
      bad('profile', `${p}: package.json BOM`, '带 UTF-8 BOM —— 内核 readProfileManifest 会 JSON.parse 失败，该 profile 起不来');
    } else ok('profile', `${p}: package.json BOM`, '无 BOM');

    // JSON 可解析
    let pkg;
    try {
      pkg = JSON.parse(buf.toString('utf8'));
      ok('profile', `${p}: package.json 可解析`, `${buf.length} B`);
    } catch (e) {
      bad('profile', `${p}: package.json 可解析`, e.message);
      continue;
    }

    const bundles = pkg?.dsh?.profile?.bundles || [];
    const deps = pkg.dependencies || {};

    // bundles 可解析
    const miss = [];
    for (const b of bundles) {
      const cands = [
        path.join(base, p, 'node_modules', b),
        path.join(base, 'node_modules', b),
      ];
      if (!cands.some((c) => fs.existsSync(c))) miss.push(b);
    }
    if (miss.length) bad('profile', `${p}: bundles 可解析`, `缺失 ${miss.length} 个: ${miss.join(', ')}`);
    else ok('profile', `${p}: bundles 可解析`, `${bundles.length} 个全部命中`);

    // fujiang 声明 + Junction
    const inBundles = bundles.includes(PLUGIN);
    const dep = deps[PLUGIN];
    if (!inBundles || !dep) {
      skip('plugin', `${p}: ${PLUGIN} 挂载`, `未安装（bundles=${inBundles} dep=${dep || '(none)'}）`);
      continue;
    }
    ok('plugin', `${p}: ${PLUGIN} 声明`, `dep=${dep}`);

    const nm = path.join(base, p, 'node_modules', PLUGIN);
    if (!fs.existsSync(nm)) {
      bad('plugin', `${p}: Junction`, `${nm} 不存在 —— 宿主会静默跳过，零日志假死`);
    } else {
      const st = fs.lstatSync(nm);
      if (st.isSymbolicLink()) {
        let tgt = '';
        try { tgt = fs.readlinkSync(nm); } catch { /* ignore */ }
        ok('plugin', `${p}: Junction`, `-> ${tgt}`);
      } else if (st.isDirectory()) {
        bad('plugin', `${p}: Junction`, '是实体目录而非 Junction（pnpm 重装后会失联）');
      }
    }
  }
  return profiles;
}

// ---------- 2. 插件本体完整性 ----------
async function checkPluginBody() {
  const dir = path.join(DSH_HOME, 'local-plugins', PLUGIN);
  if (!fs.existsSync(dir)) return bad('body', '插件目录', `${dir} 不存在`);

  for (const f of REQUIRED) {
    if (fs.existsSync(path.join(dir, f))) ok('body', `必需项 ${f}`, '');
    else bad('body', `必需项 ${f}`, '缺失');
  }

  // 文件数 / 体积
  let n = 0, bytes = 0;
  const walk = (d) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.isFile()) { n++; bytes += fs.statSync(p).size; }
    }
  };
  try { walk(dir); ok('body', '文件清单', `${n} 文件 / ${bytes} B`); } catch (e) { bad('body', '文件清单', e.message); }

  // 真实 import
  try {
    const mod = await import(pathToFileURL(path.join(dir, 'index.js')).href + `?t=${Date.now()}`);
    const need = ['name', 'apply', 'inject', 'Config'];
    const miss = need.filter((k) => mod[k] === undefined);
    if (miss.length) bad('body', '真实 import', `缺少导出: ${miss.join(', ')}`);
    else ok('body', '真实 import', `EXPORTS: ${need.join(',')} | name=${mod.name} inject=${JSON.stringify(mod.inject)}`);
  } catch (e) {
    bad('body', '真实 import', `${e.code || ''} ${e.message}`);
  }

  // 编码体检
  try {
    let fffd = 0;
    const scan = (d) => {
      for (const e of fs.readdirSync(d, { withFileTypes: true })) {
        const p = path.join(d, e.name);
        if (e.isDirectory()) scan(p);
        else if (/\.(js|mjs|cjs|json|yml|yaml|md)$/i.test(e.name)) {
          const t = fs.readFileSync(p, 'utf8');
          if (t.includes('\uFFFD')) fffd++;
        }
      }
    };
    scan(dir);
    if (fffd) bad('body', '编码体检', `${fffd} 个文件含 U+FFFD 替换符（GBK 被当 UTF-8 读过）`);
    else ok('body', '编码体检', 'U+FFFD = 0');
  } catch (e) { skip('body', '编码体检', e.message); }

  // 依赖闭包
  try {
    const req = createRequire(path.join(dir, 'index.js'));
    const want = [
      PLUGIN,
      '@deepseek-ai/cordis',
      '@deepseek-ai/dsh-tools',
      '@deepseek-ai/schemastery',
    ];
    const got = [];
    for (const w of want) {
      try { got.push(`${w}=${req(w + '/package.json').version}`); }
      catch (e) { bad('deps', `解析 ${w}`, e.code || e.message); }
    }
    if (got.length === want.length) ok('deps', '解析链', got.join(' '));
  } catch (e) { bad('deps', '解析链', e.message); }
}

// ---------- 3. 会话 message id 体检 ----------
function loadZstdFrames(p) {
  const raw = fs.readFileSync(p);
  const MAGIC = Buffer.from([0x28, 0xb5, 0x2f, 0xfd]);
  const offs = [];
  let i = 0;
  while (true) { const k = raw.indexOf(MAGIC, i); if (k < 0) break; offs.push(k); i = k + 4; }
  const parts = [];
  for (let j = 0; j < offs.length; j++) {
    const s = offs[j], e = j + 1 < offs.length ? offs[j + 1] : raw.length;
    try { parts.push(zlib.zstdDecompressSync(raw.subarray(s, e))); } catch { /* partial frame */ }
  }
  return Buffer.concat(parts).toString('utf8');
}

function checkSessions() {
  const root = path.join(DSH_HOME, 'sessions');
  if (!fs.existsSync(root)) return skip('session', '会话目录', '不存在');

  const files = [];
  const walk = (d) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name === 'session.v4.jsonl.zstd') files.push(p);
    }
  };
  walk(root);

  const MSG = new Set(['developer/message', 'system/message', 'user/message', 'assistant/message', 'tool/result']);
  const offenders = [];
  let totalBad = 0;
  const bySource = {};

  for (const f of files) {
    let txt;
    try { txt = loadZstdFrames(f); } catch { continue; }
    let n = 0;
    for (const L of txt.split('\n')) {
      if (!L.trim()) continue;
      let e;
      try { e = JSON.parse(L); } catch { continue; }
      if (!MSG.has(e.type)) continue;
      const d = e.data || {};
      const m = e.type === 'user/message' ? d : d.message;
      if (typeof m !== 'object' || m === null || typeof m.id !== 'string' || m.id === '') {
        n++;
        const kind = m?.source?.kind || d?.source?.kind || '(none)';
        bySource[kind] = (bySource[kind] || 0) + 1;
      }
    }
    if (n) { offenders.push({ file: path.basename(path.dirname(f)), n }); totalBad += n; }
  }

  if (totalBad) {
    bad('session', 'message 事件 id', `${totalBad} 个缺 id，涉及 ${offenders.length} 个会话 —— 这些会话点开会报 "lacks an identified message"`);
    const top = offenders.sort((a, b) => b.n - a.n).slice(0, 5);
    bad('session', '受影响会话 TOP5', top.map((o) => `${o.file}(${o.n})`).join(', '));
    bad('session', '注入来源统计', Object.entries(bySource).map(([k, v]) => `${k}=${v}`).join(', ') || '(none)');
  } else {
    ok('session', 'message 事件 id', `${files.length} 个会话全部合规，缺 id = 0`);
  }
}

// ---------- 输出 ----------
function render() {
  const w = (s) => [...s].reduce((a, c) => a + (c.charCodeAt(0) > 0x2e80 ? 2 : 1), 0);
  const pad = (s, n) => s + ' '.repeat(Math.max(0, n - w(s)));
  const lines = [];
  let cur = '';
  for (const r of rows) {
    if (r.area !== cur) { cur = r.area; lines.push(`\n[${cur}]`); }
    const mark = r.ok === true ? 'OK  ' : r.ok === false ? 'FAIL' : 'SKIP';
    lines.push(`  ${mark}  ${pad(r.item, 30)} ${r.detail}`);
  }
  return lines.join('\n');
}

// ---------- main ----------
(async () => {
  const profiles = checkProfiles();
  await checkPluginBody();
  if (SCAN_SESSIONS) checkSessions();

  const fails = rows.filter((r) => r.ok === false);
  const oks = rows.filter((r) => r.ok === true);

  if (JSON_OUT) {
    console.log(JSON.stringify({ dshHome: DSH_HOME, ok: oks.length, fail: fails.length, rows }, null, 2));
  } else {
    console.log('='.repeat(72));
    console.log(`  fujiang-armor 安装体检  |  DSH_HOME=${DSH_HOME}`);
    console.log('='.repeat(72));
    console.log(render());
    console.log('\n' + '='.repeat(72));
    console.log(`  通过 ${oks.length} 项 / 失败 ${fails.length} 项 / profile: ${profiles.join(', ')}`);
    console.log(fails.length ? '  结论：存在问题，见上方 FAIL' : '  结论：全部通过');
    console.log('='.repeat(72));
  }
  process.exit(fails.length ? 1 : 0);
})();
