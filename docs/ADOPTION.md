# Adoption — classes, presets, and the order

## The five classes

A class is **not** a stringency level. It selects which parts are required, optional or off, and
it supplies the default gate and ratchet shape. The gate vocabulary differs by class; the
harness does not. The names are words; the letters `A`..`E` are read-time aliases.

| Class | What "done" means |
|---|---|
| **software** (A) | a gate set reports measured numbers, a round lands, the artifact deploys or publishes |
| **service** (B) | a contract (schema, route, API) is unchanged, or the change is intentional and migrated |
| **game** (C) | a suite green in the Editor **and** a human feel verdict — the verdict is a first-class deliverable |
| **research** (D) | a question is answered with sources and the answer is findable |
| **fleet** (E) | a config change is applied, verified against the **artifact**, and versioned |

Two placements worth arguing about:

- A repo whose code is small and lives elsewhere, while the repo holds *output*, belongs in
  **research**, not **software** — gating it like an application gates the wrong artifact; its gate
  is freshness, not compilation.
- An input directory that is not a build target at all belongs in **research** with **`--archive`**.
  Without the flag the installer keeps producing HANDOFFs for a directory whose own design
  folders are empty.

## The preset matrix

`R` = required · `O` = optional (installed, reported) · `—` = off. The same data is in
`manifest/classes.tsv`, and `CL-01` checks it against the repo.

| Part | software | service | game | research | fleet |
|---|---|---|---|---|---|
| HANDOFF | R | R | R | R | R |
| SPEC before change | R | R | R | — | R |
| Verification gate | R | R | R | O | R |
| Pinned-commit REPLAY | R | — | R | — | O |
| Ratchet | R | O | O | — | O |
| PR gate | O | — | O | — | O |
| Review panel | O | — | R | — | O |
| Playbooks (the skills) | R | R | R | R | R |
| Design tokens | O | — | — | — | O |

(The `ci-gate` part is not a row here: v2 installs no CI, so the part is off for every class —
the W4 preset matrix that carried it is recorded in `docs/LIMITS.md` as out of the v2 product.)

**The electron opt-in, not a class**, added at W4: an Electron app is the **software** class with
`electron: true`, which declares the Electron failure surface as bans (`BN-06`..`BN-09`) and
declares its FPS number as a **host gate** rather than a ratchet, because the probe that measures
it needs Playwright or Electron plus a display — neither of which a shipped rule may depend on. Its
ratchet carries `app_bundle_bytes` instead. The old sixth class was merged into `software` (its need
column measured identical on all ten parts), and the old `F` letter remains an install-time alias
that selects `software` **with** the opt-in (frame time measured flat at 16.70 ms while the main
thread went from 1.8 % to 54.5 % busy — the number is the argument).

**`—` is a real, enforced option.** The installer records every off part in `disabled:`, so its
rows report `SKIP (opt-out)`; `CL-01` fails if a forbidden part's artifact exists. A repo with
1,599 test files or 27 research notes is not broken by a forced harness directory — it is
switched off for that class.

Four consequences that follow from measurement, not taste:

1. A forced harness directory breaks a repo whose tests are not `checks/*.mjs`.
2. Two gate *kinds* must exist in the schema: hermetic (repo-local) and host (touches paths
   outside the repo). A host gate reported as hermetic reports environment differences as
   failures.
3. **The gate command must be declarable per project, never inferred from the stack.** One
   inferred command is wrong for a repo with no runner, a repo that cannot run its own typecheck
   read-only, and a repo whose runner lives in a skill — all at once. The shipped gate is a
   **floor**, and `P8` step 3 is "replace it".
4. **The default branch is not always `main`.** It is declared in `.gob/goblin.yaml` and
   compared against the real branch by `PT-02`; a preset that assumes `main` silently skips a
   repo on `master`.

## The adoption order

Each step is independently useful and the later ones build on the earlier:

1. **A repo already at the standard, first — to prove the installer, not to improve the
   project.** The only honest test of an installer is that it is idempotent against a repo that
   needs nothing. Success = install, then verify reproduces the harness count and the ratchet
   number with `git status` unchanged.
2. **The highest-risk gap second.** A large repo with client deliverables and **no version
   control**: everything else is recoverable from a working tree, that one has no "before".
   Gate on: `git init` done, `.gitignore` verified against local env and build-info files, first
   commit exists, HANDOFF exists, the real typecheck recorded.
3. **The fleet-config repo third — highest value per minute.** A non-code preset that cannot
   fix its own home is not publishable.
4. **The cheapest correctness win fourth.** Content types untracked inside a repo that looks
   protected: commit them, write a HANDOFF, then fix the branch name.
5. **The small ones fifth** — they exercise the `—` switches. One needs a single commit; another
   needs its `.gitignore` fixed **before** `git init` because a credentials file sits in-tree.
6. **The two small repairs sixth** that make a fleet self-consistent: a stale HEAD, a stale
   number, and the REPLAY added to each.
7. **The rest seventh — real work, no emergency.** Each is blocked on a *decision* more than on
   effort.
8. **An archived input directory — never adopted.** It is the regression test for the off
   switch.

## What a first install actually gives you

`goblin-install` exits 0 and creates: `.gob/` (the verifier, the manifest, the config),
`.hermes/skills/` (the flows), `HANDOFF.md`, `AGENTS.md`, and — for classes that need them —
`ROUND-000-SPEC.md`, `reviews/`, and the harness scaffold in `checks/`.

Then, in order:

    git add -A && git commit          # the install is a change like any other
    .gob/bin/goblin-verify            # 33 passed, 2 failed - CM-03 + SP-02, until the install is committed

A default software-class install (no agent skills) is **green** — `35 passed, 0 failed, 6 advisory,
25 skipped`, exit 0 — once
`HANDOFF.md` names a commit that exists; before that edit the scaffold's `0000000` placeholder is
the one expected red (`34 passed, 1 failed`). Both numbers are measured, not assumed
(`docs/CONTRACTS.md`; step 2 of `docs/GUIDE.md`). Twenty-five rows skip with a reason: the
five skill rows (`SK-01`..`SK-04`, `AU-04`) skip on the `playbooks` opt-out a skills-free
install records, plus the not-yet rows: `HS-02` (no
pinned pre-change commit yet), `AU-02`/`AU-03` (no report has been filed, so there is nothing to
dedup and no reporter run to audit), `SC-06` (no dependency manifest, no lockfile), `PF-01` (no measured perf baseline), `BN-01`/`BN-02`/`BN-05` (no `src/` for a ban
to read) and `BN-03` with the four
electron bans `BN-06`/`BN-07`/`BN-08`/`BN-09` (not in this class's `bans: [BN-01, BN-02, BN-05]`, so
they skip as *not enabled* rather than as *unread*), `FM-01`/`FM-02`/`VA-01`
(no feature map and no declared `verify_doctor:` yet) and `RC-01`..`RC-04` (no reference corpus
declared: `reference_manifest:` ships empty and a fresh repo has no lab `manifests/`). The class's
required parts that only a round can produce pass *vacuously* (zero `reviews/*.md` to check; the
declared gate is still the shipped floor), so the first-step list is a list of work, not a list of
FAILs.

## Adopting into a repo that already has a `HANDOFF.md`

The installer never overwrites a `HANDOFF.md` that existed before the install. It prints
`refused to overwrite: HANDOFF.md` and exits 1. **That exit is correct, and `--force` is not the
remedy**: `--force` replaces the project's own record with the scaffold, which is the act the
refusal exists to prevent. `--force` is for a scaffold copy with nothing to keep.

The remedy is a reconciliation. The project's file stays the file of record; nothing is deleted
(a stale sentence is corrected in place with a dated parenthetical, never removed).

1. **Keep the file.** Do not re-install with `--force`, and do not delete it.
2. **Give it the five sections it is missing**, each as an H2 or H3 heading whose *first word* is
   the slot name — a marker or number prefix (`## ▶ START HERE`) is fine:

   | section | accepted first words |
   |---|---|
   | orientation | `START HERE` |
   | current state | `State` · `Status` |
   | gates | `Gate` · `Gates` |
   | next steps | `Next steps` · `Next` |
   | what is not verified | `Not verified` · `Unverified` · `Not proven` · `Unproven` · `Pending <x> device test` |

   `HP-02` is satisfied by the heading, not by the words appearing inside one: a `## BOARD STATE`
   heading is not a `State` section.
3. **Put the current gate numbers inside the `Gates` section, each with its date.** Every
   gate-bearing line in that section must read `measured YYYY-MM-DD`. Gate numbers elsewhere (in
   `State`, in a round block) are not the current gate line, and historical round gate lines are
   exempt — they are the record and are kept:

       - `tsc`=0 · `build`=0 · hex **144** (ceiling 160) · 38/38 harnesses green · measured 2026-09-24

4. **Name the HEAD in `State`** (`HEAD when this file was written: <short sha>`) — `HP-05` wants a
   commit that exists in this repo and is an ancestor of HEAD.
5. **Commit, then verify:**

       git add -A && git commit
       .gob/bin/goblin-verify        # HP-02, HP-03, HP-05 go green

   Success is the class's full green path (`35 passed, 0 failed, 6 advisory, 25 skipped`, exit 0 for
   the software class) with `git status --short` empty.

The edit is additive and small — measured on the model repo (§1's exemplar, 2450 lines): three
headings plus a `State` block, one dated gate line and a `Not verified` block, 15 lines, no line
removed.
