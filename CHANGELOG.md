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
- `manifest/enforcement.tsv` is **67 rules** (62 target, 5 source); `tests/t-verify-red.sh`
  carries **73** controls (+5 `expect_green`) over the 62 target rows.
- A fresh class-A install verifies **`42 passed, 0 failed, 9 advisory, 11 skipped`**, exit 0
  (eleven rows skip with a reason: `HS-02`, `AU-02`, `AU-03`, `SC-06`, `SC-07`, `SC-08`,
  `PF-01`, and `BN-01`/`BN-02`/`BN-03`/`BN-05` on a repo with no `src/`). A fresh class-B install
  (`bans: []`) verifies `37 passed, 0 failed, 8 advisory, 17 skipped` — the four BN rows SKIP with
  "not enabled in `bans:`"; class-C verifies `42 passed, 0 failed, 9 advisory, 11 skipped`; class-E
  (`bans: [BN-02]`) verifies `41 passed, 0 failed, 9 advisory, 12 skipped`. All measured on fresh
  installs, committed with no hand edit.

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
