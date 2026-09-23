---
name: goblin-tdd-repro
description: P5: write the failing test, confirm it fails for the intended reason, fix, replay RED.
---

# goblin-tdd-repro (P5)

Use when a defect is reproducible and a regression test is cheap.

1. **Write the failing test.**
2. **Confirm it fails for the intended reason** — not a typo, not a missing import. Paste the
   failure and say why it is the right failure.
3. **Smallest production fix.** No drive-by edits.
4. **Revert the fix -> the test MUST fail -> restore.** This is the negative control; without
   it the test is decoration.

## Verification

- The RED-again step is captured, with the command and the failure.
- Prefer no new test over a bad test. A test that asserts an implementation detail pins the
  bug in place.
- If you skip this playbook because a regression test is not cheap, say so explicitly. The
  skip path is never silent.

## What this cannot see

Defects that need a device, a network, or a human to trigger.
