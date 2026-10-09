# Risk register and non-goals

## Risks

| # | Risk | Counter-measure | Status |
|---|---|---|---|
| K1 | **Model promotion churn** breaks a role binding | Roles are capabilities, never slugs; one mapping file; `MD-01` lints every artifact for a hardcoded model name; `MD-02` reports family equality. A campaign that changes nine profiles changes nothing here. | Handled by design |
| K2 | **Profile drift across the fleet** | The attack surface is removed, not managed: project procedures live in the repo's `.hermes/skills/`, so there is no second copy to drift. `SK-02` hashes what is installed. The existing divergence outside goblin-stack's scope is a separate, escalated cleanup. | Handled in scope; fleet-side cleanup escalated |
| K3 | **Skills duplicating between profiles** | Same as K2. The precedence order is stated in `docs/INTEGRATION.md` so a future agent knows which copy wins instead of guessing. | Handled by design |
| K4 | **The vendored copy rots** (a repo sits at an old version) | `installed.json` records version and hashes; `goblin-verify` reports the installed version; `--upgrade` prints created/updated/unchanged. Accepted for repos that stop being worked on — the alternative (a network call at verify time) violates the offline dependency contract. | Accepted, with detection |
| K5 | **The harness decays into prose** | `IN-03` plus `SK-03`: a row without a command must say `advisory`, and the advisory count is capped (`advisory_ceiling`, default 10). The cap is the ratchet. | Handled by design |
| K6 | **A HANDOFF carries a stale number** | `HP-03` requires `measured <date>`; `HP-05` requires a commit that exists. | Partial: proves a date exists, not that the number is fresh. V1 anchored the row on the gate names the config declares (and skips the template's example sentence), so the real gate line can no longer lose its date in silence - but nothing re-measures the number, and a gate-bearing line that names no declared gate and carries no gate-shaped keyword is still unseen |
| K7 | **The gate is theatre** (self-skipping checks, admin bypass) | `PG-05` FAILs a conditional **job**, a conditional **step**, a job with no step and a workflow with no `jobs:` - re-declared at W4, because the old predicate counted "every step is guarded" and therefore passed the measured real shape (one unguarded step deciding whether the guarded gate step runs) while GitHub reported Success. `PG-06` then requires the gate CI runs to be the gate the project declares. `PG-04` documents the bypass. *"A required check that self-skips reports success… and a protected branch whose only admin is the person pushing protects nothing."* | Mechanised where a file can be read (`docs/CI.md` §1); the required-check list, the bypass switch and the push identity are forge state and stay documented, not solvable from the repo (`docs/LIMITS.md` #13, #34) |
| K8 | **Cost** | Roles plus effort tokens; the panel only at S3+; sweeps are cron-and-one-line; no playbook fans out without a named predicate. | Handled by policy |
| K9 | **The builder may only install into its own repo plus a scratch copy** | The install proof target is a throwaway copy under the scratch directory; the recipe is in `docs/ADOPTION.md`. | Constraint, satisfied |
| K10 | **A fleet-config repo is the least-governed artifact in an estate** | The E-class preset plus an artifact-scoped gate (a commit exists). The underlying staleness bug in a backup job is named and escalated — goblin-stack can detect staleness but cannot fix another repository. | Escalated |
| K11 | **The pre-change tree is unknown in a repo with no git history** | Repos with no `.git` are ordered *after* `git init`. `HS-02` is **skipped with a reason** rather than faked while no pinned commit exists. | Handled by ordering |
| K12 | **A check green on both trees** (the failure mode the REPLAY exists for) | `HS-02` runs the harness set against the pinned pre-change commit and requires **every** harness to be RED there. The shipped scaffold harness is deliberately such a check and is therefore reported as unproven until it is replaced. | Handled by design; see `docs/LIMITS.md` |
| K13 | **A nightly automation files the same defect twice, or files one that is not there** | A content-only dedup key (`--idempotency-key`, checked by `AU-02`) plus the board's own `recent_success` and `active_pr` guards; a report whose `revision` does not resolve is a refusal, not a card; `--max-runtime`, `--max-retries 1` and the failure limit auto-block a looping card. The producer's own ceiling bounds filings per day. | Handled by design; the key is a dedup, not a mutex (`docs/LIMITS.md` #20) |
| K14 | **A waiver becomes a permanent blind spot** - a dated exception nobody re-decides | `SC-05`'s boundary waivers are recorded decisions the row reads where it runs, and the waiver count is printed on the gate line so the debt stays loud | Handled by design |
| K15 | **goblin-stack installs agent-authored skills, and the one controlled study of that practice puts it BELOW the no-skill baseline.** SkillsBench 1.1's self-generated condition (the agent authors its own Skills before solving) reports all three tested configurations below their no-Skills baseline (-8.1, -11.3, -11.5 points), while curated Skills rose +16.6 points across 18 configurations. A generated skill accepted after a skim is a different proposition from a written one. | `P6` hands every generated verification skill to `P12`, and `verified:` does not advance until an eval record exists; the record's shape, the eleven-token ban, the cheap-checks-first ladder and the pass condition (every seeded defect detected, the control at zero, every correction RED before GREEN) are specified in `skills/goblin-eval/SKILL.md`. The evidence is cited with its pin in `docs/LIMITS.md` #15. | **Stated requirement, not an enforced one**: the runner is not shipped and no row reads a lane (`docs/LIMITS.md` #31) |
| K16 | **The feature map rots, or claims coverage it does not have** - a route renamed under a recipe that still "works", a feature file nobody indexed, a `verified:` date nobody drove | `FM-01` (every feature file indexed, the four-H2 entry contract, the slug matches the filename), `FM-02` (every declared entry path still resolves under `source_root:`, no entry path changed after its `verified:` date), `VA-01` (the declared `verify_doctor:` exits 0); the upkeep pass and the rot table live in `skills/goblin-feature-map/SKILL.md`. | Handled by design for everything the map LISTED; completeness is not checkable (`docs/LIMITS.md` #30) |
| K17 | **An unattended loop grades itself** - the judge is a language model handed the worker's own prose, the lane that judges can be the lane that wrote, and Hermes has **no progress detector**: `run_kanban_goal_loop` carries no progress state, so a loop returning `continue` for the same reason nineteen times spends nineteen turns and then blocks | `JG-01` (a `done` verdict may only cite a handle the repo can resolve - a commit in `git rev-list --all`, a path under the root, a `sha256:` of a file under `.goblin/loop/`), `JG-02` (the declared judge lane must be **disjoint** from the author's - a FAIL, not a report), `JG-03` (counted: a lane with no non-`done` verdict is escalated), and `LP-01`..`LP-05` (one predicate command, run and recorded before iteration 1, pinned by digest, budgeted under a ceiling, no three identical pointers without a green, and a write-up when it ends red). The contract is `docs/LOOP.md`. | **Partial, and stated**: disjoint *profiles* is gated; disjoint *families* needs the mapping file (`MD-02`, ADV) and *which lane ran* is unobservable from a repo (`MD-03`); the judge lane resolves to no profile on this box, so `JG-02` reports ADV with its one-line remedy rather than failing a repo for the fleet's routing. The judge's own failure modes (prose-not-evidence, a lane that always says yes, no progress detector, cost) are `docs/LIMITS.md` #32 and #33 |

| K18 | **The shipped workflow is mistaken for a gate** — a file in `.github/workflows/` with no required-check entry, with the admin-bypass switch on, or pushed under the sole admin's own identity, is decoration that reads as enforcement | The template's header states the four settings that make a workflow a gate, `docs/CI.md` §1 argues them with the vendor's own words, `PG-05` refuses a conditional job or step and `PG-06` refuses a workflow that runs some other truth, `CL-01` makes `ci-gate` a class contract (absent where the class forbids it), and the verifier's "cannot see" footer names the lane on every run | The file half is mechanised; the forge half is not observable from a repo, and `PG-04` is the row that says so (`docs/LIMITS.md` #34) |

## The advisory rows, named

Ten rows are labelled `advisory` (this sentence said nine until 2026-09-25: the tenth, `JG-03`,
landed with G2's judge lane), and the count is capped by `SK-03` (default ceiling 10 — the cap is
now **full**, `advisory 10 of ceiling 10`).
Nine carry **no executable check at all**:

- **HP-04** — a stale sentence is corrected in place with a dated parenthetical, never deleted.
- **HS-03** — source probes read text with comments blanked first.
- **CM-02** — the commit message was written to a file, not passed inline.
- **MD-03** — role-pinned fan-out goes through the kanban, not a model-less subagent spawn.
- **PG-04** — never bypass what the forge enforces.
- **DOC-01** — a significant change updates the docs that teach it.
- **DOC-02** — system-level changes are recorded wherever the project's standard says they live.
- **SC-09** — auth is applied consistently across sibling routes.
- **JG-03** — a judge lane that has never returned a non-`done` verdict is escalated. The history
  that would show a bad lane lives across cards and repos, so the counter-measure is policy (one
  known-red control verdict per wave, `docs/LOOP.md`), not a command.

One is advisory-labelled but still **reports its state** as `ADV`:

- **MD-02** — the review lane is a different model family from the code lane.

`HP-04`, `CM-02` and `MD-02` additionally print a heuristic when run with `--only`. A heuristic
is not a check: it never fails a run. A counted rule is still not an enforced one, and the cap
is a policy, not a proof.

## Non-goals

Stated so no future reader infers them:

- not a plugin or a marketplace package; no slash commands;
- **no auto-merge** — no reviewed source ships it unconditionally, and merging is a different
  decision from a green gate;
- not a fleet orchestrator — the board owns that;
- does not provision, migrate or verify models;
- does not write the vault;
- does not replace any project's existing gate (adopt, don't replace);
- is not a monorepo tool and not a CI tool. **Amended at W4:** it now places **at most one**
  workflow, into its own target, for a class that requires or permits `ci-gate` — and it runs
  nothing for that repo, holds no credentials, and cannot arm a check. See `docs/CI.md`;
- does not manage profile skill libraries;
- writes nothing outside the target repo;
- does not attempt to make the *prose* rules enforceable — it counts them instead.
