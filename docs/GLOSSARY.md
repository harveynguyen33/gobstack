# Glossary

Every term of art in one table, rendered from `manifest/glossary.tsv` — that file is the source;
edit it there and re-render (or hand-render: one row per term, alphabetical, the definition one
sentence). A term a new reader might trip on belongs here, not in a footnote.

| term | definition | source |
|---|---|---|
| advisory | A rule with no executable check. Counted in the verify summary and capped by advisory_ceiling; never a silent pass. | R6 sec.5 |
| archive | A class-D flag: verify requires no HANDOFF and no gates, and the summary says so. | R7 sec.2.4 |
| class | A project category A-E that selects which parts are required, optional or off. See manifest/classes.tsv. | R7 sec.4 |
| drift | A file whose current bytes no longer match the hash recorded at install time. IN-02 reports it; the remedy column says how to recover. | UX-review-2026-10-06 |
| engine | The bash programs plus the manifest a verify run actually resolved: per-repo (.gob/bin) or global (engine_dir:). Named in every run's footer. | UX-review-2026-10-06 |
| forge | The hosting platform a repo pushes to (GitHub, GitLab, ...). PG-05 and PG-06 read the workflow text but can never see what the forge itself enforces. | UX-review-2026-10-06 |
| foreman | The orchestrating agent that delegates work to the fleet; the role that reads HANDOFF.md first and writes it last. | UX-review-2026-10-06 |
| gate | A declared command that must exit 0. Declared per project, never inferred from the stack. | PP sec.4 |
| HANDOFF | The session-boundary contract at the repo root: START HERE / State / Gates / Next steps / NOT verified. | PP sec.1 |
| harness | An asserting check file: a failures counter, an assert(name, ok, detail) printer, and a non-zero exit on failure. | PP sec.3 |
| judge | A role that decides whether a PROCESS met its own predicate, from a command's output and a pointer it can resolve - never from a report. One lane per verdict; never the author's lane. | docs/LOOP.md |
| lane | A family of rules that share a mechanism and a blind spot: the ban lane, the judge/loop lane, the CI lane, the reference lane. The cannot-see footer reports per lane. | UX-review-2026-10-06 |
| loop | One unattended run over a predicate, recorded in the committed .gob/loop/ (predicate, pin, first-run, budget, one decisions.tsv row per iteration). | docs/LOOP.md |
| never-relax | The predicate's digest is recorded at loop start and never updates itself; relaxing it is closing this loop and opening another, with the old predicate archived under .gob/loop/closed-<date>/. | docs/LOOP.md |
| opt-out | A part recorded in disabled: so its required checks report SKIP (opt-out) instead of failing. | R6 sec.6.3 |
| overnight | P10: an unattended run over a checkable predicate written before iteration 1. | R6 sec.3 |
| part | One installable unit a class requires or forbids: handoff, spec, gate, replay, ratchet, pr-gate, review-panel, playbooks, tokens. | R7 sec.5 |
| patch-id | git patch-id --stable of base..head. A new head voids a verdict; a matching commit message does not restore it. | R1 sec.10 |
| playbook | A named, ordered procedure with a measurable verification step. goblin-stack ships 15. | R6 sec.3 |
| predicate | One shell command that exits 0 when the loop is finished. Written before iteration 1 and run once before it, so its first state is known to be red. A duration is not a predicate. | docs/LOOP.md + pstack guide/07 |
| preimage | The input that produces a known hash. The hash checks here prove non-drift, not preimage resistance - they are tamper-evidence, not signatures (docs/LIMITS.md #18). | UX-review-2026-10-06 |
| profile | A worker identity in the Hermes fleet (architect, coder, reviewer, ...). Owns memory and skills. | R4 |
| review-panel | N independent verdict lanes, each its own card with its own resolved model. Only at stakes S3+. | R6 sec.4.3 |
| REPLAY | Re-running each assertion against the pinned pre-change commit and requiring it to be RED there. A check green on both trees proves nothing. | PP sec.3 |
| ratchet | A count that must not rise, with a declared ceiling; a rise is allowed only when re-anchored with the arithmetic (old + N new = new). | PP sec.4 |
| role | What the work needs: code \| judgment \| review-panel \| synthesis \| investigate \| judge. A role maps to a profile; it never names a model. | R6 sec.4.1 |
| round | One full pass of the work cycle: plan, implement, gate, replay, hand off. The unit a wave code counts. | UX-review-2026-10-06 |
| skill | A Hermes SKILL.md directory. goblin-stack installs its skills into the target repo at .hermes/skills/ (project tier), never into a profile. | R6 sec.0.1 / sec.7.3 |
| SPEC | A per-round document written before implementation: measured root cause plus an AC: list checkable without a human. | PP sec.2 |
| stakes | The S0-S4 ladder that chooses the review gate strength by the change, not by the repo. | R5 sec.3.2 |
| sweep | P11: the same change or question across many projects, enumerated by glob, one card each. | R6 sec.3 |
| vendored | Copied into the repo rather than read from the package, so it survives offline and is hashed by IN-02 like any installed file. | UX-review-2026-10-06 |
