# Roles and models

A **profile** is a worker identity. A **role** is what the work needs. Conflating them is how
five documents once gave five different model answers — a role name used as a model name.

goblin-stack keeps them separate and **never names a model**. `MD-01` lints every reusable rule
for a hardcoded model name; `MD-02` reports, but cannot change, whether the review lane and the
code lane resolve to the same family.

## The role vocabulary

`roles.yaml` declares each role's capability and the default **profile** that carries it:

| role | what it needs | default profile | used by |
|---|---|---|---|
| `code` | fast, cheap, mechanical correctness | `coder` | P2, P4, P5, P10 |
| `judgment` | strongest available reasoning and prose | `architect` | P1, P3 (spec half), P6, P8, P9 |
| `review-panel` | **a list** — N independent verdict lanes, each its own lane | `[reviewer, architect]` | P7 at stakes S3+ |
| `synthesis` | merges many outputs into one artifact | `architect` | P11, P12 |
| `investigate` | read-only exploration returning a distilled summary | `researcher` | P1 (read-only half) |
| `judge` | decides whether a process met its own predicate, from a command's output and a pointer it can resolve, never from a report | `judge` (a **single** lane) | P10, P12, P7 at S3+, the terminal handoff gate |

The list-valued panel is the sharpest configuration idea retained here: **one lane runs per list
entry, so the list length sets the lane count.** Lane count is configuration, not code.

A **panel is N opinions; a judge is one decision** — which is why `role-judge` is a role and not a
sentence inside P7 or P12. The judge's contract (what it receives, what it must refuse, how its
verdict is recorded) is `docs/LOOP.md`; the pair of rules that make it real are that a `done`
verdict may only cite a handle the repo can resolve (`JG-01`) and that the judge's lane must be
disjoint from the author's (`JG-02`).

## The model-mapping contract

The machine-specific mapping (`profile → provider/model/effort`) is read at run time from the
file declared as `models_file:` in `.gob/goblin.yaml`. That is **the single documented
install-time machine input**, and goblin-stack **reads it and never writes it**.

Why not ship a copy of the mapping: the mapping file is a live routing source owned and
rewritten by another tool. Adding a foreign key to a file another tool owns is the precedent
for what happens when two tools share a file with unstated ownership. One place to change a
model, and the model layer stays where it belongs.

Resolution:

    bin/goblin-model <role>              # one line per lane: profile provider model effort
    bin/goblin-model --list              # the roles and their capabilities
    bin/goblin-model review-panel        # the panel: one line per lane

`bin/goblin-model` is **checkout-only**. `goblin-install` copies four scripts into a target's
`.gob/bin/` — `goblin-verify`, `goblin-lib.sh`, `goblin-audit` and `goblin-bans` — so an
adopted repo has no `goblin-model` command (`ls .gob/bin/` →
`goblin-audit  goblin-bans  goblin-lib.sh  goblin-verify`). The installed path
for the same resolution is the `resolve_role_models` helper inside `.gob/bin/goblin-verify`,
which is what `MD-02` calls; `bin/goblin-model` exists for a human at a checkout, is covered only
by `bash -n` in `tests/run-tests.sh`, and has no `enforcement.tsv` row because it enforces
nothing — it prints. Naming it here is the alternative R6 §2.2 allows to shipping a row for it.

Absent on this machine, every role resolves to `unknown` and the model-dependent checks report
advisory. Absent is not an error — goblin-stack is portable, and another machine has no such
file. That is the one documented exception to the portability rule, and `PT-01` enforces it:
the path is a config *value* in `.gob/goblin.yaml`, never a literal inside a rule.

## The fan-out rule: role-pinned work goes through the kanban

Measured, from the live tool schemas:

- a bare subagent spawn takes **no** model or provider parameter, so it cannot honour a role —
  it would silently run every lane on one model, which is exactly the review failure the panel
  exists to prevent;
- a board card **does** take a model and a provider, and a review request takes a reviewer
  profile.

Therefore: a panel is N board cards parented to the change, each carrying the resolved
`(provider, model)`, the pinned SHA, the diff, and one focus. `goblin-mode` forbids inventing a
fan-out that a subagent spawn cannot honour, and `MD-03` records that no repo-local file can
observe which tool created a worker — so this rule is stated here and enforced at board level.

## The measured caveat

Today's mapping puts every switchable profile on the **same** model, so `review-panel` resolves
to the same family as `code`, and **`judge` resolves to no lane at all**. `MD-02` therefore reports
the state and is labelled advisory: goblin-stack cannot choose the fleet's models, and a harness
must not fail a repo for a fleet-wide campaign. This is a reported number, not a silent assumption.

The judge lane, measured on this box on 2026-09-25:

    bash bin/goblin-model judge         -> judge unknown unknown unknown        (rc 0)
    bash bin/goblin-model code          -> coder <provider> <model> <effort>
    bash bin/goblin-model review-panel  -> reviewer <...> · architect <...>

`~/projects/fleet-model.yaml` has no `judge:` entry, and `hermes profile list` reports no `judge`
profile. So **`MD-02`'s rule is not satisfiable on this box today through the mapping file**: the
judge and the author would run on one family. A different family exists only as a per-profile
alias held in another profile's own config (a comment in the mapping file names it), and **the
mapping file cannot express an alias** — it maps a profile to a provider/model pair. Making the
constraint real is a **fleet-side** change (add the `judge` profile, add the entry, re-apply),
never a goblin-stack one; `JG-02` therefore gates the *declared lanes* being disjoint and reports
an unresolved judge lane as `ADV` with the one-line remedy rather than failing a repo for the
fleet's routing.

## Budget

`effort` is one word per role, read from the same mapping file. The panel is bounded — lanes
only at S3+ — because parallel lanes cost about N times the tokens, and token usage is the
dominant term in the variance of agent outcomes. No playbook fans out without a named predicate.
