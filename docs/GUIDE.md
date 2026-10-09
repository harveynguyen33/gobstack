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

**Words this guide uses** — gate, ratchet, part, replay and the rest are defined in one
sentence each in `README.md` (rendered from the glossary table the install ships:
`.gob/manifest/glossary.tsv`).

---

## 2. Before you begin

**You need:**

| | |
|---|---|
| `bash`, `git`, `awk`, `sed`, `grep`, `python3` | already on any Linux/macOS box |
| a project that is a **git repository** | `git status` must work; the harness reads commit history |

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

The brief asks for one decision — the gate command — plus the mandatory feature map
that proves the repo is healthy. Write them into the proposal file (the brief names the schema;
a hand-written one works fine):

    <!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->
    gate_check_cmd: bash tests/run-tests.sh
    <!-- gob:end -->

    ## gob init summary

    - scan: bare repo, no package.json — the brief was answered by hand
    - chose: gate `bash tests/run-tests.sh`, a one-feature map

then install it:

    gob init --write .gob-init-proposal.md --yes

Expected output (this is a real transcript, trimmed):

    created 19 · updated 0 · unchanged 0 · skipped 0

    next:
      1. cd /tmp/gs-try && git add -A && git commit   # the install is a change like any other
      2. .gob/bin/goblin-verify   # or add .gob/bin to PATH
      3. edit AGENTS.md: replace the default gate with your real commands (P8 step 3)
      4. agent skills are opt-in

**`created 19`** is the installer's count of the files it **tracks**. It writes **20**: the 20th
is `.gob/installed.json`, the record it keeps for itself, which it writes but does not count. It
has written nothing outside this directory — and nothing under `.github/`: **v2 installs no
CI, ever.** The default install ships **no agent skills** — the harness is neutral.

**The config is the AGENTS.md frontmatter.** There is no separate config file: every key the
harness reads lives in the `<!-- gob:begin --> … <!-- gob:end -->` marker block at the top of
`AGENTS.md`. Edit it in place; the parser reads only that block.

## 4. Step 2 — Commit, then verify (the moment it earns its keep)

    cd /tmp/gs-try
    git add -A && git commit -m "chore: install gobstack"
    .gob/bin/goblin-verify

You will see one line per rule. The shape:

    PASS  IN-01  the install record exists and names its version
    PASS  IN-02  13 installed files hashed
    FAIL  HP-05  HANDOFF.md names no commit that exists in this repo
    SKIP  FM-01  feature_map: is empty - this state is UNREACHABLE ...
    SKIP  SK-01  Every shipped skill has name + description frontmatter. (opt-out: playbooks)

and a summary line at the bottom:

    13 passed, 1 failed, 0 advisory, 13 skipped     # the HP-05 placeholder, before you name a real commit

### How to read that output

| Marking | Meaning | What you do |
|---|---|---|
| `PASS` | the rule's command succeeded | nothing |
| `FAIL` | the rule's command failed, and the message says why | fix it — this is the whole point |
| `SKIP` | the rule cannot run **yet**, and it says why | usually expected on day one |
| `ADV` | advisory — a rule with no runnable check, **counted** | nothing, but know it is not enforced |

**`SKIP` is not success and not failure.** It is the harness telling you the truth: "this rule has
nothing to read yet." On a brand-new install, thirteen rows skip — because there is no `src/` for a
ban to scan, no feature map, no pinned pre-change commit. That is correct on day
one. The list of what is still skipping *is* your onboarding checklist.

### Feature maps: authored in the `gob init` proposal, mandatory

The feature-map rows (`FM-01`, `FM-02`) are always live: `feature_map:` is a REQUIRED key, so
there is no "no map declared" state and no standalone generator. The map is authored in the SAME
pass as the install — the `gob init` brief's `## feature-map` section asks the agent to embed the
files in the proposal: a `### features/README.md` index and one `### features/<slug>.md` per
feature, each in a fenced block. `gob init --write` validates the whole map before it writes
anything, then materialises `features/`.

Per feature file: frontmatter with `feature:` equal to the filename stem, >=1 `entry_paths:`
item (each a single whitespace-free token), and exactly the four H2s in order — `Sub-features`,
`How to get to it (user POV)`, `Driving it with <harness>`, `Gotchas`. The README index must link
every feature as `(./<slug>.md)` and every relative link must resolve. `--write` resolves every
entry path at write time: it must EXIST and be TRACKED (`git ls-files`), so a map cannot claim a
`verified:` date over uncommitted source — `verified: never-driven (<date>)` is the honest
day-one line, not a drive claim. A repo with no committed file to map refuses with a named
remedy — commit at least one file, then run again.

**Read the failure messages.** They are written to be actionable, not decorative. `HP-05` above is
telling you the HANDOFF does not yet name a commit — fix it by naming your HEAD in the `State`
section.

### The day-one table, measured on this exact walk

| Step | Command | Verify prints | The FAILs |
|---|---|---|---|
| 1. the install ran | `gob init --write ... --yes` | `18 passed, 0 failed, 0 advisory, 9 skipped` | none — the installer fills `HANDOFF.md`'s HEAD from the seed commit, and the uncommitted-install / untracked-SPEC reds (`CM-03`, `SP-02`) are now library rows, off by default |
| 2. the first commit | `git add -A && git commit` | `18 passed, 0 failed, 0 advisory, 9 skipped` | none — green |
| 3. name a real HEAD — and **commit that too** | edit `HANDOFF.md`, then `git add -A && git commit` | `18 passed, 0 failed, 0 advisory, 9 skipped` | none — `CM-03` is a library row, so a dirty tree no longer re-reds by default |

One of those deserves its name spelled out:

- **`GT-02` exit 127 is the guide's own teaching point, not a defect.** The gate you wrote in the
  proposal (`bash tests/run-tests.sh`) does not exist in a throwaway repo — the shell's own
  *command not found*. Replace it with a command that can run (or create the script). The failure
  line tells you this: `gate check: bash tests/run-tests.sh -> exit 127`.
- **Step 3 is two steps on purpose.** `CM-03` (commit-as-you-go) is a library row now, so a
  dirty tree no longer re-reds by default — but the discipline is unchanged: edit, commit, then
  verify. Enable `CM-03` from the library if you want the gate to hold you to it.

### The three-day-one failures, and why they are not a broken harness

If you ran step 1 without `-b main`, or with the wrong git identity, you will see:

| FAIL | Cause | Fix |
|---|---|---|
| `HP-05` | `HANDOFF.md` still names the scaffold placeholder `` `0000000` `` | replace it with your real short HEAD |

**It is configuration, not a defect.** The harness is reporting your repo's actual state
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

    practice: /path/to/your-standard.md   # optional: your own house rules, hash-pinned
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

## 6. Step 4 — There is one config, not five classes

There is **no class to pick**. gobstack installs one configuration; the ban table self-selects
per row (a ban runs only when a real file matches its `applies_when` glob), so the installer
needs no taxonomy to decide what to render. "Done" is defined by the repo's own gate, not by a
category: ask *what does "done" mean here?* and declare it as `gate_<name>_cmd` (§5).

Parts you do not want are switched off by name with `--opt-out <part>`, which records the part
in `disabled:` so its rows report `SKIP (opt-out)` rather than passing silently.

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
it go green. Break it on a row this walkthrough can actually break: `IN-02` hashes the 13 files it
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

A default install lands on a specific shape. The first red is
the scaffold teaching on purpose — `HP-05`, the `0000000` placeholder in `HANDOFF.md` (§4). The
walk in §4 measured, step by step:

    13 passed, 1 failed, 0 advisory, 13 skipped     # straight after the install (the HP-05 placeholder)
    14 passed, 0 failed, 0 advisory, 13 skipped     # name a real commit in HANDOFF.md, commit, and it is green

(On the older `gob init` walk the uncommitted-install and untracked-SPEC reds — `CM-03`, `SP-02`
— were the first two FAILs; both are library rows now, off by default.) Name a real commit in
`HANDOFF.md`, commit, and give the gate lines real commands (§5), and it is green:

    14 passed, 0 failed, 0 advisory, 13 skipped     (on a real project; your numbers will differ)

**Thirteen rows skipping is correct**, and each skip prints its reason. In plain terms: the
harness is telling you which of its rules have nothing to read yet. It is a checklist, not a
scolding.

Two readings that are easy to get wrong:

- **Advisory rows are not passes.** No row of the shipped matrix is labelled `advisory` — the
  six advisory rows moved to the library (`gob verify --library`), so a default install sits at
  0 of 10 on `advisory_ceiling: 10`. Enabling one from the library spends a slot: adding
  unenforceable rules eventually fails verify until one is removed. That is intentional.
- **Vacuously-passing rows are not proven.** A rule about "the first review note" passes when there
  is no review note yet. It is not lying — it is passing on an empty set. `docs/GUIDE.md`
  names which rows do this.

---

## 10. When something goes wrong

| Symptom | What it means | What to do |
|---|---|---|
| `refused to overwrite: HANDOFF.md`, exit 1 | your repo already had a HANDOFF | **do not `--force`** — reconcile it (below) |
| `IN-02 ... practice EDITED` | someone changed the pinned standard | re-pin deliberately: `--re-pin` |
| `gob: unrecognized command: <verb>` (exit 2) | you ran a verb outside the v2 surface (`audit`, `install`) | use the six wired verbs: `init`, `map`, `verify`, `bans`, `mcp`, `uninstall` |
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
same commands are available outside any repo through the npm CLI: `gob init` /
`gob verify` / `gob bans` / `gob --version`.

**Two exit-code contracts worth knowing:**

| Command | Exit codes |
|---|---|
| `goblin-install` | `0` ok · `1` a refusal (with the path and the fix) · `2` bad input |
| `goblin-verify` | `0` all checks passed · `1` a check failed · `2` could not run · `3` the manifest itself is broken |
| `gob` (npm CLI) | propagates the subcommand's codes verbatim; a verb outside the surface (`audit`/`install`) is refused with exit 2 and the usage |

`3` is the one to notice: it means gobstack's own rule table is malformed, not your project.

---

## 11. Reference

### Commands

    gob init [--heuristic] [--write <proposal>] [--target <dir>] [--dry-run] [--yes]
             [--with-mcp-config]
    gob mcp                                  # the MCP stdio server (three tools, local only)

    .gob/bin/goblin-verify [--only <id[,id...]>] [--json] [--list]
    .gob/bin/goblin-bans           # run the ban list
    gob uninstall --target <dir>             # the uninstall job
    goblin-install --target <dir> --re-pin   # the deliberate re-pin (from the checkout/install tree)

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

gobstack ships three documents. This guide is the front door; the README is the reference; LIMITS is the honesty ledger. The sections below (§14–§18) absorb the material that used to live in the per-topic files.

| File | Read it for |
|---|---|
| `README.md` | the thesis, every rejected alternative, the risk register and non-goals, and the glossary |
| `docs/GUIDE.md` | this file: the first week in order, the interface, the rule matrix, the playbooks, the integration points |
| `docs/LIMITS.md` | **what this cannot check** — read this one early: the security and perf lanes, and every recorded limit |
| `docs/RECORD-NOTES.md` | the wave codes the changelog and the matrix parentheticals use, one line each |

---

## 12. What this will not do for you

Stated plainly, because a guide that oversells its tool is worse than no guide:

- **It cannot force an agent that never reads `HANDOFF.md`.** It can only make the file exist,
  structured and dated, so the reading is cheap.
- **It cannot prove your checks test the right thing.** A green suite that asserts the wrong
  behaviour passes. Only the REPLAY habit (prove it goes red) catches that, and only if you do it.
- **It cannot see a real user's device.** A performance number measured on your machine is not a
  user's experience, and the harness says so in its own output.
- **Six of its rules are labelled `advisory`** — counted, not enforced, and capped at a ceiling of 10. They
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
you declare, and the REPLAY habit. The rest is optional machinery you can switch off per part.
Lead with *"prove it was broken first"* — it is the one practice that survives contact with a
deadline.

---


---

## 14. The interface — the installer and the verifier

Dependencies: **`bash`, `git`, `awk`, `sed`, `grep`, `python3`.** No npm, no jq, no yq, no
network. `python3` is used for one thing only: reading the two-level model mapping file, the
same way the fleet's own tool reads it. Everything else is line-oriented shell.

### Install

    goblin-install --target <dir> [options]

    --target <dir>        required; the repo root to install into
    --practice <path>     the referenced standard (default: $GOBLIN_PRACTICE; unset = no
                          practice pin; a named path that is absent is reported, never
                          silently dropped)
    --parts <list>        comma list to install (default = the whole default part set)
    --archive             mark the project archive: verify requires no HANDOFF and no gates
    --skills yes|no       install agent skills under .hermes/skills (default no — the harness is
                          neutral). On a repo whose record already has skills installed, an OMITTED
                          flag keeps them; an explicit --skills no removes them.
    --dry-run             print the plan; write nothing
    --no-verify           skip the health check (goblin-verify) at the end; the wizard
                          still installs, and prints the skip notice
    --upgrade             re-install at the current version; report created/updated/unchanged/skipped
    --opt-out <part>      record the part in disabled: so its required checks are skipped
    --uninstall           remove exactly the files in installed.json
    --re-pin              re-record practice_sha256: for an edited standard; nothing else changes
    --force               allow overwriting a file gobstack did not create
    --yes                 non-interactive; take the defaults above

Exit codes: `0` success or no-op · `1` a refusal, with the path and the fix · `2` bad input or a
missing dependency.

#### Idempotency

The installer writes only paths it records, and it **hash-compares before writing**, so running
it twice with the same arguments and the same `VERSION` prints `no-op: N files unchanged` and
exits 0 **without touching a byte**. A different `VERSION` is an upgrade: it rewrites only the
files whose hash changed and prints `created C · updated U · unchanged N · skipped S`.

#### Three kinds of file, and why the distinction matters

| kind | recorded as | overwritten? | hash-checked? | removed by `--uninstall`? |
|---|---|---|---|---|
| installed artifact (bin, manifest, opt-in skills, harness scaffold) | `files` | yes, on upgrade | yes — IN-02, SK-02 | yes |
| created once, then yours (the `AGENTS.md` gob block, `HANDOFF.md`, `AGENTS.md`, `*-SPEC.md`, `reviews/.gitkeep`) | `owned` | never | no — you are meant to edit them | no, except the config |
| pre-existing, left alone | `refused` | never | no — IN-04 only proves it was not taken over | no |

A `refused` path is not a dead end. For `HANDOFF.md` the remedy is the reconciliation in
`docs/GUIDE.md` ("Adopting into a repo that already has a `HANDOFF.md`"): keep the project's
file, merge the five required sections and a dated gate line in, then verify. `--force` overwrites
it and exists for a scaffold copy with nothing to keep.

An **edited standard is not a dead end** either. `practice_sha256:` pins the referenced standard
and `IN-02` re-checks it, so one intended edit to the standard reds `IN-02` in every installed
repo. The remedy is the explicit re-pin below — not a hand-edit of the hash, and never an
automatic one.

`.gitignore` is not a file gobstack owns: it appends **one marked block** and never rewrites
the rest. The `AGENTS.md` gob block is generated once and is gobstack's own config, so
`--uninstall` removes it; `HANDOFF.md`, `AGENTS.md`, `ROUND-000-SPEC.md` and `reviews/` are the
project's record, not the harness's, and are left in place.

#### An edited standard is not a dead end

the `AGENTS.md` gob block records `practice:` and `practice_sha256:`, and `IN-02` re-checks that hash.
The pin has exactly one purpose: to make a **silently** edited standard visible rather than
assumed. The standard itself is a living document, corrected in place, so an edit that is
*intended* needs a deliberate way to re-record the pin. That is all `--re-pin` is:

    goblin-install --target <dir> --re-pin

It rewrites one line of the config — nothing else — and prints both hashes:

    practice re-pinned: /path/to/PROJECT-PRACTICE.md
      recorded 81612b17ac3483b9d613aeb86e236539fc17403e38bf7903af708d369cf7918f
      now      8334ac24f056c94c35fa97831253e7e12bace68ae5747c81ae3b696c42ddd33a

`.gob/bin/goblin-verify --only IN-02` then reports `practice pin ok`. Every other line of
the `AGENTS.md` gob block, comments included, is untouched, so the `owned` contract holds for everything
except the one value you just asked to re-record. Commit the config like any other change.
`--dry-run` prints the plan and writes nothing; when there is nothing to do it prints
`practice pin already current` and exits 0.

Four things it deliberately is not:

- **not automatic.** `goblin-verify` never re-pins, and neither does a plain `--upgrade`: a pin
  that updated itself would be the very silent edit the pin exists to catch. The `practice EDITED`
  failure detail names this command, so the remedy is printed where the operator meets the problem.
- **not a hand-edit.** Editing `practice_sha256:` by hand does work, but nothing then checks that
  you pasted the right hash — which is the one thing this command does for you.
- **not `--force`.** `--force` is about overwriting a file gobstack did not create; it has no
  opinion about the pin.
- **not a re-point.** It re-records the hash of the path already in `practice:`. Pointing the repo
  at a *different* standard is a deliberate config edit, not a re-pin.

Refusals are exit `2`, each naming the path: no the `AGENTS.md` gob block, no `practice:` recorded, the
recorded path absent, or no `practice_sha256:` line to rewrite. A failed write is exit `1`, with
the path — the command never reports a re-pin that did not land. One refusal guards the mode
itself: `--uninstall --re-pin` is exit `2` with `--uninstall and --re-pin are different jobs; run
them one at a time` — the two modes run one at a time, and the pair is refused before anything is
removed.

#### Never a half-state

If any write fails the installer prints the file and exits 1. It does not roll back, because
every created file is either a whole file or absent, and the record is written last.

### Verify

    goblin-verify [--only <id[,id...]>] [--json] [--list] [--source <gobstack path>]

Output is one line per executed row, in manifest order, plus a summary line at the end:

    PASS  HP-01  (test -f HANDOFF.md)
    FAIL  GT-02  gate commit: false -> exit 1
    SKIP  FM-01  feature_map: is empty - this state is UNREACHABLE ...
    SKIP  SK-01  Every shipped skill has name + description frontmatter. (opt-out: playbooks)

Those three lines are one row of each marking a default run can show (no row of the shipped
matrix is advisory — the advisory rows live in the library). The summary line of a green default
run is `14 passed, 0 failed, 0 advisory, 13 skipped`.

**Exit codes:** `0` every executed check passed (advisories and skips do not fail the run) ·
`1` at least one check FAILED · `2` verify could not run (not installed, a missing dependency,
an unparseable config) · `3` the manifest itself is broken (a row with no check and no
`advisory` label, or a duplicate id).

**What verify asserts, in one sentence:** that the files it installed are the files on disk,
that every rule in the manifest with a command still passes, and that the untestable remainder
is counted and capped.

**What it cannot see** (printed at the end of every run): whether a check in the harness dir
tests the right path rather than merely passing; whether the forge is bound by the workflow
a config declares found; whether a human
read the diff; and whether `.gob/installed.json` — the record every drift check trusts — was
itself rewritten, since it
is not signed (`docs/LIMITS.md` #18). The CI lane is out of the product and its doc is deleted; the
verifier still names the CI lane's blind spots in its "cannot see" footer, because the *reason* a
workflow file is not a gate still holds (`docs/LIMITS.md` #34).

#### A fresh install verifies green

Measured on a fresh DEFAULT install (skills opt-in, W6 neutral-first), committed with no
hand edit: **`14 passed, 0 failed, 0 advisory, 13 skipped`, exit 0.** Thirteen rows skip with
a reason — the three active-out skill rows (`SK-01`, `SK-02`, `SK-04`) that skip on the
`playbooks` opt-out a skills-free install records: `BN-01`/`BN-02`/`BN-05`, which have no `.ts`
file for a ban's `applies_when` glob, so they report *not applicable*, and `BN-03` with the four
electron bans `BN-06`..`BN-09`, which the `bans:` list does not enable
(`bans: [BN-01, BN-02, BN-05]`), so they skip as *not enabled* rather than as *unread* — and
`FM-01`/`FM-02`, which have no feature map yet (`feature_map:` ships empty on purpose: a fresh
install must not be born RED — G1, `docs/LIMITS.md` #30). Thirty-two further rows are **not
skipped but OFF** — they live in the library (`gob verify --library`), the rows that are not
right for every repo. Every skip above is a *not yet*, not a pass.

The parts that only a round can produce do **not** fail on a fresh install; the round-shaped
rows (`PG-01`..`PG-03`) are library rows now — off by default — and the declared gate *is* the
shipped floor until step 3 replaces it. `P8`
(`goblin-bootstrap`) walks that first-step list because the work is not done, not because the
verifier is reporting FAILs.

### Opting out, and uninstalling

- **Per part:** `--opt-out <part>` records the part in `disabled:`. `goblin-verify` then reports
  the part's rows as `SKIP (opt-out)` in the summary, so the opt-out is **visible rather than
  absent**. The same mechanism is what makes a part's off state real.
- **The opt-out numbers are pinned (V3-3).** A default install with an explicit `--skills no`
  verifies `14 passed, 0 failed, 0 advisory, 13 skipped`, exit 0, and
  `tests/t-install-off-switch.sh` asserts that line: a silent drift in the opt-out path is caught
  rather than left as a number nobody wrote down (the `--skills no` count moved from `37/0/9/11`
  at v0.2 as the ban and feature-map rows landed; in v3 the model/role/loop and CI rows are cut,
  and the 32 not-for-every-repo rows moved to the library, so the shape is `14/0/0/13`).
- **Skills, W6 neutral-first.** A default install ships no agent skills. A repo whose record has
  `skills: yes` keeps them through every flag-less re-install and `--upgrade` (the installer
  reads the record's choice and says so out loud); an explicit `--skills no` removes exactly the
  recorded skill files; `--uninstall` removes everything recorded, as always.
  `tests/t-install-off-switch.sh` walks that migration: install `--skills yes`, upgrade flag-less,
  the skills survive byte-identical; uninstall, and they are all gone.
- **Whole harness:** `--uninstall` deletes the `files` list plus the `AGENTS.md` gob block, removes
  every directory that leaves empty (deepest first, after `installed.json` itself is gone — the
  order that used to leave `.gob/` and the sixteen `.hermes/skills/*` directories behind),
  leaves `HANDOFF.md`, `AGENTS.md`, `ROUND-000-SPEC.md`, `reviews/` and the `.gitignore` block
  (with a `# gobstack uninstalled <date>` marker inside it), and prints what it removed and
  what it left.

### The two commands, verbatim

    gob init --write <proposal.md> --yes
    .gob/bin/goblin-verify

From a checkout, without installing anything:

    bash tests/run-tests.sh

---

## 15. The adoption order

**`—` is a real, enforced option.** The installer records every off part in `disabled:`, so its
rows report `SKIP (opt-out)`. A repo with 1,599 test files or 27 research notes is not broken by
a forced harness directory — the part is switched off by name.

Four consequences that follow from measurement, not taste:

1. A forced harness directory breaks a repo whose tests are not `checks/*.mjs`.
2. Two gate *kinds* must exist in the schema: hermetic (repo-local) and host (touches paths
   outside the repo). A host gate reported as hermetic reports environment differences as
   failures.
3. **The gate command must be declarable per project, never inferred from the stack.** One
   inferred command is wrong for a repo with no runner, a repo that cannot run its own typecheck
   read-only, and a repo whose runner lives in a skill — all at once. The shipped gate is a
   **floor**, and `P8` step 3 is "replace it".

### The adoption order

Each step is independently useful and the later ones build on the earlier:

1. **A repo already at the standard, first — to prove the installer, not to improve the
   project.** The only honest test of an installer is that it is idempotent against a repo that
   needs nothing. Success = install, then verify reproduces the harness count and the ratchet
   number with `git status` unchanged.
2. **The highest-risk gap second.** A large repo with client deliverables and **no version
   control**: everything else is recoverable from a working tree, that one has no "before".
   Gate on: `git init` done, `.gitignore` verified against local env and build-info files, first
   commit exists, HANDOFF exists, the real typecheck recorded.
3. **The fleet-config repo third — highest value per minute.** A non-code repo that cannot
   fix its own home is not publishable.
4. **The cheapest correctness win fourth.** Content types untracked inside a repo that looks
   protected: commit them and write a HANDOFF.
5. **The small ones fifth** — they exercise the `—` switches. One needs a single commit; another
   needs its `.gitignore` fixed **before** `git init` because a credentials file sits in-tree.
6. **The two small repairs sixth** that make a fleet self-consistent: a stale HEAD, a stale
   number, and the REPLAY added to each.
7. **The rest seventh — real work, no emergency.** Each is blocked on a *decision* more than on
   effort.
8. **An archived input directory — never adopted.** It is the regression test for the off
   switch.

### What a first install actually gives you

`goblin-install` exits 0 and creates `.gob/` (the verifier, the manifest, the config), `HANDOFF.md`,
`AGENTS.md`, and — when the parts are on — `ROUND-000-SPEC.md`, `reviews/`, and the harness
scaffold in `checks/`. A default install ships **no** agent skills: skills are opt-in (W6 neutral-first).

Then, in order:

    git add -A && git commit          # the install is a change like any other
    .gob/bin/goblin-verify            # 14 passed, 0 failed - the uncommitted-install red (CM-03) is a library row now

A default install (no agent skills) is **green** — `14 passed, 0 failed, 0 advisory,
13 skipped`, exit 0 — once
`HANDOFF.md` names a commit that exists; before that edit the scaffold's `0000000` placeholder is
the one expected red (`13 passed, 1 failed`). Both numbers are measured, not assumed
(`docs/GUIDE.md`; step 2 of `docs/GUIDE.md`). Thirteen rows skip with a reason: the
three active-out skill rows (`SK-01`, `SK-02`, `SK-04`) skip on the `playbooks` opt-out a
skills-free install records, plus the not-yet rows: `BN-01`/`BN-02`/`BN-05` (no `.ts` file
for a ban's `applies_when` glob, so each reports *not applicable*), `BN-03` with the four
electron bans `BN-06`/`BN-07`/`BN-08`/`BN-09` (not in the `bans:` list `[BN-01, BN-02, BN-05]`, so
they skip as *not enabled* rather than as *unread*), and `FM-01`/`FM-02`
(no feature map yet). Thirty-two further rows are held in the **library** (`gob verify
--library`) — off by default, each with the line that turns it on. The round-shaped rows
(`PG-*`) and the corpus rows (`RC-*`) are library rows now, so the first-step list is a list of
work, not a list of FAILs.

### Adopting into a repo that already has a `HANDOFF.md`

The installer never overwrites a `HANDOFF.md` that existed before the install. It prints
`refused to overwrite: HANDOFF.md` and exits 1. **That exit is correct, and `--force` is not the
remedy**: `--force` replaces the project's own record with the scaffold, which is the act the
refusal exists to prevent. `--force` is for a scaffold copy with nothing to keep.

The remedy is a reconciliation. The project's file stays the file of record; nothing is deleted
(a stale sentence is corrected in place with a dated parenthetical, never removed).

1. **Keep the file.** Do not re-install with `--force`, and do not delete it.
2. **Give it the five sections it is missing**, each as an H2 or H3 heading whose *first word* is
   the slot name — a marker or number prefix (`## ▶ START HERE`) is fine:

   | section | accepted first words |
   |---|---|
   | orientation | `START HERE` |
   | current state | `State` · `Status` |
   | gates | `Gate` · `Gates` |
   | next steps | `Next steps` · `Next` |
   | what is not verified | `Not verified` · `Unverified` · `Not proven` · `Unproven` · `Pending <x> device test` |

   `HP-02` is satisfied by the heading, not by the words appearing inside one: a `## BOARD STATE`
   heading is not a `State` section.
3. **Put the current gate numbers inside the `Gates` section, each with its date.** Every
   gate-bearing line in that section must read `measured YYYY-MM-DD`. Gate numbers elsewhere (in
   `State`, in a round block) are not the current gate line, and historical round gate lines are
   exempt — they are the record and are kept:

       - `tsc`=0 · `build`=0 · hex **144** (ceiling 160) · 38/38 harnesses green · measured 2026-09-24

4. **Name the HEAD in `State`** (`HEAD when this file was written: <short sha>`) — `HP-05` wants a
   commit that exists in this repo and is an ancestor of HEAD.
5. **Commit, then verify:**

       git add -A && git commit
       .gob/bin/goblin-verify        # HP-02, HP-03, HP-05 go green

   Success is the full green path (`14 passed, 0 failed, 0 advisory, 13 skipped`, exit 0)
   with `git status --short` empty.

The edit is additive and small — measured on the model repo (§1's exemplar, 2450 lines): three
headings plus a `State` block, one dated gate line and a `Not verified` block, 15 lines, no line
removed.

---

## 16. The rule matrix

`.gob/manifest/enforcement.tsv` is the matrix: **one row per on-by-default rule**. The `check`
column holds a real command that `goblin-verify` runs, or the literal `advisory`, or the marker
`goblin-verify --only <ID>` for a check that needs more than one shell line (those are
builtins in `bin/goblin-verify`, so the row stays self-describing and the matrix stays the
single source of truth). `.gob/manifest/library.tsv` holds the **off-by-default** rows — the shipped
rules that are not right for every repo — and `gob verify --library` lists each with the exact
line that turns it on: paste that line into the repo-local, versioned
`.gob/manifest/enforcement.local.tsv`, and the row joins the run exactly as if it were in the
matrix — it can PASS, FAIL (with its `remedy:` line) or report itself *not applicable*. The
override file is **optional**: absent, a run is the default set and says nothing about it. When it
is present, the summary names the rows it added under `enabled-locally:`, so a reader can tell them
apart from the default set. A local row that names no check the engine can run is **refused**
(exit 3, with a named remedy) — a row id in neither the matrix nor the library, a
`goblin-verify --only <ID>` marker whose builtin does not exist, a check that cannot execute, or a
bare id with no check cell: a repo cannot add a rule that nothing verifies.

Some `if_not_why` cells carry internal workstream tags — `W1`, `W5`, `W6` — recording which
redesign of this toolkit last touched that rule's check (W1 the global-engine split, W5 the
publish prep, W6 neutral-first).
They are historical provenance only: the rule text and its check are authoritative, not the
tag. `D1`..`D6` are the design decisions in `README.md`; `Z1`-style identifiers are
independent verification pass IDs.

`scope` is `target` (runs in an installed repo via `goblin-verify`) or `source` (runs in
this repo via `tests/run-tests.sh`). The two scopes name WHOSE proof burden a row carries:
`scope:source` is the framework's own burden when developing gobstack (a dev runs
`run-tests.sh`), `scope:target` is the adopting repo's burden (the user runs `goblin-verify`).
The source-scope rows (`PR-01`..`PR-04`) therefore never run
in an installed repo — they execute only in this repo's own test suite. `enforced_by` is one of
five values, and the enum is
closed and now ENFORCED (`IN-03`'s third clause, Z1-5): `script`, `lint`, `gate`, `advisory`,
plus `test` for a source-scope row, whose check is a script under `tests/` run by
`tests/run-tests.sh`.

Measured shape of this table: **31 rows** - 27 target, 4 source; advisory 0, gate 4, lint 16, script 8, test 3 (the on-by-default matrix, `.gob/manifest/enforcement.tsv`). The **library** (`library.tsv`) holds a further **32 rows**, all `scope:target`, off by default. The table below renders the **full 63-rule set** (matrix + library) so a reader sees the whole contract; the 32 library rows are the ones `gob verify --library` names.

### The rows

| id | scope | enforced by | rule | check | if it cannot be enforced, why |
|---|---|---|---|---|---|
| `IN-01` | target | script | The install exists and records its version + every file's hash. | goblin-verify --only IN-01 | — (W1: the check is a builtin so the engine.mode=global clause can run — a global, declaration-only repo has no install record and SKIPs with `global engine mode — no per-repo install record`; the vendored clauses are the old one-liner: the record exists and names its version) |
| `IN-02` | target | script | Every installed file still matches its recorded hash. | goblin-verify --only IN-02 | recover: git checkout -- .gob/installed.json (or re-run `npx @techgoblin/gobstack init --write` to re-install); for a file it names drifted: git checkout -- <path> (if the edit is yours and intended, re-pin it: `goblin-install --target <dir> --re-pin` from the checkout/install tree) |
| `IN-03` | target | script | The verifier's own manifest is complete: every rule has a check or is advisory. | goblin-verify --only IN-03 | — (this row is the reason the matrix cannot rot; the second clause is D6's shape in general: a row that carries no check must be labelled advisory, or it claims verification it does not perform. The third clause is Z1-5: `enforced_by` is documented as a closed enum in docs/GUIDE.md and was read by NOTHING, so a typo in that cell changed nothing - `script\|lint\|gate\|advisory` plus `test`, the source-scope value whose check is tests/run-tests.sh. W1: the check runs against whichever manifest the engine actually resolved (the chain in bin/goblin-verify), no longer the hardcoded per-repo path — the rule's meaning is untouched, only the path input follows the engine) |
| `IN-04` | target | script | No file gobstack did not create has been overwritten. | goblin-verify --only IN-04 | Detects a file the installer recorded as pre-existing (a `refused` entry) that has since vanished, or that is listed as installed anyway. The second clause is an internal-consistency guard: with correct code a refused path is never written, so it fires only if the installer regresses. The negative control exercises the vanished branch. |
| `HP-01` | target | gate | HANDOFF.md exists at the root. | test -f HANDOFF.md | — |
| `HP-02` | target | lint | The HANDOFF carries its five required sections. | for h in 'START HERE' 'STATE\|STATUS' 'GATES?' 'NEXT STEPS\|NEXT' 'NOT VERIFIED\|UNVERIFIED\|NOT PROVEN\|UNPROVEN\|PENDING[^.]*DEVICE TEST'; do grep -qiE "^#{2,3}[[:space:]]+[^[:alpha:]]*($h)\b" HANDOFF.md \|\| { echo "missing section: $h"; exit 1; }; done | Partial: proves a heading exists whose first word names the slot, not that the section's content is complete. The slot may use the repo's own vocabulary (the model repo's `### NEXT` passes; `Status`, `Gate`, `Unverified`, `Pending <x> device test` are accepted); a heading that merely contains the word (`## BOARD STATE`) does not satisfy `State`. |
| `HP-03` | target | lint | Every gate number is a measurement with a date, never a copy. | goblin-verify --only HP-03 | Builtin, anchored on the gate NAMES `AGENTS.md` declares (GT-01's source of truth) rather than on a hardcoded keyword list: the shipped gates are named `commit` and `todo_ceiling`, neither of which the old list matched, so on a fresh install the only line it could see was the template's own example sentence, and a real gate line could lose its `date` and the row stayed GREEN (G8-2). A line whose text says "example of the required form" is template prose, not a gate number, and is skipped, so the template cannot satisfy the row. Partial: it proves a dated line inside the `Gates` section exists and that every gate-bearing line there carries a date - not that the number was re-measured that day, and not a gate-bearing line that names no declared gate and carries no gate-shaped keyword (so a line the config does not declare and the keyword list does not recognise is unseen). Historical gate lines outside that section are exempt by design - PROJECT-PRACTICE section 1's stale-sentence rule requires them to be kept. |
| `HP-04` | target | advisory | A stale sentence is corrected in place with a dated parenthetical, never deleted. | advisory | Detecting a silent deletion needs semantic judgement; a diff heuristic (>=5 removed non-empty lines with no 'corrected' addition) is too noisy to gate on. goblin-verify --only HP-04 prints the heuristic as a warning only. |
| `HP-05` | target | gate | The HANDOFF names the HEAD it describes. | goblin-verify --only HP-05 | Deviation from the design spec, with the reason: the spec's literal check is `grep -q "$(git rev-parse --short HEAD)" HANDOFF.md`, which can never pass - committing the HANDOFF moves HEAD, so the file can only name a commit that is now an ancestor. The mechanised form is therefore 'the HANDOFF names a commit that exists in this repo AND is an ancestor of HEAD', which still catches the defect it exists for (a review/handoff artifact that names no commit at all). |
| `SP-01` | target | gate | A *-SPEC.md file exists at the repo root (any round, not the current one - round-scoping arrives with the W6 staged chain). | ls ./*-SPEC.md >/dev/null 2>&1 | Skipped when `spec` is in `disabled:`. |
| `SP-02` | target | script | The SPEC is committed, not left untracked. | test -z "$(git ls-files --others --exclude-standard -- '*-SPEC.md')" | — |
| `SP-03` | target | lint | Every AC: item is checkable without a human. | awk '/^[[:space:]]*[-*][[:space:]]/ && /AC[0-9]*:/ && !/`\|==\|===\|exit\|<\|>/ {print; bad=1} END{exit bad}' ./*-SPEC.md | Partial: structural only - a checkable-looking bullet can still be unfalsifiable. The matcher is `AC[0-9]*:` because the shipped template writes `- AC1: ...`; the literal `/AC:/` only saw a bullet that spelled the label without a number. |
| `GT-01` | target | gate | The gate set is declared, never inferred from the stack. | goblin-verify --only GT-01 | Builtin: every `gate_<name>_cmd:` key in the AGENTS.md gob block is a DECLARED gate and its declaration and command are one line - a gate cannot lose its cmd and survive the count (G8-3, the condition of G8's own score sentence). The count is of declarations, not of runnable pairs. It cannot see whether a declared command is the RIGHT gate for the project: it proves a command exists, not that it is meaningful. |
| `GT-02` | target | gate | Every declared gate runs and exits 0. | goblin-verify --only GT-02 | — |
| `GT-03` | target | script | The round reports one line of measured numbers. | test -f .gob/last-gate-line && [ .gob/last-gate-line -nt "$(git rev-parse --git-dir)/logs/HEAD" ] | The freshness reference is HEAD's reflog (`.git/logs/HEAD`), which every HEAD movement rewrites - a commit in an attached or a detached worktree included, and independently of whether the refs are packed. The clause it replaced read `.git/HEAD`, a file a commit never rewrites (only branch operations do), so a commit landing after the measured line left the row GREEN while the round had moved on (D2, measured: `.git/HEAD`'s mtime unchanged across a real commit, `--only GT-03` exit 0). Two limits remain, recorded rather than hidden: a repo with the reflog disabled (`core.logAllRefUpdates=false`) has no reference to compare against, and `-nt` against a missing path is true, so the clause passes vacuously and the row then proves only that a measured line EXISTS (a repo with no commit yet is the same case); and the clause reads ANY HEAD movement as staleness, so a checkout, a branch rename or a reset FAILs it until the next gate run rewrites the line. That second behaviour is what makes a full run self-freshening: `GT-02` writes the line earlier in the same pass, so the row asserts that the line in front of you came from THIS run. `tests/t-gt03-freshness.sh` is the control, in both directions. |
| `GT-04` | target | gate | A ratchet is declared with a ceiling. | goblin-verify --only GT-04 | — |
| `GT-05` | target | gate | The ratchet has not risen. | goblin-verify --only GT-05 | — |
| `HS-01` | target | lint | Asserting harnesses follow the house shape. | goblin-verify --only HS-01 | A declared harness_dir that is absent FAILS when `scaffold_checks: yes`; when it is `no`, the row SKIPs with a reason. Keying the skip off the path alone let one config line switch this row and HS-02 off. A report utility in the same dir is counted and reported separately rather than failing the run. |
| `HS-02` | target | gate | A check green on both trees proves nothing - the REPLAY must show RED pre-change. | goblin-verify --only HS-02 | The declared `replay.cmd` is EXECUTED with `{name}` replaced by each harness's name, in the pre-change worktree, with `replay.env=<commit>` set (Z1-4). Two clauses that used to be unheard: a command that interpolates no `{name}` FAILs (it cannot be running the harness it names, so nothing was replayed), and a command that cannot be executed at all - exit 126 or 127 - FAILs rather than counting as a RED harness. The harness's name is substituted SHELL-QUOTED (`printf %q`), because the name is part of the command text the shell parses; unquoted, a name carrying `;` or `#` reached the shell as syntax (Z2-3, the G8-1 surface class), and the control for it carries a metacharacter-bearing file name. What it cannot see: a command that runs *something else* under the harness's name and exits non-zero, and whether the harness tests the right path rather than merely failing on this tree. |
| `HS-03` | target | advisory | Source probes read text with comments blanked first. | advisory | Recognising 'this probe reads source text' is semantic; a grep for the blanking helper produces false FAILs on harnesses that do not probe source. |
| `CM-02` | target | advisory | The commit message was written to a file, not passed with -m. | advisory | A backtick lost to command substitution leaves no trace a later check can read. Reported as a heuristic (unbalanced backticks in a body) only. |
| `CM-03` | target | script | Commit-as-you-go: the working tree is not carrying a dead run's work. | goblin-verify --only CM-03 | — |
| `PG-01` | target | gate | The reviewed artifact is named by SHA, and that SHA exists. | goblin-verify --only PG-01 | — |
| `PG-02` | target | script | The gate is chosen by the change, not the repo, and the tier's evidence exists. | goblin-verify --only PG-02 | — |
| `PG-03` | target | gate | A new head voids the verdict. | goblin-verify --only PG-03 | — |
| `DS-01` | target | script | Runtime data is not test fixture: a gate run must not write it. | goblin-verify --only DS-01 | — |
| `DS-02` | target | gate | Snapshot before, verify after. | goblin-verify --only DS-02 | — |
| `DOC-01` | target | advisory | A significant change updates the docs that teach it. | advisory | 'Significant' is a judgement; a diff-size heuristic fails on the cases that matter. |
| `DOC-02` | target | advisory | System-level changes are recorded wherever the project's standard says they live. | advisory | Where the recording lives may be owned by a stricter external rule than gobstack may add; the repo can only state it. |
| `SK-01` | target | lint | Every shipped skill has name + description frontmatter. | goblin-verify --only SK-01 | W1: the check is a builtin so the engine.mode=global clause can run - in global mode the procedure tier is emitted per platform (not carried in this repo) and the row SKIPs with that reason instead of passing vacuously on a repo with no skills (§2.5 names SK-01 alongside SK-02/SK-04). In vendored mode it is exactly the old loop: every SKILL.md must open with frontmatter carrying both name and description. |
| `SK-02` | target | script | The skills on disk match their recorded hashes (no drift). | goblin-verify --only SK-02 | — |
| `SK-03` | target | script | A rule with no mechanism is labelled advisory, and the advisory count is reported. | goblin-verify --only SK-03 | — |
| `SK-04` | target | lint | Every shipped skill says what it cannot see. | goblin-verify --only SK-04 | Partial: proves the section exists, not that what it says is complete or true - the limit every prose rule carries. Every shipped skill already carries it, so the row is GREEN on a fresh install and RED only under a real violation. W1: the check is a builtin so the engine.mode=global clause can run - in global mode the procedure tier is emitted per platform (not carried in this repo) and the row SKIPs with that reason. |
| `PT-01` | target | lint | No tenant-specific string inside a reusable rule. | for d in skills manifest bin templates .gob .hermes; do [ -d "$d" ] \|\| continue; grep -rniE --exclude=AGENTS.md --exclude=installed.json '(h[a]rvey\|tech-g[o]blin\|/h[o]me/[a-z]+\|g[o]blin-ui\|op[e]n-door\|sup[r]eme\|bb[t]ech\|c[l]v)' "$d" && exit 1; done; exit 0 | — (the rules an install actually writes live in `.gob/` and `.hermes/`, not in the source layout. Two documented exceptions: `AGENTS.md`, which holds `practice:` - per-machine config, not a rule - and `.gob/installed.json`, which since W1 records the machine's absolute `engine_dir` in its `engine:` block - both per-machine facts, not rules - each excluded by name. The pattern is written with character classes so this row cannot match itself.) |
| `CL-02` | target | script | An archive: true project verifies GREEN without a HANDOFF or gates. | goblin-verify --only CL-02 | Falsifiable: FAILs when `archive:` is not `true`/`false`, and when the config's value disagrees with the one the install recorded in `.gob/installed.json` (so the waiver cannot be flipped on by hand). It cannot observe the *effect* of the waiver on the other rows without re-entering the runner. |
| `SC-01` | target | lint | No secret file is tracked. | n=$(git ls-files \| grep -iE '(^\|/)\.env\|\.pem$\|\.key$' \| grep -vcE '\.(example\|sample\|template)$'); printf '%s tracked secret file(s)\n' "$n"; [ "$n" = 0 ] | Partial: it sees tracked PATHS, never contents - a secret pasted into a tracked file is invisible here, and the pattern is a name family, so a credential inside `config.ts` is missed by construction. |
| `SC-02` | target | gate | The ignore rules cover the whole secret family. | goblin-verify --only SC-02 | Builtin, and behavioural: clause 1 reads `.gitignore`; clause 2 asks git's own matcher (`git check-ignore`) for `.env`, `.env.local` and `.env.production` one path at a time, so a rule that looks right but does not match still fails. It cannot see a secret already in git history, or one committed under a name the family does not cover. SKIPs with a reason when there is no `.gitignore` and no `package.json`. |
| `SC-03` | target | lint | No client-visible name is secret-shaped, and no build output carries a secret literal. | goblin-verify --only SC-03 | Builtin, two clauses: the `NEXT_PUBLIC_*_(SECRET\|TOKEN\|KEY\|PASSWORD\|PRIVATE)` name pattern over source, and known secret prefixes over the declared build output. Partial: a prefix pattern cannot see a secret that does not look like one, and clause 2 says "no build output to scan" on the line rather than skipping silently. The source scan excludes `.gob/` and `.hermes/`, so it cannot match the row text that describes it. |
| `SC-04` | target | lint | Every cookie write carries its flags. | goblin-verify --only SC-04 | Builtin, same-statement only: a write spread over three lines is not seen, and the row says so. It REPORTS that a JS-written cookie is readable by any script rather than failing on it - that is a design fact, not a bug - so the pass is about the flags, never about the choice. |
| `SC-05` | target | gate | Every write route validates its input, or is waived. | goblin-verify --only SC-05 | Builtin: it proves a validator is CALLED (`safeParse\|zod\|valibot\|yup\|ajv\|superstruct\|validate(`), never that the schema is right - a schema that accepts everything passes. `.gob/boundary-waivers` is the escape hatch, and the waived count is printed, so a silent pile-up is visible. |
| `SC-06` | target | gate | A lockfile exists, and the repo tracks it. | goblin-verify --only SC-06 | Builtin: presence, then `git ls-files --error-unmatch`. It cannot see that the lockfile is STALE relative to `package.json` - resolving that needs the package manager, which is a deliberate network-shaped step, not a check. SKIPs with a reason when there is no `package.json`. |
| `SC-09` | target | advisory | Auth is applied consistently across sibling routes. | advisory | Prose on purpose: "consistently" is a semantic judgement about a private surface no repo here has yet. Counted (advisory; the library holds it now) so the matrix cannot quietly grow prose. |
| `PF-01` | target | lint | The perf baseline names the commit it measured. | goblin-verify --only PF-01 | Builtin: the metric must equal `ratchet.name` so the budget and the measurement cannot silently disagree, the value must be numeric, the date must exist, the baseline commit must exist AND be an ancestor of HEAD (`HP-05`'s mechanic, reused rather than re-derived), and `ratchet.ceiling` must equal `perf.baseline_value` - otherwise a one-line ceiling raise passes while the row prints the contradiction, which is `I raised the budget and never measured again` (G8-6b). It cannot see whether the metric is the right one for the product, and it never re-measures: re-anchoring is a deliberate operator action. SKIPs with a reason when no perf metric is declared, or none has been recorded yet. |
| `BN-00` | target | script | Every ban has an enforcement row, every ban row names a replacement, and the ban table is not empty. | goblin-verify --only BN-00 | — (this row is the reason the ban list cannot decay into prose: IN-03's shape applied to bans.tsv, and it agrees in both directions) |
| `BN-01` | target | lint | No `any` in application TypeScript. | goblin-verify --only BN-01 | Text probe, not an AST: a `: any` inside a string or a comment is reported, and `Record<string, any>` (no leading colon) is missed. The AST form needs a parser the no-npm contract (docs/GUIDE.md) forbids (docs/LIMITS.md #27). SKIPs when the ban is not in `bans:` or its globs match no file. |
| `BN-02` | target | lint | No `@ts-ignore` / `@ts-expect-error` suppressions. | goblin-verify --only BN-02 | Text probe: it sees the directive wherever it appears, including inside a string, and cannot tell a suppression hiding a real error from one on a line that would compile anyway. SKIPs when the ban is not in `bans:` or its globs match no file. |
| `BN-03` | target | lint | No direct network call from a component. | goblin-verify --only BN-03 | Text probe over the declared component globs: it stops the call and cannot tell whether a data layer was written or the call merely moved into a helper. SKIPs when the ban is not in `bans:` or its globs match no file. |
| `BN-05` | target | lint | No import across a declared layer boundary. | goblin-verify --only BN-05 | Reads the `layers:` list; an empty list SKIPs with a reason, never a vacuous pass. It matches an import path naming the target directory's last segment - module aliases and dynamic imports are not seen. SKIPs when no file matches its globs. |
| `BN-06` | target | lint | No renderer with Node access (`nodeIntegration: true`). | goblin-verify --only BN-06 | Text probe over the ban table's globs, the same mechanism as BN-01..BN-05: it sees `nodeIntegration: true` wherever it appears, including inside a string, and cannot see a webPreferences object built at run time or spread in from another module. The STRONGER form is a runtime measurement - the renderer prints `process.contextIsolated` and `process.sandboxed` and the check requires true/true - and that needs a real Electron process, which the dependency contract (docs/GUIDE.md) does not allow a shipped rule to launch: it is the project's host gate (docs/LIMITS.md #34). SKIPs when the ban is not in `bans:` or its globs match no file. |
| `BN-07` | target | lint | No renderer with context isolation or the process sandbox turned off. | goblin-verify --only BN-07 | One probe for two properties because Electron's own documentation makes them one: disabling `contextIsolation` "also disables process sandboxing", so a repo that has turned either off has lost both. Text probe, with the same false-positive set as BN-06. SKIPs when the ban is not in `bans:` or its globs match no file. |
| `BN-08` | target | lint | No dangerous webPreferences. | goblin-verify --only BN-08 | Four one-line patterns from Electron's own security checklist (`webSecurity: false`, `allowRunningInsecureContent: true`, `enableBlinkFeatures`, `<webview allowpopups>`). Text probe: `enableBlinkFeatures` is banned by name rather than by value, so the string is reported even in a comment. SKIPs when the ban is not in `bans:` or its globs match no file. |
| `BN-09` | target | lint | No synchronous IPC and no `@electron/remote`. | goblin-verify --only BN-09 | The banned-list shape the wave's note 9 asks for, applied to Electron: `sendSync(` and `@electron/remote` block the renderer's own thread, which is the freeze these bans exist to prevent. Text probe - it sees the call site, not the call graph, so a wrapper around `sendSync` in a file the globs do not match is missed. SKIPs when the ban is not in `bans:` or its globs match no file. |
| `FM-01` | target | lint | Every feature file is indexed from the map README, declares its slug and at least one entry path, and carries the four-H2 entry contract. | goblin-verify --only FM-01 | SKIPs (exit 3) when feature_map: is empty - a fresh install has no map and must not be born RED (the D8 shape). When a map IS declared: the README must exist, every features/*.md must be linked from it in the (./<slug>.md) form and every relative .md link must resolve, each feature file's `feature:` must equal its filename stem, it must declare >=1 `entry_paths:`, and its H2s must be exactly Sub-features / How to get to it (user POV) / Driving it with <harness> / Gotchas, in that order. Partial: the README's own H2s are prose this row does not read, and 'the map lists every user-facing feature' is not mechanically checkable - that is docs/LIMITS.md #30, not a row. |
| `FM-02` | target | lint | Every entry point a feature declares still resolves in source, and no entry path changed after the map was verified. | goblin-verify --only FM-02 | SKIPs (exit 3) when feature_map: is empty. A tripwire, not a proof. The token is searched under source_root with occurrences under the map's own directory excluded - without that exclusion the map's own entry-path list satisfies the search and the row could never go RED. Freshness is `git log -1 --format=%cs` on the resolved file against the feature's `verified:` date, and git sees a FILE change, not a behaviour change: the row can be RED-when-stale and never GREEN-means-fresh. A token that also occurs in a vendored copy or a build artifact is read as resolved, and a `verified:` date is itself a claim the row cannot test (docs/LIMITS.md #30). W5-4: the search skips the harness's own directories (`.gob/`, `.hermes/`, the declared `harness_dir`) and the map's own directory, so a stub map whose token occurs only in the install no longer resolves; a token that occurs only in the target's own `docs/`, `tests/` or build output still does (docs/LIMITS.md #37). Z1-6: the resolved file must be TRACKED (`git ls-files --error-unmatch`) before its date is compared - an untracked file used to make the freshness clause skip in silence, so a map could claim `verified: 2020-01-01` over source that was never committed. |
| `VA-01` | target | gate | The generated verification skill's doctor command runs and exits 0. | goblin-verify --only VA-01 | SKIPs (exit 3) when verify_doctor: is empty (the replay.commit: "" shape). Runs the DECLARED command exactly as GT-02 runs a declared gate, and never a string read out of file content (the v0.2 blocker). Closes P6's stated-but-unenforced clause 'a generated skill that was never executed is a draft': the doctor is the smallest executable proof that the skill's own instructions still run - and it proves only that, never that the doctor tests the right path. |
| `RC-01` | target | gate | No file in the shipping tree matches a reference-corpus hash. | goblin-verify --only RC-01 | Four clauses: (1) `reference_manifest:` empty -> SKIP with that reason (the `FM-01`/`VA-01` shape - not born RED); (2) declared but missing or unparseable -> FAIL, never a SKIP; (3) any file under the declared `security: build_output:` whose sha256 appears in an entry's sha256 -> FAIL, naming path + entry; (4) the manifest itself must not sit inside the build output, at the declared path or as a byte-identical copy - it is a listing of every corpus hash, so shipping it ships the corpus's shape. Cannot see: a re-encoded/resized/recoloured asset (level 2), copied text in a shipped string (level 3), or a manifest authored weak - that is `RC-02`. |
| `RC-02` | target | lint | The reference manifest is shaped so `RC-01` cannot pass vacuously. | goblin-verify --only RC-02 | Schema `reference-manifest/1`; `generated_from` non-empty; `reference_app.package`/`.version`/`apk_sha256` (64 hex); `entries` non-empty; every entry carries `path`, 64-hex `sha256`, numeric `bytes`; `entry_count` equals `len(entries)`. SKIPs with `RC-01`'s reason when the key is empty. Exists because `RC-01` alone carries the `bans.tsv` weakness: a weakened input passes the check it feeds (`LIMITS.md` #28). It cannot see whether the entries are the *right* hashes - that is as strong as tamper hashing, and `installed.json` is unsigned (`LIMITS.md` #18). |
| `RC-03` | target | script | A lab repo tracks no extracted byte: scripts, notes, manifests, docs only. | goblin-verify --only RC-03 | Two clauses: every tracked path falls under a declared allowlist (`scripts/`, `notes/`, `manifests/`, root docs - the harness's own `.gob/` and `.hermes/` files and the `.gitignore` block it appends are the install, not the lab's content, and are excluded the way `FM-02` excludes them); and no tracked file's sha256 equals any hash in a `manifests/*.sha256`. The manifest itself lists paths and hashes, which the lab repo's own README explicitly permits - the check is about *bytes*, and it must not read the manifest as a violation. SKIPs with a reason when no `manifests/` exists. Cannot see a payload renamed and re-encoded - which is why the allowlist is a second, independent trap. |
| `RC-04` | target | lint | The acquisition record exists, and the manifest names the target and its source. | goblin-verify --only RC-04 | The header block must name a target slug + version, a source store, and a checksum (md5 or sha256 hex); the manifest must hold a `*.apk` row, the header's named apk must be that row, and a 64-hex token in the header, if present, must equal the row's sha256 (a header carrying only the md5 passes - the comparison is conditional in the engine). Weakest of the four: it proves a record EXISTS, not that the number came from the store (`HP-03`'s defect). It is the first to cut if the matrix gets heavy. |
| `PR-01` | source | test | The installer never writes outside its target. | tests/run-tests.sh | — |
| `PR-02` | source | test | A second install is a no-op, and an upgrade reports created/updated/unchanged. | tests/run-tests.sh | — |
| `PR-03` | source | test | Every target-scope check goes RED under its own violation. | tests/run-tests.sh | — (the negative control the verifier re-runs) |
| `PR-04` | source | lint | The repo is portable: no personal path in any reusable rule. | tests/run-tests.sh (the PT-01 body over the source tree, plus tests/) | — |

### Advisory rows, named

0 of the 27 rows are labelled `advisory`. 0 of them carry no executable check at all — the six
advisory rows (`HP-04`, `HS-03`, `CM-02`, `DOC-01`, `DOC-02`, `SC-09`) all moved to the library
(`gob verify --library`), so a default run carries no prose row (they are prose the matrix
refuses to pretend about).

- **HP-04** (no check at all) - A stale sentence is corrected in place with a dated parenthetical, never deleted.
- **HS-03** (no check at all) - Source probes read text with comments blanked first.
- **CM-02** (no check at all) - The commit message was written to a file, not passed with -m.
- **DOC-01** (no check at all) - A significant change updates the docs that teach it.
- **DOC-02** (no check at all) - System-level changes are recorded wherever the project's standard says they live.
- **SC-09** (no check at all) - Auth is applied consistently across sibling routes. Added when the missing entry was measured: the count said 9 and this list held 8.

`advisory_ceiling` (default 10) caps that count: **SK-03 fails the run when the advisory
count exceeds it.** The number of unenforceable rules is itself a gate. Measured (v3):
`advisory 6 of ceiling 10`.

**The budget, stated so the next rule author does not have to work it out (V1/G8-5).** The
count is 6 of a ceiling of 10, so **four advisory slots are free**: a tenth advisory row is
available, but the one after the ceiling FAILs `SK-03` unless the ceiling is raised in the same
change, with the reason written down. `SK-03` prints the arithmetic on every run
(`advisory 6 of ceiling 10 (4 free slots)`), and a ceiling that is not a number is a FAIL rather
than a silent ADVISORY. The v3 cuts returned the slots the model/role/loop, dependency-audit and
CI rows had spent.

`SK-03`'s count is the count the run itself uses: a row is advisory if its `check` cell says so
OR its `enforced_by` cell does.

### The ban list (G5)

`BN-00`..`BN-09` are not ordinary rows: they read `.gob/manifest/bans.tsv`, a table whose
every row carries a real command. A ban with no mechanism is a wish, so `.gob/manifest/bans.tsv`
holds `id`, the ban, the globs, the `applies_when` glob, the `detect` command, the replacement
code, the escape hatch, the reviewer and the source — and `BN-00` fails the whole list if any ban has no enforcement
row, if any row names no replacement, or if the table is empty. `bin/goblin-bans` is the engine
(`--only <id>` for one, `--list` for the table); each ban's `detect` exits 0 when the tree is
clean, 1 when the ban is violated, 3 when it cannot be read (no file matches its globs, no
`layers:` declared) and 2 when it could not run at all — a 2 FAILS, never passes.

Which bans apply is the config's `bans:` list, and whether a listed ban runs is decided per row by
its `applies_when` glob: an unlisted ban SKIPs with that reason, and a listed ban whose glob matches
no file reports itself *not applicable* (the default `bans: [BN-01, BN-02, BN-05]`).
`bans_exempt:` records narrow, reviewed exceptions and `layers:` is what `BN-05` reads. An
exception reaches the **probe**, not the engine's stdout: the engine exports `GOBLIN_BANS_ID` and
`GOBLIN_BANS_EXEMPT`, the probe drops the exempted hits *before* it chooses its exit code, and an
inline `// BAN-OK(<id>): <reason>` on the offending line clears that one line. Filtering stdout
after the probe had already decided was decorative and made every exemption a permanent RED
(W5-1, measured `rc 0` at `72490f0` → `rc 1` at `7fec08f`); the trade is that a project's **own**
probe must honour the two variables or the exception fails **closed** (`docs/LIMITS.md` #36). The
probes are text probes — `grep`, no `npm`, no AST — so their false-positive sets are stated on
each row and in `docs/LIMITS.md` #27, and G5's `BN-04` is deliberately unshipped for the same
reason: it cannot be mechanised without a parser, and a ban that cannot go red is worse than an
advisory.

### How a rule is added

A rule enters only by adding a row. If the author cannot write a command, the row's `check`
is `advisory` and the rule's cost is visible in the summary line. There is no third option,
and `IN-03` plus `SK-03` are what make that true: a row with neither a command nor the
`advisory` label fails the manifest before any check runs (exit 3), and the advisory count
fails the run when it exceeds the ceiling.

### What the matrix cannot do

A counted rule is still not an enforced one. The cap is a policy, not a proof, and six of
these rows are prose. That is stated here rather than implied away.

---

## 17. The playbooks in full

`.gob/manifest/playbooks.tsv` is the machine-readable form; this is the prose. Every playbook has
the same six fields, and `verification` is always a *measurable* step that also names what it
cannot see. The router that picks one is the `goblin-mode` skill.

### P1 - `goblin-investigation`

- **When:** a read-only question, or "why is this happening"
- **Steps:** 1 name the question as a falsifiable claim<br>- 2 read the code paths, cite file:line<br>- 3 if the answer is observable by running something, run it instead of asking<br>- 4 write the answer with its evidence
- **Verification:** every claim carries a file:line or a command+output; no code changes; a claim you cannot source is marked [unverified]
- **Profiles:** any
- **Role:** investigate

### P2 - `goblin-bugfix`

- **When:** a reported defect
- **Steps:** 1 reproduce it yourself<br>- 2 state the root cause with a measurement, never 'should be'<br>- 3 fix the root, not the symptom<br>- 4 prove absence on the same surface, with a negative control
- **Verification:** the repro fails before and passes after, on the same command; unit tests show branch behaviour, not bug absence
- **Profiles:** coder
- **Role:** code

### P3 - `goblin-feature`

- **When:** new behaviour
- **Steps:** 1 SPEC first (measured root cause + AC: list)<br>- 2 name the data shape before the code<br>- 3 land it in units that each end checkable<br>- 4 write the SHA it landed at into the review note
- **Verification:** every AC: item has a checkable assertion; the gate line is measured; the SHA is named
- **Profiles:** architect -> coder
- **Role:** judgment -> code

### P4 - `goblin-refactor`

- **When:** a behaviour-preserving reshape
- **Steps:** 1 pin the contract first (characterization test / snapshot / equivalence harness)<br>- 2 shape only, no behaviour<br>- 3 delete the legacy path in the same change
- **Verification:** the pin is a real assertion run before and after; a type check and lint are not a pin
- **Profiles:** coder
- **Role:** code

### P5 - `goblin-tdd-repro`

- **When:** a defect where a regression test is cheap
- **Steps:** 1 write the failing test<br>- 2 confirm it fails for the intended reason<br>- 3 smallest production fix<br>- 4 revert the fix -> the test MUST fail -> restore
- **Verification:** the RED-again step is captured; prefer no new test over a bad test; the skip path is explicit, never silent
- **Profiles:** coder
- **Role:** code

### P6 - `goblin-verify-author`

- **When:** a project has no live lane, or its gates drift
- **Steps:** 1 read the repo, not the user, for entry points<br>- 2 write the gate/check set into the harness dir with the house harness shape<br>- 3 execute it once end to end<br>- 4 add the REPLAY block<br>- 5 seed the feature map and declare `feature_map:`/`source_root:` (`goblin-feature-map`)<br>- 6 hand the generated skill to P12: `verified:` does not advance until the eval record exists
- **Verification:** a generated skill that was never executed is a draft, not a deliverable; the harness prints PASS/FAIL and exits non-zero on failure; the REPLAY shows RED pre-change; the map's index and four-H2 entry contract hold (`FM-01`), every declared entry path still resolves (`FM-02`), and the declared `verify_doctor:` exits 0 (`VA-01`)
- **Profiles:** architect
- **Role:** judgment

### P7 - `goblin-pr-gate`

- **When:** anything that should be reviewed before it lands
- **Steps:** 1 classify stakes S0-S4<br>- 2 run the gate set at the candidate SHA and record the numbers<br>- 3 write reviews/<slug>-<head7>.md with head/base/patch-id/stakes/checks-run<br>- 4 evaluate the panel rule for S3+<br>- 5 at S3+ the foreman turns N lane verdicts into one decision<br>- 6 re-check the patch-id before landing
- **Verification:** the patch-id of base..head still matches the recorded one; the review note names a SHA that exists in git rev-list; for S2+ a check ran on that SHA; at S3+ the deciding lane is disjoint from the author's
- **Profiles:** reviewer (+ architect for S3)
- **Role:** review-panel

### P8 - `goblin-bootstrap`

- **When:** adopting gobstack in a repo, or starting one
- **Steps:** 1 classify the project<br>- 2 goblin-install --target .<br>- 3 goblin-verify GREEN<br>- 4 fix .gitignore BEFORE any git init<br>- 5 first HANDOFF, first SPEC, first check script
- **Verification:** goblin-verify exits 0 and the created-file list matches installed.json; a repo with no gate declares one and records its first measured numbers
- **Profiles:** architect
- **Role:** judgment

### P9 - `goblin-handoff`

- **When:** ending a session, or picking up another's
- **Steps:** 1 commit uncommitted edits as one internally-consistent wip: commit<br>- 2 write intent / verified state / next steps / what is NOT verified<br>- 3 stale sentences get a dated parenthetical, never deletion<br>- 4 on pickup: verify inherited claims against the artifact
- **Verification:** every gate number in the HANDOFF carries 'measured <date>'; the named HEAD matches git rev-parse --short HEAD; the NOT-verified section is non-empty or says 'nothing outstanding'
- **Profiles:** any
- **Role:** judgment

### P10 - `goblin-overnight`

- **When:** an unattended run over a predicate
- **Steps:** 1 the exit condition is a checkable predicate written before iteration 1<br>- 2 it never gets relaxed<br>- 3 an escape hatch: a genuine dead end writes up why and stops<br>- 4 the morning audit reads the Attention section first
- **Verification:** the predicate is a command, and its first run is recorded before iteration 1; the predicate is pinned and never relaxed; the turn budget is set and respected; no three consecutive rows share an evidence pointer without reaching `predicate:green`; a run that ends without its predicate green carries a committed write-up naming it; every landed change has a P7 verdict row; a verdict that says `done` cites a handle the repo resolves
- **Profiles:** default + coder
- **Role:** code

### P11 - `goblin-sweep`

- **When:** the same change or question across projects
- **Steps:** 1 enumerate targets with a shell glob, not a memory<br>- 2 classify each; an archive project is skipped, not processed<br>- 3 one card per project, parents=[sweep]<br>- 4 collect one line per project: what changed / what was refused / what is unfindable
- **Verification:** the per-project line carries the command it ran; the sweep report states its own coverage (n of m projects, and names the skipped ones)
- **Profiles:** default
- **Role:** synthesis

### P12 - `goblin-eval`

- **When:** a skill or prompt changed, and you want to know if it did anything
- **Steps:** 1 candidate and control run in sanitized directories<br>- 2 no eval/test/judge/rubric token anywhere the candidate sees<br>- 3 grade the chain from the transcript (which files it actually opened), never self-report<br>- 4 the judge runs on a different model family<br>- 5 write the record to `evals/<slug>/` (prompt, rubric, manifest.tsv, transcripts/, verdict.md)<br>- 6 a change must improve the evaluated cases or add new evaluations; a generated verification skill passes only on a measured sensitivity
- **Verification:** the judge's verdict is reproducible from the transcripts; candidates never learn other candidates exist; the record exists and every lane names a transcript file that exists; a generated verification skill is verified only by a record, with its sensitivity printed beside the control's number
- **Profiles:** researcher
- **Role:** synthesis

### P13 - `goblin-bugreporter`

- **When:** an event delivered a report — a bug report file, a chat message turned into one, a webhook
- **Steps:** 1 validate intake (the six required keys; a missing key is a refusal card with no assignee)<br>- 2 freeze `repo` + `revision` as immutable<br>- 3 reproduce (R1 a failing command, then R2 the REPLAY, then R3 a real-UI drive)<br>- 4 write `reports/<slug>/repro.md` with the `pre`/`post` table<br>- 5 create the fix card only on `reproduced`<br>- 6 complete its own card with the verdict
- **Verification:** `repro.md` carries a command, a revision that exists in `git rev-list`, and a RED `pre` row; the fix card exists iff the verdict is `reproduced`; `git status --porcelain` is empty after the run
- **Profiles:** researcher
- **Role:** investigate

### P14 - `goblin-drift-audit`

- **When:** a recorded claim disagrees with the artifact (drift)
- **Steps:** 1 enumerate targets by glob, never by memory<br>- 2 compute the drift record per target<br>- 3 print nothing when clean<br>- 4 one card per drifting repo<br>- 5 report `n of m`, naming the skipped targets
- **Verification:** the summary names each repo and the command it ran; a clean run prints nothing; skipped targets are named; a capped run prints its own line, so "silent because clean" and "silent because capped" are never confused
- **Profiles:** architect
- **Role:** judgment

**Why a 13th and 14th playbook, rather than folding these into P1/P9.** Every other playbook is
entered by a *human or orchestrator request* and delivers a *change*. These two are entered by an
*event* and deliver a *card*. `P10` covers "an unattended run over a predicate" — a run over a
*condition*, not a run *started by* a condition. Stretching P1 would lose the intake gate;
stretching P9 would lose the reproduce-first gate. The producers these cards came from were cut
in v3 (the `automations/` cron scripts); the two playbooks remain as the card-producing
procedures.

### P15 - `goblin-re-mobile`

- **When:** one shipped Android build must be understood as facts for study, with a reproducible, hash-manifested corpus
- **Steps:** 1 S0 preflight: the sandbox exists and is the one the fences describe<br>- 2 S1 acquire, S2 verify provenance against the published hash<br>- 3 S3 triage: the engine verdict, cheapest test first<br>- 4 S4 static decompile, S5 carve the containers, S6 manifest the corpus<br>- 5 S7 dossier: facts and numbers, never expression<br>- 6 S8 is deferred by design; S9 retention/teardown
- **Verification:** the corpus manifest verifies `sha256sum -c` where the corpus lives; `RC-01`, `RC-02` and `RC-03` return the exits their rows define (an exact hash inside the build output, a weak manifest and a tracked payload each fail the build); every negative control NC-1..NC-6 was shown RED and then restored
- **Profiles:** coder
- **Role:** code

**The step list above is the summary, not the procedure**, and the four `RC-` rows are what make
its verification column measurable rather than aspirational: `RC-01` is the build-time gate over
the declared `security: build_output:`, `RC-02` is the vacuous-pass guard on the manifest's own
shape, `RC-03` is the quarantine rule over the lab repo's tracked tree, and `RC-04` is the
acquisition record. The procedure's non-negotiable fences (an owned build only, one dedicated
sandbox, the quarantine, nothing extracted entering a repo) are stated with what enforces each.

### The cuts - pstack ships 23, this ships 15

Each cut has a reason, and a cut is recorded rather than deleted silently.

| cut | verdict | reason |
|---|---|---|
| `perf-issue` | folded into P2 | Its mechanism is "baseline trace, post-fix trace, diff the artifacts" - a step of a bug fix, not a playbook. No project here has a perf-target loop. |
| `hillclimb` | cut, deferred | Needs a frozen harness with proven sensitivity plus a loop primitive; the kanban's `goal_mode` already provides re-entry with a budget cap. |
| `runtime-forensics`, `trace-forensics` | merged into P2 | The transferable step is "capture a real artifact, then inject instrumentation into the running process". The library already ships the runners (`node-inspect-debugger`, `python-debugpy`), so a playbook would restate an existing skill. |
| `prototype` | merged into P1 step 3 | The valuable half is the classifier: a question whose answer is observable by running something is not the human's to answer. |
| `visual-parity` | cut | Needs a baseline screenshot harness; no project has a pixel-parity migration target. |
| `authoring-a-skill` | cut | `hermes-agent-skill-authoring` is live in the global library and is a Hermes-native duplicate. |
| `autopilot-stack` | cut | Nothing to stack: measured 0 branches and 0 PR merges across the repos this was designed for. |
| `autopilot-full`, `orchestrate` | merged into P10 + P11 + kanban | The fleet-programme half is the board's job (`parents`, `goal_mode`, `request_review`). The patch-id rule they contain is kept as PG-03. |
| `multi-phase-plan` | merged into P3 + P8 | The standard already owns the SPEC lifecycle; duplicating it violates the one-owner rule. The machine-checkable half is kept as SP-01/02/03. |
| `worktree-cleanup` | cut | macOS/Xcode-specific by inspection (`xcrun simctl`, `DerivedData`). |
| `opening-a-pr` | merged into P7 | It is the terminal step of every other playbook; as its own playbook it would be a step file with one caller. Its PR-body schema becomes P7's review-note schema. |

**Deliberate non-imports:** the `swarm` and `arena` fan-out shapes (the axis is read-vs-write,
and five parallel lanes cost about five times the tokens), the cloud-agent lane (no per-agent
computer here), and the Slack automation lane (the *shape* transfers, and P11 plus cron is
that shape).

---

## 18. Integration points

### The kanban board

The board is the fleet's fan-out carrier and the only one with a model knob.

- `goblin-overnight` (P10) maps to `goal_mode: true` plus a turn budget. **Corrected 2026-09-25
  (W3), measured in `hermes_cli/goals.py`:** the truth was weaker than this line claimed. The
  auxiliary judge is called as `judge_goal(goal_text, last_response)` (`:1662`) — two positional
  arguments and nothing else: **no contract, no subgoals, no quality gates** (the function takes all
  three; this call site passes none), so it is not "the predicate re-check"; what it sees is the card's
  goal text (truncated to 2000 chars) and the worker's own most recent response (truncated to
  4000) (`:39`, `:904-905`). The judge is an auxiliary model call at `temperature=0` (`:858-863`)
  and the loop's whole state is `last_response`, `turns_used` and `nudged_to_finalize` — **there is
  no progress detector at all** (`:1636-1638`). `wait` is downgraded to `continue` in a kanban loop
  (`:1666-1667`), a judged-done worker that never finalises is nudged once and then **blocked**
  (`:1676-1685`), and the budget (`DEFAULT_MAX_TURNS = 20`) is checked before each further turn
  (`:1689-1696`). The terminal handoff gate is judged on the supplied summary
  text and **allows the handoff when the judge breaks** (`tools/kanban_tools.py:414-424`,
  `:447-477`).
- `goblin-pr-gate` (P7) maps to the board's review request and change-request verbs. The
  verdict's `{head_sha, base_sha, patch_id, lanes, verdict}` lives in the card metadata **and**
  in the committed `reviews/<slug>-<head7>.md`. The card is the routing record; the file is the
  artifact the verifier can test (`PG-01`/`PG-02`/`PG-03`).
- `goblin-sweep` (P11) is one card per project, parented to the sweep card.

**Rule:** role-pinned fan-out goes through the board, never through a bare subagent spawn.

### Cron

`goblin-sweep` is the cron-shaped playbook: enumerate by glob, one card per project, one line
back.

Measured constraint to state plainly: a non-interactive surface inherits the skills **trust**
decision and resolves the project root from the job's `workdir`. So **a sweep job whose `workdir`
is not inside a trusted repo loads none of gobstack's skills.** The installer prints the
`hermes skills trust` step, and `goblin-verify` cannot check it (it is a fleet-runtime property).

The answer to a lost bootstrap is the same as the answer to compaction: the mode skill is
loadable on demand and `AGENTS.md` names it, so recovery is reading one file rather than
depending on a hook. On this runtime `on_session_start` exists and cannot inject (its
return is discarded — it is an observer), and `pre_llm_call` can inject into the user
message; gobstack uses neither as its bootstrap, because recovery-by-reading-one-file
is strictly more robust than a hook that six of the seven platforms do not have.

### Skills, and the precedence that decides which copy wins

gobstack **ships** skills and the installer **installs them into the project** at
`.hermes/skills/` — never into a profile.

Measured mechanism: the project tier is the highest precedence (`project → local → external`),
project dirs are treated as repo-owned so autonomous skill maintenance never rewrites them, the
code and its procedure are versioned together, and they need one `hermes skills trust` per repo.

Consequence a future agent must know rather than guess: **for a repo with gobstack
installed, the copy in `.hermes/skills/` wins.** Profiles keep only skills that are genuinely
cross-project. A shared library directory remains available in Hermes for a future shared
library, but it is deliberately unused here: it is read-only to maintenance as well, yet it is
*not* repo-versioned, and that is the property that matters.

### The fleet's routing text — what gobstack ships and cannot fix

gobstack **does not edit the fleet's orchestrator constitution and cannot**: it writes
nothing outside its target repo.

It ships the corrected routing text here, as an escalation, because the measured defect is
high-cost and lives on the fleet side: the rule deciding *whether specialist work happens at
all* is **false where the orchestrator reads it first**. A bare subagent spawn cannot reach the
architect/coder/reviewer profiles; delegation that must land there goes through the board. The
orchestrator's own text says the opposite in its first lines, and the word "kanban" does not
appear there.

The one mechanical thing gobstack can do is lint its own artifacts: a source test that no shipped skill tells a worker to reach another profile with a bare subagent spawn.

### The referenced standard

Referenced and hash-pinned, never moved, never superseded, never vendored. The `AGENTS.md` gob block
carries `practice:` and `practice_sha256:`; `goblin-verify` compares. The `practice` skill's body
is a pointer and a mandate — read the standard at the configured path before starting work; if
the path is absent, say so and continue with the gobstack rules alone.

An edit to the standard that **is** intended is re-recorded with one explicit command,
`goblin-install --target <dir> --re-pin`, which rewrites that one config line and prints the old
and new hash; nothing re-pins automatically, because a self-updating pin would be the silent edit
it exists to catch (`docs/GUIDE.md`, "An edited standard is not a dead end").

Three existing consumers of that standard have its path baked in, and gobstack is not one of
them: it reads the path from config, so moving the standard is a one-line config change.

---

## Appendix — a 45-minute first run, on one page

    # 0. get it
    npx @techgoblin/gobstack init          # or: npm i -g @techgoblin/gobstack

    # 1. try it somewhere disposable
    mkdir -p /tmp/gs-try && cd /tmp/gs-try
    git init -b main
    gob init --heuristic                   # the brief + schema; answer it in a proposal file
    gob init --write .gob-init-proposal.md --yes
                                           # expect: created 19 (no skills — those are opt-in)

    # 2. commit and check
    git add -A && git commit -m "chore: install gobstack"
    .gob/bin/goblin-verify                 # expect: mostly PASS, some SKIP

    # 3. make it yours
    $EDITOR AGENTS.md               # YOUR real gate commands (the gob block)

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
