# The loop contract — the judge, and the loop that has one

`P10 goblin-overnight` and kanban `goal_mode` both describe an unattended run. One gap joins them:
**the loop has a judge, and the judge has no contract.** This file is the contract, and it is the
prose half of the eight rows `JG-01`..`JG-03` and `LP-01`..`LP-05` mechanise.

## 1. A reviewer inspects an artifact; a judge decides whether a *process* met its own predicate

| | reviewer (`role-review-panel`) | judge (`role-judge`) |
|---|---|---|
| input | an artifact — a diff at a SHA, a file, a spec | a **predicate** + the evidence it produced |
| question | "is this artifact right?" | "did the process meet the condition it declared?" |
| output | findings, categorised | a verdict from a **closed enum**, plus the handle it rests on |
| may accept | the artifact itself, at a named revision | only what the verdict can be re-derived from |
| failure mode | misses a defect, or bikesheds | **says yes** — a judge that has never returned "not done" |
| retry | re-review, possibly by another lane | re-run the *same* predicate on the recorded evidence |
| relation to the author | may be a sibling lane | **not the author, and not the author's profile** |

A panel is **N opinions**; a judge is **one decision**. That is why the judge is a role
(`role-judge` in `roles.yaml`) and not a sentence inside P7 or P12.

## 2. What Hermes actually does today — read, not assumed

Every claim below was read in this box's Hermes tree (`/home/harvey/.hermes/hermes-agent/`) on
2026-09-25. Anything not read there is marked `[inferred]`.

| mechanism | measured behaviour | where it was read |
|---|---|---|
| the judge call | an **auxiliary LLM call**, `temperature=0`, max_tokens 4096, timeout 30 s, routed by `auxiliary.goal_judge.*`. The function also accepts `contract=`, `subgoals=` and `background_processes=` | `hermes_cli/goals.py:31-38`, `:858-863`, `:870-935` |
| **what the judge sees** | the goal (truncated to 2000 chars) and **the agent's own most recent response** (truncated to 4000) | `hermes_cli/goals.py:39`, `:904-905` |
| the verdict enum | `done \| blocked \| continue \| wait`, plus `skipped` for an empty goal; the legacy `{"done": bool}` shape is still accepted | `hermes_cli/goals.py:773-800`, `:888` |
| quality gates | deterministic shell commands that must pass before the judge may say `done`; a failed gate **short-circuits judging** and its bounded output (3000 chars) becomes the continuation prompt. 300 s timeout, 3 retries | `hermes_cli/goals.py:50-54`, `:60`, `:1279-1324` |
| fail-open | an unparseable or unreachable judge → `continue`. The constants for an auto-pause exist (3 consecutive parse failures, 5 consecutive transport failures) but belong to the interactive goal loop: **the kanban loop binds `_parse_failed` and `_transport_failed` and discards both** | `hermes_cli/goals.py:45`, `:48` (constants), `:923-930` (fall-through), `:1662` (discarded) |
| budget | `DEFAULT_MAX_TURNS = 20`; the kanban loop **starts `turns_used` at 1** and checks the budget **before** spending another turn; exhaustion blocks with outcome `blocked_budget` | `hermes_cli/goals.py:31`, `:1632-1634` (the default and the clamp), `:1637` (`turns_used = 1`), `:1689-1696` (the check and the block) |
| terminators | the worker's own terminal calls stop the loop (`kanban_complete`, `kanban_block`, review hand-off) | `hermes_cli/goals.py:1586-1592` |
| `wait` in a kanban loop | **downgraded to `continue`** — a worker finishes with kanban tools, not by parking | `hermes_cli/goals.py:1666-1667` |
| **what the kanban loop passes the judge** | `judge_goal(goal_text, last_response)` — **two positional arguments only: no contract, no subgoals, no gates** (the function can take all three; this call site passes none) | `hermes_cli/goals.py:1662` |
| a judged-done worker that never finalises | one finalize nudge, then a **block**, never a completion | `hermes_cli/goals.py:1676-1685` |
| the terminal handoff gate | `kanban_complete` and `kanban_request_review` are judged on the **supplied summary text**; a broken judge **allows** the handoff; the gate is skipped entirely when no auxiliary client resolves | `tools/kanban_tools.py:414-424`, `:447-477`, `:654-680`, `:783-808` |
| **progress detection** | **none.** The loop's whole state is `last_response`, `turns_used`, `nudged_to_finalize` | `hermes_cli/goals.py:1636-1638` |
| predicate pinning | **none** — `goal_text` is read once from the card, and a worker cannot edit its own card: `grep -rn kanban_edit tools/` finds **one** hit, the gate's own message text, and no tool definition | `hermes_cli/goals.py:1595-1601`, `tools/kanban_tools.py:432` |

**The three sentences that matter.**

1. **The stop condition is a self-report.** The judge is handed the agent's own prose and asked
   whether it is enough. The prompt demands concrete evidence; the judge cannot go and get it. So
   *"a judge given prose instead of evidence"* is the default on every turn, not an edge case.
2. **The one mechanical path exists and is not connected.** Quality gates would make this a real
   loop, and the kanban path passes neither gates nor contract (`hermes_cli/goals.py:1662`).
3. **No progress detector, no predicate pin — the budget is the only backstop.**

`[inferred]` the goal-judge verdicts on this box are any *good*: this card ran no `goal_mode`
card, and nothing in the repo can observe which lane graded what.

## 3. The record

One unattended run, one committed record. `templates/loop/` ships a copy-ready `predicate` and
`decisions.tsv` header; nothing installs them, because a fresh install must not be born with a
loop record — every `LP-` row skips until a loop has actually run here.

    .goblin/loop/predicate          one command; exits 0 == the loop is finished
    .goblin/loop/predicate.sha256   its digest, recorded at loop start (the pin); after a close,
                                    the chain follows on `previous: <digest>` lines
    .goblin/loop/first-run          exit=<n> ts=<ISO8601>, run BEFORE iteration 1
    .goblin/loop/budget             the turn budget this run declares
    .goblin/loop/decisions.tsv      ts · phase · decision · why · evidence · result
    .goblin/loop/stuck.md           the write-up when the run ended without predicate:green
    .goblin/loop/closed-<date>/     a relaxed predicate AND the pin it was closed under, archived

An iteration row's `evidence` is a **pointer that resolves**: `sha:<hex>` (a commit in
`git rev-list --all`), `file:<path>` (a path under the root), `sha256:<hex>` (the digest of a file
under `.goblin/loop/`). A `cmd:` token resolves **nothing** on purpose: the command ran, its
output is not in the record, and a verdict resting on it is the self-report `JG-01` refuses.

## 4. The five rules

1. **The exit predicate is a command, written before iteration 1, and run at least once before
   it.** Not a duration, not a description. The *run once before* half is not ceremony: it is the
   only way to know the command is runnable **and currently red**, which is what makes a later
   green mean anything (`LP-01`).
2. **Never relax.** The predicate's digest is recorded at loop start (`LP-02`). Changing it
   mid-loop is not an edit; it is closing this loop and opening another, with the old predicate
   **and the pin it was closed under** archived under `.goblin/loop/closed-<date>/` and committed,
   and the new `predicate.sha256` naming the archived digest on a `previous: <digest>` line. That
   chain is what `LP-02` checks: not that the new bar is as strong — no digest can say that
   (`docs/LIMITS.md` #39) — but that the supersession is **recorded**, so a silent relaxation is a
   FAIL rather than an indistinguishable re-scope. The precedent is already in the repo:
   `practice_sha256:` + `IN-02` and the deliberate `--re-pin`, which never re-pins automatically
   "because a self-updating pin would be the silent edit it exists to catch"
   (`docs/CONTRACTS.md`).
3. **The escape hatch is a write-up, not a silence.** A run whose last row's `result` is not
   `predicate:green` carries `.goblin/loop/stuck.md` — at least three non-blank lines naming the
   predicate (`LP-05`). Wording matters: the exits a worker can actually reach are `kanban_block`
   and `kanban_complete`; **there is no `kanban_edit` tool** in the worker toolset, so the remedy
   the rejection message names is not one a worker holds. `kanban_block` names the predicate, and
   the write-up makes the stop visible.
4. **The budget.** `goal_max_turns` on the card, mirrored into the record, capped by
   `loop_max_turns_ceiling` in `.goblin/goblin.yaml`, default **20** — the value measured at
   `hermes_cli/goals.py:31`. A ceiling that does not match the engine's own default is a number
   someone made up (`LP-03`).
5. **The morning audit reads the rows that did not reach the goal, in order**, then the last five
   for context — `P10` step 4's "read the `Attention` section first" applied to the record.

## 5. The guard rails — what stops a night being burned

**What stops a loop making no progress?** *Nothing in Hermes*: `run_kanban_goal_loop` has no
notion of progress (`hermes_cli/goals.py:1636-1638`), so a loop returning `continue` with the same
reason nineteen times spends nineteen turns and then blocks. The mechanism here is `LP-04`: three
consecutive verdict rows with an **unchanged evidence pointer** and a result that is not
`predicate:green` is a FAIL naming the row numbers. **What it measures is a changed pointer, not
progress** — a loop that edits a file each turn to keep the pointer moving is not caught, which is
why `LP-05` and the budget sit behind it.

**What stops a loop "succeeding" by weakening its own check?** *Partly, and partly by accident.*
A **card** predicate is already protected: a worker cannot mutate its own card
(`tools/kanban_tools.py:211-229`) and no `kanban_edit` **tool** ships - the CLI verb
`hermes kanban edit` exists, and a headless worker cannot call it. A predicate in a **file** has no
such protection, so `LP-02`'s pin is the mechanism. The wider hazard is unaddressed and stated:
the judge is a language model grading prose (`hermes_cli/goals.py:904-905`), and *"the agent optimises
exactly the gate signal, including by faking it"* is measured rather than hypothetical. **The
counter-measure is not a better prompt.** It is that a `done` verdict may only cite a handle the
repo can resolve and re-check tomorrow (`JG-01`).

**What does a genuinely stuck loop do?** Today: it burns the budget and **blocks for review**,
carrying only the last judge reason, which came from a self-report (`hermes_cli/goals.py:1692-1695`).
Approved shape: write `.goblin/loop/stuck.md`, commit it, `kanban_block` naming the predicate.
`LP-05` makes the write-up mandatory and therefore visible; **nothing can make it true.**

## 6. The judge's failure modes, and what is mechanical

| failure mode | counter-measure | mechanically enforceable? |
|---|---|---|
| **a judge that always says yes** | count the lane's verdicts; escalate a lane with no non-`done` verdict over N; **baseline it against one known-red control verdict per wave** | **No.** A repo sees only its own rows, and a lane that has judged twice cannot be called always-yes. → `JG-03`, `advisory`, counted |
| **a judge grading its own profile** | the judge's profile set must be **disjoint** from the author's (`JG-02`, FAIL) | **Partly.** Disjoint *profiles* is fully checkable; disjoint *families* needs the mapping file and is a report (`MD-02`), and *which lane ran* is unobservable from a repo (`MD-03`) |
| **a judge given prose instead of evidence** | `done` may only cite a **typed handle** the repo can resolve (`JG-01`) | **Yes**, on the record — it still cannot see whether the handle *supports* the verdict |
| **a loop making no progress** | three consecutive identical pointers with a non-terminal result → FAIL (`LP-04`) | **Yes** on the record; a changed pointer is a proxy, not progress |
| **a loop weakening its check** | the predicate is pinned by digest at loop start (`LP-02`); relaxing it is a committed archive-and-restart, and the new pin must name the archived digest on a `previous:` line, so a SILENT relaxation is a FAIL | **Partly**: the chain is checked; whether the new predicate is weaker is not (docs/LIMITS.md #39). A card predicate is protected by the board itself |
| **a loop that thrashes** | budget ceiling + `LP-04` + the mandatory write-up (`LP-03`, `LP-04`, `LP-05`) | **Yes** |

**The JG-03 policy, stated so it is not mistaken for a check.** `JG-03` is a **counted** row, never
a gate: once per wave, run the judge against a **known-red control** — a predicate the loop
deliberately cannot satisfy — and record the verdict in this file. A judge that returns `done` on a
known-red control is a judge that always says yes, and that fact is invisible to every row here.

## 7. What this contract cannot see

1. **Whether a resolvable handle supports the verdict it is attached to.** `JG-01` proves a commit
   or a file exists; it cannot read it. A judge may cite a real commit that has nothing to do with
   the claim.
2. **Which lane actually produced a verdict.** No repo file observes which profile ran. `JG-02`
   checks that the *declared* lanes are disjoint, not that a judge ran on one — the blindness
   `MD-03` records.
3. **Whether the predicate was the right one.** P10's own skill says it first: *"It measures only
   what it was told to measure."* Every `LP-` row checks the process.
4. **Whether `first-run`'s `exit=` was measured or typed** — `HP-03`'s defect, one artifact over:
   the record proves a date and a code exist, not that a command produced them.
5. **A predicate that was vacuously true from the start.** A `grep -c` against a renamed directory
   exits 1, passes `LP-01` ("it ran") and `LP-02` (nothing edited), and the loop ends green on
   nothing. The only defences are the run-once rule and a human reading the predicate.
6. **Cost.** No row prices a loop. `DEFAULT_MAX_TURNS = 20` bounds turns, not tokens, and the
   auxiliary judge call per turn is a cost the record does not contain.
7. **A worker-created loop.** The board's worker toolset exposes `goal_mode` / `goal_max_turns` on
   `kanban_create`, so loops can spawn loops; `loop_max_turns_ceiling` bounds one loop's turns and
   nothing bounds their number. An aggregate board budget is fleet work, not repo work.
8. **Whether a lane that never says no is a bad lane** — see the `JG-03` policy in §6.
