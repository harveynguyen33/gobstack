#!/usr/bin/env bash
# t-practice-repin.sh — the practice pin has a documented, explicit re-pin path (F4-followup).
#
# The gap this closes. `PROJECT-PRACTICE.md` is a living standard, corrected in place, while
# `.goblin/goblin.yaml` is an `owned` file the installer never rewrites. So one legitimate edit
# to the standard reddened `IN-02` (`practice EDITED`) in every installed repo, and nothing —
# not the failure detail, not any file the installer wrote — named a way out.
#
# WHICH ASSERTIONS ARE CONTROLS AND WHICH ARE GUARDS — measured, not asserted.
# A tree exported from cadf79b — or from 6cabb50, this change's actual parent — with this file
# copied into it fails 23 of the 40 assertions and exits 1 (17 ok / 23 FAIL). Those 23 are the
# controls:
#   * 4 name-the-remedy assertions: the `practice EDITED` detail, the installed verifier, the
#     installed `practice` skill and docs/CONTRACTS.md all say nothing about `--re-pin` there;
#   * 14 from the "the documented path clears it" block: `--re-pin` is an unknown option there
#     (exit 2), so nothing is rewritten, nothing prints either hash, and IN-02 stays RED;
#   * the 2 refusal *messages* ("nothing to re-pin", "no practice: recorded");
#   * 3 from the quoted-pin block (the verifier, `--re-pin` exiting 0, and "already current") —
#     there the setup re-pin fails, so the pin is left stale and even the first of the three
#     reds.
# The other 17 pass on both trees by design — they are GUARDS, pinning behaviour that must not
# change: installed.json is byte-identical after a re-pin, exactly one config line moves, a second
# re-pin writes nothing, `--upgrade` never re-pins, `--re-pin --dry-run` writes nothing, and the
# pin still reds a further edit. Several pass *trivially* on the pre-change tree (there is no
# re-pin to observe), which is why they are labelled GUARD and not counted as proof.
#
# THE g_unquote CONTROL IS SEPARATE FROM THAT MEASUREMENT. The quoted-pin block exists for one
# defect found in this change's own first cut: the verifier `g_unquote`s `practice_sha256:` but
# the re-pin did not, so against a hand-quoted config the re-pin printed two identical hashes and
# rewrote a line that already matched. Reverting only that one line of `bin/goblin-install` (from
# 39c546c) reds exactly 2 of these 40 assertions — "reports the pin already current" and "rewrites
# nothing" — and the whole file still exits 1.
#
# Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
TARGET="$WORK/target"
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }
sha() { sha256sum "$1" | awk '{print $1}'; }

printf 'profiles:\n  coder:\n    model: model-code\n    provider: prov-code\n    effort: low\n' > "$WORK/models.yaml"
printf '# a fixture standard\nthe house style lives here\n' > "$WORK/standard.md"

mkdir -p "$TARGET" && cd "$TARGET"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# target\n' > README.md
git add -A && git commit -q -m "chore: seed"

bash "$SRC/bin/goblin-install" --target "$TARGET" --class A --models "$WORK/models.yaml" \
  --practice "$WORK/standard.md" >/dev/null 2>&1
git add -A && git commit -q -m "chore: install goblin-stack"

PIN_BEFORE=$(grep '^practice_sha256:' .goblin/goblin.yaml | awk '{print $2}')
INSTALLED_BEFORE=$(sha .goblin/installed.json)

# ---- baseline ----------------------------------------------------------------
out=$(bash .goblin/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "the fixture starts IN-02 PASS, exit 0" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'practice pin ok'
check "  and the detail says 'practice pin ok'" "$?"
[ "$PIN_BEFORE" = "$(sha "$WORK/standard.md")" ]
check "  and the recorded pin is the fixture standard's hash" "$?"

# ---- the legitimate edit, and the remedy it must name ------------------------
printf '# a corrected sentence\n' >> "$WORK/standard.md"
out=$(bash .goblin/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "one edited byte of the standard reds IN-02 (exit 1)" "$([ "$rc" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'practice EDITED'
check "  and the detail says 'practice EDITED'" "$?"
printf '%s' "$out" | grep -q 'practice standard edited:'
check "  and names the edited file" "$?"
printf '%s' "$out" | grep -q -- '--re-pin'
check "  and the failure detail names the re-pin remedy (CONTROL)" "$?"
grep -q -- '--re-pin' .goblin/bin/goblin-verify
check "  and the installed verifier names it (CONTROL)" "$?"
grep -q -- '--re-pin' .hermes/skills/practice/SKILL.md
check "  and the installed practice skill names it (CONTROL)" "$?"
grep -q -- '--re-pin' "$SRC/docs/CONTRACTS.md"
check "  and docs/CONTRACTS.md documents it (CONTROL)" "$?"

# ---- the documented path clears it ------------------------------------------
out=$(bash "$SRC/bin/goblin-install" --target "$TARGET" --re-pin 2>&1); rc=$?
check "the documented re-pin exits 0 (CONTROL: exit 2 pre-change)" \
  "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q "recorded $PIN_BEFORE"
check "  and prints the OLD hash it replaced" "$?"
PIN_AFTER=$(grep '^practice_sha256:' .goblin/goblin.yaml | awk '{print $2}')
[ "$PIN_AFTER" != "$PIN_BEFORE" ] && [ "$PIN_AFTER" = "$(sha "$WORK/standard.md")" ]
check "  and the new pin is the standard's current hash" "$?"
printf '%s' "$out" | grep -q "$PIN_AFTER"
check "  and prints the NEW hash too" "$?"

out=$(bash .goblin/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "IN-02 is PASS again (exit 0)" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'practice pin ok'
check "  and the detail says 'practice pin ok'" "$?"

# ---- the `owned` contract holds for every other line ------------------------
[ "$(sha .goblin/installed.json)" = "$INSTALLED_BEFORE" ]
check "installed.json is byte-identical (GUARD: the record was not rewritten)" "$?"
DIFF=$(git --no-pager diff --unified=0 -- .goblin/goblin.yaml)
[ "$(printf '%s\n' "$DIFF" | grep -cE '^[+-][^+-]')" -eq 2 ]
check "exactly one config line removed and one added" "$?"
printf '%s' "$DIFF" | grep -q '^-practice_sha256:'
check "  the removed line is practice_sha256:" "$?"
printf '%s' "$DIFF" | grep -q '^+practice_sha256:'
check "  the added line is practice_sha256:" "$?"
[ "$(git status --porcelain)" = " M .goblin/goblin.yaml" ]
check "  and no other path in the repo changed" "$?"

# ---- the re-pin is stable, and the pin still bites afterwards ----------------
git add -A && git commit -q -m "chore: re-pin the practice standard" >/dev/null 2>&1 || true
CONFIG_AFTER=$(sha .goblin/goblin.yaml)
out=$(bash "$SRC/bin/goblin-install" --target "$TARGET" --re-pin 2>&1); rc=$?
check "a second re-pin exits 0" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'already current'
check "  and says the pin is already current" "$?"
[ "$(sha .goblin/goblin.yaml)" = "$CONFIG_AFTER" ]
check "  and the config is byte-identical (nothing rewritten)" "$?"

printf '# a silent byte nobody asked for\n' >> "$WORK/standard.md"
out=$(bash .goblin/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "an edit AFTER a re-pin reds IN-02 again (GUARD)" "$([ "$rc" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'practice EDITED'
check "  with 'practice EDITED'" "$?"
[ "$(grep '^practice_sha256:' .goblin/goblin.yaml | awk '{print $2}')" = "$PIN_AFTER" ]
check "  and the pin was not re-recorded behind our back (GUARD)" "$?"

# ---- --dry-run writes nothing ------------------------------------------------
CONFIG_BEFORE_DRY=$(sha .goblin/goblin.yaml)
out=$(bash "$SRC/bin/goblin-install" --target "$TARGET" --re-pin --dry-run 2>&1); rc=$?
check "--re-pin --dry-run exits 0" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'would re-pin'
check "  and prints the plan" "$?"
[ "$(sha .goblin/goblin.yaml)" = "$CONFIG_BEFORE_DRY" ]
check "  and writes nothing (GUARD)" "$?"

# ---- the two refusals: no config, and no practice: recorded ------------------
mkdir -p "$WORK/noconfig"
out=$(cd "$WORK/noconfig" && bash "$SRC/bin/goblin-install" --target "$WORK/noconfig" --re-pin 2>&1); rc=$?
check "no config -> exit 2 with a reason (not a crash; GUARD on the code)" \
  "$([ "$rc" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'nothing to re-pin'
check "  and says nothing to re-pin (CONTROL)" "$?"

mkdir -p "$WORK/nostandard"
cd "$WORK/nostandard"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# nostandard\n' > README.md
git add -A && git commit -q -m "chore: seed"
bash "$SRC/bin/goblin-install" --target "$WORK/nostandard" --class A --models "$WORK/models.yaml" \
  --practice "$WORK/absent.md" >/dev/null 2>&1
out=$(bash "$SRC/bin/goblin-install" --target "$WORK/nostandard" --re-pin 2>&1); rc=$?
check "no practice: configured -> exit 2 (GUARD on the code)" "$([ "$rc" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'no practice: recorded'
check "  and says there is no practice: to re-pin (CONTROL)" "$?"

# ---- a plain --upgrade must never re-pin by itself ---------------------------
cd "$TARGET"
PIN_STALE=$(grep '^practice_sha256:' .goblin/goblin.yaml | awk '{print $2}')
bash "$SRC/bin/goblin-install" --target "$TARGET" --class A --upgrade --models "$WORK/models.yaml" \
  --practice "$WORK/standard.md" >/dev/null 2>&1
[ "$(grep '^practice_sha256:' .goblin/goblin.yaml | awk '{print $2}')" = "$PIN_STALE" ]
check "--upgrade does not re-pin the standard by itself (GUARD)" "$?"
out=$(bash .goblin/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "  and the stale pin is still RED after it (exit 1)" "$([ "$rc" -eq 1 ] && echo 0 || echo 1)"

# ---- a hand-quoted pin is read the way goblin-verify reads it -----------------
# goblin-verify g_unquotes practice_sha256:, so a quoted value verifies green. The re-pin must
# agree, or it reports a spurious "re-pinned" with two identical hashes and rewrites a line that
# already matched. Measured before the fix: `recorded "81612b17..."` / `now 81612b17...` and a
# one-line diff, against a config the verifier called `practice pin ok`. This block runs last
# because it leaves the pin CURRENT, which the --upgrade guard above needs it not to be.
bash "$SRC/bin/goblin-install" --target "$TARGET" --re-pin >/dev/null 2>&1
sed -i 's/^practice_sha256: \(.*\)$/practice_sha256: "\1"/' .goblin/goblin.yaml
QUOTED=$(sha .goblin/goblin.yaml)
out=$(bash .goblin/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "a hand-quoted pin still verifies green (exit 0)" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
out=$(bash "$SRC/bin/goblin-install" --target "$TARGET" --re-pin 2>&1); rc=$?
check "  and --re-pin agrees: it exits 0 (CONTROL)" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'already current'
check "  and reports the pin already current (CONTROL)" "$?"
[ "$(sha .goblin/goblin.yaml)" = "$QUOTED" ]
check "  and rewrites nothing (GUARD)" "$?"

if [ "$fail" -eq 0 ]; then note "t-practice-repin: PASS"; else note "t-practice-repin: FAIL"; fi
exit "$fail"
