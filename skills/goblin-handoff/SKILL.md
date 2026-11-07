---
name: goblin-handoff
description: P9: write or pick up a HANDOFF - state, gates, next steps, and what is NOT verified.
---

# goblin-handoff (P9)

Use when ending a session, or picking up another's.

1. **Commit uncommitted edits** as one internally consistent `wip:` commit. A run that dies
   must lose nothing.
2. **Write intent / verified state / next steps / what is NOT verified.** The last one is the
   most important and the most often skipped.
3. **Stale sentences get a dated parenthetical, never deletion.** Deleting erases the fact
   that it was once believed true; leaving it undated re-arms the trap.
4. **On pickup, verify inherited claims against the artifact.** A passing prior self-report is
   not the proof. Re-run the gate, check the file exists, grep the vault.
5. **Every next-steps item is one of three shapes — open is not one of them.** Owned with a date
   (`— owner: <name>, since <date>`), done with evidence, or cancelled with a date and the
   decision verbatim. A bare intention bullet is work that will never be done, and every status
   report after it inherits the lie (`HP-06`).

## Verification

- Every gate number in the HANDOFF carries `measured <date>`.
- The named HEAD matches `git rev-parse --short HEAD`.
- The NOT-verified section is non-empty, or explicitly says "nothing outstanding".
- Every next-steps bullet carries a date and one of owner / done / cancelled.

## What this cannot see

Whether the prose is true. A HANDOFF's own top blocks drift out of sync with its body — grep
the whole file for a status before planning from the first hit.
