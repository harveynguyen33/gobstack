#!/usr/bin/env bash
# t-install-idempotent.sh — PR-02 (a second install is a no-op) and PR-01 (the installer
# writes nothing outside its target). Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { # check <name> <condition-result>
  if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi
}

# ---- a fixture, plus a sentinel OUTSIDE the target to prove nothing else is written ----
mkdir -p "$WORK/target"
printf 'sentinel\n' > "$WORK/outside-sentinel"
printf 'profiles:\n  coder:\n    model: model-code\n    provider: prov-code\n    effort: low\n' > "$WORK/models.yaml"
printf 'the referenced standard\n' > "$WORK/standard.md"
SENT_BEFORE=$(sha256sum "$WORK/outside-sentinel" | awk '{print $1}')
OUTSIDE_BEFORE=$(ls -A "$WORK" | sort)

cd "$WORK/target"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# target\n' > README.md
git add -A && git commit -q -m "chore: seed"

INSTALL="bash $SRC/bin/goblin-install --target $WORK/target --class A --models $WORK/models.yaml --practice $WORK/standard.md"

# ---- first install -----------------------------------------------------------
OUT1=$($INSTALL 2>&1); RC1=$?
check "first install exits 0" "$RC1"
note "$(printf '%s' "$OUT1" | grep -E '^created' || echo 'no created line')"
INSTALLED_FILES=$(find . -path ./.git -prune -o -type f -print | wc -l | tr -d ' ')
check "first install creates the harness ($INSTALLED_FILES files in the tree)" \
  "$([ "$INSTALLED_FILES" -gt 20 ] && echo 0 || echo 1)"
check "the verifier landed" "$([ -x .goblin/bin/goblin-verify ] && echo 0 || echo 1)"
# The installer's write set under .goblin/bin is exactly the four shipped scripts: bin/goblin-model
# is checkout-only (docs/ROLES.md, F2-8), and the same fixture is what t-uninstall.sh asserts.
# goblin-audit joined the set in v0.2 (G4/SC-07): it is the deliberate, network-touching half of
# the dependency row, and the row that reads its record never runs it. goblin-bans joined it in
# v0.3 (G5): the ban engine, installed with the table it reads.
check ".goblin/bin holds exactly goblin-audit + goblin-bans + goblin-verify + goblin-lib.sh" \
  "$([ "$(ls .goblin/bin | sort | tr '\n' ' ')" = "goblin-audit goblin-bans goblin-lib.sh goblin-verify " ] && echo 0 || echo 1)"
# W6 neutral-first: a DEFAULT install ships no agent skills — the harness is neutral. The
# explicit opt-in (--skills yes) is what installs them, asserted in t-init.sh's flags run.
check "a default install writes NO .hermes dir (skills are opt-in)" \
  "$([ ! -e .hermes ] && echo 0 || echo 1)"

git add -A && git commit -q -m "chore: install"
STATUS_BEFORE=$(git status --porcelain)

# ---- second install ----------------------------------------------------------
OUT2=$($INSTALL 2>&1); RC2=$?
check "second install exits 0" "$RC2"
printf '%s' "$OUT2" | grep -q '^no-op:'
check "second install prints no-op" "$?"
STATUS_AFTER=$(git status --porcelain)
check "second install changes no tracked file" "$([ "$STATUS_BEFORE" = "$STATUS_AFTER" ] && echo 0 || echo 1)"

# ---- nothing outside the target ---------------------------------------------
SENT_AFTER=$(sha256sum "$WORK/outside-sentinel" | awk '{print $1}')
OUTSIDE_AFTER=$(ls -A "$WORK" | sort)
check "the sentinel outside the target is byte-identical" "$([ "$SENT_BEFORE" = "$SENT_AFTER" ] && echo 0 || echo 1)"
check "no new entry outside the target" "$([ "$OUTSIDE_BEFORE" = "$OUTSIDE_AFTER" ] && echo 0 || echo 1)"

# ---- a re-install after a file is deleted restores it, and reports it as created
rm -f "$WORK/target/.goblin/manifest/glossary.tsv"
OUT3=$($INSTALL 2>&1)
printf '%s' "$OUT3" | grep -qE '^created 1 '
check "a deleted installed file is restored and reported as created" "$?"

if [ "$fail" -eq 0 ]; then note "t-install-idempotent: PASS"; else note "t-install-idempotent: FAIL"; fi
exit "$fail"
