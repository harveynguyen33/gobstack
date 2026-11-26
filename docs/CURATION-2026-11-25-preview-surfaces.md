# Curation — what the tech-goblin preview round taught gobstack (2026-11-25)

One project, mined for rules that are true beyond it. This file is the analysis, not the adoption: every
proposal is stated so it can be argued with, priced, or refused on the record.

**Evidence base.** `tech-goblin.com` frontend, 2026-11-24 → 2026-11-25: one feature (owner-only draft
preview) built in three rounds — preview mode behind an HMAC cookie, then a decoupling pass that moved the
preview to its own route namespace and returned the public writing routes to ISR, then a chrome-parity pass
after the owner rejected the preview because it did not look like the published page. Commits `2d9407d`,
`453cf80`, `21fc5c2`, `eaa6ac0`, `8ea81ec`, `91a5955`; one verification harness at 25 gates plus one
browser-only measurement harness. Numbers quoted here were measured on that deployment; the failures named
are the ones that happened, with the artifact that shows them.

**What makes this round worth mining.** Every failure in it was a *review-artifact* failure, not a feature
failure: the code did what it was asked and the thing the human was shown still led them to the wrong
conclusion. Three of the six cost a full round (one of them, twice, because the first fix did not address
the cause).

---

## 0. The standing rule this file is held to

A lesson may enter gobstack only if it is true regardless of framework: a row states a rule that holds with
no framework named, and framework-specific mechanics stay in the project's own skill. A mechanism may read
per-framework conventions ONLY as heuristics — a repo without those conventions gets `SKIP` with the reason,
never a RED. This rule governs everything below, including the verdicts in §1, the withdrawal recorded in §3
and what §5 refuses.

---

## 1. The seven candidates, ranked by leverage

| # | Lesson | Class | Mechanisable today | Verdict |
|---|---|---|---|---|
| P1 | A surface that exists to be reviewed must render the artifact that will be published | verification / review | partly, import probe | **adopt (opt-in lint)** |
| P2 | A streaming boundary above a "not found" decision commits the status before the decision is made | verification / web | yes, text probe | **withdrawn after review — framework-specific (`loading.*` / `notFound()`); see §3** |
| P3 | A build-time list is not a runtime list | publishing / caching | shape only | advisory |
| P4 | A preload claim needs two timestamps, not one stopwatch | verification | no | advisory |
| P5 | "Cannot leak" is proven by the absence of a code path, not by the absence of an observed behaviour | isolation / security | partly | advisory (strong later row) |
| P6 | One working tree, one agent — and the commit proves which branch it landed on | process / governance | shape only | advisory (proposed `AG`-class script) |
| P7 | A delegated agent's green is a claim, not a state | delegation | already covered | **no new row** — see §4 |

---

## 2. The adoptions, with the failure that justifies each

P2 was **withdrawn after review** as framework-specific; its failure story now lives in §3 with the
withdrawal reason. What follows is the one adoption that survived the standing rule (§0).

### P1 — a review surface must render the artifact that will be published

**Failure.** The preview shipped with its own minimal root layout: a banner, the article, nothing else. The
owner opened it and reported that the floating chips (scroll-to-top, the language switcher) were missing and
that the language control had moved to a top-left tab strip. He was right, and the round was wasted: the
review surface existed to let him judge the published render, and it was rendering a different page. The
fix (`91a5955`) mounts the production shell — the same provider, nav, footer and floating chips, the same
fonts and dark class — and leaves exactly three differences, each one declared: a banner strip in normal
flow above the nav, `noindex`, and no analytics/JSON-LD (owner visits must not pollute the numbers).

**Rule (project-independent).** *A surface that exists to be reviewed renders the same shell the published
surface renders; every remaining difference is enumerated in the surface's own source, so a difference is a
decision rather than an accident.*

**Mechanism (proposed `PV-01`, opt-in lint).** For each route directory the project config names as a review
surface, the layout file must import the same shell module(s) the public layout imports, **or** carry
`preview_differs: <comma list>` naming every difference it keeps. Red when the surface renders a shell the
public tree does not use and declares nothing. The detection reads route-tree/shell conventions — what
counts as a review surface, what names the shell — as heuristics: a repo whose conventions the probe cannot
read gets `SKIP` with the reason, never a RED (the standing rule, §0). The intersection counts project CODE
modules only: a shared stylesheet or any style/asset import proves the same theme, never the same shell,
and a side-effect import wires a module without naming what renders — neither is evidence.

**Honest limit (goes in the row's `if_not_why`).** An import probe proves the module is reachable from the
file, never that the render is identical: a shell imported and then overridden by a local wrapper passes
while still differing. The stronger form is a design change — one `SiteShell` component both trees import —
and this project needed the probe *before* it had the design.

---

## 3. The advisory set (no mechanism yet, and why)

- **P2 — withdrawn after review (framework-specific).** The failure was real — a draft slug that must 404
  answered **HTTP 200** with a body reading "Not Found": a streaming boundary at the segment flushed `200`
  before the not-found decision could run, and every status-code check read the lie as truth (the same class
  then hid a build-time-params trap behind a passing 404 test). But the rule as stated is only true where
  one framework's conventions exist: the boundary is `loading.*`, the decision API is `notFound()`, both live
  in a single framework's route tree. Under the standing rule (§0) that cannot be a gobstack row — the
  proposed `PV-02` was **removed from `library.tsv`, the verifier and LIMITS** (a one-line tombstone keeps
  the old number stable), and the defect class moved to the project's own skill. The general residue that
  *did* travel: P3 below.
- **P3 — a build-time list is not a runtime list.** `generateStaticParams` runs at build; `dynamicParams =
  false` then 404s anything published since. The honest mechanism is only a *shape* check ("a page exporting
  generateStaticParams declares `dynamicParams` explicitly"), which proves a decision was made, not that it
  suits a project whose content arrives at runtime. Advisory, with the sentence in the verify-author skill:
  *a static list proves the build, and says nothing about content created after it.*
- **P4 — a preload claim needs two timestamps.** A coder reported "prefetch proven before click". Measured
  honestly: the RSC request's `startTime` (4353 ms) came *after* the click (4348 ms) — no prefetch happened
  at all, and the 57 ms the harness celebrated was loopback latency. The general form: *an ordering claim
  names the request, its start time and the interaction time, and the comparison is printed.* That is a
  measurement discipline, not a lint (a timestamp comparison inside a harness is exactly the decorative-guard
  case `HV-02` already admits it cannot judge). Advisory; belongs in the verify-author skill beside HV-02.
- **P5 — "cannot leak" is an absence of code path.** The first preview leaked draft titles into the public
  index because the public tree read the preview cookie. The fix that made the claim *provable* was
  structural: the public tree now contains zero cookie reads and zero draft fetches, so a grep can witness
  the absence, and the preview owns a separate route namespace. A probe would have to know which call is
  "the draft-capable fetch" in each stack; today that is a review question ("show me the grep"), and the
  answer in this project was `grep -r "cookies()" app/(frontend) → 0`. Strong candidate for a later row once
  a second project states the same shape.
- **P6 — one working tree, one agent.** A commit made while another agent had a different branch checked out
  landed on that branch; the push "succeeded" and `origin/main` never moved, and the discrepancy was found by
  `git branch --contains <sha>` three hours later. The protocol that would mechanise it: a tree declares its
  current owner and intended branch (`.gob/active-branch`), the pre-commit refuses a mismatch. That is a
  coordination protocol, not a check, and gobstak has no per-tree lock concept yet. Advisory, with the
  recovery command recorded because that is what actually saved the round.
- **P7 — a delegated agent's green is a claim.** Two self-reported gates this round were false (the prefetch
  one, and a `dynamicParams = false` comment asserting a behaviour the framework does not have). Both were
  caught by re-running the measurement, not by reading the report. This is **already** the shape of `HP-03`
  ("every gate number is a measurement with a date, never a copy") plus the delegation tiers in the standard;
  no new row. Recorded here so the next curation does not propose it again.

---

## 4. Where these should live, concretely

| Proposal | Matrix row | Skill touch | Doc touch |
|---|---|---|---|
| P1 | `PV-01` (opt-in, lint) | `goblin-verify-author`: "render the artifact, not a sketch of it" | LIMITS: an import is not a render |
| P2 | withdrawn after review (was proposed `PV-02`) — framework-specific | — (defect class in the project skill) | LIMITS: one-line tombstone at the old number |
| P3, P4 | — (advisory) | `goblin-verify-author`: two sentences, dated failures named | — |
| P5, P6 | — (advisory, named candidates) | `goblin-handoff` / `practice`: the grep and the branch proof | GUIDE: recovery commands |
| P7 | none (covered by `HP-03`) | — | — |

Cost estimate, from the shape of the existing checks: the surviving `PV-*` row is the `BN-01` class — grep
over text, no AST — two hours including a negative control that proves the row RED under its own violation.
It is opt-in: a repo that declares no review surface gets `SKIP` with the reason, never red. (The withdrawn
`PV-02` would have cost the same and was not paid — see §3.)

---

## 5. What this project must NOT push into gobstack

Saying no is half of curation, and the standing rule (§0) **is** the reason this section exists — it is cited
here instead of re-listing what it refuses: a tech-goblin fact enters gobstack only if it survives being
separated from its framework. Route-kind behaviour, `loading.*` ownership, `force-dynamic` / ISR /
`revalidate` semantics as policy, the cookie design and its secret names, the measured numbers (TTFB
470–615 → 181–211 ms, 25 harness gates, six commits), the Strapi/webhook shapes, the CMS content model and
the chrome inventory are this project's facts or this framework's mechanics; they stay here and in the
project skill. What the rule already admitted: P1 passed the test and became `PV-01`; P2 failed it and was
withdrawn (§3); P3–P7 are held advisory in §3 for exactly the same test.

---

## 6. What this file leaves open for the next curation

Not questions about the adopted rule — that one is decided. These are the things one project could not
settle, and the next project with a different shape should test:

1. **Is "review surface" a route kind or a config declaration?** `PV-01` reads a directory the config names.
   A repo whose preview is a query parameter, a feature flag, or a separate deploy has no such directory,
   and the rule still applies. The second project decides the shape.
2. **Does the status-code lie matter when nothing consumes the status?** Here it mattered because a public
   route answered 200 to crawlers for a page that should not exist. In a repo with no crawler, the same
   defect is cosmetic. A rule that cannot say when it does *not* apply will be disabled everywhere.
3. **How does a project prove its harness measured the deployed artifact and not the tree?** Recurring in
   both curations (this round: coder's 57 ms was loopback; earlier: `sha(build) == sha(deployed)` proved the
   deploy, not the behaviour). Still no shared form beyond a release record.

The general rule this file is built on, unchanged from the first curation: a lesson earns a row only when its
failure has been *measured* somewhere, and a rule earns a mechanism only when the mechanism can be proven red
on demand.
