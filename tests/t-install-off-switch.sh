#!/usr/bin/env bash
# t-install-off-switch.sh — the class matrix is a real switch, not a label.
#   class D + --archive  -> no checks/, no HANDOFF, no SPEC, no reviews/, verify exits 0
#   class A              -> the same shape fails HP-01 and CL-01
# Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

printf 'profiles:\n  coder:\n    model: model-code\n    provider: prov-code\n    effort: low\n' > "$WORK/models.yaml"

mkfix() {
  mkdir -p "$1" && cd "$1"
  git init -q -b main
  git config user.name "Test Runner"
  git config user.email "runner@example.com"
  printf '# %s\n' "$(basename "$1")" > README.md
  git add -A && git commit -q -m "chore: seed"
}

# ---- class D + --archive -----------------------------------------------------
mkfix "$WORK/archived"
bash "$SRC/bin/goblin-install" --target "$WORK/archived" --class D --archive --models "$WORK/models.yaml" >/dev/null 2>&1
check "archive install exits 0" "$?"
check "no checks/ directory" "$([ ! -d checks ] && echo 0 || echo 1)"
check "no HANDOFF.md" "$([ ! -f HANDOFF.md ] && echo 0 || echo 1)"
check "no *-SPEC.md" "$(ls ./*-SPEC.md >/dev/null 2>&1 && echo 1 || echo 0)"
check "no reviews/ directory" "$([ ! -d reviews ] && echo 0 || echo 1)"
check "no .goblin/tokens.yaml" "$([ ! -f .goblin/tokens.yaml ] && echo 0 || echo 1)"
git add -A && git commit -q -m "chore: install (archive)"
VERIFY_OUT=$(bash .goblin/bin/goblin-verify 2>&1); VERIFY_RC=$?
note "verify exit=$VERIFY_RC"
printf '%s' "$VERIFY_OUT" | grep -q 'SKIP  HP-01'
check "HP-01 is skipped for an archive project" "$?"
printf '%s' "$VERIFY_OUT" | grep -q 'SKIP  GT-01'
check "GT-01 is skipped for an archive project" "$?"
check "archive verify exits 0 without a HANDOFF" "$VERIFY_RC"
printf '%s' "$VERIFY_OUT" | grep -q 'archive: true'
check "the summary says why the rows were skipped" "$?"

# ---- the same shape, class A: the switch is what made it pass ----------------
mkfix "$WORK/notarchived"
bash "$SRC/bin/goblin-install" --target "$WORK/notarchived" --class A --models "$WORK/models.yaml" >/dev/null 2>&1
git add -A && git commit -q -m "chore: install (class A)"
rm -f HANDOFF.md && git add -A && git commit -q -m "test: remove the HANDOFF"
A_OUT=$(bash .goblin/bin/goblin-verify 2>&1); A_RC=$?
note "class A without a HANDOFF: verify exit=$A_RC"
printf '%s' "$A_OUT" | grep -q 'FAIL  HP-01'
check "class A fails HP-01 when the HANDOFF is gone" "$?"
printf '%s' "$A_OUT" | grep -q 'FAIL  CL-01'
check "class A fails CL-01 when a required part is absent" "$?"
check "and the run is not green" "$([ "$A_RC" -eq 1 ] && echo 0 || echo 1)"

# ---- the playbooks part: `--skills no` is a real switch, and it used to FAIL ---------------
# Measured at v0.2.0-dev: `--skills no` gave "32 passed, 1 failed, 8 advisory, 6 skipped" with
# "FAIL  SK-02  0 installed skill file(s) hashed" - a repo that opted OUT of the skills part was
# failed by the row that hashes them. The five automation rows and SK-02/SK-04 skip instead.
mkfix "$WORK/noskills"
bash "$SRC/bin/goblin-install" --target "$WORK/noskills" --class A --skills no \
  --models "$WORK/models.yaml" >/dev/null 2>&1
check "--skills no installs" "$?"
check "  and writes no automation producers either" \
  "$([ ! -d .goblin/automations ] && echo 0 || echo 1)"
git add -A && git commit -q -m "chore: install (--skills no)"
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"
NS_OUT=$(bash .goblin/bin/goblin-verify 2>&1); NS_RC=$?
note "class A --skills no: verify exit=$NS_RC, $(printf '%s' "$NS_OUT" | grep -E '^ *[0-9]+ passed')"
check "class A with --skills no verifies green" "$NS_RC"
printf '%s' "$NS_OUT" | grep -q 'SKIP  AU-01  .*opt-out: playbooks'
check "  and the automation rows are opt-out, not absent" "$?"
printf '%s' "$NS_OUT" | grep -q 'SKIP  SK-02'
check "  and SK-02 is opt-out rather than FAIL (the pre-fix defect)" "$?"
# V3-3: the opt-out path had a number no file recorded (the count moved from `37/0/9/11` at v0.2
# to `38/0/9/15` with the ban rows and nothing noticed, and to `38/0/9/18` on 2026-09-25 when G1's
# FM-01/FM-02/VA-01 joined - each of those three skips on this path for its own reason, and to
# `38/0/11/24` on 2026-09-25 when W3's judge/loop rows joined: JG-02 reports ADV and JG-01 +
# LP-01..LP-05 skip, all six because no loop has run). Pin the
# line so the next silent shift is caught here. The number is measured, not copied: see the note
# line the run prints above.
printf '%s' "$NS_OUT" | grep -q '39 passed, 0 failed, 11 advisory, 28 skipped'
check "  and the --skills no numbers are pinned (V3-3: 38/0/11/24)" "$?"

if [ "$fail" -eq 0 ]; then note "t-install-off-switch: PASS"; else note "t-install-off-switch: FAIL"; fi
exit "$fail"
