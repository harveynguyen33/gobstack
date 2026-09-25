# Limits — where this is weaker, and what is unproven

Honest accounting. Nothing here is a hedge for a defect that could be fixed; each is either a
deliberate trade or an unfilled gap.

## Weaker than the Cursor harness it learns from

1. **No live-drive lane is shipped.** A harness that launches and drives the real application is
   what several of the source harness's playbooks depend on, and it is inert without a plugin
   that is not shipped. `P6` can *author* a project-local driver; goblin-stack cannot ship one,
   because that is per-project work. **The "live lane is the floor" rule is stated and
   unfilled.**
2. **No cloud agents.** There is no per-agent computer here, so nothing that needs a machine of
   its own.
3. **No agent graph and no verdict-ledger daemon.** The board replaces both at a lower
   resolution: `parents` expresses ordering, not data flow, and sibling cards cannot see each
   other.
4. **Fourteen playbooks against twenty-three.** The cuts in `docs/FLOWS.md` are deliberate and each
   is argued, but real coverage is lost: performance hillclimbing, pixel parity, trace
   forensics, stack landing, worktree hygiene.
5. **No swarm or arena fan-out.** The read-versus-write axis says that is correct for this work
   mix; it is still a capability the other harness has and this does not.

## Weaker than the status quo it is meant to improve

6. **The biggest measured defect is out of reach.** The orchestrator's routing text says a bare
   subagent spawn reaches the specialist profiles; it does not. That is the highest-cost defect
   on the box, and goblin-stack cannot fix it from inside a project repo. It ships corrected
   text in `docs/INTEGRATION.md` and lints its own artifacts (`MD-03`); the fleet-side edit is
   escalated.
7. **The staleness of a fleet-config repo is detectable and not fixable here** — the E-class gate
   notices it, and the underlying job bug belongs to another repository.
8. **A new surface to maintain.** Per-repo vendored `.goblin/` plus `.hermes/skills/` means
   upgrade debt in every adopted repo, plus one more command pair to learn. The counter is that
   the alternative — profile copies — already failed.
9. **Ten rows are labelled `advisory`, and nine of them are prose with no check at all:**
   `HP-04`, `HS-03`, `CM-02`, `MD-03`, `PG-04`, `DOC-01`, `DOC-02`, `SC-09` and `JG-03` (G2, the
   judge lane that has never returned a non-`done` verdict). One (`MD-02`) is
   advisory-labelled but still reports its state as `ADV`. Each is counted and capped, but a
   counted rule is still not an enforced one, and **the cap is a policy, not a proof.**
10. **It does not reduce the profile-skill surface.** It only stops that surface from growing
    with project procedures; the existing divergence is a separate cleanup.
11. **`HS-02` cannot prove anything until a round lands.** With no pinned pre-change commit it is
    skipped with a reason. That is honest, and it means a brand-new install has **no** REPLAY
    evidence at all. The shipped `checks/assert.mjs` is a scaffold: it asserts something true by
    construction, so `HS-02` correctly reports it as a check that proves nothing until it is
    replaced with real probes.
12. **`HP-03` proves a date exists, not that a number is fresh.** A HANDOFF can carry yesterday's
    number with today's date and pass. Since V1 the row is anchored on the gate names
    `.goblin/goblin.yaml` DECLARES and skips the template's own example sentence, so a real gate
    line can no longer lose its `measured <date>` in silence (G8-2 measured the old row passing
    exactly that); but nothing re-measures the number, and a gate-bearing line that names no
    declared gate and carries no gate-shaped keyword is still unseen.
13. **`PG-04` and `PG-05` are documentation plus a textual heuristic.** A protected branch whose
    only admin is the person pushing protects nothing, and a required check that self-skips
    reports success. Neither is observable from inside a repo.
14. **`CM-02` cannot be enforced.** A backtick lost to command substitution leaves no trace a
    later check can read.

## Unproven at the level that matters

15. **The controlled evidence now exists, and its counter-finding is about this repo (corrected
    2026-09-25).** This entry used to say that **no controlled study of skill efficacy exists**, so
    that nothing here claimed the installed skills change agent behaviour. That is out of date:
    **SkillsBench 1.1** (benchmark published 2026-06-16) reports that **curated Skills raise the
    mean task-resolution rate from 33.9% to 50.5% — +16.6 points, a 25.5% normalized gain — across
    87 tasks, 8 domains and 18 model–harness configurations**, with every one of the 18
    configurations higher with Skills (configuration-level gains from +4.1 to +25.7 points).
    **The counter-finding matters more here than the headline:** in the same benchmark's
    **self-generated condition — the agent authors its own Skills before solving — all three tested
    configurations landed BELOW their no-Skills baseline** (−8.1, −11.3 and −11.5 points), while
    curated Skills stayed above it. **goblin-stack installs agent-authored skills**, so the lower
    row of that result is a warning about its own output, not someone else's: a generated skill
    accepted after a skim is a different proposition from a written one. It is why `P6` hands the
    generated skill to `P12` before any `verified:` date advances (`docs/RISKS.md` K15).
    **`P12` is still the mechanism to find out, and it has still never been run**: the record format
    is now specified (`skills/goblin-eval/SKILL.md`) and **no row reads a lane** (#31).
    Pin: `https://www.skillsbench.ai/blogs/skillsbench-1-1`, sha256 of the retrieved page
    `d812bb7c2da702cc67556eb5f46b9e93faaca19d3545376544866e940126ef15`, fetched 2026-09-25; the
    eleven-token ban and the judge procedure are argued in
    `https://ai.engineer/talks/0vphxNt4wyk-don-t-ship-skills-without-evals`. **Not registered**:
    the source registry is `manifest/sources.tsv` (G9's artifact) and that file does not exist in
    this repo — measured, `git ls-files manifest/` names five files and none of them is
    `sources.tsv` — so the registry row is composed in the W2 report for G9's patch instead of
    being written into a file this card does not own.
16. **Every number in the design is a file read or a third-party published number; none of it is
    a measurement of this harness under load.** The harness was built and its verifier was shown
    RED under a deliberate break; that is a statement about the mechanism, not about outcomes.
17. **One spec deviation, recorded rather than hidden.** The design spec's literal HANDOFF check
    is `grep -q "$(git rev-parse --short HEAD)" HANDOFF.md`, which **can never pass** — committing
    the HANDOFF moves HEAD, so the file can only ever name an ancestor. `HP-05` is therefore
    mechanised as *the HANDOFF names a commit that exists in this repo and is an ancestor of
    HEAD*, which still catches the defect the rule exists for (an artifact that names no commit
    at all). The deviation and its reason are in the row's own `if_not_why` column.
18. **`.goblin/installed.json` is not signed, so nothing here proves it was not rewritten.** Every
    drift check — `IN-02`, `SK-02`, and `HS-01`'s hash of the harness dir — reads its expected
    hash out of that one file, and that file is the one file no check protects. Measured: append a
    byte to `.goblin/bin/goblin-verify`, rewrite its recorded hash in `installed.json`, commit, and
    the run is **fully GREEN** (`42 passed, 0 failed`, exit 0). One edit defeats three rows at
    once, and it is the cheapest way to fake a green run. Doing better needs an anchor the target
    cannot edit — a signature, or a hash held outside the repo — and goblin-stack has no such
    trust root: the source checkout is not guaranteed to exist at verify time, and any value
    stored in the tree is editable by the same hand. It is therefore **recorded here and printed
    in the "cannot see" footer on every run**, not claimed away.
19. **No automation has ever run here.** Cost per run, the respawn guards under a nightly
    producer, and whether `researcher` is the right reporter profile are all unmeasured; the
    first watched run of A-02 is what produces those numbers. The producer's own ceiling is a
    **run count**, not a dollar figure — no config key holds the spend cap, so no automation can
    read it, and none pretends to.
20. **The dedup key is a dedup, not a mutex.** The board's lookup runs before the write
    transaction, so a concurrent create can insert twice and the next lookup stabilises on the
    newest. The key stops a duplicate storm; it does not make one impossible.
21. **`AU-02`'s normalisation is only measured on synthetic reports.** Two differently-typed
    copies of one symptom give one key and a different symptom gives another, but whether a real
    report set normalises well enough is unknown. Its failure mode is a duplicate card, never a
    lost report.
22. **No audit has ever run against a real registry here.** Everything `SC-07` does was measured
    against a canned npm-audit report (`tests/t-audit.sh`), so the parse is proven, the *policy*
    is not: whether the recorded waiver set matches the real advisory set is unknown until the
    first real `goblin-audit`. Its skip-with-a-reason behaviour on a repo with no record is what
    keeps that honest rather than silent.
23. **The audit record is read by field name, not by a JSON parser.** `goblin-audit` recognises
    npm's `vulnerabilities` / `via` shape (`source`, `name`, `url`, `range`) with awk and REFUSES
    (exit 5) anything it cannot parse, rather than writing an empty record that `SC-07` would read
    as clean. A different audit tool is therefore a refusal, not a silent pass.
24. **The freshness rows need a GNU `date -d`.** `SC-07` parses the record's date that way; on a
    host without it the row FAILS with the reason rather than assuming the record is fresh.
25. **`SC-04` reads one statement, not one program.** A cookie write spread over three lines (or
    assembled through a helper) is not seen, and the row says so in its own cell.
26. **The last advisory slot is an open decision, not a rule.** Measured (V1): the advisory rows
    are `HP-04`, `HS-03`, `CM-02`, `MD-02`, `MD-03`, `PG-04`, `DOC-01`, `DOC-02`, `SC-09` — 9 at a
    ceiling of 10 — so **exactly one slot is free**, and `SK-03` reports that arithmetic on every
    run (`advisory 9 of ceiling 10 (1 free slot)`). Two planned cards each wanted the slot: G1's
    `FM-03` (the feature map) and G2's `JG-03` (the judge agent). **Nothing in this repo chooses
    between them**, and V1 deliberately spent nothing. The cap is a count, not a strict bound:
    measured, 10 advisory rows at a ceiling of 10 **pass**, and the 11th FAILs (10 at a ceiling
    of 9 FAILs). So the tenth row is allowed; the eleventh is not. Whoever lands second brings a
    real command.
    **Decided 2026-09-25 (W2):** G1's `FM-03` does **not** take the slot. The feature map ships
    `FM-01` and `FM-02` as real commands, and the one thing they cannot check — whether the map
    lists every feature — is recorded as #30 instead of as a counted row; the slot is left free for
    G2's `JG-03`, whose judge is the mechanism `P12` actually needs. Measured after W2, `SK-03`
    still reads `advisory 9 of ceiling 10 (1 free slot)`.
    **Spent 2026-09-25 (W3):** G2 landed and `JG-03` took it. The slot is now **full** — measured
    `advisory 10 of ceiling 10 (0 free slots: the next advisory row FAILs)` — so the next author who
    wants an advisory row must raise `advisory_ceiling` in the same change and write down why,
    rather than discovering the cap from a red run. This is not a rule change; it is the arithmetic
    the ceiling was always meant to force into the open.
30. **The feature map is an inventory, and nothing checks that it is complete.** `FM-01` checks the
    index against the feature files that exist and the four-H2 entry contract; `FM-02` is a tripwire
    over `entry_paths:`. **Neither can see a feature nobody wrote down** — that needs semantic
    judgement over the app, which no command here performs. Three smaller blind spots are named in
    the rows' own why-cells and repeated here: `FM-02` searches for the token under `source_root:`
    and therefore **reads a vendored copy, a lockfile or a build artifact as "still resolves"**; it
    sees a *file* change and not a *behaviour* change, so a refactor that leaves the route alone
    reports stale-and-wrong and a behaviour change in a file the token does not appear in is missed;
    and a `verified:` date is a **claim the row cannot test** — nothing distinguishes a feature
    driven that day from a date typed that day. The first of those is why `source_root:` should name
    the source tree, not the repo root, and the third is why the upkeep pass in
    `skills/goblin-feature-map/SKILL.md` requires the date to advance only for a feature someone
    actually drove.
31. **The P6↔P12 loop is wired as a contract with no runner.** `P6` now hands a generated
    verification skill to `P12` and `verified:` does not advance until an eval record exists; the
    record's shape, the eleven-token ban, the cheap-checks-first ladder, the merge rule and the pass
    condition (every seeded defect detected, the control's number at zero, every correction RED
    before GREEN) are all specified in `skills/goblin-eval/SKILL.md`. **No row reads a lane, and
    nothing executes an eval** — measured after W2, `manifest/enforcement.tsv` has no `EV-*` row,
    and `P12` has still never been run. The runner and the record checks (`EV-01`..`EV-04` in G1's
    design) are deferred to a follow-up card, deliberately and in the open, rather than half-built:
    a row that reads a record nobody writes would pass vacuously and look like enforcement.
32. **The judge is a language model grading prose, and the record proves a handle exists — never
    that the handle supports the verdict.** `JG-01` FAILs a `done` verdict whose evidence resolves
    to nothing: `sha:<hex>` must be a commit in `git rev-list --all`, `file:<path>` a path under the
    root, `sha256:<hex>` the digest of a file under `.goblin/loop/`. All three say *exists*. A judge
    may cite a real commit that has nothing to do with the claim and pass, and a `cmd:<command>`
    token resolves **nothing on purpose** — the command ran, its output is not in the record, and a
    verdict resting on it is the self-report the row refuses. Two smaller blind spots are stated in
    the row's own why-cell and repeated here: the row cannot see **which lane returned a verdict**
    (no file in a repo observes the profile that ran — `MD-03`), and **an unresolved judge lane is
    an `ADV`, not a failure**, because a repo cannot choose the fleet's routing (`docs/ROLES.md`,
    "the measured caveat"): measured on this box, the judge lane resolves to no profile at all.
    Finally, the `JG-03` counter-measure is **policy, not a check** — one known-red control verdict
    per wave, recorded in `docs/LOOP.md`: a lane that has judged twice cannot be called always-yes,
    and the history that would show a bad lane lives across cards and repos.
33. **`LP-04` measures a changed evidence pointer, which is a proxy for progress — not progress.**
    Three consecutive verdict rows with an identical non-empty pointer and a result that is not
    `predicate:green` is a FAIL naming the row numbers, and that is the strongest thing a repo can
    read without running the loop. A loop that edits a file each turn to keep the pointer moving is
    not caught, and **nothing in Hermes detects a lack of progress either**: measured in
    `hermes_cli/goals.py`, `run_kanban_goal_loop` carries no progress state at all — its whole
    state is `last_response`, `turns_used` and `nudged_to_finalize`, so a loop that returns
    `continue` for the same reason nineteen times spends nineteen turns and then blocks
    (`hermes_cli/goals.py:1636-1638`, `:1689-1696`). So the budget is the backstop, and the budget
    has its own blind spots: `LP-03` proves the declared budget is a positive integer at or under
    `loop_max_turns_ceiling` and that the record holds no more verdict rows than the budget — it
    cannot see whether the budget is **affordable**, and cost is not a field the record holds
    (neither turns nor tokens nor the per-turn auxiliary judge call). Three further "not yets" are
    structural rather than measurable: `LP-01` proves a recorded first run exists and that its
    timestamp is at or before the first log row — **not that the command ran and not that the
    `exit=` value was measured rather than typed** (`HP-03`'s defect, one artifact over); `LP-02`
    proves the predicate file still hashes to its pin — **not that the predicate is the right one,
    and not who edited it**; and a predicate that was **vacuously true from the start** (a `grep -c`
    against a renamed directory) passes `LP-01` and `LP-02` and ends the loop green on nothing.
    `LP-05` makes a write-up mandatory and therefore visible — nothing can make it true.

## What the harness refuses to do

It does not claim a green run means the work is right. `goblin-verify` asserts that the installed
files are the files on disk, that every rule with a command still passes, and that the
untestable remainder is counted and capped — and it prints, on every single run, what it cannot
see: the five upstream blind spots, plus the ban lane's own (the unsigned ban table #28, the
text-probe gap #27, and a ban that is invisible until verify runs, `V3-1`), plus the judge/loop
lane's (#32: a handle that exists is not a handle that supports the verdict; #33: a changed
pointer is a proxy for progress, not progress).

27. **The ban probes are text probes, not ASTs.** `BN-01`, `BN-02`, `BN-03` and `BN-05` are
    `grep` over source under `bash`/`grep`/`awk` only — the dependency contract in
    `docs/CONTRACTS.md` allows no parser and no `npm`. So a `: any` inside a string or a comment
    is reported, `Record<string, any>` (no leading colon) is missed, and BN-05 does not resolve
    module aliases or dynamic imports. The AST-grade form of the same bans (BN-01..BN-04 in
    `G5.md` §C.2) needs ESLint and `dependency-cruiser`; that is why **G5's `BN-04` (the nine
    named unnecessary-effect patterns) is NOT shipped** — it cannot be mechanised without a
    parser, and a ban that cannot go red is worse than advisory, so it is recorded here rather
    than as a row that would cost the last advisory slot. A text probe with a stated
    false-positive set is still a gate: each BN row is shown RED under its own violation and
    GREEN when it is removed (`tests/t-verify-red.sh`).
28. **The ban table's integrity rides on `IN-02`, and `IN-02` rides on an unsigned record.** A
    project could empty `manifest/bans.tsv` (or edit a `detect` command) and the ban gate would
    pass vacuously — `BN-00` fails closed on an *empty* table, but it cannot see a table whose
    rows were weakened, because `.goblin/manifest/bans.tsv` is hashed by `IN-02` and
    `.goblin/installed.json` is not signed (`docs/LIMITS.md` #18). The ban list is not
    tamper-proof; it is as strong as the record every drift check trusts.
29. **The perf ceiling must EQUAL the recorded baseline, so a budget with headroom is not
    expressible.** `PF-01` FAILs when `ratchet.ceiling` and `perf.baseline_value` disagree
    (G8-6b), which is what stops a one-line ceiling raise from passing while printing the
    contradiction. The cost is real and the row cannot see it: a project that wants the ratchet
    to allow, say, 10% growth over the measured baseline cannot write `ceiling: 44000` beside
    `baseline_value: 40000` — the row reads that as a disagreement. Headroom is expressed by
    re-anchoring BOTH (measure on a pinned commit, then set `baseline_value` and `ceiling` to the
    new number together, and record it as an operator action), which is the deliberate re-anchor
    the row's own why-cell names. It is a bound on the budget's shape, not a claim that the
    budget is the right one — and it still never re-measures.
