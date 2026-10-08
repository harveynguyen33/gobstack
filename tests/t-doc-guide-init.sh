#!/usr/bin/env bash
# t-doc-guide-init.sh — the walked path in docs/GUIDE.md is `gob init` (the v2 agent-brief flow),
# and the numbers the guide quotes are THE INIT-PATH's, re-measured here on the same shape §3
# teaches: an EMPTY repo, a hand-written proposal (the schema the brief prints), `--write`, then
# the day-one commits.
#
#   UX-i   §3's transcript is the installer's: `created 23` — it writes 24, because
#          `.gob/installed.json` is written but not counted. v2 writes no `.github/` anything.
#   UX-ii  the day-one table: the pre-commit run is `36 passed, 1 failed` (uncommitted install +
#          the HP-05 placeholder + the 127 gate), and the green-path run — after naming a real
#          HEAD in HANDOFF.md and committing it — is `37 passed, 0 failed, 11 advisory,
#          34 skipped`. With a gate that can run (the fixture writes tests/run-tests.sh) there
#          is no standing red: the 127 the guide teaches about belongs to the throwaway shape
#          whose gate names a script the repo does not have, and t-doc-guide.sh pins that side.
#   UX-iii the second-commit step (CM-03): editing HANDOFF.md without committing re-reds CM-03
#          (`1 dirty entr(y|ies)`), so the day-one table shows the edit AND the commit as two
#          steps, and this control re-measures the dirty-tree shape between them.
#
# The numbers move as a set with §3/§4/§9 of the guide (t-doc-guide.sh keeps pinning the same
# tree's shapes on its own install).
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

# ---- UX-i: the init transcript is `created 23` -----------------------------------------------
# The repo carries a seed commit BEFORE the install: a proposal + a gate script are themselves
# work product, and an empty repo would fail PT-02 (no HEAD to compare the declared branch
# against) and CM-01 on the day-one run — shapes §10 documents as configuration errors, not the
# day-one walk. The guide's own §3 has the reader commit the proposal first, in step 2.
mkdir -p tests
printf '#!/usr/bin/env bash\nexit 0\n' > tests/run-tests.sh
chmod +x tests/run-tests.sh
cat > proposal.md <<'EOF'
<!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->
class: software
branch: main
owner_email: runner@example.com
gate_check_cmd: bash tests/run-tests.sh
<!-- gob:end -->

## gob init summary

- the brief answered by hand: class software, branch main, one real gate
EOF
git add -A && git commit -q -m "chore: the proposal and its gate"
OUT=$(HOME="$HOMEDIR" bash "$SRC/bin/goblin-init" --write proposal.md --yes 2>&1); RC=$?
check "gob init --write exits 0 on the guide's proposal shape" "$RC"
printf '%s' "$OUT" | grep -qF "created 23 · updated 0 · unchanged 0 · skipped 0"
check "UX-i the install prints created 23 (installed.json is written but not counted)" "$?"
[ ! -e .github ]
check "UX-i and writes NO .github anything (v2 installs no CI)" "$?"
grep -qF "created 23" "$GUIDE"
check "  and the guide quotes the created line" "$?"

# ---- UX-ii: the day-one shapes -----------------------------------------------------------------
# Measured here (and matching t-doc-guide.sh's plain install): the pre-commit run carries the
# uncommitted install (CM-03) plus the untracked ROUND-000-SPEC.md (SP-02) — `35 passed,
# 2 failed` — and the first commit clears both, leaving HP-05's placeholder as the one red
# until it names a real HEAD: `36 passed, 1 failed`. Green is `37 passed, 0 failed`.
SUM() { HOME="$HOMEDIR" bash .gob/bin/goblin-verify 2>&1 | grep -m1 -E '^ +[0-9]+ passed, [0-9]+ failed, [0-9]+ advisory, [0-9]+ skipped$' | sed 's/^ *//'; }

PRE=$(SUM)
check "UX-ii the pre-commit run prints 35 passed, 2 failed (uncommitted install + SP-02)" \
  "$(printf '%s' "$PRE" | grep -qF '35 passed, 2 failed, 11 advisory, 34 skipped' && echo 0 || echo 1)"

git add -A && git commit -q -m "chore: install gobstack"
DAY1=$(SUM)
# The installer fills HANDOFF.md's HEAD line from the seed commit when one exists, so HP-05 has
# nothing to flag and the first-commit run is already green. The placeholder red the guide
# teaches (HP-05) belongs to the verify-on-an-empty-repo path t-doc-guide.sh walks.
check "UX-ii the first-commit run is green (the installer filled the HANDOFF HEAD)" \
  "$(printf '%s' "$DAY1" | grep -qF '37 passed, 0 failed, 11 advisory, 34 skipped' && echo 0 || echo 1)"

# ---- UX-iii: the second-commit step (CM-03) ----------------------------------------------------
HEAD_NOW=$(git rev-parse --short HEAD)
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$HEAD_NOW\`/" HANDOFF.md
DIRTY=$(SUM)
check "UX-iii the HANDOFF edit alone re-reds CM-03 (commit-as-you-go, day-one table step 3)" \
  "$(printf '%s' "$DIRTY" | grep -qF '36 passed, 1 failed' && [ -n "$(git status --porcelain)" ] && echo 0 || echo 1)"
printf '%s' "$(HOME="$HOMEDIR" bash .gob/bin/goblin-verify 2>&1)" | grep -q '^FAIL  CM-03  1 dirty entr(y|ies)'
check "  and the dirty row is CM-03 with the 1-entry count" "$?"

git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"
GREEN=$(SUM)
check "UX-ii the green path prints 37 passed, 0 failed, 11 advisory, 34 skipped" \
  "$(printf '%s' "$GREEN" | grep -qF '37 passed, 0 failed, 11 advisory, 34 skipped' && echo 0 || echo 1)"

# ---- the guide quotes exactly these shapes ----------------------------------------------------
for shape in "35 passed, 2 failed, 11 advisory, 34 skipped" \
             "36 passed, 1 failed, 11 advisory, 34 skipped" \
             "37 passed, 0 failed, 11 advisory, 34 skipped"; do
  grep -qF "$shape" "$GUIDE"
  check "the guide quotes the measured line ($shape)" "$?"
done
# ...and no summary line in the guide is outside the measured set (both control installs print
# the same three shapes in v2: pre-commit, HP-05-left, green).
SHAPES=$(grep -E '^[[:space:]]*[0-9]+ passed, [0-9]+ failed, [0-9]+ advisory, [0-9]+ skipped' "$GUIDE" \
         | sed -n 's/^[[:space:]]*\([0-9]* passed, [0-9]* failed, [0-9]* advisory, [0-9]* skipped\).*/\1/p' | sort -u)
MEASURED=$(printf '%s\n' \
  "35 passed, 2 failed, 11 advisory, 34 skipped" \
  "36 passed, 1 failed, 11 advisory, 34 skipped" \
  "37 passed, 0 failed, 11 advisory, 34 skipped")
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
