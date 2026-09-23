---
name: goblin-investigation
description: P1: answer a read-only question with cited evidence, or mark it unverified.
---

# goblin-investigation (P1)

For a read-only question, or "why is this happening". **No code changes.**

1. **Name the question as a falsifiable claim.** "The board writes to the wrong path" is a
   claim; "the board is broken" is not.
2. **Read the code paths and cite `file:line`.** A claim with no anchor is a rumour.
3. **If the answer is observable by running something, run it instead of asking.** A question
   whose answer is a fact a command can print is not the human's to answer. This is the whole
   classifier: *observable by running* -> run it; *a preference or a decision* -> ask.
4. **Write the answer with its evidence.** Command and real output, or `file:line`.

## Verification

- Every claim carries a `file:line` or a command plus its output.
- No file is modified. Prove it: `git status --short` is unchanged from before the pass.
- Anything you could not source is marked `[unverified]`. There is no third state.

## What this cannot see

Intent, and anything outside the repo — a service that is down, a decision not written down.
