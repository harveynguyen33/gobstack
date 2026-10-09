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
CI configs) and what to decide (the first gate command and the feature map) — plus the
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
of file it manages: `docs/GUIDE.md`.

A repo that already has its own `HANDOFF.md` exits 1 on the refusal. That is the contract, not a
failure: reconcile the file rather than forcing over it — `docs/GUIDE.md`.

**The config is the AGENTS.md frontmatter.** There is no separate config file in v2: every knob
the harness reads — gates, ratchet, bans, replay, opt-outs — is a `key: value`
line inside the `<!-- gob:begin --> … <!-- gob:end -->` marker block at the top of `AGENTS.md`.
Edit it in place; the parser reads only that block, and the installer never rewrites it after the
first install.

After installing, in this order:

    cd <target> && git add -A && git commit   # the install is a change like any other
    .gob/bin/goblin-verify                    # or gob verify, anywhere in the target

**A default install verifies green — `17 passed, 0 failed, 0 advisory,
10 skipped`, exit 0 — once `HANDOFF.md` names a commit that exists. Before that edit the
scaffold's `0000000` placeholder is the one expected red.** Ten rows skip: `SK-01`, `SK-02` and
`SK-04` **run** (the core procedure tier is vendored under `.gob/skills/` on every install);
`BN-01`/`BN-02`/`BN-03`/`BN-05` match only `.ts`/`.tsx`/`.js`/`.jsx` and have no such source, so
each reports itself *not applicable*; the four electron bans `BN-06`–`BN-09` are selected by the
`dep:electron` predicate, so with no `package.json` they too report *not applicable* — never
running vacuously off the harness's own `.mjs`/`.json`;
and `FM-01`/`FM-02` have no feature map yet. **Thirty-two further rows are OFF by default** —
they are not skipped, they are held in the **library** (`gob verify --library`), the discovery
surface for the extend mechanism: the spec/round rows (`SP-01`..`SP-03`), the ratchet rows
(`GT-04`/`GT-05`), the replay rows (`HS-01`..`HS-03`), commit hygiene (`CM-02`/`CM-03`),
the PR-gate rows (`PG-01`..`PG-03`), the runtime-data rows (`DS-01`/`DS-02`), the doc rows
(`DOC-01`/`DOC-02`), the security rows (`SC-02`..`SC-06`, `SC-09`), the perf baseline (`PF-01`),
the reference corpus (`RC-01`..`RC-04`), the archive switch (`CL-02`), the portability row
(`PT-01`) and the doctor row (`VA-01`). A default run states the library count in its summary, so
a green run is never the whole story. Full inventory: `gob verify --library`. Turn one on by
pasting the line `--library` prints into `.gob/manifest/enforcement.local.tsv` (repo-local,
committed with the repo); the run then names it `enabled-locally` in its summary. The file is
optional, and a local row that names no check the engine can run is refused (exit 3), never
silently green. The
parts that only a round can produce — a first review note, a gate that is not the shipped floor —
pass *vacuously* rather than failing, and `P8` (`goblin-bootstrap`) still walks them as work to
do. The measurement and the vacuous-pass reading are in `docs/GUIDE.md`.

## The `gob` CLI

The v2 surface is six verbs — `init`, `map`, `verify`, `bans`, `mcp`, `uninstall`. Everything
else — audit, install — is unwired in this alpha: the shim refuses the verb by name
and prints the usage.

| command | what it does |
|---|---|
| `gob init` | the first step: print the AGENT BRIEF + proposal schema; `--heuristic` appends scanned hints as a fallback; `--write <proposal> [--yes]` validates the proposal and installs; `--target <dir>` aims elsewhere; `--dry-run` validates without writing |
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
| `gob_init_status` | is this repo under the harness — the `AGENTS.md` gob block, its gates, the engine version |

Register it one of three ways:

    # 1. per-user, Claude Code:
    claude mcp add gob -- npx -y @techgoblin/gobstack mcp

    # 2. per-user, Cursor — .cursor/mcp.json:
    { "mcpServers": { "gob": { "command": "npx", "args": ["-y", "@techgoblin/gobstack", "mcp"] } } }

    # 3. repo-distributed (Claude Code and Cursor auto-detect a repo-root .mcp.json):
    #    `gob init --write <proposal>` writes it as part of the install — no extra command

`init --write` writes the repo-root `.mcp.json` alongside the harness, so the user runs no
separate gob command. It is ask-once: the generated bytes written again are a named no-op,
and a file that carries anything else is **kept untouched** — a registration you customized
is the project's and is never overwritten. `gob uninstall` removes it only when it still
matches the generated bytes, by the same hash-compare the decision records get.

## Agent skills

**Agent skills are opt-in.** The default install vendors the **core procedure tier** — the seven
skills whose rows (`SK-01`/`SK-02`/`SK-04`) ride every install — under `.gob/skills/`, so a fresh
repo runs those rows instead of skipping them. The wider **Hermes project tier** is the opt-in:
`--skills yes` (or `init --write` with skills on) copies the full skill set under `.hermes/skills/`.

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
| `docs/GUIDE.md` | **read this first**: the first week in order, the installer/verifier interface, the rule matrix, the 15 playbooks, the integration points |
| `README.md` | this file: the thesis and rejected alternatives, the risk register and non-goals, the glossary (all below) |
| `docs/LIMITS.md` | where this is weaker than its sources, and what is unproven |
| `docs/RECORD-NOTES.md` | the wave codes the changelog and the matrix parentheticals use, one line each |

`manifest/enforcement.tsv` is the source of truth for rules; `manifest/playbooks.tsv` for the
flows; `manifest/glossary.tsv` for the vocabulary.

## Verify

    gob verify [--only <id[,id...]>] [--json] [--list] [--source <path>]

Exit codes: `0` pass · `1` a check failed · `2` could not
run · `3` the manifest is broken. Every run prints what it cannot see.

## Develop

    bash tests/run-tests.sh

Runs the source-scope rules (PR-01..PR-04) and the test scripts, including `t-verify-red.sh` —
one control per target-scope row (114 over 59 target rows), each required to go RED and then
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
`practice EDITED` failure prints this command. The whole contract: `docs/GUIDE.md`,
"An edited standard is not a dead end".

## Dependencies

`bash`, `git`, `awk`, `sed`, `grep`, `python3` (the engine); node ≥ 18 for the npm shim only. No
jq, no yq, no network at verify time.

## License

MIT.

---

## Design

### The thesis

gobstack is a small portable repository that installs three things into any target repo:

1. an **executable rule manifest** — every rule carries a runnable check or is explicitly
   counted as advisory;
2. a set of **Hermes project-local skills** that carry the flows;
3. an **installer and a verifier** that prove the first two are still true.

It is not a rules document. A rules document has no enforcement, and the published evidence is
that an LLM-generated context file costs tokens and can reduce resolution. A rule that cannot
be checked is counted and capped instead of asserted.

It is not a port of any Cursor harness. The primitives that carry those harnesses —
`subagent_type`, `/loop`, `/goal`, `environment: "cloud"`, `readonly`, a vendored plugin
directory — do not exist in Hermes. What transfers is the *shape*: an executable matrix, a
bounded panel, a pinned-SHA verdict. What does not transfer is cut, with the reason recorded in
`docs/GUIDE.md`.

### Three load-bearing decisions

#### D1 — the enforcement matrix is an executable artifact, not a document

`manifest/enforcement.tsv` has one row per rule. The `check` column holds a real command, the
literal `advisory`, or the marker `goblin-verify --only <ID>` for a check that needs more than
one shell line. A self-check row (IN-03) fails the manifest when a row has neither, and SK-03
caps the advisory count. **The number of unenforceable rules is itself a gate.**

#### D2 — skills install as *project-local* skills, never into a profile

Hermes discovers skills at `<project-root>/.hermes/skills/` and gives the project tier the
highest precedence — above `~/.hermes/skills/` and above any profile copy. Project dirs are
treated as repo-owned, so autonomous skill maintenance never rewrites them, and they are
versioned with the code they govern.

This is the design that removes a whole class of rot instead of managing it. Two living copies
of the same rule with no equality check drift; one copy plus a recorded hash does not. The
installer puts the skills in the repo, and `SK-02` hashes what it installed.

#### D3 — the gate is chosen by the change, not by the repo, and every review names its SHA

The stakes ladder S0–S4 becomes the `goblin-pr-gate` playbook. The one-line upgrade that
applies at every tier — including a direct push — is that a review note names the SHA it
reviewed: `reviews/<slug>-<head7>.md` with `head:`, `base:`, `patch-id:`, `stakes:`,
`checks-run:`. A verdict is a claim about an artifact, not about a moment, and `PG-03`
re-checks the patch-id so a new head voids it.

### The composition decision: the house style is referenced, never copied

The split is by **kind**, and it is checkable.

- The **standard this repo references** owns the house style: the HANDOFF shape and the
  stale-sentence rule, the SPEC lifecycle, the harness house style and the pinned-commit
  REPLAY, the gate vocabulary, commit discipline, the delegation tiers, data safety, the
  documentation duty, adopt-don't-replace.
- **gobstack owns the mechanism**: which rule is enforced by what, how it is installed, how
  it is verified, which flow applies, which role runs a flow.

gobstack carries **no copy** of the standard's text. The `AGENTS.md` gob block holds
`practice:` and `practice_sha256:`; `goblin-verify` re-checks the hash, so a silently edited
standard is visible rather than assumed. An edit that *is* intended is re-pinned by one explicit,
printed command (`goblin-install --target <dir> --re-pin`), never automatically — the pin exists
to catch a silent edit, so it may not update itself. If no standard is configured, the checks that
depend on it report advisory, never a failure — that is what makes the repo portable.

### Rejected alternatives

| Rejected | Why |
|---|---|
| A file-for-file port of a Cursor harness | Most of its playbooks are inert without a plugin that is not shipped, and its primitives do not exist here. |
| A "gobstack rules" document | The #1 anti-pattern: a rules doc with no enforcement is a measured net cost. |
| Copying the referenced standard into this repo | It is the strongest artifact on the box and must not be weakened; a second copy is exactly the duplication that already rots. |
| Replacing the referenced standard | Would discard the pinned-commit REPLAY rule, the stale-sentence rule, the data-safety rule and adopt-don't-replace — four things no imported source has. |
| Per-project bespoke harnesses | The *gate vocabulary* differs by language, not the harness. One default config plus a real off switch. |
| Fan-out by default, auto-merge, or an unattended hillclimb | The axis is read-versus-write, parallel lanes cost about N times the tokens, and no reviewed source ships unconditional auto-merge. |
| A plugin or marketplace package | There is no marketplace here. The portable unit is a `SKILL.md` plus a bash installer. |
| Shipping a workflow (the W4 position, reversed in v3) | Measured: a workflow file is not a gate (a required check can self-skip, and the forge settings are not in the repo), and CI and `goblin-verify` were free to report different truths about one SHA. v3 cut the lane and ships no workflow; a project that wants CI wires its own. |

### What it deliberately does not do

See `docs/LIMITS.md` and the non-goals in `README.md`. The short version: it does not choose
models, does not write the vault, does not replace any project's existing gate, writes nothing
outside its target, and does not pretend the prose rules are enforced.

**Amended at W4, reversed at v3.** It used to say *"there is no CI workflow"*; W4 wrote at most one workflow. v3 cut the lane: it ships **no** workflow and reads
none. The reason the W4 experiment was reversed is recorded in `docs/LIMITS.md` #34 — a workflow
file is not a gate (the required-check list, the bypass switch and the push identity are forge
state), and CI and `goblin-verify` were free to report different truths about one SHA.

---

## Risks and non-goals

### Risks

| # | Risk | Counter-measure | Status |
|---|---|---|---|
| K1 | **Model promotion churn** breaks a role binding | Roles are capabilities, never slugs, and v3 removed the model surface entirely: the harness names no model and reads no mapping file. A campaign that changes nine profiles changes nothing here. | Handled by design |
| K2 | **Profile drift across the fleet** | The attack surface is removed, not managed: project procedures live in the repo's `.hermes/skills/`, so there is no second copy to drift. `SK-02` hashes what is installed. The existing divergence outside gobstack's scope is a separate, escalated cleanup. | Handled in scope; fleet-side cleanup escalated |
| K3 | **Skills duplicating between profiles** | Same as K2. The precedence order is stated in `docs/GUIDE.md` so a future agent knows which copy wins instead of guessing. | Handled by design |
| K4 | **The vendored copy rots** (a repo sits at an old version) | `installed.json` records version and hashes; `goblin-verify` reports the installed version; `--upgrade` prints created/updated/unchanged. Accepted for repos that stop being worked on — the alternative (a network call at verify time) violates the offline dependency contract. | Accepted, with detection |
| K5 | **The harness decays into prose** | `IN-03` plus `SK-03`: a row without a command must say `advisory`, and the advisory count is capped (`advisory_ceiling`, default 10). The cap is the ratchet. | Handled by design |
| K6 | **A HANDOFF carries a stale number** | `HP-03` requires `measured <date>`; `HP-05` requires a commit that exists. | Partial: proves a date exists, not that the number is fresh. V1 anchored the row on the gate names the config declares (and skips the template's example sentence), so the real gate line can no longer lose its date in silence - but nothing re-measures the number, and a gate-bearing line that names no declared gate and carries no gate-shaped keyword is still unseen |
| K7 | **The gate is theatre** (self-skipping checks, admin bypass) | The CI lane is cut in v3, but the hazard it named is a fact about CI in general: a required check that self-skips reports success, and a protected branch whose only admin is the person pushing protects nothing. The harness ships no workflow and reads none, so the hazard is documented here and in `docs/LIMITS.md` #13/#34, not mechanised. | Not solvable from a repo: the required-check list, the bypass switch and the push identity are forge state |
| K8 | **Cost** | Roles plus effort tokens; the panel only at S3+; sweeps are cron-and-one-line; no playbook fans out without a named predicate. | Handled by policy |
| K9 | **The builder may only install into its own repo plus a scratch copy** | The install proof target is a throwaway copy under the scratch directory; the recipe is in `docs/GUIDE.md`. | Constraint, satisfied |
| K10 | **A fleet-config repo is the least-governed artifact in an estate** | An artifact-scoped gate (a commit exists). The underlying staleness bug in a backup job is named and escalated — gobstack can detect staleness but cannot fix another repository. | Escalated |
| K11 | **The pre-change tree is unknown in a repo with no git history** | Repos with no `.git` are ordered *after* `git init`. `HS-02` is **skipped with a reason** rather than faked while no pinned commit exists. | Handled by ordering |
| K12 | **A check green on both trees** (the failure mode the REPLAY exists for) | `HS-02` runs the harness set against the pinned pre-change commit and requires **every** harness to be RED there. The shipped scaffold harness is deliberately such a check and is therefore reported as unproven until it is replaced. | Handled by design; see `docs/LIMITS.md` |
| K13 | **A nightly automation files the same defect twice, or files one that is not there** | Cut in v3 with `automations/` and `AU-02`. A project that runs its own intake keeps a content-only dedup key (`--idempotency-key`) plus the board's own `recent_success` and `active_pr` guards; a report whose `revision` does not resolve is a refusal, not a card; `--max-runtime`, `--max-retries 1` and the failure limit auto-block a looping card. | Handled by design; the key is a dedup, not a mutex (`docs/LIMITS.md` #20) |
| K14 | **A waiver becomes a permanent blind spot** - a dated exception nobody re-decides | `SC-05`'s boundary waivers are recorded decisions the row reads where it runs, and the waiver count is printed on the gate line so the debt stays loud | Handled by design |
| K15 | **gobstack installs agent-authored skills, and the one controlled study of that practice puts it BELOW the no-skill baseline.** SkillsBench 1.1's self-generated condition (the agent authors its own Skills before solving) reports all three tested configurations below their no-Skills baseline (-8.1, -11.3, -11.5 points), while curated Skills rose +16.6 points across 18 configurations. A generated skill accepted after a skim is a different proposition from a written one. | `P6` hands every generated verification skill to `P12`, and `verified:` does not advance until an eval record exists; the record's shape, the eleven-token ban, the cheap-checks-first ladder and the pass condition (every seeded defect detected, the control at zero, every correction RED before GREEN) are specified in `skills/goblin-eval/SKILL.md`. The evidence is cited with its pin in `docs/LIMITS.md` #15. | **Stated requirement, not an enforced one**: the runner is not shipped and no row reads a lane (`docs/LIMITS.md` #31) |
| K16 | **The feature map rots, or claims coverage it does not have** - a route renamed under a recipe that still "works", a feature file nobody indexed, a `verified:` date nobody drove | `FM-01` (every feature file indexed, the four-H2 entry contract, the slug matches the filename), `FM-02` (every declared entry path still resolves under `source_root:`, no entry path changed after its `verified:` date), `VA-01` (the declared `verify_doctor:` exits 0); the upkeep pass and the rot table live in `skills/goblin-feature-map/SKILL.md`. | Handled by design for everything the map LISTED; completeness is not checkable (`docs/LIMITS.md` #30) |

| K18 | **A workflow is mistaken for a gate** — a file in `.github/workflows/` with no required-check entry, with the admin-bypass switch on, or pushed under the sole admin's own identity, is decoration that reads as enforcement | The harness ships no workflow (the CI lane is cut in v3) and no row reads one; the four settings that make a workflow a gate are recorded in `docs/LIMITS.md` #34, and the verifier's "cannot see" footer names the lane on every run | The file half is gone with the lane; the forge half was never observable from a repo |

### The advisory rows, named

No row of the shipped matrix is labelled `advisory` — the **six advisory rows moved to the
library**, so a default run sits at **0 of 10** on the `SK-03` cap (`gob verify --library` lists
them). Those six carry **no executable check at all**:

- **HP-04** — a stale sentence is corrected in place with a dated parenthetical, never deleted.
- **HS-03** — source probes read text with comments blanked first.
- **CM-02** — the commit message was written to a file, not passed inline.
- **DOC-01** — a significant change updates the docs that teach it.
- **DOC-02** — system-level changes are recorded wherever the project's standard says they live.
- **SC-09** — auth is applied consistently across sibling routes.

`HP-04` and `CM-02` additionally print a heuristic when run with `--only`. A heuristic is not a
check: it never fails a run. A counted rule is still not an enforced one, and the cap is a policy,
not a proof.

### Non-goals

Stated so no future reader infers them:

- not a plugin or a marketplace package; no slash commands;
- **no auto-merge** — no reviewed source ships it unconditionally, and merging is a different
  decision from a green gate;
- not a fleet orchestrator — the board owns that;
- does not provision, migrate or verify models;
- does not write the vault;
- does not replace any project's existing gate (adopt, don't replace);
- is not a monorepo tool and not a CI tool. **v3:** it ships no workflow and reads none — a project
  that wants CI wires its own, and CI is out of the product (`docs/LIMITS.md` #55);
- does not manage profile skill libraries;
- writes nothing outside the target repo;
- does not attempt to make the *prose* rules enforceable — it counts them instead.

---

## Glossary

Every term of art in one table, rendered from `manifest/glossary.tsv` — that file is the source;
edit it there and re-render (or hand-render: one row per term, alphabetical, the definition one
sentence). A term a new reader might trip on belongs here, not in a footnote.

| term | definition | source |
|---|---|---|
| advisory | A rule with no executable check. Counted in the verify summary and capped by advisory_ceiling; never a silent pass. | R6 sec.5 |
| archive | An opt-in flag: verify requires no HANDOFF and no gates, and the summary says so. | R7 sec.2.4 |
| drift | A file whose current bytes no longer match the hash recorded at install time. IN-02 reports it; the remedy column says how to recover. | UX-review-2026-10-06 |
| engine | The bash programs plus the manifest a verify run actually resolved: per-repo (.gob/bin) or global (engine_dir:). Named in every run's footer. | UX-review-2026-10-06 |
| forge | The hosting platform a repo pushes to (GitHub, GitLab, ...). What the forge itself enforces — the required-check list, the bypass switch, the push identity — is not observable from inside a repo. | UX-review-2026-10-06 |
| foreman | The orchestrating agent that delegates work to the fleet; the role that reads HANDOFF.md first and writes it last. | UX-review-2026-10-06 |
| gate | A declared command that must exit 0. Declared per project, never inferred from the stack. | PP sec.4 |
| HANDOFF | The session-boundary contract at the repo root: START HERE / State / Gates / Next steps / NOT verified. | PP sec.1 |
| harness | An asserting check file: a failures counter, an assert(name, ok, detail) printer, and a non-zero exit on failure. | PP sec.3 |
| lane | A family of rules that share a mechanism and a blind spot: the ban lane, the CI lane, the reference lane. The cannot-see footer reports per lane. | UX-review-2026-10-06 |
| opt-out | A part recorded in disabled: so its required checks report SKIP (opt-out) instead of failing. | R6 sec.6.3 |
| overnight | P10: an unattended run over a fixed goal, stopped by an escape hatch. | R6 sec.3 |
| part | One installable unit: handoff, spec, gate, replay, ratchet, pr-gate, review-panel, playbooks, tokens. | R7 sec.5 |
| patch-id | git patch-id --stable of base..head. A new head voids a verdict; a matching commit message does not restore it. | R1 sec.10 |
| playbook | A named, ordered procedure with a measurable verification step. gobstack ships 15. | R6 sec.3 |
| preimage | The input that produces a known hash. The hash checks here prove non-drift, not preimage resistance - they are tamper-evidence, not signatures (docs/LIMITS.md #18). | UX-review-2026-10-06 |
| profile | A worker identity in the Hermes fleet (architect, coder, reviewer, ...). Owns memory and skills. | R4 |
| review-panel | N independent verdict lanes, each its own card with its own resolved model. Only at stakes S3+. | R6 sec.4.3 |
| REPLAY | Re-running each assertion against the pinned pre-change commit and requiring it to be RED there. A check green on both trees proves nothing. | PP sec.3 |
| ratchet | A count that must not rise, with a declared ceiling; a rise is allowed only when re-anchored with the arithmetic (old + N new = new). | PP sec.4 |
| round | One full pass of the work cycle: plan, implement, gate, replay, hand off. The unit a wave code counts. | UX-review-2026-10-06 |
| skill | A Hermes SKILL.md directory. gobstack installs its skills into the target repo at .hermes/skills/ (project tier), never into a profile. | R6 sec.0.1 / sec.7.3 |
| SPEC | A per-round document written before implementation: measured root cause plus an AC: list checkable without a human. | PP sec.2 |
| stakes | The S0-S4 ladder that chooses the review gate strength by the change, not by the repo. | R5 sec.3.2 |
| sweep | P11: the same change or question across many projects, enumerated by glob, one card each. | R6 sec.3 |
| vendored | Copied into the repo rather than read from the package, so it survives offline and is hashed by IN-02 like any installed file. | UX-review-2026-10-06 |
