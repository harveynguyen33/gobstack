# Changelog

One line per released version. `goblin-install --upgrade` prints the delta between the
version recorded in a target's `.goblin/installed.json` and the source `VERSION`.

## 0.3.0

- **The ban list (G5).** `manifest/bans.tsv`, `bin/goblin-bans` and `bans/` install as
  `.goblin/manifest/bans.tsv`, `.goblin/bin/goblin-bans` and `.goblin/bans/` — Dune rule 2 made
  a gate: **a ban without a mechanism is a wish.** Four bans ship with a real command each
  (`BN-01` no `any`, `BN-02` no `@ts-ignore`/`@ts-expect-error`, `BN-03` no `fetch` from a
  component, `BN-05` no import across a declared layer boundary), plus `BN-00` (the coherence
  row: every ban has an enforcement row, every row names a replacement, the table is not empty).
  The config gains `bans:` (which bans this project turns on — an unlisted ban SKIPs with a
  reason), `bans_exempt:` (narrow, explicit exceptions) and `layers:` (what `BN-05` reads).
  Class A and C turn on `BN-01 BN-02 BN-05`; E turns on `BN-02`.
- The ban probes are **text probes** (`grep`, no npm, no AST — `docs/CONTRACTS.md`), so G5's
  `BN-04` (the nine named unnecessary-effect patterns) is **not shipped**: it cannot be
  mechanised without a parser, and a ban that cannot go red is worse than advisory. Recorded in
  `docs/LIMITS.md` #27 rather than spent as the last advisory slot. Advisory stays **9 of 10**.
- **V3's four 9/10 blockers closed (W1).** `GT-01` FAILs when a declared gate carries no `cmd:` —
  deleted, blanked or re-indented — instead of silently counting the survivors (G8-3, the third
  condition of G8's own 9/10 sentence); the ban engine and the `bans:` switch are named in the
  installed `AGENTS.md`, so a ban is discoverable while the code is written and not only in the
  post-mortem (V3-1); `bin/goblin-bans` reads a detect's exit 1 as VIOLATED even when stdout is
  empty, so the code matches the exit contract it documents instead of failing open (V3-2); and
  `PF-01` FAILs when `ratchet.ceiling` and `perf.baseline_value` disagree, so a hand-raised
  ceiling no longer passes while printing the contradiction (G8-6b). The verifier's "cannot see"
  footer now names the ban lane's own blind spots (V3-8), and `docs/ROLES.md`'s "exactly two
  scripts" is corrected to the four an install actually writes (V3-6).
- **The feature map, the P6↔P12 wiring, and the skills evidence (G1, W2).**
  `skills/goblin-feature-map/SKILL.md` is the map's contract — the README index, the four-H2 entry
  contract, the rot table, the upkeep pass — and three **declared** config keys drive it:
  `feature_map:` (the map's README; **empty means both FM rows SKIP with that reason**, so a fresh
  install is not born RED), `source_root:` and `verify_doctor:`. Three new rows: `FM-01` (every
  feature file indexed and linked, `feature:` equal to the filename stem, at least one
  `entry_paths:`, the four H2s in order), `FM-02` (every declared entry path still resolves under
  `source_root:` and none changed after its `verified:` date — a tripwire, never a proof) and
  `VA-01` (the declared doctor exits 0, the executable half of P6's "never executed is a draft").
  `P6` gains step 5 (seed the map) and step 6 (hand the generated skill to `P12`: `verified:` does
  not advance until an eval record exists); `P12` gains the record format (`evals/<slug>/`), the
  eleven-token ban, the cheap-checks-first ladder, the merge rule and the pass condition. The eval
  **runner is not shipped** and no row reads a lane (`docs/LIMITS.md` #31). `docs/LIMITS.md` #15 is
  corrected: the controlled evidence now exists — SkillsBench 1.1 measures curated Skills at
  **+16.6 points (33.9% → 50.5%, 18 model–harness configurations, 87 tasks)**, and its
  **self-generated condition put all three tested configurations BELOW their no-Skills baseline**
  (`docs/RISKS.md` K15) — a warning about this repo's own agent-authored output, not someone
  else's.
- **The judge role and the loop contract (G2, W3).** `role-judge` in `roles.yaml` — a capability,
  never a model — plus `skills/goblin-judge` (what a judge is, and what it must refuse) and
  `skills/goblin-loop` (the record it leaves). `docs/LOOP.md` is the contract **and** the measured
  reading of Hermes's own `goal_mode`: the judge is called as `judge_goal(goal_text,
  last_response)`, with **no contract, no subgoals and no quality gates**
  (`hermes_cli/goals.py:1660`); it sees the card's goal (2000 chars) and the worker's own most
  recent response (4000) (`:38`, `:901-905`); and the loop has **no progress detector at all** —
  its whole state is `last_response`, `turns_used`, `nudged_to_finalize` (`:1634-1636`). Eight new
  rows. `JG-01`: a `done` verdict may only cite a **handle the repo can resolve** (`sha:` a commit
  in `git rev-list --all`, `file:` a path under the root, `sha256:` a file under `.goblin/loop/`) —
  a `cmd:` token resolves **nothing**, because the command's output is not in the record.
  `JG-02`: the declared judge lane must be **disjoint** from the author's — a FAIL, not a report;
  an unresolved lane is an `ADV` with a one-line remedy, because a repo cannot choose the fleet's
  routing. `JG-03`: a judge lane with no non-`done` verdict is escalated — **counted, never gated**,
  and the advisory slot W2 left free for G2. `LP-01`..`LP-05`: one predicate command, run and
  recorded (`exit=<n> ts=<ISO8601>`) **before iteration 1**; pinned by digest and never relaxed;
  a budget under the new `loop_max_turns_ceiling` (default **20** — the engine's own
  `DEFAULT_MAX_TURNS`, so the two numbers agree); no three consecutive rows on one evidence
  pointer without reaching `predicate:green`; and a `.goblin/loop/stuck.md` naming the predicate
  when the loop ends red. `templates/loop/` ships a copy-ready predicate and record header, and
  **nothing installs them**: a fresh install must not be born with a loop record. `P10`'s role is
  now `code + judge`, `P7` gains the S3+ foreman (`role-judge`, one decision from N lane verdicts),
  and `docs/INTEGRATION.md`'s claim that the auxiliary judge "is the predicate re-check" is
  corrected in place with the measured calls. `docs/LIMITS.md` #32 and #33 and `docs/RISKS.md` K17
  record what the lane cannot see.
- `manifest/enforcement.tsv` is **78 rules** (73 target, 5 source); the advisory count is **10 of
  ceiling 10 — full**, so the next advisory row must raise the ceiling in the same change;
  `tests/t-verify-red.sh` carries **93** controls and **14** `expect_green` over the 70 target rows
  that carry an executable rule. (Superseded 2026-09-25: this line read 70 rules / 65 target /
  9 advisory / 80 controls / 7 green before G2's eight rows landed.)
- A fresh class-A install verifies **`42 passed, 0 failed, 11 advisory, 20 skipped`**, exit 0
  (twenty rows skip with a reason: `HS-02`, `AU-02`, `AU-03`, `SC-06`, `SC-07`, `SC-08`, `PF-01`,
  `BN-01`/`BN-02`/`BN-03`/`BN-05` on a repo with no `src/`, `FM-01`/`FM-02`/`VA-01` with no map
  and no doctor declared, and `JG-01` + `LP-01`..`LP-05` with no `.goblin/loop/` record). A fresh
  class-B install (`bans: []`) verifies `37 passed, 0 failed, 10 advisory, 26 skipped`; class-C
  verifies `42 passed, 0 failed, 11 advisory, 20 skipped`; class-E (`bans: [BN-02]`) verifies
  `41 passed, 0 failed, 11 advisory, 21 skipped`; class-A with `--skills no` verifies
  `38 passed, 0 failed, 11 advisory, 24 skipped`. All measured on fresh installs, committed with no
  hand edit. (Superseded 2026-09-25: these lines read 42/0/9/14, 37/0/8/20, 42/0/9/14, 41/0/9/15
  and 38/0/9/18 before G2's eight rows landed.)

## 0.2.0

- **Automation agents (G3).** `P13 goblin-bugreporter` and `P14 goblin-drift-audit`, plus the
  producer half in `automations/` — `drift-audit.sh` (deterministic, network-free, silent when
  clean, with a kill switch and a run ceiling) and `bugreporter-intake.sh` (the intake gate: a
  missing key is a refusal card with **no assignee**, so it is structurally un-spawnable). The
  files install to `.goblin/automations/`; the fleet steps are printed by `goblin-install` and
  argued in `automations/README.md`. Six new rules: `AU-01`, `AU-02`, `AU-03`, `AU-04`,
  `SK-04` ("every shipped skill says what it cannot see") and the source row `PR-05`
  (`tests/t-automation-silent.sh` — the mutation is the control). Advisory was **8 of 10** after
  G3 and is **9 of 10** once `SC-09` lands with G4.
- **Guard rails (G4).** `SC-01`..`SC-09` and `PF-01`: secrets and the config surface, input
  boundaries and dependencies, and the performance lane. The perf budget stays `GT-04`/`GT-05`
  (no second mechanism): the class-A preset's metric is now `client_js_bytes` and the TODO count
  moved into a `todo_ceiling` gate. `bin/goblin-audit` installs to `.goblin/bin/` and is the ONE
  tool allowed to touch the network - run deliberately, it writes the record `SC-07` reads
  offline, and it refuses (exit 5) to write an empty record rather than let "nothing parsed" read
  as "clean". A class declares its security surface and perf baseline in `security:` / `perf:`;
  the guard rails are argued in `docs/GUARDRAILS.md`, and `tests/t-audit.sh` exercises the whole
  producer offline against a canned npm-audit report.
- `manifest/enforcement.tsv` is **62 rules** (57 target, 5 source); playbooks are **14**;
  `tests/t-verify-red.sh` carries **60** controls over the 57 target rows.
- A fresh class-A install verifies **`41 passed, 0 failed, 9 advisory, 7 skipped`**, exit 0
  (seven rows skip with a reason: `HS-02`, `AU-02`, `AU-03`, `SC-06`, `SC-07`, `SC-08`,
  `PF-01`); a fresh class-E install verifies `40 passed, 0 failed, 9 advisory, 8 skipped`.
  Advisory is **9 of ceiling 10**.

## 0.1.0

- First version. Ships `bin/goblin-install`, `bin/goblin-verify`, `bin/goblin-model`,
  `bin/goblin-lib.sh`; `manifest/enforcement.tsv` (46 rules); 12 playbooks + `goblin-mode`
  + `practice` as Hermes project-local skills; 5 class presets; the templates; and
  `tests/run-tests.sh` with the negative control for every target-scope check class.
