---
name: goblin-verify-author
description: P6: author a project's gate set and harness, then execute it once end to end.
---

# goblin-verify-author (P6)

Use when a project has no live lane, or its gates have drifted from what it actually does.

1. **Read the repo, not the user, for entry points.** The declared gate must be a command the
   repo can actually run. One inferred command is wrong for a repo with no runner, a repo that
   cannot run its own typecheck read-only, and a repo whose runner lives elsewhere — all at
   once.
2. **Write the gate/check set into the harness dir**, in the house harness shape: a
   `failures` counter, an `assert(name, ok, detail)` printer, a non-zero exit on failure, and
   a REPLAY block at the bottom.
3. **Execute it once end to end.** A generated skill that was never executed is a draft, not
   a deliverable.
4. **Add the REPLAY block.** Run each assertion against the pinned pre-change commit and
   require it to be RED there. Pin the pre-change commit, never `HEAD`.

## Verification

- The harness prints `PASS`/`FAIL` per assertion and exits non-zero on any failure.
- The REPLAY shows RED pre-change, with the commit named.
- The gate set is declared in `.goblin/goblin.yaml`, never inferred.

## What this cannot see

Whether an assertion tests the right path rather than merely passing. That needs a human read
of the diff, and `goblin-verify` says so on every run.
