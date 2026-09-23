#!/usr/bin/env bash
# t-verify-green.sh — a correctly installed and committed target verifies GREEN, and the
# summary line reports the advisory count. Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

printf 'profiles:\n  coder:\n    model: model-code\n    provider: prov-code\n    effort: low\n  reviewer:\n    model: model-review\n    provider: prov-review\n    effort: high\n' > "$WORK/models.yaml"
printf 'the referenced standard\n' > "$WORK/standard.md"

mkdir -p "$WORK/target" && cd "$WORK/target"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# target\n' > README.md
git add -A && git commit -q -m "chore: seed"

bash "$SRC/bin/goblin-install" --target "$WORK/target" --class A --models "$WORK/models.yaml" --practice "$WORK/standard.md" >/dev/null 2>&1
check "install exits 0" "$?"
git add -A && git commit -q -m "chore: install goblin-stack"

# P9: the HANDOFF names the HEAD it describes. Committing the HANDOFF moves HEAD, so the
# check accepts any commit that exists in the repo and is an ancestor of HEAD.
HEAD_NOW=$(git rev-parse --short HEAD)
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$HEAD_NOW\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"

OUT=$(bash .goblin/bin/goblin-verify 2>&1); RC=$?
printf '%s\n' "$OUT" | sed 's/^/      /'
check "verify exits 0" "$RC"
printf '%s' "$OUT" | grep -qE '[0-9]+ passed, 0 failed, [0-9]+ advisory'
check "the summary line reports passed/failed/advisory" "$?"
printf '%s' "$OUT" | grep -q 'cannot see'
check "the run states what it cannot see" "$?"
printf '%s' "$OUT" | grep -q 'SKIP  HS-02'
check "HS-02 is skipped with a reason while no pre-change commit is pinned" "$?"
printf '%s' "$OUT" | grep -q 'ADV   MD-02'
check "MD-02 reports the model families as ADV, never a failure" "$?"
check "a class-A repo with no reviews yet does not fail the PR gate" \
  "$(printf '%s' "$OUT" | grep -q 'PASS  PG-03' && echo 0 || echo 1)"

if [ "$fail" -eq 0 ]; then note "t-verify-green: PASS"; else note "t-verify-green: FAIL"; fi
exit "$fail"
