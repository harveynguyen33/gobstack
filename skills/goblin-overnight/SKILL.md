---
name: goblin-overnight
description: P10: an unattended run over a checkable predicate written before iteration 1.
---

# goblin-overnight (P10)

1. **The exit condition is a checkable predicate written before iteration 1**, and it is a
   command in the card body. Run it once before starting, so you know it is runnable.
2. **It never gets relaxed.** If the predicate turns out to be wrong, stop and write up why;
   do not edit the predicate to fit the result.
3. **An escape hatch.** A genuine dead end writes up why and stops. An unattended run that
   cannot stop is a runaway.
4. **The morning audit reads the `Attention` section first.**

## Verification

- The predicate was run at least once, and its output is in the card.
- `goal_max_turns` is set. An unattended loop without a budget cap is not bounded by anything.
- Every landed change has a P7 verdict row.

## What this cannot see

Whether the predicate was the right one. It measures only what it was told to measure.
