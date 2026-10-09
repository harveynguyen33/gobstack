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
printf 'the referenced standard\n' > "$WORK/standard.md"
SENT_BEFORE=$(sha256sum "$WORK/outside-sentinel" | awk '{print $1}')
OUTSIDE_BEFORE=$(ls -A "$WORK" | sort)

cd "$WORK/target"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# target\n' > README.md
git add -A && git commit -q -m "chore: seed"

INSTALL="bash $SRC/bin/goblin-install --target $WORK/target --practice $WORK/standard.md"

# ---- first install -----------------------------------------------------------
OUT1=$($INSTALL 2>&1); RC1=$?
check "first install exits 0" "$RC1"
note "$(printf '%s' "$OUT1" | grep -E '^created' || echo 'no created line')"
INSTALLED_FILES=$(find . -path ./.git -prune -o -type f -print | wc -l | tr -d ' ')
check "first install creates the harness ($INSTALLED_FILES files in the tree)" \
  "$([ "$INSTALLED_FILES" -ge 20 ] && echo 0 || echo 1)"
check "the verifier landed" "$([ -x .gob/bin/goblin-verify ] && echo 0 || echo 1)"
# The installer's write set under .gob/bin is exactly the three shipped scripts (goblin-bans,
# goblin-lib.sh, goblin-verify), and the same fixture is what t-uninstall.sh asserts.
# goblin-bans joined the set in v0.3 (G5): the ban engine, installed with the table it reads.
check ".gob/bin holds exactly goblin-bans + goblin-verify + goblin-lib.sh" \
  "$([ "$(ls .gob/bin | sort | tr '\n' ' ')" = "goblin-bans goblin-lib.sh goblin-verify " ] && echo 0 || echo 1)"
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

# ---- regression pin: the gawk -v escape bug ---------------------------------
# gawk processes backslash escapes in -v assignment values, so a second rewrite of
# the AGENTS.md block used to turn a literal \b inside a value into a backspace byte.
# The block must now travel via ENVIRON (no escape processing) and round-trip the
# written file BYTE-IDENTICALLY twice, escapes and tabs intact.
BLOCK_FILE="$WORK/agents-block-pin.md"
: > "$BLOCK_FILE"
PIN_VALUE='grep -q "\bTODO\b" src && printf "a\tb\n"'
. "$WORK/target/.gob/bin/goblin-lib.sh"
g_agents_write "$BLOCK_FILE" < <(printf '%s\n' "gates_gate_cmd	$PIN_VALUE") >/dev/null
cp "$BLOCK_FILE" "$BLOCK_FILE.snap1"
g_agents_write "$BLOCK_FILE" < "$BLOCK_FILE" >/dev/null
g_agents_write "$BLOCK_FILE" < "$BLOCK_FILE" >/dev/null
check "the gob block round-trips twice byte-identically (gawk -v escape pin)" \
  "$(cmp -s "$BLOCK_FILE.snap1" "$BLOCK_FILE" && echo 0 || echo 1)"
check "a literal backslash-b survives the round-trip as text (no backspace byte)" \
  "$(grep -qF '"\bTODO\b" src' "$BLOCK_FILE" && echo 0 || echo 1)"
check "the block carries no control byte (0x08)" \
  "$(grep -qP '\x08' "$BLOCK_FILE" && echo 1 || echo 0)"
check "a tab escape inside a value survives the round-trip as text" \
  "$(grep -qF 'a\tb' "$BLOCK_FILE" && echo 0 || echo 1)"
grep 'gates_gate_cmd' "$BLOCK_FILE" | cat -A > /tmp/pin-line.txt 2>&1

# ---- a re-install after a file is deleted restores it, and reports it as created
rm -f "$WORK/target/.gob/manifest/glossary.tsv"
OUT3=$($INSTALL 2>&1)
printf '%s' "$OUT3" | grep -qE '^created 1 '
check "a deleted installed file is restored and reported as created" "$?"

if [ "$fail" -eq 0 ]; then note "t-install-idempotent: PASS"; else note "t-install-idempotent: FAIL"; fi
exit "$fail"
