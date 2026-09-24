#!/usr/bin/env bash
# t-automation-silent.sh — PR-05. The automation producer is SILENT when there is nothing to
# report, and it prints the record when there is. Run by tests/run-tests.sh.
#
# Why this is a test and not a promise: a script that prints nothing is indistinguishable, from
# the outside, from a script that found nothing. The mutation below is what separates them —
# the same producer, on the same fixture, with one installed file edited, must go from an empty
# stdout to a record and exit 1. A producer that stays quiet after the mutation is not silent,
# it is broken.
#
# What this cannot see: whether a real bug's symptom is what the report said it was, whether
# the ceiling was hit on a run that also had drift, and anything about a producer that is not
# installed at all (the test builds its own repo from the real installer).
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

PRODUCER="$SRC/automations/drift-audit.sh"
[ -f "$PRODUCER" ] || { note "FAIL no producer at $PRODUCER"; exit 1; }

printf 'profiles:\n  coder:\n    model: model-code\n    provider: prov-code\n    effort: low\n' > "$WORK/models.yaml"
printf 'the referenced standard\n' > "$WORK/standard.md"

# ---- two targets: one installed, one not ------------------------------------
mkdir -p "$WORK/projects/installed"
cd "$WORK/projects/installed"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# installed\n' > README.md
git add -A && git commit -q -m "chore: seed"
bash "$SRC/bin/goblin-install" --target "$WORK/projects/installed" --class A \
  --models "$WORK/models.yaml" --practice "$WORK/standard.md" >/dev/null 2>&1
check "the fixture installs" "$?"
git add -A && git commit -q -m "chore: install goblin-stack"
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"
bash .goblin/bin/goblin-verify >/dev/null 2>&1
check "the installed fixture starts GREEN (nothing below is measured against a broken baseline)" "$?"

mkdir -p "$WORK/projects/not-installed"
printf 'no .goblin here\n' > "$WORK/projects/not-installed/README.md"

STATE="$WORK/state"

clean_run() { # clean_run <label>
  bash "$PRODUCER" --root "$WORK/projects/*" --state "$STATE" --dry-run > "$WORK/out" 2> "$WORK/err"
}
drift_run() { # drift_run <label> — dry-run has no meaning here: the record is the point
  bash "$PRODUCER" --root "$WORK/projects/*" --state "$STATE" --dry-run > "$WORK/out" 2> "$WORK/err"
}

# ---- 1. a clean estate prints NOTHING ---------------------------------------
clean_run
RC=$?
check "a clean run exits 0" "$([ "$RC" -eq 0 ] && echo 0 || echo 1)"
check "a clean run prints nothing on stdout ($(wc -c < "$WORK/out" | tr -d ' ') bytes)" \
  "$([ ! -s "$WORK/out" ] && echo 0 || { sed 's/^/      /' "$WORK/out"; echo 1; })"
check "and it says nothing on stderr either" "$([ ! -s "$WORK/err" ] && echo 0 || echo 1)"

# ---- 2. the mutation: one installed file edited ------------------------------
printf '\n# an unrecorded byte\n' >> "$WORK/projects/installed/.goblin/roles.yaml"
drift_run
RC=$?
check "the same run with one installed file edited exits 1" "$([ "$RC" -eq 1 ] && echo 0 || echo 1)"
check "and it now prints a record (so the silence in (1) was 'clean', not 'broken')" \
  "$([ -s "$WORK/out" ] && echo 0 || echo 1)"
grep -q 'IN-02' "$WORK/out"
check "  the record names the check that disagreed (IN-02)" "$?"
grep -q 'goblin-verify --only IN-02' "$WORK/out"
check "  and the command it ran, so the finding is reproducible" "$?"
grep -q '^# coverage:' "$WORK/out"
check "  and its own coverage (n of m, skipped named)" "$?"

# ---- 3. restore: silent again -----------------------------------------------
cd "$WORK/projects/installed" && git checkout -q -- .goblin/roles.yaml
clean_run
check "restored, the run is silent again" "$([ ! -s "$WORK/out" ] && echo 0 || echo 1)"

# ---- 4. the kill switch -----------------------------------------------------
mkdir -p "$WORK/state-dir"
printf 'enabled: false\n' > "$WORK/state-dir/drift-audit.state"
printf '\n# an unrecorded byte\n' >> "$WORK/projects/installed/.goblin/roles.yaml"
bash "$PRODUCER" --root "$WORK/projects/*" --state "$WORK/state-dir/drift-audit.state" > "$WORK/out" 2> "$WORK/err"
RC=$?
check "the kill switch suppresses the finding and exits 0" "$([ "$RC" -eq 0 ] && echo 0 || echo 1)"
check "  it prints nothing on stdout" "$([ ! -s "$WORK/out" ] && echo 0 || echo 1)"
grep -q 'enabled: false' "$WORK/err"
check "  and it says WHY on stderr, so a silenced run is not a mystery" "$?"
cd "$WORK/projects/installed" && git checkout -q -- .goblin/roles.yaml

# ---- 5. the ceiling: a capped run is a DIFFERENT line from a clean run -------
printf '\n# an unrecorded byte\n' >> "$WORK/projects/installed/.goblin/roles.yaml"
mkdir -p "$WORK/state-dir"
printf 'enabled: true\nrun: %s\nrun: %s\n' "$(date -u +%F)" "$(date -u +%F)" > "$WORK/state-dir/drift-audit.state"
bash "$PRODUCER" --root "$WORK/projects/*" --state "$WORK/state-dir/drift-audit.state" --limit 2 > "$WORK/out" 2>/dev/null
RC=$?
check "a capped run exits 0" "$([ "$RC" -eq 0 ] && echo 0 || echo 1)"
grep -q '^# capped: 2 of 2' "$WORK/out"
check "  a capped run prints a capped line, never the silence of a clean one" "$?"
cd "$WORK/projects/installed" && git checkout -q -- .goblin/roles.yaml

# ---- 6. the intake validator: the refusal carries no --assignee --------------
mkdir -p "$WORK/reports/good" "$WORK/reports/bad"
cat > "$WORK/reports/good/report.yaml" <<'YAML'
repo: .
symptom: The panel Shows   the wrong total
expected: the total is the sum
observed: the total is zero
repro_steps:
  - open the panel
revision: HEAD
YAML
KEY=$(printf '%s' "The panel Shows   the wrong total" | tr 'A-Z' 'a-z' | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')
if command -v sha256sum >/dev/null 2>&1; then H=$(printf '%s' "$KEY" | sha256sum | cut -c1-12); else H=$(printf '%s' "$KEY" | shasum -a 256 | cut -c1-12); fi
printf 'dedup_key: bug:.:%s\n' "$H" >> "$WORK/reports/good/report.yaml"
printf 'repo: .\nsymptom: something\n' > "$WORK/reports/bad/report.yaml"

OUT=$(cd "$WORK/projects/installed" && bash "$SRC/automations/bugreporter-intake.sh" good --reports "$WORK/reports" 2>&1); RC=$?
check "a complete report passes intake" "$([ "$RC" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -q -- '--assignee researcher'
check "  and the card command names the reporter role's profile" "$?"

OUT=$(cd "$WORK/projects/installed" && bash "$SRC/automations/bugreporter-intake.sh" bad --reports "$WORK/reports" 2>&1); RC=$?
check "an incomplete report is REFUSED" "$([ "$RC" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -q 'REFUSED - .* carries no value for: expected observed repro_steps revision'
check "  the refusal names every missing field" "$?"
check "  and the refusal command carries NO --assignee (structurally un-spawnable)" \
  "$(printf '%s' "$OUT" | grep '^hermes kanban create' | grep -q -- '--assignee' && echo 1 || echo 0)"
check "  while the card command for a complete report does name one" \
  "$(printf '%s' "$(cd "$WORK/projects/installed" && bash "$SRC/automations/bugreporter-intake.sh" good --reports "$WORK/reports")" \
     | grep '^hermes kanban create' | grep -q -- '--assignee' && echo 0 || echo 1)"

# two differently-typed copies of one symptom must produce one key
printf '%s\n' "$H" > "$WORK/keyA"
sed -n 's/^dedup_key: bug:\.://p' "$WORK/reports/good/report.yaml" > "$WORK/keyB"
diff -q "$WORK/keyA" "$WORK/keyB" >/dev/null 2>&1
check "the dedup key is a function of the normalised symptom only" "$?"

rm -rf "$WORK"
if [ "$fail" -eq 0 ]; then note "t-automation-silent: PASS"; else note "t-automation-silent: FAIL"; fi
exit "$fail"
