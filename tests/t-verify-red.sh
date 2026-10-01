#!/usr/bin/env bash
# t-verify-red.sh — PR-03, the negative control. Every target-scope row must go RED under its
# own violation. A verifier that only ever prints GREEN is a failure, and this is the file that
# proves it is not one. Run by tests/run-tests.sh.
#
# One control per target-scope row: 133 `expect_red` call sites and 34 `expect_green` - 167 calls over
# all 82 of the matrix's 82 target rows (the other five rows are source-scope and carry controls of
# their own). Measured at this revision: 82 distinct ids, 0 phantom ids (every id used here is a row
# in the matrix) and 0 target row left without a control. Nine of the 82 - `HP-04`, `HS-03`,
# `CM-02`, `MD-03`, `PG-04`, `DOC-01`, `DOC-02`, `SC-09` and `JG-03`, the rows whose check column is
# literally `advisory` (docs/LIMITS.md and docs/RISKS.md name them and say why) - carry no
# executable check at all, and ten carry the wire control below (those nine plus `MD-02`, whose
# check column holds a real command of its own). For a row with no check of its own, its control
# replaces the row's check column with a command that fails and proves the row is WIRED, not that a
# rule bites. This paragraph was counted
# from the file rather than carried: it said "63 of the matrix's 65 target rows. The two it does not
# cover are `DOC-01` and `DOC-02`" until G2, and "70 ... the three as rules" for one commit
# - both were one count behind, because a row whose control exists was still described as uncovered.
# The ids were built up as 42 at v0.1 plus the
# five added with AU-01..AU-04 and SK-04, plus the ten added with SC-01..SC-09 and PF-01, plus the
# five added with BN-00..BN-03 and BN-05, plus the three F4/G4 extras, the two V1 extras (G8-2,
# G8-5), the second BN-00 control, the five W1 extras (three G8-3 gate-cmd forms, the V3-2
# exit-code ban control, and the G8-6b ceiling/baseline control), the seven added with G1's
# FM-01/FM-02/VA-01 - four of FM-01's clauses, FM-02's two, and the failing doctor - and the
# fourteen added with G2's JG-01..JG-03 and LP-01..LP-05 (one expectation per clause the rows
# mechanise, plus a seeded loop record that has to PASS, which is the half of a control that
# proves a new row is not always-red), and the seventeen added with G6/W4's CI lane and Electron
# class (five re-declared PG-05 shapes with the GREEN half that proves the new strictness is not
# "any file that mentions if:", six controls for the new PG-06 row - one per clause plus the two
# halves that prove it is not always-red and not always-green, five electron bans with the SKIP
# control, and the second class-B part control), and the ten added with X1/W5 - five for the ban
# lane's two DOCUMENTED escapes in both directions (`bans_exempt:` with a real violation inside
# the exempt path, the same violation outside it, the inline `BAN-OK(<id>): <reason>` marker, a
# marker with no reason, and a marker naming another ban), one stub feature map whose token occurs
# only in the harness, and three for the loop's close-and-reopen (silent, recorded, stub archive),
# and the six added with Z1 - `HS-02`'s declared-command pair (the GREEN half runs a harness set
# that is RED on the pre-change tree, the RED half declares `cmd: false`, a command that
# interpolates no `{name}`), one for `IN-03`'s newly-enforced enum, one for `FM-02`'s tracked-file
# clause, one for `SC-03`'s hit count, one text assertion over the summary's advisory arithmetic
# (Z1-7 - a `check`, not an `expect_*` call, for the judge-lane reason below) and one pinning the
# drift guard that catches a defanged ban probe, and the ten added with AA1/Z2 - two for Z2-2's
# minified lockfile (the FAIL half that used to PASS vacuously, and the allowlisted half that
# proves the fix is not "any minified lock FAILs"), one for Z2-3's metacharacter-bearing harness
# name, seven for Y1 §7 items 1/2/6 (item 1 in both directions, item 6's subtree/sibling pair plus
# the trailing-slash case, item 2's env contract in both directions - the cluster Z1 named as the
# one with a real engine underneath), plus one assertion on the LINE the alignment control reports
# (a `check`, not an `expect_*`, for the judge-lane reason below): ten call sites, eleven
# assertions. Measured against a054289 with the pre-fix
# `bin/goblin-verify` and `manifest/enforcement.tsv` restored and these tests kept: SIX controls are
# RED there - `Z1-4`, `Z1-5`, `Z1-6`, `Z1-7` and `W5-11` (Z1's five) plus `Z2-2`, the
# minified-lockfile FAIL half AA1 added - and they are the ONLY controls in this file that change
# verdict between the two trees. (`W5-12` is a PIN, holding on both trees, because it asserts the
# limitation Z1 chose to record rather than fix, and the GREEN half of the `HS-02` pair is the same
# kind of half - it proves the row is not always-red, not that a fix bites.)
# The judge-lane family comparison is two text assertions rather than `expect_*` calls, because
# `MD-02` is advisory and exits 0 either way; its control reads the line it prints. Thirty-four of
# the controls are `expect_green` (the F2-9 pairs, three F4/G8-6b asserts, two that seed a feature
# map and require it to PASS, seven that seed a loop record or a judge lane and require
# `JG-01`, `JG-02` and `LP-01`..`LP-05` to PASS, five that pin a new row's non-failing half -
# a commented-out `if:`, the installed workflow, a verbatim gate run, the no-workflow SKIP and an
# unlisted ban - four that prove the two escapes, the recorded re-scope and the replay row's
# declared command are not
# always-red, and the five AA1 added: Z2-2's allowlisted minified lock, Z2-3's metacharacter-bearing
# harness name, and the non-failing half of each of Y1 §7's items 1, 2 and 6). The `--only <id>` form is used
# so a mutation in one row cannot be masked by another row failing first.
#
# PLUS F4's four controls, in a block of their own below the HP rows. HP-02 and HP-03 are the two
# rows whose bodies F4 rewrote, so beyond the one `expect_red` each already had, four more controls
# pin the new semantics: two are `expect_green` (a legitimate HANDOFF that the pre-change rows
# rejected) and two are `expect_red` (a violation the pre-change rows let through). All four are
# RED on the pre-change rows - measured by running this file against e196b3e with its old HP-02 and
# HP-03 bodies restored, the F4 way of proving a control is not green on both trees.
#
# V1 (G8-2) rewrote HP-03 a second time: the row's matcher was satisfied by the TEMPLATE's own
# example sentence, so the real gate line could lose its `measured <date>` and the row stayed
# GREEN. The F4 `expect_red ... m_no_gate_line` control was re-pointed with it (it now removes the
# real gate line and leaves the example), and one control per direction was added: m_no_date_real
# (`expect_red`) and m_no_date_example (`expect_green`). Neither is green on both trees - measured
# in V1.md against 43f7f69 with this same file.
#
# WHAT THE ADVISORY-ROW CONTROLS DO AND DO NOT PROVE. Ten target rows are labelled
# `advisory` by design (HP-04, HS-03, CM-02, MD-02, MD-03, PG-04, DOC-01, DOC-02, SC-09, JG-03 —
# the ninth landed with G4's guard rails and the tenth with G2's judge row; this sentence said
# eight until 2026-09-25, then nine until the count was taken again at W4): their rules
# are not mechanically checkable, so there is no violation of the *rule* to produce. Their
# control mutates the row's check column to a command that fails, and asserts the run then
# reports that row FAIL. That proves the row is wired into the runner and that its id is
# honoured — it does NOT prove the rule bites, because no check for it exists. The manifest
# itself keeps them honest: IN-03 fails the run if a row labelled advisory claims enforcement
# it does not perform.
#
# WHAT THE PRE-FIX RED LOOKS LIKE. For each row whose check this pass changed, the control is
# RED on the pre-fix tree as well as after (D4/PT-01, D5/SP-03, D6/CL-02, D7/HS-01,
# D10/CL-01, D12/DS-01, D13/SK-03). The pre-fix transcripts are in
# goblin-stack-research/F1.md, section 2. Z1's five biting controls were measured the same way -
# this file run from a copy that keeps these tests and restores `bin/goblin-verify` and
# `manifest/enforcement.tsv` from a054289: `Z1-4` (HS-02 exit 0, wanted 1), `Z1-5` (IN-03 exit 0,
# wanted 1), `Z1-6` (FM-02 exit 0, wanted 1), `W5-11` (the run still prints the character count) and
# `Z1-7` (the summary prints no arithmetic line) all go RED there. They were the Z1-era file's ONLY
# five FAILs; at 0.4.2 the same procedure yields SIX - these five plus `Z2-2`, whose minified-lock
# FAIL half is RED on the 0.4.0 verifier too (168 ok, 6 FAIL, 174 assertions in all) - and those six
# are the only controls in the file that change verdict between the two trees.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
TARGET="$WORK/target"
TARGET_B="$WORK/targetB"
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

printf 'profiles:\n  coder:\n    model: model-code\n    provider: prov-code\n    effort: low\n  reviewer:\n    model: model-review\n    provider: prov-review\n    effort: high\n' > "$WORK/models.yaml"
printf '# a fixture standard\nthe house style lives here\n' > "$WORK/standard.md"

mkdir -p "$TARGET" && cd "$TARGET"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# target\n' > README.md
git add -A && git commit -q -m "chore: seed"
PRE_CHANGE=$(git rev-parse --short HEAD)

bash "$SRC/bin/goblin-install" --target "$TARGET" --class A --models "$WORK/models.yaml" --practice "$WORK/standard.md" >/dev/null 2>&1
git add -A && git commit -q -m "chore: install gobstack"
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"

bash .goblin/bin/goblin-verify >/dev/null 2>&1
check "the fixture starts GREEN (nothing below is measured against a broken baseline)" "$?"

# V3-1: the ban lane has to reach the WRITER, not only the post-mortem. AGENTS.md is the file a
# session reads first in an adopted repo, so the engine and the `bans:` switch are named there.
# RED on the pre-change tree (0 mentions), which is what the assertion is for.
grep -q 'goblin-bans' AGENTS.md
check "the installed AGENTS.md names the ban engine (V3-1)" "$?"

BK="$WORK/backup"
mkdir -p "$BK"
cp -a HANDOFF.md "$BK/HANDOFF.md"
cp -a .goblin/goblin.yaml "$BK/goblin.yaml"
cp -a .goblin/installed.json "$BK/installed.json"
cp -a .goblin/manifest/enforcement.tsv "$BK/enforcement.tsv"
cp -a .hermes/skills/goblin-mode/SKILL.md "$BK/SKILL.md"
cp -a ROUND-000-SPEC.md "$BK/ROUND-000-SPEC.md"
cp -a "$WORK/standard.md" "$BK/standard.md"
cp -a .hermes/skills/goblin-drift-audit/SKILL.md "$BK/drift-audit-SKILL.md"
cp -a .hermes/skills/goblin-bugreporter/SKILL.md "$BK/bugreporter-SKILL.md"
cp -a .goblin/automations "$BK/automations"
cp -a .goblin/audit-waiver.tsv "$BK/audit-waiver.tsv"
cp -a .goblin/install-hooks.allowlist "$BK/install-hooks.allowlist"
cp -a .goblin/boundary-waivers "$BK/boundary-waivers"
cp -a .goblin/manifest/bans.tsv "$BK/bans.tsv"
# G2 mutates roles.yaml (the judge lane's profile list) and the mapping file (a judge profile
# beside the code lane). Both are restored: a leaked judge profile would turn MD-02's ADV into a
# PASS for every control below it.
cp -a .goblin/roles.yaml "$BK/roles.yaml"
cp -a "$WORK/models.yaml" "$BK/models.yaml"
# W4: the CI lane. A class-A install now carries .github/workflows/goblin-gate.yml, and CL-01
# requires it (ci-gate is `R` for A), so it must come back byte-for-byte after every workflow
# mutation below - the `rm -rf .github` this used to be would have left the final full run RED on
# a required part.
cp -a .github "$BK/github"
# .gitignore is mutated by m_sc_02 and must come back byte-for-byte: the fixture-green check at
# the end of this file is what caught its absence.
cp -a .gitignore "$BK/gitignore"
# Z1-4: the harness set. The replay controls below REPLACE checks/*.mjs with a harness that is
# RED on both trees - they have to, because the shipped scaffold (`assert.mjs`) asserts something
# true by construction and so is GREEN on the pre-change tree, which would make HS-02 FAIL for a
# reason unrelated to the declared command. The scaffold comes back byte-for-byte.
cp -a checks/assert.mjs "$BK/assert.mjs"
# W1: the IN-02 clause-2 control deletes .goblin/bin and .goblin/manifest wholesale, so
# the whole engine payload is backed up (once, here) and rebuilt by restore_all.
cp -a .goblin/bin "$BK/bin"
cp -a .goblin/manifest "$BK/manifest"

restore_all() {
  cp -a "$BK/HANDOFF.md" HANDOFF.md
  cp -a "$BK/goblin.yaml" .goblin/goblin.yaml
  cp -a "$BK/installed.json" .goblin/installed.json
  # W1: the IN-02 clause-2 control deletes .goblin/bin and .goblin/manifest wholesale,
  # so the restore rebuilds them from the backup before the per-file copies below.
  rm -rf .goblin/bin .goblin/manifest
  cp -a "$BK/bin" .goblin/bin
  cp -a "$BK/manifest" .goblin/manifest
  cp -a "$BK/roles.yaml" .goblin/roles.yaml
  cp -a "$BK/models.yaml" "$WORK/models.yaml"
  cp -a "$BK/SKILL.md" .hermes/skills/goblin-mode/SKILL.md
  cp -a "$BK/ROUND-000-SPEC.md" ROUND-000-SPEC.md
  cp -a "$BK/standard.md" "$WORK/standard.md"
  cp -a "$BK/drift-audit-SKILL.md" .hermes/skills/goblin-drift-audit/SKILL.md
  cp -a "$BK/bugreporter-SKILL.md" .hermes/skills/goblin-bugreporter/SKILL.md
  cp -a "$BK/automations/." .goblin/automations/
  cp -a "$BK/gitignore" .gitignore
  rm -f checks/green.mjs checks/red.mjs newfile.txt todo-marker.mjs ROUND-001-SPEC.md stray.txt \
        .goblin/state.json .goblin/last-gate-line .goblin/.ds-report .goblin/ratchet-last \
        .envrc .goblin/audit.tsv package.json package-lock.json reference-manifest.json
  # P15: the four RC- controls declare a corpus in directories a class-A install does not have, so
  # the last thing each leaves behind is removed here (the r_rc03_git hook only handles the index).
  rm -rf manifests refs notes
  # Z2-3's harness carries shell metacharacters in its NAME, so it needs its own rm: `checks/*.mjs`
  # would expand to it, but an unquoted glob in a restore path is exactly the habit that control
  # exists to break.
  rm -f 'checks/z2;true;#.mjs'
  # The allowlist is mutated by m_sc_08_minified_ok (Z2-2's green half) and was backed up but never
  # restored. This is FIXTURE HYGIENE, not drift prevention: .goblin/install-hooks.allowlist is an
  # `owned` file, and IN-02 hashes only the `files` map (40 entries, the allowlist not among them),
  # so a leftover entry is not drift-checked by IN-02 at all. Measured at 0.4.2: an allowlist edited
  # by hand still prints `IN-02 ... 40 installed files hashed | practice pin ok` at exit 0, and this
  # file exits 0 (`t-verify-red: PASS`) with this `cp` line deleted. The restore is what keeps the
  # fixture byte-accurate for the green check at the end of the file.
  cp -a "$BK/install-hooks.allowlist" .goblin/install-hooks.allowlist
  cp -a "$BK/assert.mjs" checks/assert.mjs
  rm -f reviews/fixture-*.md
  # G2: the planted loop record. A leftover .goblin/loop/ would leave JG-01/LP-* green by
  # accident AND count as an untracked file for CM-03 in the final full run.
  rm -rf .goblin/loop
  rm -rf reports
  rm -rf .github
  cp -a "$BK/github" .github
  rm -rf dist src app .hermes/skills/verify-fix
  git add -A >/dev/null 2>&1
  git commit -q -m "test: restore fixture" >/dev/null 2>&1 || true
}

# expect_red <label> <row id> <expected exit> <mutate fn> [workdir] [restore fn]
# (declared with `function` so that `grep -c '^expect_red'` counts controls, not the definition)
function expect_red {
  local label="$1" id="$2" want="$3" mutate="$4" dir="${5:-}" restore="${6:-restore_all}"
  local out rc
  if [ -n "$dir" ]; then ( cd "$dir" && "$mutate" ); else "$mutate"; fi
  if [ -n "$dir" ]; then out=$( cd "$dir" && bash .goblin/bin/goblin-verify --only "$id" 2>&1 ); rc=$?
  else out=$(bash .goblin/bin/goblin-verify --only "$id" 2>&1); rc=$?; fi
  if [ "$rc" = "$want" ]; then
    note "ok   $label -> $id exit $rc ($(printf '%s' "$out" | grep -m1 -E '^FAIL|^error' | cut -c1-88))"
  else
    note "FAIL $label -> $id exit $rc, wanted $want"
    printf '%s\n' "$out" | sed 's/^/        /'
    fail=1
  fi
  if [ -n "$dir" ]; then ( cd "$dir" && "$restore" ); else "$restore"; fi
}

# expect_green <label> <row id> <mutate fn> [workdir] [restore fn]
# The mirror of expect_red: F4 gave HP-02 a closed alias set and scoped HP-03 to the Gates
# section, so two of its controls assert that a HANDOFF the pre-change rows rejected now passes.
# Declared with `function` for the same reason expect_red is.
function expect_green {
  local label="$1" id="$2" mutate="$3" dir="${4:-}" restore="${5:-restore_all}"
  local out rc
  if [ -n "$dir" ]; then ( cd "$dir" && "$mutate" ); else "$mutate"; fi
  if [ -n "$dir" ]; then out=$( cd "$dir" && bash .goblin/bin/goblin-verify --only "$id" 2>&1 ); rc=$?
  else out=$(bash .goblin/bin/goblin-verify --only "$id" 2>&1); rc=$?; fi
  if [ "$rc" = "0" ]; then
    note "ok   $label -> $id exit 0 ($(printf '%s' "$out" | grep -m1 -E '^PASS' | cut -c1-88))"
  else
    note "FAIL $label -> $id exit $rc, wanted 0"
    printf '%s\n' "$out" | sed 's/^/        /'
    fail=1
  fi
  if [ -n "$dir" ]; then ( cd "$dir" && "$restore" ); else "$restore"; fi
}

# ---- mutations: the exact violation each row exists to catch ------------------
m_in_01()         { sed -i '/"version"/d' .goblin/installed.json; }
m_edit_practice() { printf '# an edited byte\n' >> "$WORK/standard.md"; }
m_blank_row()     { sed -i -E 's/^(HP-05\t[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t)[^\t]*/\1/' .goblin/manifest/enforcement.tsv; }
m_in_04()         { sed -i 's|^  "refused": {|  "refused": {\n    "checks/gone.mjs": "deadbeef",|' .goblin/installed.json; }
# Z1-5: a typo in the `enforced_by` cell. docs/ENFORCEMENT.md calls the enum closed; before the
# fix NOTHING read the column, so this changed no verdict anywhere in the run.
m_bad_enum()      { awk -F'\t' -v OFS='\t' '{ if ($1=="BN-01") $4="bogus"; print }' .goblin/manifest/enforcement.tsv > .goblin/manifest/enforcement.tsv.n && mv .goblin/manifest/enforcement.tsv.n .goblin/manifest/enforcement.tsv; }

m_drop_handoff()  { rm -f HANDOFF.md; git add -A >/dev/null 2>&1; git commit -q -m "test: drop handoff" >/dev/null 2>&1; }
m_drop_heading()  { sed -i 's/^## Gates$/#### Gates/' HANDOFF.md; git add -A >/dev/null 2>&1; git commit -q -m "test: demote the Gates heading" >/dev/null 2>&1; }
# The row's WIRING control: it strips every date in the file, so it is RED on the pre-change row
# and on the new one alike. Kept for that reason - it proves the id is honoured and the row can
# still go red - and it proves nothing about which line the row reads (see the two G8-2 controls).
m_no_date()       { sed -i -E 's/measured [0-9]{4}-[0-9]{2}-[0-9]{2}/measured/g' HANDOFF.md; }
# G8-2, direction 1: the date goes from every line EXCEPT the template's example, i.e. from the
# REAL gate line the row is supposed to check. Measured at 43f7f69 this left the row GREEN: the
# old matcher's keyword list (tsc|build|hex|safelist|n/n) did not contain the shipped gate name
# `commit`, so the only gate-shaped line it could see was the example prose.
m_no_date_real()  { sed -i -E '/Example of the required form/!s/measured [0-9]{4}-[0-9]{2}-[0-9]{2}/-/g' HANDOFF.md; }
# G8-2, direction 2: the date goes from the EXAMPLE only. Measured at 43f7f69 this made the row
# FAIL - the fault was the other way round, and that is the proof the row tested the template
# rather than the artifact. Prose is not a gate number, so it now PASSES.
m_no_date_example() { sed -i -E '/Example of the required form/s/measured [0-9]{4}-[0-9]{2}-[0-9]{2}/-/g' HANDOFF.md; }

# ---- F4's four controls: HP-02 slot-based, HP-03 scoped to the Gates section ------------------
# Each is RED on the pre-change rows (the shipped `for h in 'State' 'Gates' ...` grep and the
# whole-file awk), which is what makes it a control rather than a restatement:
#   m_phantom_state  a heading that merely CONTAINS "State" - the old grep passed it (phantom);
#   m_hist_lines     the record PROJECT-PRACTICE section 1 requires, which the old awk reddened;
#   m_alias_vocab    the model repo's own vocabulary, which the old literal strings rejected;
#   m_no_gate_line   a Gates section with nothing in it - the old awk had no n==0 clause.
m_phantom_state() { sed -i 's|^## State$|## ⚠️ BOARD STATE|' HANDOFF.md; }
m_alias_vocab()   { sed -i -e 's|^## State$|## Status|' -e 's|^## Gates$|## Gate|' \
                         -e 's|^## Next steps$|### NEXT|' \
                         -e 's|^## NOT verified$|## Pending his device test|' HANDOFF.md; }
m_hist_lines()    { awk '
  /^## Next steps$/ && !d {
    print "## Round log"
    for (i = 1; i <= 20; i++) print "- round " i ": tsc=0 · build=0 · " i "/" i " harnesses green"
    print ""
    d = 1
  }
  { print }
' HANDOFF.md > HANDOFF.md.new && mv HANDOFF.md.new HANDOFF.md; }
m_no_gate_line()  { awk '
  /^## Gates$/ {print; inG = 1; next}
  inG && /^#{1,3}[[:space:]]/ {inG = 0}
  inG && /Example of the required form/ {print; next}
  inG && /^[[:space:]]*[-*][[:space:]]/ {next}
  {print}
' HANDOFF.md > HANDOFF.md.new && mv HANDOFF.md.new HANDOFF.md; }
m_row_fails()     { awk -F'\t' -v OFS='\t' -v x="$1" 'NR==1{print;next} {if ($1==x) $6="false"; print}' .goblin/manifest/enforcement.tsv > .goblin/manifest/enforcement.tsv.new; mv .goblin/manifest/enforcement.tsv.new .goblin/manifest/enforcement.tsv; }
m_hp_04()         { m_row_fails HP-04; }
m_no_head()       { sed -i -E 's/`[0-9a-f]{7,40}`/`deadbee`/' HANDOFF.md; }

m_drop_spec()     { rm -f ./*-SPEC.md; git add -A >/dev/null 2>&1; git commit -q -m "test: drop spec" >/dev/null 2>&1; }
m_untracked_spec() { printf '# a round nobody committed\n\n- AC1: `x` prints `y`\n' > ROUND-001-SPEC.md; }
m_feely_ac()      { printf '\n- AC9: the panel feels right\n' >> ROUND-000-SPEC.md; }

m_no_gates()      { sed -i '/^gates:/,/^$/{/^$/d; d}' .goblin/goblin.yaml; }
# G8-3: a DECLARED gate that loses its `cmd:` used to survive as a silent drop from GT-01's
# count (`1 declared gate(s)` for a config that declares two). Three forms, all of them a
# one-line edit: the cmd line deleted, re-indented out of the gate block, and blanked.
m_gate_no_cmd()   { sed -i '/^    cmd: test /d' .goblin/goblin.yaml; }
m_gate_indent_cmd(){ sed -i 's/^    cmd: test /  cmd: test /' .goblin/goblin.yaml; }
m_gate_blank_cmd(){ sed -i 's/^    cmd: test .*/    cmd:/' .goblin/goblin.yaml; }
m_break_gate()    { sed -i 's|^    cmd: git rev-parse --verify --quiet HEAD|    cmd: false|' .goblin/goblin.yaml; }
m_drop_gate_line(){ rm -f .goblin/last-gate-line; }
# The class-A ratchet is the PERF metric (G4 D2): the TODO count moved into the `todo_ceiling`
# gate. So m_no_ratchet strips the metric name and m_ratchet_rise grows the measured number.
m_no_ratchet()    { sed -i 's/^  name: client_js_bytes/  name:/' .goblin/goblin.yaml; }
m_ratchet_rise()  { mkdir -p dist/assets; printf 'console.log("a byte that was not there before")\n' > dist/assets/chunk.js; }
m_todo_gate()     { sed -i 's/-le 160/-le 0/' .goblin/goblin.yaml; printf '// TODO: over the ceiling\n' > todo-marker.mjs; }

m_no_harness_dir() { sed -i 's|^harness_dir: .*|harness_dir: nowhere|' .goblin/goblin.yaml; }
m_green_harness() { printf 'console.log("PASS  nothing\\n"); process.exit(0);\n' > checks/green.mjs; git add -A >/dev/null 2>&1; git commit -q -m "test: a harness green on both trees" >/dev/null 2>&1; sed -i "s|^  commit: \"\"|  commit: \"$PRE_CHANGE\"|" .goblin/goblin.yaml; }
m_hs_03()         { m_row_fails HS-03; }
# Z1-4: `replay.cmd` was read only to assert it was non-empty, and the row ran `node <file>`
# itself - so the declared command and its `{name}` placeholder were decorative and `false`
# changed no verdict. The harness set has to be RED on the pre-change tree for the difference to
# be visible at all: the shipped scaffold `assert.mjs` asserts something TRUE by construction and
# is therefore GREEN on the pre-change tree, which would make HS-02 fail for an unrelated reason.
#   m_replay_all_red   the GREEN half: a harness RED on both trees, run by the declared command
#                      (`node checks/{name}.mjs`) -> PASS, so the row is not always-red;
#   m_replay_cmd_false the RED half: the same tree with `replay.cmd: false`, a command that
#                      interpolates no `{name}` and so replayed nothing.
m_replay_all_red()   { rm -f checks/*.mjs; printf 'process.exit(1)\n' > checks/red.mjs; sed -i "s|^  commit: \"\"|  commit: \"$PRE_CHANGE\"|" .goblin/goblin.yaml; }
m_replay_cmd_false() { m_replay_all_red; sed -i 's|^  cmd: node checks/{name}.mjs|  cmd: false|' .goblin/goblin.yaml; }
# Z2-3: the harness FILE NAME is part of the command text the shell parses, because Z1-4 made the
# row run the DECLARED command instead of `node "$f"`. The name is therefore substituted shell-
# quoted, and this is the measurement: the file is named with `;` and `#`. Unquoted, the name
# split into two commands and the trailing `true` decided the exit code, so the row reported the
# file GREEN on the pre-change tree and FAILed - measured on 846c132's bin/goblin-verify: rc 1,
# "z2;true;#.mjs was GREEN on the pre-change tree". Quoted, `node` receives ONE argument, the
# harness runs, exits 1, and the row passes - which is what this control asserts.
m_replay_meta_name() { rm -f checks/*.mjs; printf 'process.exit(1)\n' > 'checks/z2;true;#.mjs'; sed -i "s|^  commit: \"\"|  commit: \"$PRE_CHANGE\"|" .goblin/goblin.yaml; }

m_bad_author()    { git -c user.email=someone@else.test commit -q --allow-empty -m "test: ambient author"; }
m_cm_02()         { m_row_fails CM-02; }
m_dirty_tree()    { printf 'untracked\n' > newfile.txt; }

# The slug is assembled at run time, never written literally (G8-10 - the same fix F2-5 gave the
# tenant string). A literal model name here was one of the two repo-wide MD-01 hits: MD-01's own
# scope does not read tests/, so the ROW was clean, but the control was the leak its own rule
# exists to catch, and a reviewer grepping the repo found it. The repo-wide count is 0 now.
MD_SLUG="$(printf '%s%s' 'deep' 'seek-v9-turbo')"
m_model_leak()    { printf '\nmodel: %s\n' "$MD_SLUG" >> .hermes/skills/goblin-mode/SKILL.md; }
m_md_02()         { m_row_fails MD-02; }
m_md_03()         { m_row_fails MD-03; }

m_review_no_sha() { mkdir -p reviews; printf 'head: 0000000000000000000000000000000000000000\nbase: %s\npatch-id: x\nstakes: S1\n' "$PRE_CHANGE" > reviews/fixture-def5678.md; }
m_bad_stakes()    { mkdir -p reviews; printf 'head: %s\nbase: %s\npatch-id: x\nstakes: S9\n' "$(git rev-parse HEAD)" "$PRE_CHANGE" > reviews/fixture-pg02.md; }
m_bad_review()    { mkdir -p reviews; printf 'head: %s\nbase: %s\npatch-id: deadbeef\nstakes: S2\nchecks-run:\n' "$(git rev-parse HEAD)" "$PRE_CHANGE" > reviews/fixture-abc1234.md; }
m_pg_04()         { m_row_fails PG-04; }
m_self_skip_wf()  { mkdir -p .github/workflows; printf 'jobs:\n  a:\n    steps:\n      - if: ${{ secrets.NOPE }}\n        run: echo hi\n' > .github/workflows/ci.yml; git add -A >/dev/null 2>&1; git commit -q -m "test: self-skipping workflow" >/dev/null 2>&1; }
# ---- W4/G6: the PG-05 hole G8 measured, and the PG-06 row that closes the other half ---------
# The four shapes below are all PASSES on the pre-change predicate (measured - see W4.md), because
# it counted "every step is guarded": a JOB-level condition reads as zero guarded steps, a job with
# no step has nothing to guard, and an UNGUARDED step that decides whether the guarded gate step
# runs makes the count 1-of-2. Each one reaches the end of the job without running the gate while
# the required check reports Success (R5's trap, one level up).
m_job_if_wf()     { mkdir -p .github/workflows; printf 'jobs:\n  gate:\n    if: ${{ github.event_name == '"'"'push'"'"' }}\n    steps:\n      - run: bash .goblin/bin/goblin-verify\n' > .github/workflows/jobif.yml; git add -A >/dev/null 2>&1; git commit -q -m "test: a job-level if:" >/dev/null 2>&1; }
m_nosteps_wf()    { mkdir -p .github/workflows; printf 'jobs:\n  gate:\n    runs-on: ubuntu-latest\n' > .github/workflows/nosteps.yml; git add -A >/dev/null 2>&1; git commit -q -m "test: a job with no steps" >/dev/null 2>&1; }
m_nojobs_wf()     { mkdir -p .github/workflows; printf 'name: nothing\non: push\n' > .github/workflows/nojobs.yml; git add -A >/dev/null 2>&1; git commit -q -m "test: a workflow with no jobs" >/dev/null 2>&1; }
m_decider_wf()    { mkdir -p .github/workflows; printf 'jobs:\n  gate:\n    steps:\n      - id: check\n        run: echo ready=true >> "$GITHUB_OUTPUT"\n      - if: steps.check.outputs.ready == '"'"'true'"'"'\n        run: bash .goblin/bin/goblin-verify\n' > .github/workflows/decider.yml; git add -A >/dev/null 2>&1; git commit -q -m "test: an unguarded decider step" >/dev/null 2>&1; }
# The probe is a TEXT reading and the row says so: a `#` before the step keeps the words and
# removes the step. This is the expect_green half - it proves the new strictness is not "any file
# that mentions if:".
m_wf_comment_if() { sed -i '1i # the old shape, kept for reference: if: steps.check.outputs.ready == true' .github/workflows/goblin-gate.yml; }
# PG-06, clause 1: a workflow that runs something else entirely.
m_wf_npm_test()   { rm -f .github/workflows/goblin-gate.yml; printf 'jobs:\n  gate:\n    steps:\n      - run: npm test\n' > .github/workflows/ci.yml; git add -A >/dev/null 2>&1; git commit -q -m "test: CI runs npm test" >/dev/null 2>&1; }
# PG-06, clause 1: the verifier IS called, but narrowed - a subset of the declared gates is a
# different truth about the same SHA, which is the failure mode the row exists for.
m_wf_only()       { sed -i 's|run: bash .goblin/bin/goblin-verify$|run: bash .goblin/bin/goblin-verify --only IN-02|' .github/workflows/goblin-gate.yml; }
# PG-06: the call is COMMENTED OUT. The words are still in the file, so a probe that reads text
# without blanking comments first would call this a run (HS-03's rule, applied to the CI lane).
m_wf_commented()  { sed -i 's|^\( *\)run: bash .goblin/bin/goblin-verify|\1# run: bash .goblin/bin/goblin-verify|' .github/workflows/goblin-gate.yml; }
# PG-06, clause 2: the workflow runs each DECLARED gate command verbatim instead of the verifier.
m_wf_verbatim()   { rm -f .github/workflows/goblin-gate.yml; { printf 'jobs:\n  gate:\n    steps:\n'; sed -n 's/^    cmd: /      - run: /p' .goblin/goblin.yaml; } > .github/workflows/ci.yml; git add -A >/dev/null 2>&1; git commit -q -m "test: CI runs the declared gates verbatim" >/dev/null 2>&1; }
# PG-06 is a SKIP (not a pass) when there is no workflow to compare: the HS-01 precedent.
m_wf_none()       { rm -rf .github; git add -A >/dev/null 2>&1; git commit -q -m "test: no workflow" >/dev/null 2>&1; }
# The do-nothing mutation, for the two expect_green controls whose point is the state the install
# already produced (the shipped workflow passes, and PG-06 skips when there is nothing to read).
m_wf_nothing()    { :; }

m_tracked_runtime() { sed -i 's|^  - .goblin/state.json|  - README.md|' .goblin/goblin.yaml; }
m_drop_ds_report()  { rm -f .goblin/.ds-report; }

m_doc_01()        { m_row_fails DOC-01; }
m_doc_02()        { m_row_fails DOC-02; }

# ---- the security and perf rows (G4): SC-01..SC-09, PF-01 -------------------------------------
# Every mutation is the exact failure the row's why-cell names, and every one is a file a real
# repo produces by accident: a dotenv-family file that got added, an ignore rule narrowed by
# hand, a client-visible key name, a cookie written without flags, a write route with no
# validator, a manifest with no lockfile, an audit record nobody re-took, an install hook nobody
# decided on.
m_sc_01()  { printf 'export TOKEN=x\n' > .envrc; git add -A >/dev/null 2>&1; git commit -q -m "test: a tracked dotenv-family file" >/dev/null 2>&1; }
m_sc_02()  { sed -i '/^\.env$/d' .gitignore; }
m_sc_03()  { mkdir -p src; printf 'export const k = process.env.NEXT_PUBLIC_API_SECRET_KEY;\n' > src/config.ts; }
m_sc_04()  { mkdir -p src; printf 'document.cookie = "theme=dark";\n' > src/cookie.ts; }
m_sc_05()  { mkdir -p app/api/contact; printf 'export async function POST(req) {\n  const b = await req.json();\n  await save(b);\n}\n' > app/api/contact/route.ts; }
m_sc_06()  { printf '{"name":"fixture","version":"1.0.0"}\n' > package.json; }
m_sc_07()  { printf '# .goblin/audit.tsv - written by goblin-audit 0.2.0 on 2020-01-01\n# command: npm audit --json\nmeasured 2020-01-01\n' > .goblin/audit.tsv; }
m_sc_08()  { printf '{\n  "packages": {\n    "node_modules/esbuild": {\n      "version": "0.1.0",\n      "hasInstallScript": true\n    }\n  }\n}\n' > package-lock.json; }
# Z2-2: the SAME lockfile on ONE LINE. The reader is line-anchored, so before the fix this shape
# matched nothing and the row printed `0 install hook(s), 0 allowlisted` - a PASS, exit 0, where
# the pnpm/yarn branch above already reports a SKIP. Two halves: the unlisted hook must FAIL here
# (it did not - a vacuous PASS), and the allowlisted one must PASS (so the fix is not "any
# minified lock FAILs").
m_sc_08_minified()    { printf '{"name":"fixture","lockfileVersion":3,"packages":{"node_modules/esbuild":{"version":"0.1.0","hasInstallScript":true}}}\n' > package-lock.json; }
m_sc_08_minified_ok() { m_sc_08_minified; printf 'esbuild\n' >> .goblin/install-hooks.allowlist; }
m_sc_09()  { m_row_fails SC-09; }
m_pf_01()  { sed -i -e 's/^  metric: .*/  metric: client_js_bytes/' -e 's/^  baseline_commit: .*/  baseline_commit: 0000000000000000000000000000000000000000/' -e 's/^  baseline_value: .*/  baseline_value: 1/' -e 's/^  measured: .*/  measured: 2026-01-01/' .goblin/goblin.yaml; }
# G8-6b: the budget and the measurement have to be the SAME number. Two controls - the honest
# record passes, and a one-line `ceiling:` raise that leaves the baseline alone FAILs. Before the
# fix both were GREEN: the passing line printed `baseline_value 0 ... (ceiling 100000)` and
# nothing cross-checked it.
m_pf_ceiling_match() { sed -i -e 's/^  metric: .*/  metric: client_js_bytes/' -e "s/^  baseline_commit: .*/  baseline_commit: $PRE_CHANGE/" -e 's/^  baseline_value: .*/  baseline_value: 0/' -e 's/^  measured: .*/  measured: 2026-01-01/' .goblin/goblin.yaml; }
m_pf_ceiling_raise() { m_pf_ceiling_match; sed -i 's/^  ceiling: .*/  ceiling: 100000/' .goblin/goblin.yaml; }

# ---- the ban list (G5): BN-00..BN-03, BN-05 ------------------------------------------------
# Every mutation is the exact move a ban forbids. The bans are TEXT probes (no npm, no AST), so
# the violation is a real line of source the probe reads - not a mocked tool.
m_bn_00_orphan()   { sed -i '/^BN-05\t/d' .goblin/manifest/bans.tsv; }
m_bn_00_norepl()   { awk -F'\t' -v OFS='\t' '{ if ($1=="BN-01") $5=""; print }' .goblin/manifest/bans.tsv > .goblin/manifest/bans.tsv.n && mv .goblin/manifest/bans.tsv.n .goblin/manifest/bans.tsv; }
m_bn_01()          { mkdir -p src; printf 'export const a: any = 1;\n' > src/bn01.ts; }
# V3-2: the engine judged by stdout emptiness, so a detect that reports a violation through its
# EXIT CODE alone was read as clean - fail-open, in the lane whose whole job is failing closed.
# The ban really is violated on disk (`: any`), and the detect says so only with exit 1.
m_bn_exit1_detect() { awk -F'\t' -v OFS='\t' '{ if ($1 == "BN-01") $4 = "exit 1"; print }' .goblin/manifest/bans.tsv > .goblin/manifest/bans.tsv.n && mv .goblin/manifest/bans.tsv.n .goblin/manifest/bans.tsv; mkdir -p src; printf 'export const a: any = 1;\n' > src/bn01.ts; }
# W5-12: a DEFANGED probe - `BN-01`'s detect set to `true`, so it always reports clean. Both ban
# rows then PASS vacuously (measured), because neither can read a table whose rows were weakened.
# The decision (Z1) is to RECORD that rather than fix it: the guard that holds is IN-02's drift
# check over `.goblin/manifest/bans.tsv` (docs/LIMITS.md #28), and this control is that guard -
# the defanging is caught, one row over, by the only row that can see it.
m_bn_defang()      { awk -F'\t' -v OFS='\t' '{ if ($1 == "BN-01") $4 = "true"; print }' .goblin/manifest/bans.tsv > .goblin/manifest/bans.tsv.n && mv .goblin/manifest/bans.tsv.n .goblin/manifest/bans.tsv; }
m_bn_02()          { mkdir -p src; printf '// @ts-expect-error\nexport const b = 1;\n' > src/bn02.ts; }
m_bn_03()          { sed -i 's/^bans: \[.*\]/bans: [BN-01, BN-02, BN-03, BN-05]/' .goblin/goblin.yaml; mkdir -p src/components; printf 'export const P = () => { fetch("/api/x"); return null; };\n' > src/components/panel.tsx; }
m_bn_05()          { printf '\nlayers:\n  - src/renderer src/main\n' >> .goblin/goblin.yaml; mkdir -p src/renderer src/main; printf "import { db } from '../main/db';\nexport const r = db;\n" > src/renderer/p.ts; }
# A tree BN-05 can read (so its globs match) but with no `layers:` declared: the row must SKIP
# with that reason, never pass vacuously.
m_bn_05_nolayers() { mkdir -p src/renderer; printf 'export const r = 1;\n' > src/renderer/p.ts; }

# ---- W4/G6: the Electron failure surface, as bans (BN-06..BN-09) -----------------------------
# Each mutation turns its ban ON in the config (a class-A install does not list them - the SKIP
# control below is the other half) and writes the exact line the row exists to catch. The pattern
# is the wrongEnough-shape: these are the keys Electron's own security checklist names, which is
# why they are one-line rules rather than a dependency-graph run.
m_bn_06()  { sed -i 's/^bans: \[.*\]/bans: [BN-01, BN-02, BN-05, BN-06]/' .goblin/goblin.yaml; mkdir -p src; printf 'export const prefs = { nodeIntegration: true };\n' > src/main-prefs.ts; }
m_bn_06_unlisted() { mkdir -p src; printf 'export const prefs = { nodeIntegration: true };\n' > src/main-prefs.ts; }
m_bn_07()  { sed -i 's/^bans: \[.*\]/bans: [BN-01, BN-02, BN-05, BN-07]/' .goblin/goblin.yaml; mkdir -p src; printf 'export const prefs = { contextIsolation: false };\n' > src/isolate.ts; }
m_bn_08()  { sed -i 's/^bans: \[.*\]/bans: [BN-01, BN-02, BN-05, BN-08]/' .goblin/goblin.yaml; mkdir -p src; printf 'export const prefs = { webSecurity: false };\n' > src/webs.ts; }
m_bn_09()  { sed -i 's/^bans: \[.*\]/bans: [BN-01, BN-02, BN-05, BN-09]/' .goblin/goblin.yaml; mkdir -p src; printf 'const v = ipcRenderer.sendSync("chan", 1);\n' > src/ipc.ts; }

# ---- W5-1/W5-2: the two documented escapes, in BOTH directions ---------------------------------
# `bans_exempt:` and the inline `// BAN-OK(<id>): <reason>` were documented in three places and
# exercised by NOTHING (`grep -rn bans_exempt tests/` = 0 hits at 7fec08f), which is why W5's
# regression - a documented escape that produced a permanent RED - shipped unnoticed. These five
# controls are that missing pair. Every one of them NAMES a row that is RED on the pre-fix tree,
# and TWO of the five controls themselves FAIL there - measured at 7fec08f, the two `expect_green`
# halves (the exempt path's PASS and the inline marker's PASS both come back rc 1, because the
# escape did nothing there) while the three `expect_red` halves report ok, the row they drive
# being red for the old reason. This comment claimed "every one of them is RED on the pre-fix
# tree" without that distinction (Z2-4); the CHANGELOG's corrected sentence - in the 0.4.0 entry,
# corrected by 0.4.1 - says which sense it means.
m_bn_01_exempt()      { m_bn_01; awk '{ if ($0 ~ /^bans_exempt:/) { print; print "  - BN-01 src"; next } print }' .goblin/goblin.yaml > .goblin/goblin.yaml.n && mv .goblin/goblin.yaml.n .goblin/goblin.yaml; }
# The other direction: the exception names a DIFFERENT path, so the same violation still counts.
# Without this half, an engine that exempted everything would pass the control above.
m_bn_01_exempt_else() { m_bn_01; awk '{ if ($0 ~ /^bans_exempt:/) { print; print "  - BN-01 app"; next } print }' .goblin/goblin.yaml > .goblin/goblin.yaml.n && mv .goblin/goblin.yaml.n .goblin/goblin.yaml; }
m_bn_01_banok()       { mkdir -p src; printf 'export const a: any = 1; // BAN-OK(BN-01): the value is narrowed at the boundary\n' > src/bn01.ts; }
# The documented form carries a reason. A bare marker is not an escape, and the line stays RED.
m_bn_01_banok_noreason() { mkdir -p src; printf 'export const a: any = 1; // BAN-OK(BN-01)\n' > src/bn01.ts; }
# The marker names the ban it clears. A BAN-OK for another ban must not clear this one - which is
# what stops a sloppy `BAN-OK\(` matcher from becoming a blanket escape.
m_bn_01_banok_other() { mkdir -p src; printf 'export const a: any = 1; // BAN-OK(BN-02): another ban\n' > src/bn01.ts; }

# ---- AA1: Y1 §7 items 1, 2 and 6 - the LAYER probe, the env contract, the alignment ------------
# Y1 §7 named eighteen documented mechanisms with no control; Z1 fixed 2 and closed 2, and its
# own note said "a later wave that wants more controls should start with items 1, 2 and 6, which
# are the cluster with a real engine underneath". These are those three. Helpers rather than
# copies, because every case needs the same `layers:` pair and an entry appended to the
# `bans_exempt:` key the installer wrote.
add_layers() { printf '\nlayers:\n  - src/renderer src/main\n' >> .goblin/goblin.yaml; mkdir -p src/renderer src/main; }
add_exempt() { awk -v v="$1" '{ if ($0 ~ /^bans_exempt:/) { print; print "  - " v; next } print }' .goblin/goblin.yaml > .goblin/goblin.yaml.n && mv .goblin/goblin.yaml.n .goblin/goblin.yaml; }
# item 1 - `bans_exempt:` honoured by the LAYER probe. This is bans/layer-check.sh, a different
# file from grep-ban.sh, which is the only probe the five W5-1/W5-2 controls above reach; and it
# is the sibling of the probe whose regression (a documented escape that produced a permanent
# RED) started this chain. The crossing import sits INSIDE the exempted path...
m_bn_05_exempt()      { add_layers; mkdir -p src/renderer/legacy; printf "import { db } from '../../main/db';\nexport const r = db;\n" > src/renderer/legacy/p.ts; add_exempt "BN-05 src/renderer/legacy"; }
# ...and the SAME violation with the exemption naming another path still counts. Without this
# half, a probe that exempted everything would pass the first one.
m_bn_05_exempt_else() { add_layers; mkdir -p src/renderer/legacy; printf "import { db } from '../../main/db';\nexport const r = db;\n" > src/renderer/legacy/p.ts; add_exempt "BN-05 src/renderer/app"; }
# item 6, both directions: an exempt prefix covers its OWN subtree, and it does not swallow a
# sibling whose name merely starts with it (`src/ok` vs `src/okay`).
m_bn_05_exempt_subtree() { add_layers; mkdir -p src/renderer/ok; printf "import { db } from '../../main/db';\n" > src/renderer/ok/a.ts; add_exempt "BN-05 src/renderer/ok"; }
m_bn_05_exempt_align()   { add_layers; mkdir -p src/renderer/ok src/renderer/okay; printf "import { db } from '../../main/db';\n" > src/renderer/ok/a.ts; printf "import { db } from '../../main/db';\n" > src/renderer/okay/y.ts; add_exempt "BN-05 src/renderer/ok"; }
# ...and the documented form needs no trailing slash: `src/legacy/` strips nothing, so it matches
# no file and exempts nothing (a prefix is compared as written).
m_bn_05_exempt_slash()   { add_layers; mkdir -p src/renderer/legacy; printf "import { db } from '../../main/db';\n" > src/renderer/legacy/q.ts; add_exempt "BN-05 src/renderer/legacy/"; }
# item 2 - the engine->probe env contract itself, which nothing in tests/ has ever asserted
# (`grep -c GOBLIN_BANS_EXEMPT tests/` = 0). The detect column is replaced by a probe a PROJECT
# could write: it exits 0 only when the engine put BOTH GOBLIN_BANS_ID and GOBLIN_BANS_EXEMPT in
# its environment. The exemption supplies the prefix, so with it the probe passes; with none
# declared the same probe FAILs, which is the half that proves the value is config-driven and not
# ambient.
m_bn_01_probe_env()      { set_bn01_probe; mkdir -p src; printf 'export const a: number = 1;\n' > src/clean.ts; add_exempt "BN-01 src"; }
m_bn_01_probe_env_none() { set_bn01_probe; mkdir -p src; printf 'export const a: number = 1;\n' > src/clean.ts; }
set_bn01_probe() { awk -F'\t' -v OFS='\t' '{ if ($1 == "BN-01") $4 = "test \"$GOBLIN_BANS_ID\" = BN-01 && test \"$GOBLIN_BANS_EXEMPT\" = src"; print }' .goblin/manifest/bans.tsv > .goblin/manifest/bans.tsv.n && mv .goblin/manifest/bans.tsv.n .goblin/manifest/bans.tsv; }

m_skill_frontmatter() { sed -i '1d' .hermes/skills/goblin-mode/SKILL.md; }
m_skill_drift()   { printf '\n<!-- drift -->\n' >> .hermes/skills/goblin-mode/SKILL.md; }
m_adv_ceiling()   { sed -i 's/^advisory_ceiling: .*/advisory_ceiling: 7/' .goblin/goblin.yaml; }
# V1/G8-5: a ceiling that is not a number made `[ n -le ten ]` return 2, and the runner reads 2
# as ADV - so the cap silently stopped capping and the run still exited 0. It is a FAIL now.
m_adv_ceiling_bad() { sed -i 's/^advisory_ceiling: .*/advisory_ceiling: ten/' .goblin/goblin.yaml; }

# ---- the automation rows (G3): AU-01..AU-04, SK-04 -------------------------------------------
# These five rows are NEW, so there is no pre-change tree for their controls: what the control
# proves is that the rule bites on a real violation, and that the row is wired into the runner.
# The wiring proof is IN-03/PR-03's enumeration plus one control per row here.
m_au_01()         { printf '\ncurl https://example.invalid/thing\n' >> .goblin/automations/drift-audit.sh; }
m_au_02()         { mkdir -p reports/fixture; printf 'repo: .\nsymptom: the panel shows the wrong total\ndedup_key: bug:.:2026-09-24\n' > reports/fixture/report.yaml; }
m_au_03()         { mkdir -p reports/fixture; printf 'stray\n' > stray.txt; }
m_au_04()         { sed -i 's|^## Write surface$|## Surface|' .hermes/skills/goblin-drift-audit/SKILL.md; }
m_sk_04()         { sed -i 's|^## What this cannot see$|## Not seen|' .hermes/skills/goblin-drift-audit/SKILL.md; }

# The tenant string is built at run time. A literal here would be the repo's only tenant hit
# (measured at f23b371: 1 repo-wide, 0 at b100b44) and PT-01, the rule that exists to catch
# exactly that, does not scan tests/ - so the control was the leak it was meant to catch (F2-5).
# $HOME expands to the same /home/<user>/projects the rule matches.
m_tenant_leak()   { printf '\nsee %s/projects for the tenant list\n' "$HOME" >> .hermes/skills/goblin-mode/SKILL.md; }
m_wrong_branch()  { sed -i 's/^branch: main/branch: trunk/' .goblin/goblin.yaml; }

m_archive_flip()  { sed -i 's/^archive: false/archive: true/' .goblin/goblin.yaml; }

# ---- the class-B fixture: CL-01's "the class forbids this part" branch (D10) ----
# Class B turns tokens off, so the installer records it in disabled:. Before the fix the
# opt-out branch returned before the '-' branch, so a tokens file in a class-B repo passed as
# "opt-out". (reviews/ cannot be the mutation: pr-gate and review-panel share that artifact, and
# review-panel was the one '-' part the installer never pre-disabled, so the run went RED for
# the wrong reason.) The R branch of CL-01 is covered by t-install-off-switch.sh.
mkdir -p "$TARGET_B" && cd "$TARGET_B"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# targetB\n' > README.md
git add -A && git commit -q -m "chore: seed"
bash "$SRC/bin/goblin-install" --target "$TARGET_B" --class B --models "$WORK/models.yaml" >/dev/null 2>&1
git add -A && git commit -q -m "chore: install gobstack (class B)"
cd "$TARGET"
m_b_tokens() { printf 'a_part_class_B_turns_off: true\n' > .goblin/tokens.yaml; }
restore_b()  { rm -f .goblin/tokens.yaml; rm -rf .github; }
# W4: ci-gate is `-` for class B, so the workflow goblin-stack writes elsewhere must be ABSENT
# here. CL-01 keys off the exact path, not the directory, so a class-B repo is still allowed to
# carry CI of its own - which is why this control plants goblin-stack's own filename.
m_b_workflow() { mkdir -p .github/workflows; printf 'jobs:\n  gate:\n    steps:\n      - run: echo hi\n' > .github/workflows/goblin-gate.yml; }

# ---- the 82 target-scope rows, in manifest order ------------------------------
expect_red "a manifest with no version"            IN-01 1 m_in_01
expect_red "one edited byte of the standard"       IN-02 1 m_edit_practice
expect_red "a manifest row with no check"          IN-03 3 m_blank_row
# Z1-5: the third clause. A typo in `enforced_by` used to change NO verdict in the whole run -
# the enum was documented as closed in docs/ENFORCEMENT.md and read by nothing.
expect_red "Z1-5: an enforced_by outside the closed enum" IN-03 1 m_bad_enum
expect_red "a pre-existing file the install recorded has vanished" IN-04 1 m_in_04

expect_red "a missing HANDOFF"                     HP-01 1 m_drop_handoff
expect_red "a required HANDOFF heading demoted"     HP-02 1 m_drop_heading
expect_red "a gate number with no measured date"   HP-03 1 m_no_date
# V1/G8-2: the row used to be satisfied by the template's own example sentence, so the REAL gate
# line could lose its `measured <date>` and the row stayed GREEN. Two controls pin the two
# directions, and neither is green on both trees: the first is RED at 43f7f69 as a control (the
# old row returned PASS where the control wants exit 1), the second is RED there too (the old row
# returned FAIL where the control wants exit 0). Both transcripts are in V1.md.
expect_red   "G8-2: the REAL gate line loses its date while the example keeps its" HP-03 1 m_no_date_real
expect_green "G8-2: the template's example line loses its date (prose is not a gate number)" HP-03 m_no_date_example
expect_red "HP-04 (advisory row: wired, not biting)" HP-04 1 m_hp_04
expect_red "a HANDOFF naming no commit in the repo" HP-05 1 m_no_head

# ---- F4's controls for the two rows whose bodies moved ---------------------------------------
# The five required sections become slots (first word of an H2/H3, closed alias set) and HP-03 is
# scoped to the Gates section. Two of these assert the new leniency (a HANDOFF the old rows
# rejected is correct), two assert the new strictness (a violation the old rows let through).
expect_red   "F4: the only 'State' is a heading that merely contains the word" HP-02 1 m_phantom_state
expect_green "F4: 20 historical undated gate lines outside the dated Gates section" HP-03 m_hist_lines
expect_green "F4: the repo's own vocabulary (Status, Gate, NEXT, Pending ...)" HP-02 m_alias_vocab
expect_red   "F4: a Gates section carrying no gate-bearing line" HP-03 1 m_no_gate_line

expect_red "no SPEC"                               SP-01 1 m_drop_spec
expect_red "an untracked SPEC"                     SP-02 1 m_untracked_spec
expect_red "an AC that is a feeling, not a check"  SP-03 1 m_feely_ac

expect_red "no gate declared"                      GT-01 1 m_no_gates
# G8-3: the third condition of G8's own 9/10 sentence - "G8-3's parser made to fail loudly".
# Each of the three forms is RED at 72490f0, where GT-01 reported the surviving gate(s).
expect_red "G8-3: a declared gate whose cmd line was deleted"    GT-01 1 m_gate_no_cmd
expect_red "G8-3: a declared gate whose cmd line was re-indented" GT-01 1 m_gate_indent_cmd
expect_red "G8-3: a declared gate whose cmd value was blanked"   GT-01 1 m_gate_blank_cmd
expect_red "a gate that exits non-zero"            GT-02 1 m_break_gate
expect_red "no measured gate line"                 GT-03 1 m_drop_gate_line
expect_red "a ratchet with no name"                GT-04 1 m_no_ratchet
expect_red "the ratchet above its ceiling"         GT-05 1 m_ratchet_rise
# G4 D2 moved the TODO count out of the ratchet and into a gate. One control for the row that
# still holds it, so the move is measured rather than asserted.
expect_red "the TODO ceiling gate, moved from the ratchet" GT-02 1 m_todo_gate

expect_red "a declared harness dir that is absent"  HS-01 1 m_no_harness_dir
expect_red "a harness green on both trees"         HS-02 1 m_green_harness
# Z1-4: the declared command has to be what RUNS the harness. Two halves - the GREEN one proves
# the row is not always-red when the command is the shipped one, the RED one is `replay.cmd:
# false`. `false` interpolates no `{name}`, so it cannot be running the harness it names and
# nothing was replayed; the row FAILs instead of reporting "every harness was RED" from a command
# that never ran one.
expect_green "a harness set RED on the pre-change tree, run as the declared command" HS-02 m_replay_all_red
expect_red   "Z1-4: a replay.cmd that interpolates no {name}"                       HS-02 1 m_replay_cmd_false
# Z2-3: the name is shell-quoted before it is substituted into the declared command. This control
# is the measurement - unquoted, the name split and the row reported the file GREEN pre-change (rc
# 1, measured on 846c132's verifier); quoted, the name is ONE argument and the row passes.
expect_green "Z2-3: a harness file name carrying shell metacharacters reaches node as ONE argument" HS-02 m_replay_meta_name
expect_red "HS-03 (advisory row: wired, not biting)" HS-03 1 m_hs_03

expect_red "an ambient commit author"              CM-01 1 m_bad_author
expect_red "CM-02 (advisory row: wired, not biting)" CM-02 1 m_cm_02
expect_red "an uncommitted file"                   CM-03 1 m_dirty_tree

expect_red "a hardcoded model name"                MD-01 1 m_model_leak
expect_red "MD-02 (advisory row: wired, not biting)" MD-02 1 m_md_02
expect_red "MD-03 (advisory row: wired, not biting)" MD-03 1 m_md_03

expect_red "a review naming no real SHA"           PG-01 1 m_review_no_sha
expect_red "a review with an unknown stakes tier"  PG-02 1 m_bad_stakes
expect_red "a review with a wrong patch-id"        PG-03 1 m_bad_review
expect_red "PG-04 (advisory row: wired, not biting)" PG-04 1 m_pg_04
# W4/G6: re-declared PG-05. The old body counted "every step is guarded", so the four shapes
# below all PASSED it. Measured on the pre-change tree: see W4.md section 3.
expect_red   "a self-skipping workflow (every step guarded)"   PG-05 1 m_self_skip_wf
expect_red   "G8's hole: a JOB-level if: makes every step self-skip" PG-05 1 m_job_if_wf
expect_red   "a job that declares no step at all"              PG-05 1 m_nosteps_wf
expect_red   "a workflow with no jobs to run"                  PG-05 1 m_nojobs_wf
expect_red   "the real shape: one UNGUARDED step decides whether the gate step runs" PG-05 1 m_decider_wf
expect_green "a commented-out if: is not a conditional gate"    PG-05 m_wf_comment_if
# W4/G6: PG-06 - the gate CI runs is the gate the project declares. One control per clause, plus
# the SKIP half: nothing to compare is reported as a reason, never as a pass.
expect_green "the installed workflow runs the declared gate set" PG-06 m_wf_nothing
expect_red   "a workflow that runs npm test instead"            PG-06 1 m_wf_npm_test
expect_red   "the verifier called with --only (a different truth for the same SHA)" PG-06 1 m_wf_only
expect_red   "the verifier call commented out"                  PG-06 1 m_wf_commented
expect_green "each declared gate command run verbatim"          PG-06 m_wf_verbatim
expect_green "no workflow at all -> PG-06 skips with a reason"   PG-06 m_wf_none

expect_red "a runtime_data path that is git-tracked" DS-01 1 m_tracked_runtime
expect_red "no DS-01 snapshot to verify"           DS-02 1 m_drop_ds_report

expect_red "DOC-01 (advisory row: wired, not biting)" DOC-01 1 m_doc_01
expect_red "DOC-02 (advisory row: wired, not biting)" DOC-02 1 m_doc_02

expect_red "a skill with no frontmatter"           SK-01 1 m_skill_frontmatter
expect_red "an edited installed skill"             SK-02 1 m_skill_drift
expect_red "the advisory cap evaded by a builtin"  SK-03 1 m_adv_ceiling
expect_red "an advisory ceiling that is not a number" SK-03 1 m_adv_ceiling_bad
expect_red "a shipped skill with no cannot-see section" SK-04 1 m_sk_04

expect_red "a tenant string in an installed rule"  PT-01 1 m_tenant_leak
expect_red "the declared branch is wrong"          PT-02 1 m_wrong_branch

expect_red "an automation producer with a network verb" AU-01 1 m_au_01
expect_red "a dedup key outside the content-only form"  AU-02 1 m_au_02
expect_red "a reporter leaving the tree dirty"          AU-03 1 m_au_03
expect_red "an automation skill with no write surface"  AU-04 1 m_au_04

expect_red "a tracked dotenv-family file"           SC-01 1 m_sc_01
expect_red "an ignore rule narrowed to .env.* only" SC-02 1 m_sc_02
expect_red "a client-visible secret-shaped name"    SC-03 1 m_sc_03
# W5-11: the informative line printed a CHARACTER count as a hit count (`${#hits}` on a multiline
# string), so ONE matching line was reported as "the length of that line client-visible
# secret-shaped name(s)". The half-done fix left these two lines behind.
m_sc_03
out=$(bash .goblin/bin/goblin-verify --only SC-03 2>&1)
printf '%s' "$out" | grep -q '1 client-visible secret-shaped name(s)'
check "W5-11: SC-03 reports ONE hit, not the character count of the matching line" "$?"
restore_all
expect_red "a JS cookie write with no flags"        SC-04 1 m_sc_04
expect_red "a write route with no validator"        SC-05 1 m_sc_05
expect_red "a manifest with no lockfile"           SC-06 1 m_sc_06
expect_red "an audit record nobody re-took"        SC-07 1 m_sc_07
expect_red "an install hook nobody decided on"     SC-08 1 m_sc_08
# Z2-2: the same hook in a ONE-LINE lockfile. It used to print `0 install hook(s), 0 allowlisted`
# and exit 0 - a vacuous PASS, the defect family this harness exists to prevent; the reader now
# normalises the text into the pretty shape, and the allowlisted half proves the fix is not "any
# minified lock FAILs".
expect_red   "Z2-2: the same unlisted hook in a MINIFIED (one-line) lockfile"   SC-08 1 m_sc_08_minified
expect_green "Z2-2: the same hook ALLOWLISTED in a minified lockfile passes"    SC-08 m_sc_08_minified_ok
expect_red "SC-09 (advisory row: wired, not biting)" SC-09 1 m_sc_09
expect_red "a perf baseline naming no real commit" PF-01 1 m_pf_01
expect_green "G8-6b: the ceiling matches the recorded baseline"        PF-01 m_pf_ceiling_match
expect_red   "G8-6b: the ceiling raised by hand, the baseline untouched" PF-01 1 m_pf_ceiling_raise

# ---- G5: the ban list is a gate, not a wish - one control per row -----------------------------
expect_red   "the ban table loses a row the matrix still names" BN-00 1 m_bn_00_orphan
expect_red   "a ban that names no replacement"                  BN-00 1 m_bn_00_norepl
expect_red   "an any type in application TypeScript"               BN-01 1 m_bn_01
expect_red   "V3-2: a ban violated by exit code alone (no stdout)"  BN-01 1 m_bn_exit1_detect
# W5-12: a defanged probe is INVISIBLE to the ban lane - with `BN-01`'s detect set to `true`, BN-00
# and BN-01 both PASS (measured). Z1's decision is to keep that as RECORDED, because the row that
# can see it is the drift guard over the table itself: this control pins the guard that actually
# holds. BN-00's own why-cell and docs/LIMITS.md #28 name the limitation.
expect_red   "W5-12: a defanged ban probe is caught by the drift guard, one row over" IN-02 1 m_bn_defang
# ---- Y1 §7 items 4 and 5: the ban ENGINE's own contract, closed here --------------------------
# Z1's census (docs/LIMITS.md #41) records the documented mechanisms with no control. Two are
# closeable from this fixture and are closed: the engine's `exit 2` (a table it cannot read must
# FAIL CLOSED, never report a clean lane) and `--list`. Neither had any control before -
# `grep -c goblin-bans tests/` was 0 invocations, only `ls`/`grep` over the file. PR-03's second
# branch applies rather than the pre-change tree: the mechanism WORKED before (that is why the
# census calls it "verified working, control missing"), so the RED direction is a deliberately
# broken copy of the engine - its table made unreadable (the missing-table path) and its `--list`
# output emptied - which is what turns each of these three assertions red.
BANS=.goblin/bin/goblin-bans
out=$($BANS --list 2>&1); rc=$?
printf '%s' "$out" | grep -q '^BN-01' && [ "$rc" -eq 0 ]
check "Y1-§7 item 5: --list prints the table (BN-01 named)" "$?"
mv .goblin/manifest/bans.tsv "$WORK/bans.tsv.parked"
out=$($BANS 2>&1); rc=$?
printf '%s' "$out" | grep -qi 'no ban table' && [ "$rc" -eq 2 ]
check "Y1-§7 item 4a: a missing ban table is exit 2, not a silent pass" "$?"
printf 'id\tscope\tban\tdetect\n' > .goblin/manifest/bans.tsv
out=$($BANS 2>&1); rc=$?
printf '%s' "$out" | grep -qi 'holds no bans' && [ "$rc" -eq 2 ]
check "Y1-§7 item 4b: an empty ban table is exit 2, not a silent pass" "$?"
mv "$WORK/bans.tsv.parked" .goblin/manifest/bans.tsv
expect_red   "a ts-expect-error suppression"                 BN-02 1 m_bn_02
expect_red   "a fetch() called from a component"                BN-03 1 m_bn_03
expect_red "an import across a declared layer boundary"       BN-05 1 m_bn_05
# BN-05 is a SKIP (not a FAIL) when no layers are declared - the HS-01 precedent: nothing to
# read is reported as a reason, never as a pass.
expect_green "no layers declared -> BN-05 skips with a reason"  BN-05 m_bn_05_nolayers
# W4/G6: the Electron surface, one control per row, plus the SKIP half. A new row has no
# pre-change tree to be RED on, so PR-03's other branch applies: the mutation is the deliberately
# broken copy (a renderer with the key set) and the SKIP control proves the row is not
# always-red.
expect_red   "a renderer with nodeIntegration: true"            BN-06 1 m_bn_06
expect_green "an unlisted electron ban skips with a reason"     BN-06 m_bn_06_unlisted
expect_red   "a renderer with contextIsolation: false"          BN-07 1 m_bn_07
expect_red   "a renderer with webSecurity: false"               BN-08 1 m_bn_08
expect_red   "a synchronous IPC call in a hot path"             BN-09 1 m_bn_09

# ---- W5-1/W5-2: both documented escapes, both directions --------------------------------------
# The exempt path must PASS with a real violation inside it, and the SAME violation must still
# FAIL when the exception names another path. That pair is the control whose absence let W5-1 ship.
expect_green "W5-1: a bans_exempt path holding a real violation PASSES"      BN-01 m_bn_01_exempt
expect_red   "W5-1: the same violation outside the exempt path still FAILs"  BN-01 1 m_bn_01_exempt_else
expect_green "W5-2: inline BAN-OK(<id>): <reason> clears the offending line" BN-01 m_bn_01_banok
expect_red   "W5-2: a BAN-OK with no reason is not an escape"                BN-01 1 m_bn_01_banok_noreason
expect_red   "W5-2: a BAN-OK naming another ban does not clear this one"     BN-01 1 m_bn_01_banok_other

# ---- AA1: Y1 §7 items 1, 2 and 6 - the direct controls for the ban cluster --------------------
# LIMITS #41 recorded these three as exercised only INDIRECTLY, and `grep -c GOBLIN_BANS_EXEMPT
# tests/` was 0: the five W5-1/W5-2 controls above all drive BN-01, i.e. grep-ban.sh. Item 1 is a
# different file (bans/layer-check.sh), item 2 is the contract between the engine and ANY probe a
# project writes, and item 6 is the predicate both shipped probes implement. PR-03's second branch
# applies rather than the pre-change tree - Y1 measured each of the three WORKING, which is why the
# census calls them "verified working, control missing", so the RED direction is a deliberately
# broken copy of the module under test; each has one below, and the measurement is in AA1.md.
#
# item 1: the crossing import is inside the exempted path, and reaches the LAYER probe.
expect_green "AA1 §7-1: bans_exempt is honoured by the LAYER probe (not only grep-ban)" BN-05 m_bn_05_exempt
expect_red   "AA1 §7-1: the same crossing import outside the exempt path still FAILs"   BN-05 1 m_bn_05_exempt_else
# item 6, both directions: the prefix covers its own subtree; `src/ok` does not swallow `src/okay`.
expect_green "AA1 §7-6: an exempt prefix covers its own subtree"                        BN-05 m_bn_05_exempt_subtree
expect_red   "AA1 §7-6: an exempt src/ok does not swallow a violation in src/okay"      BN-05 1 m_bn_05_exempt_align
# The alignment claim is about WHICH line survives the filter, not only about the exit code, so it
# is asserted on the reported line as well: the exempted hit is dropped, the sibling's is printed.
m_bn_05_exempt_align
out=$(bash .goblin/bin/goblin-verify --only BN-05 2>&1)
printf '%s' "$out" | grep -q 'src/renderer/okay/y.ts'; hit=$?
printf '%s' "$out" | grep -q 'src/renderer/ok/a.ts' && hit=1
check "AA1 §7-6: the exempt subtree's hit is dropped, the sibling's is the one reported" "$hit"
restore_all
# ...and a prefix written with a TRAILING SLASH strips nothing, so it exempts nothing.
expect_red   "AA1 §7-6: a prefix written with a trailing slash exempts nothing"         BN-05 1 m_bn_05_exempt_slash
# item 2: a probe of the project's own reading both variables out of its environment. The engine
# has to put them there - with the exemption declared the probe passes, with none declared the SAME
# probe fails, which is the half that proves the value comes from the config and not from ambient
# state.
expect_green "AA1 §7-2: the engine hands the probe GOBLIN_BANS_ID and GOBLIN_BANS_EXEMPT" BN-01 m_bn_01_probe_env
expect_red   "AA1 §7-2: with no exemption declared the probe sees an EMPTY GOBLIN_BANS_EXEMPT" BN-01 1 m_bn_01_probe_env_none

# ---- G1: the feature map (FM-01, FM-02) and the generated skill's doctor (VA-01) --------------
# P6 authors the map (skills/goblin-feature-map); FM-01 is the entry contract + index hygiene,
# FM-02 the source tripwire, VA-01 the declared doctor. All three are NEW rows, so there is no
# pre-change tree to be RED on: PR-03's other branch is "a deliberately broken copy of the module
# under test", which is what these mutations are. The map is SEEDED first - a contract map that
# passes both FM rows, which is the half of the control that proves the rows are not always-red -
# and then one clause is broken at a time.
#
# The empty-config case is asserted first, because it is the state every fresh install is in: a
# declared value that is empty must report SKIP with its own reason, never a vacuous PASS (the
# shape PROJECT-PRACTICE section 3 calls out and PG-01..PG-03 still have).
MAPDIR=".hermes/skills/verify-fix/features"
FM_SRC="src/panel/index.ts"
plant_map() {
  mkdir -p "$MAPDIR" "$(dirname "$FM_SRC")"
  printf 'panel-root\n' > "$FM_SRC"
  cat > "$MAPDIR/README.md" <<'MAPEOF'
# Features

## Baseline preconditions
- the app builds

## Driving conventions
- literal commands only

## Proof and skip reporting
- a skip names the feature id and the entry point

## Features
- [Panel](./panel.md) covers the side panel
MAPEOF
  cat > "$MAPDIR/panel.md" <<MAPEOF
---
feature: panel
entry_paths:
  - panel-root
verified: $(date +%F)
---
# Panel
The panel shows the total for the current selection.

## Sub-features
- the running total

## How to get to it (user POV)
- open the app and select a row

## Driving it with node
Preconditions: the app is built.
Select a row. Run \`node -e 'process.stdout.write("1")'\`. The total updates.

## Gotchas
- a row with no children shows no total
MAPEOF
  sed -i "s|^feature_map: .*|feature_map: $MAPDIR/README.md|" .goblin/goblin.yaml
  git add -A >/dev/null 2>&1; git commit -q -m "test: seed the feature map" >/dev/null 2>&1
}
# Every mutation below seeds the map first and then breaks exactly one clause.
m_fm_plant()        { plant_map; }
m_fm_01_unindex()   { plant_map; sed -i '/^- \[Panel\](\.\/panel\.md)/d' "$MAPDIR/README.md"; }
m_fm_01_dangling()  { plant_map; printf -- '- [Gone](./gone.md) covers nothing\n' >> "$MAPDIR/README.md"; }
m_fm_01_h2()        { plant_map; sed -i 's/^## Gotchas$/### Gotchas/' "$MAPDIR/panel.md"; }
m_fm_01_slug()      { plant_map; sed -i 's/^feature: panel$/feature: sidebar/' "$MAPDIR/panel.md"; }
m_fm_02_token()     { plant_map; printf 'route-renamed\n' > "$FM_SRC"; }
m_fm_02_stale()     { plant_map; sed -i 's/^verified: .*/verified: 2020-01-01/' "$MAPDIR/panel.md"; }
# W5-4: the STUB map. `entry_paths` naming a token that occurs only inside the harness (this one
# occurs in .goblin/bin/goblin-verify and nowhere else in the fixture) passed both FM rows before
# the fix, because `source_root: .` walked the install: the map merely echoed the template. The
# token has to be one the harness demonstrably holds - the control below is measured, not assumed.
m_fm_02_stub()      { plant_map; sed -i 's|^  - panel-root$|  - g_yaml_block_scalar|' "$MAPDIR/panel.md"; }
# Z1-6: the resolved file is UNTRACKED. `git log -1 --format=%cs` prints nothing for a file git
# cannot date, and the freshness clause used to skip on that empty string - so a map could claim
# `verified: 2020-01-01` and PASS. The token is moved to a file created AFTER plant_map's commit,
# so it is the only source occurrence (the map's own directory is excluded from the search).
m_fm_02_untracked() { plant_map; printf 'untracked-panel-root\n' > src/panel/late.ts; \
                      sed -i 's|^  - panel-root$|  - untracked-panel-root|' "$MAPDIR/panel.md"; \
                      sed -i 's|^verified: .*|verified: 2020-01-01|' "$MAPDIR/panel.md"; }
m_va_01_fail()      { sed -i 's|^verify_doctor: .*|verify_doctor: false|' .goblin/goblin.yaml; }

# The empty config is the fresh-install state: each row SKIPs (the builtin returns 3, which the
# runner counts as a SKIP; the process still exits 0 - only FAIL or a broken manifest exits
# non-zero), and the reason names WHY.
for pair in "FM-01:no map is declared" "FM-02:no entry paths to resolve" "VA-01:no doctor is declared"; do
  rid=${pair%%:*}; want=${pair#*:}
  out=$(bash .goblin/bin/goblin-verify --only "$rid" 2>&1); rc=$?
  printf '%s' "$out" | grep -q "^SKIP  $rid.*$want"; hit=$?
  check "$rid with an empty config SKIPs with its reason (not a vacuous pass)" \
    "$([ "$rc" -eq 0 ] && [ "$hit" -eq 0 ] && echo 0 || echo 1)"
done

# The fixture is GREEN again after the last of these: every mutation is reverted by restore_all,
# which also removes the seeded map (nothing below is measured against a planted tree).
expect_green "a seeded feature map passes FM-01"  FM-01 m_fm_plant
expect_red   "a feature file that is not indexed" FM-01 1 m_fm_01_unindex
expect_red   "an index link that does not resolve" FM-01 1 m_fm_01_dangling
expect_red   "an entry H2 demoted to H3"           FM-01 1 m_fm_01_h2
expect_red   "a feature: that is not the filename stem" FM-01 1 m_fm_01_slug
expect_green "a seeded feature map resolves under source_root" FM-02 m_fm_plant
expect_red   "a declared entry path renamed in source"  FM-02 1 m_fm_02_token
# W5-4: the stub map. RED before the fix too - `source_root: .` resolved the token against the
# install, so the map passed while naming nothing in source.
expect_red   "W5-4: a stub map whose token occurs only in the harness" FM-02 1 m_fm_02_stub
expect_red   "an entry path changed after the map was verified" FM-02 1 m_fm_02_stale
# Z1-6: an entry path that resolves only to a file git does not track. The freshness clause used
# to SKIP when `git log -1 --format=%cs` printed nothing, so `verified: 2020-01-01` passed over
# source that was never committed. "Resolves" must not imply "is tracked".
expect_red   "Z1-6: an entry path only an untracked file holds" FM-02 1 m_fm_02_untracked
expect_red   "a verify_doctor that exits non-zero" VA-01 1 m_va_01_fail
# ---- G2: the judge role and the loop contract (JG-01..JG-03, LP-01..LP-05) --------------------
# All eight rows are NEW, so there is no pre-change tree to be RED on: PR-03's other branch is "a
# deliberately broken copy of the module under test", which is what these mutations are. A LOOP
# RECORD is seeded first - one that passes JG-01 and all five LP rows, which is the half of the
# control that proves the rows are not always-red - and then one clause at a time is broken.
#
# The empty state is asserted first, because it is the state every fresh install is in: with no
# .goblin/loop/ the six loop-dependent rows must report SKIP with their reason, never a vacuous
# PASS (the PG-01..PG-03 shape). JG-02 is the exception by design: it reads roles.yaml and the
# mapping file, so a lane that resolves to no provider/model is an ADV with its one-line remedy,
# and that is asserted in t-verify-green.sh (ADV, exit 0).
LOOP=".goblin/loop"
plant_loop() {
  mkdir -p "$LOOP"
  printf '# the loop exit condition: exit 0 == the loop is finished\ntest -f .goblin/loop/done\n' > "$LOOP/predicate"
  sha256sum "$LOOP/predicate" | awk '{print $1}' > "$LOOP/predicate.sha256"
  printf 'exit=1 ts=2026-09-25T00:00:00Z\n' > "$LOOP/first-run"
  printf '12\n' > "$LOOP/budget"
  printf 'ts\tphase\tdecision\twhy\tevidence\tresult\n' > "$LOOP/decisions.tsv"
  printf '2026-09-25T00:10:00Z\tcheck\tverdict:continue\tthe marker file is not there yet\tsha:%s\tpredicate:red\n' \
    "$(git rev-parse HEAD)" >> "$LOOP/decisions.tsv"
  printf '2026-09-25T00:20:00Z\tcheck\tverdict:done\tthe marker exists and the gate is green\tfile:README.md\tpredicate:green\n' \
    >> "$LOOP/decisions.tsv"
}
# JG-02's own green: a `judge` lane beside the code lane in the mapping file. The fixture's
# mapping file has no judge profile, which is the ADV state every install starts in.
plant_judge_lane() {
  printf '  judge:\n    model: model-judge\n    provider: prov-judge\n    effort: high\n' >> "$WORK/models.yaml"
}
m_loop_plant()   { plant_loop; }
m_jg_02_ok()     { plant_judge_lane; }
# The judge is the author: role-judge resolves to the code lane's own profile. A FAIL, not an ADV -
# the declared lanes are visible to a repo, which is the whole point of the row.
m_jg_02_shared() { plant_judge_lane; sed -i 's/^  profiles: \[judge\]$/  profiles: [coder]/' .goblin/roles.yaml; }
# A verdict resting on a command that ran: `cmd:` resolves NOTHING by design, because the command's
# output is not in the record and a verdict resting on it is the self-report the row refuses.
m_jg_01_cmd()    { plant_loop; sed -i "s|sha:$(git rev-parse HEAD)|cmd:npm test|" "$LOOP/decisions.tsv"; }
# A handle of the right SHAPE that names nothing: 40 hex, no such commit in `git rev-list --all`.
m_jg_01_ghost()  { plant_loop; sed -i "s|sha:$(git rev-parse HEAD)|sha:deadbeefdeadbeefdeadbeefdeadbeefdeadbeef|" "$LOOP/decisions.tsv"; }
m_jg_03_wired()  { m_row_fails JG-03; }
m_lp_01_two()    { plant_loop; printf 'test -f README.md\n' >> "$LOOP/predicate"; }
m_lp_01_late()   { plant_loop; printf 'exit=1 ts=2026-09-25T00:30:00Z\n' > "$LOOP/first-run"; }
m_lp_01_norun()  { plant_loop; rm -f "$LOOP/first-run"; }
m_lp_02_repin()  { plant_loop; printf '# relaxed by hand\n' >> "$LOOP/predicate"; }
# W5-7: the close-and-reopen path. A loop archives its bar under closed-<date>/, writes a weaker
# one and re-pins - and before the fix LP-02 and LP-05 both PASSED with nothing in the record.
# Three controls: the silent version must FAIL, the RECORDED version must pass (the half that
# proves the clause is not always-red), and a stub archive must FAIL.
m_lp_02_reopen_silent() {
  plant_loop
  mkdir -p "$LOOP/closed-2026-09-24"
  cp "$LOOP/predicate" "$LOOP/closed-2026-09-24/predicate"
  cp "$LOOP/predicate.sha256" "$LOOP/closed-2026-09-24/predicate.sha256"
  printf '# the relaxed bar: any file will do\n' >> "$LOOP/predicate"
  sha256sum "$LOOP/predicate" | awk '{print $1}' > "$LOOP/predicate.sha256"
}
m_lp_02_reopen_recorded() {
  m_lp_02_reopen_silent
  printf 'previous: %s\n' "$(sha256sum "$LOOP/closed-2026-09-24/predicate" | awk '{print $1}')" >> "$LOOP/predicate.sha256"
}
m_lp_02_reopen_noarc() {
  plant_loop
  mkdir -p "$LOOP/closed-2026-09-24"
  cp "$LOOP/predicate" "$LOOP/closed-2026-09-24/predicate"
  printf '# the relaxed bar\n' >> "$LOOP/predicate"
  sha256sum "$LOOP/predicate" | awk '{print $1}' > "$LOOP/predicate.sha256"
}
m_lp_03_over()   { plant_loop; printf '21\n' > "$LOOP/budget"; }
m_lp_03_rows()   { plant_loop; printf '1\n' > "$LOOP/budget"; }
# The same pointer three times with no green: rows 2, 3 and 4 of the record. What the row measures
# is a CHANGED pointer, which is a proxy for progress - the why-cell says so.
m_lp_04_thrash() {
  plant_loop
  printf '2026-09-25T00:30:00Z\tcheck\tverdict:continue\tthe same pointer again\tfile:README.md\tpredicate:red\n2026-09-25T00:40:00Z\tcheck\tverdict:continue\tand again\tfile:README.md\tpredicate:red\n' \
    >> "$LOOP/decisions.tsv"
}
m_lp_05_nostuck() { plant_loop; sed -i 's|\tpredicate:green$|\tpredicate:stuck|' "$LOOP/decisions.tsv"; }
m_lp_05_short()   { m_lp_05_nostuck; printf 'the marker never appeared\nthe predicate is still red\n' > "$LOOP/stuck.md"; }

# The empty state: no loop has run here, so the six loop-dependent rows SKIP with their reason.
for pair in "JG-01:no loop record" "LP-01:no loop has run" "LP-02:no loop has run" \
            "LP-03:no loop has run" "LP-04:no loop has run" "LP-05:no loop has run"; do
  rid=${pair%%:*}; want=${pair#*:}
  out=$(bash .goblin/bin/goblin-verify --only "$rid" 2>&1); rc=$?
  printf '%s' "$out" | grep -q "^SKIP  $rid.*$want"; hit=$?
  check "$rid with no loop record SKIPs with its reason (not a vacuous pass)" \
    "$([ "$rc" -eq 0 ] && [ "$hit" -eq 0 ] && echo 0 || echo 1)"
done

expect_green "a seeded loop record passes JG-01 (a sha: handle that resolves)" JG-01 m_loop_plant
expect_red   "a verdict resting on a command that ran (cmd:)" JG-01 1 m_jg_01_cmd
expect_red   "a sha of the right shape that names no commit"  JG-01 1 m_jg_01_ghost
expect_green "a judge lane beside the code lane, disjoint"    JG-02 m_jg_02_ok
expect_red   "the judge lane IS the author lane"              JG-02 1 m_jg_02_shared
# ---- W5-6: the judge lane's model FAMILY ------------------------------------------------------
# JG-02 proves the declared profile NAMES are disjoint; a `judge:` profile mapped to the author's
# own model passed it, so the judge was distinct by name only. MD-02 now compares the judge lane's
# resolved model with the code lane's - and it stays ADVISORY either way (`ADV`, exit 0), because
# goblin-stack cannot choose the fleet's models. So the control reads the LINE, not the exit code:
# the same-family case must be named as such, and the different-family case must be too.
plant_judge()      { plant_judge_lane; }
plant_judge_same() { plant_judge_lane; awk '{ if ($0 ~ /^  judge:$/) { print; getline; print "    model: model-code"; next } print }' "$WORK/models.yaml" > "$WORK/models.yaml.n" && mv "$WORK/models.yaml.n" "$WORK/models.yaml"; }
plant_judge_same
out=$(bash .goblin/bin/goblin-verify --only MD-02 2>&1); rc=$?
printf '%s' "$out" | grep -q 'the SAME family as the code lane'; hit=$?
check "W5-6: a judge mapped to the author's own model is reported as the same family" \
  "$([ "$rc" -eq 0 ] && [ "$hit" -eq 0 ] && echo 0 || echo 1)"
restore_all
plant_judge
out=$(bash .goblin/bin/goblin-verify --only MD-02 2>&1); rc=$?
printf '%s' "$out" | grep -q 'judge lane model-judge, code lane model-code - different family'; hit=$?
check "W5-6: a judge on another model is reported as a different family" \
  "$([ "$rc" -eq 0 ] && [ "$hit" -eq 0 ] && echo 0 || echo 1)"
restore_all
expect_red   "JG-03 (advisory row: wired, not biting)"        JG-03 1 m_jg_03_wired
expect_green "a seeded loop record passes LP-01 (one command, run first)" LP-01 m_loop_plant
expect_red   "a predicate of two commands"                       LP-01 1 m_lp_01_two
expect_red   "a first run recorded AFTER the first log row"      LP-01 1 m_lp_01_late
expect_red   "no recorded first run at all"                      LP-01 1 m_lp_01_norun
expect_green "a seeded loop record passes LP-02 (the pin still matches)" LP-02 m_loop_plant
expect_red   "the predicate relaxed after the pin was taken"     LP-02 1 m_lp_02_repin
# W5-7: the close-and-reopen, recorded vs silent, plus a stub archive.
expect_red   "W5-7: a close-and-reopen that records nothing"     LP-02 1 m_lp_02_reopen_silent
expect_green "W5-7: the same re-scope with the archived digest named" LP-02 m_lp_02_reopen_recorded
expect_red   "W5-7: a closed loop whose archive holds no pin"    LP-02 1 m_lp_02_reopen_noarc
expect_green "a seeded loop record passes LP-03 (budget 12, 2 rows)" LP-03 m_loop_plant
expect_red   "a budget above loop_max_turns_ceiling"             LP-03 1 m_lp_03_over
expect_red   "more verdict rows than the declared budget"        LP-03 1 m_lp_03_rows
expect_green "a seeded loop record passes LP-04 (the pointer moved)" LP-04 m_loop_plant
expect_red   "three consecutive rows on one pointer, none green" LP-04 1 m_lp_04_thrash
expect_green "a seeded loop record passes LP-05 (the last row is green)" LP-05 m_loop_plant
expect_red   "a loop that ended not-green and left no write-up"  LP-05 1 m_lp_05_nostuck
expect_red   "a write-up shorter than three lines"               LP-05 1 m_lp_05_short

expect_red "a class-B repo carrying a part it forbids" CL-01 1 m_b_tokens "$TARGET_B" restore_b
expect_red "a class-B repo carrying the CI lane it forbids" CL-01 1 m_b_workflow "$TARGET_B" restore_b
# The complement, on class A: there `ci-gate` is `R`, so the SAME path being absent is the class
# contract violated. Both controls move one file in opposite directions, which is the point of
# keying the artifact on the path rather than on the `.github/` directory - each carries its own
# restore, because a control that leaves the tree changed makes the next one lie.
m_a_nowf()  { mv .github/workflows/goblin-gate.yml "$WORK/gg.bak"; }
restore_a() { mkdir -p .github/workflows; mv "$WORK/gg.bak" .github/workflows/goblin-gate.yml; }
expect_red "a class-A repo with the CI lane its class REQUIRES removed" CL-01 1 m_a_nowf "$TARGET" restore_a
expect_red "the archive waiver flipped by hand"    CL-02 1 m_archive_flip

# ---- P15: the reference-corpus rows, RC-01..RC-04 ------------------------------------------------
# Four rows over two DECLARED values (`reference_manifest:`, and the `security: build_output:` key
# SC-03 already owns - reused, never duplicated) and a lab repo's `manifests/`. The corpus payload
# lives OUTSIDE the fixture ($RP, under $WORK): a control that dropped a payload into the tree
# would dirty it for every control after it. The one control that DOES track a payload (NC-5)
# takes it back out of the index in r_rc03_git, because a staged file is exactly what it tests.
RP="$WORK/rcpayload.raw"
printf 'the reference corpus payload, byte-identical\n' > "$RP"
RP_HASH=$(sha256sum "$RP" | awk '{print $1}')
# rc_manifest <file>: a well-shaped `reference-manifest/1`, naming the corpus payload's real hash.
rc_manifest() {
  printf '{"schema":"reference-manifest/1","generated_from":"sha256sum over the quarantine","reference_app":{"package":"com.example.app","version":"1.0.9","apk_sha256":"%s"},"entries":[{"path":"refs/1.0.9/payloads/a/payload.raw","sha256":"%s","bytes":42}],"entry_count":1}\n' "$RP_HASH" "$RP_HASH" > "$1"
}
# Declare the corpus, and a build output this fixture does not otherwise have.
rc_declare() {
  sed -i 's|^  build_output: .*|  build_output: dist|' .goblin/goblin.yaml
  sed -i 's|^reference_manifest: .*|reference_manifest: reference-manifest.json|' .goblin/goblin.yaml
  rc_manifest reference-manifest.json
}
m_rc_key_empty() { sed -i 's|^reference_manifest: .*|reference_manifest:|' .goblin/goblin.yaml; }
# The declared-but-empty control: the corpus is declared and its manifest is well-shaped, but the
# fixture has no build output for RC-01 to scan - RC-01 must still exit 0 (nothing to check), and
# RC-02 must pass the well-shaped manifest. Declared as a function because expect_green invokes it.
m_rc_declare() { rc_declare; }
# RC-01 clause 3 (NC-1) and clause 4 (NC-2): a corpus payload inside the build output, then the
# manifest itself there. Same exit, two different clauses - the second is the corpus's own shape
# shipping, not one payload of it.
m_rc01_payload()       { rc_declare; mkdir -p dist; cp "$RP" dist/payload.raw; }
m_rc01_manifest_copy() { rc_declare; mkdir -p dist; cp reference-manifest.json dist/reference-manifest.json; }
# RC-01 clause 2 (NC-4): declared but gone, then declared but unreadable. FAIL, never a SKIP.
m_rc01_absent()        { rc_declare; rm -f reference-manifest.json; }
m_rc01_unparseable()   { rc_declare; printf 'not json at all\n' > reference-manifest.json; }
# RC-02 (NC-3), the vacuous-pass control: `entries` truncated to [] is what a "it parsed, ship it"
# check would pass. RC-02 must reject it AND RC-01 must still accept it - that pair is what makes
# these two rows rather than one check wearing two ids.
m_rc02_empty_entries() {
  rc_declare
  printf '{"schema":"reference-manifest/1","generated_from":"x","reference_app":{"package":"com.example.app","version":"1.0.9","apk_sha256":"%s"},"entries":[],"entry_count":0}\n' "$RP_HASH" > reference-manifest.json
}
m_rc02_count_mismatch() { rc_declare; sed -i 's/"entry_count":1/"entry_count":7/' reference-manifest.json; }
# RC-03 (NC-5) and RC-04: the lab tree, and the acquisition record's header. `manifests/` is what
# makes RC-03 and RC-04 applicable at all - a class-A install has neither it nor `refs/`.
m_rc03_clean() { mkdir -p manifests; printf '# lab corpus\n%s  apk/x.apk\n' "$RP_HASH" > manifests/lab.sha256; }
m_rc03_tracked_payload() {  # NC-5: a payload git-added under an ALLOWED path (clause 2, not clause 1)
  m_rc03_clean
  mkdir -p notes; cp "$RP" notes/payload.raw
  git add notes/payload.raw >/dev/null 2>&1
}
m_rc03_outside() {          # clause 1: a tracked path no allowlist entry covers
  m_rc03_clean
  mkdir -p refs; printf 'some bytes\n' > refs/payload.bin
  git add refs/payload.bin >/dev/null 2>&1
}
rc04_header() {
  printf '# lab reference corpus manifest\n# target : edotownsL-1.0.9.apk (com.example v1.0.9 vercode 10)\n# source : Aptoide pool.apk.aptoide.com ; md5 23974f8582359aa32eac30ad42a7744e\n# anchor : relative to the quarantine root\n%s  apk/edotownsL-1.0.9.apk\n' "$RP_HASH" > manifests/lab.sha256
}
m_rc04_valid()     { mkdir -p manifests; rc04_header; }
m_rc04_no_source() { m_rc04_valid; sed -i '/^# source :/d' manifests/lab.sha256; }
m_rc04_no_apk()    { m_rc04_valid; sed -i 's|apk/edotownsL-1.0.9.apk|payloads/a/payload.raw|' manifests/lab.sha256; }
# The index is the one part of the tree restore_all cannot put back by copying a file, so the two
# staged-file controls carry their own undo.
r_rc03_git() {
  git rm -q --cached notes/payload.raw >/dev/null 2>&1
  git rm -q --cached refs/payload.bin >/dev/null 2>&1
  rm -f reference-manifest.json
  rm -rf manifests refs notes
  git add -A >/dev/null 2>&1
  git commit -q -m "test: restore fixture" >/dev/null 2>&1 || true
}

expect_red   "a reference-corpus payload in the build output (NC-1)"         RC-01 1 m_rc01_payload
expect_red   "a copy of the manifest itself in the build output (NC-2)"      RC-01 1 m_rc01_manifest_copy
expect_red   "the file reference_manifest: names has been deleted (NC-4)"    RC-01 1 m_rc01_absent
expect_red   "a declared manifest that is not parseable"                     RC-01 1 m_rc01_unparseable
expect_green "reference_manifest: empty -> RC-01 SKIPs with a reason"        RC-01 m_rc_key_empty
expect_green "a declared corpus with no build output to scan"                RC-01 m_rc_declare
expect_red   "entries truncated to [] (NC-3: RC-02 RED)"                     RC-02 1 m_rc02_empty_entries
expect_green "entries truncated to [] leaves RC-01 GREEN (NC-3: the pair)"   RC-01 m_rc02_empty_entries
expect_red   "an entry_count that disagrees with entries"                    RC-02 1 m_rc02_count_mismatch
expect_green "a well-shaped reference manifest"                              RC-02 m_rc_declare
expect_red   "a corpus payload git-added under an allowed path (NC-5)"       RC-03 1 m_rc03_tracked_payload "" r_rc03_git
expect_red   "a tracked path outside the lab allowlist"                      RC-03 1 m_rc03_outside "" r_rc03_git
expect_green "a manifests/ tree with no tracked payload in it"               RC-03 m_rc03_clean
expect_red   "an acquisition record whose header names no source store"      RC-04 1 m_rc04_no_source
expect_red   "an acquisition record with no apk row"                         RC-04 1 m_rc04_no_apk
expect_green "a well-formed acquisition record"                              RC-04 m_rc04_valid

# ---- V1/G8-5: the advisory budget is reported, not left to arithmetic --------------------------
# The ceiling is the one scarce resource a rule author spends, and two cards (G1's FM-03, G2's
# JG-03) each wanted that last slot: nothing at HEAD decided which, and SK-03 printed the COUNT
# with no remaining budget, so the author had to work the arithmetic out. Both statements below
# are RED against 43f7f69, where the line was `advisory 9 of ceiling 10` and nothing else -
# measured in V1.md. The numbers come from the fixture, not from this file, so the control still
# holds if a later card legitimately spends the slot.
ADV_N=$(awk -F'\t' 'NR>1 && ($4=="advisory" || $6=="advisory") {n++} END{print n+0}' .goblin/manifest/enforcement.tsv)
ADV_C=$(sed -n 's/^advisory_ceiling:[[:space:]]*//p' .goblin/goblin.yaml | head -n 1)
: "${ADV_C:=10}"
out=$(bash .goblin/bin/goblin-verify --only SK-03 2>&1)
printf '%s' "$out" | grep -qE "advisory $ADV_N of ceiling $ADV_C \((0 free slots: the next advisory row FAILs|[0-9]+ free slots?)\)"
check "SK-03 reports the advisory count AND the remaining budget ($ADV_N of $ADV_C)" "$?"
sed -i "s/^advisory_ceiling: .*/advisory_ceiling: $ADV_N/" .goblin/goblin.yaml
out=$(bash .goblin/bin/goblin-verify --only SK-03 2>&1)
printf '%s' "$out" | grep -qE "advisory $ADV_N of ceiling $ADV_N \(0 free slots: the next advisory row FAILs\)"
check "  at the ceiling it says so, and names what the next row does" "$?"
sed -i "s/^advisory_ceiling: .*/advisory_ceiling: $ADV_C/" .goblin/goblin.yaml


# ---- W1: the engine split, the chain, and the global-mode clauses -------------
# Controls for the engine_path re-point (W1-SPEC §2.5), each shown RED then restored.
# The declaration-only probe itself lives in tests/t-engine-dir.sh; these stay on the
# class-A fixture, where the engine is vendored and the install record is full.

# The W1 footer: EVERY run names its judge - the running verifier and the manifest that
# judged this run (LIMITS #43: the statement is unsigned, and that hole is recorded).
W1_FOOTER=$(bash .goblin/bin/goblin-verify --only SK-03 2>&1 | grep -c 'cli_sha256=.*enforcement_tsv_sha256=')
[ "$W1_FOOTER" -ge 1 ]
check "W1: every run's footer names cli_sha256 and enforcement_tsv_sha256" "$?"

# IN-02 clause 2/3 (§2.2): with engine.mode=global in the record, a MISSING engine file
# is not drift (W3 removes them by design), and a repo-local recorded file that drifts
# still FAILs. The engine: block is planted by hand (the migration that writes it is
# W3). Both runs go through the CHECKOUT's verifier with --source: the control deletes
# the repo's own .goblin/bin + .goblin/manifest, so the installed interpreter and the
# vendored fallback must not be the thing being tested here.
w1_plant_engine_record() {
  python3 -c '
import json
rec = json.load(open(".goblin/installed.json"))
rec["engine"] = {"mode": "global", "engine_dir": "/tmp/w1-engine-gmode",
                 "cli_version": "0.4.4", "cli_sha256": "a", "enforcement_tsv_sha256": "b"}
json.dump(rec, open(".goblin/installed.json", "w"), indent=2)
'
}
m_in_02_global_local_drift() {
  w1_plant_engine_record
  printf '# an edited byte\n' >> "$WORK/standard.md"
}
m_in_02_global_engine_gone() {
  w1_plant_engine_record
  rm -rf .goblin/bin .goblin/manifest
}
# Clause 3 (§2.2): a global repo whose files map is EMPTY hashes nothing and passes - the
# lenient reader (g_installed_files) leaks the engine: block's key/value pairs as phantom
# file entries and reports drift on keys that were never files (measured pre-fix: '8
# installed files hashed' with rc 1). The strict reader must keep clause 3 at 0 files, rc 0.
m_in_02_global_files_empty() {
  w1_plant_engine_record
  python3 -c '
import json
rec = json.load(open(".goblin/installed.json"))
rec["files"] = {}
rec["owned"] = {}
json.dump(rec, open(".goblin/installed.json", "w"), indent=2)
'
}
m_in_02_global_files_empty
out=$(bash "$SRC/bin/goblin-verify" --source "$SRC" --only IN-02 2>&1); rc=$?
if [ "$rc" = "0" ] && printf '%s' "$out" | grep -qE '0 repo-local files hashed \(global engine mode\)'; then
  note "ok   W1: an empty files map under mode=global hashes nothing and passes (clause 3)"
else
  note "FAIL W1: an empty files map under mode=global hashes nothing and passes (clause 3) (rc=$rc)"
  printf '%s\n' "$out" | sed 's/^/        /'
  fail=1
fi
restore_all
m_in_02_global_engine_gone
out=$(bash "$SRC/bin/goblin-verify" --source "$SRC" --only IN-02 2>&1); rc=$?
if [ "$rc" = "0" ] && printf '%s' "$out" | grep -qE '[0-9]+ installed files hashed'; then
  note "ok   W1: in global mode the engine payload's absence is NOT drift (clause 2)"
else
  note "FAIL W1: in global mode the engine payload's absence is NOT drift (clause 2) (rc=$rc)"
  printf '%s\n' "$out" | sed 's/^/        /'
  fail=1
fi
restore_all
m_in_02_global_local_drift
out=$(bash "$SRC/bin/goblin-verify" --source "$SRC" --only IN-02 2>&1); rc=$?
if [ "$rc" = "1" ]; then
  note "ok   W1: in global mode a repo-local recorded file that drifts still FAILs"
else
  note "FAIL W1: in global mode a repo-local recorded file that drifts still FAILs (rc=$rc)"
  printf '%s\n' "$out" | sed 's/^/        /'
  fail=1
fi
restore_all

# AU-01's new clause (§2.5, Q2's narrow form): a repo that DECLARES its own automations
# (a root automations/ the engine never wrote) is judged like any producer - a network
# verb FAILs it, and when the declared producer disappears the row FAILs too. The SKIP
# half at the bottom proves the fixture's default state (no producer anywhere) is a
# SKIP with the reason, not the born-RED FAIL the pre-W1 glob produced (M9).
m_au_01_declared_network() { mkdir -p automations; printf 'curl https://x\n' > automations/mine.sh; }
# The producer-gone mutation builds the SAME tree the network control leaves: a declared
# automations/ directory whose .sh producer is renamed away. `mv` on a file the mutation
# never created failed with exit 1 and the control ran on the untouched fixture - the
# false GREEN an undefined mutate function produces, in the skill's own words.
m_au_01_declared_gone()    { mkdir -p automations; printf '# a producer\n' > automations/mine.sh; mv automations/mine.sh automations/mine.sh.gone; }
r_au_01_declared() { rm -rf automations; }
expect_red   "W1: the repo's OWN automation producer with a network verb" AU-01 1 m_au_01_declared_network "" r_au_01_declared
expect_red   "W1: automations declared but the producer is gone"          AU-01 1 m_au_01_declared_gone    "" r_au_01_declared
# The SKIP half cannot run on this fixture: its VENDORED engine payload
# (.goblin/automations/*.sh) supplies producers, so AU-01 PASSES here by design. The SKIP
# fires only when NO producer exists in either place - the global-mode probe below (the
# SC-07 block, which strips the engine payload) is the repo that proves it.

# SC-07 in global mode names the CLI verb, not the vendored path (§2.5). The probe must
# actually resolve GLOBAL: a class-B install vendored its own engine payload, and the
# chain's vendored step would win over the declared engine_dir:, so the mode stayed
# vendored and the old remedy text was printed. The engine payload is removed and the
# record it leaves behind is rewritten with the W3-shaped engine: block (§2.2) - the
# same state a migrated repo is in mid-sequence. The same probe carries AU-01's SKIP
# half: no producer in the engine dir, none in the repo.
W1_GMODE="$WORK/w1-gmode"
rm -rf "$W1_GMODE" /tmp/w1-engine-gmode
mkdir -p "$W1_GMODE" /tmp/w1-engine-gmode
cp -r "$SRC/manifest" /tmp/w1-engine-gmode/manifest
( cd "$W1_GMODE" \
  && git init -q -b main \
  && git config user.name "Test Runner" && git config user.email "runner@example.com" \
  && printf '# gmode\n' > README.md \
  && bash "$SRC/bin/goblin-install" --target . --class B --models "$WORK/models.yaml" >/dev/null 2>&1 \
  && sed -i "/^models_file:/a engine_dir: /tmp/w1-engine-gmode" .goblin/goblin.yaml \
  && python3 -c '
import json
rec = json.load(open(".goblin/installed.json"))
rec["engine"] = {"mode": "global", "engine_dir": "/tmp/w1-engine-gmode", "cli_version": "0.4.4", "cli_sha256": "a", "enforcement_tsv_sha256": "b"}
json.dump(rec, open(".goblin/installed.json", "w"), indent=2)' \
  && rm -rf .goblin/bin .goblin/manifest .goblin/bans .goblin/automations .goblin/roles.yaml )
# The probe is the repo the SC-07 block builds below; the AU-01 SKIP half runs there
# because that is the only producer-less repo in this file. Kept as a plain block: the
# two checks below share the probe's one build.
out=$( cd "$W1_GMODE" && bash "$SRC/bin/goblin-verify" --only AU-01 2>&1 )
printf '%s' "$out" | grep -q 'SKIP  AU-01.*no automation producer found'
check "W1: no producer anywhere -> AU-01 SKIPs with the reason (the born-RED FIX)" "$?"
out=$( cd "$W1_GMODE" && bash "$SRC/bin/goblin-verify" --only SC-07 2>&1 )
printf '%s' "$out" | grep -q 'gob audit'
check "W1: a global-mode SC-07 SKIP names the CLI verb (gob audit)" "$?"
printf '%s' "$out" | grep -q '.goblin/audit.tsv'
check "  and the record it names is still the repo-local one" "$?"
rm -rf /tmp/w1-engine-gmode

# ---- F2-6: --only must refuse a selection that runs no target row -------------
# A valid SOURCE-scope id selects nothing in an installed repo, so the run printed
# "0 passed, 0 failed" and exited 0: a pipeline gate built on `--only PR-01` was a no-op.
out=$(bash .goblin/bin/goblin-verify --only PR-01 2>&1); rc=$?
check "--only <source-scope id> refuses instead of reporting 0 passed" "$([ "$rc" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'selects no target-scope row'
check "  and the refusal says why" "$?"
out=$(bash .goblin/bin/goblin-verify --only IN-01,PR-02 2>&1); rc=$?
check "--only <target id mixed with a source id> still runs the target row" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"

FINAL=$(bash .goblin/bin/goblin-verify 2>&1); FINAL_RC=$?
[ "$FINAL_RC" -eq 0 ] || printf '%s\n' "$FINAL" | grep -E '^(FAIL|SKIP|ADV)' | sed 's/^/        /'
check "the fixture is GREEN again after every mutation was restored" "$FINAL_RC"

# ---- Z1-7: the summary's advisory arithmetic, over the same full run -------------------------
# The line `advisory N of ceiling C` counts the rows the MATRIX labels advisory (SK-03), while the
# `ADV` lines on screen include a non-advisory row whose lane cannot be resolved here (JG-02). The
# two numbers therefore differ by design, and the summary used to print only the first - so a
# reader comparing it with the ADV lines saw a mismatch that only the row's why-cell explained.
# This is a text assertion rather than an `expect_*` call for the same reason the judge-lane
# comparison is: the row exits 0 either way and the claim is about the LINE it prints.
ADV_LABELLED=$(awk -F'\t' 'NR>1 && ($4=="advisory" || $6=="advisory") {n++} END{print n+0}' .goblin/manifest/enforcement.tsv)
ADV_PRINTED=$(printf '%s\n' "$FINAL" | grep -cE '^ADV')
printf '%s\n' "$FINAL" | grep -q "of those $ADV_PRINTED advisory: the matrix labels $ADV_LABELLED row(s) advisory"
check "Z1-7: the summary prints the advisory arithmetic ($ADV_PRINTED ADV lines vs $ADV_LABELLED labelled)" "$?"

if [ "$fail" -eq 0 ]; then note "t-verify-red: PASS"; else note "t-verify-red: FAIL"; fi
exit "$fail"
