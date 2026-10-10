#!/usr/bin/env bash
# t-verify-green.sh — a correctly installed and committed target verifies GREEN, and the
# summary line reports the advisory count. Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

printf 'the referenced standard\n' > "$WORK/standard.md"

mkdir -p "$WORK/target" && cd "$WORK/target"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# target\n' > README.md
git add -A && git commit -q -m "chore: seed"

bash "$SRC/bin/goblin-install" --target "$WORK/target" --practice "$WORK/standard.md" >/dev/null 2>&1
check "install exits 0" "$?"
git add -A && git commit -q -m "chore: install gobstack"

# P9: the HANDOFF names the HEAD it describes. Committing the HANDOFF moves HEAD, so the
# check accepts any commit that exists in the repo and is an ancestor of HEAD.
HEAD_NOW=$(git rev-parse --short HEAD)
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$HEAD_NOW\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"

OUT=$(bash .gob/bin/goblin-verify 2>&1); RC=$?
printf '%s\n' "$OUT" | sed 's/^/      /'
check "verify exits 0" "$RC"
printf '%s' "$OUT" | grep -qE '[0-9]+ passed, 0 failed, [0-9]+ advisory'
check "the summary line reports passed/failed/advisory" "$?"
printf '%s' "$OUT" | grep -q 'cannot see'
check "the run states what it cannot see" "$?"
printf '%s' "$OUT" | grep -q 'not signed'
check "the run says the record every drift check trusts is not signed (F2-3)" "$?"
printf '%s' "$OUT" | grep -q 'library: 32 off-by-default row(s)'
check "the summary counts the off-by-default library (HS-02/PG-03 live there, held back)" "$?"
printf '%s' "$OUT" | grep -q 'gob verify --library'
check "  and the summary names the discovery surface for the off rows" "$?"

# ---- the ban table self-selects per row: GLOB or `dep:` PREDICATE (FIX 1) ---------------------
# A ban is code-shaped: it runs only when the repo actually HAS the stack it polices, and a ban
# with no surface REPORTS itself not applicable, never silently green. Two applicability forms:
#   * a GLOB (BN-01/02/03/05): the ban runs when at least one real file matches;
#   * `dep:<pkg>` (BN-06..09): the ban runs only when package.json names the package under
#     dependencies or devDependencies. This tree has NEITHER .ts source NOR a package.json, so ALL
#     eight bans report themselves not applicable. This is the FIX-1 false green: the electron
#     bans' globs used to include `**/*.mjs`, which matched the harness's OWN shipped
#     checks/*.mjs, so on a repo with no electron they RAN and PASSED vacuously.
printf '%s' "$OUT" | grep -qE 'SKIP  BN-01 .*not applicable: no file matches applies_when'
check "a ban the tree has no surface for reports itself NOT APPLICABLE" "$?"
printf '%s' "$OUT" | grep -qE 'SKIP  BN-06 .*not applicable: no package' && \
printf '%s' "$OUT" | grep -qE 'SKIP  BN-07 .*not applicable: no package' && \
printf '%s' "$OUT" | grep -qE 'SKIP  BN-08 .*not applicable: no package' && \
printf '%s' "$OUT" | grep -qE 'SKIP  BN-09 .*not applicable: no package'
check "FIX 1: the four electron bans report NOT APPLICABLE on a repo with no package.json" "$?"
printf '%s' "$OUT" | grep -qE '^PASS  BN-06'
check "FIX 1: and NONE of them RUNS on the harness's own shipped checks/*.mjs (no false green)" \
  "$([ $? -ne 0 ] && echo 0 || echo 1)"
# The predicate's positive half: declare electron and the SAME ban RUNS (no file matches its scope,
# so it PASSes on a clean tree, but the point is it is no longer not-applicable).
printf '{"name":"x","devDependencies":{"electron":"^30"}}\n' > package.json
git add -A >/dev/null 2>&1; git commit -q -m "test: declare electron"
printf '%s' "$(bash .gob/bin/goblin-verify --only BN-06 2>&1)" | grep -qE '^PASS  BN-06'
check "FIX 1: once package.json names electron, the same ban RUNS (predicate selects it)" "$?"
rm -f package.json; git add -A >/dev/null 2>&1; git commit -q -m "test: drop the electron dep"


# ---- UX pass: remedy lines, day-one banners, recovery lines, GT-03's sentence --------------
# (review 1 scope 4-7) Five print contracts live in the printers and the summary block:
#   R1  the matrix's remedy column rides under a FAIL (g_fail -> g_remedy, _GOB_MANIFEST) -
#       absent under every PASS, whole under --only, width-truncated in the default listing.
#       A GREEN RUN prints no `remedy:` line at all: every row above the summary is PASS/ADV/SKIP
#       and none of the three RED-direction remedy lines may appear.
#   R3  the fresh-clone banner (fresh_clone) - only under a red run, commit-count keyed
#   R4  GT-03's failure line is a sentence, not the raw test(1) dump
# Pinned here in the GREEN direction (the red direction is t-verify-red.sh's, which must
# produce the violation itself): a green run prints none of it.
BAD_REMEDIES=$(printf '%s' "$OUT" | grep -c '^remedy:')
[ -z "$OUT" ] && BAD_REMEDIES=0
[ "$BAD_REMEDIES" -eq 0 ]
check "R1 a green run prints no remedy: line (none under a PASS/ADV/SKIP row)" "$?"
printf '%s' "$OUT" | grep -q 'fresh clone detected'
check "R3 a green run prints no fresh-clone banner" "$([ $? -ne 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -q 'the gate line is older than the last commit'
check "R4 a green run prints no GT-03 staleness sentence" "$([ $? -ne 0 ] && echo 0 || echo 1)"

# R5: the fresh-clone banner is keyed on COMMIT COUNT ONLY (the mtime-vs-reflog branch fired
# after every ordinary GT-02 write and lingered on aged repos). A repo under 3 commits with a
# failing row gets the banner; the same repo AGED past 3 commits with the same failing row and
# repeated GT-02 writes stays silent.
mkdir -p "$WORK/fresh" && cd "$WORK/fresh"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# fresh\n' > README.md
git add -A && git commit -q -m "seed"
bash "$SRC/bin/goblin-install" --target . >/dev/null 2>&1
rm HANDOFF.md
git add -A && git commit -q -m "install gobstack"
FOUT2=$(bash .gob/bin/goblin-verify 2>&1); FRC2=$?
check "R5a the 2-commit probe fails for the planted reason (HP-01, exit 1)" "$([ "$FRC2" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$FOUT2" | grep -q 'fresh clone detected: some of these fails are not yours'
check "R5b the fresh-clone banner fires under 3 commits" "$?"
git commit -q --allow-empty -m "third commit"
git commit -q --allow-empty -m "fourth commit"
FOUT3=$(bash .gob/bin/goblin-verify 2>&1)
FOUT4=$(bash .gob/bin/goblin-verify 2>&1); FRC4=$?
check "R5d the aged probe still fails for the same planted reason (exit 1)" "$([ "$FRC4" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$FOUT4" | grep -q 'fresh clone detected'
check "R5e the banner is SILENT on the aged repo after two GT-02 rewrites (mtime branch gone)" "$([ $? -ne 0 ] && echo 0 || echo 1)"

# ---- UX-vi: the sign-off is the mascot on green, the first-FAIL remedy on red -------------
# (locked v2 decision, re-landed on the engine after the init rewrite dropped it): a GREEN
# run ends on "the goblin sees you. keep the gate green." — a RED run replaces it with the
# concrete first command. Pinned both directions: green here, red in t-verify-red.sh (UX-vi).
printf '%s' "$OUT" | grep -qF '▙ the goblin sees you. keep the gate green.'
check "UX-vi the green run ends on the mascot sign-off" "$?"
printf '%s' "$OUT" | grep -qF 'start with the first FAIL above'
check "  and no red tail on a green run" "$([ $? -ne 0 ] && echo 0 || echo 1)"

if [ "$fail" -eq 0 ]; then note "t-verify-green: PASS"; else note "t-verify-green: FAIL"; fi
exit "$fail"
