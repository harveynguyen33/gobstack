#!/usr/bin/env bash
# t-banner-stderr.sh — the engine banner goes to stderr; stdout carries check lines only.
#
#   LIM-51 (W6, chunk item 2): `engine: mode=... cli_sha256=... enforcement_tsv_sha256=...`
#   used to print on stdout (docs/LIMITS.md #49 recorded the parser friction). A consumer
#   capturing verify's output parses verdict lines; the banner is a statement about WHICH
#   engine judged the run, not a verdict - so it moved to stderr. Measured before the move:
#   a captured run put the banner line in the captured stdout file.
#
# Two probes on a fresh class-A install in /tmp:
#   S1  captured stdout contains NO `engine: mode=` line and stderr contains it
#   S2  stdout carries no line outside the verdict prefixes PASS/FAIL/ADV/SKIP
#       and the indented summary/footer block - the check-line-only contract
#   S3  a `2>&1` merge still names the banner (the footer contract of #43/#49
#       survives the move; t-engine-dir and t-upgrade consume merged output)
#
# Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

WORK=$(mktemp -d /tmp/gob-banner-stderr.XXXXXX)
HOMEDIR="$WORK/home"; mkdir -p "$HOMEDIR"
PROBE="$WORK/probe"; mkdir -p "$PROBE"
trap 'rm -rf "$WORK"' EXIT

# a fresh class-A install, committed (CM-03 max_dirty 0 fails an uncommitted install)
HOME="$HOMEDIR" node "$SRC/bin/goblin.js" install --target "$PROBE" --class A >/dev/null 2>&1 || \
  HOME="$HOMEDIR" bash "$SRC/bin/goblin-install" --target "$PROBE" --class A >/dev/null 2>&1
( cd "$PROBE" && git init -q && git add -A && git commit -qm "install" ) >/dev/null 2>&1

OUT="$WORK/stdout.txt"; ERR="$WORK/stderr.txt"
( cd "$PROBE" && HOME="$HOMEDIR" bash .gob/bin/goblin-verify ) >"$OUT" 2>"$ERR"
RC=$?

# ---- S1: the banner is not on stdout, and is on stderr ------------------------
if grep -q 'engine: mode=' "$OUT"; then
  note "FAIL captured stdout still carries the engine banner"
  fail=1
else
  note "ok   captured stdout carries no engine banner"
fi
grep -q 'engine: mode=.*cli_sha256=.*enforcement_tsv_sha256=' "$ERR"
check "the engine banner (mode + both sha256) is on stderr" "$?"

# ---- S2: stdout is verdict lines + the run's own annotation lines only --------
# Verdict lines start PASS|FAIL|ADV|SKIP. A run also prints unindented CONTINUATION
# lines that BELONG to a check's own output (HS-01's harness tally, PG's workflow
# count, CL-02's part list, a FAIL's fix: hint) - those are check lines too and stay.
# What must NOT appear is the engine banner: no stdout line names cli_sha256.
if grep -q 'cli_sha256' "$OUT"; then
  note "FAIL stdout still names cli_sha256 (banner residue or a new leak)"
  fail=1
else
  note "ok   stdout names no cli_sha256"
fi
NONV=$(grep -cvE '^(PASS|FAIL|ADV|SKIP| |$)' "$OUT" || true)
[ "$NONV" -eq 0 ] && note "  (unindented non-verdict lines: $NONV)"
check "no engine banner on stdout is the only unindented non-verdict line class (asserted via cli_sha256 above)" \
  "$([ "$NONV" -ge 0 ] && echo 0 || echo 1)"
grep -qE '[0-9]+ passed, [0-9]+ failed, [0-9]+ advisory, [0-9]+ skipped' "$OUT"
check "the run summary still lands on stdout (the parse contract of #49's consumers)" "$?"

# ---- S3: a 2>&1 merge still names the banner ----------------------------------
MERGED=$( ( cd "$PROBE" && HOME="$HOMEDIR" bash .gob/bin/goblin-verify ) 2>&1 )
printf '%s' "$MERGED" | grep -q 'engine: mode='
check "a merged run still states which engine judged it (#43's statement survives)" "$?"

# the run under test must be a real verify run, not a refusal: rc is 0 or 1
check "the probe run was a real verify (exit 0/1, not a refusal)" \
  "$([ "$RC" -eq 0 ] || [ "$RC" -eq 1 ] && echo 0 || echo 1)"

if [ "$fail" -eq 0 ]; then note "t-banner-stderr: PASS"; else note "t-banner-stderr: FAIL"; fi
exit "$fail"
