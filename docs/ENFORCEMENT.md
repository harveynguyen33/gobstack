# Enforcement matrix

`manifest/enforcement.tsv` is the matrix: **one row per rule**. The `check` column holds a
real command that `goblin-verify` runs, or the literal `advisory`, or the marker
`goblin-verify --only <ID>` for a check that needs more than one shell line (those are
builtins in `bin/goblin-verify`, so the row stays self-describing and the matrix stays the
single source of truth).

`scope` is `target` (runs in an installed repo via `goblin-verify`) or `source` (runs in
this repo via `tests/run-tests.sh`). `enforced_by` is one of four values, and the enum is
closed: `script`, `lint`, `gate`, `advisory`.

Measured shape of this table: **62 rows** - 57 target, 5 source; advisory 9, gate 19, lint 16, script 14, test 4.

## The rows

| id | scope | enforced by | rule | check | if it cannot be enforced, why |
|---|---|---|---|---|---|
| `IN-01` | target | script | The install exists and records its version + every file's hash. | `test -s .goblin/installed.json && grep -q '"version"' .goblin/installed.json` | — |
| `IN-02` | target | script | Every installed file still matches its recorded hash. | `goblin-verify --only IN-02` (builtin) | — |
| `IN-03` | target | script | The verifier's own manifest is complete: every rule has a check or is advisory. | `awk -F'\t' 'NR>1 && ($6=="" \|\| ($6=="advisory" && $4!="advisory")) {n++} END{exit n>0}' .goblin/manifest/enforcement.tsv` | — (this row is the reason the matrix cannot rot; the second clause is D6's shape in general: a row that carries no check must be labelled advisory, or it claims verification it does not perform) |
| `IN-04` | target | script | No file goblin-stack did not create has been overwritten. | `goblin-verify --only IN-04` (builtin) | Detects a file the installer recorded as pre-existing (a `refused` entry) that has since vanished, or that is listed as installed anyway. The second clause is an internal-consistency guard: with correct code a refused path is never written, so it fires only if the installer regresses. The negative control exercises the vanished branch. |
| `HP-01` | target | gate | HANDOFF.md exists at the root. | `test -f HANDOFF.md` | — |
| `HP-02` | target | lint | The HANDOFF carries its five required sections. | `for h in 'START HERE' 'STATE\|STATUS' 'GATES?' 'NEXT STEPS\|NEXT' 'NOT VERIFIED\|UNVERIFIED\|NOT PROVEN\|UNPROVEN\|PENDING[^.]*DEVICE TEST'; do grep -qiE "^#{2,3}[[:space:]]+[^[:alpha:]]*($h)\b" HANDOFF.md \|\| { echo "missing section: $h"; exit 1; }; done` | Partial: proves a heading exists whose first word names the slot, not that the section's content is complete. The slot may use the repo's own vocabulary (the model repo's `### NEXT` passes; `Status`, `Gate`, `Unverified`, `Pending <x> device test` are accepted); a heading that merely contains the word (`## BOARD STATE`) does not satisfy `State`. |
| `HP-03` | target | lint | Every gate number is a measurement with a date, never a copy. | `goblin-verify --only HP-03` (builtin) | Builtin, anchored on the gate NAMES `.goblin/goblin.yaml` declares (GT-01's source of truth) rather than on a hardcoded keyword list: the shipped gates are named `commit` and `todo_ceiling`, neither of which the old list matched, so on a fresh install the only line it could see was the template's own example sentence, and a real gate line could lose its `date` and the row stayed GREEN (G8-2). A line whose text says "example of the required form" is template prose, not a gate number, and is skipped, so the template cannot satisfy the row. Partial: it proves a dated line inside the `Gates` section exists and that every gate-bearing line there carries a date - not that the number was re-measured that day, and not a gate-bearing line that names no declared gate and carries no gate-shaped keyword (so a line the config does not declare and the keyword list does not recognise is unseen). Historical gate lines outside that section are exempt by design - PROJECT-PRACTICE section 1's stale-sentence rule requires them to be kept. |
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
| `SK-04` | target | lint | Every shipped skill says what it cannot see. | `n=0; for f in .hermes/skills/*/SKILL.md; do [ -e "$f" ] \|\| continue; n=$((n+1)); grep -q "^## What this cannot see" "$f" \|\| { echo "missing cannot-see section: $f"; exit 1; }; done; [ "$n" -gt 0 ] \|\| { echo "no installed skill found"; exit 1; }; exit 0` | Partial: proves the section exists, not that what it says is complete or true - the limit every prose rule carries. Every shipped skill already carries it, so the row is GREEN on a fresh install and RED only under a real violation. |
| `PT-01` | target | lint | No tenant-specific string inside a reusable rule. | `for d in skills manifest bin templates presets .goblin .hermes; do [ -d "$d" ] \|\| continue; grep -rniE --exclude=goblin.yaml '(h[a]rvey\|tech-g[o]blin\|/h[o]me/[a-z]+\|g[o]blin-ui\|op[e]n-door\|sup[r]eme\|bb[t]ech\|c[l]v)' "$d" && exit 1; done; exit 0` | — (the same directory list MD-01 uses: the rules an install actually writes live in `.goblin/` and `.hermes/`, not in the source layout. The one documented exception is `.goblin/goblin.yaml`, which holds `models_file:`/`practice:` - per-machine config, not a rule - and is excluded by name. The pattern is written with character classes so this row cannot match itself.) |
| `PT-02` | target | gate | The default branch is declared, not assumed. | `goblin-verify --only PT-02` (builtin) | — |
| `CL-01` | target | script | Every part the class requires is present, and every part it forbids is absent. | `goblin-verify --only CL-01` (builtin) | — |
| `CL-02` | target | script | An archive: true project verifies GREEN without a HANDOFF or gates. | `goblin-verify --only CL-02` (builtin) | Falsifiable: FAILs when `archive:` is not `true`/`false`, and when the config's value disagrees with the one the install recorded in `.goblin/installed.json` (so the waiver cannot be flipped on by hand). It cannot observe the *effect* of the waiver on the other rows without re-entering the runner. |
| `SC-01` | target | lint | No secret file is tracked. | `n=$(git ls-files \| grep -iE '(^\|/)\.env\|\.pem$\|\.key$' \| grep -vcE '\.(example\|sample\|template)$'); printf '%s tracked secret file(s)\n' "$n"; [ "$n" = 0 ]` | Partial: it sees tracked PATHS, never contents - a secret pasted into a tracked file is invisible here, and the pattern is a name family, so a credential inside `config.ts` is missed by construction. |
| `SC-02` | target | gate | The ignore rules cover the whole secret family. | `goblin-verify --only SC-02` | Builtin, and behavioural: clause 1 reads `.gitignore`; clause 2 asks git's own matcher (`git check-ignore`) for `.env`, `.env.local` and `.env.production` one path at a time, so a rule that looks right but does not match still fails. It cannot see a secret already in git history, or one committed under a name the family does not cover. SKIPs with a reason when there is no `.gitignore` and no `package.json`. |
| `SC-03` | target | lint | No client-visible name is secret-shaped, and no build output carries a secret literal. | `goblin-verify --only SC-03` | Builtin, two clauses: the `NEXT_PUBLIC_*_(SECRET\|TOKEN\|KEY\|PASSWORD\|PRIVATE)` name pattern over source, and known secret prefixes over the declared build output. Partial: a prefix pattern cannot see a secret that does not look like one, and clause 2 says "no build output to scan" on the line rather than skipping silently. The source scan excludes `.goblin/` and `.hermes/`, so it cannot match the row text that describes it. |
| `SC-04` | target | lint | Every cookie write carries its flags. | `goblin-verify --only SC-04` | Builtin, same-statement only: a write spread over three lines is not seen, and the row says so. It REPORTS that a JS-written cookie is readable by any script rather than failing on it - that is a design fact, not a bug - so the pass is about the flags, never about the choice. |
| `SC-05` | target | gate | Every write route validates its input, or is waived. | `goblin-verify --only SC-05` | Builtin: it proves a validator is CALLED (`safeParse\|zod\|valibot\|yup\|ajv\|superstruct\|validate(`), never that the schema is right - a schema that accepts everything passes. `.goblin/boundary-waivers` is the escape hatch, and the waived count is printed, so a silent pile-up is visible. |
| `SC-06` | target | gate | A lockfile exists, and the repo tracks it. | `goblin-verify --only SC-06` | Builtin: presence, then `git ls-files --error-unmatch`. It cannot see that the lockfile is STALE relative to `package.json` - resolving that needs the package manager, which is a deliberate network-shaped step, not a check. SKIPs with a reason when there is no `package.json`. |
| `SC-07` | target | gate | The dependency audit record is present, dated, fresh, and clean-or-waived. | `goblin-verify --only SC-07` | Builtin, OFFLINE by construction: it reads the record and never the network. The record comes from `.goblin/bin/goblin-audit`, run once, deliberately; the waiver count is printed on the gate line so the debt is loud even when the row passes. It cannot see an advisory the registry did not know on the day the record was taken. SKIPs with a reason when no record exists yet. |
| `SC-08` | target | gate | No dependency runs an install-time script that is not on the allowlist. | `goblin-verify --only SC-08` | Builtin over `package-lock.json`'s `hasInstallScript`: a pnpm/yarn lockfile has no such field, so those repos get a SKIP with that reason rather than a vacuous pass. Lowest-value row of the ten - regression detection - and the first to cut if the matrix gets heavy. |
| `SC-09` | target | advisory | Auth is applied consistently across sibling routes. | `advisory` | Prose on purpose: "consistently" is a semantic judgement about a private surface no repo here has yet. Counted (9 of ceiling 10) so the matrix cannot quietly grow prose. |
| `PF-01` | target | lint | The perf baseline names the commit it measured. | `goblin-verify --only PF-01` | Builtin: the metric must equal `ratchet.name` so the budget and the measurement cannot silently disagree, the value must be numeric, the date must exist, and the baseline commit must exist AND be an ancestor of HEAD (`HP-05`'s mechanic, reused rather than re-derived). It cannot see whether the metric is the right one for the product, and it never re-measures: re-anchoring is a deliberate operator action. SKIPs with a reason when the class declares no metric, or none has been recorded yet. |
| `AU-01` | target | lint | An automation's producer is deterministic and network-free. | `n=0; for f in .goblin/automations/*.sh automations/*.sh automations/*/*.sh; do [ -e "$f" ] \|\| continue; n=$((n+1)); grep -nE "^[[:space:]]*(curl\|wget\|gh[[:space:]]\|npm[[:space:]]\|npx[[:space:]])" "$f" && exit 1; done; [ "$n" -gt 0 ] \|\| { echo "no automation producer found"; exit 1; }; exit 0` | Partial: proves that no line of an installed producer begins with a network or forge verb, not that the script is otherwise deterministic. A target with no producer FAILS rather than passing vacuously - goblin-install writes its own, so an absent producer means the install was tampered with (IN-02 catches that too). |
| `AU-02` | target | script | A report's dedup key is a function of content only - no date, no run id. | `goblin-verify --only AU-02` (builtin) | Builtin: it recomputes the key from the report's own `repo` and `symptom` and requires the recorded `dedup_key` to equal it, then refuses a key carrying a date. Skipped with a reason when the repo holds no report - nothing to dedup. It cannot see whether two reports should have been one: a normalisation that merges two genuinely different symptoms is a duplicate card, not a lost report. |
| `AU-03` | target | gate | A reporter run leaves the tree and the harness untouched. | `goblin-verify --only AU-03` (builtin) | Builtin: asserts a clean working tree, and - when HEAD is a reporter commit - that no path under the declared harness_dir appears in it. Skipped with a reason when the repo holds no reports/ - no reporter has run here. It cannot see a reporter that edited the tree and committed the edit as part of the report. |
| `AU-04` | target | lint | An automation's skill declares its own write surface. | `n=0; for f in .hermes/skills/goblin-bugreporter/SKILL.md .hermes/skills/goblin-drift-audit/SKILL.md; do [ -e "$f" ] \|\| continue; n=$((n+1)); grep -q "^## Write surface" "$f" \|\| { echo "missing write surface: $f"; exit 1; }; done; [ "$n" -gt 0 ] \|\| { echo "no automation skill found"; exit 1; }; exit 0` | Partial: proves the heading exists, not that the surface it names is the right one. The heading is the contract a human reads before trusting an automation; the mechanical half is AU-03, which asserts the surface was respected. |
| `PR-01` | source | test | The installer never writes outside its target. | `tests/run-tests.sh` | — |
| `PR-02` | source | test | A second install is a no-op, and an upgrade reports created/updated/unchanged. | `tests/run-tests.sh` | — |
| `PR-03` | source | test | Every target-scope check goes RED under its own violation. | `tests/run-tests.sh` | — (the negative control the verifier re-runs) |
| `PR-04` | source | lint | The repo is portable: no personal path in any reusable rule. | `tests/run-tests.sh (the PT-01 body over the source tree, plus tests/)` | — |
| `PR-05` | source | test | The automation producer is silent when there is nothing to report. | `tests/run-tests.sh` | — (the mutation is the control: the same producer, on the same fixture, with one installed file edited, must go from an empty stdout to a record and exit 1. A producer that stays quiet after the mutation is not silent, it is broken.) |

## Advisory rows, named

9 of the 62 rows are labelled `advisory`. 8 carry no executable check at all
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

