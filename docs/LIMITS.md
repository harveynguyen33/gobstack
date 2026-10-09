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
4. **Fifteen playbooks against twenty-three.** The cuts in `docs/GUIDE.md` are deliberate and each
   is argued, but real coverage is lost: performance hillclimbing, pixel parity, trace
   forensics, stack landing, worktree hygiene.
5. **No swarm or arena fan-out.** The read-versus-write axis says that is correct for this work
   mix; it is still a capability the other harness has and this does not.

## Weaker than the status quo it is meant to improve

6. **The biggest measured defect is out of reach.** The orchestrator's routing text says a bare
   subagent spawn reaches the specialist profiles; it does not. That is the highest-cost defect
   on the box, and goblin-stack cannot fix it from inside a project repo. It ships corrected
   text in `docs/GUIDE.md`; the fleet-side edit is
   escalated.
7. **The staleness of a fleet-config repo is detectable and not fixable here** — an artifact-scoped gate
   notices it, and the underlying job bug belongs to another repository.
8. **A new surface to maintain.** Per-repo vendored `.gob/` plus `.hermes/skills/` means
   upgrade debt in every adopted repo, plus one more command pair to learn. The counter is that
   the alternative — profile copies — already failed.
9. **Six rows are labelled `advisory`, and all six are prose with no check at all:**
   `HP-04`, `HS-03`, `CM-02`, `DOC-01`, `DOC-02` and `SC-09`. Each is counted and capped, but a
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
    the `AGENTS.md` gob block DECLARES and skips the template's own example sentence, so a real gate
    line can no longer lose its `measured <date>` in silence (G8-2 measured the old row passing
    exactly that); but nothing re-measures the number, and a gate-bearing line that names no
    declared gate and carries no gate-shaped keyword is still unseen.
13. **Cut in v3: the CI lane (`PG-04`, `PG-05`, `PG-06`, `docs/CI.md`).** The workflow reader is
    gone: no `.github/workflows` payload is shipped, no row reads a workflow, and the doc that
    argued the forge settings is deleted. What the lane could never see — the required-check list,
    the bypass switch, the push identity, whether the job ever ran — is recorded here and in
    `README.md` K7/K18, not solved.
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
    generated skill to `P12` before any `verified:` date advances (`README.md` K15).
    **`P12` is still the mechanism to find out, and it has still never been run**: the record format
    is now specified (`skills/goblin-eval/SKILL.md`) and **no row reads a lane** (#31).
    Pin: `https://www.skillsbench.ai/blogs/skillsbench-1-1`, sha256 of the retrieved page
    `d812bb7c2da702cc67556eb5f46b9e93faaca19d3545376544866e940126ef15`, fetched 2026-09-25; the
    eleven-token ban and the grading procedure are argued in
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
18. **`.gob/installed.json` is not signed, so nothing here proves it was not rewritten.** Every
    drift check — `IN-02`, `SK-02`, and `HS-01`'s hash of the harness dir — reads its expected
    hash out of that one file, and that file is the one file no check protects. Measured: append a
    byte to `.gob/bin/goblin-verify`, rewrite its recorded hash in `installed.json`, commit, and
    the run is **fully GREEN** (`14 passed, 0 failed`, exit 0). One edit defeats three rows at
    once, and it is the cheapest way to fake a green run. Doing better needs an anchor the target
    cannot edit — a signature, or a hash held outside the repo — and goblin-stack has no such
    trust root: the source checkout is not guaranteed to exist at verify time, and any value
    stored in the tree is editable by the same hand. It is therefore **recorded here and printed
    in the "cannot see" footer on every run**, not claimed away.
19. **Cut in v3: the automation producers.** `automations/` (the drift-audit and bugreporter cron
    producers), their `AU-01`..`AU-04` rows and the cron walkthrough are removed. Their cost per
    run and the respawn guards were never measured against a real board here, and the producer's
    own ceiling was a **run count**, not a dollar figure.
20. **Cut in v3: the automation dedup key.** The content-only dedup contract (`AU-02`) retired
    with the producers that wrote the key; a project that runs its own intake keeps the
    `--idempotency-key` dedup on the board side.
21. **Cut in v3: the reporter normalisation.** `AU-02`'s synthetic-only normalisation measurement
    retired with the row and the producers.
22. **Cut in v3: the dependency-audit lane.** `goblin-audit`, `SC-07` and `SC-08` are removed —
    the deliberate network-shaped audit and the lockfile install-hook reader are gone.
23. **Cut in v3: the audit-record parse (#22's lane).** The field-name reader and its
    refuse-unparseable (exit 5) contract retired with `goblin-audit`.
24. **Cut in v3: the freshness date parse (#22's lane).** The GNU `date -d` dependency retired
    with `SC-07`.
25. **`SC-04` reads one statement, not one program.** A cookie write spread over three lines (or
    assembled through a helper) is not seen, and the row says so in its own cell.
26. **The advisory slots are a count, not a strict bound.** Measured (v3): 0 advisory rows in the
    default matrix at a ceiling of 10 (all six moved to the library), so `SK-03` reports
    `advisory 0 of ceiling 10 (10 free slots)`. A row is advisory
    if its `check` cell says so OR its `enforced_by` cell does; the cap is a count — 10 advisory
    rows at a ceiling of 10 **pass**, and the 11th FAILs (10 at a ceiling of 9 FAILs). The v3 cuts
    (the dependency-audit and CI rows) returned the slots earlier advisory rows had spent, so the
    next author who wants an advisory row has room — and, once it is full again, must raise
    `advisory_ceiling` in the same change and write down why rather than discovering the cap from a
    red run. This is not a rule change; it is the arithmetic the ceiling was always meant to force
    into the open.
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
32. **Withdrawn (v3).** The judge lane and loop record this item measured were removed in the
    model/role/loop cut; the numbering is kept stable for the cross-references below.
33. **Withdrawn (v3).** Same cut: `LP-*` and `JG-*` no longer exist.

## What the harness refuses to do

It does not claim a green run means the work is right. `goblin-verify` asserts that the installed
files are the files on disk, that every rule with a command still passes, and that the
untestable remainder is counted and capped — and it prints, on every single run, what it cannot
see: the five upstream blind spots, plus the ban lane's own (the unsigned ban table #28, the
text-probe gap #27, and a ban that is invisible until verify runs, `V3-1`), plus the CI lane's (#34: a file is not a gate —
the required-check list, the bypass switch and the push identity are forge state; #35: the
Electron perf number is a host gate, and the ratchet deliberately carries a different metric).

27. **The ban probes are text probes, not ASTs.** `BN-01`, `BN-02`, `BN-03` and `BN-05` are
    `grep` over source under `bash`/`grep`/`awk` only — the dependency contract in
    `docs/GUIDE.md` allows no parser and no `npm`. So a `: any` inside a string or a comment
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
    rows were weakened, because `.gob/manifest/bans.tsv` is hashed by `IN-02` and
    `.gob/installed.json` is not signed (`docs/LIMITS.md` #18). The ban list is not
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
34. **Cut in v3: the CI lane reads files, and a file is not a gate.** The shipped
    `goblin-gate.yml` template and the `PG-05`/`PG-06` readers are gone. The limit the lane named
    stands as a fact about CI in general: nothing in a repository can make GitHub **require** a
    workflow, and the required-check list, the bypass switch and the push identity are forge state.
    A project that runs CI wires its own workflow; the harness ships none, and none of its rows
    read one.
35. **The Electron perf number is a host gate, and the ratchet carries a different metric.**
    The (now removed) Electron preset declared `main_thread_busy_pct` as `perf.host_gate:` and used
    `app_bundle_bytes` for `ratchet:` — a **deliberate deviation** from G6 §B.3, which put the FPS
    number in the ratchet. The instrument that produces it (CDP `Performance.getMetrics`, or
    `app.getAppMetrics()[i].cpu.percentCPUUsage` inside a real Electron) needs Playwright or
    Electron plus a GUI, and a shipped rule may use nothing but bash/git/awk/sed/grep/python3
    (`docs/GUIDE.md`) — so `ratchet.cmd` pointing at the probe would make a fresh install
    **born RED**, which is the one thing the install path must not produce. The probe belongs to
    the project; a project whose CI needs npm runs it in **its own** workflow. What the number
    means has a limit of its own, and it is measured: this box is an LXC with no display and no
    system Chromium, so the G6 sweep came from a *bundled headless* Chromium with no compositor
    and no vsync. Relative comparisons on one machine are meaningful (which is why
    `main_thread_busy_pct` works at all, and why frame time does not — p50 stayed flat at 16.70 ms
    while the main thread went from 1.8 % to 54.5 % busy, the W4 sweep); an absolute FPS
    claim is not. Three further Electron failure modes are **recorded, not mechanised**: the
    dependency-graph boundary check, `ipcMain` sender validation,
    and fuses at package time. **Cut in v3:** the class presets and the `electron` overlay are
    gone; an Electron project declares `perf.host_gate:` and lists the electron bans (`BN-06`..`BN-09`)
    in its own `bans:` — the bans ride on their `applies_when` glob, not on a class.
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
    `.gob/`, `.hermes/`, the declared `harness_dir` and the map's own directory, so a stub map
    whose token occurs only in the install no longer resolves (W5-4: `entry_paths: [export]` used to
    "resolve" to `./.gob/bin/goblin-verify`). It does **not** exclude the target's own `docs/`,
    `tests/` or build output: a token that occurs only there still reads as resolved, and excluding
    them would be a guess about a layout goblin-stack does not know. Nor is there a frequency bound
    — a common token ("export", "main") is satisfied by the first of hundreds of files.
38. **Withdrawn (v3).** The judge-lane model comparison this item measured was removed in the
    model/role/loop cut; the numbering is kept stable.
39. **Withdrawn (v3).** Same cut: `LP-*` no longer exist.
40. **A fresh install into a repo with no commits is born RED, and X1 did not change that.** Measured
    at X1: `goblin-install` into a `git init` with zero commits, then `goblin-verify`, gives
    a fresh install into a repo with no commits is born RED — `HP-05`, `SP-02`, `GT-02`,
    `CM-03` and others read a HEAD that does not exist yet. The install never creates the seed
    commit (`bin/goblin-install` writes files and stops), and it must not: a tool that commits into
    Harvey's repo on first contact is the overreach `docs/GUIDE.md` rules out. Carried from W5
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
      - item 8 — `SC-05`'s `.gob/boundary-waivers`: the file is copied and both FAIL directions
        are controlled; the *honoured* direction is not.
      - item 10 — `SC-03` clause 2, `sec_build_output`: a literal in `dist/assets` FAILs; only the
        clause-1 path is controlled.
      - items 11, 12, 15 — `scaffold_checks:`'s SKIP branch, `perf_host_gate` (#35) and
        `templates/*.tmpl`: declared no-ops (SKIP, a host gate). A control here would assert that
        nothing happens.
      - item 13 — the cut CI lane's flow-style `jobs: {…}` refusal: it failed closed already, and
        the lane is gone, so no control is owed.
    **W5-10 is answered here too.** The tenant strings `PT-01` forbids do not reach `docs/`, because
    `docs/` is never installed: the row's directory list is `skills manifest bin templates`
    .gob .hermes`, so a string under `docs/` is source-tree prose that no operator's repo ever
    receives. That is the whole reason, it is deliberate, and the row is not weakened by it — Y1
    agreed, and Z1 leaves it. This is the sentence Z1 added so the reason is visible in the shipped
    artifact rather than only in the wave's own notes.

42. **The doc walk cannot read a path broken at the directory/name boundary.**
    `tests/t-doc-promises.sh` reads a command directory only as `.gob/bin/` or `bin/` **with its
    trailing slash**; when a line ends on the bare directory (`.gob/bin`, `bin`) and the slash
    leads the next line (`/goblin-verify`) or is dropped (`goblin-verify`), the directory and its
    continuation are both invisible — the first fragment stops before the name the grammar needs, the
    second is not preceded by `bin/`, so neither is a token and neither is asserted. Measured
    2026-09-26 (AB7): a plant of that form is reported **`PASS`, rc 0**, mentioning
    the plant **zero** times, and a line that ends on the bare directory with nothing after it is
    silent too, because the `dangling()` guard needs the trailing slash as well. **0 live instances**
    — measured: `grep -rnE '\.gob/bin$|bin/$' $(git ls-files)` → **no output, exit 1**. **What it
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
    measured consequence: a fresh default install ships the scaffold's `ROUND-000-SPEC.md`, and
    `SP-01` PASSes on that scaffold alone — no round is open, and the row is green anyway. A stale
    spec from a finished round keeps satisfying the row exactly as well as a live one, because the
    check has no notion of "current". **Fixed in W6 (text, not check):** the row now reads
    "A *-SPEC.md file exists at the repo root (any round, not the current one - round-scoping
    arrives with the W6 staged chain)" — manifest and `docs/GUIDE.md` re-rendered in the
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
    reading lines. Measured: `./.gob/bin/goblin-verify > out.txt` on a probe install puts
    `engine: mode=vendored cli_sha256=… enforcement_tsv_sha256=…` in the captured file
    (`tests/t-engine-dir.sh` itself asserts the footer IN captured output, so removing it or
    tty-gating it would break the engine's own suite). Recorded so the pitfall is findable from
    this file; no change to the engine is implied or wanted.

50. **Cut in v3: the owner-identity and declared-branch rows.** `CM-01` (commits carry the owner
    identity) and `PT-02` (the default branch is declared, not assumed) are removed, with their
    `owner_email:` / `branch:` config keys. The gate reads git directly, so neither is worth
    asking a human for: a verify run that needs the current branch or the commit author can read
    both from `git`. The old `CM-01` limit — it gated only the identity of HEAD, so historical
    commits with a wrong identity passed — is recorded here rather than mechanised, and `GT-03`'s
    freshness check still reads HEAD's reflog.

51. **`gob init` merges its proposal keys into the `AGENTS.md` gob block itself, not through a
    template.** Install renders the `AGENTS.md` gob block from `templates/AGENTS.md.tmpl` and
    owns it (`put_once`: never rewritten after the first install), and install carries no
    `--gate`/`--feature-map` flags, because those keys are the project's to edit. The wizard
    therefore merges the proposal's first gate (and its `feature_map:`) over the installer's
    default keys right after install renders the file, fail-closed: the gate must read back
    through the engine's own `g_agents_gates` or the run stops. The cost is a second writer for
    exactly those keys: a hand-customised comment placement survives, but a future template
    change to those lines' shapes must be mirrored in `bin/goblin-init`. The wizard never
    rewrites anything outside the declared keys, and a re-run after a hand edit of another line
    leaves that line alone. Recorded as a boundary; the alternative — teaching install
    wizard-only flags — would put wizard vocabulary into the installer's contract for no gain.

52. **`scope:source` and `scope:target` name WHOSE burden a row carries — the framework's or
    the adopting repo's.** `scope:source` is goblin-stack's own proof burden: those rows
    (`PR-01`..`PR-04`) are the framework testing ITSELF while it is being developed — they run
    in this repo, under `tests/run-tests.sh`, and a dev of goblin-stack is the one who owes the
    run. `scope:target` is the adopting repo's proof burden: those rows run in an installed
    repo via `goblin-verify`, and the repo's owner owes the run. Same matrix, two creditors:
    a source row can never fail a user's repo, and a target row can never substitute for the
    framework's own suite. Recorded as a definition; `docs/GUIDE.md`'s scope paragraph
    carries the same sentence for the reader who arrives there first.

53. **Cut in v3: the class taxonomy and the presets.** The five class names (`software`,
    `service`, `game`, `research`, `fleet`), the `A`..`E` letters, the older `app`/`agent`/`desktop`
    aliases, the `presets/` yaml files, `manifest/classes.tsv` and the `--class` / `--electron`
    flags are all removed. A class only ever selected which parts were required and which bans ran;
    the parts default on (opt out by name with `--opt-out`), and a ban self-selects by its
    `applies_when` glob. The installer renders ONE default config block; there is no taxonomy left
    to render it from, and no reader has to choose a category before installing.

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

55. **CI is out of the product, and its reference doc is deleted.** The install writes nothing under
    `.github/` — the `ci-gate` part is off — and the `PG-04`/`PG-05`/`PG-06` rows are cut. The doc that carried
    the lane's contract (`docs/CI.md`) is deleted with them; the argument it made (a required
    check that reports Success after skipping its gate is a green light for a commit whose gate
    never ran) is about CI in general and is preserved in this entry. What this admits: the
    verifier's "cannot see" footer still names the CI lane's blind spots.

---

## The guard rails — the security and perf rows

`manifest/enforcement.tsv` is the machine-readable form; this is the prose for the ten rows it
gained in v0.2 (`SC-01`..`SC-09`, `PF-01`). Every one of them is **declared** in
the `AGENTS.md` gob block under `security:` and `perf:` - a stack-specific rule guessed from the
files on disk is how a matrix starts lying, so nothing here infers a stack.

### The rung ladder, and the rule for choosing a rung

    (a) lint rule / static check  >  (b) script gate  >  (c) CI job  >  (d) runtime check  >  (e) prose

The rung is chosen by **what can observe the failure**, not by what is cheapest to write, and the
rung below must be *demonstrably unable* to see it - the reason is recorded in the row's
`if_not_why` cell. Three constraints shaped the design, and all three are pre-existing:

1. **No network at verify time.** `README.md` K4: a network call at verify time breaks the
   offline dependency contract. A row that needs the network is not a verify-time row.
2. **`enforced_by` is a closed enum** (`script`, `lint`, `gate`, `advisory`) and `check` is one of:
   a real command, the literal `advisory`, or `goblin-verify --only <ID>` for a multi-line body.
   Every row here obeys that, and `IN-03` fails the manifest otherwise.
3. **`advisory_ceiling` is 10 and the labelled count is 0.** The matrix labels no row
   `advisory`, and the ceiling caps that count at **0 of 10** — every advisory row moved to the
   library (off by default), so a default run spends no slot. **Corrected 2026-10-10 (v3).** Nothing else in this lane is
   prose dressed as a check.

### T1 - secrets and the config surface (`SC-01`..`SC-04`)

All four are rung (a)/(b): one shell line or a small builtin, and all four are RED-able.

| row | what it proves | how it proves it |
|---|---|---|
| `SC-01` | no secret file is tracked | `git ls-files` over the `.env`/`.pem`/`.key` family (`.example`/`.sample`/`.template` excluded) |
| `SC-02` | the ignore rules cover the **whole** family | clause 1 reads `.gitignore`; clause 2 asks git's own matcher, `git check-ignore -q`, once per path - a rule that looks right but does not match still fails |
| `SC-03` | no client-visible name is secret-shaped, and no build output carries a secret literal | the `NEXT_PUBLIC_*_(SECRET\|TOKEN\|KEY\|PASSWORD\|PRIVATE)` name pattern over source, then known secret prefixes (`sk-`, `ghp_`, `AKIA`, `eyJ`) over `security.build_output` |
| `SC-04` | every cookie write carries its flags | `document.cookie =` needs `secure` + `samesite` in the same statement; `cookies().set(` / `res.cookie(` need `httpOnly` + `sameSite` |

`SC-02` ships a real control rather than being assumed, because the honest baseline is GREEN: a
fresh install writes the family into `.gitignore` (`sec_gitignore_family: yes`), and the control
proves the row would notice the day a hand edit narrows it.

**A JS-written cookie is readable by any script.** `SC-04` *reports* that; it does not fail on it.
That is a design fact about the product, not a bug, and a matrix that failed on it would be wrong
about the thing it was measuring.

### T2 - input boundaries and dependencies (`SC-05`..`SC-06`)

| row | what it proves | the limit it states |
|---|---|---|
| `SC-05` | every write route calls a validator, or is waived | it proves a validator is *called* (`safeParse\|zod\|valibot\|yup\|ajv\|superstruct\|validate(`), never that the schema is right - a schema that accepts everything passes |
| `SC-06` | a lockfile exists and is tracked | it cannot see that the lockfile is *stale* relative to `package.json`: resolving that needs the package manager, which is a deliberate network-shaped step |

### T3 - the performance budget (`PF-01`, plus the ratchet)

The budget **is** `GT-04`/`GT-05`, unchanged: `ratchet.name` is the metric, `ratchet.cmd` is the
one command that produces it, `ratchet.ceiling` is the measured baseline, and `GT-05` prints
`old <n> + <delta> new = <n>` when the number rises. **No second mechanism, no new key for the
number.**

| project shape | metric | command | hermetic? |
|---|---|---|---|
| web app (Next) | total client JS bytes | `find .next/static -type f -name '*.js' -exec cat {} + \| wc -c` | yes |
| SPA (Vite) | bundle JS bytes | `find dist/assets -type f -name '*.js' -exec cat {} + \| wc -c` | yes |
| component lib | published bytes | `find dist -type f -exec cat {} + \| wc -c` | yes |
| service/config | own build bytes, plus host latency | `find dist -type f -exec cat {} + \| wc -c` · `curl -w '%{time_total}'` | size yes, latency **no** |
| game | build bytes, plus host frame time | as web app · Editor run | size yes, frame time **no** |
| none declared | none | - | - |

`find ... -exec cat {} + | wc -c` is used rather than `du` because `du` reports block sizes and is
not deterministic across filesystems. Raw bytes are the *reported* number and are the only one
that is ratcheted: a gzip figure changes with the compressor, so it is a report, never a ceiling.

**The default config ships this metric** (`client_js_bytes`), and the TODO count that used to be
the ratchet moved into a **gate** (`todo_ceiling`, `-le 160`): a shipped-software round is
supposed to move the perf number, and the TODO ceiling is a floor against decay, not the budget.
A fresh install measures `0` for a repo with no build output, so the number is honest from the
first commit and gets re-anchored deliberately.

**Re-anchoring is deliberate, never automatic.** When a round legitimately raises the number, the
operator re-runs the command, writes the new `ceiling`, and writes the matching
`perf.baseline_value`/`baseline_commit`/`measured`. `PF-01` is the row that stops "I raised the
ceiling" from silently becoming "I never measured again": a baseline whose commit does not resolve
to an ancestor of `HEAD` is a RED.

`PF-01` **skips with a reason** when no metric is declared (`perf.metric` empty) or when no
baseline has been recorded yet - because a row that is RED on every fresh install teaches people
to ignore it. The skip names the command to run.

### What this lane cannot see

- **A local byte count is not a real user's device.** It says nothing about parse/execute time on
  a mid-range phone, a cold cache or a slow network - and nothing about what the bytes do. A
  700 KB bundle that does nothing is better than a 200 KB one that blocks the main thread.
- **Frame time, idle CPU, memory growth and latency are host gates**, named as such in
  `perf.host_gate` and in `gates:` - never hermetic ratchets.
- **A perf budget cannot see a layout thrash or a re-render per keystroke.** Only a frame-time
  measurement can, and that is a host gate.
- **No automation has ever run against a real board here.** Cost per run is unmeasured.
