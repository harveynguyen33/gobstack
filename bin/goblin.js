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
//   goblin init   [...]                   -> bin/goblin-init (W6, the first-run wizard)
//   goblin uninstall [--target <dir>]     -> bin/goblin-install --uninstall
//   goblin install [...]                  -> bin/goblin-install (the one legacy fallback)
//   no args | -h/--help | any other unrecognized first arg
//                                         -> this file's short usage, exit 2. A bare `goblin`
//                                            used to fall through into the installer; a typo
//                                            (`goblin inti`) silently installed too. Both now
//                                            print the usage and stop.
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

const SCRIPT = { verify: "goblin-verify", bans: "goblin-bans", audit: "goblin-audit", upgrade: "goblin-upgrade", doctor: "goblin-doctor", emit: "goblin-emit", init: "goblin-init" };
const [cmd, ...rest] = process.argv.slice(2);

// No args, a help flag, or an unrecognized first arg: short usage, exit 2. The one survivor of
// the old catch-all fallback is the literal `install` first arg — bare `goblin` mapped to the
// installer through npm's bin default, and a typo (`goblin inti`) silently installed into
// whatever directory the shell sat in. A bare subcommand-less `goblin install ...` keeps the
// installer; everything else stops here and names the word it did not know.
function usage() {
  process.stderr.write(
[
"goblin <command>",
"",
"  goblin init      start here — the guided first step (detect, class, emit, first verify)",
"  goblin verify    run the rule matrix against the current repo",
"  goblin bans      run the ban list (per-pattern red lines over the source tree)",
"  goblin audit     check recorded dependency claims against live advisory feeds",
"  goblin upgrade   migrate a repo to the shared global engine at ~/.goblin/engine",
"  goblin doctor    one detection/drift run across the agent platforms",
"  goblin emit      write the skills + context block for one platform",
"  goblin uninstall --target .        remove exactly what an install wrote (preimages)",
"",
"start here: goblin init",
"uninstall: npm uninstall -g @techgoblin/gobstack",
"",
].join("\n"));
}

if (cmd === undefined || cmd.startsWith("-")) {
  usage();
  process.exit(2);
}
if (!SCRIPT[cmd] && cmd !== "install" && cmd !== "uninstall") {
  process.stderr.write(`goblin: unrecognized command: ${cmd}\n\n`);
  usage();
  process.exit(2);
}

let target;
let extra = [];
if (cmd === "install") {
  target = "goblin-install"; // the one legacy fallback, kept verbatim
} else if (cmd === "uninstall") {
  // `goblin uninstall --target <dir>` routes into the installer's uninstall job — the shape
  // docs/GUIDE.md and README already promise. `--uninstall` is appended FIRST so the user's
  // own `--target <dir>` and options still parse, and a stray literal `--uninstall` cannot
  // appear twice.
  target = "goblin-install";
  extra = ["--uninstall"];
} else {
  target = SCRIPT[cmd];
}
const file = path.join(__dirname, "..", "bin", target);
// execPath-independent: call bash explicitly so Windows-WSL/Git-Bash works and no
// shebang resolution is needed.
const r = spawnSync("bash", [file, ...extra, ...rest], { stdio: "inherit" });
process.exit(r.status ?? 2);
