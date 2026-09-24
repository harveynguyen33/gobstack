# Contracts — installer and verifier

Dependencies: **`bash`, `git`, `awk`, `sed`, `grep`, `python3`.** No npm, no jq, no yq, no
network. `python3` is used for one thing only: reading the two-level model mapping file, the
same way the fleet's own tool reads it. Everything else is line-oriented shell.

## Install

    goblin-install --target <dir> [options]

    --target <dir>        required; the repo root to install into
    --class A|B|C|D|E     required unless --uninstall or --re-pin
    --models <path>       model mapping file   (default: $GOBLIN_MODELS -> ~/projects/fleet-model.yaml)
    --practice <path>     the referenced standard (default: $GOBLIN_PRACTICE -> ~/projects/PROJECT-PRACTICE.md)
    --parts <list>        comma list to install; default = every part the class requires
    --archive             mark the project archive: verify requires no HANDOFF and no gates
    --skills yes|no       install .hermes/skills (default yes; needs the one-time trust step)
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
| installed artifact (bin, manifest, roles, skills, harness scaffold) | `files` | yes, on upgrade | yes — IN-02, SK-02 | yes |
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
recorded path absent, or no `practice_sha256:` line to rewrite.

### Never a half-state

If any write fails the installer prints the file and exits 1. It does not roll back, because
every created file is either a whole file or absent, and the record is written last.

## Verify

    goblin-verify [--only <id[,id...]>] [--json] [--list] [--source <goblin-stack path>]

Output is one line per executed row, in manifest order:

    PASS  HP-01  (test -f HANDOFF.md)
    FAIL  GT-02  gate commit: false -> exit 1
    ADV   MD-02  code lane and review lane both resolve to the same family
    SKIP  HS-02  no pinned pre-change commit yet - REPLAY not provable
          33 passed, 0 failed, 8 advisory, 1 skipped

**Exit codes:** `0` every executed check passed (advisories and skips do not fail the run) ·
`1` at least one check FAILED · `2` verify could not run (not installed, a missing dependency,
an unparseable config) · `3` the manifest itself is broken (a row with no check and no
`advisory` label, or a duplicate id).

**What verify asserts, in one sentence:** that the files it installed are the files on disk,
that every rule in the manifest with a command still passes, and that the untestable remainder
is counted and capped.

**What it cannot see** (printed at the end of every run): whether a check in the harness dir
tests the right path rather than merely passing; whether the target repo has CI; whether a human
read the diff; whether the model mapping names a family that actually differs; and whether
`.goblin/installed.json` — the record every drift check trusts — was itself rewritten, since it
is not signed (`docs/LIMITS.md` #18).

### A fresh install verifies green

Measured on a fresh class-A install, committed with no hand edit: **`33 passed, 0 failed,
8 advisory, 1 skipped`, exit 0.** The single skip is `HS-02` — no pre-change commit is pinned
yet, so the REPLAY is not provable (`docs/LIMITS.md` #11).

The class's required parts that only a round can produce do **not** fail on a fresh install; they
pass **vacuously**, and that is the honest reading: `PG-01`..`PG-03` iterate over `reviews/*.md`
and there are none, and the declared gate *is* the shipped floor until step 3 replaces it. `P8`
(`goblin-bootstrap`) walks that first-step list because the work is not done, not because the
verifier is reporting FAILs.

## Opting out, and uninstalling

- **Per part:** `--opt-out <part>` records the part in `disabled:`. `goblin-verify` then reports
  the part's rows as `SKIP (opt-out)` in the summary, so the opt-out is **visible rather than
  absent**. The same mechanism is what makes a class's `-` (off) real.
- **Whole harness:** `--uninstall` deletes the `files` list plus `.goblin/goblin.yaml`, removes
  every directory that leaves empty (deepest first, after `installed.json` itself is gone — the
  order that used to leave `.goblin/` and the fourteen `.hermes/skills/*` directories behind),
  leaves `HANDOFF.md`, `AGENTS.md`, `ROUND-000-SPEC.md`, `reviews/` and the `.gitignore` block
  (with a `# goblin-stack uninstalled <date>` marker inside it), and prints what it removed and
  what it left.

## The two commands, verbatim

    bash bin/goblin-install --target /path/to/repo --class A
    .goblin/bin/goblin-verify

From a checkout, without installing anything:

    bash tests/run-tests.sh
