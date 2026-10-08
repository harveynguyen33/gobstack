# Changelog

One line per released version. `goblin-install --upgrade` prints the delta between the
version recorded in a target's `.goblin/installed.json` and the source `VERSION`.

## 0.6.0-alpha.1

The v2 breaking release: rules-first. The rules a repo is judged by move from a config file the
installer generated into the file a new session already reads, the folder the engine is vendored
into gets a name that cannot collide with the global one, and every command a reader could not
reach is cut from the surface rather than shipped half-wired. Nothing here is additive — a repo
on 0.5.x does not silently keep working through this version; run `gob init` again in the repo.

- **`goblin.yaml` is gone. AGENTS.md frontmatter is the single source of truth.** The gates, the
  bans enablement and the model mapping all read the frontmatter block of the root `AGENTS.md`
  (flat `gate_<name>_cmd:` keys beside the prose a teammate reads anyway). There is no second
  config file to drift out of sync with the prose, and the file a new session reads first is the
  file the rules live in. `gob init` prints the agent brief plus a proposal schema and the agent
  fills the frontmatter; `--write` installs the validated result.
- **`.goblin/` is renamed `.gob/`.** The vendored engine payload (`.gob/bin/`,
  `.gob/manifest/`, `.gob/installed.json`) sits one level deep under a short name, and the
  global `~/.goblin` tree no longer shares a prefix with it.
- **The CI lane is cut.** No shipped workflow file, no CI toggle in the config — the gate hook
  and `gob verify` are the enforcement paths.
- **The surface is six verbs: `init`, `map`, `verify`, `bans`, `mcp`, `uninstall`.** The dispatcher
  refuses everything else with exit 2 — `doctor`, `audit`, `upgrade`, `emit`, `sync` and
  `install` are unwired (their code is deleted or unreachable; see `docs/LIMITS.md` #54 for the
  engine-dir decision the upgrade command used to serve). `gob init` replaces `gob install`
  entirely.
- **npx-first, no global install.** The documented entry is
  `npx @techgoblin/gobstack init`; `uninstall` is the npm one-liner. Nothing asks for `-g`.
- **Remedy per FAIL.** A `FAIL` row prints its one-line `remedy:` at the point of failure and
  again under the summary payload, so a red run says what to do next without a docs trip. The
  mascot sign-off is a GREEN-run line only: a red run ends on
  `start with the first FAIL above — its remedy line says the fix.` — the verdict IS the FAIL
  list, and mascot noise on the run's one actionable moment is noise.
- **Framed for the new teammate.** The docs lead with what a person joining the repo reads
  first (`AGENTS.md`, `HANDOFF.md`), not with the toolchain that maintains them.

`VERSION`, `package.json` and all six `GOBLIN_*_VERSION` constants in `bin/` are this version.
No id, verdict or matrix cell moved in this release; the counts the docs quote are the ones
measured on this tree.

## 0.4.4

The five findings an independent verification of 0.4.3 left open (AB3). The blocker is the species
this campaign keeps meeting: a false statement about the artifact's own enforcement, written into the
guide **while** the wave that fixed five of the same kind was landing. No row was added, moved or
re-labelled — `advisory` stays at **10 of 10**, and `manifest/enforcement.tsv` and
`tests/t-verify-red.sh` are untouched, so the census cannot drift.

- **`docs/GUIDE.md` §8's rule sentence was false (AB3-1, the BLOCKER).** It said `IN-02` "hashes
  **every file the installer wrote**". Measured on a fresh class-A install: the installer writes
  **50** files and the row's `files` map covers **40** — ten sit outside it, including
  `.goblin/goblin.yaml`, the file §5 step 3 tells the reader to edit. Editing all ten at once still
  printed `PASS IN-02 40 installed files hashed` rc 0, so a reader who followed §5 and then §8 would
  watch REPLAY "confirm" a check that never moved. The sentence now names the 40, the 8 it `owns` and
  `.goblin/installed.json`, and points the exercise at `.goblin/bans/README.md`.
  `tests/t-doc-guide.sh` asserts the count the guide quotes equals the `files`-map length of the
  install it made, and that the universal is gone — both RED at `58a6fe6`.
- **The 9/10 in `docs/GUIDE.md` §11 was unversioned.** It presented a previous revision's score as
  "the current status" in a file stamped `0.4.3`, so the next pass made it false in silence. The
  sentence now carries the revision it was measured at (`0.4.2`, where AC1 measured 9.0), and
  `t-doc-guide.sh` reads it — RED at `58a6fe6`.
- **Two more live copies of the stale 9-of-10 advisory arithmetic.** `docs/GUARDRAILS.md`'s third
  design constraint carried the count with no dating at all; `docs/LIMITS.md` #26 said `SK-03`
  "reports that arithmetic **on every run** (`advisory 9 of ceiling 10 (1 free slot)`)" while the run
  prints `advisory 10 of ceiling 10 (0 free slots: the next advisory row FAILs)`. Both now state the
  measured value and date the correction, and `tests/t-doc-sync.sh` reads the two LIVE copies — RED at
  `58a6fe6` — while the dated history (the CHANGELOG entries, `docs/ENFORCEMENT.md`'s chronology,
  `t-verify-red.sh`'s pre-change note) keeps its own tense and is not read.
- **`CHANGELOG.md`'s 0.4.0 census is annotated, not rewritten.** It claimed "**105** controls and
  **19** `expect_green` — **124**", a figure that matched no tree even when it was written: 0.4.0's
  own tree (`63d62d2`) measures **112** + **22** = **134**, and the tree at 0.4.3 measures **121** +
  **28** = **149**. The released numbers stand and carry a dated correction beside them.
- **`VERSION` is `0.4.4`** — `VERSION`, the five `bin/` version constants and this entry agree. No
  logic changed in `bin/`, and no id, verdict or matrix cell moved.

## 0.4.3

Five defects an independent verification of 0.4.2 measured, and all five are the same species: a
sentence in a reader-facing artifact that a measurement contradicts. Four are prose, one is a row
that stayed GREEN under its own violation. No row was added, moved or re-labelled — `advisory` stays
at **10 of 10**.

- **`docs/GUIDE.md`'s only hands-on REPLAY exercise was false as written (D1, the BLOCKER).** §7 and
  the appendix both told the reader `git stash && .goblin/bin/goblin-verify --only GT-02 # expect
  FAIL`, and `GT-02` runs the gates the config declares (`commit`, `todo_ceiling`), whose exit status
  a stash cannot change: measured on the shipped class-A configuration, `PASS` rc 0 before, during
  and after — the guide taught the lesson backwards. The exercise REPLAYs `IN-02` now, the row that
  hashes the files the installer wrote: break one, watch the row go `FAIL` rc 1, put the file back,
  watch it go `PASS` rc 0. The restore is path-limited (`git stash push -- <path>`) so it cannot
  swallow the uncommitted `.goblin/goblin.yaml` edit step 3 leaves behind, and both copies carry the
  same block between sentinels.
- **`docs/GUIDE.md` had no control at all, which is how four false sentences survived in it (D1's
  cause).** `grep -rn GUIDE tests/*.sh` was **0** hits before this release. `tests/t-doc-guide.sh`
  now extracts the guide's own exercise and RUNS it — every `goblin-verify` line must do what its
  `# expect PASS|FAIL` annotation promises, verdict and exit code — and re-measures the guide's own
  numbers on a fresh class-A install (`created 49` against **50** files on disk; the day-one and
  green-path summary lines). RED on `d5424be`.
- **`GT-03` was GREEN under its own violation (D2).** Its freshness clause compared the gate line
  with `$(git rev-parse --git-dir)/HEAD`, and `.git/HEAD` is rewritten by **branch operations, never
  by a commit**: measured, its mtime was unchanged across a real commit and `--only GT-03` stayed
  `PASS` rc 0 while the round had moved on. The clause reads HEAD's **reflog** (`.git/logs/HEAD`) now,
  which a commit rewrites in an attached *and* a detached worktree and whatever the refs' packing
  state; the row's `—` why-cell became the two limits that remain (a disabled reflog passes
  vacuously, and any HEAD movement counts as staleness). `tests/t-gt03-freshness.sh` controls it in
  both directions: RED on `d5424be`.
- **"The four rows that do not skip" is two (D3).** `README.md` and `docs/CONTRACTS.md` both said
  four. Measured on the class-A run the paragraph describes: `PG-05` and `PG-06` PASS, and the four
  electron bans named in the same breath (`BN-06`..`BN-09`) **SKIP**. Both copies say **two** now and
  name them, and `docs/ADOPTION.md` and the shipped `skills/goblin-bootstrap/SKILL.md` no longer give
  the bans' reason as "no `src/`" when five of those eight rows skip as *not enabled in `bans:`*.
- **"`created 49` means it wrote 49 files" was one file short (D4).** The installer writes **50**
  files into an empty repo: the 49 it counts (40 `files` + 8 `owned` + `.gitignore`) plus
  `.goblin/installed.json`, the record it keeps for itself, which it writes and does not count. The
  guide says exactly that now. The counter is unchanged — moving it would have moved every derived
  number in every document that quotes a `created N` line.
- **"It adds no network calls" was unscoped, and false (D5).** Every other copy of that claim is
  scoped — `docs/GUARDRAILS.md` says "No network at **verify time**", README and `docs/CONTRACTS.md`
  put it under "**Dependencies**", and `bin/goblin-audit`'s own header calls itself "the ONE command
  in the toolchain that touches the network" — as does the guide itself in §8 and §11. §1, the first
  sentence a new reader meets, now says `no network call at verify time`.
- **`VERSION` is `0.4.3`** — `VERSION`, the five `bin/` version constants and this entry agree. The
  seven dated `0.4.2` statements (this file's own 0.4.2 entry, `docs/LIMITS.md`'s AA1 note,
  `docs/ENFORCEMENT.md`'s and `manifest/enforcement.tsv`'s SC-08 cells, and
  `tests/t-verify-red.sh`'s two "measured at …" notes) describe a past revision and keep their
  version.

## 0.4.2

- **`SC-08` no longer passes vacuously on a minified lockfile (Z2-2).** `check_sc_08` read
  `package-lock.json` with a line-anchored awk, so a **minified** (one-line) lockfile matched
  nothing and the row printed `0 install hook(s), 0 allowlisted` — **exit 0, a PASS** where the
  pnpm/yarn branch's SKIP is the honest shape. Measured on one tree: the same unlisted hook is
  `FAIL` rc 1 pretty-printed and was `PASS` rc 0 on one line. The text is normalised into the
  pretty shape before the reader sees it (a text transform — no npm, no jq, no parser) and the
  anchor accepts `": {` and `":{`; two controls hold it, and the FAIL half is RED against the
  0.4.1 verifier.
- **`HS-02` shell-quotes the harness file name it substitutes (Z2-3).** Z1-4 made the row run the
  DECLARED command instead of `node "$f"`, which put a file name from the harness dir into the
  command text `bash -c` parses — the same surface class as the G8-1 injection. Measured with a
  file named `z2;true;#.mjs`: unquoted, two commands ran and the trailing `true` decided the exit
  code (rc 1, "was GREEN on the pre-change tree"); quoted with `printf %q`, `node` receives one
  argument. The control carries that name.
- **Y1 §7's items 1, 2 and 6 have their direct controls, so the census moves (AA1).** The layer
  probe's `bans_exempt:` path, the engine→probe `GOBLIN_BANS_ID`/`GOBLIN_BANS_EXEMPT` contract,
  and the prefix's segment alignment (including the trailing-slash case) each have one now;
  `grep -c GOBLIN_BANS_EXEMPT tests/` was **0** before, and the five W5-1/W5-2 controls all drive
  `grep-ban.sh`, never `layer-check.sh`. The census is therefore **18 listed · 2 fixed · 2 closed ·
  3 controlled · 11 recorded**: three mechanisms left `LIMITS.md` #41's recorded set, which is the
  only direction that frees headroom, and no advisory row was spent — **10 of 10**.
- **`tests/t-verify-red.sh`'s census is re-counted, not carried: 121 `expect_red` + 28
  `expect_green` = 149 calls**, 78 distinct ids, 0 phantom, 0 uncovered. Its W5-1/W5-2 comment no
  longer says that all five of those controls are RED on the pre-fix tree — two of the five are
  (Z2-4). Measured on 7fec08f: the two `expect_green` halves fail there (the escape did nothing),
  the three `expect_red` halves report ok; all five name a row that is RED there.
- **`VERSION` is `0.4.2`** — `VERSION`, the five `bin/` version constants and this entry agree.

## 0.4.1

- **Y1's remaining defects, landed (Z1).** Eight MINOR/STYLE findings from an independent verification
  of 0.4.0, plus the carried W5 items that survived X1. The load-bearing one is `{{GATE2}}`, which
  leaked an unsubstituted token into **all six classes'** installed `.goblin/goblin.yaml` for two
  waves while `grep -rl '{{GATE2}}' tests docs manifest bin` was **0 files**: nothing rendered it and
  nothing saw it. It is deleted, and it now has the control that would have caught it —
  `tests/t-render-tokens.sh` renders all six classes and scans every installed file for a `{{…}}`
  token (RED on the pre-fix template: 6 leaks, 1 per class).
- **`replay.cmd` now runs.** `presets/*.yaml` declared `replay_cmd: node checks/{name}.mjs` and `HS-02`
  read it only to assert it was non-empty, then ran `node <file>` itself — so the declared command and
  its `{name}` placeholder were decorative and `replay.cmd: false` changed no verdict. The row
  executes the declared command with `{name}` substituted; measured, `false` now FAILs and the PASS
  line names the command it ran.
- **Also fixed:** `IN-03` now enforces the `enforced_by` enum it documented as closed (a `bogus` cell
  changed nothing before); `FM-02` refuses an entry path that resolves only to a file git does not
  track (the freshness clause used to skip silently); `SC-03` prints a hit count instead of the
  character count of the matching line (W5-11, a half-done fix); the summary prints the advisory
  arithmetic, so `advisory 10 of ceiling 10` beside 11 `ADV` lines is explained on screen (Z1-7);
  `--practice <path>` that does not resolve is now reported instead of silently dropped (W5-3);
  `CHANGELOG.md`'s own ban-lane claim is corrected to its measurement (two of five RED pre-fix, three
  pinning behaviour that was never broken, which is what X1 §5 reports); `docs/ENFORCEMENT.md` cites
  the right `LIMITS` entry; `tests/run-tests.sh`'s header counts five source rows, not four.
- **`docs/LIMITS.md` #41** records Y1 §7's census, and the arithmetic is stated separably so a
  reader can check it: Y1 listed **18** documented mechanisms with no control of their own; this
  wave **fixed** two (the unrendered token, `replay.cmd` — items 17 and 18, which by definition
  now HAVE controls and so sit **outside** the "carry no control" set), **closed** two more (the
  ban engine's `exit 2` paths and `--list` — items 4 and 5, three assertions in
  `tests/t-verify-red.sh`), and **recorded the remaining 14** with their reason. **18 listed ·
  2 fixed · 2 closed · 14 recorded.** (This sentence said *sixteen* and counted the two fixed
  mechanisms inside the no-control set, so `2 + 2 + 14` could not be reconciled from it —
  Z2-1; the corrected counts are the ones that add up.) W5-10's exemption (`docs/` is never
  installed) is stated there too. No advisory row was added: **10 of 10**, unchanged.
- **`VERSION` is `0.4.1`** — `VERSION`, the five `bin/` version constants and this entry agree.

## 0.4.0

- **W5's regression is closed: the ban lane's two documented escapes now work (X1).** `bans_exempt:`
  was a **permanent RED** after W1's V3-2 fix — the engine filtered the probe's stdout *after* the
  probe had already chosen its exit code, so the filter was decorative and a violation inside an
  exempted path had no remedy (measured `rc 0` at `72490f0` → `rc 1` at `7fec08f`, and
  `grep -rn bans_exempt tests/` was **0 hits**, which is why nothing caught it). The engine now
  exports `GOBLIN_BANS_ID` and `GOBLIN_BANS_EXEMPT` and the shipped probes filter the **file list
  before judging**; the manifest's `escape` column is now true — `// BAN-OK(<id>): <reason>` on the
  offending line clears that line, and a non-empty reason is required. Five controls, both
  directions — **two of the five RED on the pre-fix tree; the other three pin behaviour that was
  never broken** (Y1 measured the ban-lane half at 2, which is what X1 §5 itself reports);
  the residual (a project's own `detect` that ignores the
  variables keeps the old, closed failure) is `docs/LIMITS.md` #36.
- **W5's four half-instrumentations: closed where closable, recorded where not (X1).** `FM-02` no
  longer resolves a token that occurs only in the harness — `.goblin/`, `.hermes/`, the declared
  `harness_dir` and the map's own directory are skipped, so a stub map that echoes the template
  FAILs (W5-4, `docs/LIMITS.md` #37). `MD-02` now resolves the **judge** lane and compares its model
  with the code lane's, instead of leaving the judge distinct by profile name only; it stays
  advisory, and the measured state is recorded (#38 — on this box the live mapping names **no
  `judge:` profile at all**, so the judge lane reads unresolved, while every profile it does name
  resolves to one model: map a judge and it is the author's family). `LP-02`
  requires a close-and-reopen to archive the predicate **and** the pin it was closed under and to
  name the archived digest on a `previous:` line, so a silent relaxation FAILs while a real re-scope
  costs one line (#39 — whether the new bar is *weaker* is not decidable from a digest). And
  `PG-06`'s why-cell now says plainly that the CI lane's enforcement is the **target repo's**, not
  goblin-stack's (#34), rather than reading as enforcement.
- **The control census is counted, not carried.** `tests/t-verify-red.sh` now carries **112**
  `expect_red` and **22** `expect_green` — **134** call sites over all 78 target rows, 78 distinct
  ids, 0 uncovered, 0 phantom (W5-9 measured the header sentence one count behind at 105+19).
- **`VERSION` is `0.4.0`.** It read `0.3.0` at `7fec08f` while the board and four build passes
  called the wave v0.4 — this section is the entry the wave lacked, and the artifact no longer
  calls itself a version its own build passes did not.

The wave proper (W1–W4) built on **0.3.0**'s ban list and added:

- **V3's four 9/10 blockers closed (W1).** `GT-01` FAILs when a declared gate carries no `cmd:` —
  deleted, blanked or re-indented — instead of silently counting the survivors (G8-3, the third
  condition of G8's own 9/10 sentence); the ban engine and the `bans:` switch are named in the
  installed `AGENTS.md`, so a ban is discoverable while the code is written and not only in the
  post-mortem (V3-1); `bin/goblin-bans` reads a detect's exit 1 as VIOLATED even when stdout is
  empty, so the code matches the exit contract it documents instead of failing open (V3-2); and
  `PF-01` FAILs when `ratchet.ceiling` and `perf.baseline_value` disagree, so a hand-raised
  ceiling no longer passes while printing the contradiction (G8-6b). The verifier's "cannot see"
  footer now names the ban lane's own blind spots (V3-8), and `docs/ROLES.md`'s "exactly two
  scripts" is corrected to the four an install actually writes (V3-6).
- **The feature map, the P6↔P12 wiring, and the skills evidence (G1, W2).**
  `skills/goblin-feature-map/SKILL.md` is the map's contract — the README index, the four-H2 entry
  contract, the rot table, the upkeep pass — and three **declared** config keys drive it:
  `feature_map:` (the map's README; **empty means both FM rows SKIP with that reason**, so a fresh
  install is not born RED), `source_root:` and `verify_doctor:`. Three new rows: `FM-01` (every
  feature file indexed and linked, `feature:` equal to the filename stem, at least one
  `entry_paths:`, the four H2s in order), `FM-02` (every declared entry path still resolves under
  `source_root:` and none changed after its `verified:` date — a tripwire, never a proof) and
  `VA-01` (the declared doctor exits 0, the executable half of P6's "never executed is a draft").
  `P6` gains step 5 (seed the map) and step 6 (hand the generated skill to `P12`: `verified:` does
  not advance until an eval record exists); `P12` gains the record format (`evals/<slug>/`), the
  eleven-token ban, the cheap-checks-first ladder, the merge rule and the pass condition. The eval
  **runner is not shipped** and no row reads a lane (`docs/LIMITS.md` #31). `docs/LIMITS.md` #15 is
  corrected: the controlled evidence now exists — SkillsBench 1.1 measures curated Skills at
  **+16.6 points (33.9% → 50.5%, 18 model–harness configurations, 87 tasks)**, and its
  **self-generated condition put all three tested configurations BELOW their no-Skills baseline**
  (`docs/RISKS.md` K15) — a warning about this repo's own agent-authored output, not someone
  else's.
- **The judge role and the loop contract (G2, W3).** `role-judge` in `roles.yaml` — a capability,
  never a model — plus `skills/goblin-judge` (what a judge is, and what it must refuse) and
  `skills/goblin-loop` (the record it leaves). `docs/LOOP.md` is the contract **and** the measured
  reading of Hermes's own `goal_mode`: the judge is called as `judge_goal(goal_text,
  last_response)`, with **no contract, no subgoals and no quality gates**
  (`hermes_cli/goals.py:1660`); it sees the card's goal (2000 chars) and the worker's own most
  recent response (4000) (`:38`, `:901-905`); and the loop has **no progress detector at all** —
  its whole state is `last_response`, `turns_used`, `nudged_to_finalize` (`:1634-1636`). Eight new
  rows. `JG-01`: a `done` verdict may only cite a **handle the repo can resolve** (`sha:` a commit
  in `git rev-list --all`, `file:` a path under the root, `sha256:` a file under `.goblin/loop/`) —
  a `cmd:` token resolves **nothing**, because the command's output is not in the record.
  `JG-02`: the declared judge lane must be **disjoint** from the author's — a FAIL, not a report;
  an unresolved lane is an `ADV` with a one-line remedy, because a repo cannot choose the fleet's
  routing. `JG-03`: a judge lane with no non-`done` verdict is escalated — **counted, never gated**,
  and the advisory slot W2 left free for G2. `LP-01`..`LP-05`: one predicate command, run and
  recorded (`exit=<n> ts=<ISO8601>`) **before iteration 1**; pinned by digest and never relaxed;
  a budget under the new `loop_max_turns_ceiling` (default **20** — the engine's own
  `DEFAULT_MAX_TURNS`, so the two numbers agree); no three consecutive rows on one evidence
  pointer without reaching `predicate:green`; and a `.goblin/loop/stuck.md` naming the predicate
  when the loop ends red. `templates/loop/` ships a copy-ready predicate and record header, and
  **nothing installs them**: a fresh install must not be born with a loop record. `P10`'s role is
  now `code + judge`, `P7` gains the S3+ foreman (`role-judge`, one decision from N lane verdicts),
  and `docs/INTEGRATION.md`'s claim that the auxiliary judge "is the predicate re-check" is
  corrected in place with the measured calls. `docs/LIMITS.md` #32 and #33 and `docs/RISKS.md` K17
  record what the lane cannot see.
- **The CI lane and the desktop-shell class (G6, W4).** `PG-05` is **re-declared**, not patched: it
  counted "every step is guarded", which passed the shape G8 measured — a single **job-level**
  `if:`, a job with no step, and one *unguarded* step deciding whether the guarded gate step runs —
  all of which reach the end of the job without running the gate while the required check reports
  Success. It now FAILs all four. **`PG-06` is new**: the gate CI runs must be the gate the project
  declares, read from the same `g_yaml_gates` reader `GT-01` uses so a gate cannot vanish from the
  comparison in silence; a workflow satisfies it by running the verifier with no `--only`, or by
  running every declared gate command verbatim, with comments blanked first. A `ci-gate` **part**
  joins `manifest/classes.tsv` (`R` for A/F, `O` for C/E, `-` for B/D) and the installer renders
  `templates/ci/goblin-gate.yml.tmpl` into `.github/workflows/goblin-gate.yml` — one job, no `if:`
  anywhere, one step that runs the repo's own gate set. `CL-01`'s artifact for the part is that
  exact path, never the `.github/` directory, so a repo that forbids `ci-gate` may still carry CI of
  its own. `bin/goblin-install --uninstall` now walks **every** ancestor directory, because that
  workflow empties two levels. **Class F (desktop shell)** is the new preset: five electron bans
  (`BN-06` `nodeIntegration: true`, `BN-07` context isolation/sandbox off, `BN-08` the dangerous
  `webPreferences`, `BN-09` synchronous IPC / `@electron/remote`) and the FPS number as a **host
  gate** — the instrument needs Playwright or Electron plus a display, which no shipped rule may
  depend on, so the ratchet carries the hermetic `app_bundle_bytes` instead. **A stated deviation
  from G6 §B.3**, recorded in `docs/LIMITS.md` #35; a `ratchet.cmd` that cannot run would make a
  fresh install born RED. `docs/CI.md` is the new contract: what makes a workflow a gate (required
  check, no admin bypass, a push identity that is not the sole admin, never conditional), why frame
  time is the wrong metric (measured p50 flat at 16.70 ms while the main thread went 1.8 % → 54.5 %
  busy), and what is deliberately not mechanised. `docs/LIMITS.md` #13 and #34, `docs/RISKS.md` K7
  and the new K18, `docs/DESIGN.md`'s "no CI workflow" invariant (amended as an architecture change)
  and the verifier's "cannot see" footer all carry it.
- `manifest/enforcement.tsv` is **83 rules** (78 target, 5 source); the advisory count is **10 of
  ceiling 10 — full**, unchanged (both new rows are real commands, so no slot was spent);
  `tests/t-verify-red.sh` carries **105** controls and **19** `expect_green` — **124** over all 78
  target rows, 0 uncovered and 0 phantom. (Superseded 2026-09-25: this line read 78 rules / 73
  target / 93 controls / 14 green before W4's five rows landed. **Corrected 2026-09-25 (AB3):** the
  census above was wrong when it was written — 0.4.0's own tree (`63d62d2`) carries **112**
  `expect_red` + **22** `expect_green` = **134**, not 105 + 19 = 124, and the tree at 0.4.3 measures
  **121** + **28** = **149**. The released numbers stand as written; this is their correction.)
- A fresh class-A install verifies **`43 passed, 0 failed, 11 advisory, 24 skipped`**, exit 0
  (twenty-four rows skip with a reason: `HS-02`, `AU-02`, `AU-03`, `SC-06`, `SC-07`, `SC-08`,
  `PF-01`, `BN-01`/`BN-02`/`BN-03`/`BN-05` plus `BN-06`..`BN-09` on a repo with no `src/`,
  `FM-01`/`FM-02`/`VA-01` with no map
  and no doctor declared, and `JG-01` + `LP-01`..`LP-05` with no `.goblin/loop/` record); `PG-05`
  and `PG-06` do **not** skip, because this class installs the workflow they read. A fresh
  class-B install (`bans: []`) verifies `37 passed, 0 failed, 10 advisory, 31 skipped`; class-C
  verifies `43 passed, 0 failed, 11 advisory, 24 skipped`; class-E (`bans: [BN-02]`) verifies
  `42 passed, 0 failed, 11 advisory, 25 skipped`; the new **class-F** verifies
  `43 passed, 0 failed, 11 advisory, 24 skipped`; class-A with `--skills no` verifies
  `39 passed, 0 failed, 11 advisory, 28 skipped`. All measured on fresh installs, committed with no
  hand edit. (Superseded 2026-09-25: these lines read 42/0/9/14, 37/0/8/20, 42/0/9/14, 41/0/9/15
  and 38/0/9/18 before G2's eight rows landed, and 42/0/11/20, 37/0/10/26, 42/0/11/20, 41/0/11/21
  and 38/0/11/24 before W4's five.)

## 0.3.0

- **The ban list (G5).** `manifest/bans.tsv`, `bin/goblin-bans` and `bans/` install as
  `.goblin/manifest/bans.tsv`, `.goblin/bin/goblin-bans` and `.goblin/bans/` — Dune rule 2 made
  a gate: **a ban without a mechanism is a wish.** Four bans ship with a real command each
  (`BN-01` no `any`, `BN-02` no `@ts-ignore`/`@ts-expect-error`, `BN-03` no `fetch` from a
  component, `BN-05` no import across a declared layer boundary), plus `BN-00` (the coherence
  row: every ban has an enforcement row, every row names a replacement, the table is not empty).
  The config gains `bans:` (which bans this project turns on — an unlisted ban SKIPs with a
  reason), `bans_exempt:` (narrow, explicit exceptions) and `layers:` (what `BN-05` reads).
  Class A and C turn on `BN-01 BN-02 BN-05`; E turns on `BN-02`.
- The ban probes are **text probes** (`grep`, no npm, no AST — `docs/CONTRACTS.md`), so G5's
  `BN-04` (the nine named unnecessary-effect patterns) is **not shipped**: it cannot be
  mechanised without a parser, and a ban that cannot go red is worse than advisory. Recorded in
  `docs/LIMITS.md` #27 rather than spent as the last advisory slot. Advisory stays **9 of 10**.
- `manifest/enforcement.tsv` is **67 rules** (62 target, 5 source); `tests/t-verify-red.sh`
  carries **68** controls over the 62 target rows.
- A fresh class-A install verifies **`42 passed, 0 failed, 9 advisory, 11 skipped`**, exit 0
  (eleven rows skip with a reason: `HS-02`, `AU-02`, `AU-03`, `SC-06`, `SC-07`, `SC-08`,
  `PF-01`, and `BN-01`/`BN-02`/`BN-03`/`BN-05` on a repo with no `src/`). A fresh class-B install
  (`bans: []`) verifies `37 passed, 0 failed, 8 advisory, 17 skipped` — the four BN rows SKIP with
  "not enabled in `bans:`"; class-C verifies `42 passed, 0 failed, 9 advisory, 11 skipped`; class-E
  (`bans: [BN-02]`) verifies `41 passed, 0 failed, 9 advisory, 12 skipped`. All measured on fresh
  installs, committed with no hand edit.

## 0.2.0

- **Automation agents (G3).** `P13 goblin-bugreporter` and `P14 goblin-drift-audit`, plus the
  producer half in `automations/` — `drift-audit.sh` (deterministic, network-free, silent when
  clean, with a kill switch and a run ceiling) and `bugreporter-intake.sh` (the intake gate: a
  missing key is a refusal card with **no assignee**, so it is structurally un-spawnable). The
  files install to `.goblin/automations/`; the fleet steps are printed by `goblin-install` and
  argued in `automations/README.md`. Six new rules: `AU-01`, `AU-02`, `AU-03`, `AU-04`,
  `SK-04` ("every shipped skill says what it cannot see") and the source row `PR-05`
  (`tests/t-automation-silent.sh` — the mutation is the control). Advisory was **8 of 10** after
  G3 and is **9 of 10** once `SC-09` lands with G4.
- **Guard rails (G4).** `SC-01`..`SC-09` and `PF-01`: secrets and the config surface, input
  boundaries and dependencies, and the performance lane. The perf budget stays `GT-04`/`GT-05`
  (no second mechanism): the class-A preset's metric is now `client_js_bytes` and the TODO count
  moved into a `todo_ceiling` gate. `bin/goblin-audit` installs to `.goblin/bin/` and is the ONE
  tool allowed to touch the network - run deliberately, it writes the record `SC-07` reads
  offline, and it refuses (exit 5) to write an empty record rather than let "nothing parsed" read
  as "clean". A class declares its security surface and perf baseline in `security:` / `perf:`;
  the guard rails are argued in `docs/GUARDRAILS.md`, and `tests/t-audit.sh` exercises the whole
  producer offline against a canned npm-audit report.
- `manifest/enforcement.tsv` is **62 rules** (57 target, 5 source); playbooks are **14**;
  `tests/t-verify-red.sh` carries **60** controls over the 57 target rows.
- A fresh class-A install verifies **`41 passed, 0 failed, 9 advisory, 7 skipped`**, exit 0
  (seven rows skip with a reason: `HS-02`, `AU-02`, `AU-03`, `SC-06`, `SC-07`, `SC-08`,
  `PF-01`); a fresh class-E install verifies `40 passed, 0 failed, 9 advisory, 8 skipped`.
  Advisory is **9 of ceiling 10**.

## 0.1.0

- First version. Ships `bin/goblin-install`, `bin/goblin-verify`, `bin/goblin-model`,
  `bin/goblin-lib.sh`; `manifest/enforcement.tsv` (46 rules); 12 playbooks + `goblin-mode`
  + `practice` as Hermes project-local skills; 5 class presets; the templates; and
  `tests/run-tests.sh` with the negative control for every target-scope check class.
