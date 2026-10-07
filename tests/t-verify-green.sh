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
git add -A && git commit -q -m "chore: install gobstack"

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
printf '%s' "$OUT" | grep -q 'not signed'
check "the run says the record every drift check trusts is not signed (F2-3)" "$?"
printf '%s' "$OUT" | grep -q 'SKIP  HS-02'
check "HS-02 is skipped with a reason while no pre-change commit is pinned" "$?"
printf '%s' "$OUT" | grep -q 'ADV   MD-02'
check "MD-02 reports the model families as ADV, never a failure" "$?"
check "a class-A repo with no reviews yet does not fail the PR gate" \
  "$(printf '%s' "$OUT" | grep -q 'PASS  PG-03' && echo 0 || echo 1)"

# ---- W6: the electron opt-in (merged from class F) installs green, and its CI lane is real ---
# F was merged into software (§W6-TAXONOMY-SPEC): a desktop shell is `--class software --electron`.
# It has to reach the same green path as every other install: a class whose ratchet command cannot
# run would be born RED, which is the one thing the install path must not produce. The FPS number
# itself is a HOST gate (it needs a display and a probe the no-npm contract forbids goblin-stack to
# ship) - the point of this block is that the hermetic half is green and the host half is DECLARED
# rather than silently absent.
mkdir -p "$WORK/f" && cd "$WORK/f"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# desktop shell\n' > README.md
git add -A && git commit -q -m "chore: seed"
bash "$SRC/bin/goblin-install" --target "$WORK/f" --class software --electron --models "$WORK/models.yaml" --practice "$WORK/standard.md" >/dev/null 2>&1
check "software+electron install exits 0" "$?"
git add -A && git commit -q -m "chore: install gobstack"
F_HEAD=$(git rev-parse --short HEAD)
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$F_HEAD\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"

FOUT=$(bash .goblin/bin/goblin-verify 2>&1); FRC=$?
check "software+electron verify exits 0" "$FRC"
printf '%s' "$FOUT" | grep -qE '[0-9]+ passed, 0 failed, [0-9]+ advisory'
check "  and its summary line reports passed/failed/advisory" "$?"
awk '/^perf:/{p=1} p&&/^  host_gate: /{print; exit}' .goblin/goblin.yaml | grep -q 'Electron run' \
  && awk '/^perf:/{p=1} p&&/^  host_gate: /{print; exit}' .goblin/goblin.yaml | grep -q 'main_thread_busy_pct'
check "  and the FPS number is DECLARED as a host gate, not silently absent" "$?"
awk '/^ratchet:/{r=1} r&&/^  name: /{print; exit}' .goblin/goblin.yaml | grep -qE '^  name: [a-z_]+$' \
  && grep -qE '^  name: app_bundle_bytes$' .goblin/goblin.yaml \
  && ! grep -qE '^  name: (main_thread_busy_pct|fps|frame_time_ms)$' .goblin/goblin.yaml
check "  and the ratchet carries a hermetic metric of its own (the bundle bytes, not the FPS)" "$?"
grep -q '^electron: true$' .goblin/goblin.yaml
check "  and electron: true is DECLARED in the config" "$?"
[ -f .github/workflows/goblin-gate.yml ]
check "  and the CI lane was placed for a class that permits it" "$?"
printf '%s' "$FOUT" | grep -q 'PASS  PG-05' && printf '%s' "$FOUT" | grep -q 'PASS  PG-06'
check "  and the shipped workflow passes PG-05 and PG-06" "$?"
printf '%s' "$FOUT" | grep -q 'SKIP  BN-06'
check "  and an electron ban the class lists still skips on a tree with no renderer" "$?"
printf '%s' "$FOUT" | grep -qE 'ADV   PF-01|PASS  PF-01|SKIP  PF-01'
check "  and the perf pin reports itself (ADV/PASS/SKIP), never silently" "$?"

# ---- W6: the desktop/F alias resolves to software+electron, byte-identically -----------------
# The merged class kept the old spellings: `--class desktop` (and F/f) must produce the SAME
# config a `--class software --electron` install does, not a silently weaker software install.
mkdir -p "$WORK/falias" && cd "$WORK/falias"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# desktop shell\n' > README.md
git add -A && git commit -q -m "chore: seed"
bash "$SRC/bin/goblin-install" --target "$WORK/falias" --class desktop --models "$WORK/models.yaml" --practice "$WORK/standard.md" >/dev/null 2>&1
check "the desktop alias install exits 0" "$?"
cmp -s "$WORK/f/.goblin/goblin.yaml" "$WORK/falias/.goblin/goblin.yaml" \
  && grep -q '"class": "software"' "$WORK/falias/.goblin/installed.json"
check "  and its config is identical to software+electron (class recorded as software)" "$?"

# ---- UX pass: remedy lines, day-one banners, recovery lines, GT-03's sentence --------------
# (review 1 scope 4-7) Five print contracts live in the printers and the summary block:
#   R1  the matrix's remedy column rides under a FAIL (g_fail -> g_remedy, _GOB_MANIFEST) -
#       absent under every PASS, whole under --only, width-truncated in the default listing.
#       A GREEN RUN still prints one remedy: the JG-02 lane FAILs nothing but its unresolved
#       judge lane is ADV BY DESIGN (no judge profile in the fixture's models.yaml), and an ADV
#       remedy is part of that row's print contract since before this pass - so the pin is on
#       the remedy-bearing ROWS, not the whole output: every row above the summary is PASS/SKIP
#       and none of the three RED-direction remedy lines may appear.
#   R2  the owner-mismatch note (owner_mismatch) - only under a red run, names the email
#   R3  the fresh-clone banner (fresh_clone) - only under a red run, commit-count keyed
#   R4  GT-03's failure line is a sentence, not the raw test(1) dump
# Pinned here in the GREEN direction (the red direction is t-verify-red.sh's, which must
# produce the violation itself): a green run prints none of it.
BAD_REMEDIES=$(printf '%s' "$OUT" | grep '^remedy:' | grep -vc 'add the missing profile to the file declared as models_file')
[ -z "$OUT" ] && BAD_REMEDIES=0
[ "$BAD_REMEDIES" -eq 0 ]
check "R1 the only remedy: on a green run is the unresolved-lane ADV remedy (none under a PASS/FAIL row)" "$?"
printf '%s' "$OUT" | grep -q 'note: this repo records a different owner'
check "R2 a green run prints no owner-mismatch note" "$([ $? -ne 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -q 'fresh clone detected'
check "R3 a green run prints no fresh-clone banner" "$([ $? -ne 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -q 'the gate line is older than the last commit'
check "R4 a green run prints no GT-03 staleness sentence" "$([ $? -ne 0 ] && echo 0 || echo 1)"

# R5: the fresh-clone banner is keyed on COMMIT COUNT ONLY (the mtime-vs-reflog branch fired
# after every ordinary GT-02 write and lingered on aged repos). A repo under 3 commits with a
# failing row gets the banner; the same repo AGED past 3 commits with the same failing row and
# repeated GT-02 writes stays silent.
mkdir -p "$WORK/fresh" && cd "$WORK/fresh"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# fresh\n' > README.md
git add -A && git commit -q -m "seed"
bash "$SRC/bin/goblin-install" --target . --class A --models "$WORK/models.yaml" >/dev/null 2>&1
sed -i 's/^owner_email:.*/owner_email: other@owner.example/' .goblin/goblin.yaml
git add -A && git commit -q -m "install gobstack"
FOUT2=$(bash .goblin/bin/goblin-verify 2>&1); FRC2=$?
check "R5a the 2-commit probe fails for the planted reason (CM-01, exit 1)" "$([ "$FRC2" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$FOUT2" | grep -q 'fresh clone detected: some of these fails are not yours'
check "R5b the fresh-clone banner fires under 3 commits" "$?"
printf '%s' "$FOUT2" | grep -q 'note: this repo records a different owner'
check "R5c the owner-mismatch note fires beside it (same red run)" "$?"
git commit -q --allow-empty -m "third commit"
git commit -q --allow-empty -m "fourth commit"
FOUT3=$(bash .goblin/bin/goblin-verify 2>&1)
FOUT4=$(bash .goblin/bin/goblin-verify 2>&1); FRC4=$?
check "R5d the aged probe still fails for the same planted reason (exit 1)" "$([ "$FRC4" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$FOUT4" | grep -q 'fresh clone detected'
check "R5e the banner is SILENT on the aged repo after two GT-02 rewrites (mtime branch gone)" "$([ $? -ne 0 ] && echo 0 || echo 1)"

if [ "$fail" -eq 0 ]; then note "t-verify-green: PASS"; else note "t-verify-green: FAIL"; fi
exit "$fail"
