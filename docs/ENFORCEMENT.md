# Enforcement matrix

`manifest/enforcement.tsv` is the matrix: **one row per rule**. The `check` column holds a
real command that `goblin-verify` runs, or the literal `advisory`, or the marker
`goblin-verify --only <ID>` for a check that needs more than one shell line (those are
builtins in `bin/goblin-verify`, so the row stays self-describing and the matrix stays the
single source of truth).

`scope` is `target` (runs in an installed repo via `goblin-verify`) or `source` (runs in
this repo via `tests/run-tests.sh`). `enforced_by` is one of four values, and the enum is
closed: `script`, `lint`, `gate`, `advisory`.

Measured shape of this table: **46 rows** - 42 target, 4 source; advisory 8, gate 13, lint 9, script 13, test 3.

## The rows

| id | scope | enforced by | rule | check | if it cannot be enforced, why |
|---|---|---|---|---|---|
| `IN-01` | target | script | The install exists and records its version + every file's hash. | `test -s .goblin/installed.json && grep -q '"version"' .goblin/installed.json` | — |
| `IN-02` | target | script | Every installed file still matches its recorded hash. | `goblin-verify --only IN-02` (builtin) | — |
| `IN-03` | target | script | The verifier's own manifest is complete: every rule has a check or is advisory. | `awk -F'\t' 'NR>1 && ($6=="" \|\| ($6=="advisory" && $4!="advisory")) {n++} END{exit n>0}' .goblin/manifest/enforcement.tsv` | — (this row is the reason the matrix cannot rot; the second clause is D6's shape in general: a row that carries no check must be labelled advisory, or it claims verification it does not perform) |
| `IN-04` | target | script | No file goblin-stack did not create has been overwritten. | `goblin-verify --only IN-04` (builtin) | Detects a file the installer recorded as pre-existing (a `refused` entry) that has since vanished, or that is listed as installed anyway. The second clause is an internal-consistency guard: with correct code a refused path is never written, so it fires only if the installer regresses. The negative control exercises the vanished branch. |
| `HP-01` | target | gate | HANDOFF.md exists at the root. | `test -f HANDOFF.md` | — |
| `HP-02` | target | lint | The HANDOFF carries its five required sections. | `for h in 'START HERE' 'STATE\|STATUS' 'GATES?' 'NEXT STEPS\|NEXT' 'NOT VERIFIED\|UNVERIFIED\|NOT PROVEN\|UNPROVEN\|PENDING[^.]*DEVICE TEST'; do grep -qiE "^#{2,3}[[:space:]]+[^[:alpha:]]*($h)\b" HANDOFF.md \|\| { echo "missing section: $h"; exit 1; }; done` | Partial: proves a heading exists whose first word names the slot, not that the section's content is complete. The slot may use the repo's own vocabulary (the model repo's `### NEXT` passes; `Status`, `Gate`, `Unverified`, `Pending <x> device test` are accepted); a heading that merely contains the word (`## BOARD STATE`) does not satisfy `State`. |
| `HP-03` | target | lint | Every gate number is a measurement with a date, never a copy. | `awk 'BEGIN{bad=0;n=0} tolower($0) ~ /^#{2,3}[[:space:]]+[^[:alpha:]]*gates?([^[:alpha:]]\|$)/ {g=1;next} g && /^#{1,3}[[:space:]]/ {g=0} g && /(tsc\|build\|hex\|safelist\|[0-9]+\/[0-9]+)[^=]*=/ {n++; if ($0 !~ /measured [0-9]{4}-[0-9]{2}-[0-9]{2}/) {print; bad=1}} END {if (n==0) {print "no gate line inside the Gates section"; bad=1} exit bad}' HANDOFF.md` | Partial: proves every gate-bearing line inside the `Gates` section carries a date, not that the number was re-measured that day. Historical gate lines outside that section are exempt by design - PROJECT-PRACTICE section 1's stale-sentence rule requires them to be kept. |
| `HP-04` | target | advisory | A stale sentence is corrected in place with a dated parenthetical, never deleted. | `advisory` | Detecting a silent deletion needs semantic judgement; a diff heuristic (>=5 removed non-empty lines with no 'corrected' addition) is too noisy to gate on. goblin-verify --only HP-04 prints the heuristic as a warning only. |
| `HP-05` | target | gate | The HANDOFF names the HEAD it describes. | `goblin-verify --only HP-05` (builtin) | Deviation from the design spec, with the reason: the spec's literal check is `grep -q "$(git rev-parse --short HEAD)" HANDOFF.md`, which can never pass - committing the HANDOFF moves HEAD, so the file can only name a commit that is now an ancestor. The mechanised form is therefore 'the HANDOFF names a commit that exists in this repo AND is an ancestor of HEAD', which still catches the defect it exists for (a review/handoff artifact that names no commit at all). |
| `SP-01` | target | gate | The current round has a SPEC. | `ls ./*-SPEC.md >/dev/null 2>&1` | Skipped when class: D and disabled: [spec]. |
| `SP-02` | target | script | The SPEC is committed, not left untracked. | `test -z "$(git ls-files --others --exclude-standard -- '*-SPEC.md')"` | — |
| `SP-03` | target | lint | Every AC: item is checkable without a human. | `awk '/^[[:space:]]*[-*][[:space:]]/ && /AC[0-9]*:/ && !/\|==\|===\|exit\|<\|>/ {print; bad=1} END{exit bad}' ./*-SPEC.md` | Partial: structural only - a checkable-looking bullet can still be unfalsifiable. The matcher is `AC[0-9]*:` because the shipped template writes `- AC1: ...`; the literal `/AC:/` only saw a bullet that spelled the label without a number. |
| `GT-01` | target | gate | The gate set is declared, never inferred from the stack. | `goblin-verify --only GT-01` (builtin) | — |
| `GT-02` | target | gate | Every declared gate runs and exits 0. | `goblin-verify --only GT-02` (builtin) | — |
| `GT-03` | target | script | The round reports one line of measured numbers. | `test -f .goblin/last-gate-line && [ .goblin/last-gate-line -nt "$(git rev-parse --git-dir)/HEAD" ]` | — |
| `GT-04` | target | gate | A ratchet is declared with a ceiling. | `goblin-verify --only GT-04` (builtin) | — |
| `GT-05` | target | gate | The ratchet has not risen. | `goblin-verify --only GT-05` (builtin) | — |
| `HS-01` | target | lint | Asserting harnesses follow the house shape. | `goblin-verify --only HS-01` (builtin) | A declared harness_dir that is absent FAILS when the class scaffolds one (config `scaffold_checks: yes`, classes A and C); a class that ships no harness dir (B/D/E) SKIPs with a reason. Keying the skip off the path alone let one config line switch this row and HS-02 off. A report utility in the same dir is counted and reported separately rather than failing the run. |
| `HS-02` | target | gate | A check green on both trees proves nothing - the REPLAY must show RED pre-change. | `goblin-verify --only HS-02` (builtin) | — |
| `HS-03` | target | advisory | Source probes read text with comments blanked first. | `advisory` | Recognising 'this probe reads source text' is semantic; a grep for the blanking helper produces false FAILs on harnesses that do not probe source. |
| `CM-01` | target | gate | Commits carry the owner identity, not an ambient one. | `test "$(git log -1 --format='%ae')" = "$(grep '^owner_email:' .goblin/goblin.yaml \| cut -d' ' -f2)"` | — |
| `CM-02` | target | advisory | The commit message was written to a file, not passed with -m. | `advisory` | A backtick lost to command substitution leaves no trace a later check can read. Reported as a heuristic (unbalanced backticks in a body) only. |
| `CM-03` | target | script | Commit-as-you-go: the working tree is not carrying a dead run's work. | `goblin-verify --only CM-03` (builtin) | — |
| `MD-01` | target | lint | No model name is hardcoded in any reusable rule. | `for d in skills manifest bin templates presets .goblin .hermes; do [ -d "$d" ] \|\| continue; grep -rniE '(d[e]epseek\|cl[a]ude\|g[p]t-[0-9]\|gr[o]k\|g[e]mini\|g[l]m-[0-9]\|k[i]mi)[a-z0-9.:_-]*' "$d" && exit 1; done; exit 0` | — (the pattern is written with character classes so this row cannot match itself; tests/t-verify-red.sh proves it still catches a real model name) |
| `MD-02` | target | advisory | The review lane is a different model family from the code lane. | `goblin-verify --only MD-02` (builtin) | goblin-stack cannot choose the fleet's models; today's map resolves both roles to the same family. Reported as ADV, never gated. |
| `MD-03` | target | advisory | Role-pinned fan-out goes through kanban, not a model-less subagent spawn. | `advisory` | It is a fleet-runtime property: no repo-local file can observe which tool created a worker. Enforced at board level, described in docs/INTEGRATION.md. |
| `PG-01` | target | gate | The reviewed artifact is named by SHA, and that SHA exists. | `goblin-verify --only PG-01` (builtin) | — |
| `PG-02` | target | script | The gate is chosen by the change, not the repo, and the tier's evidence exists. | `goblin-verify --only PG-02` (builtin) | — |
| `PG-03` | target | gate | A new head voids the verdict. | `goblin-verify --only PG-03` (builtin) | — |
| `PG-04` | target | advisory | Never bypass what the forge enforces. | `advisory` | Needs the forge: GitHub's restrictions do not apply to admins, and a sole-admin repo has nobody the gate binds. Not observable from the repo. |
| `PG-05` | target | lint | No required check that self-skips. | `goblin-verify --only PG-05` (builtin) | Heuristic: 'all steps guarded' is textual. |
| `DS-01` | target | script | Runtime data is not test fixture: a gate run must not write it. | `goblin-verify --only DS-01` (builtin) | — |
| `DS-02` | target | gate | Snapshot before, verify after. | `goblin-verify --only DS-02` (builtin) | — |
| `DOC-01` | target | advisory | A significant change updates the docs that teach it. | `advisory` | 'Significant' is a judgement; a diff-size heuristic fails on the cases that matter. |
| `DOC-02` | target | advisory | System-level changes are recorded in the vault via the pkm profile. | `advisory` | Vault writes route through another profile by a stricter rule than goblin-stack may add; the repo can only state it. |
| `SK-01` | target | lint | Every shipped skill has name + description frontmatter. | `for f in .hermes/skills/*/SKILL.md; do [ -e "$f" ] \|\| continue; head -n 1 "$f" \| grep -qx -- '---' \|\| exit 1; awk 'NR==1{next} /^---/{exit} /^name:/{n=1} /^description:/{d=1} END{exit !(n&&d)}' "$f" \|\| exit 1; done` | — |
| `SK-02` | target | script | The installed skills match their recorded hashes (no drift). | `goblin-verify --only SK-02` (builtin) | — |
| `SK-03` | target | script | A rule with no mechanism is labelled advisory, and the advisory count is reported. | `goblin-verify --only SK-03` (builtin) | — |
| `PT-01` | target | lint | No tenant-specific string inside a reusable rule. | `for d in skills manifest bin templates presets .goblin .hermes; do [ -d "$d" ] \|\| continue; grep -rniE --exclude=goblin.yaml '(h[a]rvey\|tech-g[o]blin\|/h[o]me/[a-z]+\|g[o]blin-ui\|op[e]n-door\|sup[r]eme\|bb[t]ech\|c[l]v)' "$d" && exit 1; done; exit 0` | — (the same directory list MD-01 uses: the rules an install actually writes live in `.goblin/` and `.hermes/`, not in the source layout. The one documented exception is `.goblin/goblin.yaml`, which holds `models_file:`/`practice:` - per-machine config, not a rule - and is excluded by name. The pattern is written with character classes so this row cannot match itself.) |
| `PT-02` | target | gate | The default branch is declared, not assumed. | `goblin-verify --only PT-02` (builtin) | — |
| `CL-01` | target | script | Every part the class requires is present, and every part it forbids is absent. | `goblin-verify --only CL-01` (builtin) | — |
| `CL-02` | target | script | An archive: true project verifies GREEN without a HANDOFF or gates. | `goblin-verify --only CL-02` (builtin) | Falsifiable: FAILs when `archive:` is not `true`/`false`, and when the config's value disagrees with the one the install recorded in `.goblin/installed.json` (so the waiver cannot be flipped on by hand). It cannot observe the *effect* of the waiver on the other rows without re-entering the runner. |
| `PR-01` | source | test | The installer never writes outside its target. | `tests/run-tests.sh` | — |
| `PR-02` | source | test | A second install is a no-op, and an upgrade reports created/updated/unchanged. | `tests/run-tests.sh` | — |
| `PR-03` | source | test | Every target-scope check goes RED under its own violation. | `tests/run-tests.sh` | — (the negative control the verifier re-runs) |
| `PR-04` | source | lint | The repo is portable: no personal path in any reusable rule. | `tests/run-tests.sh (the PT-01 body over the source tree, plus tests/)` | — |

## Advisory rows, named

8 of the 46 rows are labelled `advisory`. 7 carry no executable check at all
(they are prose the matrix refuses to pretend about); 1 are advisory-labelled but still
report their state.

- **HP-04** (no check at all) - A stale sentence is corrected in place with a dated parenthetical, never deleted.
- **HS-03** (no check at all) - Source probes read text with comments blanked first.
- **CM-02** (no check at all) - The commit message was written to a file, not passed with -m.
- **MD-02** (reports state as ADV) - The review lane is a different model family from the code lane.
- **MD-03** (no check at all) - Role-pinned fan-out goes through kanban, not a model-less subagent spawn.
- **PG-04** (no check at all) - Never bypass what the forge enforces.
- **DOC-01** (no check at all) - A significant change updates the docs that teach it.
- **DOC-02** (no check at all) - System-level changes are recorded in the vault via the pkm profile.

`advisory_ceiling` (default 10) caps that count: **SK-03 fails the run when the advisory
count exceeds it.** The number of unenforceable rules is itself a gate. Measured now:
`advisory 8 of ceiling 10`.

## The class matrix

`manifest/classes.tsv` is the same idea applied to the parts a project must have.
`R` = required, `O` = optional (installed, reported), `-` = off, and **off is enforced**:
the installer records every `-` part in `disabled:`, so its rows report `SKIP (opt-out)`
instead of silently passing, and `CL-01` fails if a forbidden part's artifact exists.

| part | A | B | C | D | E |
|---|---|---|---|---|---|
| handoff | R | R | R | R | R |
| spec | R | R | R | - | R |
| gate | R | R | R | O | R |
| replay | R | - | R | - | O |
| ratchet | R | O | O | - | O |
| pr-gate | O | - | O | - | O |
| review-panel | O | - | R | - | O |
| playbooks | R | R | R | R | R |
| tokens | O | - | - | - | - |

## How a rule is added

A rule enters only by adding a row. If the author cannot write a command, the row's `check`
is `advisory` and the rule's cost is visible in the summary line. There is no third option,
and `IN-03` plus `SK-03` are what make that true: a row with neither a command nor the
`advisory` label fails the manifest before any check runs (exit 3), and the advisory count
fails the run when it exceeds the ceiling.

## What the matrix cannot do

A counted rule is still not an enforced one. The cap is a policy, not a proof, and seven of
these rows are prose. That is stated here rather than implied away.

