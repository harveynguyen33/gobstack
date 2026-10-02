# The CI lane — what makes a workflow a gate

`goblin-verify` runs on a machine you control, at a moment you choose. A workflow runs on a machine
you do not, at a moment you do not. The two must not be able to disagree about one SHA: that
disagreement is the failure mode *"review is a prompt and a report, never a gate"* (R5 §1.1), and one
level up it is a **required check that goes green while the gate never ran**.

This file is the contract for the three things that close it: the part `ci-gate` (CL-01), the workflow
the installer writes, and the two rows — `PG-05` and `PG-06` — that read it.

---

## 1. A workflow file is not a gate

Four settings separate the two. None of them lives in the repository, which is why no check in this
harness can make them true — they are **forge** changes, and `PG-04` is the row that records that.

| # | Setting | Why it is load-bearing |
|---|---|---|
| 1 | **Required check** — Settings → Branches (or a ruleset) requires the gate job | A workflow nobody waits on cannot block anything. It reports and is ignored. |
| 2 | **`Do not allow bypassing the above settings`** | *"By default, the restrictions of a branch protection rule don't apply to people with admin permissions"*, and *"People and apps with admin permissions to a repository are always able to push to a protected branch"*. Without this switch the rule binds everyone except the person who wrote it. It is per-rule, and it applies to a single branch at a time. |
| 3 | **A push identity that is not the repo's sole admin** | A required check armed under your own identity binds nobody. This is the honest blocker in the estate today: the sole admin of every repo is the only committer to it, so a required check is advisory for exactly the pushes that matter. Changing it is a forge/account change, not a repository change. |
| 4 | **Never conditional — not the job, not the step** | *"A job that is skipped will report its status as 'Success'. It will not prevent a pull request from merging, even if it is a required check."* GitHub reports a **skipped** job as Success, so a `if:` anywhere above the gate step is a green light for a commit whose gate never ran. `PG-05` enforces this mechanically. |

**Where a private repo's minutes go.** GitHub Free gives 2,000 Actions minutes/month (S12); a
typecheck + build is 3–5 minutes, so five repos on every push fits comfortably. A Unity job does not
(30-minute timeout, image-cache churn), which is why the one existing C# workflow is the outlier and
not the model.

**Ground truth, measured at the W4 revision** — `find ~/projects -maxdepth 6 -type d -name workflows
-path '*/.github/*'`:

- `~/projects/supreme-unity/.github/workflows/unity-compile-check.yml` — the estate's **only**
  first-party CI, and it self-skips (6 of its 7 steps are guarded by
  `if: steps.check.outputs.ready == 'true'`, and the step that sets `ready=false` is not guarded).
- `~/projects/pstack-upstream/.github/workflows/validate-plugins.yml` — an upstream clone of someone
  else's project, not part of the estate.
- Everything else: none. Of the repos with a remote (`goblin-stack`, `goblin-ui`, `open-door`,
  `tech-goblin/frontend`, `tech-goblin/lab/diagram-studio`, `supreme-unity`) five have no CI at all.
  A research vault, a notes repo and a no-remote directory are not candidates.

---

## 2. What goblin-stack places, and what it checks

The `ci-gate` part is `R` for **software**, `O` for **game** and **fleet**, and `-` for **service**
and **research** (`manifest/classes.tsv`). When it is installed, the installer renders
`templates/ci/goblin-gate.yml.tmpl` into `.github/workflows/goblin-gate.yml` — one job, no `if:` at
any level, whose only step runs `.goblin/bin/goblin-verify`. It is `owned`, so a second install is a
no-op and a hand-edited copy is never overwritten.

Three rows read it:

- **`CL-01`** — the part's presence/absence is a class contract. Its artifact is
  `.github/workflows/goblin-gate.yml`, **not** the `.github/` directory: a class that forbids
  `ci-gate` forbids *goblin-stack writing a workflow there*, never the repo having CI of its own.
- **`PG-05`** — no job-level and no step-level `if:` anywhere in any workflow under
  `.github/workflows/`, and every job must declare at least one `run:`/`uses:` step. A job that
  declares nothing, a workflow with no `jobs:`, and the measured real shape (one *unguarded* step
  deciding whether the guarded gate step runs) all FAIL.
- **`PG-06`** — the declared gate set is the gate CI runs. The declared set comes from
  `g_yaml_gates` — the same reader `GT-01` uses, so a gate cannot vanish from the comparison in
  silence. A workflow satisfies the row when the whole declared set is **run**: the verifier with no
  `--only` (a full run executes every declared gate through `GT-02`), or every declared gate command
  appearing verbatim.

Comments are blanked before either row reads the file, so a commented-out verifier call is not a run.
`#` inside a quoted string is the one reading error this costs: the rest of the line is treated as a
comment and cannot count toward a pass.

---

## 3. The Electron opt-in (software class)

An Electron app is the **`software`** class with `electron: true`. The opt-in exists because such an
app needs a part no other shape has — a **host gate**, a number measured on a machine with a display
— and forbids a thing the plain software class allows: a **renderer that reaches Node or the
filesystem directly**. The merge measured the old sixth class's part needs identical to `software` on
all ten parts, so none of this is a sixth column in `manifest/classes.tsv`: it is the `bans:` list and
the `perf.host_gate:` key, rendered over the software preset by `presets/electron-overlay.yaml`.

### 3.1 The failure surface, and the check for each

| Failure mode | What the harness does | Row |
|---|---|---|
| Renderer has Node access (`nodeIntegration: true`) | ban, text probe over the class's globs | `BN-06` |
| Context isolation / process sandbox off | ban (one rule: Electron's docs make them one property) | `BN-07` |
| `webSecurity: false`, `allowRunningInsecureContent`, `enableBlinkFeatures`, `allowpopups` | one ban, four one-line patterns | `BN-08` |
| `sendSync(` / `@electron/remote` in a hot path | ban | `BN-09` |
| Blocking the main process | **host gate** — see §3.2 | declared, `PF-01` |
| Renderer idle-CPU spin (`idleWakeupsPerSecond`) | host gate, sampled over a 60 s window | declared |
| A leak that grows over hours | host gate; an 8-hour property a 30-minute gate cannot see | declared |
| The bundle ships dev dependencies | `SC-08`/`SC-03` read the manifest and the build output | existing |
| A renderer importing main (or the reverse) | **not mechanised** — needs a dependency graph; see §4 | — |
| IPC without `event.senderFrame` validation | **not mechanised** — semantic; see §4 | — |
| Fuses left at defaults (`runAsNode`) | **not mechanised** — a package-time read of the built binary | — |

### 3.2 The perf lane: one ratchet, and a host gate beside it

There is **one** mechanism, and the opt-in reuses it unchanged: `ratchet: {name, cmd, ceiling}`,
enforced by `GT-04`/`GT-05` and pinned to a commit by `PF-01`. A second perf mechanism is not
introduced.

What the ratchet measures here is `app_bundle_bytes` — the packaged bundle's byte count. It is
hermetic, it needs no browser, no display and no dependency, and a fat bundle is a slow cold start on
every machine. **The FPS number is declared as a host gate instead** (`perf_host_gate:` in
`presets/electron-overlay.yaml`), and carried in the HANDOFF with the date it was measured.

This is a **deviation from G6 §B.3**, which put `main_thread_busy_pct` in the ratchet, and the reason
is measured: the instrument that produces it — CDP `Performance.getMetrics`, or
`app.getAppMetrics()[i].cpu.percentCPUUsage` inside a real Electron — needs Playwright or Electron
plus a GUI, and the dependency contract (`docs/CONTRACTS.md`) allows a shipped rule nothing but
bash/git/awk/sed/grep/python3. A `ratchet.cmd` that cannot run makes a fresh install **born RED**,
which is the one thing the install path must not produce. The probe belongs to the project, next to
the code it measures; a project whose CI needs npm runs it in **its own** workflow, never in
goblin-stack's shipped contract.

### 3.3 Why the FPS metric is `main_thread_busy_pct` and not frame time

Measured on a real Chromium (Playwright, CDP `Performance.getMetrics`), sweeping the main-thread
workload from 0 to 32 ms per frame:

```
burn= 0 (0ms/frame)   frames=194  p50=16.70ms p95=16.80ms p99=16.80ms  >2xp50=0   main-thread-busy= 1.8%
burn= 1 (2ms/frame)   frames=187  p50=16.70ms p95=16.80ms p99=16.80ms  >2xp50=0   main-thread-busy=13.5%
burn= 2 (4ms/frame)   frames=188  p50=16.70ms p95=16.70ms p99=16.80ms  >2xp50=0   main-thread-busy=26.0%
burn= 4 (8ms/frame)   frames=191  p50=16.70ms p95=16.80ms p99=33.40ms  >2xp50=1   main-thread-busy=54.5%
burn= 6 (12ms/frame)  frames=  7  p50=366.70ms p95=2550.00ms p99=2550ms >2xp50=3   main-thread-busy=76.9%
burn=10 (20ms/frame)  frames=157  p50=16.70ms p95=33.40ms p99=33.40ms  >2xp50=11  main-thread-busy=99.5%
burn=16 (32ms/frame)  frames= 92  p50=33.30ms p95=33.50ms p99=50.00ms  >2xp50=0   main-thread-busy=96.6%
```

- `main_thread_busy` is the **only monotone instrument**: 1.8 → 13.5 → 26.0 → 54.5 → 76.9 → 99.5 %.
  It moves with the workload across the whole range, and it is a *ratio* (CDP `TaskDuration` ÷ wall
  time), so it needs no per-run calibration.
- **`p50` frame time is FLAT at 16.70 ms from burn=0 through burn=4** — while the main thread goes
  from 1.8 % to 54.5 % busy. A frame-time gate at any threshold near 16.7 ms is **green on the idle
  tree and green on the loaded tree** — `PROJECT-PRACTICE.md` §3, reproduced live in the exact metric
  the note proposed.
- **Dropped frames (`>2×p50`) are non-monotone**: 0, 0, 0, 1, 3, 11, 0. At burn=16, the worst
  workload in the sweep, the counter reads **0** — at 33.3 ms pacing every frame is equally slow and
  nothing is 2× anything. A dropped-frame gate would pass the worst case.
- The sampler **starves** at burn=6 (7 frames in a 3.2 s window): any gate that reports "frames
  counted" must treat a collapsed sample count as failure, not as data.

The same number exists on both sides of the process boundary. In the renderer it is CDP
`Performance.getMetrics` (`TaskDuration`/wall). In the main process it is
`app.getAppMetrics()[i].cpu.percentCPUUsage`, whose own docs note it *"starts a new measurement
interval"* per call — so the probe's sample window **is** the interval, and two probes in one run
interfere. `idleWakeupsPerSecond` is the idle-spin half, an Electron-specific field, and it is an
average over the time since the previous call, which makes a 60-second idle sample the natural unit.

**A perf number measured on one box is not a user's experience.** This box is an LXC with no display
and no system Chromium, so the numbers above come from a *bundled headless* Chromium with no
compositor and no vsync. Relative comparisons within one machine are meaningful — which is why
`main_thread_busy_pct` works as a gate at all — and an absolute FPS claim is not. The gate can catch
*"this commit made the main thread 3× busier than the SHA we measured"*; it can never answer *"does it
feel smooth on a laptop"*.

---

## 4. What is not mechanised, and why

Recorded rather than shipped, so a later session does not re-derive them:

- **A dependency-graph run over the renderer/main boundary.** Mechanisable *once the directory
  convention is declared*, but it needs a graph tool, and no declaration exists yet.
- **`ipcMain` handler sender validation.** Semantic: proving `event.senderFrame` was checked requires
  reading a control-flow path, not a line.
- **Fuses at package time.** The honest form reads the *built binary*, which needs a package step.
- **A real user's device, GPU, compositor and thermal state.** Not observable from any machine but
  theirs.
- **An 8-hour leak.** A gate gets 30 minutes; a slope extrapolated from 30 minutes is a hypothesis.
- **Packaging, signing, notarisation, installers, auto-update, OS integration.** OS-specific; none of
  it observable here.
- **Whether the app is *right*.** As with every gate: green means the declared checks ran.

## 5. What this lane cannot see

The workflow rows read a **file**. They cannot see branch protection, the required-check list, or
whether the forge ever ran the job (`PG-04` is the row that records that, and it is advisory by
design). `PG-06` proves a declared gate is **invoked** in a file under `.github/workflows/` — never
that the forge marks that job required, never that it is the job the forge waits on, and never that
the workflow *can fail* (`PG-05` is the row for that). A command sitting inside a `name:`, `env:` or
`with:` value is dropped by the reader, but a command inside a quoted string that happens to match
the verifier's name is not. And nothing here can arm a check: a workflow file, a required check and a
push identity are three different things, and only the first one is in the repository.

See `docs/LIMITS.md` #34 for the Electron perf gap, #13 for the `PG-05` reading, and #18 for the
record every drift check trusts.
