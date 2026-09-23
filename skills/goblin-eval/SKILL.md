---
name: goblin-eval
description: P12: measure whether a skill or prompt change did anything, blinded.
---

# goblin-eval (P12)

Use when a skill or prompt changed and you want to know if it did anything. This is the only
mechanism goblin-stack has for that question, and it has never been run — treat its output as
a first measurement, not a verdict.

1. **Candidate and control run in sanitized directories.** Same task, same starting tree, one
   difference.
2. **No `eval`, `test`, `judge` or `rubric` token anywhere the candidate can see.** A
   candidate that knows it is being graded changes behaviour.
3. **Grade the chain from the transcript** — which files it actually opened, which commands it
   ran — never the self-report.
4. **The judge runs on a different model family.** A model grading its own family's output is
   grading itself.

## Verification

- The judge's verdict is reproducible from the transcripts alone.
- Candidates never learn that other candidates exist.

## What this cannot see

Small effects. With a handful of runs, a difference smaller than the run-to-run variance is
noise, and no amount of prose makes it a signal.
