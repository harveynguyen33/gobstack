#!/usr/bin/env node
// bin/goblin.js — the node shim over the bash engine (W2, PLAN-V1 §4.3).
//
// The shebang is load-bearing: the §4.3 body always calls bash with the payload
// explicitly, but npm's bin symlink executes THIS file directly (npx ./ --version),
// and a marketplace packager stripping the executable bit breaks the symlink, not
// the spawnSync path below.
//
//   goblin verify [--only <id,...>] ...   -> bin/goblin-verify
//   goblin bans   [...]                   -> bin/goblin-bans
//   goblin audit  [...]                   -> bin/goblin-audit
//   goblin upgrade [...]                  -> bin/goblin-upgrade (W3)
//   goblin doctor [...]                   -> bin/goblin-doctor (W4a)
//   goblin emit   [...]                   -> bin/goblin-emit (W4a)
//   anything else (init)                  -> bin/goblin-install
//
// Non-negotiables (§4.3): args are passed as an ARRAY, never a shell string (no
// injection surface); `bash` is named explicitly (a packager stripping the
// executable bit must not break every command); the exit status is propagated
// VERBATIM so the four-value verify contract survives the shim. No dependencies,
// no async, CommonJS — this repo has no node tooling by design.
//
// The payload/ re-point happens with packaging (W3/W5): the npm tarball moves the
// bash payload under payload/, so this line becomes path.join(__dirname, "..", "payload", "bin", target).
// Until then the shim runs straight out of the checkout layout.
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

const SCRIPT = { verify: "goblin-verify", bans: "goblin-bans", audit: "goblin-audit", upgrade: "goblin-upgrade", doctor: "goblin-doctor", emit: "goblin-emit" };
const [cmd, ...rest] = process.argv.slice(2);
const target = SCRIPT[cmd] ?? "goblin-install"; // init → goblin-install (v1)
const file = path.join(__dirname, "..", "bin", target);
// execPath-independent: call bash explicitly so Windows-WSL/Git-Bash works and no
// shebang resolution is needed.
const r = spawnSync("bash", [file, ...rest], { stdio: "inherit" });
process.exit(r.status ?? 2);
