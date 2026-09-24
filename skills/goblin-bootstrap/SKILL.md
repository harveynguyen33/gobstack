---
name: goblin-bootstrap
description: P8: adopt goblin-stack in a repo - classify, install, verify, then the first round.
---

# goblin-bootstrap (P8)

Use when adopting goblin-stack in a repo, or starting one.

1. **Classify the project A-E.** The class selects which parts are required, optional or off;
   it is not a stringency level.
2. **`goblin-install --target <dir> --class <x>`**
3. **`goblin-verify`** — a fresh class-A install verifies green: `41 passed, 0 failed, 9
   advisory, 7 skipped`, exit 0. Seven rows skip with a reason, and the reason matters: `HS-02`
   (no pinned pre-change commit yet, so the REPLAY is not provable), `AU-02`/`AU-03` (no report
   has been filed in this repo), `SC-06`/`SC-07`/`SC-08` (no dependency manifest, no lockfile, no
   audit record) and `PF-01` (no perf baseline measured yet). Each is a *not yet*, not a pass.
   The class's required parts
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

- `goblin-verify` exit 0, and the created-file list matches `.goblin/installed.json`.
- A repo with no gate declares one and records its first measured numbers.
- `.gitignore` is verified before the first commit, not after.
- The perf baseline exists, and it names a commit that exists (`PF-01`), rather than the ratchet
  ceiling having been raised by hand.

## What this cannot see

Whether the class you chose matches how the project actually ships. Re-classify when it does
not; the installer records the class and `CL-01` checks the parts against it.
