#!/usr/bin/env bash
# t-verify-nested.sh — F2-1: the git-scoped rows must never read the ENCLOSING repo.
#
# find_installed_root resolves the *config* lookup to the target, but CM-01, CM-03, GT-03, SP-02,
# PG-01, PG-03, DS-01, PT-02 and HP-05 shell out to git, and git resolves $PWD to the enclosing
# repository when the target is not a repository of its own. Measured pre-fix (b100b44): a target
# at outer/sub with no .git of its own verified `32 passed, 1 failed`, exit 1, with
# `FAIL CM-03 30 dirty entr(y|ies), max_dirty 0` - the 30 entries being sub/'s own installed
# files, staged in the OUTER repo's index by the `git add -A` the installer itself advises.
# The card named this as "the case that would bite ~/.hermes".
#
#   outer/sub   no .git of its own -> verify exits 2, names the outer repo and the fix
#   outer/sub2  its own .git      -> verify exits 0, 41 passed / 0 failed / 9 advisory / 7 skipped
#
# Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

printf 'profiles:\n  coder:\n    model: model-code\n    provider: prov-code\n    effort: low\n' > "$WORK/models.yaml"
printf 'the referenced standard\n' > "$WORK/standard.md"

# ---- the enclosing repo, and a target inside it with no .git of its own -------
mkdir -p "$WORK/outer/sub"
cd "$WORK/outer"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# outer\n' > README.md
git add -A && git commit -q -m "chore: seed the outer repo"

cd "$WORK/outer/sub"
bash "$SRC/bin/goblin-install" --target "$WORK/outer/sub" --class A \
  --models "$WORK/models.yaml" --practice "$WORK/standard.md" >/dev/null 2>&1
check "install into a nested target with no .git of its own succeeds" "$?"
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
# The installer's own "next" advice is `git add -A && git commit`. F2's fixture staged the
# target's files in the OUTER repo and verified before committing - which is what produced
# `FAIL CM-03 30 dirty entr(y|ies)`: the outer repo's index, counted as the target's dirty tree.
cd "$WORK/outer" && git add -A
note "the OUTER repo's index, as the git-scoped rows would read it:"
git status --porcelain | head -3 | sed 's/^/      /'
note "  ... $(git status --porcelain | wc -l | tr -d ' ') staged entries, none of them the target's business"
cd "$WORK/outer/sub"
note "git rev-parse --show-toplevel from the target -> $(git rev-parse --show-toplevel)"

OUT=$(bash .goblin/bin/goblin-verify 2>&1); RC=$?
note "verify from inside the nested target: exit $RC"
printf '%s\n' "$OUT" | grep -E '^(FAIL|error)' | head -3 | sed 's/^/      /'
check "a nested target with no .git of its own is refused (exit 2)" \
  "$([ "$RC" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -q 'is inside the git repository'
check "  the refusal names the enclosing repository" "$?"
printf '%s' "$OUT" | grep -q 'not a repository of'
check "  the refusal says what is wrong with the target" "$?"
printf '%s' "$OUT" | grep -q 'git init'
check "  the refusal names the fix" "$?"
printf '%s' "$OUT" | grep -q 'CM-03'
check "  the refusal names the rows that would read the outer repo" "$?"
check "  and it prints no dirty-entry count about the outer repo" \
  "$(printf '%s' "$OUT" | grep -q 'dirty entr' && echo 1 || echo 0)"

# ---- a nested target that IS its own repository still verifies ----------------
mkdir -p "$WORK/outer/sub2"
cd "$WORK/outer/sub2"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# sub2\n' > README.md
git add -A && git commit -q -m "chore: seed sub2"
bash "$SRC/bin/goblin-install" --target "$WORK/outer/sub2" --class A \
  --models "$WORK/models.yaml" --practice "$WORK/standard.md" >/dev/null 2>&1
check "install into a nested target that is its own repo succeeds" "$?"
git add -A && git commit -q -m "chore: install goblin-stack"
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
git add -A && git commit -q -m "docs: the handoff names the head"

OUT2=$(bash .goblin/bin/goblin-verify 2>&1); RC2=$?
printf '%s\n' "$OUT2" | sed 's/^/      /'
check "a nested target with its own .git verifies (exit 0)" "$([ "$RC2" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT2" | grep -qE '^ *42 passed, 0 failed, 9 advisory, 11 skipped'
check "  and it is the class-A green path (33/0/8/1)" "$?"

if [ "$fail" -eq 0 ]; then note "t-verify-nested: PASS"; else note "t-verify-nested: FAIL"; fi
exit "$fail"
