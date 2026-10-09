#!/usr/bin/env bash
# t-extend.sh — batch 3: the EXTEND mechanism, proved through the PRODUCT path.
#
# A repo turns an off-by-default (library) row ON by pasting its line into the repo-local,
# versioned override `.gob/manifest/enforcement.local.tsv`. This file drives that real file -
# NOT a test-only helper - and pins the five behaviours the mechanism must have:
#
#   (a) a library row that is NOT enabled does not run (a default run never executes it);
#   (b) after pasting the snippet `gob verify --library` prints, the row DOES run and PASSES
#       on a clean tree, and the summary names it `enabled-locally`;
#   (c) the SAME row goes RED when the violation it detects is introduced, and its remedy line
#       prints under the FAIL;
#   (d) THE HONESTY GATE: a local row that names no check the engine can run is REFUSED
#       (exit 3, named remedy) and nothing is silently green. Four forms, all refused:
#         * a bare row id with no check cell (an id, no check);
#         * an id in neither the matrix nor the library;
#         * a `goblin-verify --only <ID>` marker whose builtin does not exist;
#         * a check that cannot execute (not found -> exit 127): it produced NO verdict.
#   (e) removing the snippet returns the run EXACTLY to the default set (byte-for-byte).
#
# The fixture is a real class-A install (gob init's own writer), so the row under test is the
# SCHEDULED library row with the row's own check text - not a stub.

set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
TARGET="$WORK/target"
LOCAL_REL=".gob/manifest/enforcement.local.tsv"
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

mkdir -p "$TARGET" && cd "$TARGET"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# target\n' > README.md
git add -A && git commit -q -m "chore: seed"
# The install is the writer `gob init` uses; --skills yes gives the SK-* rows their subjects.
bash "$SRC/bin/goblin-install" --target "$TARGET" --skills yes >/dev/null 2>&1
git add -A && git commit -q -m "chore: install gobstack"
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"

verify() { bash .gob/bin/goblin-verify "$@"; }

# ---- the row under test: SC-02 (the ignore rules cover the whole secret family) ---------------
# It is a LIBRARY row (off by default), it PASSES on a clean tree, and its violation is a real
# one-line edit (.gitignore loses its `.env` rule) - so (b) and (c) drive one row both ways.
ROW=SC-02

BASE=$(verify 2>&1); BASE_RC=$?
check "the fixture starts GREEN (nothing below is measured against a broken baseline)" \
  "$([ "$BASE_RC" -eq 0 ] && echo 0 || echo 1)"

# ===============================================================================================
# (a) the row is held back: a default run does not execute it, and does not name it.
# ===============================================================================================
printf '%s\n' "$BASE" | grep -qE "^(PASS|FAIL|ADV|SKIP) +$ROW\b"
check "(a) the library row $ROW does NOT run in a default verify" "$([ $? -ne 0 ] && echo 0 || echo 1)"
printf '%s\n' "$BASE" | grep -q 'enabled-locally'
check "(a)  and no enabled-locally line prints when the override is absent" \
  "$([ $? -ne 0 ] && echo 0 || echo 1)"
# The file is OPTIONAL: absent means the default set only, and nothing is said about it.
printf '%s\n' "$BASE" | grep -qi 'enforcement.local.tsv'
check "(a)  and an absent override file is silent (no noise about it)" \
  "$([ $? -ne 0 ] && echo 0 || echo 1)"

# ===============================================================================================
# (b) paste the snippet `--library` prints, then the row runs and passes on a clean tree.
# ===============================================================================================
SNIP=$(verify --library 2>&1 | sed -n "s/^          \($ROW\t.*\)\$/\1/p")
check "(b) gob verify --library prints a paste-ready snippet for $ROW (not just the id)" \
  "$([ -n "$SNIP" ] && [ "$SNIP" != "$ROW" ] && echo 0 || echo 1)"
printf '%s\n' "$SNIP" > "$LOCAL_REL"
B=$(verify 2>&1); B_RC=$?
printf '%s\n' "$B" | grep -qE "^PASS +$ROW\b"
check "(b) after pasting the snippet, $ROW runs and PASSES on the clean tree" "$?"
check "(b)  and the run stays green (exit 0)" "$([ "$B_RC" -eq 0 ] && echo 0 || echo 1)"
printf '%s\n' "$B" | grep -qE "^      enabled-locally: 1 row\(s\) added by \.gob/manifest/enforcement\.local\.tsv: $ROW\$"
check "(b)  and the summary names it enabled-locally, set apart from the default set" "$?"

# ===============================================================================================
# (c) the same row goes RED under its violation, with its remedy line.
# ===============================================================================================
cp .gitignore "$WORK/gitignore.bak"
sed -i '/^\.env$/d' .gitignore
C=$(verify --only "$ROW" 2>&1); C_RC=$?
printf '%s\n' "$C" | grep -qE "^FAIL +$ROW\b"
check "(c) $ROW goes RED under its violation (the .env rule dropped)" "$?"
check "(c)  and the run exits 1" "$([ "$C_RC" -eq 1 ] && echo 0 || echo 1)"
printf '%s\n' "$C" | grep -q '^remedy:'
check "(c)  and the row's remedy line prints under the FAIL" "$?"
cp "$WORK/gitignore.bak" .gitignore
# the controlled GREEN direction again, so the row is provably not always-red
verify --only "$ROW" >/dev/null 2>&1
check "(c)  and the row is green again once the rule is restored" "$?"

# ===============================================================================================
# (d) THE HONESTY GATE: a local row that names no check the engine can run is refused.
#     Every form exits 3 (the manifest is broken), prints a named remedy, and is never green.
# ===============================================================================================
refuse_case() { # <label> <file-content> [--only id]
  local label="$1" body="$2" only="${3:-}"
  printf '%s\n' "$body" > "$LOCAL_REL"
  local out rc
  if [ -n "$only" ]; then out=$(verify --only "$only" 2>&1); rc=$?
  else out=$(verify 2>&1); rc=$?; fi
  rm -f "$LOCAL_REL"
  check "(d) $label is REFUSED (exit 3)" "$([ "$rc" -eq 3 ] && echo 0 || echo 1)"
  printf '%s\n' "$out" | grep -q '^error: local override:'
  check "(d)   and the refusal names a remedy" "$?"
}

refuse_case "a bare id with no check cell" "HP-04"
refuse_case "a row naming an id in neither the matrix nor the library" \
  "$(printf 'ZZ-99\ttarget\tbogus\tlint\t-\tgoblin-verify --only ZZ-99\t-')"
refuse_case "a builtin marker the engine has no builtin for" \
  "$(printf 'LX-02\ttarget\ta local rule\tlint\t-\tgoblin-verify --only LX-02\t-')"
# The run-time half: a check that cannot execute exits 127 - it produced NO verdict, so it is
# refused rather than read as the FAIL the shell fold would make of it.
refuse_case "a check that cannot execute (no verdict)" \
  "$(printf 'LX-01\ttarget\ta local rule\tlint\t-\t.gob/checks/gone.sh\t-')" "LX-01"

# ===============================================================================================
# (e) removing the snippet returns the run EXACTLY to the default set.
# ===============================================================================================
rm -f "$LOCAL_REL"
E=$(verify 2>&1); E_RC=$?
check "(e) removing the snippet returns the run to the default set (same bytes as the baseline)" \
  "$([ "$E" = "$BASE" ] && echo 0 || echo 1)"
check "(e)  and it is green again (exit 0)" "$([ "$E_RC" -eq 0 ] && echo 0 || echo 1)"
printf '%s\n' "$E" | grep -q "$ROW"
check "(e)  and $ROW no longer runs at all" "$([ $? -ne 0 ] && echo 0 || echo 1)"

# ===============================================================================================
# The override also works for a repo's OWN rule (LX-*), through the same file.
# ===============================================================================================
printf 'LX-03\ttarget\ta local rule\tlint\t-\ttest -f README.md\t-\n' > "$LOCAL_REL"
F=$(verify 2>&1); F_RC=$?
printf '%s\n' "$F" | grep -qE '^PASS +LX-03\b'
check "(f) an LX-* rule with a real check runs from the same file and passes" "$?"
check "(f)  and the run is green (exit 0)" "$([ "$F_RC" -eq 0 ] && echo 0 || echo 1)"
printf '%s\n' "$F" | grep -q 'enabled-locally: 1 row(s).*LX-03'
check "(f)  and the summary names it enabled-locally" "$?"
rm -f "$LOCAL_REL"

if [ "$fail" -eq 0 ]; then note "t-extend: PASS"; else note "t-extend: FAIL"; fi
exit "$fail"
