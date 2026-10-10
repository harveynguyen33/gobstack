#!/usr/bin/env bash
# t-skills-library.sh — the skill LIBRARY. The repo ships 18 skills in skills/, but a default
# install vendors only the 7 core ones; the rest must be SELECTABLE, not unreachable dead weight.
# This is the same shape the rule LIBRARY uses: a default set on, the rest held back, chosen
# through the one flag, and discoverable from the CLI before choosing.
#
# Run by tests/run-tests.sh.
#
#   L0  --list-skills prints every skill (name, tier, one-line purpose) — discovery, no repo opened
#   L1  a default install vendors exactly the 7 core skills; the record says skills=no; SK-02 hashes 7
#   L2  --skills all vendors all 18; the record says skills=all; SK-02 hashes 18
#   L3  a named subset vendors exactly that subset; SK-02 hashes exactly that many
#   L4  an unknown name is REFUSED with a named remedy, and nothing partial is written
#   L5  installed.json covers exactly the vendored set, no more no fewer: all -> no shrinks 18 -> 7
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

seed() { # seed <dir>
  mkdir -p "$1"
  ( cd "$1" && git init -q -b main && git config user.email t@t && git config user.name t \
    && printf '# t\n' > README.md && git add -A && git commit -qm seed ) >/dev/null 2>&1
}
install() { # install <dir> [args...]
  local d="$1"; shift
  ( cd "$d" && bash "$SRC/bin/goblin-install" --target . "$@" ) 2>&1
}
skcount() { find "$1/.gob/skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' '; }
sk02() { ( cd "$1" && bash .gob/bin/goblin-verify --only SK-02 2>/dev/null ); }
# sk02_has avoids `sk02 | grep -q`: grep -q closes the pipe the moment it matches, giving the
# upstream verifier a SIGPIPE, and `set -o pipefail` turns that into a false 141. Capture first.
sk02_has() { local out; out=$(sk02 "$1"); case "$out" in *"$2"*) return 0 ;; *) return 1 ;; esac; }
record() { grep -o '"skills": "[^"]*"' "$1/.gob/installed.json"; }

TOTAL=$(ls -d "$SRC"/skills/*/ | wc -l | tr -d ' ')

# ---- L0: the library is discoverable from the CLI, before choosing ---------------------------
LIST=$(bash "$SRC/bin/goblin-install" --list-skills)
check "L0a --list-skills names every skill in skills/ ($TOTAL, measured: $(printf '%s' "$LIST" | grep -cE '^  [a-z]'))" \
  "$(printf '%s' "$LIST" | grep -cE '^  [a-z]' | grep -qx "$TOTAL" && echo 0 || echo 1)"
check "L0b --list-skills marks exactly the 7 core tier" \
  "$(printf '%s' "$LIST" | grep -cE '^  [a-z-]+ +core ' | grep -qx 7 && echo 0 || echo 1)"
check "L0c --list-skills carries a one-line purpose for each skill" \
  "$(printf '%s' "$LIST" | grep -qE '^  goblin-eval +optional +P12:' && echo 0 || echo 1)"
check "L0d --list-skills writes nothing (no target needed)" \
  "$( cd "$WORK" && bash "$SRC/bin/goblin-install" --list-skills >/dev/null 2>&1; [ ! -e "$WORK/.gob" ] && echo 0 || echo 1)"

# ---- L1: the DEFAULT install vendors the 7 core skills --------------------------------------
seed "$WORK/def"
OUT1=$(install "$WORK/def"); RC1=$?
check "L1a a default install exits 0 (got $RC1)" "$([ "$RC1" = 0 ] && echo 0 || echo 1)"
check "L1b a default install vendors exactly 7 skills (measured: $(skcount "$WORK/def"))" \
  "$([ "$(skcount "$WORK/def")" = 7 ] && echo 0 || echo 1)"
check "L1c the record says skills=no" \
  "$(record "$WORK/def" | grep -qx '"skills": "no"' && echo 0 || echo 1)"
check "L1d SK-02 hashes 7 skill files" \
  "$(sk02_has "$WORK/def" '7 installed skill file(s) hashed' && echo 0 || echo 1)"

# ---- L2: --skills all vendors the whole library ---------------------------------------------
seed "$WORK/all"
install "$WORK/all" --skills all >/dev/null 2>&1
check "L2a --skills all vendors all $TOTAL skills (measured: $(skcount "$WORK/all"))" \
  "$([ "$(skcount "$WORK/all")" = "$TOTAL" ] && echo 0 || echo 1)"
check "L2b the record says skills=all" \
  "$(record "$WORK/all" | grep -qx '"skills": "all"' && echo 0 || echo 1)"
check "L2c SK-02 hashes $TOTAL skill files" \
  "$(sk02_has "$WORK/all" "$TOTAL installed skill file(s) hashed" && echo 0 || echo 1)"

# ---- L3: a named subset vendors exactly that subset -----------------------------------------
seed "$WORK/sub"
install "$WORK/sub" --skills goblin-eval,goblin-tdd-repro >/dev/null 2>&1
check "L3a a named subset vendors exactly those 2 (measured: $(skcount "$WORK/sub"))" \
  "$([ "$(skcount "$WORK/sub")" = 2 ] && echo 0 || echo 1)"
check "L3b the two named skills are on disk" \
  "$([ -f "$WORK/sub/.gob/skills/goblin-eval/SKILL.md" ] && [ -f "$WORK/sub/.gob/skills/goblin-tdd-repro/SKILL.md" ] && echo 0 || echo 1)"
check "L3c a skill NOT named is absent (goblin-mode)" \
  "$([ ! -e "$WORK/sub/.gob/skills/goblin-mode" ] && echo 0 || echo 1)"
check "L3d the record names exactly the subset" \
  "$(record "$WORK/sub" | grep -qx '"skills": "goblin-eval,goblin-tdd-repro"' && echo 0 || echo 1)"
check "L3e SK-02 hashes exactly 2 skill files" \
  "$(sk02_has "$WORK/sub" '2 installed skill file(s) hashed' && echo 0 || echo 1)"

# ---- L4: an unknown name is refused with a named remedy, and nothing partial is written ------
seed "$WORK/bad"
BADOUT=$(install "$WORK/bad" --skills goblin-eval,nosuchskill,goblin-mode 2>&1); BADRC=$?
check "L4a an unknown --skills name exits 2 (got $BADRC)" "$([ "$BADRC" = 2 ] && echo 0 || echo 1)"
check "L4b the refusal names the offending skill" \
  "$(printf '%s' "$BADOUT" | grep -q 'unknown --skills name(s): nosuchskill' && echo 0 || echo 1)"
check "L4c the refusal names the remedy (available set + --skills all)" \
  "$(printf '%s' "$BADOUT" | grep -q 'available:' && printf '%s' "$BADOUT" | grep -q -- '--skills all' && echo 0 || echo 1)"
check "L4d nothing partial is written (no .gob, no AGENTS.md, no HANDOFF.md)" \
  "$([ ! -e "$WORK/bad/.gob" ] && [ ! -e "$WORK/bad/AGENTS.md" ] && [ ! -e "$WORK/bad/HANDOFF.md" ] && echo 0 || echo 1)"

# ---- L5: no more, no fewer — the record covers exactly the vendored set ----------------------
# all (18) then an explicit --skills no: the 11 dropped skills must leave the record too.
seed "$WORK/shrink"
install "$WORK/shrink" --skills all >/dev/null 2>&1
( cd "$WORK/shrink" && git add -A && git commit -qm all ) >/dev/null 2>&1
install "$WORK/shrink" --skills no >/dev/null 2>&1
check "L5a --skills all -> no shrinks the tree to 7 (measured: $(skcount "$WORK/shrink"))" \
  "$([ "$(skcount "$WORK/shrink")" = 7 ] && echo 0 || echo 1)"
check "L5b the record says skills=no after the shrink" \
  "$(record "$WORK/shrink" | grep -qx '"skills": "no"' && echo 0 || echo 1)"
check "L5c SK-02 hashes 7 — no orphan left in the record" \
  "$(sk02_has "$WORK/shrink" '7 installed skill file(s) hashed' && echo 0 || echo 1)"

if [ "$fail" -eq 0 ]; then note "t-skills-library: PASS"; else note "t-skills-library: FAIL"; fi
exit "$fail"
