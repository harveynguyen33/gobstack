#!/usr/bin/env bash
# t-shim.sh — the npm shim's dispatch table (v2 surface: init/map/verify/bans/uninstall).
#
#   SH1  no args: the shim prints the short usage and exits 2 — the v2 verb set, and a
#        verb absent from it (audit/upgrade/doctor/emit/sync/install, the unwired
#        commands) is named as unrecognized, never routed
#   SH2  a leading flag (-h/--help): the same usage, exit 2
#   SH3  an unrecognized first arg (`inti`): exit 2, and the usage NAMES the word
#   SH4  `install ...` is REFUSED in v2 (init replaced it): exit 2, the word named
#   SH5  `uninstall --dry-run --target <fresh install>` prints the installer's uninstall
#        plan (`would remove ...`) and exits 0 — the dispatcher's uninstall job is real
#   SH6  --version is byte-identical to VERSION (the V6 property, re-pinned here so a
#        shim edit cannot move it)
#   SH7  `map` routes to the standalone feature-map generator: --help exits 0; on a
#        fixture repo with an app/page.tsx `map --heuristic` generates features/ (exit 0);
#        on a repo with an existing features/ it refuses with exit 1 naming --force
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
for sub in init verify bans map uninstall; do
  printf '%s' "$OUT1" | grep -q "gob $sub"
  check "SH1 the usage lists $sub" "$?"
done
for gone in audit upgrade doctor emit sync install; do
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

# ---- SH7: `map` routes to the standalone generator ------------------------------
node "$SRC/bin/goblin.js" map --help > "$WORK/map9h.out" 2>&1; RC9H=$?
check "SH7 gob map --help exits 0" "$([ "$RC9H" -eq 0 ] && echo 0 || echo 1)"
grep -qc 'error:' "$WORK/map9h.out"
check "SH7 gob map --help prints no error line" "$([ $? -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT1" | grep -q 'gob map'
check "SH7 the short usage lists map" "$?"
MP="$WORK/maprepo"
mkdir -p "$MP/app"
printf 'export default function Home() { return <div>home</div> }\n' > "$MP/app/page.tsx"
OUT9=$(cd "$MP" && HOME="$HOMEDIR" node "$SRC/bin/goblin.js" map --heuristic 2>&1); RC9=$?
check "SH7 gob map --heuristic on a fixture with app/page.tsx exits 0" "$([ "$RC9" -eq 0 ] && echo 0 || echo 1)"
[ -f "$MP/features/README.md" ] && [ -f "$MP/features/home.md" ]
check "SH7 and generates features/ (index + home.md)" "$?"
OUT9B=$(cd "$MP" && HOME="$HOMEDIR" node "$SRC/bin/goblin.js" map --heuristic 2>&1); RC9B=$?
check "SH7 a second gob map --heuristic on the same repo refuses, exit 1" "$([ "$RC9B" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT9B" | grep -qF -- '--force'
check "SH7 and the refusal names --force" "$?"

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
