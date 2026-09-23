---
name: goblin-refactor
description: P4: pin the contract first, reshape, delete the legacy path in the same change.
---

# goblin-refactor (P4)

1. **Pin the contract first** — a characterization test, a snapshot, or an equivalence
   harness that asserts the *current* behaviour. A type check and lint are not a pin: they
   say the code still compiles, not that it still does the same thing.
2. **Shape only, no behaviour.** If the pin changes, this is not a refactor; stop and treat it
   as a feature (P3) or a bug fix (P2).
3. **Delete the legacy path in the same change.** A refactor that leaves the old path behind
   has doubled the surface, not reshaped it.

## Verification

- The pin is a real assertion, run before and after, with both results captured.
- The legacy path is gone: the pin no longer references it and `grep` for it returns nothing.

## What this cannot see

Performance characteristics a functional pin does not cover.
