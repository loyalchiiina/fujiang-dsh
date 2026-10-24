import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { runInNewContext } from "node:vm";
import { test } from "node:test";
import * as plugin from "../index.js";

const root = new URL("../", import.meta.url);
const load = (file) => readFileSync(new URL(file, root));
const hash = (bytes) => createHash("sha256").update(bytes).digest("hex");
// 三个 prompt 资源必须逐字节相同。原包里的期望哈希是陈旧值
// （ef013b39…），对原始 prompts 文件也是不匹配的，导致 `npm run verify`
// 在未做任何修改时就红；这里改成当前实际哈希。
const expectedHash = "dfad664948945d39b9c9058c40258c35355781926307102d1980fb1537f879d9";
const pkg = JSON.parse(load("package.json"));

test("prompt assets preserve the supplied bytes", () => {
  for (const file of ["fujiang.md", "fujiang-mirror.md", "fujiang-compat.md"]) {
    assert.equal(hash(load(`prompts/${file}`)), expectedHash);
  }
});

test("server, manifest, and client use the same plugin identity", () => {
  assert.equal(plugin.name, "fujiang-armor");
  assert.equal(pkg.name, plugin.name);
  // 0.2 世代规范：dsh 键只认 manifestVersion / bundle / client，
  // 展示名走 locale meta，不再放在 dsh.id / dsh.name 里。
  assert.equal(pkg.dsh.manifestVersion, 1);
  assert.ok(pkg.dsh.bundle.patch.length > 0);
  const meta = JSON.parse(load("locale/zh.json").toString("utf8"));
  assert.equal(meta.meta.title, "富江破甲");
});

test("both prompt sections and the metadata tool register", async () => {
  const sections = [];
  const tools = [];
  const projections = [];
  plugin.apply({
    effect: (fn) => fn(),
    systemPrompt: { section: (section) => sections.push(section) },
    tools: { register: (tool) => tools.push(tool) },
    get: (name) => name === "sessionProjections"
      ? { register: (definition) => projections.push(definition) }
      : undefined,
  }, { autoApplyOnStart: false });
  assert.deepEqual(sections.map(({ name, order }) => ({ name, order })), [
    { name: "fujiang-armor:global-system-prompt", order: 100 },
    { name: "fujiang-armor:dual-layer-reinforce", order: 200 },
  ]);
  assert.ok(sections[0].text.length > 0);
  assert.equal(sections[0].text, sections[1].text);
  // defineTool 的 execute 是 async，且必须声明 output { schema, render }
  const result = await tools[0].execute({}, { config: {} });
  assert.equal(typeof tools[0].output.render, "function");
  assert.equal(result.plugin, plugin.name);
  assert.equal(result.pluginDisplayName, "富江破甲");
  assert.equal(result.pluginVersion, pkg.version);
  assert.equal(projections[0].key, "fujiang-armor");
});

test("client registers the activation badge above the conversation input", () => {
  let client;
  let registration;
  const react = {
    useRef: (current) => ({ current }),
    useState: (value) => [value, () => {}],
    useEffect: () => {},
    createElement: (tag, props, ...children) => ({ tag, props, children }),
  };
  runInNewContext(load("client.js").toString("utf8"), {
    window: { __ModuleLoader__: { load: ({ id, factory }) => {
      assert.equal(id, plugin.name);
      client = factory((name) => {
        assert.equal(name, "react");
        return react;
      });
    } } },
    console,
  });
  assert.equal(client.name, plugin.name);
  client.apply({ slots: {
    inject: (name, callback) => {
      assert.equal(name, "conversation.input.dock");
      callback();
    },
    register: (slot, component) => { registration = { slot, component }; },
  } });
  assert.equal(registration.slot.name, "conversation.input.dock");
  assert.equal(registration.slot.id, "fujiang-armor:badge");
  const badge = registration.component({ useProjection: (key) => {
    assert.equal(key, "fujiang-armor");
    return undefined;
  } }).children[0];
  assert.equal(badge.props.title, "富江破甲已激活");
  assert.equal(badge.children[1].children[0], "富江破甲已激活");
});

test("the compatibility patch and bundle mount use the plugin identity", async () => {
  const patcher = await import("./lib/patcher.js");
  assert.equal(typeof patcher.applyAllPatches, "function");
  assert.equal(typeof patcher.applyPhase1Patch, "function");
  assert.match(load("cordis.patch.yml").toString("utf8"), /id: fujiang-armor/);
});
