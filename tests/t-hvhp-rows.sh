#!/usr/bin/env bash
# t-hvhp-rows.sh — the curation phase-1 rows (CURATION-2026-11-07 §6), RED on demand in a
# throwaway repo. Each row gets its exact violation planted, must exit 1 naming the file and
# the reason, and must return to exit 0 when the violation is removed — the drill an operator
# runs before trusting the row on a real repo. The per-clause controls (both HV-02 clauses,
# the marker escapes) live in t-verify-red.sh; this file pins one violation per row, red then
# green, plus the two rows a new enforcement row must not disturb (IN-03, SK-03).
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
# name the HEAD the way a real round does, so the only red below is the planted one
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"

out=$(bash .gob/bin/goblin-verify 2>&1); rc=$?
check "the throwaway repo starts GREEN with the new row(s) on it" "$rc"

# ---- HV-02: a number taken from a live surface carries its guard ------------------------------
printf '%s\n' \
  'const box = document.querySelector("#shot").getBoundingClientRect();' \
  'assert("inside", box.bottom < 4096);' > checks/hv02-drill.mjs
out=$(bash .gob/bin/goblin-verify --only HV-02 2>&1); rc=$?
[ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'checks/hv02-drill.mjs'
check "HV-02: an unguarded bounding box is RED, naming the file" "$?"
printf '%s' "$out" | grep -q 'viewport guard'
check "  and the reason" "$?"
rm -f checks/hv02-drill.mjs
out=$(bash .gob/bin/goblin-verify --only HV-02 2>&1); rc=$?
check "HV-02: the violation removed is GREEN" "$rc"

# ---- HP-06: open is not a shape ---------------------------------------------------------------
awk '/^## Next steps$/ && !d { print; print "- Ship the thing."; d = 1; next } { print }' HANDOFF.md > HANDOFF.md.new && mv HANDOFF.md.new HANDOFF.md
out=$(bash .gob/bin/goblin-verify --only HP-06 2>&1); rc=$?
[ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'HANDOFF.md: an open item'
check "HP-06: an open item is RED, naming HANDOFF.md" "$?"
printf '%s' "$out" | grep -q 'carries no date'
check "  and the reason" "$?"
git checkout -q -- HANDOFF.md
out=$(bash .gob/bin/goblin-verify --only HP-06 2>&1); rc=$?
check "HP-06: the violation removed is GREEN" "$rc"

# ---- HV-01: the input the check uses is the input the user gets -------------------------------
printf '%s\n' \
  'const doc = { nodes: [{ id: "a", x: 0, y: 0 }] };' \
  'assert("has nodes", doc.nodes.length === 1);' > checks/hv01-drill.mjs
out=$(bash .gob/bin/goblin-verify --only HV-01 2>&1); rc=$?
[ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'checks/hv01-drill.mjs'
check "HV-01: a hand-written doc literal is RED, naming the file" "$?"
printf '%s' "$out" | grep -q 'produced_by'
check "  and the reason" "$?"
rm -f checks/hv01-drill.mjs
out=$(bash .gob/bin/goblin-verify --only HV-01 2>&1); rc=$?
check "HV-01: the violation removed is GREEN" "$rc"

# ---- the rows a new enforcement row must not disturb ------------------------------------------
out=$(bash .gob/bin/goblin-verify --only IN-03,SK-03 2>&1); rc=$?
check "IN-03 and SK-03 stay green with the new row(s) in the matrix" "$rc"

out=$(bash .gob/bin/goblin-verify 2>&1); rc=$?
check "the full run is GREEN again after every planted violation was removed" "$rc"

cd /
rm -rf "$WORK"
if [ "$fail" -eq 0 ]; then note "t-hvhp-rows: PASS"; else note "t-hvhp-rows: FAIL"; fi
exit "$fail"
