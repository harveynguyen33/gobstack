---
name: goblin-eval
description: P12: measure whether a skill or prompt change did anything, blinded.
---

# goblin-eval (P12)

Use when a skill or prompt changed and you want to know if it did anything — including when the
thing that changed is a **generated verification skill** (P6's output). This is the only mechanism
goblin-stack has for that question, and it has never been run — treat its output as a first
measurement, not a verdict. The runner is **not shipped**: every step below is a procedure an
operator executes, and no row in `manifest/enforcement.tsv` reads a lane yet.

1. **Candidate and control run in sanitized directories.** Same task, same starting tree, one
   difference. Sanitized means a **clean workspace with nothing borrowed**: no prior chats, no
   prior artifacts, no prior executions. An agent that can reach a previous run can produce the
   answer without using the skill, and then the eval measures nothing but the leak.
2. **No condition token anywhere the candidate can see.** The ban is eleven tokens — `eval`,
   `test`, `judge`, `experiment`, `rubric`, `score`, `compare`, `benchmark`, `candidate`,
   `arena`, `control` — not only the four this skill used to name, and it covers the directory
   names, the file names and the prompt. A candidate that knows it is being graded changes
   behaviour.
3. **Grade the chain from the transcript** — which files it actually opened, which commands it
   ran — never the self-report.
4. **The judge runs as `role-judge`, on a lane disjoint from the candidate's.** A model grading its
   own family's output is grading itself; the lane that decides must not be the lane that wrote.
   `JG-02` checks the declared lanes are disjoint, and reports an unresolved judge lane as `ADV`
   rather than failing a repo for the fleet's routing. What the judge receives, what it must
   refuse and how its verdict is recorded is `docs/LOOP.md` — the short form is: **a predicate and
   a handle the repo can resolve, never a self-report.**
5. **Write the record where the next reader looks.** One directory per eval, `evals/<slug>/`:
   `prompt.md` (the one organic prompt, identical across lanes), `rubric.md` (3–6 criteria, for
   the judge only), `manifest.tsv` (`lane · condition · label · profile · provider · model ·
   family · workspace · card_id · session_id · transcript`), `transcripts/<label>.jsonl` (the
   exported session, one file per lane) and `verdict.md` (the judge's per-criterion scores, each
   with an `evidence:` line naming the lane and the location). The **family** is recorded, never
   only the model slug — and **no model slug belongs under `skills/ manifest/ bin/ templates/
   presets/ .goblin/ .hermes/`**; `evals/` sits outside that scope on purpose, because a slug is
   run data, not content for a rule.
6. **A change must improve the evaluated cases or add new evaluations.** That is the merge rule,
   and it is this repo's "a check must be able to go RED" applied to skill prose: changing
   instructions requires evidence about the resulting behaviour, not a judgement that the new
   wording sounds better. **When the subject is a generated verification skill, the pass condition
   is a number**: every seeded defect must make the harness RED, the control (the same defects
   against a harness carrying no assertions) must detect **zero**, and every correction must be
   RED before it is GREEN. A skill that misses a seeded defect has a hole; a sensitivity below
   1.0 is reported with the number beside it, never rounded up to a pass.
7. **Cheap checks first; the judge last.** Regex and script assertions for what is concrete (the
   right SDK, the right method, the absence of an obsolete pattern); an LLM judge with an explicit
   rubric only for what needs interpretation. **Triggering is a diagnostic, not the objective** —
   loading the skill on the fifth turn can be fine and completing the task without loading it can
   be fine too, so the trigger result stays visible without defining pass/fail.

## Verification

- The judge's verdict is reproducible from the transcripts alone.
- Candidates never learn that other candidates exist.
- Every lane named in `manifest.tsv` has a transcript file that exists.
- A generated verification skill is not "verified" until a record exists for it: its declared
  doctor exits 0 (`VA-01` is the executable half), and the record carries the sensitivity.

## What this cannot see

Small effects. With a handful of runs, a difference smaller than the run-to-run variance is
noise, and no amount of prose makes it a signal. It also cannot see **its own blinding**: on a
machine where a candidate holds terminal access, sibling workspaces, sibling cards and other
sessions are readable, so blinding is a discipline with a detector rather than a property. And
the runner is not shipped — with no record, this skill is a procedure, not a measurement.
