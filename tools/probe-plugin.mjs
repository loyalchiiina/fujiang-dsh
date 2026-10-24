// probe-plugin.mjs — 插件自检：语法外的真实模块加载 + 依赖解析
// 用法: node probe-plugin.mjs <pluginDir>
import { pathToFileURL } from "node:url";
import { join } from "node:path";

const dir = process.argv[2];
if (!dir) { console.log("PROBE_FAIL:no-arg"); process.exit(2); }

const url = pathToFileURL(join(dir, "index.js")).href;
try {
  const m = await import(url);
  const need = ["name", "apply", "inject", "Config"];
  const miss = need.filter((k) => !(k in m));
  if (miss.length) { console.log("PROBE_FAIL:missing-exports:" + miss.join(",")); process.exit(1); }
  console.log("PROBE_OK:" + Object.keys(m).join(","));
} catch (e) {
  const code = e.code || e.name || "ERR";
  const msg = String(e.message || e).split("\n")[0];
  console.log("PROBE_FAIL:" + code + ":" + msg);
  process.exit(1);
}
