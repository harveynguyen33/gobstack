# gobstack v3 — a minimal, purely agent-driven core

Status: SPEC. No code. v3 keeps exactly six elements; anything else must name the element
it displaces. One test decides every call below: **does this help the agent stop
re-improvising, or is it surface the repo does not need yet?**

---

## A. What gobstack v3 IS

gobstack installs four files the agent already uses: the `AGENTS.md` `gob` block (config =
the rules), `.gob/bin/goblin-verify` (the gate, owned by the repo), `HANDOFF.md` (the note
between sessions), and the MCP tool `gob_verify` (the agent runs the gate on itself). The CLI
never scans, never calls an AI API, never touches the network.

The single sentence a user tells their agent:

> "Adopt gobstack in this repo: scan it, write the init proposal with our real gate command
> and a feature map, install it, and register the verify tool for yourself."

The agent then runs, unaided:

    npx @techgoblin/gobstack init                 # 1. read the brief + proposal schema
    #   ...scan package.json/scripts, routes, tests, CI, git identity with its OWN tools...
    #   ...write .gob-init-proposal.md (config block + feature-map section)...
    npx @techgoblin/gobstack init --write .gob-init-proposal.md   # 2. validate + install (MCP registration is INSIDE this step)
    bash .gob/bin/goblin-verify                   # 3. run the gate; fix the day-one reds
    git add -A && git commit                      # 4. the install is a change like any other

There is no `gob map` step. The map is written inside step 1 and installed in step 2.

**After install the user never runs a gob command again** (DECISION, Harvey 2026-10-09). The
steady state is the agent's own session calling `gob_verify` over MCP before it reports a task
complete. The CLI goes dormant; the harness lives in the repo and the agent's toolchain.

---

## B. The single init flow

`gob init` prints the brief + schema. The agent writes **one** proposal carrying both
halves. `gob init --write <proposal>` validates and installs everything.

### v3 PROPOSAL SCHEMA (verbatim)

```
<!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->
gate_<name>_cmd: <one shell command that must stay green>
feature_map: <dir — e.g. features>          # REQUIRED FOR EVERY CLASS — no empty state exists
source_root: <dir — default .>
<!-- gob:end -->

## gob init summary
- <one bullet per decision: what was scanned, what was chosen, why>

## feature-map

### features/README.md
```md
# Features
- [<slug>](./<slug>.md) — <one line>
```

### features/<slug>.md
```md
---
feature: <slug — lowercase [a-z0-9-], equals the filename stem>
entry_paths:
  - <repo-relative path that exists>
verified: never-driven (<today>)
---
# <slug>
<one user-visible paragraph>
## Sub-features
## How to get to it (user POV)
## Driving it with <harness>
## Gotchas
```
```

### What `--write` validates (fail closed, exit 2, nothing written)

- **Config:** every block key is in the engine's key set (a typo'd key refuses — it would
  otherwise be ignored forever); **at least one** `gate_<name>_cmd` with a non-empty command;
  `feature_map` non-empty. `class:` is **no longer a key** (DECISION, Harvey 2026-10-09):
  the class only ever selected which bans ran, and a ban is code-shaped — so each row in
  `manifest/bans.tsv` instead declares `applies_when: <glob>` and the verifier runs it only
  when a file matches. Nothing to declare, nothing to get wrong.
  `branch:` and `owner_email:` are **no longer keys** — a proposal carrying either refuses as
  an unknown key (DECISION, Harvey 2026-10-09: the gate reads `git rev-parse --abbrev-ref HEAD`
  and `git config user.email` directly, so neither is worth asking a human for).
- **The gate is RUN, not guessed.** The agent must EXECUTE the candidate `gate_<name>_cmd` in
  the working tree before it writes the proposal, and record the observed exit code and output
  line. Rules: it must run OFFLINE and deterministically — a command needing network,
  credentials or a database is not a gate; the npm placeholder default test script (the one that
  prints an error and exits 1) must never be recorded; and if the repo has no real check, the
  agent AUTHORS one at `checks/gate.sh` (the `--write` scaffold already ships
  `templates/checks/gate.sh.tmpl`) rather than naming a command that proves nothing. `GT-02`
  re-runs the declared command at the end of init, so a wrong choice surfaces as a day-one red
  before the install is committed — a bad gate cannot hide.
- **Empty repo:** a repo with no committed file to map **REFUSES** with a named remedy
  ("commit at least one file, then run again"). No bootstrap feature is invented — a feature
  with no resolvable entry path would be an assertion, not a count.
- **Feature map, in the SAME pass, by the SAME code path `gob map --write` used:**
  - FM-01 shape, per embedded file: frontmatter present; `feature:` equals the filename
    stem; ≥1 `entry_paths:` item, each a single whitespace-free token; **exactly the four
    H2s in order** (`Sub-features` / `How to get to it (user POV)` / `Driving it with <harness>` /
    `Gotchas`); `verified:` is a date or the `never-driven` form. The README index must
    link every feature in the `(./<slug>.md)` form and every relative link must resolve.
  - FM-02 resolvability, at write time: every `entry_path` **exists** and is **tracked**
    (`git ls-files`), so a map cannot claim a `verified:` date over uncommitted source.
- **Refusals:** unknown key; bad class; no gate; no feature files; stem/`feature:` mismatch;
  missing or untracked entry path; wrong/missing/reordered H2s; bad `verified:`.

### What `--write` installs

`AGENTS.md` (body + `gob` block, **with `feature_map:` set so FM-01/FM-02 go live fresh**),
`.gob/engine/` (verifier + manifest + bans), `HANDOFF.md` (once, never overwritten),
`features/` (materialised), the `checks/` scaffold and the `.gitignore` block. `--dry-run`
validates and writes nothing.

---

## C. The row set

A fresh install must not carry a row that can only ever SKIP — a permanent skip is surface
the repo does not need. On a fresh software-class install **34 of 87 rows skip today**,
mostly because `bin/goblin-install` disables skills/playbooks by default and the row then
gates work the default forbids. Class determines which rows exist: the manifest is
class-rendered, and `CL-01` **counts** any required part that is missing rather than
asserting it.

### KEEP — rows that must ALWAYS bite

| Rows | Defect it catches |
|---|---|
| IN-01 IN-02 IN-03 IN-04 | install missing; vendored engine *drifted* from its record; a rule row with no check (manifest rot); a file the installer was told not to take over, taken |
| HP-01 HP-02 HP-03 HP-05 | no session note; note missing a section; a gate number copied, not re-measured; note names no commit |
| GT-01 GT-02 GT-03 | a gate never declared; a declared gate that does not exit 0; no measured line. `GT-04`/`GT-05` (the perf ratchet) DEFER — a perf budget is only honest once a repo has a number worth defending |
| FM-01 FM-02 | **always live, every class** — map not indexed / slug / H2 drift; a declared entry point no longer resolves. DECISION (Harvey, 2026-10-09): the map is MANDATORY for every class, so the `exit 3` SKIP branch is **deleted outright** — there is no "no map declared" state and no D8 defensive shape left to preserve |
| SC-01 | a secret tracked in git — the one security row that is right for every repo. `SC-02..SC-06` DEFER (app-shaped) |
| BN-00 + the class's enabled bans (BN-01 BN-02 BN-05 for software) | a ban with no row or no replacement; `any`; `@ts-ignore`; a cross-layer import |
| SK-01 SK-02 SK-03 SK-04 | a skill with no frontmatter; a skill drifted from its hash; **an uncheckable rule not labelled advisory, and the advisory count not reported**; a skill that does not say what it cannot see |

**The always-on core is ~19 rows:** IN 4 · HP 4 · GT 3 · FM 2 · SC 1 · SK 4 · BN-00 + the
class's enabled bans. DECISION (Harvey, 2026-10-09): *reduce what must be verified* — a row
that is not right for **every** repo is DEFERRED to the extend mechanism, never shipped as a
permanent SKIP. `BN-00` and `SK-03` are the product thesis in row form: a rule that cannot be
checked is **counted**, not asserted.

### CUT (removed outright)

- **MD-01 MD-02 MD-03** — the harness never names a model. Removing them lets `goblin-model`,
  `roles.yaml`, `docs/LOOP.md`, `docs/ROLES.md` go with them.
- **PG-04 PG-05 PG-06** — the CI/forge lane is cut (it ships nothing).
- **SC-07 SC-08** — the network dependency-audit lane; `goblin-audit` writes `.goblin/audit.tsv`
  while the row reads `.gob/audit.tsv`, so it can never go green. Delete the row, not the bug.
- **AU-01 AU-02 AU-03 AU-04** — no automation ships.
- **DOC-01 DOC-02** — advisory, unmeasurable, review-only.

### DEFER (re-added by the extend mechanism when the repo earns the surface)

- **SP-01 SP-02 SP-03** (SPEC-per-change — heavy for a solo repo), **GT-04 GT-05** (the perf
  ratchet — needs a number first), **SC-02 SC-03 SC-04 SC-05 SC-06** (app-shaped security),
  **CL-01** (required-part accounting).
- **HS-01 HS-02 HS-03** (harness shape + pre-change REPLAY), **DS-01 DS-02** (runtime data),
  **JG-01..03 + LP-01..05** (the loop/judge contract — 8 rows that skip because no loop has
  run), **RC-01..04** (reference corpus — research/lab only). Each SKIPs today with a reason;
  each returns the moment the agent adds the check, and until then it is **counted** as a
  skipped row, never presented as a pass. `HP-04`, `HS-03`, `CM-02`, `SC-09`, `SK-03`,
  `DOC-*`, `JG-03` stay as **advisory counts** — never green-by-assertion.

---

## D. The extend mechanism

Today 87 rows + 20 playbooks + a 41-row catalogue ship up-front and most never fires. v3
ships a minimal core that is right for any repo, plus a way for **the agent** to add a
repo-specific rule or skill on its own. It adds **no new verb** — that would need a removal
to pay for it; the honest home is the gate's own output.

**Where it lives.** `.gob/manifest/enforcement.local.tsv` — the shipped 8-column schema plus
`added_by | added_on | why`, with row ids namespaced `LX-*` so they cannot collide.
`.gob/checks/<ID>.sh` — the runnable check a local row must supply. `.gob/skills/<name>/SKILL.md`
— an agent-added skill, verified by `SK-01`/`SK-04` (shape) and `SK-02` (hash).

**The trigger is the gate, not a prompt.** When the verifier SKIPs a deferred row, its
remedy line states how to add the missing check (path + schema). When the agent hits a
defect the core misses — a bug that recurred, a convention the build enforces by hand — it
writes an `LX-*` row. No command; the brief is the gate's own output.

**Who validates.** The verifier, never the agent: `IN-03` refuses a local row with no check
unless it is labelled `advisory`; `BN-00` refuses a new ban with no row or no replacement;
`SK-01/02/04` verify a new skill. The agent **cannot self-certify** — it runs `gob_verify`
(element 4) and shows the row green.

**How it stays honest.** A local rule must ship a check that goes **RED on the defect, GREEN
once fixed** — the REPLAY shape, run before the row is recorded. A rule with no mechanism
is admitted only as `enforced_by: advisory`, and `SK-03` **counts** it in the reported
advisory total. So: a rule that cannot be checked is counted, not asserted.

---

## E. CUT / DEFER checklist (executable work list)

| path | call | one-line reason | risk of removing |
|---|---|---|---|
| `bin/goblin-upgrade` | CUT | targets the deleted `.goblin/goblin.yaml` + `~/.goblin/engine`; verb already refused | no in-place refresh — `init --write` re-pins |
| duplicate dispatcher (`bin/goblin` bash vs `bin/goblin.js`) | CUT | two dispatchers for one surface | keep the npm shim delegating to one bash core |
| `bin/goblin-audit` + SC-07/SC-08 | CUT | network lane; writes `.goblin/audit.tsv`, row reads `.gob/audit.tsv` | dependency-vuln gating is ops/CI, not a session gate |
| CI lane + `docs/CI.md` | CUT | v2 ships no CI; the doc describes an absent lane | `PG-05/PG-06` lose their artifact — already cut |
| `docs/RE-PLAYBOOK.md` | DEFER | P15 re-mobile + `RC-*`; research/lab only | labs lose the procedure — returns under `class: research` |
| `extras-catalogue` + `gob extras` + `discover_extras` | CUT | 41 rows, 1 payload, inert; web-discovery contradicts no-network/no-AI | loses the suggestion list — the extend mechanism adds what the repo needs |
| `adapters/` + `bin/goblin-emit` + `sync_platforms` | CUT | 7 near-duplicate `verify.sh`; README already calls sync "a later alpha" | no per-platform emit — the neutral harness + `LX-*` skills cover it |
| `bin/goblin-doctor` | CUT | unwired; `VA-01` is the live half, and `VA-01` is deferred | lose doctor generation — deferred with the corpus |
| `bin/goblin-model` + `roles.yaml` + `docs/LOOP.md` + `docs/ROLES.md` | CUT | the harness never names a model — out of the thesis | lose the role vocabulary; `MD-*`/`JG-02` cut with it |
| `automations/` | CUT | no producer ships; `AU-01..04` have nothing to read | lose bugreporter/drift-audit — they gate a producer that does not ship |
| `presets/` (6 files) + `manifest/classes.tsv` + the `--class` flag + the class aliases | CUT | the class only selected which bans ran; `applies_when: <glob>` on each ban row replaces it | ban-set detection now rides on real file patterns — nothing to declare |
| `branch:` + `owner_email:` keys, rows `CM-01 CM-03 PT-01 PT-02` | CUT | the gate reads git; neither key is a decision worth asking a human for | a declared branch that drifts is a claim nothing needs |
| 17 docs → **3** | CUT | most restate the same contracts | target: `README.md`, `docs/GUIDE.md` (folds CONTRACTS+ADOPTION+FLOWS+INTEGRATION), `docs/ENFORCEMENT.md`, `docs/LIMITS.md` (the honesty ledger). Fold RISKS+GLOSSARY. |

---

## F. Test strategy

**Survive (behavioural — each can go RED):** `t-verify-green`, `t-verify-red`,
`t-verify-nested`, `t-gt03-freshness`, `t-init`, `t-install-idempotent`, `t-install-refusal`,
`t-install-off-switch`, `t-uninstall`, `t-mcp`, `t-shim`, `t-practice-repin`,
`t-version-sync`, `t-banner-stderr` (its dead assertion, `$([ "$NONV" -ge 0 ] …)`, is fixed
to a real one).

**Go (assert-a-string-is-present — the defect the product exists to catch):** `t-doc-guide`,
`t-doc-guide-init`, `t-doc-promises`, `t-doc-replay`, `t-doc-sync`, `t-render-tokens`,
`t-extras`, `t-automation-silent` (surfaces cut above).

**Rule:** only behavioural tests survive. A test whose only failure mode is a doc string
moving is itself the anti-pattern gobstack mechanises against; a green that cannot go red
proves nothing. `t-map` folds into `t-init` (the map is now validated in the same pass).

---

## G. Hygiene fix list

- **`.goblin/` leftovers** — 26 files under `docs/ skills/ bin/ automations/ bans/` still
  name the pre-rename path. Fix to `.gob/`; the offenders that remain after the cuts
  (`goblin-audit`, `automations/`) disappear with their rows.
- **`goblin.yaml` ghosts** — 24 references treat `.gob/goblin.yaml` as live config;
  `bin/goblin-lib.sh:276` says plainly there is no `goblin.yaml`. `docs/CONTRACTS.md:52`
  still lists it as the owned config file — point it at the `AGENTS.md` block.
- **Verb count** — README "seven", CHANGELOG "six", GUIDE "five". v3 settles on **four**:
  `init`, `verify`, `mcp`, `uninstall` (`bans` folds into `verify`; `map` folds into `init`).
- **`.gitignore`** — lines 1–3 still ignore `.goblin/state.json`, `.goblin/last-gate-line`,
  `.goblin/.ds-report`; make them `.gob/…`.
- **CHANGELOG gap** — newest header is `0.6.0-alpha.2` while `VERSION` (and package.json) is
  `0.6.0-alpha.4`; add the missing headers (or collapse to one unreleased entry).
- **python3** — `bin/goblin-init:66` hard-requires python3 for a peripheral `.mcp.json`
  merge. Drop the requirement; the only real python use is the model-mapping read, which goes
  with `goblin-model`.

---

## H. Decisions — RESOLVED (Harvey, 2026-10-09)

| # | Question | Decision |
|---|---|---|
| 1 | Four verbs vs keep `bans` | **4 verbs**: `init`, `verify`, `mcp`, `uninstall`. `bans` folds into `verify --bans` |
| 2 | Core skills by default | **Yes** — installed into `.gob/skills/` so `SK-01..04` always bite |
| 3 | Extend: local tsv vs new verb | **No new verb** — the gate's own SKIP remedy line is the brief |
| 4 | Core skill set | `goblin-mode`, `-investigation`, `-bugfix`, `-feature`, `-handoff`, `-verify-author`, `practice` |
| 5 | Feature map every class | **ALWAYS required, every class** — no empty state exists |
| 6 | Keep `uninstall` verb | **Yes** — there has to be a way back |
| 7 | Docs: 4 or 3 | **3**: `README.md`, `docs/GUIDE.md`, `docs/LIMITS.md` (ENFORCEMENT folds into GUIDE) |

Additional decisions, same date:

- **`branch:` and `owner_email:` are DROPPED.** The gate reads git directly; rows `CM-01`,
  `CM-03`, `PT-01`, `PT-02` go with them.
- **MCP registration happens INSIDE `init --write`** — the user runs no second command, and
  **no gob command ever again** after install.
- **Empty repo → REFUSE** with a named remedy. No bootstrap feature is invented.
- **Verify is reduced to the ~19 always-on rows.** Anything not right for every repo DEFERS to
  the extend mechanism rather than shipping as a permanent SKIP.
- **The product must be symbiotic**: the only durable touchpoints are the `AGENTS.md` block,
  `.gob/`, `features/`, `HANDOFF.md` and the MCP registration the agent already reads.

### `class:` removed, and why the gate stays (Harvey, 2026-10-09)

**`class:` is CUT.** After the reduction to ~19 rows, the class selected exactly one thing —
which bans ran — and a ban is code-shaped (`any` only means something in a TypeScript file).
The replacement is `applies_when: <glob>` on each `manifest/bans.tsv` row: the verifier runs a
ban only when a real file matches. Zero declaration, and it cannot be wrong. This also removes
`presets/` (the 6 files that *were* the class definitions), `manifest/classes.tsv`, the A–E /
app / agent / desktop aliases, the `--class` flag, and the "bad class" refusal branch.

**The gate STAYS and is the product.** Everything else the harness carries — the map, the
handoff, the skills — is organisation. `gate_<name>_cmd` is the only thing that converts
*"it works"* from a claim into a measurement, because it is the one command the harness can
re-run on its own to check a claim the agent made. Remove it and `verify` has nothing to
measure: it degrades into the agent asserting success, which is the exact disease gobstack
exists to cure.

It is not a key a human maintains — the **agent records it** during init, like the feature map.
Rejected alternative: deriving the gate every run from `package.json` scripts / Makefile / CI.
Detection can silently pick the wrong script, and a wrong gate that passes is strictly worse
than no gate at all — a false green is the one failure this product must never produce.

So the config block settles at **three keys**: `gate_<name>_cmd`, `feature_map`, `source_root`.

### Original questions, kept for the record

1. **Four verbs** (`init`, `verify`, `mcp`, `uninstall`) — or keep `bans` separate, since
   "run it before you write the line" is a real workflow?
2. Do the core skills install **by default** (making `SK-01/02/04` always bite), or stay
   opt-in as today?
3. Extend mechanism: purely `enforcement.local.tsv` + `.gob/checks/` driven by the gate's
   remedy lines, or do you want an explicit `gob extend` brief (which then owes a removal)?
4. Core skill set — `goblin-mode`, `goblin-investigation`, `goblin-bugfix`, `goblin-feature`,
   `goblin-handoff`, `goblin-verify-author` (+ `practice`): add or drop any?
5. Is the feature map required for **every** class at init, or only software/game (a
   research/lab repo may have no user-facing feature)?
6. Keep `uninstall` as a verb, or reduce it to the npm one-liner?
7. Docs target: keep four (README, GUIDE, ENFORCEMENT, LIMITS), or fold ENFORCEMENT into
   GUIDE and ship three?
