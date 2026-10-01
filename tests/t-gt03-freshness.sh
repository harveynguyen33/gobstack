#!/usr/bin/env bash
# t-gt03-freshness.sh — GT-03's freshness clause must be able to see a COMMIT (D2, AB2).
#
# At 0.4.2 the clause was
#     test -f .goblin/last-gate-line && [ .goblin/last-gate-line -nt "$(git rev-parse --git-dir)/HEAD" ]
# and `.git/HEAD` is rewritten by BRANCH OPERATIONS, never by a commit, so the row reported the
# round GREEN after the round had moved on. Measured at d5424be (22:00:04 both before and after a
# real commit; `.git/refs/heads/main` moved 22:00:11 -> 22:01:49; `--only GT-03` exit 0).
#
# The clause now compares the gate line with HEAD's REFLOG (`.git/logs/HEAD`), which every HEAD
# movement rewrites - a commit in an attached OR a detached worktree, and in a repo whose refs are
# packed. This file is the control AB2 added for it:
#
#   RED half   a verify (which writes the line), then a real commit -> the row must FAIL. RED on
#              d5424be, where it PASSes; GREEN at the tip.
#   GREEN half the mirror, so the row is not simply always-red: after a re-measure, in a detached
#              worktree, and with packed refs the row must still PASS. A fix that reds a legitimate
#              repo state would be a regression, not a fix (`--only GT-03` after a commit is
#              staleness by design - that is the defect being closed - but nothing ELSE may red it).
#
# The row's own `--only GT-03` invocation is what every assertion below runs, so this file also
# proves the row does not depend on any other row having run first beyond GT-02 writing the line.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

# gt03 — run the row and print "<verdict> <rc>"
gt03() { local o r v; o=$(bash .goblin/bin/goblin-verify --only GT-03 2>&1); r=$?; v=?; [ "$r" = 0 ] && v=PASS; [ "$r" = 1 ] && v=FAIL; printf '%s %s' "$v" "$r"; }
# measure — run the declared gates, which is what WRITES .goblin/last-gate-line (GT-02's body)
measure() { bash .goblin/bin/goblin-verify --only GT-02 >/dev/null 2>&1; }
# want <label> <expected verdict> — assert the row's verdict
want() {
  local got; got=$(gt03)
  if [ "${got%% *}" = "$2" ]; then note "ok   $1 -> GT-03 $got"
  else note "FAIL $1 -> GT-03 $got, wanted $2"; fail=1; fi
}

mkdir -p "$WORK/target" && cd "$WORK/target"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# target\n' > README.md
git add -A && git commit -q -m "chore: seed"
bash "$SRC/bin/goblin-install" --target . --class A >/dev/null 2>&1
git add -A && git commit -q -m "chore: install gobstack"

# ---- the reference the clause reads ---------------------------------------------------------
# Not a text pin on the cell, but the reason the behavioural half below can be RED at all: a
# reference a commit does not rewrite cannot see a commit, and that is D2.
git commit -q --allow-empty -m "a change the gate line will not mention"
gb=$(git rev-parse --git-dir)
[ -f "$gb/logs/HEAD" ] || { note "FAIL no reflog at $gb/logs/HEAD to compare against"; fail=1; }
check "the repo has the reflog the clause reads (\$git-dir/logs/HEAD)" "$?"

# ---- 1. the RED half: the defect ------------------------------------------------------------
measure;                     want "a fresh measurement" PASS
git commit -q --allow-empty -m "a real change after the measurement"
                             want "a real commit after the measurement" FAIL

# ---- 2. the GREEN half: a re-measure clears it, and no legitimate state reds it ---------------
measure;                     want "the commit re-measured" PASS
printf 'staged\n' > staged.txt; git add staged.txt
                             want "a staged, uncommitted change" PASS
git commit -q -m "commit the staged file"
                             want "that commit" FAIL
measure;                     want "that commit re-measured" PASS

git pack-refs --all --prune
                             want "packed refs, nothing committed since the measure" PASS
git commit -q --allow-empty -m "a commit with packed refs"
                             want "a commit with packed refs" FAIL
measure;                     want "that commit re-measured" PASS

git checkout -q --detach
git commit -q --allow-empty -m "a commit in a detached worktree"
                             want "a commit in a detached worktree" FAIL
measure;                     want "that commit re-measured in a detached worktree" PASS

# ---- 3. no commit at all: the row must resolve, not crash ------------------------------------
# A repo with no commits has nothing for the freshness clause to compare against. The row must
# still reach a verdict of its own (0 or 1) rather than dying with the manifest's exit 3, and it
# must not claim a freshness it cannot check. Measured at the tip: the reference is absent, the
# comparison is vacuously true, and the row PASSes - recorded in the row's own why cell.
mkdir -p "$WORK/nocommit" && cd "$WORK/nocommit"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
bash "$SRC/bin/goblin-install" --target . --class A >/dev/null 2>&1
measure
got=$(gt03)
case "$got" in
  "PASS 0"|"FAIL 1") note "ok   a repo with no commits resolves ($got)" ;;
  *) note "FAIL a repo with no commits: GT-03 -> $got (a crash, not a verdict)"; fail=1 ;;
esac

if [ "$fail" -eq 0 ]; then note "t-gt03-freshness: PASS"; else note "t-gt03-freshness: FAIL"; fi
exit "$fail"
