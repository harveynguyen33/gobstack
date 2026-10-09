#!/usr/bin/env bash
# t-render-tokens.sh — Z1-3's control: a RENDERED install carries no unsubstituted template token.
#
# The defect this exists for. `templates/goblin.yaml.tmpl` held a `{{GATE2}}` line that no
# `render` call replaced, so every one of the classes' installed `.gob/goblin.yaml`
# carried a raw template token - visible to the operator in their own config, two waves after it
# was first reported (W5-8). `grep -rl '{{GATE2}}' tests docs manifest bin` was 0 files, which is
# exactly why nothing caught it: no test, no document, and no row read the rendered output.
#
# WHY ALL CLASSES (and the electron opt-in). The rule is per-class, not per-template: a token can
# be left behind by a class's own preset path, and the install renders four other templates per
# class (AGENTS.md, HANDOFF.md, ROUND-000-SPEC.md, the CI workflow) plus the config. One class
# would have caught this particular token, but the control is the generalisation - "a rendered
# install contains no `{{...}}` token" - so it is run over the whole rendered surface of every
# class and the electron overlay.
#
# WHAT IT CANNOT SEE. It proves no placeholder SURVIVED; it cannot prove a placeholder was
# replaced by the RIGHT value (a render that substituted an empty string passes here, and the
# positive control below only proves the gate block is non-empty for each class). A token that a
# render intentionally leaves (a project's own templating inside an installed skill) would be
# reported as a leak - there is no way to tell the two apart from the bytes, so an installed file
# that legitimately carries `{{...}}` must not be shipped.
#
# Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

printf 'the referenced standard\n' > "$WORK/standard.md"

# W6: five domain-named classes, plus the electron opt-in overlay over software (the merged
# desktop class) - the overlay is a second preset path, so it is its own rendered surface.
CLASSES="software service game research fleet"
for c in $CLASSES; do
  t="$WORK/class-$c"
  mkdir -p "$t" && cd "$t"
  git init -q -b main
  git config user.name "Test Runner"
  git config user.email "runner@example.com"
  printf '# target\n' > README.md
  git add -A && git commit -q -m "chore: seed"
  bash "$SRC/bin/goblin-install" --target "$t" --class "$c" \
    --practice "$WORK/standard.md" >/dev/null 2>&1
  check "class $c renders an install" "$?"
  # The positive control: the scan below is over a tree that HAS the rendered gate block. Without
  # this, an install that wrote nothing (or a scan that read nothing) would pass the token check
  # vacuously - the shape this suite exists to refuse. v2: the gates live in the AGENTS.md
  # frontmatter block (flat gate_<name>_cmd: keys), there is no .gob/goblin.yaml.
  [ -s "$t/AGENTS.md" ] && grep -q '^gate_.*_cmd: ' "$t/AGENTS.md"
  check "  and class $c's config carries a rendered gate block (so the scan reads a real file)" "$?"
done
t="$WORK/class-software-electron"
mkdir -p "$t" && cd "$t"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# target\n' > README.md
git add -A && git commit -q -m "chore: seed"
bash "$SRC/bin/goblin-install" --target "$t" --class software --electron \
  --practice "$WORK/standard.md" >/dev/null 2>&1
check "the electron opt-in renders an install" "$?"
[ -s "$t/AGENTS.md" ] && grep -q '^gate_.*_cmd: ' "$t/AGENTS.md" \
  && grep -q '^electron: true$' "$t/AGENTS.md"
check "  and its config carries a rendered gate block (so the scan reads a real file)" "$?"

# The control. `{{` alone is not a token (a shell brace needs no partner), so the pattern is the
# token SHAPE; `.git/` is excluded because packed objects hold whatever was ever committed.
cd "$WORK"
LEAKS=$(grep -rnE '\{\{[A-Za-z0-9_]+\}\}' $WORK/class-* 2>/dev/null | grep -v '/\.git/')
if [ -z "$LEAKS" ]; then
  check "a rendered install of all five classes (and the electron opt-in) carries no unsubstituted {{...}} token" 0
else
  printf '%s\n' "$LEAKS" | sed 's/^/        /'
  check "a rendered install of all five classes (and the electron opt-in) carries no unsubstituted {{...}} token" 1
fi

if [ "$fail" -eq 0 ]; then note "t-render-tokens: PASS"; else note "t-render-tokens: FAIL"; fi
exit "$fail"
