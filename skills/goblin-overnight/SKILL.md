---
name: goblin-overnight
description: P10: an unattended run over a checkable predicate written before iteration 1.
---

# goblin-overnight (P10)

1. **The exit condition is a checkable predicate written before iteration 1**, and it is a
   command — in the card body, or in `.goblin/loop/predicate`. Run it once before starting, so
   you know it is runnable; record that run as `exit=<n> ts=<ISO8601>` in `.goblin/loop/first-run`
   and pin the predicate.
2. **It never gets relaxed.** If the predicate turns out to be wrong, stop and write up why; do
   not edit the predicate to fit the result. Relaxing it is closing this loop and opening
   another, with the old predicate archived under `.goblin/loop/closed-<date>/`.
3. **An escape hatch.** A genuine dead end writes up why and stops: `.goblin/loop/stuck.md`, at
   least three non-blank lines naming the predicate, committed. The exit a worker can actually
   reach is **`kanban_block`** (naming the predicate) — there is no `kanban_edit` tool in a
   worker's toolset. An unattended run that cannot stop is a runaway.
4. **The morning audit reads the `Attention` section first**, then the record's rows whose
   `result` is not `predicate:green`, in order.

## Verification

- The predicate is one command, and its first run is recorded at or before the first log row.
- The predicate is pinned by digest and the pin has not moved.
- `goal_max_turns` is set and the record never exceeds it.
- No three consecutive verdict rows share an evidence pointer without reaching
  `predicate:green`.
- A run whose last row is not `predicate:green` carries a committed write-up naming the
  predicate.
- Every landed change has a P7 verdict row, and any verdict that says `done` cites a handle the
  repo resolves.
- The four record artifacts — `predicate`, `predicate.sha256`, `first-run`, `decisions.tsv` —
  are committed, so tomorrow's reader can re-derive every decision.

## What this cannot see

Whether the predicate was the right one. It measures only what it was told to measure — and a
predicate that was **vacuously true from the start** runs green on nothing, which is why the
run-once rule exists and why a human reads the predicate.
