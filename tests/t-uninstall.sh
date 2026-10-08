#!/usr/bin/env bash
# t-uninstall.sh — `--uninstall` removes the harness AND the directories it emptied.
#
# F2-7: the rmdir pass ran BEFORE `rm -f "$INSTALLED"`, so `.gob/` was never empty when it was
# tested, and the list never tried `.hermes/skills/goblin-*`. Measured pre-fix (b100b44): 15
# unnamed empty directories survived (.goblin, .hermes, .hermes/skills and 13 skill dirs) and the
# summary named none of them.
#
# F2-8: the same fixture pins what the installer does NOT install. `.gob/bin` holds exactly the
# two shipped scripts, which is why `docs/ROLES.md` calls `bin/goblin-model` checkout-only.
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

mkdir -p "$WORK/target" && cd "$WORK/target"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# target\n' > README.md
git add -A && git commit -q -m "chore: seed"

bash "$SRC/bin/goblin-install" --target "$WORK/target" --class A \
  --models "$WORK/models.yaml" --practice "$WORK/standard.md" >/dev/null 2>&1
check "install exits 0" "$?"
check "the installer's .gob/bin holds exactly the four shipped scripts" \
  "$([ "$(ls .gob/bin | sort | tr '\n' ' ')" = "goblin-audit goblin-bans goblin-lib.sh goblin-verify " ] && echo 0 || echo 1)"
check "  so bin/goblin-model is checkout-only, as docs/ROLES.md says" \
  "$([ ! -e .gob/bin/goblin-model ] && echo 0 || echo 1)"
# v2: the CI lane is GONE from the product (no .github/workflows payload is ever written),
# so the v1 placement probe has nothing to place. The uninstall's own contract is now pinned
# by the two-survivors assertions below (the edited waiver + the project docs); a workflow
# file a PROJECT owns would still be removed if the record listed it, which the record can
# no longer name. (Documented conversion: the v1 placement probe is obsolete with the
# payload, not weakened — the assertion class 'uninstall removes what the record lists' is
# covered by every other recorded file in this fixture.)
git add -A && git commit -q -m "chore: install gobstack"

DIRS_BEFORE=$(find . -path ./.git -prune -o -type d -print | wc -l | tr -d ' ')

# A decision record the project has EDITED is the project's, not the harness's: the uninstall
# must keep it and name it. An untouched template is removed with the rest (both are asserted).
printf 'lodash\thigh\t*\t2026-01-01\ta decision somebody took, not a template\n' >> .gob/audit-waiver.tsv

# ---- the uninstall -----------------------------------------------------------
OUT=$(bash "$SRC/bin/goblin-install" --target "$WORK/target" --uninstall 2>&1); RC=$?
note "$(printf '%s' "$OUT" | grep -E '^removed [0-9]+ file' || echo 'no summary line')"
check "uninstall exits 0" "$([ "$RC" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -qE '^removed [1-9][0-9]* file\(s\) and [1-9][0-9]* empty director'
check "  the summary counts the files and the emptied directories it removed" "$?"

check ".gob/ holds nothing but the decision record the project edited" \
  "$([ "$(find .gob -type f | sort | tr '\n' ' ')" = ".gob/audit-waiver.tsv " ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -q 'kept .gob/audit-waiver.tsv (you edited it'
check "  and the summary names it rather than deleting it in silence" "$?"
check ".hermes/ is gone (every installed skill dir was emptied and removed)" \
  "$([ ! -d .hermes ] && echo 0 || echo 1)"
# v2: the CI lane's two-level ancestor walk is unreachable in the product (no workflow file
# is ever recorded). `.github/` absent after uninstall is still asserted — trivially true,
# and it keeps the walk honest if a future payload nests again.
check "no .github/ survives the uninstall (v2: nothing writes one; the walk would take it)" \
  "$([ ! -d .github ] && echo 0 || echo 1)"
EMPTY=$(find . -path ./.git -prune -o -type d -empty -print)
check "no empty directory is left behind (pre-fix: 15)" \
  "$([ -z "$EMPTY" ] && echo 0 || { printf '%s\n' "$EMPTY" | sed 's/^/      /'; echo 1; })"

check "the verifier's own record is gone" "$([ ! -f .gob/installed.json ] && echo 0 || echo 1)"
check "the project's HANDOFF.md survives" "$([ -f HANDOFF.md ] && echo 0 || echo 1)"
check "the project's AGENTS.md survives" "$([ -f AGENTS.md ] && echo 0 || echo 1)"
check "the project's ROUND-000-SPEC.md survives" "$([ -f ROUND-000-SPEC.md ] && echo 0 || echo 1)"
check "reviews/ survives with its .gitkeep" "$([ -f reviews/.gitkeep ] && echo 0 || echo 1)"
check "the .gitignore block is left, with the uninstalled marker" \
  "$(grep -q 'goblin-stack uninstalled' .gitignore && echo 0 || echo 1)"

note "directories before the install+uninstall cycle: $DIRS_BEFORE"

if [ "$fail" -eq 0 ]; then note "t-uninstall: PASS"; else note "t-uninstall: FAIL"; fi
exit "$fail"
