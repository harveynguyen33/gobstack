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

The list-valued panel is the sharpest configuration idea retained here: **one lane runs per list
entry, so the list length sets the lane count.** Lane count is configuration, not code.

## The model-mapping contract

The machine-specific mapping (`profile → provider/model/effort`) is read at run time from the
file declared as `models_file:` in `.goblin/goblin.yaml`. That is **the single documented
install-time machine input**, and goblin-stack **reads it and never writes it**.

Why not ship a copy of the mapping: the mapping file is a live routing source owned and
rewritten by another tool. Adding a foreign key to a file another tool owns is the precedent
for what happens when two tools share a file with unstated ownership. One place to change a
model, and the model layer stays where it belongs.

Resolution:

    bin/goblin-model <role>              # one line per lane: profile provider model effort
    bin/goblin-model --list              # the roles and their capabilities
    bin/goblin-model review-panel        # the panel: one line per lane

Absent on this machine, every role resolves to `unknown` and the model-dependent checks report
advisory. Absent is not an error — goblin-stack is portable, and another machine has no such
file. That is the one documented exception to the portability rule, and `PT-01` enforces it:
the path is a config *value* in `.goblin/goblin.yaml`, never a literal inside a rule.

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
to the same family as `code`. `MD-02` therefore reports the state and is labelled advisory:
goblin-stack cannot choose the fleet's models, and a harness must not fail a repo for a
fleet-wide campaign. This is a reported number, not a silent assumption.

## Budget

`effort` is one word per role, read from the same mapping file. The panel is bounded — lanes
only at S3+ — because parallel lanes cost about N times the tokens, and token usage is the
dominant term in the variance of agent outcomes. No playbook fans out without a named predicate.
