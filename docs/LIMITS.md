# Limits — where this is weaker, and what is unproven

Honest accounting. Nothing here is a hedge for a defect that could be fixed; each is either a
deliberate trade or an unfilled gap. (This file keeps the revision wave codes — `W6`, `Z1`, and
the rest — in its dated parentheticals; `docs/RECORD-NOTES.md` is the legend.)

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
4. **Fifteen playbooks against twenty-three.** The cuts in `docs/FLOWS.md` are deliberate and each
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
13. **`PG-04` is documentation, and `PG-05` is a text reading — re-declared at W4 rather than
    called a gate.** `PG-04` stays `advisory` because the forge is unobservable from inside a
    repo: a protected branch whose only admin is the person pushing protects nothing, so a
    required check armed under the sole admin's own identity binds nobody — the second half of
    that sentence is measured (Harvey is the sole admin of every repo he owns), and changing it
    is a forge/account change, not a repository change. `PG-05` **used to be a heuristic**: it
    counted "every step is guarded", so a single **job-level** `if:`, a job with no step, and the
    measured real shape (one *unguarded* step deciding whether the guarded gate step runs) all
    passed it while GitHub reported Success. It now refuses a conditional job, a conditional
    step, a job that declares no step and a workflow with no `jobs:` — see `docs/CI.md` §1 for
    why a skipped job is a green light. It is still a **text reading**: no YAML parser
    (`docs/CONTRACTS.md` allows none), so a flow-style `jobs: {…}` mapping is refused rather than
    parsed, a `#` inside a quoted string is read as a comment, and a conditional step that is
    genuinely safe is indistinguishable from the trap. It cannot see branch protection, the
    required-check list, or whether the job ever ran — `PG-04` is the row that says so. `PG-06`
    is the other half and has its own limit: it proves the declared gate is **invoked** in a file
    under `.github/workflows/`, never that the forge marks that job required, never that it is
    the job the forge waits on, and never that the workflow can fail.
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
    the run is **fully GREEN** (`38 passed, 0 failed`, exit 0). One edit defeats three rows at
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
    ceiling of 10 — so **exactly one slot was free**, and `SK-03` reported that arithmetic at the
    time (`advisory 9 of ceiling 10 (1 free slot)`; **corrected 2026-09-25 (AB3):** the run prints
    `advisory 10 of ceiling 10 (0 free slots: the next advisory row FAILs)`, W3's `JG-03` having
    taken the slot — the two notes below carry the chronology). Two planned cards each wanted the
    slot: G1's `FM-03` (the feature map) and G2's `JG-03` (the judge agent). **Nothing in this repo
    chooses between them**, and V1 deliberately spent nothing. The cap is a count, not a strict
    bound: measured, 10 advisory rows at a ceiling of 10 **pass**, and the 11th FAILs (10 at a
    ceiling of 9 FAILs). So the tenth row is allowed; the eleventh is not. Whoever lands second
    brings a real command.
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
pointer is a proxy for progress, not progress), plus the CI lane's (#34: a file is not a gate —
the required-check list, the bypass switch and the push identity are forge state; #35: the
Electron perf number is a host gate, and the ratchet deliberately carries a different metric).

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
    tamper-proof; it is as strong as the record every drift check trusts. **Measured (W5-12):** with
    `BN-01`'s `detect` cell set to `true`, `BN-00` and `BN-01` both PASS and the only row that
    changes verdict is `IN-02`'s drift check — the `W5-12` control in `tests/t-verify-red.sh` pins
    exactly that, and nothing else can. Z1's verdict is to **record this, not fix it**: the `detect`
    cell is executable content, and a row able to judge whether another row's command *means*
    something would be an `eval` over the matrix, which the same card rules out. The gap is now
    stated, measured and controlled one row over, which is the most this table can do without
    becoming an interpreter.
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
34. **The CI lane reads files, and a file is not a gate.** The shipped workflow
    (`templates/ci/goblin-gate.yml.tmpl` → `.github/workflows/goblin-gate.yml`) has no `if:` at any
    level, but nothing in a repository can make GitHub **require** it: the required-check list,
    the bypass switch and the push identity are forge state (four settings, `docs/CI.md` §1).
    `PG-06` proves the whole declared gate set is invoked in a file under `.github/workflows/` and
    cannot prove that file is the one the forge waits on; `PG-05`'s reader has no parser, so a
    flow-style `jobs: {…}` mapping is refused, and a `#` inside a quoted string truncates the line
    it is on. Two further measured gaps: the template's job is `ubuntu-latest` with no cache, so a
    repo whose gate needs a display, a licence, a GPU or a signed-in session cannot use it at all
    (that is a **host** gate — the class-C rule, restated for class F; **corrected 2026-10-02 (W6):**
    F is merged into `software`, so this is the electron opt-in), and a private repo's
    Actions minutes are billed to the account (2,000/month free). Measured ground truth at W4:
    **one** first-party workflow exists in the whole estate and it self-skips; five of the six
    repos with a remote have none.
35. **The Electron perf number is a host gate, and the ratchet carries a different metric.**
    `presets/F-electron.yaml` declares `main_thread_busy_pct` as `perf_host_gate:` and uses
    `app_bundle_bytes` for `ratchet:` — a **deliberate deviation** from G6 §B.3, which put the FPS
    number in the ratchet. The instrument that produces it (CDP `Performance.getMetrics`, or
    `app.getAppMetrics()[i].cpu.percentCPUUsage` inside a real Electron) needs Playwright or
    Electron plus a GUI, and a shipped rule may use nothing but bash/git/awk/sed/grep/python3
    (`docs/CONTRACTS.md`) — so `ratchet.cmd` pointing at the probe would make a fresh install
    **born RED**, which is the one thing the install path must not produce. The probe belongs to
    the project; a project whose CI needs npm runs it in **its own** workflow. What the number
    means has a limit of its own, and it is measured: this box is an LXC with no display and no
    system Chromium, so the G6 sweep came from a *bundled headless* Chromium with no compositor
    and no vsync. Relative comparisons on one machine are meaningful (which is why
    `main_thread_busy_pct` works at all, and why frame time does not — p50 stayed flat at 16.70 ms
    while the main thread went from 1.8 % to 54.5 % busy, `docs/CI.md` §3.3); an absolute FPS
    claim is not. Three further Electron failure modes are **recorded, not mechanised**, and
    `docs/CI.md` §4 says why: the dependency-graph boundary check, `ipcMain` sender validation,
    and fuses at package time. **Corrected 2026-10-02 (W6):** this preset is now
    `presets/electron-overlay.yaml`, rendered over `presets/software.yaml` by `--electron` (or the
    `desktop`/`F` install alias) — the old `F` class was merged into `software`.
36. **A ban's exemption reaches the probe through its environment, so a custom probe can ignore it.**
    `bans_exempt:` and the inline `// BAN-OK(<id>): <reason>` are filtered *before* the exit code is
    chosen, because a filter applied to a probe's stdout afterwards cannot change a verdict — that
    was W5-1, and the old code made every exemption a permanent RED. The engine therefore exports
    `GOBLIN_BANS_ID` and `GOBLIN_BANS_EXEMPT` and the two shipped probes honour them. A project's
    **own** `detect` command that ignores the variables keeps the old behaviour: a violation inside
    an exempted path stays RED. That direction is **closed**, never open, and it is the trade this
    choice makes. The engine's own stdout is no longer filtered at all, so a probe that ignores the
    contract prints the exempted lines it reported — loud, and still a FAIL.
37. **`FM-02` refuses the harness, not every non-source file.** The search skips `.git/`,
    `.goblin/`, `.hermes/`, the declared `harness_dir` and the map's own directory, so a stub map
    whose token occurs only in the install no longer resolves (W5-4: `entry_paths: [export]` used to
    "resolve" to `./.goblin/bin/goblin-verify`). It does **not** exclude the target's own `docs/`,
    `tests/` or build output: a token that occurs only there still reads as resolved, and excluding
    them would be a guess about a layout goblin-stack does not know. Nor is there a frequency bound
    — a common token ("export", "main") is satisfied by the first of hundreds of files.
38. **The judge lane's model family is reported, never enforced — and on this box it is not even
    mapped yet.** `JG-02` proves the declared profile *names* are disjoint; W5-6 measured that a
    profile mapped to the author's own model passed it. `MD-02` now resolves the judge lane and
    compares its model with the code lane's, so the state is loud — but it stays `advisory`
    (`return 2`, never a FAIL): goblin-stack cannot choose the fleet's models, and a repo-local file
    cannot observe *which* model a lane actually ran. Measured on this box at X1: Harvey's
    `fleet-model.yaml` names **no `judge:` profile at all**, so `MD-02` reports the judge lane
    **unresolved** and prints the one-line remedy, while every profile it *does* name — nine of
    them, the named per-fleet role profiles this setup routes its lanes through —
    resolves to one model under an active promotion. So on this box the honest reading is: the judge
    lane is not mapped, and the moment it is mapped it will be the author's own family. The
    comparison is exact model equality, not a version-stripped "family": two spellings of the same
    family that differ only in a suffix would read as different.
39. **`LP-02` cannot tell a weaker predicate from a re-scope. The close-and-reopen is recorded, not
    prevented.** A loop could archive its bar under `closed-<date>/`, write a weaker one, re-pin,
    and pass `LP-02` and `LP-05` with nothing in the record (W5-7, measured). The row now requires
    every archive to hold its predicate **and** the pin it was closed under, and the live
    `predicate.sha256` to name the archived digest on a `previous:` line — so a **silent** relaxation
    is caught and a legitimate re-scope costs one line. Whether the new predicate is weaker, and who
    edited it, is not decidable from a digest, and a predicate that calls a script elsewhere is
    pinned only at its call site. The residual is the same one `LP-01` carries one file over: the
    record is evidence, not proof that the loop stopped for the right reason.
40. **A fresh install into a repo with no commits is born RED, and X1 did not change that.** Measured
    at X1: `goblin-install --class A` into a `git init` with zero commits, then `goblin-verify`, gives
    `37 passed, 6 failed, 11 advisory, 24 skipped`, exit 1 — `HP-05`, `SP-02`, `GT-02`, `CM-01`,
    `CM-03` and `PT-02` all read a HEAD that does not exist yet. The install never creates the seed
    commit (`bin/goblin-install` writes files and stops), and it must not: a tool that commits into
    Harvey's repo on first contact is the overreach `docs/CONTRACTS.md` rules out. Carried from W5
    §5's `G8-9` rather than fixed here — it is a **sequencing** limit, not a hole in a row: one commit
    clears all six, and `tests/t-verify-green.sh` seeds one before it installs.
41. **Eleven of Y1 §7's eighteen documented mechanisms still carry no control of their own, and one
    exemption is by design.** The census, stated separably so a reader can check the arithmetic:
    **18 listed · 2 fixed · 2 closed · 3 controlled · 11 recorded.** Y1 §7 listed eighteen
    mechanisms; Z1 **fixed** the two load-bearing ones (17, the unrendered token — Z1-3; 18,
    `replay.cmd` — Z1-4, which now have controls and therefore sit *outside* the "carry no control"
    set) and **closed** two more (4, the ban engine's `exit 2` paths; 5, `--list` — three assertions
    in `tests/t-verify-red.sh`, RED against a deliberately broken copy of `bin/goblin-bans`, which
    is PR-03's second branch: those mechanisms *worked*, they were just unguarded); AA1
    **controlled** three (1, 2 and 6 — the ban-engine cluster, below). The remaining **eleven** are
    **recorded here rather than mechanised**. Each was measured WORKING, so an assertion would pin
    behaviour that already holds, and this box does not have eleven controls' worth of budget; the
    cost of the gap is exactly the shape of both regressions in this repo's history — a mechanism
    documented, and nothing asserting it.
      - items 1, 2, 6 — `bans_exempt:` on the layer probe, the engine→probe
        `GOBLIN_BANS_ID`/`GOBLIN_BANS_EXEMPT` contract, and its segment alignment: **CONTROLLED at
        0.4.2 (AA1)** — seven controls in `tests/t-verify-red.sh`, in both directions each (the
        layer probe's exempt path PASSes and the same crossing import outside it FAILs; a prefix
        covers its own subtree but does not swallow `src/okay`; a prefix written with a trailing
        slash exempts nothing; and a project's own probe that exits 0 only when both environment
        variables arrive). This was the cluster Z1 named as the one with a real engine underneath,
        and `grep -c GOBLIN_BANS_EXEMPT tests/` was **0** before it.
      - item 3 — a project's own probe that ignores those variables fails closed: the mechanism is
        this file's #36, where the FAIL is measured.
      - item 7 — `BAN-OK` must sit on the offending line: the marker's *effect* is controlled, the
        on-this-line clause is not (a marker on another line does not clear the violation).
      - items 8, 9 — `SC-05`'s `.goblin/boundary-waivers` and `SC-08`'s
        `.goblin/install-hooks.allowlist`: both files are copied and both FAIL directions are
        controlled; neither *honoured* direction is. (`SC-08`'s reader is the row the minified
        lockfile defeated — Z2-2; that was a shape, not this item, and it is fixed and controlled.)
      - item 10 — `SC-03` clause 2, `sec_build_output`: a literal in `dist/assets` FAILs; only the
        clause-1 path is controlled.
      - items 11, 12, 15 — `scaffold_checks:`'s SKIP branch, `perf_host_gate` (#35) and
        `templates/loop/*.tmpl`: declared no-ops (SKIP, a host gate, and templates `docs/LOOP.md`
        says nothing installs). A control here would assert that nothing happens.
      - item 13 — `docs/CI.md`'s flow-style `jobs: {…}` refusal: fails closed already, so a control
        would pin the strict direction of a check that cannot pass vacantly.
      - item 14 — `bin/goblin-model`: works (`code` → the resolved lane, unknown role → exit 2);
        only its *absence* from an install is asserted.
      - item 16 — `docs/LOOP.md` §6's "one known-red control verdict per wave, recorded in this
        file": a prose obligation, not a command. It is honoured in the write-ups (or not) and no
        check can read a wave.
    **W5-10 is answered here too.** The tenant strings `PT-01` forbids do not reach `docs/`, because
    `docs/` is never installed: the row's directory list is `skills manifest bin templates presets
    .goblin .hermes`, so a string under `docs/` is source-tree prose that no operator's repo ever
    receives. That is the whole reason, it is deliberate, and the row is not weakened by it — Y1
    agreed, and Z1 leaves it. This is the sentence Z1 added so the reason is visible in the shipped
    artifact rather than only in the wave's own notes.

42. **The doc walk cannot read a path broken at the directory/name boundary.**
    `tests/t-doc-promises.sh` reads a command directory only as `.goblin/bin/` or `bin/` **with its
    trailing slash**; when a line ends on the bare directory (`.goblin/bin`, `bin`) and the slash
    leads the next line (`/goblin-doctor`) or is dropped (`goblin-doctor`), the directory and its
    continuation are both invisible — the first fragment stops before the name the grammar needs, the
    second is not preceded by `bin/`, so neither is a token and neither is asserted. Measured
    2026-09-26 (AB7): a plant of that form in `docs/CI.md` is reported **`PASS`, rc 0**, mentioning
    the plant **zero** times, and a line that ends on the bare directory with nothing after it is
    silent too, because the `dangling()` guard needs the trailing slash as well. **0 live instances**
    — measured: `grep -rnE '\.goblin/bin$|bin/$' $(git ls-files)` → **no output, exit 1**. **What it
    costs:** a false path written in that form — the exact defect this file's whole species is named
    for — passes the watch silently, so a future document could hand a reader a command that does not
    exist and nothing in the walk would say so. **Ticketed, not gated:** reading the form is a change
    to the tokeniser inside `tests/t-doc-promises.sh`, not to a document, and it is a separate card;
    this entry records the boundary so a green run cannot imply a coverage it does not have. The
    control's own header now names the form as uncovered instead of claiming a sensitivity it does
    not have, and the slash's load-bearing role is stated where the dangling rule is.

43. **The engine footer names its judge, and the statement is unsigned — one forgery covers N
    repos.** W1's engine split prints `cli_sha256` and `enforcement_tsv_sha256` on every run
    (and `installed.json` gains an optional `engine:` block recording the same pair), so a repo
    can state WHICH engine judged it. Nothing signs either hash: the footer is printf output of
    the very binary it names, and the `engine:` block is a JSON stanza inside the same unsigned
    record `docs/LIMITS.md` #18 already covers. An edited engine, or a hand-written block
    claiming a mode that was never resolved, prints whatever it likes — and because the
    statement now rides in every repo's run, one forgery propagates to every repo that trusts
    it, which is strictly worse than #18's per-repo record. The old defences still hold and are
    what the footer must not be read to replace: `--source` pins the engine by flag, a vendored
    engine keeps beating the global one in the resolution chain, and IN-02 still hashes the
    repo-local bytes. What is NOT fixed (G6, the no-signing non-goal): no trust root, no
    detached signature, no third-party attestation. Measured with W1: tamper one byte of the
    vendored manifest and the footer's `enforcement_tsv_sha256` moves — the footer is a real
    fingerprint of what ran, it is just not PROOF of it.

## Verdicts recorded, not built (the note-8 questions)

Two library questions were investigated to a verdict and **deliberately built nothing here**, so a
later session does not re-derive them. The measurements and sources are in
`goblin-stack-research/G6.md` Part C; this is the durable half.

**Pretext (`chenglou/pretext`) — USE, narrowly, and not as a runtime dependency.** Verified from
the source of truth: a pure JS/TS library for multiline text measurement and layout, MIT, that
*"side-steps the need for DOM measurements (e.g. `getBoundingClientRect`, `offsetHeight`), which
trigger layout reflow"*, using the browser's own font engine as ground truth. Author confirmed
(Cheng Lou, `_npmUser: chenglou`); the README credits Sebastian Markbage's earlier `text-layout`,
whose repository now says *"This project is archived. The ideas here evolved into Pretext"*.
Two verified corrections to the shipped skill: the skill pins `@chenglou/pretext@0.0.6` while npm's
latest is **`0.0.9`**, and *"15KB zero-dependency"* describes the **runtime**, not the install
(published tarball `unpackedSize: 887142` across 69 files, `sideEffects: false`, subpaths `.` and
`./rich-inline`). The concrete use is a **dev-time / harness-time label-fit check** for
`diagram-studio` and `goblin-ui` — "does this string fit this box at this font", without a layout
read, as a `checks/*.mjs` assertion with a REPLAY — in exactly the repos that today hand-roll that
arithmetic (26 `getBoundingClientRect()` calls, no `measureText` call, no label-overflow probe).
**Do not** put it in the runtime bundle: the app is offline by design, and the skill's own stack
table imports it through a CDN, which contradicts that. The second use is one blog demo, not
infrastructure.

**mise (`jdx/mise`) — NOT NOW, with a named trigger that flips it.** Verified: mise-en-place, MIT,
macOS/Linux/Windows, one CLI that declares tool versions, environment variables and commands in
`mise.toml` and uses them in the shell, the editor and CI; the polyglot successor to
asdf/nvm/pyenv, and `.tool-versions` already works; installed with `curl https://mise.run | sh`.
The premise for adopting it did not survive measurement: the projects do **not** run differing Node
versions, and nothing declares a version at all — 0 `.nvmrc`/`.node-version`/`.tool-versions` files
under `~/projects`, `engines.node` in exactly **one** first-party manifest, and a single Node on
the box (v22.23.1, reached through `~/.local/bin`, which a shell profile puts first). The one real
divergence is a *package-manager* split, which mise cannot resolve. Adopting it now would add a
second version source beside the Node Hermes bundles. **Adopt when either becomes true:** two
projects need different Node majors, or the first Electron app lands (Electron ships its own
Node/Chromium, so the host Node stops mattering for the shell and starts mattering for the build
tooling). **The cheap thing to do meanwhile:** declare the version that already exists — one
`engines.node` line where it is missing, and a `measured <date>` gate line in the HANDOFF naming
the Node the gates ran under.

44. **The version statement is a convention, not an enforcement row — the sync is test-side and
    the engine itself never checks it.** W2 closed the measured hole PLAN-V1 §4.4 recorded (no
    test read any of the five `GOBLIN_*_VERSION` constants in `bin/`): `tests/t-version-sync.sh`
    now pins the count of those constants at 5, asserts every constant and
    `package.json.version` equals `VERSION`, and asserts `goblin --version` — through both the
    bash CLI and the node shim — prints `VERSION` byte-for-byte. What remains open: the sync
    lives only in this repo's test suite, which a target repo never runs — and when the npm
    tarball exists (W3/W5 packaging, planned to ship no `tests/`, deliberately), a published
    package's `goblin.js` and its bash payload could
    drift apart with nothing in the shipped artifact noticing. The engine has no self-check row
    that reads its own `--version` against a manifest record, and adding one would make the
    version a rule — which is a real option, not done here. Until then the guarantee is
    development-time only: green in this checkout, unverifiable in the wild.

45. **Cut in v3: the `gob upgrade` migration.** The 0.4.4 per-repo → global-engine migration is
    removed; `init --write` re-pins a repo in place. The crash-safety limitation it carried (its
    safety was sequence-ordered, not journalled) retires with the command.

46. **Cut in v3: the platform-emit surface.** The adapter tree and the emit engine are gone; no
    per-platform skills or context blocks are emitted; the harness stays repo-neutral. The
    unsigned, hand-editable emitted-config limitation retires with the engine.

47. **Cut in v3: the adapter conventions.** The seven near-duplicate adapter verify/detect
    scripts are gone with the platform-emit surface; the neutral harness plus the core skills
    carry the per-platform story now.

48. **`SP-01`'s rule text once overclaimed; it now states the check's actual scope.** The text
    used to read "The current round has a SPEC" while the check is
    `ls ./*-SPEC.md >/dev/null 2>&1`, which passes on ANY spec-shaped file at the repo root. The
    measured consequence: a fresh class-A install ships the scaffold's `ROUND-000-SPEC.md`, and
    `SP-01` PASSes on that scaffold alone — no round is open, and the row is green anyway. A stale
    spec from a finished round keeps satisfying the row exactly as well as a live one, because the
    check has no notion of "current". **Fixed in W6 (text, not check):** the row now reads
    "A *-SPEC.md file exists at the repo root (any round, not the current one - round-scoping
    arrives with the W6 staged chain)" — manifest and `docs/ENFORCEMENT.md` re-rendered in the
    same commit, the check cell untouched. What it costs: the SPEC-exists signal in a run summary is
    weaker than a round-scoped claim would suggest — read it as "a `*-SPEC.md` file is present", not "this round's spec is
    here". Measured: `goblin-verify` on a fresh probe install reports `PASS SP-01 (ls
    ./*-SPEC.md >/dev/null 2>&1)` with `ROUND-000-SPEC.md` the only file the glob sees, and the
    same PASS after renaming it to a non-round name. **Ticketed, not gated:** "current round" is a stage-order notion, and the W6 staged workflow chain (SC-01:
    a SPEC committed before the changes it governs) is what gives the word meaning; the staged
    chain's stage-order rows are what will make round-scoping REAL — the reword names the
    boundary until then.

49. **The engine footer prints to captured stdout, and a script parsing `goblin-verify` output
    must expect it.** The two-line footer (`engine: mode=… cli_sha256=… enforcement_tsv_sha256=…`)
    is unconditional `printf` output — there is no isatty guard, by design, so a captured run still
    names the engine that judged it (that is the point of #43's statement). The cost is parser
    friction: a script that treats every stdout line as a verdict line trips on the banner and
    footer lines, which are not `PASS`/`FAIL` rows. The contract is the EXIT CODE, never the line
    set: 0 green, 1 red, 2 refuse — parse the exit code, or filter to `^[A-Z]{2}-[0-9]{2}` before
    reading lines. Measured: `./.goblin/bin/goblin-verify > out.txt` on a probe install puts
    `engine: mode=vendored cli_sha256=… enforcement_tsv_sha256=…` in the captured file
    (`tests/t-engine-dir.sh` itself asserts the footer IN captured output, so removing it or
    tty-gating it would break the engine's own suite). Recorded so the pitfall is findable from
    this file; no change to the engine is implied or wanted.

50. **`CM-01` reads only the most recent commit — historical commits with a wrong identity pass
    unseen. Current stated scope: the row gates the identity of HEAD at the moment of the run,
    and nothing older; that is the row's whole claim, by design.** The check is
    `test "$(git log -1 --format='%ae')"` against the configured
    `owner_email`, so it gates the identity of HEAD at the moment of the run and nothing older.
    Measured: a probe history `owner → wrong@old.co → owner` reports `--only CM-01` clean (exit 0)
    with the wrong-identity commit sitting one below HEAD. That is consistent with the
    gate-at-the-moment design — every row judges the tree and history as they stand when verify
    runs, and retrofitting an identity sweep over `git log --all` is a policy change, not a bug
    fix — but it should be named: the row's green means "the latest commit carries the owner
    identity", never "no commit in this repo's history carries an ambient one". A wrong-identity
    commit that has since been followed by correct ones is invisible to every run. Recorded as a
    boundary; no row change implied. `docs/ENFORCEMENT.md`'s CM-01 row carries the same one-line
    scope statement.

51. **`gob init` writes its three added values into `goblin.yaml` itself, not through a
    template.** Install renders `.goblin/goblin.yaml` from `templates/goblin.yaml.tmpl` and
    owns it (`put_once`: never rewritten after the first install) — and install correctly
    carries no `--branch/--email/--gate` flags, because those keys are the project's to edit.
    The wizard therefore `sed`-patches `branch:` and `owner_email:` and rewrites the first
    gate's `cmd:` line right after install renders the file, fail-closed: the gate must read
    back through the engine's own `g_yaml_gates` or the run stops. The cost is a second
    writer for exactly those three lines: a hand-customised comment placement survives, but a
    future template change to those lines' shapes (renamed keys, a multi-gate default) must
    be mirrored in `bin/goblin-init`. The wizard never rewrites anything outside the declared
    keys, and a re-run after a hand edit of another line leaves that line alone. Recorded as
    a boundary; the alternative — teaching install three wizard-only flags — would put wizard
    vocabulary into the installer's contract for no gain.

52. **`scope:source` and `scope:target` name WHOSE burden a row carries — the framework's or
    the adopting repo's.** `scope:source` is goblin-stack's own proof burden: those rows
    (`PR-01`..`PR-05`) are the framework testing ITSELF while it is being developed — they run
    in this repo, under `tests/run-tests.sh`, and a dev of goblin-stack is the one who owes the
    run. `scope:target` is the adopting repo's proof burden: those rows run in an installed
    repo via `goblin-verify`, and the repo's owner owes the run. Same matrix, two creditors:
    a source row can never fail a user's repo, and a target row can never substitute for the
    framework's own suite. Recorded as a definition; `docs/ENFORCEMENT.md`'s scope paragraph
    carries the same sentence for the reader who arrives there first.

53. **The sixth class is gone: the desktop shell is `software` + `electron: true`, and `A`..`E` are
    read-time aliases.** W6 merged `F` into `software` because their `manifest/classes.tsv` need
    columns were measured identical on all ten parts — the old column added config (the electron
    `bans:`, the `perf.host_gate:`, the `app_bundle_bytes` ratchet, the `dist out release`
    build-output scope), never a part. Measured on the merge tree (2026-10-02): the tsv is 50 rows
    over five classes; `gob init --class desktop`, `--class F` and `--class software --electron`
    render byte-identical `goblin.yaml` (`class: software`, `electron: true`); and a pre-merge repo
    carrying `class: F` with no `electron:` key verifies unchanged, `38 passed, 0 failed, 11
    advisory, 33 skipped`, exit 0, with `git status --porcelain` empty — zero writes, because its
    bans and host gate live in its own config. What this costs, recorded rather than fixed: such a
    repo gets the merge's declaration-time host-gate check only after hand-adding `electron: true`;
    its bans and host gate keep running either way, so nothing fails closed, and the CLI keeps
    accepting `desktop`/`F` as aliases.

54. **The vendored engine wins over a global `engine_dir` by design, and in v2 that is the
    whole story.** The resolution chain (goblin-verify §"engine resolution") puts
    `$ROOT/.gob/...` at stage 2 and a declared `engine_dir:` at stage 3, so a repo carrying
    BOTH judges itself with the vendored manifest — the thing `IN-02` hashes — and never with
    the global one. That is not a leftover: the pre-v2 hazard (a machine-level upgrade
    silently re-judging repos through a shadowing global engine) is closed the same way the
    pin closes silent re-pinning — the rules a repo is judged by must be the rules its own
    install record hashes, and any change to them is a diff the repo owner reviews. The
    corresponding suite (`t-engine-dir.sh`) is deleted with the v2 surface cut rather than
    migrated: v3 ships no command to move a global engine under a repo, and the
    global-engine lane itself is session-2/3 scope — when it returns it returns re-measured
    against the AGENTS.md frontmatter shape.

55. **CI is out of the v2 product, and `docs/CI.md` is its LIMITS candidate, not a kept promise.**
    v2 installs nothing under `.github/` — the `ci-gate` part carries `-` for every class in
    `manifest/classes.tsv` (kept as the recorded W4 remnant), `PG-05`/`PG-06` SKIP with no
    workflow to read, and no flag configures the lane. The file that carried the lane's contract
    (`docs/CI.md`: the four forge settings that make a workflow a gate, the Electron perf
    deviation) still exists in the checkout as REFERENCE — the argument it makes ("a required
    check that reports Success after skipping its gate is a green light for a commit whose gate
    never ran") is about CI in general and survives the cut — but no document the README's table
    promises sends a reader there, and the lane returns with the CI surface in a later alpha or
    not at all. What this admits: the verifier's "cannot see" footer still names the CI lane's
    blind spots, for the day the lane comes back re-measured.
