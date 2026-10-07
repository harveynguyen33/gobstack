#!/usr/bin/env bash
# t-shim.sh — the npm shim's dispatch table (W6 beta-UX round).
#
#   SH1  no args: the shim prints the short usage and exits 2 — it must NOT fall into
#        goblin-install the way the pre-W6 fallback did
#   SH2  a leading flag (-h/--help): the same usage, exit 2
#   SH3  an unrecognized first arg (`inti`): exit 2, and the usage NAMES the word
#   SH4  `install ...` still routes to goblin-install: its usage text comes back, exit 0
#   SH5  `uninstall --dry-run --target <fresh install>` prints the installer's uninstall
#        plan (`would remove ...`) and exits 0 — the dispatcher's uninstall job is real
#   SH6  --version is byte-identical to VERSION (the V6 property, re-pinned here so a
#        shim edit cannot move it)
#   SH7  `sync` routes to the same engine as `emit` (wizard v2 renamed the verb): the
#        two --help texts are byte-identical and the alias is in the short usage
#   SH8  the sync help/refusal prints ONCE and exits (the 78856a8 infinite-loop fix):
#        `--help` exits 0 with a single usage and no error line; bare `sync` exits 2
#        with the error exactly once, usage attached; neither repeats
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
printf '%s' "$OUT1" | grep -q 'start here: gob init'
check "SH1 the usage names the guided first step" "$?"
printf '%s' "$OUT1" | grep -q 'uninstall: npm uninstall -g @techgoblin/gobstack'
check "SH1 the usage names the npm uninstall" "$?"
for sub in verify bans audit upgrade doctor emit sync init; do
  printf '%s' "$OUT1" | grep -q "gob $sub"
  check "SH1 the usage lists $sub" "$?"
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

# ---- SH4: `install` keeps the legacy fallback ---------------------------------
OUT4=$(node "$SRC/bin/goblin.js" install --help 2>&1); RC4=$?
check "SH4 gob install --help exits 0" "$([ "$RC4" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT4" | grep -q 'drop the harness into a target repo'
check "SH4 the output is the installer's own usage" "$?"

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

# ---- SH7: `sync` is the renamed `emit` (wizard v2) ------------------------------
# Same engine, so the two --help texts are byte-identical and the alias is listed
# in the short usage. The exit contract propagates verbatim (a bad input exits 2).
node "$SRC/bin/goblin.js" sync --help > "$WORK/sync.out" 2>&1
node "$SRC/bin/goblin.js" emit --help > "$WORK/emit.out" 2>&1
cmp -s "$WORK/sync.out" "$WORK/emit.out"
check "SH7 gob sync --help and gob emit --help are byte-identical" "$?"
printf '%s' "$OUT1" | grep -q 'alias: gob emit'
check "SH7 the short usage marks sync as the emit alias" "$?"
node "$SRC/bin/goblin.js" sync --platform nosuch >/dev/null 2>&1
check "SH7 a bad sync platform carries emit's exit-2 contract" "$([ $? -eq 2 ] && echo 0 || echo 1)"

# ---- SH8: the sync help/refusal prints ONCE (the 78856a8 infinite-loop fix) ------
# Pre-fix, `gob sync --help` and bare `gob sync` spun `error: emit: --platform is
# required` forever (178+ lines measured in the UX review). The regression shape: the
# error marker must appear EXACTLY once, help exits 0 with no error line at all, bare
# sync exits 2 — and a second run must produce byte-identical output, so a loop that
# merely prints fewer copies cannot sneak back.
node "$SRC/bin/goblin.js" sync --help > "$WORK/sync8h.out" 2>&1; RC8H=$?
check "SH8 gob sync --help exits 0" "$([ "$RC8H" -eq 0 ] && echo 0 || echo 1)"
grep -qc 'error:' "$WORK/sync8h.out"
check "SH8 gob sync --help prints no error line (help is not the refusal path)" "$([ $? -eq 1 ] && echo 0 || echo 1)"
node "$SRC/bin/goblin.js" sync > "$WORK/sync8a.out" 2>&1; RC8A=$?
node "$SRC/bin/goblin.js" sync > "$WORK/sync8b.out" 2>&1
check "SH8 bare gob sync exits 2" "$([ "$RC8A" -eq 2 ] && echo 0 || echo 1)"
ERR_N=$(grep -c 'error: emit: --platform is required' "$WORK/sync8a.out")
check "SH8 bare gob sync prints the error exactly once (found: $ERR_N)" "$([ "$ERR_N" -eq 1 ] && echo 0 || echo 1)"
cmp -s "$WORK/sync8a.out" "$WORK/sync8b.out"
check "SH8 bare gob sync is deterministic run to run (no loop residue)" "$?"
printf '%s' "$(cat "$WORK/sync8a.out")" | grep -q 'gob sync --platform'
check "SH8 the refusal carries the usage (the fix prints help WITH the error)" "$?"

rm -rf "$WORK"
FAIL_N=$(grep -c . "$FAILFILE" 2>/dev/null || true)
if [ "${FAIL_N:-0}" -eq 0 ]; then
  printf '      t-shim: ALL-OK\n'
  exit 0
fi
printf '      t-shim: FAILED (%s)\n' "$FAIL_N"
exit 1
