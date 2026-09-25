---
name: goblin-judge
description: role-judge: decide whether a process met its own predicate, from a command's output and a pointer it can resolve - never from a report.
---

# goblin-judge (role-judge)

A **reviewer inspects an artifact**. A **judge decides whether a process met its own predicate**.
Different input, different output, different failure mode, which is why the judge is a role of its
own and not a sentence inside another playbook.

| | reviewer (`role-review-panel`) | judge (`role-judge`) |
|---|---|---|
| input | an artifact: a diff at a SHA, a file, a spec | a **predicate** plus the evidence the predicate produced |
| question | "is this artifact right?" | "did the process meet the condition it declared?" |
| output | findings, categorised (act / consider / noted / dismissed) | a verdict from a **closed enum**, plus the handle it rests on |
| may accept | the artifact itself, at a named revision | only what the verdict can be re-derived from |
| failure mode | misses a defect, or bikesheds | **says yes** - a judge that has never returned "not done" |
| retry | re-review, possibly by another lane | re-run the *same* predicate on the recorded evidence |
| relation to the author | may be a sibling lane | **not the author, and not the author's profile** |

A reviewer's verdict is an opinion attached to a SHA, and a new head voids it. A judge's verdict
is a decision about a **process**, so it is honest only when it is reproducible from a record and
useful only when it can say **no**.

## What it receives

- **A predicate** - one shell command, the loop's declared exit condition. Never a rubric.
- **Evidence** - a pointer the repo can resolve: `sha:<hex>` (a commit), `file:<path>`, or
  `sha256:<hex>` (a file's digest). **Never the author's prose.** The single most common failure
  of a judging loop is that its only input is the worker's own summary; the prompt can demand
  evidence and still be handed a self-report.
- The **budget** and the iteration rows, so it can see what the loop has already tried.

## What it outputs

One verdict, from a closed enum: **`done` | `blocked` | `continue` | wait** - plus, in this repo's
record, the **handle** the verdict rests on. `done` may only cite a handle the repo resolves.
Anything else is a claim.

## What it must refuse

- **A self-report as evidence.** A summary is not a handle. If the only thing offered is prose,
  the verdict is `continue`, not `done`.
- **Grading its own family.** The judge's profile set must be disjoint from the author's
  (`JG-02`). A judge drawn from the same lane as the author is the author.
- **Ruling a goal done to unblock itself.** `blocked` blocks; it is never a completion. A
  judged-done-but-unfinalised loop gets one nudge, then a block - never a completion.

## Where the judge is called

1. **P10 `goblin-overnight`** - the exit predicate.
2. **P12 `goblin-eval`** - the rubric, graded from the transcript chain.
3. **P7 `goblin-pr-gate` at S3+** - the panel's *foreman*: N lane verdicts are opinions, one
   judge turns them into a decision. A panel is N opinions; a judge is one decision.
4. **The terminal handoff gate** - the card is judged *before* it is marked done.
5. **An automation's "did the fix land"** - the repro fails before, passes after, twice.

## How a verdict is recorded

One row per iteration in `.goblin/loop/decisions.tsv` (the decision-log shape pstack already
uses): `ts · phase · decision · why · evidence · result`, where `decision` is `verdict:<one of the
enum>` and `evidence` is a handle. `JG-01` reads it; `JG-03` counts it. On the board, the same
turn also leaves one line in the worker log, which is a UI surface - the committed row is what a
later reader can re-derive from.

## What this cannot see

- Whether a **resolvable handle supports the verdict** it is attached to. `JG-01` proves a commit
  or a file exists; a judge may cite a real commit that has nothing to do with the claim.
- **Which lane actually produced a verdict.** No repo-local file observes which profile ran;
  `JG-02` checks that the *declared* lanes are disjoint, not that a judge ran on one.
- Whether a lane that has always said yes is **bad**, from one repo's rows (`JG-03`, counted).
- Whether the predicate was the **right** one. The judge measures what it was told to measure.
