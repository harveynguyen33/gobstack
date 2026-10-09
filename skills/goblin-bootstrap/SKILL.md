---
name: goblin-bootstrap
description: P8: adopt goblin-stack in a repo - install, verify, then the first round.
---

# goblin-bootstrap (P8)

Use when adopting goblin-stack in a repo, or starting one.

1. **`goblin-install --target <dir>`** — the default install is a NEUTRAL harness:
   no agent skills. Vendor the Hermes project tier with `--skills yes` if you want them installed.
2. **`goblin-verify`** — a default install (no agent skills) verifies green:
   `32 passed, 0 failed, 6 advisory, 21 skipped`, exit 0, once `HANDOFF.md` names a commit that
   exists; before that edit the
   scaffold's `0000000` placeholder is `HP-05`'s one expected day-one red (`31 passed, 1 failed`).
   Twenty-one rows skip with a reason, and the reason matters: the four skill rows
   (`SK-01`..`SK-04`) skip on the `playbooks` opt-out a skills-free install records,
   then `HS-02`
   (no pinned pre-change commit yet, so the REPLAY is not provable), `SC-06` (no dependency manifest or lockfile), `PF-01` (no perf baseline measured yet), `BN-01`/`BN-02`/`BN-05` (the ban table is
   installed but this fresh repo has no `.ts` file for a ban's `applies_when` glob, so each reports
   *not applicable*) and `BN-03` with the four electron
   bans `BN-06`..`BN-09` (not in the `bans:` list `[BN-01, BN-02, BN-05]`, so they skip as
   *not enabled* rather than as *unread*),
   `FM-01`/`FM-02`/`VA-01` (no feature map and no declared `verify_doctor:` yet), `RC-01`..`RC-04`
   (no reference corpus declared: `reference_manifest:` ships empty and there is no lab
   `manifests/`). Each is a *not yet*, not a pass.
   The parts
   that only a round can produce (a first review, a real gate) pass *vacuously*, and that list
   is the repo's first-step list, not a defect.
4. **Fix `.gitignore` BEFORE any `git init`.** A credentials file already in the tree is
   committed by the first `git add -A` and is then in history forever.
5. **First HANDOFF, first SPEC, first check script** — in that order, each independently
   useful.
6. **Record the first perf number, and the commit you measured it on.** Run `ratchet.cmd` on a
   pinned commit, write the value into `ratchet.ceiling` and the same number into
   `perf.baseline_value`/`perf.baseline_commit`/`perf.measured`. Until you do, `PF-01` skips with
   "no perf baseline recorded yet" — a green run that proves nothing about the number you ship.

## Verification

- `goblin-verify` exit 0, and the created-file list matches `.gob/installed.json`.
- A repo with no gate declares one and records its first measured numbers.
- `.gitignore` is verified before the first commit, not after.
- The perf baseline exists, and it names a commit that exists (`PF-01`), rather than the ratchet
  ceiling having been raised by hand.

## What this cannot see

Whether the parts you left on match how the project actually ships. Switch a part off with
`--opt-out <part>` when it does not; the installer records it in `disabled:`.
