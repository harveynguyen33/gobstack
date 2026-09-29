#!/usr/bin/env bash
# t-doctor.sh — W4a/W4b: one run, seven platforms (W4A-SPEC §7, acceptance T1/T2).
#
#   T1  sandbox HOME with fabricated anchors for all seven platforms + emitted project
#       dirs: doctor prints all seven DETECTED, zero DRIFT, exit 0 — the E2 clause, in one run
#   T2  tamper one emitted SKILL.md byte: that platform DRIFT (named path), others
#       unchanged verdicts, exit 1; an all-NOT-DETECTED sandbox exits 2; a tampered
#       context-block VERSION drifts too
#
# Every fixture lives in a mktemp sandbox with HOME pointed inside it — no test writes
# the real $HOME. The PATH is stripped to the system dirs so the host's own hermes
# binary cannot leak a DETECTED verdict into the sandbox. Run by tests/run-tests.sh.
#
# PIPEFAIL RULE (learned twice the hard way in this file): under set -o pipefail, any
# `producer | grep -q` whose producer exits non-zero fails the pipeline even when grep
# MATCHES. Checks therefore capture output into a variable or a file first, and assert
# on the captured bytes — never pipe a possibly-failing producer into an assertion.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }
trap 'rm -rf "$WORK"' EXIT

DOCTOR="bash $SRC/bin/goblin-doctor"
EMIT="bash $SRC/bin/goblin-emit"
BARE_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
PLATFORMS="claude hermes copilot cursor opencode codex gemini"
N=$(wc -w <<<"$PLATFORMS")
new_sandbox() { # <tag> — one sandbox HOME + repo; prints nothing
  HOMEDIR="$WORK/home$1"; REPO="$WORK/repo$1"
  mkdir -p "$HOMEDIR" "$REPO"
}

# ---- T1: all seven DETECTED, zero DRIFT, exit 0, in one run ----------------------
new_sandbox t1
# anchors: the ~/.<name> dirs + opencode's ~/.config/opencode + codex's ~/.codex and ~/.agents
mkdir -p "$HOMEDIR/.claude" "$HOMEDIR/.copilot" "$HOMEDIR/.hermes" "$HOMEDIR/.cursor" \
         "$HOMEDIR/.config/opencode" "$HOMEDIR/.codex" "$HOMEDIR/.agents" "$HOMEDIR/.gemini"
for platform in $PLATFORMS; do
  $EMIT --platform "$platform" --scope project --skills core --target "$REPO" >/dev/null 2>&1
done
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR --target "$REPO" 2>&1); RC=$?
check "T1 doctor exits 0" "$RC"
printf '%s\n' "$OUT" | grep -c '  DETECTED ' > "$WORK/t1-detected.txt"
check "T1 all seven platforms print DETECTED" "$([ "$(cat "$WORK/t1-detected.txt")" -eq "$N" ]; echo $?)"
printf '%s\n' "$OUT" | grep -q 'DRIFT' && check "T1 zero DRIFT lines" 1 || check "T1 zero DRIFT lines" 0
printf '%s\n' "$OUT" | grep -c 'read 20' > "$WORK/t1-docs.txt"
check "T1 every platform names its docs pin (docs_url + docs_read)" "$([ "$(cat "$WORK/t1-docs.txt")" -eq "$N" ]; echo $?)"
for platform in $PLATFORMS; do
  printf '%s\n' "$OUT" | grep -c "^== $platform ==" > "$WORK/t1-sect.txt"
  check "T1 the report covers $platform" "$([ "$(cat "$WORK/t1-sect.txt")" -eq 1 ]; echo $?)"
done

# ---- T2a: tamper one emitted SKILL.md byte -> that platform DRIFT, exit 1 --------
TAMPER="$REPO/.claude/skills/practice/SKILL.md"
GOOD=$(cat "$TAMPER"; printf X)
printf '%s' "$GOOD" | sed 's/^name: practice$/name: practise/' > "$TAMPER"
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR --target "$REPO" 2>&1); RC=$?
check "T2 tampered SKILL.md: doctor exits 1" "$(( RC == 1 ? 0 : 1 ))"
printf '%s\n' "$OUT" | grep -q 'emitted bytes differ'
check "T2 the drifted platform names the finding" "$?"
# the DRIFT must sit INSIDE the claude section and nowhere else
AWK_PROG='BEGIN{sect=""} /^== /{sect=$2} /DRIFT/{print sect}'
printf '%s\n' "$OUT" | awk "$AWK_PROG" | sort -u > "$WORK/drift-sects.txt"
check "T2 the DRIFT is on claude (the tampered platform)" "$(grep -q '^claude$' "$WORK/drift-sects.txt"; echo $?)"
check "T2 no other platform DRIFTs" "$([ "$(wc -l < "$WORK/drift-sects.txt")" -eq 1 ]; echo $?)"
# restore: the tampered bytes are no longer goblin-owned, so re-emit would refuse (R4);
# the byte-exact restore is copying the source payload over the drifted file.
cp "$SRC/skills/practice/SKILL.md" "$TAMPER"

# ---- T2b: a stale context-block VERSION is drift ---------------------------------
for ctx in AGENTS.md CLAUDE.md GEMINI.md; do
  [ -f "$REPO/$ctx" ] && sed -i 's/goblin-stack:begin v0.4.4/goblin-stack:begin v0.0.1/' "$REPO/$ctx"
done
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR --target "$REPO" 2>&1); RC=$?
check "T2 stale marker VERSION: doctor exits 1" "$(( RC == 1 ? 0 : 1 ))"
printf '%s\n' "$OUT" | grep -q 'does not match v'
check "T2 the stale block names the VERSION mismatch" "$?"
# restore the marker VERSION
for ctx in AGENTS.md CLAUDE.md GEMINI.md; do
  [ -f "$REPO/$ctx" ] && sed -i 's/goblin-stack:begin v0.0.1/goblin-stack:begin v0.4.4/' "$REPO/$ctx"
done
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR --target "$REPO" 2>&1); RC=$?
check "T2 after the restore, doctor is clean again (exit 0)" "$RC"

# ---- T2c: an all-NOT-DETECTED sandbox exits 2 -------------------------------------
new_sandbox t2
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR 2>&1); RC=$?
check "T2 all-NOT-DETECTED sandbox: doctor exits 2" "$(( RC == 2 ? 0 : 1 ))"
printf '%s\n' "$OUT" | grep -c 'NOT-DETECTED' > "$WORK/t2-notdet.txt"
check "T2 all seven platforms print NOT-DETECTED" "$([ "$(cat "$WORK/t2-notdet.txt")" -eq "$N" ]; echo $?)"
# a bad --platform value is exit 2 with the full enum named
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR --platform nosuchplatform 2>&1); RC=$?
check "T2 unknown --platform exits 2" "$(( RC == 2 ? 0 : 1 ))"
printf '%s\n' "$OUT" | grep -q 'claude, hermes, copilot, cursor, opencode, codex, gemini'
check "T2 the refusal names the full seven-platform enum" "$?"

# ---- the single-platform selector works -------------------------------------------
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR --platform hermes 2>&1); RC=$?
check "T2 --platform hermes probes one platform (exit 2: not detected in this sandbox)" "$(( RC == 2 ? 0 : 1 ))"
printf '%s\n' "$OUT" | grep -q '^== hermes =='
check "T2 the report covers exactly the selected platform" "$?"
printf '%s\n' "$OUT" | grep -c '^== ' > "$WORK/t2-only.txt"
check "T2 the report covers ONLY the selected platform" "$([ "$(cat "$WORK/t2-only.txt")" -eq 1 ]; echo $?)"

if [ "$fail" -eq 0 ]; then note "t-doctor: PASS"; else note "t-doctor: FAIL"; fi
exit "$fail"
