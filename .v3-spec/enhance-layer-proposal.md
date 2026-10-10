# gobstack as an enhancement layer — compose, don't compete

Status: PROPOSAL for Harvey's decision. Date: 2026-10-10. AMENDED same day per Harvey:
external-skill integration is a **category inventory** (data-only list the init-time agent
adjudicates per repo), not a `compose:` config key — see §4.1. Branch: `v3-core` @ a7db4d7,
VERSION 0.6.0-alpha.4. Supersedes nothing in `.v3-spec/gobstack-v3-core.md` — it builds on
it. The one-sentence thesis:

> gobstack's surviving job is to be the **deterministic floor** that superpowers, BMAD and
> spec-kit all lack — not a fourth framework stacked beside them.

Everything below is measured against the tree as it exists on `v3-core` today: 4 verbs
(init / verify / mcp / uninstall), 31 always-biting manifest rows + 32 library rows + 8
glob-gated bans, 18 skill dirs in `skills/` (17 `goblin-*` + `practice`), the AGENTS.md
gob-block (3 live keys: `gate_<name>_cmd`, `feature_map`, `source_root`), the `.gob/`
extend mechanism, HANDOFF.md, npm packaging, and the hand-rolled stdio MCP server.

---

## 1. Interop analysis — duplicate vs complement

### 1.1 superpowers (skills packs, ~297k stars)

superpowers ships SKILL.md packs — the same agentskills.io-shaped format gobstack's
`skills/*/SKILL.md` already uses. The overlap is real and it is the *content*, not the
format:

| gobstack surface | Verdict | Why |
|---|---|---|
| `goblin-tdd-repro`, `goblin-bugfix`, `goblin-investigation`, `goblin-refactor`, `goblin-feature` (P1–P5) | **DUPLICATE** | superpowers ships mature skills for exactly these loops (TDD, systematic debugging, root-cause, plan-then-execute). A single owner with zero users has no reason to maintain his own smaller copy of commodity skills. |
| `goblin-mode` (request router) | **DUPLICATE** | A router skill is the host platform's job (Hermes skill routing, superpowers' own dispatcher). Two routers fight; the host always wins. |
| `goblin-eval`, `goblin-sweep`, `goblin-overnight`, `goblin-pr-gate`, `goblin-bugreporter`, `goblin-drift-audit`, `goblin-re-mobile` (P7, P10–P15) | **DUPLICATE / DORMANT** | Process playbooks with no gate coupling. They were valuable when gobstack was a product; as a personal layer they are shelf-ware Harvey can get from packs he didn't have to maintain. |
| `goblin-handoff` (P9) | **COMPLEMENT** | Tied to `HANDOFF.md` and the HP rows the gate enforces. superpowers has no gate, so its equivalent advice is unenforceable. Keep. |
| `goblin-verify-author` (P6) | **COMPLEMENT (unique)** | Authors the gate set + harness + feature map and executes them end to end. Nothing in superpowers/BMAD/spec-kit authors a *checkable* gate. This skill is the manual for gobstack's one unique artifact. Keep. |
| `goblin-feature-map`, `practice` | **COMPLEMENT (unique)** | The feature map feeds FM-01/FM-02; `practice` is the composition hook (reads any external standard pinned by path in the gob block). Both exist only because the gate exists. Keep. |
| `goblin-bootstrap` (P8) | **MORPH** | Becomes the "adopt the layer + wire your packs" skill (see §3/§4). |

Net: **13 of 17 goblin-* skills duplicate or are dormant commodity skills the owner should not be
maintaining; 4 are gate-coupled and survive because the owner's enforcement floor
depends on them.**

### 1.2 BMAD (roles/workflows, ~54k)

goblin-stack already cut its role vocabulary (`roles.yaml`, `goblin-model`, MD-* rows,
`docs/ROLES.md`, `docs/LOOP.md` — CUT list, §E of the v3 spec). That cut **was** the BMAD
interop decision: roles/workflows are BMAD's territory and gobstack carrying a smaller copy
was pure duplication. Remaining check: none — gobstack today names no model and no role.
COMPLEMENT BY ABSENCE. The only seam to keep is that a BMAD workflow's "definition of done"
step can call the verify gate (§4).

### 1.3 spec-kit (spec-first flow, ~141k)

spec-kit owns specify→plan→tasks. gobstack's SP-01/02/03 (SPEC-per-change) rows were
correctly deferred to `library.tsv` — duplicating a spec flow would be maintaining a
redundant copy of a stage the owner gets from elsewhere. COMPLEMENT: spec-kit produces artifacts (spec.md, plan.md,
tasks.md); gobstack can *check* them via the extend mechanism (an `LX-*` row: "spec.md
committed before the changes it governs" — the old SC-01 shape, enabled only in repos that
adopt spec-kit). gobstack never generates specs.

### 1.4 Native hooks + AGENTS.md (Claude Code / Cursor / Codex, 60k+ AGENTS.md repos)

Enforcement-by-exit-code is native now — that is exactly why the standalone-CLI product
died. gobstack does not compete here; it is a **payload** for this layer. The AGENTS.md
gob-block is a well-behaved citizen (fixed marker block, pure awk parser, zero interference
with other frontmatter consumers). The missing piece is that `init --write` writes no hook:
today the gate is invoked by the agent's discipline (MCP or instructions), never mechanically
by the platform. Hook configs (`.claude/settings.json`, `.cursor/hooks.json`) are the native
transport the v2 pivot predicted — gobstack should *emit into them* rather than pretend
instructions are enforcement.

### 1.5 Where gobstack's unique value survives

Three artifacts survive every comparison, because all three are **deterministic, offline,
and owned by the repo** — nothing else the owner could adopt ships any of them:

1. **`.gob/bin/goblin-verify`** — the exit-code gate: ~19 core rows + glob-gated bans +
   `LX-*` local rows, runs on plain git+bash with no gobstack installed, no network, no AI,
   FAIL rows carry remedy lines. This is the floor: it converts "the agent says it's done"
   into a measurement. It is the one thing every framework above can *call* and none can
   *replace*.
2. **The extend mechanism** (`.gob/manifest/enforcement.local.tsv` + `.gob/checks/<ID>.sh`
   + `.gob/skills/`) — the only mechanism in the landscape where an agent adds a repo-specific
   rule and **cannot self-certify** it (RED-on-defect/GREEN-on-fixed proof required, advisory
   rules counted not asserted). This is also the natural intake valve for *other tools'* rules.
3. **HANDOFF.md + the HP rows** — session continuity that the gate *checks* (note exists,
   has sections, names a commit, carries a re-measured gate number). Every competitor's
   handoff advice is honor-system.

Everything else — routers, role vocabularies, spec flows, generic process playbooks — is
commodity the owner should get from elsewhere instead of maintaining.

---

## 2. KEEP / CUT / MORPH — every current surface

| Surface | Call | One-line reason |
|---|---|---|
| `gob init` | **MORPH** | Stays the single agent-brief flow, but its write-set gains the platform payload (hooks snippet, §3.2) and its brief gains an "external categories" section: the agent reads the shipped category inventory (§4.1), evaluates this repo, and asks before installing anything. One flow, more of it machine-checkable. |
| `gob verify` | **KEEP** | The core. Exit-code + `--json` contract becomes the documented seam every external tool calls (§4.2). |
| `gob mcp` | **MORPH → optional** | Convenience, not dependency (already the design rule). Demote from core: hooks are the mechanical layer for Claude Code/Cursor, Hermes needs neither. Keep the file (it works, zero deps) but `init` stops registering it by default — opt-in `--with-mcp-config` only. |
| `gob uninstall` | **KEEP** | There must be a way back; grows the hook-snippet removal alongside `.mcp.json` (hash-guarded, as today). |
| Verify core rows (31 in `enforcement.tsv`: IN/HP/GT/SK/SC-01/BN-00/FM/PR) | **KEEP** | All always-bite or advisory-count rows; PR-01..04 verify `practice:` composition — the seam made checkable. |
| Verify library rows (32 in `library.tsv`) | **KEEP as-is** | Already the honest available-but-OFF tier; spec-kit/BMAD adoption enables SP-*/*-shaped rows via the extend path rather than new code. |
| Bans (8, `applies_when` globs) | **KEEP** | Code-shaped, zero-declaration, the class-taxonomy cut already landed correctly. |
| `goblin-mode`, `-investigation`, `-bugfix`, `-refactor`, `-feature`, `-tdd-repro` | **CUT from shipped payload** | Commodity skills — stop maintaining our own smaller copy; not needed by the owner, who gets them from packs he doesn't have to maintain. Repo keeps them on a branch for Harvey's own reference only. |
| `goblin-eval`, `-sweep`, `-overnight`, `-pr-gate`, `-bugreporter`, `-drift-audit`, `-re-mobile` | **CUT from shipped payload** | No gate coupling, dormant since the row cuts; playbooks without a checker are exactly the "counted, never checked" anti-pattern. |
| `goblin-handoff`, `-verify-author`, `-feature-map`, `practice`, `-bootstrap` | **KEEP (5)** | Gate-coupled and unique (§1.1/§1.5); `bootstrap` morphs into the adopt+compose skill. |
| SK-01..04 skill rows | **KEEP** | They now verify *whatever skills the repo carries* — including imported superpowers packs. The rows are content-agnostic; that is the point. |
| AGENTS.md gob-block | **KEEP** | Single config source, pure awk parser, proven frontmatter round-trip (bug classes documented). No new key: which external packs a repo uses is recorded in the local skill manifest (§4.1) after the init-time agent adjudicates the category inventory — config stays 3 keys. |
| `.gob` extend mechanism (LX-* rows, checks/, skills/) | **KEEP — this becomes the composition engine** | See §4. It was designed for agent-authored rules; third-party rule intake is the same mechanism with a different author. |
| `HANDOFF.md` + HP rows | **KEEP** | Unique enforced continuity. |
| npm packaging (`@techgoblin/gobstack`) | **FREEZE, then CUT from the critical path** | Personal layer: primary install becomes the repo itself (§3). Keep the npm name parked (repo public, alpha.4 latest — the standing decision says no deprecation chores); `npx github:harveynguyen33/gobstack init` works as one-shot transport without any publish. Zero publish cadence, zero dist-tag hygiene, zero OTP. |
| MCP server (`bin/goblin-mcp.js`) | **KEEP the code, demote the surface** | Optional convenience for MCP-native hosts; never load-bearing. `t-mcp` stays. |
| `bin/goblin-install`, `goblin-map` (internal) | **KEEP** | Internal engines behind init; no surface change. |
| `manifest/playbooks.tsv` + playbook rails | **CUT** | The playbooks it indexes are being cut; a rail for a cut list is a permanent SKIP with extra steps. |
| `manifest/glossary.tsv` | **MORPH → docs/RECORD-NOTES.md** | Wave-code legend already lives there; one home, not two. |

Count check: 5 skills kept + 13 cut + 1 morphed = 18 measured dirs ✓ (13 = 6 loop/mode skills + 7 process playbooks; bootstrap counted once as KEEP with morphed content). Verbs stay 4 ✓ (the
"nothing added without naming a removal" rule holds: hooks emission is inside init's existing
write-set; the category inventory is shipped data inside the existing vendored engine tree,
replacing the deleted extras-catalogue's *role*, not its code; the npm surface is removed).

---

## 3. Target shape — one source of truth, two install targets

**Source of truth = this repo.** The engines, manifest, templates and the 5 kept skills live
here and nowhere else. A target repo gets a **vendored copy** (`.gob/engine/`, hash-pinned in
`installed.json`, IN-02 catches drift) — that already works and stays. What changes is what
`init` writes *besides* the engine.

### 3.1 (a) Harvey's Hermes profile

- **Skills**: the 5 kept skills install into `~/.hermes/skills/` (as `gob-*`), alongside the
  existing `goblin-stack` skill, which is rewritten to the new layer description (work ON the
  layer + adoption of it). superpowers-style packs Harvey wants live in the same directory —
  Hermes does its own routing; gobstack ships no router.
- **Hooks**: Hermes' post-task hook (or the profile's session-end discipline) calls
  `bash .gob/bin/goblin-verify` in the active project — the same command Claude Code hooks
  call. No MCP registration in the profile at all; Hermes shells out natively.
- **Config**: repos Harvey works in carry the AGENTS.md gob-block; the profile carries
  nothing repo-specific. The layer stays per-repo, the *skills* are per-profile — same split
  as today, minus npm and minus the router.
- Install/refresh = `git -C ~/projects/goblin-stack pull && gob sync-profile` — no, that
  would be a fifth verb. The honest shape: the 5 skills are **files**; a one-line `cp -r`
  from the repo into `~/.hermes/skills/` documented in the layer's own SKILL.md. No verb, no
  code, nothing to rot.

### 3.2 (b) A plain repo with Claude Code / Codex / Cursor

One `init` write-set, vendor-agnostic:

```
AGENTS.md            body + gob block (3 keys)                      ← config source of truth
.gob/engine/         verifier + manifest + bans + library.tsv       ← vendored, hash-pinned
                     + categories.tsv                               ← data-only category inventory (§4.1)
.gob/bin/goblin-verify                                              ← the gate (plain bash+git)
.gob/checks/ .gob/skills/ .gob/manifest/enforcement.local.tsv       ← extend mechanism; skills/
                                                                    fills only if the agent
                                                                    adjudicates + user approves
HANDOFF.md           once, never overwritten
features/            the map, FM-01/02 live on day one
.claude/settings.json | .cursor/hooks.json  (if the vendor dir exists)
                     → hook payload: run .gob/bin/goblin-verify on Stop/PreCommit,
                       non-zero exit blocks "done"
.mcp.json            ONLY with --with-mcp-config (opt-in, hash-guarded on uninstall)
```

Codex has no hooks dir — for it the AGENTS.md body carries the one instruction line ("run
`bash .gob/bin/goblin-verify` before reporting done; FAIL rows carry remedies"), which is the
existing layer-1. The hook payload is written **only when the vendor's config dir already
exists** (detection, never creation) and is hash-recorded so uninstall removes exactly what
init wrote — the `.mcp.json` contract, reused.

**One source of truth** holds because: config = the gob block (one parser); engine = the
vendored copy pinned to the repo of origin; skills = whichever packs the agent adjudicated in
from the category inventory (recorded, with reasons, in the local skill manifest — §4.1);
nothing is generated that isn't re-derivable from `init --write`'s inputs plus the recorded
decisions.

---

## 4. Composition seams — the concrete mechanism

### 4.1 What gobstack CONSUMES from superpowers/BMAD/spec-kit: their content, never re-implemented

- **Skills/playbooks as files.** A superpowers pack, a BMAD workflow doc, or a spec-kit
  checklist is just markdown under `.gob/skills/<name>/SKILL.md` (or any dir the AGENTS.md
  body points to). The moment it lands, **SK-01/02/04 already apply** — shape checked, hash
  pinned, limits declared. No importer code: the extend mechanism's skill lane *is* the
  import path. License rule carries over unchanged: nothing lands without a license line in
  the local manifest (`added_by` names the source repo; `why` names the license).
- **The category inventory (danh mục phụ trợ) — how external packs get proposed.** gobstack
  ships a **data-only** inventory file listing candidate external categories; it carries no
  payloads, no pre-built skills, no install logic — just rows:

  ```
  # .gob/engine/categories.tsv — auxiliary category inventory (DATA, never code)
  # category<TAB>pack<TAB>source<TAB>license<TAB>provides<TAB>fits_when
  process-skills	superpowers	https://github.com/obra/superpowers	MIT	TDD, systematic-debugging, brainstorming, writing-plans loops; all as SKILL.md packs	repo does feature/bugfix work and wants battle-tested process skills
  spec-first	spec-kit	https://github.com/github/spec-kit	MIT	spec.md/plan.md/tasks.md checklists + SDD flow; pairs with an LX-* row that checks spec-before-change	repo is spec-driven or multi-session feature work dominates
  roles-workflows	BMAD-METHOD	https://github.com/bmad-code-org/BMAD-METHOD	MIT	role/workflow docs (PM/architect/dev loops) for repo-level planning ceremony	repo is greenfield/product-shaped with planning phases
  ```

  **Where it lives:** `.gob/engine/categories.tsv`, vendored with the engine (hash-pinned in
  `installed.json` like every other engine file), so a target repo's copy is pinned to this
  repo of origin. Source of truth is `manifest/categories.tsv` in this repo (same home as
  `enforcement.tsv`/`library.tsv`); init vendors it to `.gob/engine/categories.tsv` the same
  way it vendors the verifier. TSV, same conventions as `manifest/*.tsv` (tab-separated,
  `#` comments, header row). gobstack's own executable has **zero** lines of code reading it
  — the reader is the agent following the init brief; the vendored copy just ships the data.
- **Agent adjudication at `init` time — never auto-install.** The init brief gains a fixed
  "external categories" section: *read `categories.tsv`; for each row, evaluate this repo
  against `fits_when`; for every row that fits, PROPOSE it to the user (name, source,
  license, what it would add) and install only on approval — fetch the pack, drop it in
  `.gob/skills/<name>/` through the existing SK-checked lane, and record the row in
  `.gob/manifest/enforcement.local.tsv`-adjacent skill manifest (`added_by` = source URL,
  `why` = license + the fit reason). Rows that don't fit: skip silently is not allowed —*
  see the decision record below. The agent is the adjudicator because it can read the repo;
  gobstack's code cannot.
- **The decision record (auditability).** For every inventory row the agent evaluates, the
  init brief requires one line appended to `.gob/manifest/compose-decisions.tsv`:
  `date<TAB>category<TAB>decision(installed|declined)<TAB>reason`. A declined row must name
  the concrete reason ("no feature work in history; tests are the whole repo", "planning
  ceremony already handled by HANDOFF discipline"). A blank reason or an unrecorded row is
  itself an init-brief violation the next session can catch — the file is the audit trail of
  what the layer considered and why it stayed out.
- **`compose:` is gone; nothing replaces it in the gob block.** No new key, no parser
  change, and the block stays 3 keys. `PR-01..04` are untouched — they keep verifying
  `practice:` pins against whatever skills actually live in `.gob/skills/`, so an
  agent-adjudicated pack is checked the moment it lands. The DELETE that pays for the
  inventory is unchanged — `manifest/playbooks.tsv` + `extras-catalogue/` (already
  deferred/inert). The inventory replaces the catalogue's *role* (a listed inventory of
  candidates) while inverting its mechanism: list-only data + agent-decided-at-install,
  instead of inert rows with pre-built matches/conflicts columns and one payload.
- **Other tools' rules as `LX-*` rows.** "spec-kit repos: spec.md committed before the
  changes it governs" or a BMAD gate is one `LX-*` row + one `.gob/checks/<ID>.sh` —
  authored once by the agent, proven RED/GREEN, counted honestly. gobstack never grows a
  `spec-kit integration module`; it grows zero code per framework.
- **Rejected explicitly:** re-implementing any workflow stage (specify/plan/tasks, roles,
  routing). Each would be a competing copy of a dominant tool — the exact mistake the
  product pivot corrected.

### 4.2 What gobstack EXPOSES to them: the gate, callable from anywhere

- **The exit-code contract** (documented on one README block): `bash
  .gob/bin/goblin-verify` → exit 0 green / 1 red (FAIL rows on stdout, each with a remedy
  line) / 2 refusal (not installed, tampered) / 3 malformed. Any superpowers skill, BMAD
  workflow, or spec-kit task list can end with "run the gate; non-zero = not done" — that
  line is vendor-neutral and works in every one of their formats.
- **`--json`** for tool integrations (already exists via the MCP wrapper's subprocess): the
  machine-readable row set for anything that wants structured verdicts.
- **The hooks payload** (§3.2): the platform-level caller, so the gate runs even when the
  framework's workflow forgets to call it.
- The rule that keeps this honest: **the gate only ever runs the repo's own checks.** It
  never imports a framework's notion of done — frameworks may *author* `LX-*` rows, and then
  the check is the repo's, proof and all.

### 4.3 The removal ledger for this proposal

| Addition | Removal that pays for it |
|---|---|
| `categories.tsv` inventory + init-brief adjudication section + decision record | `extras-catalogue/` + `manifest/playbooks.tsv` (deletion stands as planned — the inventory replaces the catalogue's **role** as listed inventory, not its code: it ships list-only data with no matches/conflicts columns and no pre-built payloads, and adds zero gobstack code paths) |
| hooks-snippet emission in `init --write` | MCP registration stops being default (opt-in flag) |
| 5-skill payload | 13 cut skills + the rails that indexed them |
| `npx github:…` install path | npm publish cadence, dist-tag hygiene, OTP chores (package frozen) |

The ledger balance on the inventory row: the old catalogue was 41 inert rows + 1 pre-built
payload + reader code; the replacement is 3 data rows + a fixed section of prose in the init
brief + one appended-to TSV. Net code change is negative; the "nothing added without naming
a removal" rule holds because what's added is data and brief text, and the reader/rows it
replaces are deleted in the same phase.

---

## 5. Phased migration plan — small steps, each shippable, suite green at every commit

**Phase 1 — cut the commodity skills (1 commit wave, ~3 batches).** Delete the 13 cut skill
dirs from the shipped payload (move to an `attic/` branch, not history-rewritten). Re-measure
payload counts, sync the pins (the checklist in the layer skill's pin-sync section applies:
`t-install-off-switch`, `t-doc-*`), delete `manifest/playbooks.tsv` and its reader. Shipped
= the payload carries only gate-coupled skills; suite green; no behavior change to verify.

**Phase 2 — hooks payload in `init --write` (1–2 commits).** Write the hook snippet into an
*existing* `.claude/` or `.cursor/` dir (detection-only, never create the dir), record its
hash next to `.mcp.json`, extend uninstall with the same hash-guard. New behavioural test:
`t-hooks` (write → file exists with exact bytes; second write idempotent; uninstall removes
only hash-identical; refuses a user-customized one). Flip MCP registration to opt-in in the
same phase — that is the named removal.

**Phase 3 — category inventory + catalogue deletion (2 commits).** Author
`manifest/categories.tsv` (init vendors it to `.gob/engine/categories.tsv` per §4.1): the
auxiliary category inventory,
seeded with real, verified entries as of Oct 2026 — `process-skills` / superpowers
(https://github.com/obra/superpowers, MIT; TDD, systematic-debugging, brainstorming,
writing-plans packs), `spec-first` / spec-kit (https://github.com/github/spec-kit, MIT;
spec/plan/tasks checklists + the LX-* spec-before-change pairing), `roles-workflows` /
BMAD-METHOD (https://github.com/bmad-code-org/BMAD-METHOD, MIT; role/workflow docs). Each row
carries category, pack, source URL, license, what-it-provides, fits-when — data only, no
payloads. Delete `extras-catalogue/` and the extras code path (already inert: 41 rows,
1 payload); `t-extras` dies with it. Extend the init brief with the fixed "external
categories" section: read the inventory, evaluate each row's `fits_when` against this repo,
propose fits to the user, install only on approval via the SK-checked skill lane, and append
every decision — installed or declined, with reason — to
`.gob/manifest/compose-decisions.tsv`. Behavioural test in `t-init`: given a repo that fits
zero rows, init must produce a decisions file with a declined line + reason for each row, and
`.gob/skills/` stays empty.

**Phase 4 — Hermes profile packaging (no code).** `cp -r` the 5 skills into
`~/.hermes/skills/` as `gob-*`; rewrite the `goblin-stack` skill's description and
When-to-Use to the layer story (adopt + maintain + compose); document the profile hook line.
Dogfood on one repo (goblin-tlhl's legacy `.goblin/` conversion is the natural first adopter
already named in the standing decisions).

**Phase 5 — npm freeze + docs non-goal (1 commit).** npm stays frozen exactly as it is
(registry version alpha.4, no publish, no deprecation notice — standing decision) and is not
touched further. README/GUIDE/LIMITS get **no rewrite** — docs-for-others are an explicit
non-goal under the personal-only pivot. The only permitted docs change is at most a 3-line
personal note at the top of README: this is Harvey's personal layer; install = clone + init.
Nothing else in the docs is rewritten, polished, or repositioned.

**Phase 6 (optional, only if used) — a compose example repo.** One throwaway repo adopted
with a superpowers pack + a spec-kit flow + one `LX-*` row per §4.1, proving the seams end
to end. The persona-sim rule applies: a green gate proves mechanics, not whether composition
actually works — run it once for real before declaring Phase 6 done.

Sequencing note: Phases 1–3 are each independent and shippable; 4 and 5 are near-trivial
(the phase-5 docs change is at most a 3-line README note) and can ride together; 6 is the
acceptance pass for the whole proposal.

---

## 6. What this proposal deliberately does NOT do

- No new verb, no new config key. `init` gains a write-set; composition is adjudicated by
  the agent at init time from shipped inventory data (§4.1); the profile install is a file
  copy. Four verbs stand.
- No code per competitor. superpowers/BMAD/spec-kit integration is: their files in our
  checked lanes, our gate in their workflows. Zero imports, zero adapters.
- No deprecation of the npm package, no README-for-strangers polish, no adoption funnel —
  the personal-only pivot stands; this proposal only stops the payload from carrying
  competitors' best content and points the gate at the platforms that can actually call it.
