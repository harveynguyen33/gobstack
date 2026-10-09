#!/usr/bin/env bash
# t-doc-guide.sh — `docs/GUIDE.md` is the front door: the file this project hands to other
# developers. Until AB2 nothing in `tests/` read it (measured: `grep -rn GUIDE tests/*.sh` -> 0
# hits), which is why four sentences a measurement contradicted survived in it. This file is the
# control.
#
# What it asserts, and why each one is here:
#
#   D1  the guide's hands-on REPLAY exercise is RUN, not paraphrased: the block is extracted from
#       `docs/GUIDE.md` (both copies, §7 and the appendix) between two sentinels the guide carries,
#       the two copies must be identical, and every `goblin-verify` line in it must do what its own
#       `# expect PASS|FAIL` annotation promises - verdict AND exit code. At d5424be the exercise
#       promised a FAIL from `--only GT-02` that the shipped configuration cannot produce
#       (measured: PASS rc 0), i.e. the guide taught the lesson backwards.
#   D4  `created 23` is the installer's count of the files it TRACKS (the v2 neutral-first
#       default install is skills=no); it writes 24, because `.gob/installed.json` is written
#       but not counted. The number in the guide is checked against a real install and the
#       gloss must say which file the counter omits.
#   D5  §1's network claim must be scoped the way every other copy of it is (GUARDRAILS: "No
#       network at verify time"; README/CONTRACTS: under "Dependencies").
#   §3/§9  the guide's own reproducible numbers, re-measured here on a fresh class-A install: the
#       `created 23` line, the day-one line (`34 passed, 1 failed, 6 advisory, 21 skipped`) and the
#       green-path line (`35 passed, 0 failed, 6 advisory, 21 skipped`) — the v2 shapes (the CI
#       payload is gone, so PG-06 SKIPs where it passed vacuously: pass 38 -> 37, skip 33 -> 34;
#       before that skills opt-in moved the pass count 43 -> 38 and the skip count 28 -> 33). A
#       number no run prints is the defect this half exists to catch.
#   AB3 §8's rule sentence names HOW MANY files `IN-02` covers, and §11 states a review score. The
#       sentence said "hashes every file the installer wrote" - measured false (the installer writes
#       51, the row's `files` map is 41), so the reader's counterexample file drifted nothing. The
#       count the guide quotes is asserted against the map a real install writes, the universal is
#       asserted gone, and the 9/10 is asserted to name the revision it was measured at. A control
#       that RUNS a guide's commands does not read its sentences - this half reads two of them.
#   AB4 §11's identity stamp: the guide's own `Version:` line stated a revision the tree had moved
#       past - measured at 67a0872 the stamp says `0.4.3` while `VERSION` and all five `bin/`
#       constants say `0.4.4` - and nothing in `tests/` read it, which is how it survived the wave
#       that version-stamped the score eleven lines below it. The stamp is read out of the FILE, not
#       out of a line number: the header is prose, so a re-wrap moves the number off the label's
#       line. The matcher joins the first `Version:` line with the line after it and strips markdown
#       emphasis, so it tolerates a re-wrapped or `**bold**` stamp; it does NOT tolerate the label
#       and the number separated by more than one line, or a missing label.
#
# RED on d5424be / GREEN at the tip: the REPLAY block does not exist there at all, the `created 50`
# gloss is the false one, and §1 carries the unscoped claim. RED at 58a6fe6: the AB3 assertions
# below (the guide quotes no files-map length there, and the 9/10 carries no revision). RED at
# 67a0872: the guide's own `Version:` stamp still says `0.4.3` while `VERSION` is `0.4.4` - the AB4
# assertion below.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GUIDE="$SRC/docs/GUIDE.md"
WORK=$(mktemp -d)
HOMEDIR="$WORK/home"
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

# ---- D1, part 1: extract the guide's own exercise ---------------------------------------------
# The sentinels are comment lines the exercise carries, so the block a reader copies is exactly the
# block this test runs. Two copies are required (§7 and the appendix) and they must agree.
n=$(awk -v dir="$WORK" '
  /REPLAY-BEGIN/ { n++; f = 1; next }
  /REPLAY-END/   { f = 0; next }
  f              { print > (dir "/replay." n) }
  END            { print n + 0 }
' "$GUIDE")
check "the guide carries the REPLAY exercise between its sentinels ($n block(s) found)" \
  "$([ "${n:-0}" -ge 1 ] && echo 0 || echo 1)"
check "  and it carries it in both copies (§7 and the appendix), so neither can contradict the other" \
  "$([ "${n:-0}" -ge 2 ] && echo 0 || echo 1)"
if [ "${n:-0}" -ge 2 ]; then
  if diff <(sed 's/^[[:space:]]*//' "$WORK/replay.1") <(sed 's/^[[:space:]]*//' "$WORK/replay.2") >/dev/null; then
    note "ok   the two copies are identical"
  else
    note "FAIL the two copies of the REPLAY exercise differ:"; fail=1
    diff <(sed 's/^[[:space:]]*//' "$WORK/replay.1") <(sed 's/^[[:space:]]*//' "$WORK/replay.2") | sed 's/^/        /'
  fi
fi

# ---- the target the block runs in: the guide's own command, and nothing else -------------------
# Exactly §3: an EMPTY repo (no seed commit - the installer fills HANDOFF.md from HEAD when one
# exists, which is not the day-one shape the guide documents), then the install, then the commit.
mkdir -p "$WORK/target" "$HOMEDIR"
cd "$WORK/target"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"

# The reader's $HOME must not matter to any number below (the control runs with a throwaway one).
INSTALL=$(HOME="$HOMEDIR" bash "$SRC/bin/goblin-install" --target . 2>&1)
check "the guide's install command exits 0" "$?"
printf '%s\n' "$INSTALL" | head -1 | grep -qE '^created [0-9]+ · updated 0 · unchanged 0 · skipped 0$'
check "  and prints the created/updated/unchanged/skipped line" "$?"
CREATED=$(printf '%s\n' "$INSTALL" | sed -n 's/^created \([0-9]*\) .*/\1/p' | head -1)

git add -A && git commit -q -m "chore: install gobstack"

# ---- D1, part 2: RUN the block the guide writes ------------------------------------------------
run_replay() { # <block file>
  local file="$1" line cmd want out rc id
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"                 # the block is indented in the doc
    case "$line" in ''|'#'*) continue ;; esac
    want=""
    case "$line" in
      *'# expect PASS'*) want=PASS ;;
      *'# expect FAIL'*) want=FAIL ;;
    esac
    cmd=$(printf '%s' "$line" | sed 's/[[:space:]]*# expect \(PASS\|FAIL\)[[:space:]]*$//')
    if printf '%s' "$cmd" | grep -q 'goblin-verify'; then
      if [ -z "$want" ]; then
        note "FAIL the guide's own '$(printf '%s' "$cmd" | cut -c1-46)...' carries no '# expect' annotation"
        fail=1; continue
      fi
    fi
    out=$(HOME="$HOMEDIR" bash -c "$cmd" 2>&1); rc=$?
    [ -n "$want" ] || continue
    id=$(printf '%s' "$cmd" | sed -n 's/.*--only[[:space:]]*\([A-Z][A-Z]-[0-9][0-9]*\).*/\1/p')
    local want_rc=0; [ "$want" = FAIL ] && want_rc=1
    if [ "$rc" -ne "$want_rc" ]; then
      note "FAIL the guide says '# expect $want' and '$(printf '%s' "$cmd" | cut -c1-44)...' exits $rc"
      fail=1; continue
    fi
    if [ -n "$id" ] && ! printf '%s\n' "$out" | grep -qE "^$want[[:space:]]+$id"; then
      note "FAIL the guide says '# expect $want' but the run prints: $(printf '%s' "$out" | head -1 | cut -c1-60)"
      fail=1; continue
    fi
    note "ok   the guide's '$want' holds: $(printf '%s' "$out" | grep -m1 -E '^(PASS|FAIL|SKIP|ADV)' | cut -c1-58)"
  done < "$file"
}
if [ "${n:-0}" -ge 1 ]; then
  run_replay "$WORK/replay.1"
  # the exercise must leave the tree as it found it
  check "the guide's exercise restores the tree it broke" \
    "$([ -z "$(git status --porcelain)" ] && echo 0 || echo 1)"
fi

# ---- D4: the file count, and the gloss the guide puts on it ------------------------------------
# The WALKED path in the guide is `gob init` (review-UX pass), which ships no .github workflow.
# GAP-2: the seven-skill core procedure tier is now vendored under .gob/skills/, so the write
# set grew by 7 (the 20-file neutral harness -> 27 files, created 26). The gloss in §3 quotes
# both sides of the one-file delta and says which file the counter omits. Asserted against a real run.
ONDISK=$(find . -path ./.git -prune -o -type f -print | wc -l)
# v2 neutral-first + GAP-2: the DEFAULT install is skills=no for the Hermes tier but always vendors
# the core procedure tier, so the write set is the neutral harness + .gob/skills/ (27 files:
# 20 tracked + the 7 core skills + .gob/installed.json + the owned files + .gitignore).
[ "$ONDISK" = "27" ]
check "a default install writes 27 files (20 harness + 7 core skills) (measured here: $ONDISK; created $CREATED)" "$?"
check "  and the guide quotes the plain installer's own count (created $CREATED)" \
  "$(printf '%s' "$CREATED" | grep -qE '^26$' && echo 0 || echo 1)"
grep -qF "created 26 · updated 0 · unchanged 0 · skipped 0" "$GUIDE"
check "  and the guide's walked-path transcript is the installer's created-26 line" "$?"
! grep -q 'means it wrote 50 files' "$GUIDE"
check "  and the false gloss ('created 50 means it wrote 50 files') is gone (D4)" "$?"
GLOSS_LINE=$(grep -n "created 26" "$GUIDE" | head -1 | cut -d: -f1)
if [ -n "$GLOSS_LINE" ] && sed -n "${GLOSS_LINE},$((GLOSS_LINE + 12))p" "$GUIDE" | grep -q 'installed\.json'; then
  note "ok   the gloss names the file the counter does not count (.gob/installed.json)"
else
  note "FAIL the gloss on 'created $CREATED' does not say which file the installer omits from the count"
  fail=1
fi

# ---- AB3: the guide's own file-count claim must equal the map a real install writes -------------
# §8's rule tells the reader which row to break, and until AB3 it said `IN-02` "hashes every file the
# installer wrote" - measured false: the installer writes 51 files into an empty repo and the row's
# `files` map is 40, so the ten it does not hash (including the `AGENTS.md` gob block, the file §5 step 3
# has the reader edit) drift nothing and the exercise "confirms" a check that never moved. The count
# the sentence quotes is compared with the map THIS install wrote, and the universal is compared with
# absence. Both are RED at 58a6fe6, where the sentence carries no count at all.
#
# The absence half normalises the file first (markdown emphasis/code ticks to spaces, newlines to
# spaces, whitespace collapsed). A literal grep is green on BOTH trees: measured at 58a6fe6, the
# pre-change file holds "hashes every file the\ninstaller wrote" - the claim wraps, so the string the
# reader sees is not the string the file holds. That is the same defeat-the-control-by-emphasis trap
# t-doc-sync's F2-9 matcher documents.
NORMTXT=$(sed 's/[*_`]/ /g' "$GUIDE" | tr '\n' ' ' | tr -s '[:space:]' ' ')
FILESMAP=$(awk '/^  "files": \{/{f=1;next} f&&/^  \},$/{f=0} f&&/^    "/{n++} END{print n+0}' .gob/installed.json)
QUOTED=$(sed -n 's/.*hashes the [^0-9]*\([0-9][0-9]*\) files.*/\1/p' "$GUIDE" | head -1)
check "the guide quotes the files-map length a real install writes ($QUOTED quoted vs $FILESMAP measured)" \
  "$([ -n "$QUOTED" ] && [ "$QUOTED" = "$FILESMAP" ] && echo 0 || echo 1)"
if printf '%s' "$NORMTXT" | grep -q 'hashes every file the installer wrote'; then
  note "FAIL the guide still says \`IN-02\` hashes EVERY file the installer wrote (AB3)"
  fail=1
else
  note "ok   the false universal ('IN-02 hashes every file the installer wrote') is gone (AB3)"
fi

# ---- AB3: the stated score must name the revision it describes ---------------------------------
# §12 previously presented a previous revision's **9/10** as "the current status". The v2 guide
# carries no score at all — a score is a claim about a revision, and the honest v2 statement is
# the LIMITS pointer. The control asserts the score stays absent-or-attributed: if a score comes
# back, it must name the revision it was measured at.
if grep -q '9/10' "$GUIDE"; then
  awk '/9\/10/ { c = 2 } c > 0 { print; c-- }' "$GUIDE" | grep -qE '[0-9]\.[0-9][0-9]*\.[0-9]'
  check "the guide's 9/10 score names the revision it was measured at (AB3)" "$?"
else
  note "ok   the guide carries no review score to go stale (the v2 shape)"
fi

# ---- AB4: the guide's own identity stamp must equal VERSION --------------------------------------
# The `Version:` stamp at the top of the front door is a claim about the file's own identity, and
# until AB4 nothing read it: measured at 67a0872 the line says `0.4.3` while `VERSION` and all five
# `bin/` constants say `0.4.4` - it is the only stale stamp in the tree, and the same wave that
# version-stamped the score eleven lines below it left the header behind.
#
# The stamp is read out of the FILE, not out of a line number. This is prose: a re-wrap moves the
# number off the label's line, which is the same trap the AB3 count control fell into above (a
# matcher that assumes one line is green on a reflowed file it should catch). So the matcher joins
# the first `Version:` line with the line after it and strips markdown emphasis before it looks for
# the version. It TOLERATES a re-wrapped header and emphasis (`Version: **0.4.4**`); it does NOT
# tolerate a missing label, or a label whose number sits more than one line below it. The number
# may carry a prerelease suffix since 0.6.0-alpha.1 (semver), so the match is ERE (`sed -E`) and
# takes the optional `-<prerelease>` tail whole — a core-only match would read 0.6.0-alpha.1 as
# 0.6.0 and pass a stamp that is NOT the source of truth.
STAMP=$(awk '/Version:/{f=1} f{printf "%s ", $0; n++} n>=2{exit}' "$GUIDE" \
        | sed 's/[*_`]/ /g' \
        | sed -E -n 's/.*Version:[^0-9]*([0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?).*/\1/p')
VERSION_FILE=$(cat "$SRC/VERSION")
check "the guide's own Version: stamp equals VERSION ($STAMP stamped vs $VERSION_FILE in VERSION) (AB4)" \
  "$([ -n "$STAMP" ] && [ "$STAMP" = "$VERSION_FILE" ] && echo 0 || echo 1)"

# ---- D5: the network claim is scoped -----------------------------------------------------------
! grep -q 'It adds no network calls' "$GUIDE"
check "the unscoped claim ('It adds no network calls') is gone from §1 (D5)" "$?"
# The paragraph that carries the dependency list must scope the network claim itself: the sentence
# whose subject is "no server and no dependencies" is the one a new reader meets FIRST, and the
# unscoped version of it stood while §8 and §11 both said the audit step is the network step.
awk '/no server and no dependencies/{f=1} f{print} f && /^[[:space:]]*$/{exit}' "$GUIDE" \
  | grep -qi 'verify'
check "  and the same paragraph now scopes it to verify time" "$?"

# ---- §3/§9: the guide's own numbers, re-measured ------------------------------------------------
# The WALKED path is the wizard's (t-doc-guide-init.sh re-measures its 31/6 -> 35/2 -> 36/1
# shapes against the guide); the plain installer path is re-measured here. The tight set control
# below accepts BOTH paths' shapes — every line the guide quotes must be one EITHER run printed.
DAYONE=$(HOME="$HOMEDIR" bash .gob/bin/goblin-verify 2>&1 | grep -m1 -E '^ +[0-9]+ passed, [0-9]+ failed, [0-9]+ advisory, [0-9]+ skipped$' | sed 's/^ *//')
printf '%s\n' "$DAYONE" | grep -qE '^16 passed, 1 failed, 0 advisory, 10 skipped$'
check "the day-one run prints the shape the guide documents ($DAYONE)" "$?"

HEAD_NOW=$(git rev-parse --short HEAD)
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$HEAD_NOW\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"
GREEN=$(HOME="$HOMEDIR" bash .gob/bin/goblin-verify 2>&1 | grep -m1 -E '^ +[0-9]+ passed, [0-9]+ failed, [0-9]+ advisory, [0-9]+ skipped$' | sed 's/^ *//')
printf '%s\n' "$GREEN" | grep -qE '^17 passed, 0 failed, 0 advisory, 10 skipped$'
check "naming a real commit makes it green ($GREEN)" "$?"

# EVERY summary-shaped line in the guide must be one a real run printed — on this path or the
# wizard path (the six-shape set t-doc-guide-init.sh owns; the union is asserted there). The
# loose form of this (does the file contain the measured line?) is defeated by the claim living
# in three places: measured on a deliberately doctored copy that said 41 passed in §9 while §4
# still said 42, the loose form reported ok. A quoting claim that lives in three places is
# exactly how a stale number survives, so the tight form is the control.
# ...and no summary line in the guide is outside the set both paths print. The plain installer's
# two shapes are measured just above; the wizard's four are the set t-doc-guide-init.sh owns.
# The control is a SUBSET check: every summary-shaped line the guide quotes must be a line one of
# the six measured runs printed. (Equality would additionally demand the guide quote every shape
# of both paths in one file — the two paths are documented in their own sections, §3/§4 vs §9,
# and demanding the union in one file would freeze the doc's pedagogy, not its accuracy.)
SHAPES=$(grep -E '^[[:space:]]*[0-9]+ passed, [0-9]+ failed, [0-9]+ advisory, [0-9]+ skipped' "$GUIDE" \
         | sed -n 's/^[[:space:]]*\([0-9]* passed, [0-9]* failed, [0-9]* advisory, [0-9]* skipped\).*/\1/p' | sort -u)
# The wizard path's pre-commit shape (`gob init --write` leaves CM-03 + SP-02 red; its first
# commit is already green because the installer fills the HANDOFF HEAD) is t-doc-guide-init.sh's
# measurement — the plain installer this file walks never prints it. The guide teaches the wizard
# path in §8's table, so the set this SUBSET accepts is both paths' union.
WIZ_SHAPES=$(printf '%s\n' \
  "22 passed, 0 failed, 0 advisory, 5 skipped")
MEASURED=$(printf '%s\n%s\n%s\n' "$DAYONE" "$GREEN" "$WIZ_SHAPES" | sort -u)
SUBSET=0
while IFS= read -r s; do
  [ -n "$s" ] || continue
  printf '%s\n' "$MEASURED" | grep -qxF "$s" || { note "FAIL the guide quotes a summary line no run printed: $s"; SUBSET=1; }
done <<EOF_SHAPES
$SHAPES
EOF_SHAPES
check "every summary line the guide quotes is one a run printed ($(printf '%s' "$SHAPES" | tr '\n' ' ' | sed 's/ $//'))" "$SUBSET"

# ---- the exercise must not destroy the reader's own uncommitted work ---------------------------
# The block is path-limited on purpose, and the guide says so in its own parenthetical ("your own
# edits stay put"). §5 step 3 leaves an uncommitted the `AGENTS.md` gob block edit in a real reading, so
# an unqualified `git stash` + `git stash drop` would silently delete the reader's config. Measured
# here rather than claimed.
mkdir -p "$WORK/reader" && cd "$WORK/reader"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
HOME="$HOMEDIR" bash "$SRC/bin/goblin-install" --target . >/dev/null 2>&1
git add -A && git commit -q -m "chore: install gobstack"
printf '  # the reader-own edit §5 step 3 leaves behind\n' >> AGENTS.md
# The guard is not decoration: with no block extracted there is nothing to run, the edit survives
# for free, and the assertion would be green on BOTH trees - which is the one thing a control here
# may never be. Missing block = FAIL.
if [ -s "$WORK/replay.1" ]; then
  run_replay "$WORK/replay.1" >/dev/null 2>&1
  grep -q 'the reader-own edit' AGENTS.md
  check "the guide's REPLAY exercise leaves the reader's own uncommitted edit in place" "$?"
else
  note "FAIL no REPLAY block to run: 'your own edits stay put' is asserted by nothing"
  fail=1
fi

if [ "$fail" -eq 0 ]; then note "t-doc-guide: PASS"; else note "t-doc-guide: FAIL"; fi
exit "$fail"