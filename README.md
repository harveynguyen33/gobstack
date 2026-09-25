# goblin-stack

A small, portable, Hermes-native repository that installs an **executable rule manifest**, a set
of **project-local skills**, and an **installer/verifier pair** into any project — so that a
session never re-improvises, and a rule that cannot be checked is counted rather than asserted.

Two commands:

    bash bin/goblin-install --target /path/to/repo --class A
    .goblin/bin/goblin-verify

## What it is not

Not a rules document (every rule carries a runnable check or is explicitly counted as
advisory). Not a Cursor-plugin port (`subagent_type`, `/loop`, `/goal`, cloud agents and
vendored plugin paths do not exist in Hermes). Not a replacement for a project standard — it
**references** one by path and pins its hash, and carries none of its text.

## Read this on GitHub

| file | what it decides |
|---|---|
| `docs/DESIGN.md` | the thesis, the three load-bearing decisions, and every rejected alternative |
| `docs/FLOWS.md` | the 14 playbooks, with the 11 cuts and a reason for each |
| `docs/GUARDRAILS.md` | the security and perf rows (`SC-01`..`SC-09`, `PF-01`), the rung ladder, and what they cannot see |
| `docs/ROLES.md` | roles versus profiles, the model-mapping contract, the fan-out rule |
| `docs/ENFORCEMENT.md` | the matrix rendered for a human, and how a rule is added |
| `docs/CONTRACTS.md` | the installer/verifier interface, exit codes, idempotency, uninstall |
| `docs/INTEGRATION.md` | the board, cron, the skills precedence order, the referenced standard |
| `docs/RISKS.md` | the risk register, the advisory rows named, the non-goals |
| `docs/LOOP.md` | the judge role and the loop contract: what Hermes's `goal_mode` actually does, the record, and what neither can see |
| `docs/ADOPTION.md` | the five classes, the preset matrix, the adoption order |
| `docs/LIMITS.md` | where this is weaker than its sources, and what is unproven |

`manifest/enforcement.tsv` is the source of truth for rules; `manifest/classes.tsv` for what a
class requires; `manifest/playbooks.tsv` for the flows; `manifest/glossary.tsv` for the
vocabulary.

## Install

    bash bin/goblin-install --target <dir> --class A|B|C|D|E [options]

It writes only paths it records, hash-compares before writing, and prints `no-op` on a second
run with the same arguments. It never overwrites `HANDOFF.md`, `AGENTS.md`, a `*-SPEC.md`,
`reviews/`, the `.gitignore` block or `.goblin/goblin.yaml`. Full option list and the three
kinds of file it manages: `docs/CONTRACTS.md`.

A repo that already has its own `HANDOFF.md` exits 1 on the refusal. That is the contract, not a
failure: reconcile the file rather than forcing over it — `docs/ADOPTION.md`.

After installing, in this order:

    cd <target> && git add -A && git commit   # the install is a change like any other
    .goblin/bin/goblin-verify                 # a fresh class-A install: 42 passed, 0 failed
    hermes skills trust <target>              # one-time, so the project-tier skills load
    .goblin/bin/goblin-audit                  # once, deliberately: the ONLY network step (SC-07)

**A fresh class-A install verifies green: `42 passed, 0 failed, 11 advisory, 20 skipped`, exit 0.**
Twenty rows skip (`HS-02` has no pinned pre-change commit yet, so the REPLAY is not provable;
`AU-02` and `AU-03` have no report to audit; `SC-06`, `SC-07` and `SC-08` have no dependency
manifest, no lockfile and no audit record to read; `PF-01` has no measured perf baseline;
`BN-01`/`BN-02`/`BN-03`/`BN-05` have no `src/` for a ban to read; `FM-01`/`FM-02`/`VA-01`
have no feature map and no declared `verify_doctor:` yet; and `JG-01` with `LP-01`..`LP-05`
have no loop record, because no loop has run in this repo yet). Two of the eleven advisories
are new with the judge lane: `JG-02` reports that the judge lane resolves to no profile on this
fleet (it prints the one-line remedy and never fails a repo for a fleet's routing), and `JG-03`
is the counted row the advisory ceiling had left for it. The parts
that only a round can produce — a first review note, a gate that is not the shipped floor — pass
*vacuously* rather than failing, and `P8` (`goblin-bootstrap`) still walks them as work to do.
The measurement and the vacuous-pass reading are in `docs/CONTRACTS.md`.

## Verify

    .goblin/bin/goblin-verify [--only <id[,id...]>] [--json] [--list] [--source <path>]

Exit codes: `0` pass · `1` a check failed · `2` could not run · `3` the manifest is broken.
Every run prints what it cannot see.

## Develop

    bash tests/run-tests.sh

Runs the source-scope rules (PR-01..PR-05) and the test scripts, including `t-verify-red.sh` —
one control per target-scope row (60 over 57 target rows), each required to go RED and then
restored, plus `t-audit.sh` for the SC-07 producer. **A verifier that only ever prints GREEN is a
failure**, so that file is the one that matters most.

## Uninstall

    bash bin/goblin-install --target <dir> --uninstall

Removes the installed artifacts, `.goblin/goblin.yaml` and every directory that leaves empty, and
leaves `HANDOFF.md`, `AGENTS.md`, `ROUND-000-SPEC.md`, `reviews/` and the `.gitignore` block —
the project's record is not the harness's to delete.

## Re-pin the referenced standard

    bash bin/goblin-install --target <dir> --re-pin

`practice_sha256:` pins the referenced standard and `IN-02` re-checks it, so editing that standard
— a legitimate, intended edit — reds `IN-02` in every installed repo. `--re-pin` re-records that
one line and prints the old and new hash; `IN-02` then reports `practice pin ok`. Nothing re-pins
automatically, not even `--upgrade`, and the `practice EDITED` failure prints this command. The
whole contract: `docs/CONTRACTS.md`, "An edited standard is not a dead end".

## Dependencies

`bash`, `git`, `awk`, `sed`, `grep`, `python3`. No npm, no jq, no yq, no network.

## License

MIT.
