# Framework-agnostic audit of the gob rule set — 2026-11-25

One question drove this pass: **does every row state a rule that is true regardless of framework,
and does every skip prove what it could not see?** The answer at `9d277e3` was: 44 rows were
neutral and fine, 9 were neutral rules gated on an ecosystem, 6 stated framework mechanics
outright, and 4 could go green without inspecting anything. This document is the record of what
was removed, what was fixed, and how to bring any of it back.

## Method

- Scope: all 63 target rows at `origin/main` `9d277e3` — 31 enforcement (`manifest/enforcement.tsv`)
  + 32 library (`manifest/library.tsv`), plus their engine surface in `bin/goblin-verify` (2456
  lines at that revision).
- Every row's STATEMENT (the `rule` cell) was read apart from its GATE (the `check` cell and the
  engine function behind it). A row is framework-bound if its statement names mechanics another
  repo in the fleet cannot even have; it is a silent blind spot if its gate can print PASS while
  inspecting zero items.
- Empirical baseline: the kit was installed (`goblin-install --yes`) into a Godot repo
  (`project.godot` + `.gd`), a Python repo (`pyproject.toml` + `.py`) and a docs-only repo, and
  the full verify was run in each. Baseline at `9d277e3`: **20 PASS / 0 FAIL / 11 SKIP on every
  shape** — including the defects below, which is exactly the problem.

## The four classes

| Class | Count | Meaning | Rows |
|---|---|---|---|
| A — neutral | 44 | statement and gate are framework-agnostic as they stand | — |
| B — neutral rule, ecosystem gate | 9 | rule is universal, but it can only observe one ecosystem | BN-01, BN-02, BN-03, BN-05, HV-01, SC-02, SC-06, RC-02, RC-04 |
| C — framework-bound statement | 6 | the statement itself names another framework's mechanics | BN-06, BN-07, BN-08, BN-09, HV-02, SC-09 |
| D — silent blind spot | 4 | the gate printed PASS after inspecting nothing | SC-03, SC-04, SC-05, HS-02 |

## D — the silent blind spots, and the fix

The standing rule after this audit: **if a check inspected zero items, it returns SKIP(3) with a
reason naming what it could not see — never PASS, never a vacuous "every …".** Each fix keeps the
rule text and changes only the gate. Every line below was reproduced before the fix.

- **`SC-03`** — reproduced: `PASS  SC-03  0 client-visible secret-shaped name(s); no build output
  to scan for clause 2`. Now: no JS-family source file and no declared build output → SKIP
  (`no file in the JS-family set and no declared build output to scan`); PASS requires at least
  one examined artifact; the deliberate-PASS-inside-a-scanned-file behaviour is kept.
- **`SC-04`** — reproduced: `PASS  SC-04  0 cookie write(s) checked; …`. Now: zero cookie writes
  examined → SKIP (`no cookie write found in N examined file(s)`); a Python
  `response.set_cookie` gets the named skip, not a green.
- **`SC-05`** — reproduced: `PASS  SC-05  0 write handler(s), 0 waived; 11 dir(s) declared`. Now:
  undeclared `security.write_routes` → SKIP (`security.write_routes is not declared - there is no
  route surface to check`); declared but nothing matched → SKIP naming the declaration and the
  0 matches. This was already the file's own contract (goblin-verify: "a declared key that is
  absent is a skip with a reason, never a silent pass").
- **`HS-02`** — reproduced, zero `checks/*.mjs` with `replay.commit` pinned:
  `PASS  HS-02  every harness was RED at <sha>` with zero harnesses replayed. Now: zero replayed
  → SKIP (`no harness in <dir> matched the replay set`); ≥1 keeps the RED-proof semantics and
  names how many were replayed and the extension set; files the replay set does not run are
  listed in a `not replayed:` tail (the excluded extensions are named, not graded).

Loose finding fixed alongside: **`HV-01` false-RED** — the gate only recognised `pkg`/`require(`/`import(`
syntax, so a non-JS harness file was accused instead of skipped. Now: a harness directory whose
only files are not JS-family → SKIP (`no JS-family harness file in <dir> - the text probe reads
import/require syntax it cannot see in other languages`).

### Second defect, found reviewing the fixes (2026-11-25)

The SC-03/SC-04 zero-inspection gate counted the kit's OWN scaffold. `js_source_count` — the
"examined" denominator both rows skip on — excluded the build and dependency directories but not
the declared harness directory, so on a fresh Python install the one JS-family file it found was
the `checks/assert.mjs` file `goblin-install` itself had written. Measured, same repo, no
application JS anywhere:

    PASS  SC-03  0 client-visible secret-shaped name(s); no build output to scan for clause 2

Move that one scaffold file away and the same row answers:

    SKIP  SC-03  no file in the JS-family set and no declared build output to scan

The PASS came from grading the kit's scaffold — the exact pathology class D accused `HV-02` of.
`SC-04` shared the counter and printed it: `no cookie write found in 1 examined file(s)`, where
the 1 was the kit's own file. Fix: the harness directory (`AGENTS.md` `harness_dir:`, the
installer's default `checks/`) is excluded from the JS-family set that decides whether the row
examined anything. Clause semantics and messages are unchanged; a repo whose only JS-family file
is the harness is now told so (the SKIP above), and a repo with real application sources still
PASSes. Re-measured on the same Python fixture: `SKIP  SC-03  no file in the JS-family set and
no declared build output to scan`, `SKIP  SC-04  no cookie write found in 0 examined file(s)`.

## C — the withdrawn rows

A statement the fleet cannot grade is noise at best and a false green at worst: on every shape
without the framework it graded nothing and printed PASS. Withdrawn 2026-11-25:

| Row | Statement | Where it went |
|---|---|---|
| `BN-06` | No renderer has `nodeIntegration: true` | Electron-only; resurrect as an Electron project's local ban (below) |
| `BN-07` | Renderer context is `contextIsolation: true` + `sandbox: true` | same |
| `BN-08` | No remote content loaded without `webPreferences` review | same |
| `BN-09` | No `ipcRenderer.sendSync` / `@electron/remote` in the renderer | same |
| `HV-02` | A number taken from a live surface carries its viewport guard (`getBoundingClientRect` + Node child-process) | web-automation surface of one project; on other shapes it graded the kit's own scaffold. Resurrect as that project's local check |
| `SC-09` | Auth is applied consistently across sibling routes | "sibling routes" is web routing; was advisory prose with no check at all. Resurrect as a web project's local advisory row |

Mechanics of the withdrawal: rows deleted from `manifest/enforcement.tsv` / `library.tsv`;
the four Electron `bans.tsv` rows removed with `BN-00` recomputed (`BN-00` still holds: every ban
has an enforcement row and a named replacement); `check_hv_02` and its helpers deleted from
`bin/goblin-verify`; the rows' controls deleted from the suites. `--only BN-06` / `--only HV-02` /
`--only SC-09` on a fresh install now report: *names id(s) in neither the manifest, the library
nor the local override* (exit 2).

### How to resurrect a withdrawn row

1. Copy the rule text from the table above into the project's own row set — a project-local
   `manifest/enforcement.local.tsv` row, or a ban in the project's `bans.tsv` — never back into
   the shipped manifests.
2. Write the gate against the framework's own parser (Electron: `electron/main.js` prefs; browser
   automation: the project's own harness), not against a text probe that other shapes cannot see.
3. Prove the skip first: a fixture without the framework must get SKIP(3) with a reason before
   the RED is trusted. A row that cannot prove its skip is a C row, whatever it claims.
4. Record the resurrection in the project's own CHANGELOG, not this kit's.

## B — the ecosystem-gated rows, and their skip proofs

Each B row now names its ecosystem explicitly: an `ecosystem:<name>` token in the artifact cell
of the manifest. And each has a control proving that a fixture of ANOTHER shape gets SKIP(3)
with a reason — never a PASS graded on nothing, never a FAIL (the fixtures live in
`tests/t-verify-red.sh` under "the ecosystem-gate half of the B rows"):

| Row | Ecosystem token | Skip proof (foreign-shape fixture) |
|---|---|---|
| `BN-01` | `ecosystem:typescript` | `SKIP  BN-01` — a typescript ban over a tree with no typescript source |
| `BN-02` | `ecosystem:typescript` | same gate, no-op mutation on the TS-free base tree |
| `BN-03` | `ecosystem:typescript` | same gate |
| `BN-05` | `ecosystem:typescript` | same gate |
| `HV-01` | `ecosystem:javascript-harness` | a harness dir whose only file is not JS-family → SKIP naming the language limitation |
| `SC-02` | `ecosystem:node` | the secret surface with no ignore/dependency surface (`.gitignore` removed) → SKIP |
| `SC-06` | `ecosystem:node` | no `package.json` to read → SKIP |
| `RC-02` | `ecosystem:goblin-reference` | reference corpus absent from a foreign shape → SKIP |
| `RC-04` | `ecosystem:goblin-reference` | same gate |

A measured skip line from a fresh docs-only install:

    SKIP  BN-01  No `any` in application TypeScript. (not applicable: no file matches applies_when: **/*.ts **/*.tsx ...)

## Empirical baseline after the curation

Fresh `goblin-install --yes` + full verify, measured 2026-11-25/26 on the post-curation tree:

| Shape | Result |
|---|---|
| Godot (`project.godot` + `.gd`) | `19 passed, 0 failed, 0 advisory, 7 skipped` |
| Python (`pyproject.toml` + `.py`) | `19 passed, 0 failed, 0 advisory, 7 skipped` |
| docs-only (`README.md`) | `19 passed, 0 failed, 0 advisory, 7 skipped` |

The seven skips are: `AG-01` (no approval record yet), `BN-01`/`BN-02`/`BN-03`/`BN-05`
(applies_when GLOB matches no source — not applicable), and `FM-01`/`FM-02` (no feature map yet).
The library count in the summary is `32 off-by-default row(s)` (SC-09 out, PV-01 in).

## The standing rule

**Framework-agnostic only.** A row in this kit states a rule that is true for every repo the
fleet can contain, and its gate proves what it could and could not see. Framework mechanics live
in the project's local rows and skill, where the framework is a given and a parser exists.

## Loose findings

- `HV-01` false-RED on non-JS harness files — fixed (see D above).
- `docs/GUIDE.md` §439 claimed the guide "names which rows" pass vacuously, but no such list
  existed anywhere in the guide — the guide's vacuous-pass section now carries the real list.
