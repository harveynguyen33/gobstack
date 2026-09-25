---
name: goblin-loop
description: Arm, pin, run and close one unattended loop whose exit condition is a command - and stop when it stops making progress.
---

# goblin-loop (the loop contract)

A **loop** is an unattended run whose exit condition is a **command**. One run, one record:
`.goblin/loop/`, committed, so a reader tomorrow can re-derive every decision. An unrecorded loop
is a story.

## 1. Arm it: the predicate comes first

Write the exit condition as **one** shell command in `.goblin/loop/predicate`, and **run it once
before iteration 1**:

    .goblin/loop/predicate       # one command; exits 0 == the loop is finished
    .goblin/loop/predicate.sha256  # its digest, recorded at loop start
    .goblin/loop/first-run       # exit=<n> ts=<ISO8601>, from that first run
    .goblin/loop/budget          # the turn budget this run declares

A **duration is not a finish condition.** Neither is a description of one. The run-once rule is
not ceremony: it is the only way to know the command is runnable *and currently red*, which is
what makes a later green mean anything.

`.goblin/loop/budget` is capped by `loop_max_turns_ceiling` in `.goblin/goblin.yaml` (default
**20**). The number is not invented: 20 is the engine's own default turn budget for a kanban goal
loop, and a ceiling that disagreed with the engine would be a number someone made up.

## 2. Pin it: never relax

The predicate's digest is recorded at loop start (`LP-02`). Changing it mid-loop is **not an
edit** - it is closing this loop and opening another:

    .goblin/loop/closed-<date>/   # the relaxed predicate AND its pin go here, committed
    # then re-record predicate.sha256 with a `previous: <archived digest>` line beside the new one

The chain is what the row checks: a silent relaxation fails, a recorded re-scope costs one line.
Whether the new predicate is *weaker* is not decidable from a digest and is recorded in
`docs/LIMITS.md` #39 rather than claimed.

The pin never updates itself, for the same reason `practice_sha256:` never re-pins itself: a
self-updating pin is the silent edit it exists to catch. The remedy is printed when the row fails
and is never automatic.

## 3. Log every iteration

One row per iteration, appended to `.goblin/loop/decisions.tsv` - the decision-log shape, unchanged
from the template:

    ts · phase · decision · why · evidence · result
    decision = "verdict:<done|blocked|continue|wait>"
    evidence = a pointer that resolves: sha:<hex> | file:<path> | sha256:<hex>
    result   = "predicate:red" | "predicate:green" | "parked" | "stuck"

`evidence` is the thing a judge's verdict rests on. A `verdict:done` row that cites nothing
resolvable is refused by `JG-01`: the verdict may only rest on a handle the repo can re-derive.

## 4. Guard rails - what stops a night being burned

- **No progress stops the loop.** Three consecutive verdict rows with an **unchanged evidence
  pointer** and a result that is not `predicate:green` is a failure (`LP-04`). What it measures
  is a *changed pointer*, a proxy for progress, not progress itself - a loop that edits a file
  each turn to keep the pointer moving is not caught.
- **The check cannot be weakened.** The predicate is pinned by digest (`LP-02`); the budget is
  declared and capped (`LP-03`); and a card's own predicate cannot be edited by its worker at all,
  which is why the file predicate needs the pin and the card predicate does not.
- **A stuck loop writes up and stops.** A run whose last row is not `predicate:green` carries
  `.goblin/loop/stuck.md`: at least three non-blank lines naming the predicate it failed
  (`LP-05`). The exit a worker can actually reach is `kanban_block` - naming the predicate - plus
  the write-up. Thrashing is not an option the record allows.

## 5. The morning audit

Read the rows whose `result` is not `predicate:green`, **in order**, then the last five rows for
context. That is the same discipline as P10's "read the Attention section first": the interesting
rows are the ones that did not reach the goal, and a green summary line is not one of them.

## What this cannot see

- **Whether the predicate was the right one.** Every `LP-` row checks the process; a loop can run
  perfectly against a predicate that measures the wrong thing - and a predicate that was
  **vacuously true from the start** (a `grep -c` against a renamed directory exits 1, passes
  `LP-01` and `LP-02`, and ends green on nothing) is the failure mode the run-once rule exists to
  make visible to a human, not one a row can catch.
- **Whether the recorded `exit=` was measured or typed**, and whether the loop really ran - the
  record proves a date and a code exist, not that a command produced them.
- **Cost.** A turn budget bounds turns, not tokens, and the record prices nothing.
