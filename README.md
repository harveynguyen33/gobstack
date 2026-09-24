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
| `docs/FLOWS.md` | the 12 playbooks, with the 11 cuts and a reason for each |
| `docs/ROLES.md` | roles versus profiles, the model-mapping contract, the fan-out rule |
| `docs/ENFORCEMENT.md` | the matrix rendered for a human, and how a rule is added |
| `docs/CONTRACTS.md` | the installer/verifier interface, exit codes, idempotency, uninstall |
| `docs/INTEGRATION.md` | the board, cron, the skills precedence order, the referenced standard |
| `docs/RISKS.md` | the risk register, the advisory rows named, the non-goals |
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

After installing, in this order:

    cd <target> && git add -A && git commit   # the install is a change like any other
    .goblin/bin/goblin-verify                 # a fresh class-A install: 33 passed, 0 failed
    hermes skills trust <target>              # one-time, so the project-tier skills load

**A fresh class-A install verifies green: `33 passed, 0 failed, 8 advisory, 1 skipped`, exit 0.**
Only `HS-02` skips (no pre-change commit is pinned yet, so the REPLAY is not provable). The parts
that only a round can produce — a first review note, a gate that is not the shipped floor — pass
*vacuously* rather than failing, and `P8` (`goblin-bootstrap`) still walks them as work to do.
The measurement and the vacuous-pass reading are in `docs/CONTRACTS.md`.

## Verify

    .goblin/bin/goblin-verify [--only <id[,id...]>] [--json] [--list] [--source <path>]

Exit codes: `0` pass · `1` a check failed · `2` could not run · `3` the manifest is broken.
Every run prints what it cannot see.

## Develop

    bash tests/run-tests.sh

Runs the source-scope rules (PR-01..PR-04) and the test scripts, including `t-verify-red.sh` —
one control per target-scope row (42), each required to go RED and then restored. **A verifier
that only ever prints GREEN is a failure**, so that file is the one that matters most.

## Uninstall

    bash bin/goblin-install --target <dir> --uninstall

Removes the installed artifacts, `.goblin/goblin.yaml` and every directory that leaves empty, and
leaves `HANDOFF.md`, `AGENTS.md`, `ROUND-000-SPEC.md`, `reviews/` and the `.gitignore` block —
the project's record is not the harness's to delete.

## Dependencies

`bash`, `git`, `awk`, `sed`, `grep`, `python3`. No npm, no jq, no yq, no network.

## License

MIT.
