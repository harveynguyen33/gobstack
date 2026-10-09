---
name: goblin-drift-audit
description: P14: repair a recorded claim that no longer agrees with the artifact, one card per drifting repo.
---

# goblin-drift-audit (P14)

Use when a drift card exists. The drift run compared a recorded
claim against an artifact, disagreed, and filed **one card per drifting repo**. You repair the
disagreement; you do not re-derive it from memory.

1. **Read the record, not your memory.** The card body carries the repo, the check id and the
   detail line the producer computed. Re-run that exact check yourself and confirm it is still
   RED:

       <repo>/.goblin/bin/goblin-verify --only <check-id>

   A drift that is no longer reproducible is a stale card, and closing it with that fact is a
   complete run.
2. **Classify it.** A **real regression** (the artifact changed and the claim did not) | a
   **stale-by-design claim** (the claim is historical, and `PROJECT-PRACTICE` section 1 requires
   it kept, so it gets a dated parenthetical) | **fixture drift** (the recorded value is right
   and the check is wrong).
3. **Repair the right one.** A hash drift after an intended edit of the referenced standard is
   a deliberate `--re-pin`, never a hand-edited hash. A missing installed file is a re-install.
   An absent gate line is a gate run. **Never edit a harness to make a number green** — that is
   the one repair that must never happen from here, and it is the repair an automated actor is
   most likely to reach for.
4. **Prove it.** Re-run the same `--only <check-id>` and show GREEN, and name the command and
   the revision in the completion metadata.

## Write surface

Only the drifting repo named by the card, only the repair the card names — the config, the
ignore file, the pin, or the install. No harness edit, no vault write, no push.

## What this cannot see

Whether the *claim* is the right one to keep. It compares a recorded value with an artifact, so
it cannot detect drift in something nobody recorded: an unwritten assumption, a stale sentence
with no number in it, or a document that was never generated from the artifact. It also cannot
see whether the producer's ceiling stopped a real finding from being filed — that is why a
capped run prints its own line.
