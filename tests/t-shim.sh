#!/usr/bin/env bash
# t-shim.sh — the npm shim's dispatch table (v2 surface: init/verify/bans/mcp/uninstall).
#
#   SH1  no args: the shim prints the short usage and exits 2 — the v2 verb set, and a
#        verb absent from it (map/audit/upgrade/doctor/emit/sync/install, the unwired
#        or folded commands) is named as unrecognized, never routed
#   SH2  a leading flag (-h/--help): the same usage, exit 2
#   SH3  an unrecognized first arg (`inti`): exit 2, and the usage NAMES the word
#   SH4  `install ...` is REFUSED in v2 (init replaced it): exit 2, the word named
#   SH5  `uninstall --dry-run --target <fresh install>` prints the installer's uninstall
#        plan (`would remove ...`) and exits 0 — the dispatcher's uninstall job is real
#   SH6  --version is byte-identical to VERSION (the V6 property, re-pinned here so a
#        shim edit cannot move it)
#   SH7  `map` is FOLDED into init: the verb is gone from the usage and `gob map` is
#        refused as unrecognized (exit 2) — there is no standalone generator any more
#
# Everything runs against the checkout's bin/goblin.js; the uninstall probe installs
# into a mktemp repo under a throwaway HOME, like t-init.sh does.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
HOMEDIR="$WORK/home"
FAILFILE="$WORK/fails"; : > "$FAILFILE"
note() { printf '      %s\n' "$*"; }
check() {
  if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; printf '%s\n' "$1" >> "$FAILFILE"; fi
}
mkdir -p "$HOMEDIR"

# ---- SH1: no args --------------------------------------------------------------
OUT1=$(node "$SRC/bin/goblin.js" 2>&1); RC1=$?
check "SH1 no args exits 2" "$([ "$RC1" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT1" | grep -q 'start here: npx @techgoblin/gobstack init'
check "SH1 the usage names the npx first step" "$?"
printf '%s' "$OUT1" | grep -q 'uninstall: npm uninstall -g @techgoblin/gobstack'
check "SH1 the usage names the npm uninstall" "$?"
for sub in init verify bans uninstall; do
  printf '%s' "$OUT1" | grep -q "gob $sub"
  check "SH1 the usage lists $sub" "$?"
done
for gone in map audit upgrade doctor emit sync install; do
  node "$SRC/bin/goblin.js" "$gone" >/dev/null 2>&1
  check "SH1 the unwired verb $gone is refused (exit 2)" "$([ $? -eq 2 ] && echo 0 || echo 1)"
done

# ---- SH2: a leading flag -------------------------------------------------------
OUT2=$(node "$SRC/bin/goblin.js" --help 2>&1); RC2=$?
check "SH2 --help exits 2" "$([ "$RC2" -eq 2 ] && echo 0 || echo 1)"
[ "$OUT1" = "$OUT2" ]
check "SH2 --help prints the same usage as no args" "$?"
node "$SRC/bin/goblin.js" -h >/dev/null 2>&1
check "SH2 -h exits 2 too" "$([ $? -eq 2 ] && echo 0 || echo 1)"

# ---- SH3: an unrecognized first arg -------------------------------------------
OUT3=$(node "$SRC/bin/goblin.js" inti 2>&1); RC3=$?
check "SH3 the typo \`inti\` exits 2" "$([ "$RC3" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT3" | grep -q 'unrecognized command: inti'
check "SH3 the refusal names the unknown word" "$?"

# ---- SH4: `install` is refused in v2 (init replaced it) ------------------------
OUT4=$(node "$SRC/bin/goblin.js" install --help 2>&1); RC4=$?
check "SH4 gob install exits 2 (the verb is unwired)" "$([ "$RC4" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT4" | grep -q 'unrecognized command: install'
check "SH4 and the refusal names install" "$?"

# ---- SH5: `uninstall` is a real job --------------------------------------------
P="$WORK/probe"
mkdir -p "$P"
(
  cd "$P" || exit 1
  git init -q -b main
  git config user.name "Test Runner"
  git config user.email "runner@example.com"
  printf '# probe\n' > README.md
  git add -A && git commit -q -m seed
) >/dev/null 2>&1
HOME="$HOMEDIR" bash "$SRC/bin/goblin-install" --target "$P" --class A >/dev/null 2>&1
OUT5=$(HOME="$HOMEDIR" node "$SRC/bin/goblin.js" uninstall --dry-run --target "$P" 2>&1); RC5=$?
check "SH5 goblin uninstall --dry-run exits 0" "$([ "$RC5" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT5" | grep -q 'would remove'
check "SH5 the uninstall plan is the installer's (would remove ...)" "$?"

# ---- SH6: --version byte-identical --------------------------------------------
node "$SRC/bin/goblin.js" --version > "$WORK/v.out" 2>/dev/null
cmp -s "$WORK/v.out" "$SRC/VERSION"
check "SH6 --version prints VERSION byte-for-byte" "$?"

# ---- SH7: `map` is folded into init — the verb is gone ---------------------------
if printf '%s' "$OUT1" | grep -q 'gob map'; then MAPLIST=1; else MAPLIST=0; fi
check "SH7 the short usage does NOT list map (folded into init)" "$MAPLIST"
OUT7=$(node "$SRC/bin/goblin.js" map 2>&1); RC7=$?
check "SH7 gob map is refused (exit 2)" "$([ "$RC7" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT7" | grep -q 'unrecognized command: map'
check "SH7 and the refusal names the word it did not know" "$?"
printf '%s' "$OUT7" | grep -q 'gob init'
check "SH7 and the usage points at init" "$?"

# Count the failure file BEFORE the workdir is removed, and with wc (grep -c prints 0
# AND exits 1 on an empty file; with `|| true` that made FAIL_N empty, `${FAIL_N:-0}`
# then read 0, and a fully-red run reported ALL-OK).
FAIL_N=$(wc -l < "$FAILFILE" | tr -d ' ')
rm -rf "$WORK"
if [ "${FAIL_N:-0}" -eq 0 ]; then
  printf '      t-shim: ALL-OK\n'
  exit 0
fi
printf '      t-shim: FAILED (%s)\n' "$FAIL_N"
exit 1
