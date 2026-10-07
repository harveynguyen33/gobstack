#!/usr/bin/env bash
# t-doc-guide-init.sh — the walked path in docs/GUIDE.md is `gob init` (review-UX pass), and the
# numbers the guide quotes are THE WIZARD PATH's, re-measured here on the same shape §3 teaches:
# an EMPTY repo, the wizard with its default gate, then the day-one commits.
#
#   UX-i   §3's transcript is the wizard's: `created 24` — one fewer than the plain installer's
#          25, because the wizard's unanswered ci screen defaults to an explicit no, which is
#          recorded as an opt-out and suppresses `.github/workflows/goblin-gate.yml`.
#   UX-ii  the day-one table: the pre-commit run is `31 passed, 6 failed` (uncommitted install +
#          the HP-05 placeholder + the 127 gate), the first-commit run is `35 passed, 2 failed`
#          (HP-05 + GT-02 exit 127 left), and the green-path run — after naming a real HEAD in
#          HANDOFF.md and committing it — is `36 passed, 1 failed, 11 advisory, 34 skipped`.
#          The one standing red is GT-02: the default gate is `bash tests/run-tests.sh` and a
#          throwaway repo has no tests/ — exit 127. That red is the guide's own teaching point
#          (§5: replace the default gate with your real commands), not a defect.
#   UX-iii the second-commit step (CM-03): editing HANDOFF.md without committing re-reds CM-03
#          (`1 dirty entr(y|ies)`), so the day-one table shows the edit AND the commit as two
#          steps, and this control re-measures the dirty-tree shape between them.
#
# The numbers move as a set with §3/§4/§9 of the guide (t-doc-guide.sh keeps pinning the plain
# installer's 25/26 on the same tree; the two paths are documented side by side there).
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GUIDE="$SRC/docs/GUIDE.md"
WORK=$(mktemp -d)
HOMEDIR="$WORK/home"; mkdir -p "$HOMEDIR"
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

mkdir -p "$WORK/target"
cd "$WORK/target"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"

# ---- UX-i: the wizard transcript is `created 24` ----------------------------------------------
OUT=$(HOME="$HOMEDIR" bash "$SRC/bin/goblin-init" --target . --class software --branch main \
        --email "runner@example.com" --yes </dev/null 2>&1); RC=$?
check "gob init exits 0 on the guide's flag shape" "$RC"
printf '%s' "$OUT" | grep -qF "created 24 · updated 0 · unchanged 0 · skipped 0"
check "UX-i the wizard prints created 24 (the ci opt-out suppresses the workflow)" "$?"
[ -f .github/workflows/goblin-gate.yml ]
check "UX-i and writes NO .github workflow (the ci default is an explicit no)" "$([ $? -ne 0 ] && echo 0 || echo 1)"
grep -qF "created 24" "$GUIDE"
check "  and the guide quotes the wizard's created line" "$?"

# ---- UX-ii: the three day-one shapes ----------------------------------------------------------
SUM() { HOME="$HOMEDIR" bash .goblin/bin/goblin-verify 2>&1 | grep -m1 -E '^ +[0-9]+ passed, [0-9]+ failed, [0-9]+ advisory, [0-9]+ skipped$' | sed 's/^ *//'; }

PRE=$(SUM)
check "UX-ii the pre-commit run prints 31 passed, 6 failed (uncommitted install + HP-05 + the 127 gate)" \
  "$(printf '%s' "$PRE" | grep -qF '31 passed, 6 failed, 11 advisory, 34 skipped' && echo 0 || echo 1)"
GT02_PRE=$(HOME="$HOMEDIR" bash .goblin/bin/goblin-verify 2>&1)
printf '%s' "$GT02_PRE" | grep -qE '^FAIL  GT-02  gate commit: bash tests/run-tests.sh -> exit 127'
check "UX-ii the standing day-one red is GT-02's exit 127 (no tests/ in a throwaway repo)" "$?"

git add -A && git commit -q -m "chore: install gobstack"
DAY1=$(SUM)
check "UX-ii the first-commit run prints 35 passed, 2 failed (HP-05 + GT-02 left)" \
  "$(printf '%s' "$DAY1" | grep -qF '35 passed, 2 failed, 11 advisory, 34 skipped' && echo 0 || echo 1)"

# ---- UX-iii: the second-commit step (CM-03) ----------------------------------------------------
HEAD_NOW=$(git rev-parse --short HEAD)
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$HEAD_NOW\`/" HANDOFF.md
DIRTY=$(SUM)
check "UX-iii the HANDOFF edit alone re-reds CM-03 (commit-as-you-go, day-one table step 3)" \
  "$(printf '%s' "$DIRTY" | grep -qF '35 passed, 2 failed' && [ -n "$(git status --porcelain)" ] && echo 0 || echo 1)"
printf '%s' "$(HOME="$HOMEDIR" bash .goblin/bin/goblin-verify 2>&1)" | grep -q '^FAIL  CM-03  1 dirty entr(y|ies)'
check "  and the dirty row is CM-03 with the 1-entry count" "$?"

git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"
GREEN=$(SUM)
check "UX-ii the green path prints 36 passed, 1 failed, 11 advisory, 34 skipped (GT-02 127 left)" \
  "$(printf '%s' "$GREEN" | grep -qF '36 passed, 1 failed, 11 advisory, 34 skipped' && echo 0 || echo 1)"

# ---- the guide quotes exactly these shapes ----------------------------------------------------
for shape in "31 passed, 6 failed, 11 advisory, 34 skipped" \
             "35 passed, 2 failed, 11 advisory, 34 skipped" \
             "36 passed, 1 failed, 11 advisory, 34 skipped"; do
  grep -qF "$shape" "$GUIDE"
  check "the guide quotes the measured line ($shape)" "$?"
done
# ...and no summary line in the guide is outside the set both paths print (the plain installer's
# 37/1 + 38/0 in t-doc-guide, the wizard's three here).
SHAPES=$(grep -E '^[[:space:]]*[0-9]+ passed, [0-9]+ failed, [0-9]+ advisory, [0-9]+ skipped' "$GUIDE" \
         | sed -n 's/^[[:space:]]*\([0-9]* passed, [0-9]* failed, [0-9]* advisory, [0-9]* skipped\).*/\1/p' | sort -u)
# Subset semantics, matching t-doc-guide.sh: every summary-shaped line the guide quotes must be
# one the six measured runs printed (this file's three wizard shapes plus the plain installer's
# two, plus the wizard's own green-after-real-gate line the guide's §9 quotes).
MEASURED=$(printf '%s\n' \
  "31 passed, 6 failed, 11 advisory, 34 skipped" \
  "35 passed, 2 failed, 11 advisory, 34 skipped" \
  "36 passed, 0 failed, 11 advisory, 34 skipped" \
  "36 passed, 1 failed, 11 advisory, 34 skipped" \
  "37 passed, 1 failed, 11 advisory, 33 skipped" \
  "38 passed, 0 failed, 11 advisory, 33 skipped")
SUBSET=0
while IFS= read -r s; do
  [ -n "$s" ] || continue
  printf '%s\n' "$MEASURED" | grep -qxF "$s" || { note "FAIL the guide quotes a line no measured run printed: $s"; SUBSET=1; }
done <<EOF_SHAPES
$SHAPES
EOF_SHAPES
check "every summary line the guide quotes is one of the measured shapes" "$SUBSET"

if [ "$fail" -eq 0 ]; then note "t-doc-guide-init: PASS"; else note "t-doc-guide-init: FAIL"; fi
exit "$fail"
