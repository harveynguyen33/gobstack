#!/usr/bin/env bash
# t-verify-red.sh — PR-03, the negative control. Every check class must go RED under its own
# violation. A verifier that only ever prints GREEN is a failure, and this is the file that
# proves it is not one. Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

printf 'profiles:\n  coder:\n    model: model-code\n    provider: prov-code\n    effort: low\n  reviewer:\n    model: model-review\n    provider: prov-review\n    effort: high\n' > "$WORK/models.yaml"

mkdir -p "$WORK/target" && cd "$WORK/target"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# target\n' > README.md
git add -A && git commit -q -m "chore: seed"
PRE_CHANGE=$(git rev-parse --short HEAD)

bash "$SRC/bin/goblin-install" --target "$WORK/target" --class A --models "$WORK/models.yaml" >/dev/null 2>&1
git add -A && git commit -q -m "chore: install goblin-stack"
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"

bash .goblin/bin/goblin-verify >/dev/null 2>&1
check "the fixture starts GREEN (nothing below is measured against a broken baseline)" "$?"

BK="$WORK/backup"
mkdir -p "$BK"
cp -a HANDOFF.md "$BK/HANDOFF.md"
cp -a .goblin/goblin.yaml "$BK/goblin.yaml"
cp -a .goblin/manifest/enforcement.tsv "$BK/enforcement.tsv"
cp -a .hermes/skills/goblin-mode/SKILL.md "$BK/SKILL.md"
cp -a ROUND-000-SPEC.md "$BK/ROUND-000-SPEC.md"

restore_all() {
  cp -a "$BK/HANDOFF.md" HANDOFF.md
  cp -a "$BK/goblin.yaml" .goblin/goblin.yaml
  cp -a "$BK/enforcement.tsv" .goblin/manifest/enforcement.tsv
  cp -a "$BK/SKILL.md" .hermes/skills/goblin-mode/SKILL.md
  cp -a "$BK/ROUND-000-SPEC.md" ROUND-000-SPEC.md
  rm -f checks/green.mjs newfile.txt reviews/fixture-*.md
  rm -rf .github
  git add -A >/dev/null 2>&1
  git commit -q -m "test: restore fixture" >/dev/null 2>&1 || true
}

expect_red() { # <label> <row id> <expected exit> <mutate fn>
  local label="$1" id="$2" want="$3" mutate="$4" out rc
  "$mutate"
  out=$(bash .goblin/bin/goblin-verify --only "$id" 2>&1); rc=$?
  if [ "$rc" = "$want" ]; then
    note "ok   $label -> $id exit $rc ($(printf '%s' "$out" | grep -m1 -E '^FAIL|^error' | cut -c1-88))"
  else
    note "FAIL $label -> $id exit $rc, wanted $want"
    printf '%s\n' "$out" | sed 's/^/        /'
    fail=1
  fi
  restore_all
}

m_drop_handoff()  { rm -f HANDOFF.md; git add -A >/dev/null 2>&1; git commit -q -m "test: drop handoff" >/dev/null 2>&1; }
m_drop_heading()  { sed -i 's/^## Gates$/## Gate numbers/' HANDOFF.md; git add -A >/dev/null 2>&1; git commit -q -m "test: rename heading" >/dev/null 2>&1; }
m_blank_row()     { sed -i -E 's/^(HP-05\t[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t)[^\t]*/\1/' .goblin/manifest/enforcement.tsv; }
m_break_gate()    { sed -i 's|^    cmd: git rev-parse --verify --quiet HEAD|    cmd: false|' .goblin/goblin.yaml; }
m_drop_spec()     { rm -f ./*-SPEC.md; git add -A >/dev/null 2>&1; git commit -q -m "test: drop spec" >/dev/null 2>&1; }
m_model_leak()    { printf '\nmodel: deepseek-v9-turbo\n' >> .hermes/skills/goblin-mode/SKILL.md; }
m_skill_drift()   { printf '\n<!-- drift -->\n' >> .hermes/skills/goblin-mode/SKILL.md; }
m_wrong_branch()  { sed -i 's/^branch: main/branch: trunk/' .goblin/goblin.yaml; }
m_dirty_tree()    { printf 'untracked\n' > newfile.txt; }
m_bad_author()    { git -c user.email=someone@else.test commit -q --allow-empty -m "test: ambient author"; }
m_self_skip_wf()  { mkdir -p .github/workflows; printf 'jobs:\n  a:\n    steps:\n      - if: ${{ secrets.NOPE }}\n        run: echo hi\n' > .github/workflows/ci.yml; git add -A >/dev/null 2>&1; git commit -q -m "test: self-skipping workflow" >/dev/null 2>&1; }
m_green_harness() { printf 'console.log("PASS  nothing\\n"); process.exit(0);\n' > checks/green.mjs; git add -A >/dev/null 2>&1; git commit -q -m "test: a harness green on both trees" >/dev/null 2>&1; sed -i "s|^  commit: \"\"|  commit: \"$PRE_CHANGE\"|" .goblin/goblin.yaml; }
m_bad_review()    { mkdir -p reviews; printf 'head: %s\nbase: %s\npatch-id: deadbeef\nstakes: S2\nchecks-run:\n' "$(git rev-parse HEAD)" "$PRE_CHANGE" > reviews/fixture-abc1234.md; }
m_review_no_sha() { mkdir -p reviews; printf 'head: 0000000000000000000000000000000000000000\nbase: %s\npatch-id: x\nstakes: S1\n' "$PRE_CHANGE" > reviews/fixture-def5678.md; }

expect_red "a missing HANDOFF"              HP-01 1 m_drop_handoff
expect_red "a HANDOFF heading renamed"      HP-02 1 m_drop_heading
expect_red "a manifest row with no check"   IN-03 3 m_blank_row
expect_red "a gate that exits non-zero"     GT-02 1 m_break_gate
expect_red "no SPEC"                        SP-01 1 m_drop_spec
expect_red "a hardcoded model name"         MD-01 1 m_model_leak
expect_red "an edited installed skill"      SK-02 1 m_skill_drift
expect_red "the declared branch is wrong"   PT-02 1 m_wrong_branch
expect_red "an uncommitted file"            CM-03 1 m_dirty_tree
expect_red "an ambient commit author"       CM-01 1 m_bad_author
expect_red "a self-skipping workflow"       PG-05 1 m_self_skip_wf
expect_red "a harness green on both trees"  HS-02 1 m_green_harness
expect_red "a review with a wrong patch-id" PG-03 1 m_bad_review
expect_red "a review naming no real SHA"    PG-01 1 m_review_no_sha

FINAL=$(bash .goblin/bin/goblin-verify 2>&1); FINAL_RC=$?
[ "$FINAL_RC" -eq 0 ] || printf '%s\n' "$FINAL" | grep -E '^(FAIL|SKIP|ADV)' | sed 's/^/        /'
check "the fixture is GREEN again after every mutation was restored" "$FINAL_RC"

if [ "$fail" -eq 0 ]; then note "t-verify-red: PASS"; else note "t-verify-red: FAIL"; fi
exit "$fail"
