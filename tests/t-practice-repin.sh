#!/usr/bin/env bash
# t-practice-repin.sh — the practice pin has a documented, explicit re-pin path (F4-followup).
#
# The gap this closes. `PROJECT-PRACTICE.md` is a living standard, corrected in place, while
# the AGENTS.md gob block is a `owned` file the installer never rewrites. So one legitimate edit
# to the standard reddened `IN-02` (`practice EDITED`) in every installed repo, and nothing —
# not the failure detail, not any file the installer wrote — named a way out.
#
# WHICH ASSERTIONS ARE CONTROLS AND WHICH ARE GUARDS — measured, not asserted.
#
# BASELINE A, the pre-change tree (a tree exported from cadf79b — or from 6cabb50, this change's
# actual parent — with this file copied in): 47 assertions, 23 pass and 24 fail, exit 1. Those 24
# are the controls:
#   * 4 name-the-remedy assertions: the `practice EDITED` detail, the installed verifier, the
#     installed `practice` skill and docs/CONTRACTS.md all say nothing about `--re-pin` there;
#   * 14 from the "the documented path clears it" block: `--re-pin` is an unknown option there
#     (exit 2), so nothing is rewritten, nothing prints either hash, and IN-02 stays RED;
#   * the 2 refusal *messages* ("nothing to re-pin", "no practice: recorded");
#   * 3 from the quoted-pin block (the verifier, `--re-pin` exiting 0, and "already current") —
#     there the setup re-pin fails, so the pin is left stale and even the first of the three
#     reds;
#   * 1 from the "--uninstall --re-pin" block ("different jobs"): there `--re-pin` is unknown, so
#     the message is "unknown option: --re-pin", not the mutual-exclusion refusal.
# The other 23 pass on the pre-change tree too — they are GUARDS, pinning behaviour that must not
# change: installed.json is byte-identical after a re-pin, exactly one config line moves, a second
# re-pin writes nothing, `--upgrade` never re-pins, `--re-pin --dry-run` writes nothing, and the
# pin still reds a further edit. Several pass *trivially* on the pre-change tree (there is no
# re-pin to observe), which is why they are labelled GUARD and not counted as proof.
#
# BASELINE B, bf7e9c9 — the tree where the feature exists but both round-1 defects do: the same
# file fails exactly 5 of its 47 assertions (42 ok / 5 FAIL, exit 1), and all five are in the two
# blocks that close the round-1 findings:
#   * "a re-pin whose write cannot land exits non-zero" and "  and does not claim 'practice
#     re-pinned'" — at bf7e9c9 a read-only .gob/ made sed -i fail, yet the branch printed
#     "practice re-pinned" with both hashes and exited 0;
#   * "--uninstall --re-pin is refused, exit 2", "  and says they are different jobs" and "  and
#     the target was not uninstalled" — at bf7e9c9 the guard sat below the uninstall branch, so
#     the uninstall ran (exit 0, no message) and installed.json was gone.
# The two remaining assertions of those blocks ("the config is byte-identical", "the pin is still
# RED afterwards") are GUARDS: they pass at bf7e9c9 as well, because the write that failed left
# the config alone. The five defect controls pass *vacuously* on Baseline A (there `--re-pin` is
# an unknown option that exits 2 and writes nothing), which is why they are pinned to bf7e9c9 and
# not to 6cabb50.
#
# THE g_unquote CONTROL IS SEPARATE FROM BOTH MEASUREMENTS. The quoted-pin block exists for one
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

# W6 neutral-first: the default install is skills=no, and this control previously read the
# installed copy of the practice skill under .hermes/skills/. The control now reads the SOURCE
# copy (skills/*/SKILL.md is the installer's write set — the same file, pre-copy).
bash "$SRC/bin/goblin-install" --target "$TARGET" --class A --models "$WORK/models.yaml" \
  --practice "$WORK/standard.md" >/dev/null 2>&1
git add -A && git commit -q -m "chore: install gobstack"

# The one-block reader (the g_agents_read shape, inlined so the suite needs no lib sourcing).
g_agents_read() { sed -n "/^<!-- gob:begin/,/^<!-- gob:end/p" "$1" 2>/dev/null | sed "1d;\$d" | sed -n "s/^$2:[[:space:]]*//p" | head -n 1; }
PIN_BEFORE=$(g_agents_read "$TARGET/AGENTS.md" practice_sha256)
INSTALLED_BEFORE=$(sha .gob/installed.json)

# ---- baseline ----------------------------------------------------------------
out=$(bash .gob/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "the fixture starts IN-02 PASS, exit 0" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'practice pin ok'
check "  and the detail says 'practice pin ok'" "$?"
[ "$PIN_BEFORE" = "$(sha "$WORK/standard.md")" ]
check "  and the recorded pin is the fixture standard's hash" "$?"

# ---- the legitimate edit, and the remedy it must name ------------------------
printf '# a corrected sentence\n' >> "$WORK/standard.md"
out=$(bash .gob/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "one edited byte of the standard reds IN-02 (exit 1)" "$([ "$rc" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'practice EDITED'
check "  and the detail says 'practice EDITED'" "$?"
printf '%s' "$out" | grep -q 'practice standard edited:'
check "  and names the edited file" "$?"
printf '%s' "$out" | grep -q -- '--re-pin'
check "  and the failure detail names the re-pin remedy (CONTROL)" "$?"
grep -q -- '--re-pin' .gob/bin/goblin-verify
check "  and the installed verifier names it (CONTROL)" "$?"
grep -q -- '--re-pin' "$SRC/skills/practice/SKILL.md"
check "  and the practice skill names it (CONTROL; the source copy — a default install ships no skills)" "$?"
grep -q -- '--re-pin' "$SRC/docs/CONTRACTS.md"
check "  and docs/CONTRACTS.md documents it (CONTROL)" "$?"

# ---- the documented path clears it ------------------------------------------
out=$(bash "$SRC/bin/goblin-install" --target "$TARGET" --re-pin 2>&1); rc=$?
check "the documented re-pin exits 0 (CONTROL: exit 2 pre-change)" \
  "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q "recorded $PIN_BEFORE"
check "  and prints the OLD hash it replaced" "$?"
PIN_AFTER=$(g_agents_read "$TARGET/AGENTS.md" practice_sha256)
[ "$PIN_AFTER" != "$PIN_BEFORE" ] && [ "$PIN_AFTER" = "$(sha "$WORK/standard.md")" ]
check "  and the new pin is the standard's current hash" "$?"
printf '%s' "$out" | grep -q "$PIN_AFTER"
check "  and prints the NEW hash too" "$?"

out=$(bash .gob/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "IN-02 is PASS again (exit 0)" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'practice pin ok'
check "  and the detail says 'practice pin ok'" "$?"

# ---- the `owned` contract holds for every other line ------------------------
[ "$(sha .gob/installed.json)" = "$INSTALLED_BEFORE" ]
check "installed.json is byte-identical (GUARD: the record was not rewritten)" "$?"
DIFF=$(git --no-pager diff --unified=0 -- AGENTS.md)
[ "$(printf '%s\n' "$DIFF" | grep -cE '^[+-][^+-]')" -eq 2 ]
check "exactly one config line removed and one added" "$?"
printf '%s' "$DIFF" | grep -q '^-practice_sha256:'
check "  the removed line is practice_sha256:" "$?"
printf '%s' "$DIFF" | grep -q '^+practice_sha256:'
check "  the added line is practice_sha256:" "$?"
[ "$(git status --porcelain)" = " M AGENTS.md" ]
check "  and no other path in the repo changed" "$?"

# ---- the re-pin is stable, and the pin still bites afterwards ----------------
git add -A && git commit -q -m "chore: re-pin the practice standard" >/dev/null 2>&1 || true
CONFIG_AFTER=$(sha AGENTS.md)
out=$(bash "$SRC/bin/goblin-install" --target "$TARGET" --re-pin 2>&1); rc=$?
check "a second re-pin exits 0" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'already current'
check "  and says the pin is already current" "$?"
[ "$(sha AGENTS.md)" = "$CONFIG_AFTER" ]
check "  and the config is byte-identical (nothing rewritten)" "$?"

printf '# a silent byte nobody asked for\n' >> "$WORK/standard.md"
out=$(bash .gob/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "an edit AFTER a re-pin reds IN-02 again (GUARD)" "$([ "$rc" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'practice EDITED'
check "  with 'practice EDITED'" "$?"
[ "$(g_agents_read "$TARGET/AGENTS.md" practice_sha256)" = "$PIN_AFTER" ]
check "  and the pin was not re-recorded behind our back (GUARD)" "$?"

# ---- --dry-run writes nothing ------------------------------------------------
CONFIG_BEFORE_DRY=$(sha AGENTS.md)
out=$(bash "$SRC/bin/goblin-install" --target "$TARGET" --re-pin --dry-run 2>&1); rc=$?
check "--re-pin --dry-run exits 0" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'would re-pin'
check "  and prints the plan" "$?"
[ "$(sha AGENTS.md)" = "$CONFIG_BEFORE_DRY" ]
check "  and writes nothing (GUARD)" "$?"

# ---- CONTROL: a re-pin whose one write does not land fails closed -------------
# Before the fix the branch printed "practice re-pinned" with both hashes and exited 0 even when
# the write could not land (measured at bf7e9c9: a read-only .gob/ -> sed -i "couldn't open
# temporary file ... Permission denied", exit 0, config byte-identical, IN-02 still RED). That is
# the "hash nobody verified" class this command exists to remove. The pin is stale here, so the
# branch actually reaches the write.
# v2 mechanism note: the yaml-era control made the REPO read-only, because sed -i creates its
# temp file in the config's directory. g_agents_write writes through mktemp+cp: the temp lands
# in $TMPDIR and cp only needs WRITE permission on the CONFIG FILE itself (open O_TRUNC on an
# existing owned file needs no directory write). So the fault is injected on the file: 444.
CONFIG_BEFORE_FAIL=$(sha AGENTS.md)
chmod 444 AGENTS.md
out=$(bash "$SRC/bin/goblin-install" --target "$TARGET" --re-pin 2>&1); rc=$?
chmod 644 AGENTS.md
check "a re-pin whose write cannot land exits non-zero (CONTROL)" \
  "$([ "$rc" -ne 0 ] && echo 0 || echo 1)"
if printf '%s' "$out" | grep -q 'practice re-pinned'; then
  check "  and does not claim 'practice re-pinned' (CONTROL)" 1
else
  check "  and does not claim 'practice re-pinned' (CONTROL)" 0
fi
[ "$(sha AGENTS.md)" = "$CONFIG_BEFORE_FAIL" ]
check "  and the config is byte-identical (GUARD)" "$?"
out=$(bash .gob/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "  and the pin is still RED afterwards (GUARD)" "$([ "$rc" -eq 1 ] && echo 0 || echo 1)"

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

# ---- CONTROL: --uninstall and --re-pin are mutually exclusive -----------------
# The guard sat below the uninstall branch, which ends `exit 0`, so `--uninstall --re-pin` ran the
# uninstall and never saw the refusal (measured at bf7e9c9: exit 0, "different jobs" never
# printed, and the target WAS uninstalled). Moved above the branch, the pair is refused and the
# target is left alone. $WORK/nostandard is installed, so the uninstall branch would otherwise run.
out=$(bash "$SRC/bin/goblin-install" --target "$WORK/nostandard" --uninstall --re-pin 2>&1); rc=$?
check "--uninstall --re-pin is refused, exit 2 (CONTROL)" "$([ "$rc" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'different jobs'
check "  and says they are different jobs (CONTROL)" "$?"
[ -f "$WORK/nostandard/.gob/installed.json" ]
check "  and the target was not uninstalled (CONTROL)" "$?"

# ---- a plain --upgrade must never re-pin by itself ---------------------------
cd "$TARGET"
PIN_STALE=$(g_agents_read "$TARGET/AGENTS.md" practice_sha256)
bash "$SRC/bin/goblin-install" --target "$TARGET" --class A --upgrade --models "$WORK/models.yaml" \
  --practice "$WORK/standard.md" >/dev/null 2>&1
[ "$(g_agents_read "$TARGET/AGENTS.md" practice_sha256)" = "$PIN_STALE" ]
check "--upgrade does not re-pin the standard by itself (GUARD)" "$?"
out=$(bash .gob/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "  and the stale pin is still RED after it (exit 1)" "$([ "$rc" -eq 1 ] && echo 0 || echo 1)"

# ---- a hand-quoted pin is read the way goblin-verify reads it -----------------
# goblin-verify g_unquotes practice_sha256:, so a quoted value verifies green. The re-pin must
# agree, or it reports a spurious "re-pinned" with two identical hashes and rewrites a line that
# already matched. Measured before the fix: `recorded "81612b17..."` / `now 81612b17...` and a
# one-line diff, against a config the verifier called `practice pin ok`. This block runs last
# because it leaves the pin CURRENT, which the --upgrade guard above needs it not to be.
bash "$SRC/bin/goblin-install" --target "$TARGET" --re-pin >/dev/null 2>&1
sed -i 's/^practice_sha256: \(.*\)$/practice_sha256: "\1"/' AGENTS.md
QUOTED=$(sha AGENTS.md)
out=$(bash .gob/bin/goblin-verify --only IN-02 2>&1); rc=$?
check "a hand-quoted pin still verifies green (exit 0)" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
out=$(bash "$SRC/bin/goblin-install" --target "$TARGET" --re-pin 2>&1); rc=$?
check "  and --re-pin agrees: it exits 0 (CONTROL)" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$out" | grep -q 'already current'
check "  and reports the pin already current (CONTROL)" "$?"
[ "$(sha AGENTS.md)" = "$QUOTED" ]
check "  and rewrites nothing (GUARD)" "$?"

if [ "$fail" -eq 0 ]; then note "t-practice-repin: PASS"; else note "t-practice-repin: FAIL"; fi
exit "$fail"
