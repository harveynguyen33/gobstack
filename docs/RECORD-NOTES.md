# Record notes — the wave codes

The CHANGELOG, the enforcement matrix's parentheticals, and the older commit messages name
revisions by a short wave code. This file is the legend: one line each, oldest last. The prose
documents (README, GUIDE) do not use the codes; when one of these revisions matters to a reader,
the docs name it by what it changed and point here.

| code | revision | in one line |
|---|---|---|
| W1 | engine mode | the rule table can live in a shared engine (`engine_dir:`), not only per-repo; declared-but-unusable is exit 2 with no fallback |
| W3 | `gob upgrade` | the 8-step migration of a repo to the global engine, two commits, refusal on every unsafe tree |
| W4 | class + ci-gate | the five domain classes replaced the A–E letters (read-time aliases kept), and `ci-gate` became a declared part with its own workflow |
| W5 | report width | the verify report learned columns: payloads fold at the report width, multi-line payloads print whole, `--verbose` prints everything |
| W6 | neutral-first | a default install ships no agent skills, the desktop class merged into software, and the wizard got its health-check screen |
| G8 | audit finding 8 | the verify-UX audit's surface classes: refusals that print nothing, rows that pass vacuously, `--only` selections that run nothing |
| G8-2 | stdout discipline | the engine banner moved to stderr; stdout carries verdict lines and the run's own annotations only |
| X1 | exit-code audit | every refusal and every silent path got a distinct exit code and a stated reason (0 green, 1 red, 2 refusal/config, 3 skip-by-design) |
| AB3 | claims pinned | every count a document states about this artifact is asserted against a real install (file maps, row counts, summary lines) |
| Z1 | record integrity | the loop/judge record contract: pins, digests, the never-relax rule, and what a record proves versus what it cannot |
| V3 | day-one framing | the verify run explains its reds to a newcomer: remedy lines under FAILs, the owner-mismatch note, the fresh-clone banner, recovery lines |
| G9 | guide re-walk | docs/GUIDE.md re-walked on the wizard path with every number re-measured (see t-doc-guide-init.sh) |
