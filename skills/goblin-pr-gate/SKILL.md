---
name: goblin-pr-gate
description: P7: classify stakes S0-S4, run the gate at the candidate SHA, write a SHA-named verdict.
---

# goblin-pr-gate (P7)

Use for anything that should be reviewed before it lands.

1. **Classify the stakes S0-S4.** The gate is chosen by the *change*, not by the repo.
   - S0: no review. A typo in a comment.
   - S1: self-review. A local edit with no shared surface.
   - S2: one reviewer, gate set run at the candidate SHA.
   - S3: a panel of two or more independent lanes, each its own card and its own model.
   - S4: a panel plus a human decision before landing.
2. **Run the gate set at the candidate SHA and record the numbers.**
3. **Write `reviews/<slug>-<head7>.md`** with `head:`, `base:`, `patch-id:`, `stakes:`,
   `checks-run:`, `lanes:`. The file is the artifact; a board card is only the routing record.
   At S2+, add a `security:` line naming three things the checks cannot tell a reader: the audit
   record's date, the number of matched waivers, and the perf number with its baseline commit.
   It is prose on purpose — a review prompt, not a check (`SC-07`, `PF-01`).
4. **Evaluate the panel rule for S3+.** One lane is not a panel. Lanes go through the kanban
   (see `goblin-mode`), each carrying the resolved provider/model.
5. **Re-check the patch-id before landing.**

## Verification

- `patch-id:` of `base..head` still matches. A new head voids the verdict — a matching commit
  message does not restore it, and a green check from an older SHA is not a substitute.
- The named `head:` exists in `git rev-list --all`.
- For S2+, a check actually ran on that SHA.

## What this cannot see

A required check that self-skips (it reports Success), and a protected branch whose only
admin is the person pushing (it protects nothing).
