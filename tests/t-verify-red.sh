#!/usr/bin/env bash
# t-verify-red.sh — PR-03, the negative control. Every target-scope row must go RED under its
# own violation. A verifier that only ever prints GREEN is a failure, and this is the file that
# proves it is not one. Run by tests/run-tests.sh.
#
# One `expect_red` per target-scope row: 80 `expect_red` call sites and 7 `expect_green`, covering
# 63 of the matrix's 65 target rows. The two it does not cover are `DOC-01` and `DOC-02`, which are
# `advisory` and carry no executable check at all (docs/RISKS.md names them and says why); measured,
# 63 distinct ids, 0 phantom ids (every id used here is a row in the matrix) and 0 target row with
# an executable rule left without a control. The 63 were built up as 42 at v0.1 plus the
# five added with AU-01..AU-04 and SK-04, plus the ten added with SC-01..SC-09 and PF-01, plus the
# five added with BN-00..BN-03 and BN-05, plus the three F4/G4 extras, the two V1 extras (G8-2,
# G8-5), the second BN-00 control, the five W1 extras (three G8-3 gate-cmd forms, the V3-2
# exit-code ban control, and the G8-6b ceiling/baseline control), and the seven added with G1's
# FM-01/FM-02/VA-01 - four of FM-01's clauses, FM-02's two, and the failing doctor. Seven of the
# controls are `expect_green` (the F2-9 pairs, three F4/G8-6b asserts, and two that seed a feature
# map and require it to PASS, which is the half of a control that proves a new row is not
# always-red). The `--only <id>` form is used
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
# WHAT THE ADVISORY-ROW CONTROLS DO AND DO NOT PROVE. Nine target rows are labelled
# `advisory` by design (HP-04, HS-03, CM-02, MD-02, MD-03, PG-04, DOC-01, DOC-02, SC-09 — the
# ninth landed with G4's guard rails; this sentence said eight until 2026-09-25): their rules
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
# goblin-stack-research/F1.md, section 2.
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
git add -A && git commit -q -m "chore: install goblin-stack"
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
# .gitignore is mutated by m_sc_02 and must come back byte-for-byte: the fixture-green check at
# the end of this file is what caught its absence.
cp -a .gitignore "$BK/gitignore"

restore_all() {
  cp -a "$BK/HANDOFF.md" HANDOFF.md
  cp -a "$BK/goblin.yaml" .goblin/goblin.yaml
  cp -a "$BK/installed.json" .goblin/installed.json
  cp -a "$BK/enforcement.tsv" .goblin/manifest/enforcement.tsv
  cp -a "$BK/bans.tsv" .goblin/manifest/bans.tsv
  cp -a "$BK/SKILL.md" .hermes/skills/goblin-mode/SKILL.md
  cp -a "$BK/ROUND-000-SPEC.md" ROUND-000-SPEC.md
  cp -a "$BK/standard.md" "$WORK/standard.md"
  cp -a "$BK/drift-audit-SKILL.md" .hermes/skills/goblin-drift-audit/SKILL.md
  cp -a "$BK/bugreporter-SKILL.md" .hermes/skills/goblin-bugreporter/SKILL.md
  cp -a "$BK/automations/." .goblin/automations/
  cp -a "$BK/gitignore" .gitignore
  rm -f checks/green.mjs newfile.txt todo-marker.mjs ROUND-001-SPEC.md stray.txt \
        .goblin/state.json .goblin/last-gate-line .goblin/.ds-report .goblin/ratchet-last \
        .envrc .goblin/audit.tsv package.json package-lock.json
  rm -f reviews/fixture-*.md
  rm -rf reports
  rm -rf .github
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
m_bn_02()          { mkdir -p src; printf '// @ts-expect-error\nexport const b = 1;\n' > src/bn02.ts; }
m_bn_03()          { sed -i 's/^bans: \[.*\]/bans: [BN-01, BN-02, BN-03, BN-05]/' .goblin/goblin.yaml; mkdir -p src/components; printf 'export const P = () => { fetch("/api/x"); return null; };\n' > src/components/panel.tsx; }
m_bn_05()          { printf '\nlayers:\n  - src/renderer src/main\n' >> .goblin/goblin.yaml; mkdir -p src/renderer src/main; printf "import { db } from '../main/db';\nexport const r = db;\n" > src/renderer/p.ts; }
# A tree BN-05 can read (so its globs match) but with no `layers:` declared: the row must SKIP
# with that reason, never pass vacuously.
m_bn_05_nolayers() { mkdir -p src/renderer; printf 'export const r = 1;\n' > src/renderer/p.ts; }

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
git add -A && git commit -q -m "chore: install goblin-stack (class B)"
cd "$TARGET"
m_b_tokens() { printf 'a_part_class_B_turns_off: true\n' > .goblin/tokens.yaml; }
restore_b()  { rm -f .goblin/tokens.yaml; }

# ---- the 42 target-scope rows, in manifest order ------------------------------
expect_red "a manifest with no version"            IN-01 1 m_in_01
expect_red "one edited byte of the standard"       IN-02 1 m_edit_practice
expect_red "a manifest row with no check"          IN-03 3 m_blank_row
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
expect_red "a self-skipping workflow"              PG-05 1 m_self_skip_wf

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
expect_red "a JS cookie write with no flags"        SC-04 1 m_sc_04
expect_red "a write route with no validator"        SC-05 1 m_sc_05
expect_red "a manifest with no lockfile"           SC-06 1 m_sc_06
expect_red "an audit record nobody re-took"        SC-07 1 m_sc_07
expect_red "an install hook nobody decided on"     SC-08 1 m_sc_08
expect_red "SC-09 (advisory row: wired, not biting)" SC-09 1 m_sc_09
expect_red "a perf baseline naming no real commit" PF-01 1 m_pf_01
expect_green "G8-6b: the ceiling matches the recorded baseline"        PF-01 m_pf_ceiling_match
expect_red   "G8-6b: the ceiling raised by hand, the baseline untouched" PF-01 1 m_pf_ceiling_raise

# ---- G5: the ban list is a gate, not a wish - one control per row -----------------------------
expect_red   "the ban table loses a row the matrix still names" BN-00 1 m_bn_00_orphan
expect_red   "a ban that names no replacement"                  BN-00 1 m_bn_00_norepl
expect_red   "an any type in application TypeScript"               BN-01 1 m_bn_01
expect_red   "V3-2: a ban violated by exit code alone (no stdout)"  BN-01 1 m_bn_exit1_detect
expect_red   "a ts-expect-error suppression"                 BN-02 1 m_bn_02
expect_red   "a fetch() called from a component"                BN-03 1 m_bn_03
expect_red "an import across a declared layer boundary"       BN-05 1 m_bn_05
# BN-05 is a SKIP (not a FAIL) when no layers are declared - the HS-01 precedent: nothing to
# read is reported as a reason, never as a pass.
expect_green "no layers declared -> BN-05 skips with a reason"  BN-05 m_bn_05_nolayers

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
expect_red   "an entry path changed after the map was verified" FM-02 1 m_fm_02_stale
expect_red   "a verify_doctor that exits non-zero" VA-01 1 m_va_01_fail

expect_red "a class-B repo carrying a part it forbids" CL-01 1 m_b_tokens "$TARGET_B" restore_b
expect_red "the archive waiver flipped by hand"    CL-02 1 m_archive_flip

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
printf '%s' "$out" | grep -qE "advisory $ADV_N of ceiling $ADV_C \([0-9]+ free slots?\)"
check "SK-03 reports the advisory count AND the remaining budget ($ADV_N of $ADV_C)" "$?"
sed -i "s/^advisory_ceiling: .*/advisory_ceiling: $ADV_N/" .goblin/goblin.yaml
out=$(bash .goblin/bin/goblin-verify --only SK-03 2>&1)
printf '%s' "$out" | grep -qE "advisory $ADV_N of ceiling $ADV_N \(0 free slots: the next advisory row FAILs\)"
check "  at the ceiling it says so, and names what the next row does" "$?"
sed -i "s/^advisory_ceiling: .*/advisory_ceiling: $ADV_C/" .goblin/goblin.yaml

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

if [ "$fail" -eq 0 ]; then note "t-verify-red: PASS"; else note "t-verify-red: FAIL"; fi
exit "$fail"
