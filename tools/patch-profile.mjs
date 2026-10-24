// patch-profile.mjs — 幂等修改 DSH profile 的 package.json（BOM 容错）
// 用法: node patch-profile.mjs <profileDir> <pluginName> <linkTarget> [--remove]
import { readFileSync, writeFileSync, existsSync, copyFileSync } from "node:fs";
import { join } from "node:path";

const [profileDir, pluginName, linkTarget, flag] = process.argv.slice(2);
if (!profileDir || !pluginName || !linkTarget) {
  console.error("usage: node patch-profile.mjs <profileDir> <pluginName> <linkTarget> [--remove]");
  process.exit(2);
}
const pkgPath = join(profileDir, "package.json");
if (!existsSync(pkgPath)) { console.error("NOT_FOUND " + pkgPath); process.exit(3); }

// BOM / UTF-16 / 空白容错
let raw = readFileSync(pkgPath, "utf8");
if (raw.charCodeAt(0) === 0xfeff) raw = raw.slice(1);
raw = raw.replace(/^\uFEFF/, "").trim();
if (!raw) { console.error("EMPTY " + pkgPath); process.exit(3); }

let pkg;
try { pkg = JSON.parse(raw); }
catch (e) { console.error("BAD_JSON " + pkgPath + " :: " + e.message.split("\n")[0]); process.exit(4); }

const remove = flag === "--remove";
const linkSpec = "link:" + linkTarget.replace(/\\/g, "/");

pkg.dependencies = pkg.dependencies ?? {};
pkg.dsh = pkg.dsh ?? {};
pkg.dsh.profile = pkg.dsh.profile ?? {};
pkg.dsh.profile.bundles = Array.isArray(pkg.dsh.profile.bundles) ? pkg.dsh.profile.bundles : [];

const changes = [];
if (remove) {
  if (pkg.dependencies[pluginName] !== undefined) { delete pkg.dependencies[pluginName]; changes.push("dep-removed"); }
  const i = pkg.dsh.profile.bundles.indexOf(pluginName);
  if (i >= 0) { pkg.dsh.profile.bundles.splice(i, 1); changes.push("bundle-removed"); }
} else {
  if (pkg.dependencies[pluginName] !== linkSpec) { pkg.dependencies[pluginName] = linkSpec; changes.push("dep=" + linkSpec); }
  if (!pkg.dsh.profile.bundles.includes(pluginName)) { pkg.dsh.profile.bundles.push(pluginName); changes.push("bundle-added"); }
}

if (changes.length === 0) { console.log("NOCHANGE"); process.exit(0); }

const stamp = new Date().toISOString().replace(/[-:T.Z]/g, "").slice(0, 14);
copyFileSync(pkgPath, pkgPath + ".bak-" + stamp + "-fujiang-armor");
writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n", "utf8");
console.log("PATCHED " + changes.join(","));
