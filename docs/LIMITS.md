# Limits — where this is weaker, and what is unproven

Honest accounting. Nothing here is a hedge for a defect that could be fixed; each is either a
deliberate trade or an unfilled gap.

## Weaker than the Cursor harness it learns from

1. **No live-drive lane is shipped.** A harness that launches and drives the real application is
   what several of the source harness's playbooks depend on, and it is inert without a plugin
   that is not shipped. `P6` can *author* a project-local driver; goblin-stack cannot ship one,
   because that is per-project work. **The "live lane is the floor" rule is stated and
   unfilled.**
2. **No cloud agents.** There is no per-agent computer here, so nothing that needs a machine of
   its own.
3. **No agent graph and no verdict-ledger daemon.** The board replaces both at a lower
   resolution: `parents` expresses ordering, not data flow, and sibling cards cannot see each
   other.
4. **Fourteen playbooks against twenty-three.** The cuts in `docs/FLOWS.md` are deliberate and each
   is argued, but real coverage is lost: performance hillclimbing, pixel parity, trace
   forensics, stack landing, worktree hygiene.
5. **No swarm or arena fan-out.** The read-versus-write axis says that is correct for this work
   mix; it is still a capability the other harness has and this does not.

## Weaker than the status quo it is meant to improve

6. **The biggest measured defect is out of reach.** The orchestrator's routing text says a bare
   subagent spawn reaches the specialist profiles; it does not. That is the highest-cost defect
   on the box, and goblin-stack cannot fix it from inside a project repo. It ships corrected
   text in `docs/INTEGRATION.md` and lints its own artifacts (`MD-03`); the fleet-side edit is
   escalated.
7. **The staleness of a fleet-config repo is detectable and not fixable here** — the E-class gate
   notices it, and the underlying job bug belongs to another repository.
8. **A new surface to maintain.** Per-repo vendored `.goblin/` plus `.hermes/skills/` means
   upgrade debt in every adopted repo, plus one more command pair to learn. The counter is that
   the alternative — profile copies — already failed.
9. **Eight rows are labelled `advisory`, and seven of them are prose with no check at all:**
   `HP-04`, `HS-03`, `CM-02`, `MD-03`, `PG-04`, `DOC-01`, `DOC-02`. One (`MD-02`) is
   advisory-labelled but still reports its state as `ADV`. Each is counted and capped, but a
   counted rule is still not an enforced one, and **the cap is a policy, not a proof.**
10. **It does not reduce the profile-skill surface.** It only stops that surface from growing
    with project procedures; the existing divergence is a separate cleanup.
11. **`HS-02` cannot prove anything until a round lands.** With no pinned pre-change commit it is
    skipped with a reason. That is honest, and it means a brand-new install has **no** REPLAY
    evidence at all. The shipped `checks/assert.mjs` is a scaffold: it asserts something true by
    construction, so `HS-02` correctly reports it as a check that proves nothing until it is
    replaced with real probes.
12. **`HP-03` proves a date exists, not that a number is fresh.** A HANDOFF can carry yesterday's
    number with today's date and pass. Since V1 the row is anchored on the gate names
    `.goblin/goblin.yaml` DECLARES and skips the template's own example sentence, so a real gate
    line can no longer lose its `measured <date>` in silence (G8-2 measured the old row passing
    exactly that); but nothing re-measures the number, and a gate-bearing line that names no
    declared gate and carries no gate-shaped keyword is still unseen.
13. **`PG-04` and `PG-05` are documentation plus a textual heuristic.** A protected branch whose
    only admin is the person pushing protects nothing, and a required check that self-skips
    reports success. Neither is observable from inside a repo.
14. **`CM-02` cannot be enforced.** A backtick lost to command substitution leaves no trace a
    later check can read.

## Unproven at the level that matters

15. **No controlled study of skill efficacy exists.** Published work ablates *context files*, not
    skills, so **nothing here claims the installed skills change agent behaviour.** `P12`
    (`goblin-eval`) is the mechanism to find out, and it has never been run.
16. **Every number in the design is a file read or a third-party published number; none of it is
    a measurement of this harness under load.** The harness was built and its verifier was shown
    RED under a deliberate break; that is a statement about the mechanism, not about outcomes.
17. **One spec deviation, recorded rather than hidden.** The design spec's literal HANDOFF check
    is `grep -q "$(git rev-parse --short HEAD)" HANDOFF.md`, which **can never pass** — committing
    the HANDOFF moves HEAD, so the file can only ever name an ancestor. `HP-05` is therefore
    mechanised as *the HANDOFF names a commit that exists in this repo and is an ancestor of
    HEAD*, which still catches the defect the rule exists for (an artifact that names no commit
    at all). The deviation and its reason are in the row's own `if_not_why` column.
18. **`.goblin/installed.json` is not signed, so nothing here proves it was not rewritten.** Every
    drift check — `IN-02`, `SK-02`, and `HS-01`'s hash of the harness dir — reads its expected
    hash out of that one file, and that file is the one file no check protects. Measured: append a
    byte to `.goblin/bin/goblin-verify`, rewrite its recorded hash in `installed.json`, commit, and
    the run is **fully GREEN** (`41 passed, 0 failed`, exit 0). One edit defeats three rows at
    once, and it is the cheapest way to fake a green run. Doing better needs an anchor the target
    cannot edit — a signature, or a hash held outside the repo — and goblin-stack has no such
    trust root: the source checkout is not guaranteed to exist at verify time, and any value
    stored in the tree is editable by the same hand. It is therefore **recorded here and printed
    in the "cannot see" footer on every run**, not claimed away.
19. **No automation has ever run here.** Cost per run, the respawn guards under a nightly
    producer, and whether `researcher` is the right reporter profile are all unmeasured; the
    first watched run of A-02 is what produces those numbers. The producer's own ceiling is a
    **run count**, not a dollar figure — no config key holds the spend cap, so no automation can
    read it, and none pretends to.
20. **The dedup key is a dedup, not a mutex.** The board's lookup runs before the write
    transaction, so a concurrent create can insert twice and the next lookup stabilises on the
    newest. The key stops a duplicate storm; it does not make one impossible.
21. **`AU-02`'s normalisation is only measured on synthetic reports.** Two differently-typed
    copies of one symptom give one key and a different symptom gives another, but whether a real
    report set normalises well enough is unknown. Its failure mode is a duplicate card, never a
    lost report.
22. **No audit has ever run against a real registry here.** Everything `SC-07` does was measured
    against a canned npm-audit report (`tests/t-audit.sh`), so the parse is proven, the *policy*
    is not: whether the recorded waiver set matches the real advisory set is unknown until the
    first real `goblin-audit`. Its skip-with-a-reason behaviour on a repo with no record is what
    keeps that honest rather than silent.
23. **The audit record is read by field name, not by a JSON parser.** `goblin-audit` recognises
    npm's `vulnerabilities` / `via` shape (`source`, `name`, `url`, `range`) with awk and REFUSES
    (exit 5) anything it cannot parse, rather than writing an empty record that `SC-07` would read
    as clean. A different audit tool is therefore a refusal, not a silent pass.
24. **The freshness rows need a GNU `date -d`.** `SC-07` parses the record's date that way; on a
    host without it the row FAILS with the reason rather than assuming the record is fresh.
25. **`SC-04` reads one statement, not one program.** A cookie write spread over three lines (or
    assembled through a helper) is not seen, and the row says so in its own cell.

## What the harness refuses to do

It does not claim a green run means the work is right. `goblin-verify` asserts that the installed
files are the files on disk, that every rule with a command still passes, and that the
untestable remainder is counted and capped — and it prints, on every single run, the five things
it cannot see.
