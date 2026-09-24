# Changelog

One line per released version. `goblin-install --upgrade` prints the delta between the
version recorded in a target's `.goblin/installed.json` and the source `VERSION`.

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
