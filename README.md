# gobstack

**gobstack** (npm: [`@techgoblin/gobstack`](https://www.npmjs.com/package/@techgoblin/gobstack))
installs an **executable rule manifest**, a set of **project-local skills**, and an
**installer/verifier pair** into any project — so that an AI coding session never re-improvises,
and a rule that cannot be checked is counted rather than asserted.

Install it from npm — the one documented install path:

    npm i -g @techgoblin/gobstack        # gives you the `goblin` CLI

## Install

    npm i -g @techgoblin/gobstack

Then, from any project:

    goblin install --target /path/to/repo --class A

The installer writes only paths it records, hash-compares before writing, and prints `no-op` on a
second run with the same arguments. It never overwrites `HANDOFF.md`, `AGENTS.md`, a `*-SPEC.md`,
`reviews/`, the `.gitignore` block or `.goblin/goblin.yaml`. Full option list and the three kinds
of file it manages: `docs/CONTRACTS.md`.

A repo that already has its own `HANDOFF.md` exits 1 on the refusal. That is the contract, not a
failure: reconcile the file rather than forcing over it — `docs/ADOPTION.md`.

After installing, in this order:

    cd <target> && git add -A && git commit   # the install is a change like any other
    goblin verify                             # or .goblin/bin/goblin-verify, inside the target
    hermes skills trust <target>              # one-time, Hermes users, so project-tier skills load
    goblin audit                              # once, deliberately: the ONLY network step (SC-07)

**A class-A install verifies green — `43 passed, 0 failed, 11 advisory, 28 skipped`, exit 0 — once
`HANDOFF.md` names a commit that exists. Before that edit the scaffold's `0000000` placeholder is
the one expected red: `42 passed, 1 failed`, `HP-05`. Both numbers measured 2026-09-25; the run and
the fix are step 2 of `docs/GUIDE.md`.**
Twenty-eight rows skip (`HS-02` has no pinned pre-change commit yet, so the REPLAY is not provable;
`AU-02` and `AU-03` have no report to audit; `SC-06`, `SC-07` and `SC-08` have no dependency
manifest, no lockfile and no audit record to read; `PF-01` has no measured perf baseline;
`BN-01`/`BN-02`/`BN-05` have no `src/` for a ban to read, and `BN-03` plus the four electron bans
`BN-06`/`BN-07`/`BN-08`/`BN-09` are not in this class's `bans:` list (`bans: [BN-01, BN-02, BN-05]`),
so they skip as *not enabled* rather than as *unread*; `FM-01`/`FM-02`/`VA-01`
have no feature map and no declared `verify_doctor:` yet; `RC-01`..`RC-04` have no reference corpus
declared and no lab `manifests/` to read; and `JG-01` with `LP-01`..`LP-05`
have no loop record, because no loop has run in this repo yet). **Two** rows do **not** skip: `PG-05`
and `PG-06`, the CI lane's. This class installs `.github/workflows/goblin-gate.yml`, so the two of
them read it and pass. Two, not four — the four electron bans named above are among the skips. Two of
the eleven advisories
are new with the judge lane: `JG-02` reports that the judge lane resolves to no profile on this
fleet (it prints the one-line remedy and never fails a repo for a fleet's routing), and `JG-03`
is the counted row the advisory ceiling had left for it. The parts
that only a round can produce — a first review note, a gate that is not the shipped floor — pass
*vacuously* rather than failing, and `P8` (`goblin-bootstrap`) still walks them as work to do.
The measurement and the vacuous-pass reading are in `docs/CONTRACTS.md`.

## The `goblin` CLI

| command | what it does |
|---|---|
| `goblin verify` | run the rule matrix against the current repo — `PASS`/`FAIL`/`SKIP` per row, exit 0 pass · 1 a check failed · 2 could not run · 3 the manifest is broken |
| `goblin bans` | run the ban list (per-pattern red lines over the source tree) |
| `goblin audit` | check recorded dependency claims against live advisory feeds — the only command that touches the network |
| `goblin install` | install the manifest, skills and verifier into a target repo |
| `goblin uninstall` | remove everything an install wrote (npm shim `goblin install --target <dir> --uninstall`) |
| `goblin upgrade` | migrate a repo to the shared global engine at `~/.goblin/engine` — 8 steps, two commits, one report |
| `goblin doctor` | one run across the platforms below: DETECTED / NOT-DETECTED / DRIFT per platform |
| `goblin emit` | write the skills + context block for one platform (`--scope project` or `global`); `--unshadow` removes a hermes project skill whose hash equals the source |
| `goblin init` | the first-run wizard: detect → class → branch/email → first gate → emit → verify, one screen per question; every question has a flag (`--class app --branch main --email a@b.c --gate 'cmd' --emit hermes`), so CI runs it with zero prompts; `--dry-run` prints the plan and writes nothing |

## Platforms

`goblin emit` and `goblin doctor` cover seven agent platforms, each detected via its own anchor:

| platform | what emit writes there |
|---|---|
| `claude` | skills + context block under `~/.claude` (or `--target`'s project scope) |
| `hermes` | skills + context block under `~/.hermes` |
| `copilot` | skills + context block under `~/.copilot` |
| `cursor` | skills + context block under `~/.cursor` |
| `opencode` | skills + context block under `~/.config/opencode` |
| `codex` | skills + context block under `~/.codex` (partial: some commands blocked, `docs/LIMITS.md` #47) |
| `gemini` | skills + context block under `~/.gemini` (partial: some commands blocked, `docs/LIMITS.md` #47) |

One run of `goblin emit --platform <p> --scope project` writes the skills and the context block a
session of that platform reads; `--scope global` writes to the machine-level anchor. `--dry-run`
prints the full write plan first.

## What it is not

Not a rules document (every rule carries a runnable check or is explicitly counted as
advisory). Not a Cursor-plugin port (`subagent_type`, `/loop`, `/goal`, cloud agents and
vendored plugin paths do not exist here). Not a replacement for a project standard — it
**references** one by path and pins its hash, and carries none of its text.

## Read this on GitHub

**New here? Read `docs/GUIDE.md` first.** It is the step-by-step getting-started guide — install,
the first green run, your first change. This README is the reference you come back to; the table
below is the reference material the guide points into, so the two do not compete for the first read.

| file | what it decides |
|---|---|
| `docs/GUIDE.md` | **read this first**: the first week, in order — install, the first verify, the REPLAY habit |
| `docs/DESIGN.md` | the thesis, the three load-bearing decisions, and every rejected alternative |
| `docs/FLOWS.md` | the 15 playbooks, with the 11 cuts and a reason for each |
| `docs/GUARDRAILS.md` | the security and perf rows (`SC-01`..`SC-09`, `PF-01`), the rung ladder, and what they cannot see |
| `docs/ROLES.md` | roles versus profiles, the model-mapping contract, the fan-out rule |
| `docs/ENFORCEMENT.md` | the matrix rendered for a human, and how a rule is added |
| `docs/CONTRACTS.md` | the installer/verifier interface, exit codes, idempotency, uninstall |
| `docs/INTEGRATION.md` | the board, cron, the skills precedence order, the referenced standard |
| `docs/RISKS.md` | the risk register, the advisory rows named, the non-goals |
| `docs/CI.md` | the CI lane: what makes a workflow a gate, the four settings a repository cannot set, and the desktop-shell class |
| `docs/LOOP.md` | the judge role and the loop contract: what a goal-mode loop actually does, the record, and what neither can see |
| `docs/ADOPTION.md` | the six classes, the preset matrix, the adoption order |
| `docs/LIMITS.md` | where this is weaker than its sources, and what is unproven |

`manifest/enforcement.tsv` is the source of truth for rules; `manifest/classes.tsv` for what a
class requires; `manifest/playbooks.tsv` for the flows; `manifest/glossary.tsv` for the
vocabulary.

## Verify

    goblin verify [--only <id[,id...]>] [--json] [--list] [--source <path>]

Exit codes: `0` pass · `1` a check failed · `2` could not
run · `3` the manifest is broken. Every run prints what it cannot see.

## Develop

    bash tests/run-tests.sh

Runs the source-scope rules (PR-01..PR-05) and the test scripts, including `t-verify-red.sh` —
one control per target-scope row (167 over 82 target rows), each required to go RED and then
restored, plus `t-audit.sh` for the SC-07 producer. **A verifier that only ever prints GREEN is a
failure**, so that file is the one that matters most.

## Uninstall

    goblin install --target <dir> --uninstall

Removes the installed artifacts, `.goblin/goblin.yaml` and every directory that leaves empty, and
leaves `HANDOFF.md`, `AGENTS.md`, `ROUND-000-SPEC.md`, `reviews/` and the `.gitignore` block —
the project's record is not the harness's to delete.

## Re-pin the referenced standard

    goblin install --target <dir> --re-pin

`practice_sha256:` pins the referenced standard and `IN-02` re-checks it, so editing that standard
— a legitimate, intended edit — reds `IN-02` in every installed repo. `--re-pin` re-records that
one line and prints the old and new hash; `IN-02` then reports `practice pin ok`. Nothing re-pins
automatically, not even `--upgrade`, and the `practice EDITED` failure prints this command. The
whole contract: `docs/CONTRACTS.md`, "An edited standard is not a dead end".

## Dependencies

`bash`, `git`, `awk`, `sed`, `grep`, `python3` (the engine); node ≥ 18 for the npm shim only. No
jq, no yq, no network at verify time.

## License

MIT.
