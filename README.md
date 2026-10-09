# gobstack

**gobstack** (npm: [`@techgoblin/gobstack`](https://www.npmjs.com/package/@techgoblin/gobstack))
installs an **executable rule manifest**, a **vendored verifier**, and an **AGENTS.md-frontmatter
config** into any project — so that an AI coding session never re-improvises, and a rule that
cannot be checked is counted rather than asserted.

Start here — `init` is the first verb, and it needs no global install:

    npx @techgoblin/gobstack init        # the agent brief + proposal schema; --write installs it

or install the CLI globally (it is a CLI, not a library):

    npm install -g @techgoblin/gobstack  # gives you the `gob` CLI (`goblin` remains as a legacy alias)

## Install

**The v2 flow is `init`-first.** `gob init` prints an AGENT BRIEF — a structured prompt telling
whichever agent is already running in the repo exactly what to scan (package.json, routes, tests,
CI configs) and what to decide (class, branch, owner email, the first gate command) — plus the
schema of the proposal file the agent writes back. `gob init --write <proposal>` validates the
proposal and installs. The heuristic detector (`--heuristic`) is a fallback that appends
pre-scanned hints to the brief; it never decides.

    npx @techgoblin/gobstack init              # print the brief + schema (the agent does the scan)
    npx @techgoblin/gobstack init --write .gob-init-proposal.md --yes
                                               # validate + install

`--write` installs into the repo: AGENTS.md (a rendered body plus the `<!-- gob:begin --> …
<!-- gob:end -->` config block in its frontmatter), `.gob/` (the vendored engine — verifier,
manifest, ban probes), `HANDOFF.md`, the `checks/` scaffold and the `.gitignore` block. That
vendored layer is why an initialized repo keeps working on machines with **no gobstack installed
at all**: the engine lives in the repo, and `bash .gob/bin/goblin-verify` on a plain `git` +
`bash` box is the only runtime the repo's gate needs.

The installer writes only paths it records, hash-compares before writing, and prints `no-op` on a
second run with the same arguments. It never overwrites `HANDOFF.md`, `AGENTS.md`, a `*-SPEC.md`,
`reviews/`, or the `.gitignore` block. Full option list and the three kinds
of file it manages: `docs/CONTRACTS.md`.

A repo that already has its own `HANDOFF.md` exits 1 on the refusal. That is the contract, not a
failure: reconcile the file rather than forcing over it — `docs/ADOPTION.md`.

**The config is the AGENTS.md frontmatter.** There is no separate config file in v2: every knob
the harness reads — class, branch, gates, ratchet, bans, replay, opt-outs — is a `key: value`
line inside the `<!-- gob:begin --> … <!-- gob:end -->` marker block at the top of `AGENTS.md`.
Edit it in place; the parser reads only that block, and the installer never rewrites it after the
first install.

**`class:` picks the preset**: **software** (the default — shipped features, PRs, review gates),
**service** (backend jobs, config, unattended runs), **game** (playable builds, perf budgets),
**research** (specs, replays, reference corpora) and **fleet** (config-of-the-agent repos).
The single letters `A`–`E` are accepted aliases. What each preset turns on is the matrix in
`docs/ADOPTION.md`.

After installing, in this order:

    cd <target> && git add -A && git commit   # the install is a change like any other
    .gob/bin/goblin-verify                    # or gob verify, anywhere in the target

**A default software-class install verifies green — `36 passed, 0 failed, 10 advisory,
31 skipped`, exit 0 — once `HANDOFF.md` names a commit that exists. Before that edit the
scaffold's `0000000` placeholder is the one expected red.** Thirty-one rows skip: the five
skill rows (`SK-01`..`SK-04`, `AU-04`) skip on the `playbooks` opt-out a skills-free install
records, then the not-yet rows (`HS-02` has no pinned pre-change commit yet; `AU-02`/`AU-03`
have no report to audit; `SC-06` has no dependency manifest to read; `PF-01` has no
measured perf baseline; `BN-01`/`BN-02`/`BN-05` have no `src/` for a ban to read, and the four
electron bans `BN-06`–`BN-09` are not in this class's `bans:` list
(`bans: [BN-01, BN-02, BN-05]`), so they skip as *not enabled* rather than as *unread*;
`FM-01`/`FM-02`/`VA-01` have no feature map; `RC-01`..`RC-04` have no reference corpus; `JG-01`
with `LP-01`..`LP-05` have no loop record, because no loop has run in this repo yet). The parts
that only a round can produce — a first review note, a gate that is not the shipped floor — pass
*vacuously* rather than failing, and `P8` (`goblin-bootstrap`) still walks them as work to do.
The measurement and the vacuous-pass reading are in `docs/CONTRACTS.md`.

## The `gob` CLI

The v2 surface is six verbs — `init`, `map`, `verify`, `bans`, `mcp`, `uninstall`. Everything
else — audit, doctor, install — is unwired in this alpha: the shim refuses the verb by name
and prints the usage.

| command | what it does |
|---|---|
| `gob init` | the first step: print the AGENT BRIEF + proposal schema; `--heuristic` appends scanned hints as a fallback; `--write <proposal> [--yes]` validates the proposal and installs; `--target <dir>` aims elsewhere; `--dry-run` validates without writing |
| `gob map` | the feature-map prompt + schema (`--heuristic [target]` runs the starter scanner); `--write <dir> [--force]` validates an agent-written map and installs it; never clobbers — an existing map refuses until `--force` |
| `gob verify` | run the rule matrix against the current repo — `PASS`/`FAIL`/`SKIP` per row, exit 0 pass · 1 a check failed · 2 could not run · 3 the manifest is broken |
| `gob bans` | run the ban list (per-pattern red lines over the source tree) |
| `gob mcp` | serve the harness to your coding agent over MCP stdio — three tools (`gob_verify`, `gob_map_status`, `gob_init_status`), local only, no SDK, no network |
| `gob uninstall` | remove everything an install wrote, byte-exactly (the same job as `goblin-install --target <dir> --uninstall` from the checkout/install tree) |

`goblin` remains as a legacy alias for every command above — existing scripts keep working, but
new commands and docs use `gob`.

## Register the harness with your agent (MCP)

`gob mcp` is a **local MCP tool server**: JSON-RPC 2.0 over stdin/stdout, hand-rolled, no SDK
and no network — it calls no API and spawns nothing but the repo's vendored verifier. It
exposes three tools:

| tool | what it does |
|---|---|
| `gob_verify` | run the project discipline gate in the repo the agent has open — `PASS`/`FAIL` per row, each FAIL carrying its remedy line. The description is the trigger: *call this before reporting any coding task complete* |
| `gob_map_status` | read `features/` and the `feature_map:` key: which features exist, their `verified:` dates, and whether each declared entry path still resolves (the read-only half of `FM-02`) |
| `gob_init_status` | is this repo under the harness — the `AGENTS.md` gob block, its class and gates, the engine version |

Register it one of three ways:

    # 1. per-user, Claude Code:
    claude mcp add gob -- npx -y @techgoblin/gobstack mcp

    # 2. per-user, Cursor — .cursor/mcp.json:
    { "mcpServers": { "gob": { "command": "npx", "args": ["-y", "@techgoblin/gobstack", "mcp"] } } }

    # 3. repo-distributed (Claude Code and Cursor auto-detect a repo-root .mcp.json):
    gob init --with-mcp-config

`--with-mcp-config` is ask-once: it writes the generated `.mcp.json`, states a no-op if the
generated bytes are already there, and **refuses** a file that carries anything else — a
registration you customized is the project's, never overwritten. `gob uninstall` removes it
only when it still matches the generated bytes, by the same hash-compare the decision records
get.

## Agent skills

**Agent skills are opt-in.** An `init --write` installs the neutral harness only — `.gob/`,
`AGENTS.md`, `HANDOFF.md`, the checks and the `.gitignore` block; no skills directory, and no
files belonging to any coding agent.

## What it is not

Not a rules document (every rule carries a runnable check or is explicitly counted as
advisory). Not a Cursor-plugin port (`subagent_type`, `/loop`, `/goal`, cloud agents and
vendored plugin paths do not exist here). Not a replacement for a project standard — it
**references** one by path and pins its hash, and carries none of its text. And in this alpha,
not a CI product: nothing is installed under `.github/`, ever.

## Read this on GitHub

**New here? Read `docs/GUIDE.md` first.** It is the step-by-step getting-started guide — install,
the first green run, your first change. This README is the reference you come back to; the table
below is the reference material the guide points into, so the two do not compete for the first read.

| file | what it decides |
|---|---|
| `docs/GUIDE.md` | **read this first**: the first week, in order — init, the first verify, the REPLAY habit |
| `docs/DESIGN.md` | the thesis, the three load-bearing decisions, and every rejected alternative |
| `docs/FLOWS.md` | the 15 playbooks, with the 11 cuts and a reason for each |
| `docs/GUARDRAILS.md` | the security and perf rows (`SC-01`..`SC-09`, `PF-01`), the rung ladder, and what they cannot see |
| `docs/ROLES.md` | roles versus profiles, the model-mapping contract, the fan-out rule |
| `docs/ENFORCEMENT.md` | the matrix rendered for a human, and how a rule is added |
| `docs/CONTRACTS.md` | the installer/verifier interface, exit codes, idempotency, uninstall |
| `docs/INTEGRATION.md` | the board, cron, the skills precedence order, the referenced standard |
| `docs/RISKS.md` | the risk register, the advisory rows named, the non-goals |
| `docs/LOOP.md` | the judge role and the loop contract: what a goal-mode loop actually does, the record, and what neither can see |
| `docs/RECORD-NOTES.md` | the wave codes the changelog and the matrix parentheticals use, one line each |
| `docs/GLOSSARY.md` | every term of art in one table (rendered from the shipped `.gob/manifest/glossary.tsv`) |
| `docs/ADOPTION.md` | the five classes, the preset matrix, the adoption order |
| `docs/LIMITS.md` | where this is weaker than its sources, and what is unproven |

`manifest/enforcement.tsv` is the source of truth for rules; `manifest/classes.tsv` for what a
class requires; `manifest/playbooks.tsv` for the flows; `manifest/glossary.tsv` for the
vocabulary.

## Verify

    gob verify [--only <id[,id...]>] [--json] [--list] [--source <path>]

Exit codes: `0` pass · `1` a check failed · `2` could not
run · `3` the manifest is broken. Every run prints what it cannot see.

## Develop

    bash tests/run-tests.sh

Runs the source-scope rules (PR-01..PR-05) and the test scripts, including `t-verify-red.sh` —
one control per target-scope row (151 over 77 target rows), each required to go RED and then
restored. **A verifier that only ever prints GREEN is a failure**, so that file is the one that
matters most.

## Uninstall

gobstack lives in layers. Each is removed by its own command, and removing one never
touches the others.

**(a) The global CLI** — the npm package itself:

    npm uninstall -g @techgoblin/gobstack

This removes the `gob` (and legacy `goblin`) commands from the machine and nothing else: no
project, no repo, no `.gob/` directory anywhere is touched. Repos you already initialized keep
working fully — the engine is vendored into each repo's `.gob/`, so the CLI's absence removes no
capability.

**(b) A project's harness** — the `.gob/` tree an install created in one repo:

    gob uninstall --target .

(the same job as `goblin-install --target . --uninstall` — through the legacy alias, spell it `goblin`
instead of `gob`). The uninstall is **byte-exact**: it removes exactly the files
`installed.json` records — hash-compared preimages, so a file you edited after install is
reported and kept, never clobbered — then every directory that leaves empty, and it strips the
`<!-- gob:begin --> … <!-- gob:end -->` block out of `AGENTS.md` (the body prose stays). After
it, the repo has zero harness files; only the project's own record (`HANDOFF.md`, `AGENTS.md`'s
prose, `reviews/`, the `.gitignore` block) survives, because that is the project's, not the
harness's to delete. Two residues are left **by design, and named in the output**: the
`.gitignore` ignore-rules block stays (removing it could eat a line the project added inside
it — delete that block by hand if you want it gone), and prose that named `.gob/` paths
(HANDOFF, the AGENTS.md body, SPECs) now points at removed files. And because the engine is vendored, the repo needs no gobstack installed to
run this — it is self-contained until the moment you remove it.

The short version, for a full removal from a machine and its repos: (b) in each initialized
repo, then (a).

## Re-pin the referenced standard

    goblin-install --target <dir> --re-pin   # from the gobstack checkout / install tree

`practice_sha256:` in the AGENTS.md gob block pins the referenced standard and `IN-02`
re-checks it, so editing that standard — a legitimate, intended edit — reds `IN-02` in every
installed repo. `--re-pin` re-records that one line and prints the old and new hash; `IN-02`
then reports `practice pin ok`. Nothing re-pins automatically, not even a re-install, and the
`practice EDITED` failure prints this command. The whole contract: `docs/CONTRACTS.md`,
"An edited standard is not a dead end".

## Dependencies

`bash`, `git`, `awk`, `sed`, `grep`, `python3` (the engine); node ≥ 18 for the npm shim only. No
jq, no yq, no network at verify time.

## License

MIT.
