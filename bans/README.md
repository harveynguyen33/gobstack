# The ban list — forbidden must fail mechanically

`manifest/bans.tsv` is the table; `bin/goblin-bans` is the engine; this directory holds the
probes. Dune's rule 2, made a gate: **a ban without a mechanism is a wish.** A ban enters
`bans.tsv` only with a real command in its `detect` column, or it does not enter at all.

## How a ban is run

```
.goblin/bin/goblin-bans              # every ban the config's `bans:` list turns on
.goblin/bin/goblin-bans --only BN-01 # one ban
.goblin/bin/goblin-bans --list       # the table
```

A `detect` command runs from the repo root and exits

| exit | meaning |
|---|---|
| 0 | the tree is clean |
| 1 | the ban is violated — the exit code alone is the signal; stdout, when any, names the offending lines |
| 2 | the check could not run — **fail closed**, never a silent pass |
| 3 | nothing to check (e.g. no `layers:` declared) — SKIP with that reason |

A ban the config does not name is SKIPPED with that reason; a ban whose `globs` match no file
is SKIPPED with that reason. An empty or missing table is **exit 2**.

## No npm, no AST

The engine uses `bash`/`grep`/`awk` only — the dependency contract in `docs/CONTRACTS.md`. So
these are **text probes**, not AST checks: a `: any` inside a string or a comment is reported,
and `Record<string, any>` (no leading `:`) is missed. The AST-grade form of the same bans needs
a parser the contract does not allow; that gap is `docs/LIMITS.md` #27, stated rather than
hidden. A text probe with a known false-positive set is still a gate — it goes red on the move
it forbids — which is what a ban is for.

## Turning a ban on

```yaml
bans: [BN-01, BN-02, BN-05]      # the bans this project turns on; an unlisted ban SKIPs
bans_exempt:                     # narrow, explicit, reviewed (Dune rule 5)
  - BN-03 src/legacy             # <ban id> <path prefix>
layers:                          # what BN-05 reads; "<from> <to>"
  - src/renderer src/main
```
