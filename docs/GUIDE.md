# Getting started with gobstack

A step-by-step guide for your first week. **Read this before the README.** The README tells you
what the pieces are; this tells you what to *do*, in order, and what you should see when it works.

Version: `0.6.0-alpha.4` · Last measured: 2026-10-09 · Every command and every output below was run on a
real repository while writing this guide.

---

## 0. Who this is for, and what you will have at the end

This guide assumes you are a developer who uses an AI coding agent and has noticed the same three
problems everyone notices:

1. **A new session re-improvises.** The agent forgets how you work, what you decided last week,
   which commands matter. Every session starts from zero.
2. **"It works" is a claim, not a measurement.** The agent says it fixed something. You have no
   cheap way to know whether that is true.
3. **Rules live in prose.** You write them down, the agent reads them, and nothing enforces them —
   so they rot silently, and you find out months later.

By the end of this guide you will have a repository that fixes those three things *mechanically*:
one file a new session reads first, a checker that proves a change is a change, and a rule table
where every rule either runs a command or is explicitly counted as unenforceable.

**Time budget:** about 45 minutes to work through it once. You do not need to understand the whole
design on day one.

---

## 1. What this actually is, in plain language

gobstack (published on npm as **`@techgoblin/gobstack`**) — this guide, the README and the CLI
all call it **gobstack**
is **a folder of files you install into a project** from npm. Once
installed, three things change:

- A file called `HANDOFF.md` sits at the root. It is the note from the last session to the next one.
  Any agent — or you, a month later — reads it first.
- A command called `goblin-verify` exists in that project (vendored at `.gob/bin/`). Run it and it
  checks the project against a table of rules and prints `PASS` / `FAIL` / `SKIP` for each one.
- The config and the rules table are real files: the config is the `<!-- gob:begin --> …
  <!-- gob:end -->` block at the top of `AGENTS.md`, and the rules table is
  `.gob/manifest/enforcement.tsv`. Every row either names a command that can fail, or is labelled
  `advisory`. **Nothing in between.** That is what stops the rules turning into decoration.

It is not a framework, not a service, and not a runtime. It has no server and no dependencies
beyond `bash`, `git`, `awk`, `sed`, `grep` and `python3`. It makes **no network call at verify
time** — nothing in the v2 surface touches the network at all.

### The one idea worth holding onto

> **A rule that cannot fail is worse than no rule**, because it takes credit for verification it
> does not perform.

Everything else in gobstack follows from that sentence. If you remember one thing from this
guide, remember that one — it is also the standard the harness holds itself to, and the reason it
ships a file of things it *cannot* check (`docs/LIMITS.md`).

**Words this guide uses** — gate, ratchet, class, part, replay and the rest are defined in one
sentence each in `docs/GLOSSARY.md` (rendered from the glossary table the install ships:
`.gob/manifest/glossary.tsv`).

---

## 2. Before you begin

**You need:**

| | |
|---|---|
| `bash`, `git`, `awk`, `sed`, `grep`, `python3` | already on any Linux/macOS box |
| a project that is a **git repository** | `git status` must work; the harness reads commit identity |
| a branch named the same as the one you declare | see step 3 — a `master`/`main` mismatch is the most common first failure |

You need node ≥ 18 (for the npm shim only), beyond the row above.

**You do *not* need:** network access at verify time, or an agent running — though the `init`
brief is written for an agent to answer, you can fill the proposal in by hand.

**Get gobstack:**

    npx @techgoblin/gobstack init     # the one-shot path; installs nothing globally

or, if you want the CLI on your PATH:

    npm i -g @techgoblin/gobstack

This puts **two** commands on your PATH — `gob` and `goblin`, both the same node shim over the
bash engine. The docs say `gob` throughout; `goblin` remains as a legacy alias for existing
scripts.

---

## 3. Step 1 — Try it on a throwaway repo first (5 minutes)

**Do not install into a real project yet.** You want to see what it does before it touches
something you care about.

The v2 flow is **`init`**: it prints an AGENT BRIEF (what to scan, what to decide) plus the
schema of the proposal file, the agent (or you) writes the proposal, and `--write` validates it
and installs:

    mkdir -p /tmp/gs-try && cd /tmp/gs-try
    git init -b main
    git config user.email "you@example.com"
    git config user.name "you"

    gob init --heuristic                 # the brief + schema; --heuristic adds scanned hints

The brief asks for exactly four decisions — class, branch, owner email, and ONE gate command
that proves the repo is healthy. Write them into the proposal file (the brief names the schema;
a hand-written one works fine):

    <!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->
    class: software
    branch: main
    owner_email: you@example.com
    gate_check_cmd: bash tests/run-tests.sh
    <!-- gob:end -->

    ## gob init summary

    - scan: bare repo, no package.json — the brief was answered by hand
    - chose: class software, branch main, gate `bash tests/run-tests.sh`

then install it:

    gob init --write .gob-init-proposal.md --yes

Expected output (this is a real transcript, trimmed):

    created 23 · updated 0 · unchanged 0 · skipped 0

    next:
      1. cd /tmp/gs-try && git add -A && git commit   # the install is a change like any other
      2. .gob/bin/goblin-verify   # or add .gob/bin to PATH
      3. edit AGENTS.md: replace the default gate with your real commands (P8 step 3)
      4. agent skills are opt-in

**`created 23`** is the installer's count of the files it **tracks**. It writes **24**: the 24th
is `.gob/installed.json`, the record it keeps for itself, which it writes but does not count. It
has written nothing outside this directory — and nothing under `.github/`: **v2 installs no
CI, ever.** The default install ships **no agent skills** — the harness is neutral.

**The config is the AGENTS.md frontmatter.** There is no separate config file: every key the
harness reads lives in the `<!-- gob:begin --> … <!-- gob:end -->` marker block at the top of
`AGENTS.md`. Edit it in place; the parser reads only that block.

### Why `git init -b main` matters

The harness **declares** your default branch rather than assuming it (rule `PT-02`). If your repo's
branch is `master` and the config says `main`, verify fails on the very first run:

    FAIL  PT-02  declared main, actual master

That is not a bug — it is the harness refusing to guess, which is the same reason it fails instead
of silently skipping a repo whose branch it got wrong. **Fix it in the AGENTS.md block, not by
renaming your branch** (unless you want to).

---

## 4. Step 2 — Commit, then verify (the moment it earns its keep)

    cd /tmp/gs-try
    git add -A && git commit -m "chore: install gobstack"
    .gob/bin/goblin-verify

You will see one line per rule. The shape:

    PASS  IN-01  the install record exists and names its version
    PASS  IN-02  15 installed files hashed
    FAIL  HP-05  HANDOFF.md names no commit that exists in this repo
    SKIP  HS-02  no pinned pre-change commit yet - the REPLAY is not provable
    ADV   HP-04  A stale sentence is corrected in place... (advisory)

and a summary line at the bottom:

    36 passed, 1 failed, 11 advisory, 34 skipped     # HP-05, below

### How to read that output

| Marking | Meaning | What you do |
|---|---|---|
| `PASS` | the rule's command succeeded | nothing |
| `FAIL` | the rule's command failed, and the message says why | fix it — this is the whole point |
| `SKIP` | the rule cannot run **yet**, and it says why | usually expected on day one |
| `ADV` | advisory — a rule with no runnable check, **counted** | nothing, but know it is not enforced |

**`SKIP` is not success and not failure.** It is the harness telling you the truth: "this rule has
nothing to read yet." On a brand-new install, three dozen rows skip — because there is no `src/` for a
ban to scan, no feature map, no loop record, no pinned pre-change commit. That is correct on day
one. The list of what is still skipping *is* your onboarding checklist.

### Feature maps: generate with `gob map`, then opt in

The feature-map rows (`FM-01`, `FM-02`) are opt-in by declaration: while `feature_map:` in the
AGENTS.md gob block is empty, both rows SKIP. When you are ready to keep a map honest, the flow
is:

1. **Generate a starter.** `gob map --heuristic` works in any git repo — no install needed. It
   scans the repo (Next.js app/pages router, Nuxt, route files, or top-level `src/`/`lib/`
   module dirs as TODO placeholders) and writes `features/README.md` plus one file per detected
   feature. It never clobbers: an existing `features/` refuses until `--force`, which regenerates
   only the index and adds new slugs — your hand-edited feature files are never rewritten.
2. **Hand-pass every file.** The generated files say so themselves: a `verified: never-driven
   (generated <date>)` line is not a drive claim. Edit each one into a real feature description
   with concrete entry paths and driving steps.
3. **Then, optionally, declare it.** Set `feature_map: features/README.md` in the AGENTS.md gob
   block and `FM-01`/`FM-02` start reading it on every verify — that declaration is the
   verify opt-in, never forced. A repo that wants the generator but not the rows can run
   `gob map` and never declare anything.

**Read the failure messages.** They are written to be actionable, not decorative. `HP-05` above is
telling you the HANDOFF does not yet name a commit — fix it by naming your HEAD in the `State`
section.

### The day-one table, measured on this exact walk

| Step | Command | Verify prints | The FAILs |
|---|---|---|---|
| 1. the install ran | `gob init --write ... --yes` | `35 passed, 2 failed, 11 advisory, 34 skipped` | the install is uncommitted (`CM-03`) and the shipped SPEC is untracked (`SP-02`) |
| 2. the first commit | `git add -A && git commit` | `36 passed, 1 failed, 11 advisory, 34 skipped` | `HP-05` (the placeholder) — plus `GT-02` if your gate names a script the repo does not have |
| 3. name a real HEAD — and **commit that too** | edit `HANDOFF.md`, then `git add -A && git commit` | `37 passed, 0 failed, 11 advisory, 34 skipped` | none — green |

One of those deserves its name spelled out:

- **`GT-02` exit 127 is the guide's own teaching point, not a defect.** The gate you wrote in the
  proposal (`bash tests/run-tests.sh`) does not exist in a throwaway repo — the shell's own
  *command not found*. Replace it with a command that can run (or create the script). The failure
  line tells you this: `gate check: bash tests/run-tests.sh -> exit 127`.
- **Step 3 is two steps on purpose.** Naming a real HEAD in `HANDOFF.md` without committing it
  re-reds `CM-03` (`1 dirty entr(y|ies)`) — commit-as-you-go starts on minute one. Edit, commit,
  then verify.

### The three-day-one failures, and why they are not a broken harness

If you ran step 1 without `-b main`, or with the wrong git identity, you will see:

| FAIL | Cause | Fix |
|---|---|---|
| `PT-02 declared main, actual master` | branch name mismatch | set `branch:` in the AGENTS.md gob block |
| `CM-01` (commit identity) | the repo's commit email ≠ the declared `owner_email:` | set `owner_email:` in the gob block |
| `HP-05` | `HANDOFF.md` still names the scaffold placeholder `` `0000000` `` | replace it with your real short HEAD |

**All three are configuration, not defects.** The harness is reporting your repo's actual state
against a declared expectation. That is exactly what you want it to do.

`HP-05` deserves one sentence more, because it surprises people: the scaffold ships
`HEAD when this file was written: `0000000``, and `HP-05` **rejects that placeholder on purpose**.
A file that names a commit which does not exist is worse than one that names none — it looks like a
record. Commit first, then write the real short SHA in.

---

## 5. Step 3 — Make it yours: the one config block

Everything you configure lives in **one place**, created once and then never overwritten
by the installer:

    AGENTS.md   — the `<!-- gob:begin --> ... <!-- gob:end -->` block

Open it. The keys that matter on day one:

    class: software                       # software|service|game|research|fleet (A-E are aliases)
    branch: main                          # DECLARED, never assumed
    owner_email: you@example.com          # the commit identity this repo expects
    practice: /path/to/your-standard.md   # optional: your own house rules, hash-pinned
    models_file: /path/to/fleet-model.yaml # the ONE machine-specific input (per machine; a
                                           # fresh install without --models leaves it empty)
    gate_<name>_cmd: <one command>        # YOUR real commands, one line each

**The single most valuable edit you will make:** replace the gate line(s) with the commands you
actually run to know your project is healthy. `tsc --noEmit`, `npm run build`, your test command —
whichever three or four you would run before saying "this is fine."

Why it matters: from then on, `goblin-verify` runs *your* definition of healthy, every time,
without you remembering to. And the gate numbers are recorded with a date, so a number in
`HANDOFF.md` can never quietly go stale.

### The `practice:` key — the part that makes it yours

If you already have a house standard — a `CONTRIBUTING.md`, a `PROJECT-PRACTICE.md`, anything
written down — point `practice:` at it. gobstack does **not** copy its text. It records a
**hash** of the file (`practice_sha256:`) and re-checks that hash on every verify.

That buys you one specific, valuable thing: **if someone edits your standard, every project that
pins it goes red.** You find out immediately instead of discovering six months later that half your
repos follow an old version.

When *you* legitimately edit your own standard:

    goblin-install --target . --re-pin   # from the gobstack checkout / install tree

It re-records the hash and prints the old and new value. Nothing re-pins automatically — not even
a re-install — an edited standard is never a silent no-op.

---

## 6. Step 4 — Pick the right class (this decides what you get)

A class is **not** a strictness level. It selects which parts are required, optional, or off, and it
supplies the default gate shape. Choose by asking *what does "done" mean here?*

| Class | Choose it when | "Done" means |
|---|---|---|
| **software** (A) | an app, library, or tool users run | a gate set reports measured numbers and a round lands |
| **service** (B) | an API, schema, route, or deployment config | the contract is unchanged, or the change is deliberate and migrated |
| **game** (C) | a game | a suite is green **and** a human feel verdict exists |
| **research** (D) | notes, a vault, a research directory | a question is answered with sources and is findable |
| **fleet** (E) | your agent's own config (`~/.hermes`) | the change is applied, verified against the artifact, versioned |

An Electron app is **software** with `electron: true` — the opt-in adds the electron bans and a host
gate, not a sixth class. The old `F` letter still resolves there as an install alias.

**Two placements people get wrong:**

- A repo that holds *output* while the code lives elsewhere → **research**, not **software**. Gating
  it like an application gates the wrong artifact.
- A plain input directory that is not a build target → **research** with `archive: true`, which tells
  verify to expect no HANDOFF and no gates, and to say so.

Switch class later by editing `class:` in the gob block and re-running install. The parts you no longer
need are recorded as **disabled** and will report `SKIP (opt-out)` rather than failing.

---

## 7. Step 5 — Your first real change, end to end

Now do the thing the harness exists for. Pick a small real task in a real repo.

**The loop you are going to follow:**

    1. Write the intent down          -> ROUND-001-SPEC.md
    2. Make the change
    3. Run the gate                   -> goblin-verify
    4. Record what you proved         -> HANDOFF.md
    5. Commit as you go

Step by step:

    # 1. Say what you are about to do, and how you will know it worked
    cp ROUND-000-SPEC.md ROUND-001-SPEC.md
    #    edit it: state the measured problem, then a list of AC: items
    #    each AC: must be checkable by a machine - see below

    # 2. make your change, committing in small steps

    # 3. run the gate
    .gob/bin/goblin-verify

    # 4. write the handoff: state / gates / next steps / NOT verified

### Writing an `AC:` item that is worth writing

A spec item is only useful if a script could evaluate it. Compare:

    - AC1: the export button feels responsive after the fix      <- worthless, no machine can check it
    - AC2: export completes in < 200ms for 1000 rows             <- checkable
    - AC3: `goblin-verify --only SP-03` exits 0                  <- checkable, today

Rule `SP-03` actually fails a spec line that tries to pass prose off as a criterion. If the only
test is your own judgement, say so in the spec, in an explicit *device-test* item — that is an
honest entry, and the harness treats it as one.

### The habit that makes the whole thing work

> **Prove it was broken first.**

Before you trust a check, break the thing it checks and watch it go red — then put it back and watch
it go green. Break it on a row this walkthrough can actually break: `IN-02` hashes the 15 files it
tracks — not the ones it `owns` (including `AGENTS.md`, whose gob block §5 has you editing) and not
`.gob/installed.json`; edit one of the tracked — the exercise below uses `.gob/bans/README.md`.

    # REPLAY-BEGIN (this exact block is run by tests/t-doc-guide.sh - keep the two copies identical)
    .gob/bin/goblin-verify --only IN-02                    # expect PASS
    printf '\n<!-- a deliberate edit -->\n' >> .gob/bans/README.md
    .gob/bin/goblin-verify --only IN-02                    # expect FAIL
    git stash push -- .gob/bans/README.md                  # path-limited: your own edits stay put
    .gob/bin/goblin-verify --only IN-02                    # expect PASS
    git stash drop                                         # the break was deliberate: discard it
    # REPLAY-END

Read the direction: the edit makes the check go **red**, and putting the file back makes it green.
That is the whole habit — the change you *undo* is a deliberate break, not a fix, because `IN-02`
measures the shipped files rather than your work.

`GT-02` is the row most readers reach for first, and it will **not** work as a REPLAY demo on the
shipped configuration: it runs the gates you declared, and stashing a
local change does not change either command's exit status — so it prints `PASS` before and after,
which is exactly the "green on both trees" result this rule exists to kill. REPLAY a gate of your
own the same way, once that gate is real: declare it in the gob block and stash a change it
can see.

A check that is green on **both** the broken and the fixed tree proves nothing — it would have been
green anyway. gobstack calls this the **REPLAY** rule, and it is the single practice that has
caught every real regression in this repository's own development history.

---

## 8. Step 6 — The daily loop, once you are settled

Day to day, the harness should fade into three habits:

**Starting work** — read `HANDOFF.md` first. It tells you the state, the gates, what is next, and —
most importantly — **what is *not* verified**. Never trust a claim in it without running the
command it names.

**While working** — commit small. `CM-03` fails verify when the tree carries a dead run's work, so
the harness nudges you to land things as they work rather than in one heroic commit at the end.

**Finishing** — update `HANDOFF.md`, then:

    .gob/bin/goblin-verify && git add -A && git commit -m "..."

### Keeping `HANDOFF.md` honest

`HANDOFF.md` needs five sections, and rule `HP-02` checks the headings exist:

| Section | First word of the heading |
|---|---|
| orientation | `START HERE` |
| current state | `State` or `Status` |
| gates | `Gate` or `Gates` |
| next steps | `Next steps` or `Next` |
| what is not verified | `Not verified` / `Unverified` / `Not proven` |

Inside `Gates`, every number must carry a date:

    - `tsc`=0 · `build`=0 · hex **144** (ceiling 160) · 38/38 harnesses green · measured 2026-09-24

**A number without a date is a rumour.** `HP-03` will fail it, and the reason is that a
measurement copied from last round is worse than no measurement — it *looks* verified.

**When a sentence in `HANDOFF.md` goes stale:** correct it in place with the date, and keep the
original:

    > it used to say X. X was paid on 2026-09-20 (commit abc1234). The stale sentence is kept,
    > dated, rather than deleted.

Deleting it erases the fact that it was once believed true; leaving it undated re-arms the trap for
the next session.

---

## 9. What to expect on day one (so you do not misread it)

A software-class install lands on a specific shape. The first reds are
the scaffold teaching on purpose — `HP-05`, the `0000000` placeholder in `HANDOFF.md` (§4). The
walk in §4 measured, step by step:

    35 passed, 2 failed, 11 advisory, 34 skipped     # straight after the install (CM-03 + SP-02)
    36 passed, 1 failed, 11 advisory, 34 skipped     # first commit: HP-05 left (and GT-02 too if the gate cannot run)
    37 passed, 0 failed, 11 advisory, 34 skipped     # real HEAD named and committed: green

Name a real commit in `HANDOFF.md`, commit, and give the gate lines real commands (§5), and it is
green:

    37 passed, 0 failed, 11 advisory, 34 skipped     (on a real project; your numbers will differ)

**Thirty-four rows skipping is correct**, and each skip prints its reason. In plain terms: the
harness is telling you which of its rules have nothing to read yet. It is a checklist, not a
scolding.

Two readings that are easy to get wrong:

- **Advisory rows are not passes.** Ten rules are labelled `advisory` — counted, not enforced, and
  nine of them carry no executable check at all. The count is capped by `advisory_ceiling: 10`, and
  a software-class install already sits at 10 of 10: adding another unenforceable rule fails verify until
  one is removed. That is intentional. (The summary line can print `11 advisory`: the eleventh ADV
  line is `JG-02`, a row with a real command of its own that reports ADV here because your model
  file declares no `judge:` lane — it prints the remedy rather than failing a repo for a fleet's
  routing.)
- **Vacuously-passing rows are not proven.** A rule about "the first review note" passes when there
  is no review note yet. It is not lying — it is passing on an empty set. `docs/CONTRACTS.md`
  names which rows do this.

---

## 10. When something goes wrong

| Symptom | What it means | What to do |
|---|---|---|
| `refused to overwrite: HANDOFF.md`, exit 1 | your repo already had a HANDOFF | **do not `--force`** — reconcile it (below) |
| `PT-02 declared main, actual master` | branch mismatch | set `branch:` in the gob block |
| `IN-02 ... practice EDITED` | someone changed the pinned standard | re-pin deliberately: `--re-pin` |
| `gob: unrecognized command: <verb>` (exit 2) | you ran a verb outside the v2 surface (`audit`, `doctor`, `install`) | use the six wired verbs: `init`, `map`, `verify`, `bans`, `mcp`, `uninstall` |
| `IN-03` fails, "manifest is broken" | a row has a broken check column | fix the row; this is a source defect, not yours |
| a `FAIL` you believe is wrong | the check may be weak, or your belief may be | run `--only <id>` and read the command it prints |
| a changelog or matrix note says `W6` or `Z1-4` | that is a revision wave code | `docs/RECORD-NOTES.md` is the legend, one line per code |

**The `HANDOFF.md` refusal is the most common one, and `--force` is never the answer.** `--force`
replaces your project's own record with a blank scaffold — the exact act the refusal exists to
prevent. Reconcile instead: keep your file, and add the five sections it is missing. The measured
cost of that edit, on a real 2450-line handoff, was **15 lines added, none removed**.

**One engine, many repos (declared, not wired in this alpha):** the rule table can live outside
the repo — a declared `engine_dir:` line in the gob block names a shared engine. In v2 the
**vendored engine wins by design**: a repo carrying both `.gob/` and an `engine_dir:` judges
itself with the vendored manifest, because that is the manifest its install record hashes
(`docs/LIMITS.md` #54). A declared but unusable `engine_dir:` is verify **exit 2 with no
fallback** — a repo is never judged by an engine it did not declare. The engine's own identity
prints in every run's footer (`engine: mode=vendored cli_sha256=… enforcement_tsv_sha256=…`). The
same commands are available outside any repo through the npm CLI: `gob init` / `gob map` /
`gob verify` / `gob bans` / `gob --version`.

**Two exit-code contracts worth knowing:**

| Command | Exit codes |
|---|---|
| `goblin-install` | `0` ok · `1` a refusal (with the path and the fix) · `2` bad input |
| `goblin-verify` | `0` all checks passed · `1` a check failed · `2` could not run · `3` the manifest itself is broken |
| `gob` (npm CLI) | propagates the subcommand's codes verbatim; a verb outside the surface (`audit`/`doctor`/`install`) is refused with exit 2 and the usage |

`3` is the one to notice: it means gobstack's own rule table is malformed, not your project.

---

## 11. Reference

### Commands

    gob init [--heuristic] [--write <proposal>] [--target <dir>] [--dry-run] [--yes]
             [--with-mcp-config]
    gob map [--heuristic [target]] [--write <dir>] [--force]
    gob mcp                                  # the MCP stdio server (three tools, local only)

    .gob/bin/goblin-verify [--only <id[,id...]>] [--json] [--list]
    .gob/bin/goblin-bans           # run the ban list
    gob uninstall --target <dir>             # the uninstall job
    goblin-install --target <dir> --re-pin   # the deliberate re-pin (from the checkout/install tree)
    bin/goblin-model <role>        # checkout-only; resolve a role to a profile (docs/ROLES.md)

### Register the harness with your agent (MCP)

Your agent can call the discipline gate itself instead of you pasting verify output into the
chat. `gob mcp` is a local tool server (JSON-RPC over stdin/stdout — the Model Context
Protocol shape); it exposes `gob_verify` (the gate, with the remedy line under every FAIL),
`gob_map_status` (the feature map, read-only) and `gob_init_status` (is this repo under the
harness). It calls no API and opens no socket.

The one-liner, per user account:

    claude mcp add gob -- npx -y @techgoblin/gobstack mcp

or, committed with the repo so every teammate's agent picks it up (Claude Code and Cursor
auto-detect it):

    gob init --with-mcp-config        # writes .mcp.json; never overwrites one you customized

### The 15 playbooks

Named procedures, installed as project-local skills. Each has a measurable verification step.

| | Playbook | Use it when |
|---|---|---|
| P1 | `goblin-investigation` | a read-only question, or "why is this happening" |
| P2 | `goblin-bugfix` | a reported defect |
| P3 | `goblin-feature` | new behaviour |
| P4 | `goblin-refactor` | a behaviour-preserving reshape |
| P5 | `goblin-tdd-repro` | a defect where a regression test is cheap |
| P6 | `goblin-verify-author` | a project has no live check lane, or its gates drift |
| P7 | `goblin-pr-gate` | anything that should be reviewed before landing |
| P8 | `goblin-bootstrap` | adopting gobstack, or starting a project |
| P9 | `goblin-handoff` | ending a session, or picking up another's |
| P10 | `goblin-overnight` | an unattended run over a predicate |
| P11 | `goblin-sweep` | the same change across many projects |
| P12 | `goblin-eval` | a skill or prompt changed — did it do anything? |
| P13 | `goblin-bugreporter` | an event delivered a report |
| P14 | `goblin-drift-audit` | a recorded claim disagrees with the artifact |
| P15 | `goblin-re-mobile` | one shipped Android build must be understood as facts for study |

### Where the real documentation lives

| File | Read it for |
|---|---|
| `docs/DESIGN.md` | the thesis and every rejected alternative |
| `docs/GLOSSARY.md` | every term of art in one table (rendered from `.gob/manifest/glossary.tsv`) |
| `docs/RECORD-NOTES.md` | the wave codes the changelog uses, one line each |
| `docs/FLOWS.md` | the playbooks in full, with reasons |
| `docs/ENFORCEMENT.md` | the rule matrix, rendered for a human |
| `docs/LIMITS.md` | **what this cannot check** — read this one early |
| `docs/RISKS.md` | the risk register and non-goals |
| `docs/CONTRACTS.md` | exact interface, exit codes, uninstall |
| `docs/ADOPTION.md` | classes, presets, adoption order |
| `docs/LOOP.md`, `docs/GUARDRAILS.md` | the newer lanes |

---

## 12. What this will not do for you

Stated plainly, because a guide that oversells its tool is worse than no guide:

- **It cannot force an agent that never reads `HANDOFF.md`.** It can only make the file exist,
  structured and dated, so the reading is cheap.
- **It cannot prove your checks test the right thing.** A green suite that asserts the wrong
  behaviour passes. Only the REPLAY habit (prove it goes red) catches that, and only if you do it.
- **It cannot see a real user's device.** A performance number measured on your machine is not a
  user's experience, and the harness says so in its own output.
- **Ten of its rules are labelled `advisory`** — counted, not enforced, and capped at 10 of 10. They
  are listed by name.
- **It is not a product.** It is a repository of files, installed into other repositories.
  No service, no daemon, no support contract.

---

## 13. Where to go next

**If you only do one thing:** install into your most active repo today, set your real gate
commands, and run `goblin-verify` once a day for a week. The habit, not the tool, is what produces
the result.

**Then, in order:**

1. Point `practice:` at your existing house standard and pin it.
2. Write one `AC:` item that a script could check, and make it pass.
3. Add a ban for the one pattern you are tired of seeing in agent-written code
   (`.gob/manifest/bans.tsv` — a ban without a mechanism is a wish, so give it one).
4. When you have a bug that a test could catch, walk P5 (`goblin-tdd-repro`) end to end once.

**If you are sharing this with a team:** the parts that matter are `HANDOFF.md`, the gate commands
you declare, and the REPLAY habit. The rest is optional machinery you can switch off per class.
Lead with *"prove it was broken first"* — it is the one practice that survives contact with a
deadline.

---

## Appendix — a 45-minute first run, on one page

    # 0. get it
    npx @techgoblin/gobstack init          # or: npm i -g @techgoblin/gobstack

    # 1. try it somewhere disposable
    mkdir -p /tmp/gs-try && cd /tmp/gs-try
    git init -b main
    gob init --heuristic                   # the brief + schema; answer it in a proposal file
    gob init --write .gob-init-proposal.md --yes
                                           # expect: created 23 (no skills — those are opt-in)

    # 2. commit and check
    git add -A && git commit -m "chore: install gobstack"
    .gob/bin/goblin-verify                 # expect: mostly PASS, some SKIP

    # 3. make it yours
    $EDITOR AGENTS.md               # branch, owner_email, and YOUR real gate commands (the gob block)

    # 4. prove a check can fail (the habit that matters) - the same block §7 runs
    # REPLAY-BEGIN (this exact block is run by tests/t-doc-guide.sh - keep the two copies identical)
    .gob/bin/goblin-verify --only IN-02                    # expect PASS
    printf '\n<!-- a deliberate edit -->\n' >> .gob/bans/README.md
    .gob/bin/goblin-verify --only IN-02                    # expect FAIL
    git stash push -- .gob/bans/README.md                  # path-limited: your own edits stay put
    .gob/bin/goblin-verify --only IN-02                    # expect PASS
    git stash drop                                         # the break was deliberate: discard it
    # REPLAY-END

    # 5. do it for real, in a repo you care about
    cd ~/projects/your-project
    gob init --write .gob-init-proposal.md --yes
    git add -A && git commit -m "chore: adopt gobstack"
    .gob/bin/goblin-verify
    $EDITOR HANDOFF.md              # state / gates (dated!) / next / NOT verified

---

*This guide is part of gobstack. If you find a step that does not work as written, that is a
defect in the guide — report it the same way you would report one in the code.*
