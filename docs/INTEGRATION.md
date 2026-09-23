# Integration points

## The kanban board

The board is the fleet's fan-out carrier and the only one with a model knob.

- `goblin-overnight` (P10) maps to `goal_mode: true` plus a turn budget. The auxiliary judge
  re-checking the card against its body is the predicate re-check, with a budget cap.
- `goblin-pr-gate` (P7) maps to the board's review request and change-request verbs. The
  verdict's `{head_sha, base_sha, patch_id, lanes, verdict}` lives in the card metadata **and**
  in the committed `reviews/<slug>-<head7>.md`. The card is the routing record; the file is the
  artifact the verifier can test (`PG-01`/`PG-02`/`PG-03`).
- `goblin-sweep` (P11) is one card per project, parented to the sweep card.

**Rule:** role-pinned fan-out goes through the board, never through a bare subagent spawn. See
`docs/ROLES.md` for the measured reason.

## Cron

`goblin-sweep` is the cron-shaped playbook: enumerate by glob, one card per project, one line
back.

Measured constraint to state plainly: a non-interactive surface inherits the skills **trust**
decision and resolves the project root from the job's `workdir`. So **a sweep job whose `workdir`
is not inside a trusted repo loads none of goblin-stack's skills.** The installer prints the
`hermes skills trust` step, and `goblin-verify` cannot check it (it is a fleet-runtime property,
recorded as `MD-03`).

The answer to a lost bootstrap is the same as the answer to compaction: the mode skill is
loadable on demand and `AGENTS.md` names it, so recovery is reading one file rather than
depending on a hook that does not exist.

## Skills, and the precedence that decides which copy wins

goblin-stack **ships** skills and the installer **installs them into the project** at
`.hermes/skills/` — never into a profile.

Measured mechanism: the project tier is the highest precedence (`project → local → external`),
project dirs are treated as repo-owned so autonomous skill maintenance never rewrites them, the
code and its procedure are versioned together, and they need one `hermes skills trust` per repo.

Consequence a future agent must know rather than guess: **for a repo with goblin-stack
installed, the copy in `.hermes/skills/` wins.** Profiles keep only skills that are genuinely
cross-project. A shared library directory remains available in Hermes for a future shared
library, but it is deliberately unused here: it is read-only to maintenance as well, yet it is
*not* repo-versioned, and that is the property that matters.

## The fleet's routing text — what goblin-stack ships and cannot fix

goblin-stack **does not edit the fleet's orchestrator constitution and cannot**: it writes
nothing outside its target repo.

It ships the corrected routing text here, as an escalation, because the measured defect is
high-cost and lives on the fleet side: the rule deciding *whether specialist work happens at
all* is **false where the orchestrator reads it first**. A bare subagent spawn cannot reach the
architect/coder/reviewer profiles; delegation that must land there goes through the board. The
orchestrator's own text says the opposite in its first lines, and the word "kanban" does not
appear there.

The one mechanical thing goblin-stack can do is lint its own artifacts: `MD-03`, plus a source
test that no shipped skill tells a worker to reach another profile with a bare subagent spawn.

## The referenced standard

Referenced and hash-pinned, never moved, never superseded, never vendored. `.goblin/goblin.yaml`
carries `practice:` and `practice_sha256:`; `goblin-verify` compares. The `practice` skill's body
is a pointer and a mandate — read the standard at the configured path before starting work; if
the path is absent, say so and continue with the goblin-stack rules alone.

Three existing consumers of that standard have its path baked in, and goblin-stack is not one of
them: it reads the path from config, so moving the standard is a one-line config change.
