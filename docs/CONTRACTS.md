# Contracts — installer and verifier

Dependencies: **`bash`, `git`, `awk`, `sed`, `grep`, `python3`.** No npm, no jq, no yq, no
network. `python3` is used for one thing only: reading the two-level model mapping file, the
same way the fleet's own tool reads it. Everything else is line-oriented shell.

## Install

    goblin-install --target <dir> [options]

    --target <dir>        required; the repo root to install into
    --class A|B|C|D|E|F  required unless --uninstall or --re-pin
    --models <path>       model mapping file   (default: $GOBLIN_MODELS -> ~/projects/fleet-model.yaml)
    --practice <path>     the referenced standard (default: $GOBLIN_PRACTICE -> ~/projects/PROJECT-PRACTICE.md)
    --parts <list>        comma list to install; default = every part the class requires
    --archive             mark the project archive: verify requires no HANDOFF and no gates
    --skills yes|no       install agent skills under .hermes/skills (default no — the harness is
                          neutral; opt in per platform with: gob emit --platform <p>). On a repo whose
                          record already has skills installed, an OMITTED flag keeps them; an explicit
                          --skills no removes them.
    --dry-run             print the plan; write nothing
    --upgrade             re-install at the current version; report created/updated/unchanged/skipped
    --opt-out <part>      record the part in disabled: so its required checks are skipped
    --uninstall           remove exactly the files in installed.json
    --re-pin              re-record practice_sha256: for an edited standard; nothing else changes
    --force               allow overwriting a file goblin-stack did not create
    --yes                 non-interactive; take the defaults above

Exit codes: `0` success or no-op · `1` a refusal, with the path and the fix · `2` bad input or a
missing dependency.

### Idempotency

The installer writes only paths it records, and it **hash-compares before writing**, so running
it twice with the same arguments and the same `VERSION` prints `no-op: N files unchanged` and
exits 0 **without touching a byte**. A different `VERSION` is an upgrade: it rewrites only the
files whose hash changed and prints `created C · updated U · unchanged N · skipped S`.

### Three kinds of file, and why the distinction matters

| kind | recorded as | overwritten? | hash-checked? | removed by `--uninstall`? |
|---|---|---|---|---|
| installed artifact (bin, manifest, roles, opt-in skills, harness scaffold) | `files` | yes, on upgrade | yes — IN-02, SK-02 | yes |
| created once, then yours (`.goblin/goblin.yaml`, `HANDOFF.md`, `AGENTS.md`, `*-SPEC.md`, `reviews/.gitkeep`) | `owned` | never | no — you are meant to edit them | no, except the config |
| pre-existing, left alone | `refused` | never | no — IN-04 only proves it was not taken over | no |

A `refused` path is not a dead end. For `HANDOFF.md` the remedy is the reconciliation in
`docs/ADOPTION.md` ("Adopting into a repo that already has a `HANDOFF.md`"): keep the project's
file, merge the five required sections and a dated gate line in, then verify. `--force` overwrites
it and exists for a scaffold copy with nothing to keep.

An **edited standard is not a dead end** either. `practice_sha256:` pins the referenced standard
and `IN-02` re-checks it, so one intended edit to the standard reds `IN-02` in every installed
repo. The remedy is the explicit re-pin below — not a hand-edit of the hash, and never an
automatic one.

`.gitignore` is not a file goblin-stack owns: it appends **one marked block** and never rewrites
the rest. `.goblin/goblin.yaml` is generated once and is goblin-stack's own config, so
`--uninstall` removes it; `HANDOFF.md`, `AGENTS.md`, `ROUND-000-SPEC.md` and `reviews/` are the
project's record, not the harness's, and are left in place.

### An edited standard is not a dead end

`.goblin/goblin.yaml` records `practice:` and `practice_sha256:`, and `IN-02` re-checks that hash.
The pin has exactly one purpose: to make a **silently** edited standard visible rather than
assumed. The standard itself is a living document, corrected in place, so an edit that is
*intended* needs a deliberate way to re-record the pin. That is all `--re-pin` is:

    goblin-install --target <dir> --re-pin

It rewrites one line of the config — nothing else — and prints both hashes:

    practice re-pinned: /path/to/PROJECT-PRACTICE.md
      recorded 81612b17ac3483b9d613aeb86e236539fc17403e38bf7903af708d369cf7918f
      now      8334ac24f056c94c35fa97831253e7e12bace68ae5747c81ae3b696c42ddd33a

`.goblin/bin/goblin-verify --only IN-02` then reports `practice pin ok`. Every other line of
`goblin.yaml`, comments included, is untouched, so the `owned` contract holds for everything
except the one value you just asked to re-record. Commit the config like any other change.
`--dry-run` prints the plan and writes nothing; when there is nothing to do it prints
`practice pin already current` and exits 0.

Four things it deliberately is not:

- **not automatic.** `goblin-verify` never re-pins, and neither does a plain `--upgrade`: a pin
  that updated itself would be the very silent edit the pin exists to catch. The `practice EDITED`
  failure detail names this command, so the remedy is printed where the operator meets the problem.
- **not a hand-edit.** Editing `practice_sha256:` by hand does work, but nothing then checks that
  you pasted the right hash — which is the one thing this command does for you.
- **not `--force`.** `--force` is about overwriting a file goblin-stack did not create; it has no
  opinion about the pin.
- **not a re-point.** It re-records the hash of the path already in `practice:`. Pointing the repo
  at a *different* standard is a deliberate config edit, not a re-pin.

Refusals are exit `2`, each naming the path: no `.goblin/goblin.yaml`, no `practice:` recorded, the
recorded path absent, or no `practice_sha256:` line to rewrite. A failed write is exit `1`, with
the path — the command never reports a re-pin that did not land. One refusal guards the mode
itself: `--uninstall --re-pin` is exit `2` with `--uninstall and --re-pin are different jobs; run
them one at a time` — the two modes run one at a time, and the pair is refused before anything is
removed.

### Never a half-state

If any write fails the installer prints the file and exits 1. It does not roll back, because
every created file is either a whole file or absent, and the record is written last.

## Verify

    goblin-verify [--only <id[,id...]>] [--json] [--list] [--source <goblin-stack path>]

Output is one line per executed row, in manifest order, plus a summary line at the end:

    PASS  HP-01  (test -f HANDOFF.md)
    FAIL  GT-02  gate commit: false -> exit 1
    ADV   MD-02  code lane and review lane both resolve to the same family
    SKIP  HS-02  no pinned pre-change commit yet - REPLAY not provable

Those four lines are one row of each marking. The summary line of a green default class-A run is:

          38 passed, 0 failed, 11 advisory, 33 skipped

**Exit codes:** `0` every executed check passed (advisories and skips do not fail the run) ·
`1` at least one check FAILED · `2` verify could not run (not installed, a missing dependency,
an unparseable config) · `3` the manifest itself is broken (a row with no check and no
`advisory` label, or a duplicate id).

**What verify asserts, in one sentence:** that the files it installed are the files on disk,
that every rule in the manifest with a command still passes, and that the untestable remainder
is counted and capped.

**What it cannot see** (printed at the end of every run): whether a check in the harness dir
tests the right path rather than merely passing; whether the forge is bound by the workflow
`CL-01` found; whether a human
read the diff; whether the model mapping names a family that actually differs; and whether
`.goblin/installed.json` — the record every drift check trusts — was itself rewritten, since it
is not signed (`docs/LIMITS.md` #18). The CI lane adds its own, and `docs/CI.md` is where the four
settings that make a workflow a **gate** are written down.

### A fresh install verifies green

Measured on a fresh DEFAULT class-A install (skills opt-in, W6 neutral-first), committed with no
hand edit: **`38 passed, 0 failed, 11 advisory, 33 skipped`, exit 0.** Thirty-three rows skip with
a reason — the same not-yet rows as before, plus the five skill rows (`SK-01`..`SK-04`,
`AU-04`) that skip on the `playbooks` opt-out a skills-free install records: `HS-02` — no pre-change commit
is pinned yet, so the REPLAY is not provable (`docs/LIMITS.md` #11) — `AU-02` and `AU-03`, which
have no report to audit in a repo where no reporter has run — `SC-06`, `SC-07` and `SC-08`, which
have no dependency manifest, no lockfile and no audit record to read yet — `PF-01`, which has
no measured perf baseline — `BN-01`/`BN-02`/`BN-05`, which have no `src/` tree for a ban to read,
and `BN-03` with the four electron bans
`BN-06`..`BN-09`, which this class does not enable (`bans: [BN-01, BN-02, BN-05]`), so they skip as
*not enabled* rather than as *unread* — `FM-01`/`FM-02`/`VA-01`, which have no feature map and no declared
`verify_doctor:` yet (`feature_map:` and `verify_doctor:` ship empty on purpose: a fresh install
must not be born RED — G1, `docs/LIMITS.md` #30) — `RC-01`..`RC-04`, which read a declared
reference corpus and a lab `manifests/` directory a fresh install has neither of
(`reference_manifest:` and `quarantine_root:` ship empty on purpose: a repo with no corpus must
not be born RED) — and `JG-01` with `LP-01`..`LP-05`, which have
no `.goblin/loop/` record because no loop has run in this repo: the six judge/loop rows are
**absent-state** rows, and a fresh install must not be born RED either. **Two** rows do
**not** skip, both of them the CI lane's: `PG-05` and `PG-06` read the workflow this class installs.
Two, not four — the four electron bans named in the skip list above do skip here, and a tree without
a renderer would skip them the same way. Every skip above
is a *not yet*, not a pass.

Two of the eleven advisories arrive with the same lane. `JG-02` reports that the judge lane
resolves to **no profile** on this fleet — measured `bash bin/goblin-model judge` →
`judge unknown unknown unknown` — so the row prints the one-line remedy and reports ADV rather
than failing the repo for the fleet's routing (`docs/ROLES.md`, "the measured caveat"). `JG-03`
is the counted advisory row the ceiling had left free for G2 (`docs/ENFORCEMENT.md`).

The class's required parts that only a round can produce do **not** fail on a fresh install; they
pass **vacuously**, and that is the honest reading: `PG-01`..`PG-03` iterate over `reviews/*.md`
and there are none, and the declared gate *is* the shipped floor until step 3 replaces it. `P8`
(`goblin-bootstrap`) walks that first-step list because the work is not done, not because the
verifier is reporting FAILs.

## Opting out, and uninstalling

- **Per part:** `--opt-out <part>` records the part in `disabled:`. `goblin-verify` then reports
  the part's rows as `SKIP (opt-out)` in the summary, so the opt-out is **visible rather than
  absent**. The same mechanism is what makes a class's `-` (off) real.
- **The opt-out numbers are pinned (V3-3).** A class-A install with an explicit `--skills no`
  verifies `38 passed, 0 failed, 11 advisory, 33 skipped`, exit 0, and
  `tests/t-install-off-switch.sh` asserts that line: a silent drift in the opt-out path is caught
  rather than left as a number nobody wrote down (the `--skills no` count moved from `37/0/9/11`
  at v0.2 when the ban rows landed, **15 → 18 on 2026-09-25 (G1)** — the feature-map rows,
  **18 → 24 on 2026-09-25 (W3)** — the judge/loop rows, and **to `38/0/11/33` at W6
  (neutral-first)**, when this opt-out shape BECAME the default and the two lines converged:
  the old default install measured `43/0/11/28`).
- **Skills, W6 neutral-first.** A default install ships no agent skills. A repo whose record has
  `skills: yes` keeps them through every flag-less re-install and `--upgrade` (the installer
  reads the record's choice and says so out loud); an explicit `--skills no` removes exactly the
  recorded skill files; `--uninstall` removes everything recorded, as always.
  `tests/t-install-off-switch.sh` walks that migration: install `--skills yes`, upgrade flag-less,
  the skills survive byte-identical; uninstall, and they are all gone.
- **Whole harness:** `--uninstall` deletes the `files` list plus `.goblin/goblin.yaml`, removes
  every directory that leaves empty (deepest first, after `installed.json` itself is gone — the
  order that used to leave `.goblin/` and the sixteen `.hermes/skills/*` directories behind),
  leaves `HANDOFF.md`, `AGENTS.md`, `ROUND-000-SPEC.md`, `reviews/` and the `.gitignore` block
  (with a `# goblin-stack uninstalled <date>` marker inside it), and prints what it removed and
  what it left.

## The two commands, verbatim

    bash bin/goblin-install --target /path/to/repo --class A
    .goblin/bin/goblin-verify

From a checkout, without installing anything:

    bash tests/run-tests.sh
