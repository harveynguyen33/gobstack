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

## 1. The seven candidates, ranked by leverage

| # | Lesson | Class | Mechanisable today | Verdict |
|---|---|---|---|---|
| P1 | A surface that exists to be reviewed must render the artifact that will be published | verification / review | partly, import probe | **adopt (opt-in lint)** |
| P2 | A streaming boundary above a "not found" decision commits the status before the decision is made | verification / web | yes, text probe | **adopt (opt-in lint)** |
| P3 | A build-time list is not a runtime list | publishing / caching | shape only | advisory |
| P4 | A preload claim needs two timestamps, not one stopwatch | verification | no | advisory |
| P5 | "Cannot leak" is proven by the absence of a code path, not by the absence of an observed behaviour | isolation / security | partly | advisory (strong later row) |
| P6 | One working tree, one agent — and the commit proves which branch it landed on | process / governance | shape only | advisory (proposed `AG`-class script) |
| P7 | A delegated agent's green is a claim, not a state | delegation | already covered | **no new row** — see §4 |

---

## 2. The two adoptions, with the failure that justifies each

### P1 — a review surface must render the artifact that will be published

**Failure.** The preview shipped with its own minimal root layout: a banner, the article, nothing else. The
owner opened it and reported that the floating chips (scroll-to-top, the language switcher) were missing and
that the language control had moved to a top-left tab strip. He was right, and the round was wasted: the
review surface existed to let him judge the published render, and it was rendering a different page. The
fix (`91a5955`) mounts the production shell — the same provider, nav, footer and floating chips, the same
fonts and dark class — and leaves exactly three differences, each one declared: a banner strip in normal
flow above the nav, `noindex`, and no analytics/JSON-LD (owner visits must not pollute the numbers).

**Rule (project-independent).** *A surface whose purpose is review — preview, staging, draft, "view as
published" — renders the same shell, layout and content component as the published route; every remaining
difference is enumerated in the surface's own source as a marker, so a difference is a decision rather than
an accident.*

**Mechanism (proposed `PV-01`, opt-in lint).** For each route directory the project config names as a review
surface, the layout file must import the same shell module(s) the public layout imports, **or** carry
`preview_differs: <comma list>` naming every difference it keeps. Red when the surface renders a shell the
public tree does not use and declares nothing.

**Honest limit (goes in the row's `if_not_why`).** An import probe proves the module is reachable from the
file, never that the render is identical: a shell imported and then overridden by a local wrapper passes
while still differing. The stronger form is a design change — one `SiteShell` component both trees import —
and this project needed the probe *before* it had the design.

### P2 — a streaming boundary above a decision commits the status code first

**Failure, in three acts.** (a) `/writing/why-i-built-gobigrams` — a draft slug that must 404 on the public
site — answered **HTTP 200** with a body reading "Not Found". Root cause: a `loading.tsx` at the segment
makes the route stream; the response headers flush `200` with the shell, and `notFound()` afterwards can only
swap the body. The leak was not content (the body carried no draft text, flight data showed
`NEXT_HTTP_ERROR_FALLBACK;404`) but the *status* was a lie, and every status-code check in the project read
the lie as truth. (b) Deleting the boundary in the child segment changed nothing: a `loading.tsx` owns its
**whole subtree**, so the parent's boundary was the one doing it. (c) The same class then blocked a separate
decision: a page exporting `generateStaticParams` with `dynamicParams = false` looked safe *because* the
404 test passed — and it would have 404'd every article published after the last deploy, since the params
list is build-time only.

**Rule.** *A route that can decide "not found" at render time mounts no streaming boundary above that
decision; either the decision is taken before the first byte (existence check in metadata/generateMetadata,
a non-streamed lookup) or the boundary is removed for that subtree. A 404 assertion is made by a client
outside the framework's own boundary, never by code that reads the same stream.*

**Mechanism (proposed `PV-02`, opt-in lint).** For every route directory carrying a loading boundary
(`loading.*`, or a `<Suspense>` wrapping the page in its layout), grep the subtree for pages that call
`notFound()` / throw a 404. Red names the boundary file and the page. Escape hatch: `status_checked: <where>`
in the page when the existence is settled before streaming.

**Honest limit.** The probe reads a framework convention, not a runtime: it cannot see a boundary added by a
component the page imports, and it cannot tell whether an `status_checked:` marker is true. It is also
JS/Next-shaped — the same defect class in another framework needs its own convention map, which is why the
row is opt-in (`library.tsv`) rather than mandatory.

---

## 3. The advisory set (no mechanism yet, and why)

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
| P2 | `PV-02` (opt-in, lint) | `goblin-verify-author`: "the status is decided before the first byte" | LIMITS: convention map is per framework |
| P3, P4 | — (advisory) | `goblin-verify-author`: two sentences, dated failures named | — |
| P5, P6 | — (advisory, named candidates) | `goblin-handoff` / `practice`: the grep and the branch proof | GUIDE: recovery commands |
| P7 | none (covered by `HP-03`) | — | — |

Cost estimate, from the shape of the existing checks: both `PV-*` rows are the `BN-01` class — grep over
text, no AST — each two hours including a negative control that proves the row RED under its own violation.
Both are opt-in: a repo that declares no review surface and no streaming boundary gets `SKIP` with the
reason, never red.

---

## 5. What this project must NOT push into gobstack

Saying no is half of curation. These are tech-goblin facts with no general form:

- Next.js version behaviour (which route kinds are prefetched, what `loading.tsx` owns), router internals,
  `force-dynamic` / ISR / `revalidate` semantics as *policy*. The **defect class** survives (P2); the
  framework mechanics do not travel.
- The cookie design (HMAC payload, 30-day expiry, httpOnly/SameSite), the secret names, the redirect codes.
  One sound answer to "owner-only preview", shaped by one auth story.
- The measured numbers: TTFB 470–615 → 181–211 ms, click-to-locale 28 ms, 25 harness gates, six commits.
  Numbers are evidence for the rule, never the rule.
- Strapi/webhook shapes (`x-revalidate-secret`, `{"slug":…}`), the CMS content model, the `DRAFT — ` prefix
  convention. Product.
- The chrome inventory itself (which chips exist, where they sit, their pixel offsets). The **principle**
  (P1) is what travels; the inventory is this site's.

---

## 6. What this file leaves open for the next curation

Not questions about the two adopted rules — those are decided. These are the things one project could not
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
