# Risk register and non-goals

## Risks

| # | Risk | Counter-measure | Status |
|---|---|---|---|
| K1 | **Model promotion churn** breaks a role binding | Roles are capabilities, never slugs; one mapping file; `MD-01` lints every artifact for a hardcoded model name; `MD-02` reports family equality. A campaign that changes nine profiles changes nothing here. | Handled by design |
| K2 | **Profile drift across the fleet** | The attack surface is removed, not managed: project procedures live in the repo's `.hermes/skills/`, so there is no second copy to drift. `SK-02` hashes what is installed. The existing divergence outside goblin-stack's scope is a separate, escalated cleanup. | Handled in scope; fleet-side cleanup escalated |
| K3 | **Skills duplicating between profiles** | Same as K2. The precedence order is stated in `docs/INTEGRATION.md` so a future agent knows which copy wins instead of guessing. | Handled by design |
| K4 | **The vendored copy rots** (a repo sits at an old version) | `installed.json` records version and hashes; `goblin-verify` reports the installed version; `--upgrade` prints created/updated/unchanged. Accepted for repos that stop being worked on — the alternative (a network call at verify time) violates the offline dependency contract. | Accepted, with detection |
| K5 | **The harness decays into prose** | `IN-03` plus `SK-03`: a row without a command must say `advisory`, and the advisory count is capped (`advisory_ceiling`, default 10). The cap is the ratchet. | Handled by design |
| K6 | **A HANDOFF carries a stale number** | `HP-03` requires `measured <date>`; `HP-05` requires a commit that exists. | Partial: proves a date exists, not that the number is fresh |
| K7 | **The gate is theatre** (self-skipping checks, admin bypass) | `PG-05` flags all-guarded workflows; `PG-04` documents the bypass. *"A required check that self-skips reports success… and a protected branch whose only admin is the person pushing protects nothing."* | Documented, not solvable from the repo |
| K8 | **Cost** | Roles plus effort tokens; the panel only at S3+; sweeps are cron-and-one-line; no playbook fans out without a named predicate. | Handled by policy |
| K9 | **The builder may only install into its own repo plus a scratch copy** | The install proof target is a throwaway copy under the scratch directory; the recipe is in `docs/ADOPTION.md`. | Constraint, satisfied |
| K10 | **A fleet-config repo is the least-governed artifact in an estate** | The E-class preset plus an artifact-scoped gate (a commit exists). The underlying staleness bug in a backup job is named and escalated — goblin-stack can detect staleness but cannot fix another repository. | Escalated |
| K11 | **The pre-change tree is unknown in a repo with no git history** | Repos with no `.git` are ordered *after* `git init`. `HS-02` is **skipped with a reason** rather than faked while no pinned commit exists. | Handled by ordering |
| K12 | **A check green on both trees** (the failure mode the REPLAY exists for) | `HS-02` runs the harness set against the pinned pre-change commit and requires **every** harness to be RED there. The shipped scaffold harness is deliberately such a check and is therefore reported as unproven until it is replaced. | Handled by design; see `docs/LIMITS.md` |
| K13 | **A nightly automation files the same defect twice, or files one that is not there** | A content-only dedup key (`--idempotency-key`, checked by `AU-02`) plus the board's own `recent_success` and `active_pr` guards; a report whose `revision` does not resolve is a refusal, not a card; `--max-runtime`, `--max-retries 1` and the failure limit auto-block a looping card. The producer's own ceiling bounds filings per day. | Handled by design; the key is a dedup, not a mutex (`docs/LIMITS.md` #20) |

## The advisory rows, named

Eight rows are labelled `advisory`, and the count is capped by `SK-03` (default ceiling 10).
Seven carry **no executable check at all**:

- **HP-04** — a stale sentence is corrected in place with a dated parenthetical, never deleted.
- **HS-03** — source probes read text with comments blanked first.
- **CM-02** — the commit message was written to a file, not passed inline.
- **MD-03** — role-pinned fan-out goes through the kanban, not a model-less subagent spawn.
- **PG-04** — never bypass what the forge enforces.
- **DOC-01** — a significant change updates the docs that teach it.
- **DOC-02** — system-level changes are recorded in the vault via the `pkm` profile.

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
- is not a monorepo tool and not a CI tool;
- does not manage profile skill libraries;
- writes nothing outside the target repo;
- does not attempt to make the *prose* rules enforceable — it counts them instead.
