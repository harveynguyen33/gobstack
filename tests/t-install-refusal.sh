#!/usr/bin/env bash
# t-install-refusal.sh — the installer's documented refusal contract.
#
#   D1  a file goblin-stack did not create is never overwritten (it used to be clobbered
#       silently, against docs/GUIDE.md and the installer's own header)
#   D2  a refusal exits 1 with the path (it used to print the refusal and exit 0, so a wrapper
#       could not detect it)
#   D11 --force is the documented override, and it takes over a file that existed before the
#       install rather than leaving it byte-identical
#
# Run by tests/run-tests.sh.
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

# The three files a real project is most likely to own already: its own harness in the same
# directory goblin-stack scaffolds into, a skill with the same name, and a HANDOFF.
mkdir -p checks .hermes/skills/goblin-handoff
printf '// MY OWN HARNESS - do not touch\n' > checks/assert.mjs
printf -- '--- my own skill, before ---\n' > .hermes/skills/goblin-handoff/SKILL.md
printf '# my own handoff\n' > HANDOFF.md
OWN_ASSERT=$(sha256sum checks/assert.mjs | awk '{print $1}')
OWN_SKILL=$(sha256sum .hermes/skills/goblin-handoff/SKILL.md | awk '{print $1}')
OWN_HANDOFF=$(sha256sum HANDOFF.md | awk '{print $1}')

INSTALL="bash $SRC/bin/goblin-install --target $WORK/target --practice $WORK/standard.md"

# ---- D1 + D2: the refusal ----------------------------------------------------
OUT1=$($INSTALL 2>&1); RC1=$?
note "$(printf '%s' "$OUT1" | grep -E 'refused to overwrite|^created' | tr '\n' '|')"
check "a refusal exits 1 (D2)" "$([ "$RC1" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT1" | grep -q 'refused to overwrite:'
check "the refusal names the paths" "$?"
check "the project's own checks/assert.mjs survives (D1)" \
  "$([ "$(sha256sum checks/assert.mjs | awk '{print $1}')" = "$OWN_ASSERT" ] && echo 0 || echo 1)"
check "the project's own .hermes skill survives (D1)" \
  "$([ "$(sha256sum .hermes/skills/goblin-handoff/SKILL.md | awk '{print $1}')" = "$OWN_SKILL" ] && echo 0 || echo 1)"
check "the project's own HANDOFF.md survives (D1)" \
  "$([ "$(sha256sum HANDOFF.md | awk '{print $1}')" = "$OWN_HANDOFF" ] && echo 0 || echo 1)"
check "the installer still landed its own verifier" "$([ -x .gob/bin/goblin-verify ] && echo 0 || echo 1)"
check "the refusal is recorded in installed.json" \
  "$(grep -q 'checks/assert.mjs' .gob/installed.json && echo 0 || echo 1)"
check "the installer did not claim the refused file as installed" \
  "$(awk '/"files"/{f=1} /"owned"/{f=0} f && /checks\/assert.mjs/{n=1} END{exit (n?1:0)}' .gob/installed.json && echo 0 || echo 1)"

git add -A && git commit -q -m "chore: install (with refusals)"
OUTV=$(bash .gob/bin/goblin-verify --only IN-04 2>&1); RCV=$?
printf '%s' "$OUTV" | grep -q 'pre-existing file(s) left untouched'
check "IN-04 reports the refused files as left untouched" "$([ "$RCV" -eq 0 ] && echo 0 || echo 1)"

# ---- D11: --force is the override -------------------------------------------
OUT2=$($INSTALL --force 2>&1); RC2=$?
note "$(printf '%s' "$OUT2" | grep -E 'taken over|^created' | tr '\n' '|')"
check "--force exits 0" "$([ "$RC2" -eq 0 ] && echo 0 || echo 1)"
check "--force takes the pre-existing harness over (D11)" \
  "$([ "$(sha256sum checks/assert.mjs | awk '{print $1}')" != "$OWN_ASSERT" ] && echo 0 || echo 1)"
check "--force takes the pre-existing HANDOFF over (D11)" \
  "$([ "$(sha256sum HANDOFF.md | awk '{print $1}')" != "$OWN_HANDOFF" ] && echo 0 || echo 1)"

# ---- a re-install at the same version is a no-op -----------------------------
git add -A && git commit -q -m "chore: install (forced)"
OUT3=$($INSTALL 2>&1); RC3=$?
printf '%s' "$OUT3" | grep -q '^no-op:'
check "a second install is a no-op" "$?"
check "and it exits 0" "$([ "$RC3" -eq 0 ] && echo 0 || echo 1)"

# ---- W5-3: an explicitly named --practice that does not resolve is REPORTED ------------------
# A flag the operator wrote and the tool ignored in silence is the same species as a mechanism
# documented with nothing asserting it: exit 0, `practice: ~`, and no line about it in the log at
# all (`grep -c practice` over the install output was 0 for the flag). The DEFAULT case - no
# --practice on the command line - stays silent, because there is no flag to answer for; that is
# why the control has to NAME the path. --force is used so the install is not the same-version
# no-op above and actually reaches the practice pin.
OUT4=$(bash "$SRC/bin/goblin-install" --target "$WORK/target" \
        --practice "$WORK/absent-standard.md" --force 2>&1); RC4=$?
printf '%s' "$OUT4" | grep -q -e '--practice .*absent-standard.md does not exist'
check "W5-3: an explicit --practice that does not resolve is reported" "$?"
printf '%s' "$OUT4" | grep -q -e 'practice: and practice_sha256: stay empty'
check "  and the report says what the operator is left with" "$?"
OUT5=$(bash "$SRC/bin/goblin-install" --target "$WORK/target" \
        --force 2>&1); RC5=$?
printf '%s' "$OUT5" | grep -q -e 'does not exist' && SILENT=1 || SILENT=0
check "  no --practice on the command line stays silent, and still exits 0" \
  "$([ "$SILENT" -eq 0 ] && [ "$RC5" -eq 0 ] && echo 0 || echo 1)"

if [ "$fail" -eq 0 ]; then note "t-install-refusal: PASS"; else note "t-install-refusal: FAIL"; fi
exit "$fail"
