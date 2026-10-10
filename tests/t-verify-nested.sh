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
#   outer/sub2  its own .git      -> verify exits 0, 17 passed / 0 failed / 0 advisory / 10 skipped
#                                  (GAP-2/3: the core tier vendors on every install and bans
#                                   self-select by glob; the DEFAULT Hermes tier stays skills=no)
#
# Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

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
bash "$SRC/bin/goblin-install" --target "$WORK/outer/sub" \
  --practice "$WORK/standard.md" >/dev/null 2>&1
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

OUT=$(bash .gob/bin/goblin-verify 2>&1); RC=$?
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
bash "$SRC/bin/goblin-install" --target "$WORK/outer/sub2" \
  --practice "$WORK/standard.md" >/dev/null 2>&1
check "install into a nested target that is its own repo succeeds" "$?"
git add -A && git commit -q -m "chore: install gobstack"
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
git add -A && git commit -q -m "docs: the handoff names the head"

OUT2=$(bash .gob/bin/goblin-verify 2>&1); RC2=$?
printf '%s\n' "$OUT2" | sed 's/^/      /'
check "a nested target with its own .git verifies (exit 0)" "$([ "$RC2" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT2" | grep -qE '^ *17 passed, 0 failed, 0 advisory, 10 skipped'
check "  and it is the default green path (17/0/0/10: core tier + predicate bans, Hermes tier opt-in)" "$?"

# ---- W1 §5.1: an engine_dir declaration must not leak across the boundary ----------------
# The OUTER repo declares engine_dir; the inner repo (sub2) must resolve its own engine and
# must not inherit the outer declaration - the resolution chain reads $ROOT/AGENTS.md,
# never the enclosing repo's, so the outer declaration is invisible to the inner verify.
mkdir -p "$WORK/engine/manifest" "$WORK/engine/bin"
cp "$SRC/manifest/enforcement.tsv" "$SRC/manifest/bans.tsv" "$WORK/engine/manifest/"
cp "$SRC/bin/goblin-bans" "$SRC/bin/goblin-lib.sh" "$WORK/engine/bin/"
cat > "$WORK/outer/AGENTS.md" <<EOF
<!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->
engine_dir: $WORK/engine
<!-- gob:end -->
EOF
git -C "$WORK/outer" add -A && git -C "$WORK/outer" commit -q -m "declare engine_dir in the outer repo"
OUT3=$(bash .gob/bin/goblin-verify 2>&1); RC3=$?
check "an inner repo verify is unaffected by the OUTER repo's engine_dir (exit 0)" "$([ "$RC3" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT3" | grep -qE '^ *17 passed, 0 failed'
check "  and the inner run is still the default green path (core tier on, Hermes tier opt-in)" "$?"
printf '%s' "$OUT3" | grep -q 'mode=vendored'
check "  and the inner footer still says mode=vendored (no inherited global mode)" "$?"

if [ "$fail" -eq 0 ]; then note "t-verify-nested: PASS"; else note "t-verify-nested: FAIL"; fi
exit "$fail"
