---
name: goblin-bugreporter
description: P13: intake a bug report, reproduce it at a named revision, and hand off a fix card only on proof.
---

# goblin-bugreporter (P13)

Use when a report has arrived as an **event** — a report file under `reports/<slug>/`, a chat
message turned into one, or a webhook payload. You are the reporter. You never fix.

1. **Validate the intake.** `reports/<slug>/report.yaml` must carry the six required keys
   (`repo`, `symptom`, `expected`, `observed`, `repro_steps`, `revision`) and its `dedup_key`.
   Run your project's intake validator rather than eyeballing the file.

   A missing key is a **refusal**, not a guess: create the same card with **no `--assignee`**,
   so the dispatcher buckets it `skipped_unassigned` and no agent acts on it, and name the
   missing field in a comment. The human sees it; nothing is silently lost or invented.
2. **Freeze the coordinates.** `repo` and `revision` are immutable for the run. If `revision`
   is not a commit that resolves (`git rev-parse --verify <rev>^{commit}`), the report is a
   refusal: a repro at a revision nobody can check is not a repro.
3. **Reproduce, in this order.**
   - **R1** — a failing command with its output, at the named revision. The best form.
   - **R2** — the REPLAY form: `git show <revision>:<file>` into a temp dir, run the probe
     against it, require RED. Never a probe that is green on both trees.
   - **R3** — a real-UI drive with captured evidence. Admissible only with a configured
     control adapter, and **never** accepted as harness proof; it is evidence for a human.
4. **Write `reports/<slug>/repro.md`** as a two-row table, not a story: `command:`/`revision:`,
   a `pre:` row that is RED with the pasted output, and the `post:` row. The `pre` row is the
   negative control and it is not optional — a single green run reproduces nothing.
5. **Create the fix card only on `reproduced`.** `--assignee coder`, `--skill goblin-bugfix`,
   `--parent <this card>`, the report's dedup key. The child waits in `todo` until this card is
   `done`, so the gate is a dispatcher-enforced dependency rather than a promise.
6. **Complete your own card with the verdict** in the completion metadata:
   `reproduced` | `could-not-reproduce` | `blocked`. `could-not-reproduce` is a complete,
   successful run — not a failure to work around. `blocked` names the missing capability.

## Write surface

`reports/**`, and the card this lineage owns (`kanban_create` for the fix card). Nothing else:
no `git commit`, no source edit, no edit under the harness dir, no vault write. The harness
asserts the working tree is clean after a run, so a reporter that edited the tree fails its own
gate.

## What this cannot see

Whether the report is *true*. The gate proves the symptom reproduces at a revision; it cannot
prove the reporter's description of intent, severity or cause is right, and it cannot see a fix
that fixed the wrong thing. It cannot see a defect whose only detector is a human eye, anything
needing a device, a network or a running production instance, or a defect that reproduces only
on a revision that no longer builds. In those cases the verdict is `could-not-reproduce`, and
that is the whole answer.
