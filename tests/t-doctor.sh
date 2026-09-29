#!/usr/bin/env bash
# t-doctor.sh — W4a: one run, three platforms (W4A-SPEC §7, acceptance T1/T2).
#
#   T1  sandbox HOME with fabricated ~/.claude, ~/.copilot, ~/.hermes + emitted project
#       dirs: goblin doctor prints all three DETECTED, zero DRIFT, exit 0 — the E2
#       clause, in one run
#   T2  tamper one emitted SKILL.md byte: that platform DRIFT (named path), others
#       unchanged verdicts, exit 1; an all-NOT-DETECTED sandbox exits 2; a tampered
#       context-block VERSION drifts too
#
# Every fixture lives in a mktemp sandbox with HOME pointed inside it — no test writes
# the real $HOME. The PATH is stripped to the system dirs so the host's own hermes
# binary cannot leak a DETECTED verdict into the sandbox. Run by tests/run-tests.sh.
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
new_sandbox() { # <tag> — one sandbox HOME + repo; prints nothing
  HOMEDIR="$WORK/home$1"; REPO="$WORK/repo$1"
  mkdir -p "$HOMEDIR" "$REPO"
}

# ---- T1: all three DETECTED, zero DRIFT, exit 0, in one run ----------------------
new_sandbox t1
mkdir -p "$HOMEDIR/.claude" "$HOMEDIR/.copilot" "$HOMEDIR/.hermes"
for platform in claude copilot; do
  $EMIT --platform "$platform" --scope project --skills core --target "$REPO" >/dev/null 2>&1
done
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR --target "$REPO" 2>&1); RC=$?
check "T1 doctor exits 0" "$RC"
printf '%s\n' "$OUT" | grep -c '  DETECTED ' | grep -q '^3$'
check "T1 all three platforms print DETECTED" "$?"
printf '%s\n' "$OUT" | grep -q 'DRIFT' && check "T1 zero DRIFT lines" 1 || check "T1 zero DRIFT lines" 0
# docs pin present per platform (docs_url + docs_read from adapter.tsv)
printf '%s\n' "$OUT" | grep -c 'read 20' | grep -q '^3$'
check "T1 every platform names its docs pin (docs_url + docs_read)" "$?"

# ---- T2a: tamper one emitted SKILL.md byte -> that platform DRIFT, exit 1 --------
TAMPER="$REPO/.claude/skills/practice/SKILL.md"
GOOD=$(cat "$TAMPER"; printf X)
printf '%s' "$GOOD" | sed 's/^name: practice$/name: practise/' > "$TAMPER"
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR --target "$REPO" 2>&1); RC=$?
check "T2 tampered SKILL.md: doctor exits 1" "$(( RC == 1 ? 0 : 1 ))"
printf '%s\n' "$OUT" | grep -q 'emitted bytes differ'
check "T2 the drifted platform names the finding" "$?"
printf '%s\n' "$OUT" | awk '/^== claude ==/{p=1} /^== hermes ==/{p=0} p' | grep -q 'DRIFT'
CL_D=$?
printf '%s\n' "$OUT" | awk '/^== hermes ==/{p=1} /^== copilot ==/{p=0} p' | grep -q 'DRIFT'
HE_D=$?
printf '%s\n' "$OUT" | awk '/^== copilot ==/{p=1} p' | grep -q 'DRIFT'
CO_D=$?
check "T2 the DRIFT is on claude (the tampered platform)" "$CL_D"
check "T2 hermes verdict unchanged (no DRIFT)" "$(( 1 - HE_D ))"
check "T2 copilot verdict unchanged (no DRIFT)" "$(( 1 - CO_D ))"
# restore: the tampered bytes are no longer goblin-owned, so re-emit would refuse (R4);
# the byte-exact restore is copying the source payload over the drifted file.
cp "$SRC/skills/practice/SKILL.md" "$TAMPER"

# ---- T2b: a stale context-block VERSION is drift ---------------------------------
sed -i 's/goblin-stack:begin v0.4.4/goblin-stack:begin v0.0.1/' "$REPO/CLAUDE.md"
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR --target "$REPO" 2>&1); RC=$?
check "T2 stale marker VERSION: doctor exits 1" "$(( RC == 1 ? 0 : 1 ))"
printf '%s\n' "$OUT" | grep -q 'does not match v'
check "T2 the stale block names the VERSION mismatch" "$?"
# restore the marker VERSION
sed -i 's/goblin-stack:begin v0.0.1/goblin-stack:begin v0.4.4/' "$REPO/CLAUDE.md"
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR --target "$REPO" 2>&1); RC=$?
check "T2 after the restore, doctor is clean again (exit 0)" "$RC"

# ---- T2c: an all-NOT-DETECTED sandbox exits 2 -------------------------------------
new_sandbox t2
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR 2>&1); RC=$?
check "T2 all-NOT-DETECTED sandbox: doctor exits 2" "$(( RC == 2 ? 0 : 1 ))"
printf '%s\n' "$OUT" | grep -c 'NOT-DETECTED' | grep -q '^3$'
check "T2 all three platforms print NOT-DETECTED" "$?"
# a bad --platform value is exit 2 with the W4a enum named
HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR --platform cursor >/dev/null 2>&1; RC=$?
check "T2 unknown --platform exits 2" "$(( RC == 2 ? 0 : 1 ))"

# ---- the single-platform selector works -------------------------------------------
OUT=$(HOME="$HOMEDIR" PATH="$BARE_PATH" $DOCTOR --platform hermes 2>&1); RC=$?
check "T2 --platform hermes probes one platform (exit 2: not detected in this sandbox)" "$(( RC == 2 ? 0 : 1 ))"
printf '%s\n' "$OUT" | grep -q '^== hermes =='
check "T2 the report covers exactly the selected platform" "$?"

if [ "$fail" -eq 0 ]; then note "t-doctor: PASS"; else note "t-doctor: FAIL"; fi
exit "$fail"
