# Design

## The thesis

goblin-stack is a small portable repository that installs three things into any target repo:

1. an **executable rule manifest** — every rule carries a runnable check or is explicitly
   counted as advisory;
2. a set of **Hermes project-local skills** that carry the flows;
3. an **installer and a verifier** that prove the first two are still true.

It is not a rules document. A rules document has no enforcement, and the published evidence is
that an LLM-generated context file costs tokens and can reduce resolution. A rule that cannot
be checked is counted and capped instead of asserted.

It is not a port of any Cursor harness. The primitives that carry those harnesses —
`subagent_type`, `/loop`, `/goal`, `environment: "cloud"`, `readonly`, a vendored plugin
directory — do not exist in Hermes. What transfers is the *shape*: an executable matrix, a
bounded panel, a pinned-SHA verdict. What does not transfer is cut, with the reason recorded in
`docs/FLOWS.md`.

## Three load-bearing decisions

### D1 — the enforcement matrix is an executable artifact, not a document

`manifest/enforcement.tsv` has one row per rule. The `check` column holds a real command, the
literal `advisory`, or the marker `goblin-verify --only <ID>` for a check that needs more than
one shell line. A self-check row (IN-03) fails the manifest when a row has neither, and SK-03
caps the advisory count. **The number of unenforceable rules is itself a gate.**

### D2 — skills install as *project-local* skills, never into a profile

Hermes discovers skills at `<project-root>/.hermes/skills/` and gives the project tier the
highest precedence — above `~/.hermes/skills/` and above any profile copy. Project dirs are
treated as repo-owned, so autonomous skill maintenance never rewrites them, and they are
versioned with the code they govern.

This is the design that removes a whole class of rot instead of managing it. Two living copies
of the same rule with no equality check drift; one copy plus a recorded hash does not. The
installer puts the skills in the repo, and `SK-02` hashes what it installed.

### D3 — the gate is chosen by the change, not by the repo, and every review names its SHA

The stakes ladder S0–S4 becomes the `goblin-pr-gate` playbook. The one-line upgrade that
applies at every tier — including a direct push — is that a review note names the SHA it
reviewed: `reviews/<slug>-<head7>.md` with `head:`, `base:`, `patch-id:`, `stakes:`,
`checks-run:`. A verdict is a claim about an artifact, not about a moment, and `PG-03`
re-checks the patch-id so a new head voids it.

## The composition decision: the house style is referenced, never copied

The split is by **kind**, and it is checkable.

- The **standard this repo references** owns the house style: the HANDOFF shape and the
  stale-sentence rule, the SPEC lifecycle, the harness house style and the pinned-commit
  REPLAY, the gate vocabulary, commit discipline, the delegation tiers, data safety, the
  documentation duty, adopt-don't-replace.
- **goblin-stack owns the mechanism**: which rule is enforced by what, how it is installed, how
  it is verified, which class a project is, which flow applies, which role runs a flow.

goblin-stack carries **no copy** of the standard's text. `.goblin/goblin.yaml` holds
`practice:` and `practice_sha256:`; `goblin-verify` re-checks the hash, so a silently edited
standard is visible rather than assumed. If no standard is configured, the checks that depend
on it report advisory, never a failure — that is what makes the repo portable.

## Rejected alternatives

| Rejected | Why |
|---|---|
| A file-for-file port of a Cursor harness | Most of its playbooks are inert without a plugin that is not shipped, and its primitives do not exist here. |
| A "goblin-stack rules" document | The #1 anti-pattern: a rules doc with no enforcement is a measured net cost. |
| Copying the referenced standard into this repo | It is the strongest artifact on the box and must not be weakened; a second copy is exactly the duplication that already rots. |
| Replacing the referenced standard | Would discard the pinned-commit REPLAY rule, the stale-sentence rule, the data-safety rule and adopt-don't-replace — four things no imported source has. |
| Per-project bespoke harnesses | The *gate vocabulary* differs by class, not the harness. Five class presets plus a real off switch. |
| Fan-out by default, auto-merge, or an unattended hillclimb | The axis is read-versus-write, parallel lanes cost about N times the tokens, and no reviewed source ships unconditional auto-merge. |
| A plugin or marketplace package | There is no marketplace here. The portable unit is a `SKILL.md` plus a bash installer. |

## What it deliberately does not do

See `docs/LIMITS.md` and the non-goals in `docs/RISKS.md`. The short version: it does not choose
models, does not write the vault, does not replace any project's existing gate, writes nothing
outside its target, and does not pretend the prose rules are enforced.
