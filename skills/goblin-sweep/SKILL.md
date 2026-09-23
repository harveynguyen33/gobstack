---
name: goblin-sweep
description: P11: the same change or question across projects - one card each, one line back.
---

# goblin-sweep (P11)

1. **Enumerate targets with a shell glob, not a memory.** A list typed from memory is a list
   that is already wrong.
2. **Classify each target A-E.** An `archive` project is **skipped, not processed** — say so.
3. **One card per project, parented to the sweep card.**
4. **Collect one line per project**: what changed / what was refused / what is unfindable.

## Verification

- The per-project line carries the command it ran.
- The sweep report states its own coverage: `n of m projects`, and names the ones it skipped.
- A refusal is a result. Report it as one.

## What this cannot see

Projects that exist but were not enumerated by the glob — a sweep can only report on the set
it looked at, which is why it must state that set.
