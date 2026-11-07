#!/usr/bin/env bash
# t-ag01-rows.sh — AG-01 (CURATION-2026-11-07 §2 C6): an instruction file changes only with
# a recorded approval. The exact operator drill, in a throwaway repo: approve -> green, a
# quiet AGENTS.md edit -> red naming the file + both hashes + the fix command, a record
# whose reason names a DIFFERENT file must not clear the edit, re-approve -> green, no
# record at all -> SKIP rc 3 (an existing install never turns red by upgrading), and the
# npm shim routes the verb. The per-clause negative controls (record planted, edit planted)
# also live in tests/t-verify-red.sh so the README census counts them.
#
# Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
T="$WORK/target"
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

mkdir -p "$T" && cd "$T"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# drill\n' > README.md
git add -A && git commit -q -m "chore: seed"
bash "$SRC/bin/goblin-install" --target "$T" >/dev/null 2>&1
git add -A && git commit -q -m "chore: install gobstack"
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"

# ---- run 0: a plain install carries no record -> SKIP, and the run stays green ----------
out=$(bash .gob/bin/goblin-verify --only AG-01 2>&1); rc=$?
[ "$rc" -eq 3 ] && printf '%s' "$out" | grep -q 'no approval record; run gob approve-agents'
check "AG-01: no record is a SKIP (rc 3) with the reason, not red" "$?"
out=$(bash .gob/bin/goblin-verify 2>&1); rc=$?
check "AG-01: a full run that skips the row still exits 0" "$rc"

# ---- run 1: approve, then PASS printing date + approver ----------------------------------
out=$(bash .gob/bin/goblin-approve "day one" 2>&1); rc=$?
check "gob approve-agents \"day one\" exits 0" "$rc"
printf '%s' "$out" | grep -q '\.gob/agents\.approved'
check "  and prints the record path" "$?"
[ "$(grep -c . .gob/agents.approved)" -eq 1 ]
check "  and the record holds exactly one row" "$?"
[ "$(awk -F'\t' 'END{print NF}' .gob/agents.approved)" -eq 4 ]
check "  with 4 tab-separated fields (date sha256 approver reason)" "$?"
[ "$(awk -F'\t' 'END{print $3}' .gob/agents.approved)" = "Test Runner" ]
check "  and the approver defaulted to the git user.name" "$?"
out=$(bash .gob/bin/goblin-verify --only AG-01 2>&1); rc=$?
[ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'PASS  AG-01'
check "AG-01: --only AG-01 is GREEN after the approval" "$?"
printf '%s' "$out" | grep -q "$(date +%F).*Test Runner"
check "  printing the date and the approver" "$?"

# ---- run 2: a quiet AGENTS.md edit is RED, naming file + both hashes + the fix ----------
printf '\n# a quiet gate edit\n' >> AGENTS.md
out=$(bash .gob/bin/goblin-verify --only AG-01 2>&1); rc=$?
[ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'FAIL  AG-01'
check "AG-01: AGENTS.md edited with no approval is RED (rc 1)" "$?"
printf '%s' "$out" | grep -q 'AGENTS.md changed with no recorded approval'
check "  naming the violation" "$?"
printf '%s' "$out" | grep -q 'recorded[[:space:]]*[0-9a-f]\{64\}'
check "  the recorded hash" "$?"
printf '%s' "$out" | grep -q 'actual[[:space:]]*[0-9a-f]\{64\}'
check "  the actual hash" "$?"
printf '%s' "$out" | grep -q 'gob approve-agents'
check "  and the exact fix command" "$?"

# ---- run 3: the different-file trap — a reason naming another file clears nothing -------
printf '%s\t%s\t%s\t%s\n' "2026-01-01" "$(awk -F'\t' 'END{print $2}' .gob/agents.approved)" \
  "Test Runner" "approved the docs/LIMITS.md rewrite" >> .gob/agents.approved
out=$(bash .gob/bin/goblin-verify --only AG-01 2>&1); rc=$?
[ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'FAIL  AG-01'
check "AG-01: a record whose reason names a different file does not clear the edit" "$?"

# ---- run 4: the deliberate re-approve is green again -------------------------------------
out=$(bash .gob/bin/goblin-approve "raised the test gate" 2>&1); rc=$?
check "gob approve-agents \"raised the test gate\" exits 0" "$rc"
out=$(bash .gob/bin/goblin-verify --only AG-01 2>&1); rc=$?
[ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'PASS  AG-01'
check "AG-01: green after the re-approval" "$?"
[ "$(grep -c . .gob/agents.approved)" -eq 3 ]
check "  and the history stayed append-only (3 rows, latest wins)" "$?"

# ---- run 5: the skip path — the record deleted is rc 3, never 1 --------------------------
rm -f .gob/agents.approved
out=$(bash .gob/bin/goblin-verify --only AG-01 2>&1); rc=$?
[ "$rc" -eq 3 ] && printf '%s' "$out" | grep -q 'no approval record; run gob approve-agents'
check "AG-01: the record deleted is a SKIP (rc 3) with the reason" "$?"
out=$(bash .gob/bin/goblin-verify 2>&1); rc=$?
check "AG-01: and the full run stays exit 0 (an upgrade never re-reds an install)" "$rc"

# ---- run 6: the npm shim routes the verb --------------------------------------------------
git checkout -q -- AGENTS.md
out=$(node "$SRC/bin/goblin.js" approve-agents "via the shim" --approver ShimTest 2>&1); rc=$?
check "gob approve-agents through the shim exits 0" "$rc"
[ "$(awk -F'\t' 'END{print $3}' .gob/agents.approved)" = "ShimTest" ]
check "  --approver overrides the git identity" "$?"
out=$(bash .gob/bin/goblin-verify --only AG-01 2>&1); rc=$?
check "AG-01: green through the shim-written record" "$rc"

# ---- the rows a new enforcement row must not disturb --------------------------------------
out=$(bash .gob/bin/goblin-verify --only IN-03,SK-03 2>&1); rc=$?
check "IN-03 and SK-03 stay green with the new row in the matrix" "$rc"
out=$(bash .gob/bin/goblin-verify 2>&1); rc=$?
check "the full run is GREEN again after every planted violation was removed" "$rc"

cd /
rm -rf "$WORK"
if [ "$fail" -eq 0 ]; then note "t-ag01-rows: PASS"; else note "t-ag01-rows: FAIL"; fi
exit "$fail"
