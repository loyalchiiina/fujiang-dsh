#!/usr/bin/env node
/**
 * sync-lock.mjs —— 把插件写进 profile 的 pnpm-lock.yaml importer
 *
 * 为什么需要：内核不跑 pnpm install，但 pnpm-lock.yaml 的 importer 是
 * 「这个 profile 装了哪些包」的权威账本。缺了这条，将来任何一次
 * `pnpm install` 都会把 node_modules\<插件> 的 Junction 抹掉，插件静默失联
 * （宿主不报错、日志零 warn，表现为"装好的插件突然不见了"）。
 *
 * 本脚本只做一件事：在 importer "." 的 dependencies 下幂等插入
 *   <name>:
 *     specifier: link:<abs>
 *     version: link:<rel>
 * 已存在则输出 NOCHANGE，绝不重复插入。
 *
 * 用法：
 *   node sync-lock.mjs <profileDir> <pluginName> <linkTargetAbs> [--remove]
 * 输出：
 *   PATCHED <lockfile>         已写入
 *   NOCHANGE <lockfile>        已有，未改
 *   NOLOCK                      该 profile 没有 pnpm-lock.yaml（跳过）
 *   REMOVED <lockfile>          已移除
 *   ERROR:<msg>                 失败
 */

import fs from 'node:fs';
import path from 'node:path';

const [profileDir, pluginName, linkTarget, ...rest] = process.argv.slice(2);
const remove = rest.includes('--remove');

if (!profileDir || !pluginName || (!linkTarget && !remove)) {
  console.log('ERROR:用法 node sync-lock.mjs <profileDir> <pluginName> <linkTargetAbs> [--remove]');
  process.exit(2);
}

const lockPath = path.join(profileDir, 'pnpm-lock.yaml');
if (!fs.existsSync(lockPath)) {
  console.log('NOLOCK');
  process.exit(0);
}

// 安全闸：只允许改「package.json 里确实声明了该插件」的 profile，
// 否则会往无关 profile 的账本里塞垃圾条目（踩过：xiufu 被误写）。
if (!remove) {
  const pj = path.join(profileDir, 'package.json');
  let declared = false;
  try {
    let raw = fs.readFileSync(pj, 'utf8');
    if (raw.charCodeAt(0) === 0xfeff) raw = raw.slice(1);
    const pkg = JSON.parse(raw);
    const bundles = pkg?.dsh?.profile?.bundles || [];
    const deps = pkg?.dependencies || {};
    declared = bundles.includes(pluginName) && Boolean(deps[pluginName]);
  } catch { /* 读不到就按未声明处理 */ }
  if (!declared) {
    console.log('NOTARGET');
    process.exit(0);
  }
}

let text = fs.readFileSync(lockPath, 'utf8');
const hasEntry = new RegExp(`^\\s{6}${pluginName.replace(/[/\\@.]/g, (c) => '\\' + c)}:\\s*$`, 'm').test(text);

if (remove) {
  if (!hasEntry) { console.log('NOCHANGE ' + lockPath); process.exit(0); }
  const bak = lockPath + '.bak-' + new Date().toISOString().replace(/[-:T.Z]/g, '').slice(0, 15) + '-fujiang-armor';
  fs.copyFileSync(lockPath, bak);
  const lines = text.split(/\r?\n/);
  const out = [];
  for (let i = 0; i < lines.length; i++) {
    if (new RegExp(`^\\s{6}${pluginName.replace(/[/\\@.]/g, (c) => '\\' + c)}:\\s*$`).test(lines[i])) {
      // 跳过本条目及其后两行（specifier / version）
      let j = i + 1;
      while (j < lines.length && /^\s{8}\S/.test(lines[j])) j++;
      i = j - 1;
      continue;
    }
    out.push(lines[i]);
  }
  fs.writeFileSync(lockPath, out.join('\n'), 'utf8');
  console.log('REMOVED ' + lockPath);
  process.exit(0);
}

if (hasEntry) { console.log('NOCHANGE ' + lockPath); process.exit(0); }

// 相对路径：从 <profileDir>/node_modules/<name> 视角指向 linkTarget
// pnpm 的 version 字段是相对 <profileDir> 的路径
const rel = path.relative(profileDir, path.resolve(linkTarget)).replace(/\\/g, '/');
const abs = path.resolve(linkTarget).replace(/\\/g, '/');

const lines = text.split(/\r?\n/);
const iDot = lines.findIndex((l) => /^ {2}\.:\s*(\{\})?\s*$/.test(l));
if (iDot < 0) { console.log('ERROR:未找到 importer "."'); process.exit(1); }

const ins = [
  `      ${pluginName}:`,
  `        specifier: link:${abs}`,
  `        version: link:${rel}`,
];

if (/\{\}\s*$/.test(lines[iDot])) {
  lines[iDot] = '  .:';
  lines.splice(iDot + 1, 0, '    dependencies:', ...ins);
} else if (/^ {4}dependencies:\s*$/.test(lines[iDot + 1] || '')) {
  lines.splice(iDot + 2, 0, ...ins);
} else {
  lines.splice(iDot + 1, 0, '    dependencies:', ...ins);
}

const bak = lockPath + '.bak-' + new Date().toISOString().replace(/[-:T.Z]/g, '').slice(0, 15) + '-fujiang-armor';
fs.copyFileSync(lockPath, bak);

const out = lines.join('\n');
fs.writeFileSync(lockPath, out, 'utf8');

// 若本机有 js-yaml 则做一次语法复验（找不到就跳过，不阻断）
let chk = '';
try {
  const yaml = await import('file:///C:/Users/Administrator/.dsh/profiles/node_modules/js-yaml/index.js');
  const d = (yaml.default || yaml).load(out);
  const imp = d?.importers?.['.'] || {};
  chk = ` | YAML OK deps=${Object.keys(imp.dependencies || {}).length}`;
} catch { /* 无 js-yaml，跳过 */ }

console.log('PATCHED ' + lockPath + chk);
