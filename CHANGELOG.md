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
  (`tests/t-automation-silent.sh` — the mutation is the control). Advisory stays **8 of 10**.
- `manifest/enforcement.tsv` is **52 rules** (47 target, 5 source); playbooks are **14**;
  `tests/t-verify-red.sh` carries **49** controls over the 47 target rows.
- A fresh class-A install verifies **`36 passed, 0 failed, 8 advisory, 3 skipped`**, exit 0
  (`HS-02`, `AU-02` and `AU-03` skip with a reason); a fresh class-E install verifies
  `35 passed, 0 failed, 8 advisory, 4 skipped`.

## 0.1.0

- First version. Ships `bin/goblin-install`, `bin/goblin-verify`, `bin/goblin-model`,
  `bin/goblin-lib.sh`; `manifest/enforcement.tsv` (46 rules); 12 playbooks + `goblin-mode`
  + `practice` as Hermes project-local skills; 5 class presets; the templates; and
  `tests/run-tests.sh` with the negative control for every target-scope check class.
