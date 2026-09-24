---
name: goblin-mode
description: Route a request to one goblin-stack playbook, seed the todos, and keep the two reply habits.
---

# goblin-mode

The router. Load this first in any repo that has goblin-stack installed. It turns a request
into exactly one playbook, and it refuses to invent machinery that does not exist here.

## The index — one request, one playbook

| request | playbook | skill |
|---|---|---|
| a read-only question, or "why is this happening" | P1 | `goblin-investigation` |
| a reported defect | P2 | `goblin-bugfix` |
| new behaviour | P3 | `goblin-feature` |
| a behaviour-preserving reshape | P4 | `goblin-refactor` |
| a defect where a regression test is cheap | P5 | `goblin-tdd-repro` |
| a project has no live lane, or its gates drift | P6 | `goblin-verify-author` |
| anything that should be reviewed before it lands | P7 | `goblin-pr-gate` |
| adopting goblin-stack in a repo, or starting one | P8 | `goblin-bootstrap` |
| ending a session, or picking up another's | P9 | `goblin-handoff` |
| an unattended run over a predicate | P10 | `goblin-overnight` |
| the same change or question across projects | P11 | `goblin-sweep` |
| a skill or prompt changed, and you want to know if it did anything | P12 | `goblin-eval` |
| an event delivered a report (a bug report, a chat message, a webhook) | P13 | `goblin-bugreporter` |
| a recorded claim disagrees with the artifact (drift) | P14 | `goblin-drift-audit` |

If a request matches none of these, say so and ask — do not stretch a playbook to fit.

## The two reply habits

1. **Lead with the answer, evidence after.** The first line is the outcome; the command and
   its output follow. Never open with what you are about to do.
2. **Say what is NOT verified.** Every report ends with the surface the checks did not reach.
   A claim you cannot source is marked `[unverified]`; it is never quietly implied.

## Todo seeding

Before the first tool call of a non-trivial task, seed the todo list from the playbook's
required steps — one todo per step, in order, with the verification step last. A todo is
closed only by the measurement it names, never by "looks right". If a step turns out to be
unnecessary, close it with the reason rather than deleting it: the list is the record.

## The read-vs-write fan-out rule

The axis that decides fan-out is **read versus write**, not difficulty.

- **Read-only work** (P1, P12, a P11 sweep) may fan out: independent readers cannot corrupt
  each other, and the cost is bounded by the number of targets.
- **Write work** (P2, P3, P4, P5) does not fan out by default. Parallel writers to one tree
  cost about N times the tokens and produce conflicts a single careful pass would not.

**Role-pinned fan-out goes through the kanban.** A bare subagent spawn has no model or
provider parameter, so it cannot honour a role: it would silently run every lane on one
model, which is exactly the review failure the panel exists to prevent. Use a board card per
lane — each carrying the resolved provider/model, the pinned SHA, the diff and one focus —
never a subagent spawn. `docs/ROLES.md` states this as a rule.

## What this cannot see

Whether the request was the right one to make. It routes; it does not judge intent.
