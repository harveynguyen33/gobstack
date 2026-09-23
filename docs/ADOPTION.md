# Adoption — classes, presets, and the order

## The five classes

A class is **not** a stringency level. It selects which parts are required, optional or off, and
it supplies the default gate and ratchet shape. The gate vocabulary differs by class; the
harness does not.

| Class | What "done" means |
|---|---|
| **A. Shipped software** | a gate set reports measured numbers, a round lands, the artifact deploys or publishes |
| **B. Service / configuration** | a contract (schema, route, API) is unchanged, or the change is intentional and migrated |
| **C. Game** | a suite green in the Editor **and** a human feel verdict — the verdict is a first-class deliverable |
| **D. Knowledge / research** | a question is answered with sources and the answer is findable |
| **E. Agent-fleet config** | a config change is applied, verified against the **artifact**, and versioned |

Two placements worth arguing about:

- A repo whose code is small and lives elsewhere, while the repo holds *output*, belongs in
  **D**, not A — gating it like an application gates the wrong artifact; its gate is freshness,
  not compilation.
- An input directory that is not a build target at all belongs in **D** with **`--archive`**.
  Without the flag the installer keeps producing HANDOFFs for a directory whose own design
  folders are empty.

## The preset matrix

`R` = required · `O` = optional (installed, reported) · `—` = off. The same data is in
`manifest/classes.tsv`, and `CL-01` checks it against the repo.

| Part | A | B | C | D | E |
|---|---|---|---|---|---|
| HANDOFF | R | R | R | R | R |
| SPEC before change | R | R | R | — | R |
| Verification gate | R | R | R | O | R |
| Pinned-commit REPLAY | R | — | R | — | O |
| Ratchet | R | O | O | — | O |
| PR gate | O | — | O | — | O |
| Review panel | O | — | R | — | O |
| Playbooks (the skills) | R | R | R | R | R |
| Design tokens | O | — | — | — | — |

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
4. **The default branch is not always `main`.** It is declared in `.goblin/goblin.yaml` and
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

`goblin-install` exits 0 and creates: `.goblin/` (the verifier, the manifest, the config),
`.hermes/skills/` (the flows), `HANDOFF.md`, `AGENTS.md`, and — for classes that need them —
`ROUND-000-SPEC.md`, `reviews/`, and the harness scaffold in `checks/`.

Then, in order:

    git add -A && git commit          # the install is a change like any other
    .goblin/bin/goblin-verify         # expect FAILs for the parts only a round can produce
    hermes skills trust <target>      # one-time, so the project-tier skills load

A fresh install is **not** automatically green, and that is the design: the class's required
parts that only a round can produce are reported as FAIL, and that list is the repo's
first-step list.
