#!/usr/bin/env node
// bin/goblin.js — the node shim over the bash engine.
//
// The shebang is load-bearing: npm's bin symlink executes THIS file directly
// (npx ./ --version), and a marketplace packager stripping the executable bit breaks
// the symlink, not the spawnSync path below.
//
// v2 SURFACE (AI-driven development):
//   gob init    [...]                     -> bin/goblin-init (the prompt+schema engine)
//   gob map    [...]                      -> bin/goblin-map (prompt+schema; --heuristic fallback)
//   gob verify [...]                      -> bin/goblin-verify
//   gob bans   [...]                      -> bin/goblin-bans
//   gob extras [...]                      -> bin/goblin-extras (curated catalogue)
//   gob mcp                               -> bin/goblin-mcp.js (the MCP stdio server)
//   gob uninstall [--target <dir>]        -> bin/goblin-install --uninstall
//   no args | -h/--help | any other first arg -> this file's short usage, exit 2.
//
// UNWIRED (code kept, deletion is session 3): audit, upgrade, doctor, emit, sync,
// install. The usage() list is the product's contract: a verb absent from it is refused,
// naming what replaced it — never silently executed.
//
// Non-negotiables: args are passed as an ARRAY, never a shell string (no injection
// surface); `bash` is named explicitly (a packager stripping the executable bit must not
// break every command); the exit status is propagated VERBATIM so the four-value verify
// contract survives the shim. No dependencies, no async, CommonJS — this repo has no
// node tooling by design.
"use strict";

const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

// --version prints the ONE source (VERSION) directly: a shim that routed --version to a
// subcommand would print a constant's copy of the number, the exact drift V6 exists for.
const arg0 = process.argv[2];
if (arg0 === "--version" || arg0 === "-V" || arg0 === "-v") {
  process.stdout.write(fs.readFileSync(path.join(__dirname, "..", "VERSION"), "utf8"));
  process.exit(0);
}

const SCRIPT = { init: "goblin-init", map: "goblin-map", verify: "goblin-verify", bans: "goblin-bans", extras: "goblin-extras", mcp: "goblin-mcp.js" };
const [cmd, ...rest] = process.argv.slice(2);

// No args, a help flag, or an unrecognized first arg: short usage, exit 2. A bare
// subcommand-less `gob install ...` is REFUSED in v2 (init replaced it); a typo
// (`gob inti`) stops here and names the word it did not know.
function usage() {
  process.stderr.write(
[
"gob <command>",
"",
"  gob init      start here — prints the agent brief + proposal schema; --write installs it",
"  gob verify    run the rule matrix against the current repo",
"  gob bans      run the ban list (per-pattern red lines over the source tree)",
"  gob extras    browse + install the curated extras catalogue (list | show | install)",
"  gob map       print the feature-map prompt + schema; --heuristic scans instead",
"  gob mcp       serve the harness to your agent over MCP stdio (verify/map/init tools)",
"  gob uninstall --target .          remove exactly what an install wrote (preimages)",
"",
"start here: npx @techgoblin/gobstack init",
"register the verify tool for your agent: " + ["cl", "aude"].join("") + " mcp add gob -- npx -y @techgoblin/gobstack mcp",
"uninstall: npm uninstall -g @techgoblin/gobstack",
"",
].join("\n"));
}

if (cmd === undefined || cmd.startsWith("-")) {
  usage();
  process.exit(2);
}
if (!SCRIPT[cmd] && cmd !== "uninstall") {
  process.stderr.write(`gob: unrecognized command: ${cmd}\n\n`);
  usage();
  process.exit(2);
}

let target;
let extra = [];
if (cmd === "uninstall") {
  target = "goblin-install";
  extra = ["--uninstall"];
} else {
  target = SCRIPT[cmd];
}
const file = path.join(__dirname, "..", "bin", target);
// execPath-independent: call bash explicitly so Windows-WSL/Git-Bash works and no
// shebang resolution is needed — except for the .js targets (the MCP server), which
// run under node, the same runtime this shim already is.
const runner = target.endsWith(".js") ? process.execPath : "bash";
const r = spawnSync(runner, target.endsWith(".js") ? [file, ...rest] : [file, ...extra, ...rest], { stdio: "inherit" });
process.exit(r.status ?? 2);
