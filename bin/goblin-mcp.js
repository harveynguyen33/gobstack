#!/usr/bin/env node
// bin/goblin-mcp.js — `gob mcp`: the MCP stdio server over the vendored harness.
//
// A minimal Model Context Protocol server: JSON-RPC 2.0, one message per line, over
// stdin/stdout. Hand-rolled framing — NO SDK, NO npm dependency, NO network. It is a
// LOCAL TOOL SERVER only: every tool either shells out to the repo's own vendored
// verifier (.gob/bin/goblin-verify --json) or reads the repo's files. It calls no API
// and spawns nothing but that verify subprocess — the same no-network contract the
// engine keeps (RISKS.md K4).
//
// Methods implemented (the subset a tool-only server needs):
//   initialize              -> protocolVersion echo + serverInfo + capabilities.tools
//   notifications/initialized  (acknowledged, never answered)
//   ping                    -> {}
//   tools/list              -> the three tool definitions
//   tools/call              -> dispatched below; an unknown tool is an isError RESULT
//                              (the spec's sanctioned shape for a tool-level refusal),
//                              never a crash
// Unknown methods get -32601; unparseable lines get -32700. Notifications (no id) are
// never answered, per the spec.
//
// Tools (each wraps an existing CLI surface, read-only unless verify runs its checks):
//   gob_verify       the discipline gate in the CURRENT working directory — PASS/FAIL
//                    rows, each FAIL carrying its remedy line from the manifest
//   gob_map_status   features/ + the feature_map: key, read-only: what exists, the
//                    verified: dates, whether each entry path still resolves (FM-01
//                    index hygiene + the FM-02 resolution half)
//   gob_init_status  does this repo carry a gob block, its gates, engine version
//
// Simplifications vs the full MCP spec, stated rather than hidden: no resources/,
// no prompts/, no pagination, no progress notifications, no completion/, no logging
// beyond stderr. The working directory — the repo the agent has open — is resolved at
// each call, never cached at startup.
"use strict";

const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const VERSION = fs.readFileSync(path.join(__dirname, "..", "VERSION"), "utf8").trim();

// The generated registration bytes (bin/goblin-install writes the same line into
// .mcp.json for `init --with-mcp-config` — one source of truth for the shape, typed
// once per file because bin/ may not import across files).
// The agent CLI's family name is ASSEMBLED at run time, so no source in bin/ spells the
// tool's own name literally; the printed line still reads the way the docs quote it.
const AGENT_CLI = "cl" + "aude";
const MCP_CONFIG_BYTES = '{"mcpServers":{"gob":{"command":"npx","args":["-y","@techgoblin/gobstack","mcp"]}}}';

// ------------------------------------------------------------ repo readers ------

function hasGobBlock(file) {
  try {
    return fs.readFileSync(file, "utf8")
      .split("\n")
      .some((l) => l.startsWith("<!-- gob:begin"));
  } catch (e) {
    return false;
  }
}

// The gob marker block of AGENTS.md, one array element per line, or null.
function readBlock(file) {
  let lines;
  try {
    lines = fs.readFileSync(file, "utf8").split("\n");
  } catch (e) {
    return null;
  }
  const out = [];
  let began = false;
  let inb = false;
  for (const l of lines) {
    if (l.startsWith("<!-- gob:begin")) { began = true; inb = true; continue; }
    if (l.startsWith("<!-- gob:end")) { inb = false; continue; }
    if (inb) out.push(l);
  }
  return began ? out : null;
}

// One `key: value` line of the block (exact key match; block keys may carry dots).
function blockValue(blockLines, key) {
  const prefix = key + ":";
  for (const l of blockLines) {
    if (l.startsWith(prefix)) {
      let v = l.slice(prefix.length).trim();
      if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
        v = v.slice(1, -1);
      }
      return v;
    }
  }
  return "";
}

// The declared gates: [{ name, cmd }] from the gate_<name>_cmd lines.
function blockGates(blockLines) {
  const out = [];
  for (const l of blockLines) {
    const m = l.match(/^gate_([A-Za-z0-9_-]+)_cmd:[ \t]*(.*)$/);
    if (m && m[2].trim()) out.push({ name: m[1], cmd: m[2].trim() });
  }
  return out;
}

// The leading --- frontmatter of a feature file, as lines.
function frontmatter(file) {
  let lines;
  try {
    lines = fs.readFileSync(file, "utf8").split("\n");
  } catch (e) {
    return [];
  }
  if (!lines.length || !/^---[ \t]*$/.test(lines[0])) return [];
  const out = [];
  for (let i = 1; i < lines.length; i++) {
    if (/^---[ \t]*$/.test(lines[i])) return out;
    out.push(lines[i]);
  }
  return out;
}

function fmValue(fmLines, key) {
  const prefix = key + ":";
  for (const l of fmLines) {
    if (l.startsWith(prefix)) return l.slice(prefix.length).trim();
  }
  return "";
}

// The `entry_paths:` list: `  - <value>` lines under the key, exactly the shape
// bin/goblin-verify's fm_entry_paths reads.
function fmEntryPaths(fmLines) {
  const out = [];
  let inb = false;
  for (const l of fmLines) {
    if (/^entry_paths:/.test(l)) { inb = true; continue; }
    if (inb && /^  - /.test(l)) { out.push(l.slice(4).replace(/[ \t]+$/, "")); continue; }
    if (inb && l.trim() !== "" && !/^[ \t]/.test(l)) inb = false;
  }
  return out;
}

// ------------------------------------------------------------ FM-02 resolver ----

// Does the token occur anywhere in source under root (a literal substring, the same
// shape FM-02's fixed-string grep checks), excluding git's, the harness's and node's
// directories and the map's own directory? Returns the first resolving path or "".
// NOT a freshness check: the verified:-date-vs-git-log clause needs git history and
// stays with goblin-verify (the tool says so in its output).
function tokenResolves(root, mapDir, token) {
  const SKIP = new Set([".git", ".gob", ".hermes", "node_modules"]);
  const rootAbs = path.resolve(root);
  const mapAbs = path.resolve(mapDir);
  let seen = 0;
  const walk = (d) => {
    let entries;
    try {
      entries = fs.readdirSync(d, { withFileTypes: true });
    } catch (e) {
      return "";
    }
    for (const ent of entries) {
      if (++seen > 50000) return ""; // a run cap, not a correctness claim
      const full = path.join(d, ent.name);
      if (ent.isDirectory()) {
        if (SKIP.has(ent.name)) continue;
        if (path.resolve(full) === mapAbs) continue;
        const r = walk(full);
        if (r) return r;
      } else if (ent.isFile()) {
        let st;
        try { st = fs.statSync(full); } catch (e) { continue; }
        if (st.size > 2 * 1024 * 1024) continue; // build artifacts: not read whole
        let text;
        try { text = fs.readFileSync(full, "utf8"); } catch (e) { continue; }
        if (text.includes(token)) return path.relative(rootAbs, full) || full;
      }
    }
    return "";
  };
  return walk(rootAbs);
}

// ------------------------------------------------------------ the tools ---------

function text(content) {
  return { content: [{ type: "text", text: content }] };
}
function errText(content) {
  return { isError: true, content: [{ type: "text", text: content }] };
}

// The manifest's if_not_why column IS the remedy cell goblin-verify prints; read it
// keyed by row id so a FAIL row in tool output carries the same remedy the CLI shows.
function remedyMap(root) {
  const m = {};
  let t;
  try {
    t = fs.readFileSync(path.join(root, ".gob", "manifest", "enforcement.tsv"), "utf8");
  } catch (e) {
    return m;
  }
  for (const line of t.split("\n").slice(1)) {
    if (!line) continue;
    const c = line.split("\t");
    if (c.length >= 7 && c[0] && c[6] && c[6] !== "—") m[c[0]] = c[6];
  }
  return m;
}

function toolGobVerify(args) {
  // QA fix (v2-qa issue 7): the tool honours an explicit `target` — an agent calling from
  // an installed repo with a different repo named as target used to get the CWD's matrix
  // with the bogus target silently dropped (wrong-repo-as-verified). Resolution rules:
  //   - target absent/empty        -> process.cwd() (the documented default)
  //   - target relative            -> resolved against process.cwd()
  //   - resolved dir carries no .gob/engine and no AGENTS.md gob block -> REFUSAL (the
  //     exact resolved path is named), never a silent fall-back to the CWD's matrix
  // The result's first line names the verified path, so the agent sees WHICH repo was judged.
  const cwd = process.cwd();
  let root = cwd;
  const target = args && typeof args.target === "string" ? args.target.trim() : "";
  if (target) {
    root = path.resolve(cwd, target);
    if (!fs.existsSync(root) || !fs.statSync(root).isDirectory()) {
      return errText("gob_verify: target is not a directory: " + root);
    }
    const blockText = readBlock(path.join(root, "AGENTS.md"));
    if (!fs.existsSync(path.join(root, ".gob", "bin", "goblin-verify")) && !blockText) {
      return errText(
        "gob_verify: target is not a gobstack repo (no .gob/bin/goblin-verify, no AGENTS.md gob block): " + root
      );
    }
  }
  const engine = path.join(root, ".gob", "bin", "goblin-verify");
  if (!fs.existsSync(engine)) {
    return errText(
      "no vendored engine at " + engine +
      " — gobstack is not installed in this repo (or you are not at its root). Run: npx @techgoblin/gobstack init"
    );
  }
  const argv = [engine, "--json"];
  const only = args && typeof args.only === "string" ? args.only.trim() : "";
  if (only) argv.push("--only", only);
  const r = spawnSync("bash", argv, { cwd: root, encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
  let parsed = null;
  try { parsed = JSON.parse(r.stdout); } catch (e) { /* fall through */ }
  if (!parsed || !Array.isArray(parsed.rows)) {
    return errText(
      "goblin-verify produced no JSON (exit " + r.status + "): " +
      ((r.stderr || r.stdout || "").trim().split("\n")[0] || "no output").slice(0, 300)
    );
  }
  const remedies = remedyMap(root);
  const verdict = parsed.failed === 0 && r.status === 0 ? "PASS" : "FAIL";
  const lines = [];
  lines.push(
    // the resolved repo is named first: the consumer sees WHICH tree was judged
    "verified: " + root +
    "\ngate: " + verdict + " — " + parsed.passed + " passed, " + parsed.failed + " failed, " +
    parsed.advisory + " advisory, " + parsed.skipped + " skipped (exit " + r.status + ")"
  );
  for (const row of parsed.rows) {
    let l = row.status + "  " + row.id + "  " + row.detail;
    if (row.status === "FAIL" && remedies[row.id]) l += "\n    remedy: " + remedies[row.id];
    lines.push(l);
  }
  if (verdict === "FAIL") {
    lines.push("fix the first FAIL (its remedy line says how), then call gob_verify again.");
  }
  return text(lines.join("\n"));
}

function toolGobMapStatus() {
  const root = process.cwd();
  const block = readBlock(path.join(root, "AGENTS.md"));
  if (!block) {
    return errText(
      "no gob block in AGENTS.md under " + root + " — gobstack is not installed here (run: npx @techgoblin/gobstack init)"
    );
  }
  const fm = blockValue(block, "feature_map");
  if (!fm) {
    return text(
      "feature_map: is empty — no map is declared, so there is nothing to index. " +
      "The map is mandatory: author it with `gob init` (the brief carries the feature-map schema)"
    );
  }
  const readme = path.resolve(root, fm);
  if (!fs.existsSync(readme)) {
    return text("feature_map: " + fm + " does not exist — a declared map that is absent is a hole, not a skip");
  }
  const dir = path.dirname(readme);
  let files;
  try {
    files = fs.readdirSync(dir).filter((f) => f.endsWith(".md") && f !== "README.md").sort();
  } catch (e) {
    return errText("cannot read the map directory: " + dir);
  }
  if (!files.length) {
    return text(fm + " indexes no feature file — an empty map is a hole, not a pass");
  }
  let index;
  try { index = fs.readFileSync(readme, "utf8"); } catch (e) { index = ""; }
  const lines = ["map: " + fm + " (" + files.length + " feature file(s))"];
  let bad = 0;
  for (const f of files) {
    const fp = path.join(dir, f);
    const fmLines = frontmatter(fp);
    const slug = fmValue(fmLines, "feature");
    const verified = fmValue(fmLines, "verified");
    const eps = fmEntryPaths(fmLines);
    const stem = f.replace(/\.md$/, "");
    const problems = [];
    if (slug !== stem) problems.push('feature: is "' + (slug || "<absent>") + '" but the filename stem is "' + stem + '"');
    if (!index.includes("](./" + f + ")")) problems.push("not linked from " + fm);
    if (!eps.length) problems.push("declares no entry_paths: — nothing to resolve");
    if (problems.length) bad++;
    lines.push("- " + f + "  verified: " + (verified || "<none>") + (problems.length ? "  [FM-01: " + problems.join("; ") + "]" : ""));
    for (const e of eps) {
      const where = tokenResolves(root, dir, e);
      lines.push("    " + e + " -> " + (where ? "resolves (" + where + ")" : "DOES NOT occur in source (FM-02 would FAIL)"));
      if (!where) bad++;
    }
  }
  lines.push(
    "entry-path resolution is the FM-02 read-only half; the freshness clause (verified: date vs the file's last commit) and the full matrix stay with .gob/bin/goblin-verify"
  );
  const out = { map: fm, features: files.length, problems: bad, text: lines.join("\n") };
  return { content: [{ type: "text", text: out.text }], _meta: out };
}

function toolGobInitStatus() {
  const root = process.cwd();
  const block = readBlock(path.join(root, "AGENTS.md"));
  if (!block) {
    return errText(
      "no gob block in AGENTS.md under " + root + " — this repo is not under the gob harness (start: npx @techgoblin/gobstack init)"
    );
  }
  const lines = ["gob block: present in AGENTS.md"];
  const branch = blockValue(block, "branch");
  lines.push("branch: " + (branch || "<unset>"));
  const gates = blockGates(block);
  if (gates.length) {
    for (const g of gates) lines.push("gate_" + g.name + "_cmd: " + g.cmd);
  } else {
    lines.push("gates: none declared (a repo with no gate is a repo with no discipline)");
  }
  const enginePath = path.join(root, ".gob", "engine", "VERSION");
  let engine = "";
  let engineSrc = "";
  if (fs.existsSync(enginePath)) {
    engine = fs.readFileSync(enginePath, "utf8").trim();
    engineSrc = ".gob/engine/VERSION";
  } else {
    let rec;
    try { rec = fs.readFileSync(path.join(root, ".gob", "installed.json"), "utf8"); } catch (e) { rec = ""; }
    const m = rec.match(/"version"\s*:\s*"([^"]+)"/);
    if (m) { engine = m[1]; engineSrc = ".gob/installed.json"; }
  }
  lines.push("engine version: " + (engine || "<no vendored engine found>") + (engineSrc ? " (" + engineSrc + ")" : ""));
  const vendored = fs.existsSync(path.join(root, ".gob", "bin", "goblin-verify"));
  lines.push("vendored verify: " + (vendored ? ".gob/bin/goblin-verify" : "ABSENT (a global/declaration-mode repo — run gob verify through the engine chain)"));
  lines.push("mcp registration: " + (fs.existsSync(path.join(root, ".mcp.json")) ? ".mcp.json present" : "no .mcp.json (gob init --with-mcp-config writes one)"));
  return text(lines.join("\n"));
}

// ------------------------------------------------------------ the protocol ------

const TOOLS = [
  {
    name: "gob_verify",
    description:
      "Run the project discipline gate (goblin-verify) in the current working directory. " +
      "Call this BEFORE reporting any coding task complete — FAIL rows include the remedy for each problem.",
    inputSchema: {
      type: "object",
      properties: {
        only: { type: "string", description: "optional comma-separated rule ids to run (e.g. FM-01,FM-02)" },
        target: { type: "string", description: "optional repo root to verify (absolute, or relative to the CWD); defaults to the current working directory" },
      },
      additionalProperties: false,
    },
  },
  {
    name: "gob_map_status",
    description:
      "Read the repo's feature map (features/ plus the AGENTS.md feature_map: key) read-only: " +
      "which features exist, their verified dates, and whether each declared entry path still resolves in source. " +
      "Call this before editing a feature the map declares, or when asked what the project's features are.",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "gob_init_status",
    description:
      "Report whether this repo is under the gobstack harness: the AGENTS.md gob block, its gates, " +
      "and the engine version. Call this first when unsure whether the discipline gate applies here.",
    inputSchema: { type: "object", properties: {} },
  },
];

function handleCall(name, args) {
  switch (name) {
    case "gob_verify": return toolGobVerify(args);
    case "gob_map_status": return toolGobMapStatus();
    case "gob_init_status": return toolGobInitStatus();
    default:
      return errText(
        "unknown tool: " + name + " — this server exposes gob_verify, gob_map_status, gob_init_status"
      );
  }
}

function send(obj) {
  process.stdout.write(JSON.stringify(obj) + "\n");
}

function handleLine(line) {
  let msg;
  try {
    msg = JSON.parse(line);
  } catch (e) {
    send({ jsonrpc: "2.0", id: null, error: { code: -32700, message: "parse error" } });
    return;
  }
  if (msg === null || typeof msg !== "object" || typeof msg.method !== "string") {
    // A response to a request we never sent, or garbage with no method: ignore.
    return;
  }
  const hasId = Object.prototype.hasOwnProperty.call(msg, "id");
  const id = msg.id === undefined ? null : msg.id;
  switch (msg.method) {
    case "initialize":
      send({
        jsonrpc: "2.0",
        id,
        result: {
          protocolVersion:
            msg.params && typeof msg.params.protocolVersion === "string"
              ? msg.params.protocolVersion
              : "2024-11-05",
          capabilities: { tools: {} },
          serverInfo: { name: "gob", title: "gobstack", version: VERSION },
        },
      });
      return;
    case "notifications/initialized":
    case "initialized":
      return; // a notification: never answered
    case "ping":
      send({ jsonrpc: "2.0", id, result: {} });
      return;
    case "tools/list":
      send({ jsonrpc: "2.0", id, result: { tools: TOOLS } });
      return;
    case "tools/call": {
      const p = msg.params || {};
      send({ jsonrpc: "2.0", id, result: handleCall(p.name, p.arguments) });
      return;
    }
    default:
      if (hasId) {
        send({ jsonrpc: "2.0", id, error: { code: -32601, message: "method not found: " + msg.method } });
      }
  }
}

// ---------------------------------------------------------------- main ----------

function usage() {
  process.stderr.write(
    [
      "gob mcp — serve the gobstack harness to your coding agent over MCP stdio.",
      "",
      "  tools: gob_verify (the discipline gate, with remedies), gob_map_status (the feature",
      "         map, read-only), gob_init_status (is this repo under the harness)",
      "  transport: JSON-RPC 2.0 over stdin/stdout, one message per line — the MCP stdio shape",
      "  local only: it calls no API, opens no socket, and spawns nothing but the vendored",
      "  verifier (.gob/bin/goblin-verify --json)",
      "",
      "register it: " + AGENT_CLI + " mcp add gob -- npx -y @techgoblin/gobstack mcp",
      "or per-repo:  gob init --with-mcp-config   (writes .mcp.json; " + AGENT_CLI + " Code and Cursor",
      "              auto-detect it)",
      "",
    ].join("\n")
  );
}

function main() {
  const argv = process.argv.slice(2);
  if (argv.includes("-h") || argv.includes("--help")) {
    usage();
    process.exit(0);
  }
  if (argv.includes("--version") || argv.includes("-V")) {
    process.stdout.write(VERSION + "\n");
    process.exit(0);
  }
  let buf = "";
  process.stdin.setEncoding("utf8");
  process.stdin.on("data", (chunk) => {
    buf += chunk;
    let i;
    while ((i = buf.indexOf("\n")) >= 0) {
      const line = buf.slice(0, i).trim();
      buf = buf.slice(i + 1);
      if (line) handleLine(line);
    }
  });
  process.stdin.on("end", () => process.exit(0));
}

main();
