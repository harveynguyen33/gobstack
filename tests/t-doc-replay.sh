#!/usr/bin/env bash
# t-doc-replay.sh — the P15 procedure doc's RC claims must match the engine, and until the
# 2026-09-27 independent re-run (FIX-FIRST, findings F1/F2) nothing in tests/ read
# `docs/RE-PLAYBOOK.md`, which is how two false claims about `goblin-verify` survived a
# pass whose whole subject was verifiability:
#
#   R1  the doc's Verification section (and S9) cited `goblin-verify --only RC-03`/`RC-04`
#       against the lab repo without the bridge: goblin-verify refuses to run in a repo
#       without an installed harness (exit 2, `not installed: <root>/.goblin/goblin.yaml is
#       absent`). A reviewer who did not write the doc cannot bridge that gap from the doc
#       alone. The fix names `goblin-install --target <lab-repo> --class A` as the one-time
#       step, and the doc must keep carrying it.
#   R2  S6 said the `.sha256` manifest is what `RC-01`'s build-time gate "consumes as
#       `reference_manifest:`" - false: RC-01/RC-02 parse a `reference-manifest/1` JSON, and
#       declaring the sha256sum-format file there fails RC-01 as unparseable. The conflation
#       is the exact bug this control exists to keep out: a conformance test written from the
#       old sentence would feed RC-01 the wrong artifact.
#
# RED on the pre-fix tree (541c650): R1's install bridge is absent and R2's false sentence
# is present. GREEN at the fix. The matchers normalise markdown (emphasis/code ticks to
# spaces, newlines to spaces, whitespace collapsed) before matching, the same
# defeat-the-control-by-emphasis trap t-doc-guide's AB3 half documents: a literal grep is
# green on both trees because the claim wraps across lines.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PLAYBOOK="$SRC/docs/RE-PLAYBOOK.md"
SKILL="$SRC/skills/goblin-re-mobile/SKILL.md"
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

norm() { sed 's/[*_`]/ /g' "$1" | tr '\n' ' ' | tr -s '[:space:]' ' '; }
NORM=$(norm "$PLAYBOOK")

# ---- R1: the doc names the goblin-install bridge before the RC- rows are runnable -------------
# All three strings must survive in the SAME document, but they are asserted independently so a
# partial edit (the command kept, the refusal reason dropped, or vice versa) still goes RED: the
# refusal reason is what tells a stuck reviewer their symptom is the missing bridge.
printf '%s' "$NORM" | grep -qF 'goblin-install --target <lab-repo> --class A'
check "the playbook names goblin-install as the bridge into the lab repo (R1)" "$?"
printf '%s' "$NORM" | grep -qF 'not installed'
check "  and it names the refusal a bare lab repo hits (exit 2, 'not installed') (R1)" "$?"
printf '%s' "$NORM" | grep -qF 'harness installed there first'
check "  and the Verification section says the harness must be installed first (R1)" "$?"
norm "$SKILL" | grep -qF 'goblin-install --target <lab-repo> --class A'
check "  and the skill's Verification mirrors the bridge (R1)" "$?"

# ---- R2: the false consumption claim is gone ---------------------------------------------------
# The exact sentence the finding quoted. Normalised matching, not a literal grep: the claim
# wraps, so the string the reader sees is not the string the file holds.
if printf '%s' "$NORM" | grep -qF 'consumes as reference'; then
  note "FAIL the playbook still says the .sha256 manifest is consumed as 'reference_manifest:' (R2)"
  fail=1
else
  note "ok   the false claim ('consumes as reference_manifest:') is gone (R2)"
fi
# The corrected split must be stated, not merely implied by the deletion: RC-01/RC-02 consume a
# JSON, and the .sha256 manifest is NOT it. Without this half the control would pass on a tree
# that simply deleted the whole S6 explanation.
printf '%s' "$NORM" | grep -qiF 'reference-manifest/1'
printf '%s' "$NORM" | grep -qiF 'not what RC-01'
check "  and S6 states the .sha256 manifest is not what RC-01/RC-02 consume (R2)" "$?"

if [ "$fail" -eq 0 ]; then note "t-doc-replay: PASS"; else note "t-doc-replay: FAIL"; fi
exit "$fail"
