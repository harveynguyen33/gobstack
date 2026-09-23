# The flow catalogue - 12 playbooks

`manifest/playbooks.tsv` is the machine-readable form; this is the prose. Every playbook has
the same six fields, and `verification` is always a *measurable* step that also names what it
cannot see. The router that picks one is the `goblin-mode` skill.

## P1 - `goblin-investigation`

- **When:** a read-only question, or "why is this happening"
- **Steps:** 1 name the question as a falsifiable claim<br>- 2 read the code paths, cite file:line<br>- 3 if the answer is observable by running something, run it instead of asking<br>- 4 write the answer with its evidence
- **Verification:** every claim carries a file:line or a command+output; no code changes; a claim you cannot source is marked [unverified]
- **Profiles:** any
- **Role:** investigate

## P2 - `goblin-bugfix`

- **When:** a reported defect
- **Steps:** 1 reproduce it yourself<br>- 2 state the root cause with a measurement, never 'should be'<br>- 3 fix the root, not the symptom<br>- 4 prove absence on the same surface, with a negative control
- **Verification:** the repro fails before and passes after, on the same command; unit tests show branch behaviour, not bug absence
- **Profiles:** coder
- **Role:** code

## P3 - `goblin-feature`

- **When:** new behaviour
- **Steps:** 1 SPEC first (measured root cause + AC: list)<br>- 2 name the data shape before the code<br>- 3 land it in units that each end checkable<br>- 4 write the SHA it landed at into the review note
- **Verification:** every AC: item has a checkable assertion; the gate line is measured; the SHA is named
- **Profiles:** architect -> coder
- **Role:** judgment -> code

## P4 - `goblin-refactor`

- **When:** a behaviour-preserving reshape
- **Steps:** 1 pin the contract first (characterization test / snapshot / equivalence harness)<br>- 2 shape only, no behaviour<br>- 3 delete the legacy path in the same change
- **Verification:** the pin is a real assertion run before and after; a type check and lint are not a pin
- **Profiles:** coder
- **Role:** code

## P5 - `goblin-tdd-repro`

- **When:** a defect where a regression test is cheap
- **Steps:** 1 write the failing test<br>- 2 confirm it fails for the intended reason<br>- 3 smallest production fix<br>- 4 revert the fix -> the test MUST fail -> restore
- **Verification:** the RED-again step is captured; prefer no new test over a bad test; the skip path is explicit, never silent
- **Profiles:** coder
- **Role:** code

## P6 - `goblin-verify-author`

- **When:** a project has no live lane, or its gates drift
- **Steps:** 1 read the repo, not the user, for entry points<br>- 2 write the gate/check set into the harness dir with the house harness shape<br>- 3 execute it once end to end<br>- 4 add the REPLAY block
- **Verification:** a generated skill that was never executed is a draft, not a deliverable; the harness prints PASS/FAIL and exits non-zero on failure; the REPLAY shows RED pre-change
- **Profiles:** architect
- **Role:** judgment

## P7 - `goblin-pr-gate`

- **When:** anything that should be reviewed before it lands
- **Steps:** 1 classify stakes S0-S4<br>- 2 run the gate set at the candidate SHA and record the numbers<br>- 3 write reviews/<slug>-<head7>.md with head/base/patch-id/stakes/checks-run<br>- 4 evaluate the panel rule for S3+<br>- 5 re-check the patch-id before landing
- **Verification:** the patch-id of base..head still matches the recorded one; the review note names a SHA that exists in git rev-list; for S2+ a check ran on that SHA
- **Profiles:** reviewer (+ architect for S3)
- **Role:** review-panel

## P8 - `goblin-bootstrap`

- **When:** adopting goblin-stack in a repo, or starting one
- **Steps:** 1 classify the project (A-E)<br>- 2 goblin-install --class <x><br>- 3 goblin-verify GREEN<br>- 4 fix .gitignore BEFORE any git init<br>- 5 first HANDOFF, first SPEC, first check script
- **Verification:** goblin-verify exits 0 and the created-file list matches installed.json; a repo with no gate declares one and records its first measured numbers
- **Profiles:** architect
- **Role:** judgment

## P9 - `goblin-handoff`

- **When:** ending a session, or picking up another's
- **Steps:** 1 commit uncommitted edits as one internally-consistent wip: commit<br>- 2 write intent / verified state / next steps / what is NOT verified<br>- 3 stale sentences get a dated parenthetical, never deletion<br>- 4 on pickup: verify inherited claims against the artifact
- **Verification:** every gate number in the HANDOFF carries 'measured <date>'; the named HEAD matches git rev-parse --short HEAD; the NOT-verified section is non-empty or says 'nothing outstanding'
- **Profiles:** any
- **Role:** judgment

## P10 - `goblin-overnight`

- **When:** an unattended run over a predicate
- **Steps:** 1 the exit condition is a checkable predicate written before iteration 1<br>- 2 it never gets relaxed<br>- 3 an escape hatch: a genuine dead end writes up why and stops<br>- 4 the morning audit reads the Attention section first
- **Verification:** the predicate is a command in the card body and was run at least once; goal_max_turns is set; every landed change has a P7 verdict row
- **Profiles:** default + coder
- **Role:** code

## P11 - `goblin-sweep`

- **When:** the same change or question across projects
- **Steps:** 1 enumerate targets with a shell glob, not a memory<br>- 2 classify each (A-E); an archive project is skipped, not processed<br>- 3 one card per project, parents=[sweep]<br>- 4 collect one line per project: what changed / what was refused / what is unfindable
- **Verification:** the per-project line carries the command it ran; the sweep report states its own coverage (n of m projects, and names the skipped ones)
- **Profiles:** default
- **Role:** synthesis

## P12 - `goblin-eval`

- **When:** a skill or prompt changed, and you want to know if it did anything
- **Steps:** 1 candidate and control run in sanitized directories<br>- 2 no eval/test/judge/rubric token anywhere the candidate sees<br>- 3 grade the chain from the transcript (which files it actually opened), never self-report<br>- 4 the judge runs on a different model family
- **Verification:** the judge's verdict is reproducible from the transcripts; candidates never learn other candidates exist
- **Profiles:** researcher
- **Role:** synthesis

## The cuts - pstack ships 23, this ships 12

Each cut has a reason, and a cut is recorded rather than deleted silently.

| cut | verdict | reason |
|---|---|---|
| `perf-issue` | folded into P2 | Its mechanism is "baseline trace, post-fix trace, diff the artifacts" - a step of a bug fix, not a playbook. No project here has a perf-target loop. |
| `hillclimb` | cut, deferred | Needs a frozen harness with proven sensitivity plus a loop primitive; the kanban's `goal_mode` already provides re-entry with a budget cap. |
| `runtime-forensics`, `trace-forensics` | merged into P2 | The transferable step is "capture a real artifact, then inject instrumentation into the running process". The library already ships the runners (`node-inspect-debugger`, `python-debugpy`), so a playbook would restate an existing skill. |
| `prototype` | merged into P1 step 3 | The valuable half is the classifier: a question whose answer is observable by running something is not the human's to answer. |
| `visual-parity` | cut | Needs a baseline screenshot harness; no project has a pixel-parity migration target. |
| `authoring-a-skill` | cut | `hermes-agent-skill-authoring` is live in the global library and is a Hermes-native duplicate. |
| `autopilot-stack` | cut | Nothing to stack: measured 0 branches and 0 PR merges across the repos this was designed for. |
| `autopilot-full`, `orchestrate` | merged into P10 + P11 + kanban | The fleet-programme half is the board's job (`parents`, `goal_mode`, `request_review`). The patch-id and different-family verifier rules they contain are kept as PG-03 and MD-02. |
| `multi-phase-plan` | merged into P3 + P8 | The standard already owns the SPEC lifecycle; duplicating it violates the one-owner rule. The machine-checkable half is kept as SP-01/02/03. |
| `worktree-cleanup` | cut | macOS/Xcode-specific by inspection (`xcrun simctl`, `DerivedData`). |
| `opening-a-pr` | merged into P7 | It is the terminal step of every other playbook; as its own playbook it would be a step file with one caller. Its PR-body schema becomes P7's review-note schema. |

**Deliberate non-imports:** the `swarm` and `arena` fan-out shapes (the axis is read-vs-write,
and five parallel lanes cost about five times the tokens), the cloud-agent lane (no per-agent
computer here), and the Slack automation lane (the *shape* transfers, and P11 plus cron is
that shape).

