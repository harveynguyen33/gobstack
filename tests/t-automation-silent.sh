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
  --practice "$WORK/standard.md" >/dev/null 2>&1
check "the fixture installs" "$?"
git add -A && git commit -q -m "chore: install gobstack"
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"
bash .gob/bin/goblin-verify >/dev/null 2>&1
check "the installed fixture starts GREEN (nothing below is measured against a broken baseline)" "$?"

mkdir -p "$WORK/projects/not-installed"
printf 'no .gob here\n' > "$WORK/projects/not-installed/README.md"

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
printf '\n# an unrecorded byte\n' >> "$WORK/projects/installed/.gob/manifest/glossary.tsv"
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
cd "$WORK/projects/installed" && git checkout -q -- .gob/manifest/glossary.tsv
clean_run
check "restored, the run is silent again" "$([ ! -s "$WORK/out" ] && echo 0 || echo 1)"

# ---- 4. the kill switch -----------------------------------------------------
mkdir -p "$WORK/state-dir"
printf 'enabled: false\n' > "$WORK/state-dir/drift-audit.state"
printf '\n# an unrecorded byte\n' >> "$WORK/projects/installed/.gob/manifest/glossary.tsv"
bash "$PRODUCER" --root "$WORK/projects/*" --state "$WORK/state-dir/drift-audit.state" > "$WORK/out" 2> "$WORK/err"
RC=$?
check "the kill switch suppresses the finding and exits 0" "$([ "$RC" -eq 0 ] && echo 0 || echo 1)"
check "  it prints nothing on stdout" "$([ ! -s "$WORK/out" ] && echo 0 || echo 1)"
grep -q 'enabled: false' "$WORK/err"
check "  and it says WHY on stderr, so a silenced run is not a mystery" "$?"
cd "$WORK/projects/installed" && git checkout -q -- .gob/manifest/glossary.tsv

# ---- 5. the ceiling: a capped run is a DIFFERENT line from a clean run -------
printf '\n# an unrecorded byte\n' >> "$WORK/projects/installed/.gob/manifest/glossary.tsv"
mkdir -p "$WORK/state-dir"
printf 'enabled: true\nrun: %s\nrun: %s\n' "$(date -u +%F)" "$(date -u +%F)" > "$WORK/state-dir/drift-audit.state"
bash "$PRODUCER" --root "$WORK/projects/*" --state "$WORK/state-dir/drift-audit.state" --limit 2 > "$WORK/out" 2>/dev/null
RC=$?
check "a capped run exits 0" "$([ "$RC" -eq 0 ] && echo 0 || echo 1)"
grep -q '^# capped: 2 of 2' "$WORK/out"
check "  a capped run prints a capped line, never the silence of a clean one" "$?"
cd "$WORK/projects/installed" && git checkout -q -- .gob/manifest/glossary.tsv

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

# ---- 7. G8-1: the intake must never execute what the report says -----------------------------
# The report file is the untrusted input this gate exists to validate ("a report is a FILE WITH
# A SCHEMA, not prose"). The accept path used to `eval` a command string built from the report's
# own `symptom:`. Measured at 43f7f69: a symptom carrying a backtick ran `id -un` and its output
# landed in the card title, and one carrying `$(printf pwned > <marker>)` WROTE THE MARKER. The
# printed form (no --cards) was that same string, printed unescaped, and pasting it ran the
# injection too - and that printed line is exactly what skills/goblin-bugreporter/SKILL.md step 1
# tells the operator to run. The control mutates nothing: it fixes the INPUT. Falsifiable
# statements, per the two reachable forms:
#   (a) the injected command does not run (the marker file is still empty),
#   (b) the stub `hermes` received the title as ONE argv element, byte-for-byte as the report
#       wrote it - so the fix is an argv exec, not escaping that happens to look right,
#   (c) the printed form, pasted into a shell, does not run it either.
# What this cannot see: whether a later edit reintroduces a shell re-parse on a code path this
# symptom does not reach, and whether a report is TRUE - it proves the gate hands the board one
# literal argument, nothing about the argument's content.
SHIMDIR="$WORK/shim"; mkdir -p "$SHIMDIR" "$WORK/reports/inj"
SHIM_ARGV_LOG="$WORK/shim-argv.log"; export SHIM_ARGV_LOG; : > "$SHIM_ARGV_LOG"
cat > "$SHIMDIR/hermes" <<'SHIM'
#!/usr/bin/env bash
# A stub `hermes`: records the argv it was handed, one argument per line, and does nothing else.
# One argument per line is what makes "the title arrived as ONE element" a measurement.
for a in "$@"; do printf '%s\n' "$a"; done >> "$SHIM_ARGV_LOG"
exit 0
SHIM
chmod +x "$SHIMDIR/hermes"

MARKER="$WORK/marker.txt"; : > "$MARKER"
SYMPTOM_TMPL='the `id -un` label is wrong; $(printf pwned > __MARKER__) and a "quote" here'
SYMPTOM="${SYMPTOM_TMPL/__MARKER__/$MARKER}"
printf 'repo: alpha\nsymptom: %s\nexpected: a CSV downloads\nobserved: nothing happens\nrevision: HEAD\nrepro_steps:\n  - open the page\n' \
  "$SYMPTOM" > "$WORK/reports/inj/report.yaml"
WANT_TITLE="bug: $SYMPTOM"

cd "$WORK/projects/installed"
PATH="$SHIMDIR:$PATH" bash "$SRC/automations/bugreporter-intake.sh" inj --reports "$WORK/reports" --cards >/dev/null 2>&1
check "G8-1: a symptom carrying a backtick, \$(...) and a quote still passes intake (the gate is about the report's SHAPE, not its intent)" "$?"
check "G8-1: nothing the report says executed (the marker is still empty: $(wc -c < "$MARKER" | tr -d ' ') byte(s))" \
  "$([ ! -s "$MARKER" ] && echo 0 || echo 1)"
grep -qxF "$WANT_TITLE" "$SHIM_ARGV_LOG"
check "G8-1: the stub received the title as ONE argument, byte-for-byte as the report wrote it" "$?"
grep -qxF -- '--assignee' "$SHIM_ARGV_LOG" && grep -qxF 'researcher' "$SHIM_ARGV_LOG"
check "G8-1:  and the accept path still hands the reporter role to the board" "$?"

: > "$SHIM_ARGV_LOG"; : > "$MARKER"
OUT=$(bash "$SRC/automations/bugreporter-intake.sh" inj --reports "$WORK/reports" 2>/dev/null) || true
( PATH="$SHIMDIR:$PATH" bash -c "$OUT" ) >/dev/null 2>&1
check "G8-1: pasting the PRINTED command does not execute it either (the marker is still empty)" \
  "$([ ! -s "$MARKER" ] && echo 0 || echo 1)"
grep -qxF "$WANT_TITLE" "$SHIM_ARGV_LOG"
check "G8-1:  and the pasted line hands the same title over as ONE argument" "$?"

rm -rf "$WORK"
if [ "$fail" -eq 0 ]; then note "t-automation-silent: PASS"; else note "t-automation-silent: FAIL"; fi
exit "$fail"
