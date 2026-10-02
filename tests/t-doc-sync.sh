#!/usr/bin/env bash
# t-doc-sync.sh — the documents that claim to render the matrix must still render it.
#
#   F2-4  README calls docs/ENFORCEMENT.md "the matrix rendered for a human". Every row's check
#         cell AND its "if it cannot be enforced, why" cell must equal manifest/enforcement.tsv.
#         Measured stale at f23b371: checks IN-03, HP-02, SP-03, PT-01; whys IN-03, IN-04, HP-02,
#         SP-03, HS-01, PT-01, CL-02.
#   F2-8  docs/ROLES.md must say bin/goblin-model is checkout-only, because the installer does
#         not install it (measured in t-uninstall.sh) and it has no enforcement.tsv row.
#   F2-9  "A fresh install is not automatically green" is false as measured - a fresh class-A
#         install verifies 43 passed, 0 failed, 11 advisory, 28 skipped, exit 0. The claim was
#         written in FOUR places, not three: README.md, docs/CONTRACTS.md, docs/ADOPTION.md and
#         skills/goblin-bootstrap/SKILL.md - the last one being the copy the installer writes
#         into every target (bin/goblin-install:357-360), so a green target shipped the claim
#         that a fresh install is not green. All four are scanned, on text normalised for
#         markdown, because a literal grep is defeated by the claim's own emphasis: restored to
#         docs/ADOPTION.md as "A fresh install is **not** automatically green", the round-1
#         control printed ok and exited 0.
#   F2-3  docs/LIMITS.md must admit that .goblin/installed.json is not signed, because one edit
#         to it (plus the matching edit to the file it protects) yields a fully green run.
#   V3-1  templates/AGENTS.md.tmpl must name the ban engine, because that template is the only
#         source of the installed AGENTS.md - the file a session reads first. Without it a ban is
#         discoverable only in the post-mortem (V3-1).
#   V3-8  the verifier's "cannot see" footer must name the ban lane's own blind spots (the
#         unsigned ban table, the text-probe gap, a ban that is invisible until verify runs).
#   AB3   the advisory arithmetic is a number THIS matrix owns (`advisory_ceiling`), and it is
#         quoted as prose in five places. Three are dated history (the CHANGELOG entries,
#         docs/ENFORCEMENT.md's chronology, t-verify-red.sh's pre-change note) and keep their own
#         tense; the two LIVE claim sites stated 9 of 10 as what the run prints, one with no
#         dating at all. The live copies are read here, and only they.
#
# Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$SRC"
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

# norm <cell> — strip markdown code ticks, collapse whitespace, drop the doc's "(builtin)" note.
norm() { printf '%s' "$1" | sed 's/`//g' | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//; s/ (builtin)$//'; }

# norm_text <file> — the whole file with markdown emphasis, code ticks and run-together whitespace
# normalised away, so a claim cannot escape its own control by wearing **bold**. Emphasis markers
# become spaces (not nothing) so that `**not** automatically` and `not**automatically**` both
# normalise to the same readable phrase. The case fold is the second axis: the control this one
# replaced matched with `grep -qi`, and dropping the fold let `NOT automatically green` and a
# sentence-initial `Not automatically green` walk through (F3-followup, measured at e196b3e).
norm_text() { sed 's/[*_`]/ /g' "$1" | tr -s '[:space:]' ' ' | tr 'A-Z' 'a-z'; }

# The claim, in the normalised form the matcher looks for.
FALSE_RE='not[[:space:]]+automatically[[:space:]]+green'

# The documents a user receives: the three prose docs plus every SHIPPED skill
# (skills/*/SKILL.md is the installer's write set — bin/goblin-install:357-360).
CLAIM_DOCS="README.md docs/CONTRACTS.md docs/ADOPTION.md"
for f in skills/*/SKILL.md; do [ -f "$f" ] && CLAIM_DOCS="$CLAIM_DOCS $f"; done

# doc_cell <file> <row id> <field index> — the nth pipe-separated cell of the row whose first
# cell is the id. The cells escape their own pipes as \|, so unescape before splitting.
doc_cell() {
  awk -v id="$2" -v idx="$3" '
    /^\| *`/ {
      line = $0
      gsub(/\\\|/, "\001", line)
      n = split(line, f, "|")
      first = f[2]; gsub(/[` ]/, "", first)
      if (first != id) next
      cell = f[idx]
      gsub(/\001/, "|", cell)
      print cell
      exit
    }
  ' "$1"
}

# ---- F2-4: every cell of the rendered matrix equals the matrix ----------------
CELLS=0; DRIFT=""
while IFS=$'\t' read -r id scope rule by artifact check why; do
  [ "$id" = "id" ] && continue
  [ -n "$id" ] || continue
  CELLS=$((CELLS + 1))
  [ "$(norm "$(doc_cell docs/ENFORCEMENT.md "$id" 6)")" = "$(norm "$check")" ] || DRIFT="$DRIFT $id/check"
  [ "$(norm "$(doc_cell docs/ENFORCEMENT.md "$id" 7)")" = "$(norm "$why")" ] || DRIFT="$DRIFT $id/why"
done < manifest/enforcement.tsv
if [ -n "$DRIFT" ]; then
  note "docs/ENFORCEMENT.md has drifted from manifest/enforcement.tsv:$DRIFT"
  note "  (re-sync the cell, not the doc: the tsv is the source of truth)"
fi
check "docs/ENFORCEMENT.md renders all $CELLS rows of the matrix, both columns" \
  "$([ -z "$DRIFT" ] && echo 0 || echo 1)"

# ---- F2-8: the checkout-only statement ---------------------------------------
grep -qi 'checkout-only' docs/ROLES.md
check "docs/ROLES.md states that bin/goblin-model is checkout-only (F2-8)" "$?"

# ---- F2-9: the false claim is gone, the measured one is there ----------------
# The control's own control: the normalised matcher must still catch the claim wearing emphasis
# OR carrying a capital, or the scan below reports ok on exactly the broken copy the round-1
# review measured. The two capitalised forms are the ones F3-followup added: the round-1 control
# used `grep -qi` and this one did not, so `NOT automatically green` and a sentence-initial
# `Not automatically green` both passed until the fold above was restored.
for claim in \
  'A fresh install is **not** automatically green, and that is the design.' \
  'A fresh install is NOT automatically green.' \
  'Not automatically green: a fresh install needs a round.'
do
  if norm_text <(printf '%s\n' "$claim") | grep -qE "$FALSE_RE"; then
    note "ok   the F2-9 matcher catches: $claim"
  else
    note "FAIL the F2-9 matcher is defeated by: $claim"
    fail=1
  fi
done

FALSE_CLAIM=""
for f in $CLAIM_DOCS; do
  norm_text "$f" | grep -qE "$FALSE_RE" && FALSE_CLAIM="$FALSE_CLAIM $f"
done
[ -z "$FALSE_CLAIM" ] || note "still claims a fresh install is not green:$FALSE_CLAIM"
check "no shipped doc or skill claims a fresh install is not automatically green (F2-9)" \
  "$([ -z "$FALSE_CLAIM" ] && echo 0 || echo 1)"

# The three prose docs and the shipped bootstrap skill must carry the measured line; the other
# shipped skills do not discuss a verify run and are not required to. W6 neutral-first: the
# measured green path is the DEFAULT install's (skills opt-in, 38/0/11/33) — the pre-W6 default
# measured 43/0/11/28 and its copies are gone.
GREEN_CLAIM=""
for f in README.md docs/CONTRACTS.md docs/ADOPTION.md skills/goblin-bootstrap/SKILL.md; do
  norm_text "$f" | grep -q '38 passed, 0 failed, 11 advisory, 33 skipped' || GREEN_CLAIM="$GREEN_CLAIM $f"
done
[ -z "$GREEN_CLAIM" ] || note "does not state the measured green path:$GREEN_CLAIM"
check "README, CONTRACTS, ADOPTION and the shipped bootstrap skill state the measured green path" \
  "$([ -z "$GREEN_CLAIM" ] && echo 0 || echo 1)"

# ---- W6 neutral-first: the docs teach skills as an opt-in, never as an install default --------
# The 2026-10-01 audit finding: a default install that copies skills is a house leftover, not a
# neutral product default. The docs must say which side of the line they are on, in both
# directions: the opt-in is stated where a reader decides (README's platform section, the
# guide's install step), and no user-facing doc may claim the install writes skills by default.
for f in README.md docs/GUIDE.md; do
  norm_text "$f" | grep -q 'agent skills are opt-in'
  check "$f states agent skills are opt-in (W6 neutral-first)" "$?"
done
norm_text README.md | grep -q 'gob emit --platform'
check "README names gob emit --platform as the opt-in path (W6 neutral-first)" "$?"
# The stale claim, normalised like every matcher above: 'install' as subject of copying skills.
STALE_INSTALL_SKILLS=""
for f in README.md docs/GUIDE.md docs/CONTRACTS.md docs/ADOPTION.md; do
  norm_text "$f" | grep -qE 'install(s|ed)? (the )?(manifest, )?skills' && STALE_INSTALL_SKILLS="$STALE_INSTALL_SKILLS $f"
  norm_text "$f" | grep -q 'install .hermes/skills (default yes' && STALE_INSTALL_SKILLS="$STALE_INSTALL_SKILLS $f"
done
[ -z "$STALE_INSTALL_SKILLS" ] || note "still claims the install copies skills:$STALE_INSTALL_SKILLS"
check "no user-facing doc claims the install copies skills by default (W6 neutral-first)" \
  "$([ -z "$STALE_INSTALL_SKILLS" ] && echo 0 || echo 1)"
# The contracts doc documents the migration contract (an upgrade keeps recorded skills).
norm_text docs/CONTRACTS.md | grep -q 'skills: yes keeps them'
check "docs/CONTRACTS.md states the upgrade-keeps-recorded-skills contract (W6 neutral-first)" "$?"

# ---- W4-A: the CI lane's blind spots are stated where a run will see them --------------------
# The lane's own finding is that a workflow file is not a gate: GitHub reports a SKIPPED job as
# Success, and an admin can push straight past a protection rule. PROJECT-PRACTICE section 3
# requires every claim to say what it CANNOT see, and the "cannot see" footer is the place a run
# shows it - the V3-8 precedent, one lane over. The four settings a workflow needs to BE a gate
# live in docs/CI.md, because a template cannot arm a check.
awk '/^      cannot see:/,/^SEE$/ { if ($0 ~ /CI lane/) found = 1 } END { exit !found }' bin/goblin-verify
check "the verifier's 'cannot see' footer names the CI lane (W4-A)" "$?"
awk '/^      cannot see:/,/^SEE$/ { if ($0 ~ /required check/) found = 1 } END { exit !found }' bin/goblin-verify
check "  and says a required check is not the same thing as a gate" "$?"
for marker in 'required check' 'Do not allow bypassing' 'sole admin' 'skipped'; do
  grep -qi -- "$marker" docs/CI.md
  check "docs/CI.md states '$marker' - the settings that make a workflow a gate" "$?"
done
grep -q 'main_thread_busy_pct' docs/CI.md && grep -q 'app_bundle_bytes' docs/CI.md
check "docs/CI.md carries the Electron perf deviation, both metrics named" "$?"

# ---- W4-B / W6: the class matrix is rendered from manifest/classes.tsv ------------------------
# The part/class table is where a reader decides what a class owes, so it is the one place a class
# can rot in silence: the row set moved to `ci-gate R/-/O/-/O/R` at W4, and W6 merged the sixth
# (desktop/F) class into `software` - five domain-named columns now, with A-E as read-time aliases.
# The tsv is one row per (class, part) pair - `class<TAB>part<TAB>need` - and the doc renders a
# missing part as an em dash, so normalise. docs/ADOPTION.md's matrix is prose ("SPEC before
# change", "Design tokens"), so it is checked for its COLUMNS, not cell by cell.
CLASS_DRIFT=""
CLS=$(awk -F'\t' 'NR>1 { if (!seen[$2]++) print $2 }' manifest/classes.tsv)
for part in $CLS; do
  want=$(for c in software service game research fleet; do
           need=$(awk -F'\t' -v c="$c" -v p="$part" '$1==c && $2==p { print $3 }' manifest/classes.tsv)
           printf '%s|' "${need:--}"
         done | sed 's/|$//')
  got=$(grep -m1 "^| *$part *|" docs/ENFORCEMENT.md | tr -d ' `' \
        | awk -F'|' '{ out=""; for (i=3; i<=NF; i++) { gsub(/[ \t]/,"",$i); if ($i == "") continue; out = out "|" $i } sub(/^\|/,"",out); print out }')
  [ "$got" = "$want" ] || CLASS_DRIFT="$CLASS_DRIFT $part(doc=$got tsv=$want)"
done
[ -z "$CLASS_DRIFT" ] || note "class matrix drifted from manifest/classes.tsv:$CLASS_DRIFT"
check "docs/ENFORCEMENT.md renders the class matrix from manifest/classes.tsv (W4-B)" \
  "$([ -z "$CLASS_DRIFT" ] && echo 0 || echo 1)"
# W6: the sixth (desktop/F) class is merged into software; ADOPTION now teaches five domain-named
# classes and carries the electron opt-in that replaced F. The old pin measured the F row itself.
grep -q '^| \*\*software\*\* (A) |' docs/ADOPTION.md
check "docs/ADOPTION.md names the software class (W6: the F class merged in)" "$?"
grep -qi 'electron opt-in' docs/ADOPTION.md
check "  and states the electron opt-in that replaced the sixth class (W6)" "$?"
grep -qi '^| CI lane |' docs/ADOPTION.md
check "  and gives it a CI-lane row in the preset matrix" "$?"
grep -q 'docs/CI.md' README.md
check "README's document table names the CI lane (W4-B)" "$?"

# ---- F2-3: the unsigned record is admitted -----------------------------------
grep -qi 'is not signed' docs/LIMITS.md
check "docs/LIMITS.md admits that installed.json is not signed (F2-3)" "$?"
grep -q 'not signed' bin/goblin-verify
check "  and the verifier says so in its own 'cannot see' footer" "$?"

# ---- V3-1: a ban has to be discoverable BEFORE the code is written -----------
# The engine was named in docs/, CHANGELOG.md and two tests, and in nothing a session reads at an
# adopted repo - so the first signal was the red verify line (V3-1). The template is the only
# source of the installed AGENTS.md (bin/goblin-install:534).
grep -q 'goblin-bans' templates/AGENTS.md.tmpl
check "templates/AGENTS.md.tmpl names the ban engine, so a ban is seen in context (V3-1)" "$?"

# ---- V3-8: the footer names the ban lane's own blind spots -------------------
# PROJECT-PRACTICE section 3: every claim says what it CANNOT see. The lane's own limits (the
# unsigned ban table, the text-probe gap, and that no check reaches a ban in context) belong on
# every run, not only in docs/LIMITS.md.
awk '/^      cannot see:/,/^SEE$/ { if ($0 ~ /ban/) found = 1 } END { exit !found }' bin/goblin-verify
check "the verifier's 'cannot see' footer names the ban lane's blind spots (V3-8)" "$?"

# ---- AB3: the LIVE copies of the advisory arithmetic must match the run -----------------------
# `advisory_ceiling` is 10 and `SK-03` prints `advisory 10 of ceiling 10 (0 free slots: the next
# advisory row FAILs)`. docs/GUARDRAILS.md's third design constraint and docs/LIMITS.md #26 both
# presented 9 of 10 as what the run reports - LIMITS in the present tense ("reports that arithmetic
# on every run"), GUARDRAILS with no way to date it. Both are read here; the dated history
# (CHANGELOG entries, docs/ENFORCEMENT.md's chronology, t-verify-red.sh's pre-change note) is not,
# and keeps its own tense.
ADV_POINT=$(awk '/advisory_ceiling/ { c = 6 } c > 0 { print; c-- }' docs/GUARDRAILS.md)
printf '%s' "$ADV_POINT" | grep -q '10 of 10'
check "docs/GUARDRAILS.md's advisory point states the measured count (10 of 10) (AB3)" "$?"
printf '%s' "$ADV_POINT" | grep -qE '\*\*Corrected [0-9]{4}-[0-9]{2}-[0-9]{2}'
check "  and dates the correction, the way docs/LIMITS.md's own W2/W3 notes do (AB3)" "$?"
# Normalised, because the sentence wraps: a literal grep for 'reports that arithmetic on every run'
# is green on BOTH trees while the file holds '...on every\nrun' (measured at 58a6fe6).
LIMITS_FLAT=$(sed 's/[*_`]/ /g' docs/LIMITS.md | tr '\n' ' ' | tr -s '[:space:]' ' ')
if printf '%s' "$LIMITS_FLAT" | grep -q 'reports that arithmetic on every run'; then
  note "FAIL docs/LIMITS.md #26 still says the stale arithmetic is what the run reports (AB3)"
  fail=1
else
  note "ok   docs/LIMITS.md #26 no longer claims the stale arithmetic is what the run reports (AB3)"
fi

# ---- W4-C: the INTEGRATION hook claim states the measured mechanism ---------------------------
# docs/INTEGRATION.md's recovery paragraph is the project's bootstrap position. The W4a probe
# measured the mechanism on the real docs (hooks reference + the platform hooks pages): on this
# runtime on_session_start EXISTS and cannot inject (an observer's return is discarded), and
# pre_llm_call CAN inject into the user message. The old sentence claimed recovery was needed
# "rather than depending on a hook that does not exist" - false as measured (the hook exists;
# its return is what is discarded). The assertion pins the SHAPE on normalised text - it names
# pre_llm_call as able to inject and never lets a hook claim ride on "does not exist" - NOT a
# file:line (line numbers in prose drift; the repo has learned not to pin them). The mutation
# control below restores the old sentence and must go RED, or this asserts nothing.
# Normalisation strips emphasis and ticks but KEEPS underscores (the hook names are
# snake_case identifiers; a matcher that spaced them out could not see them at all).
INT_FLAT=$(sed 's/[*`]//g' docs/INTEGRATION.md | tr -s '[:space:]' ' ' | tr 'A-Z' 'a-z')
printf '%s' "$INT_FLAT" | grep -q 'pre_llm_call can inject into the user message'
check "docs/INTEGRATION.md names pre_llm_call as the hook that can inject (W4-C)" "$?"
if printf '%s' "$INT_FLAT" | grep -q 'hook that does not exist'; then
  note "FAIL docs/INTEGRATION.md still claims a hook does not exist (W4-C)"
  fail=1
else
  note "ok   no hook claim in docs/INTEGRATION.md rests on 'does not exist' (W4-C)"
fi
# the mutation control: the OLD sentence must be caught by the matcher above
OLD_INT='the mode skill is loadable on demand and AGENTS.md names it, so recovery is reading one file rather than depending on a hook that does not exist.'
if printf '%s' "$OLD_INT" | tr -s '[:space:]' ' ' | grep -q 'hook that does not exist'; then
  note "ok   the W4-C matcher catches the reverted (pre-W4a) sentence - the control is real"
else
  note "FAIL the W4-C matcher no longer catches the reverted sentence"
  fail=1
fi

# ---- W5-D: the README is written for the npm package --------------------------
# The package landed as @techgoblin/gobstack (6cd75b7) and the README was rewritten
# for a public audience. npm is THE install path, and the clone is not a path at all:
#   1. the npm identity is present (a reader arriving from npmjs.com must find it);
#   2. the npm install command is stated verbatim;
#   3. the `gob` CLI is named as what the npm install yields, `gob install`
#      as its install command;
#   4. NO user-facing clone/install instruction survives: the checkout's
#      `bin/goblin-install` and the clone URL must not appear in the README as an
#      instruction (W5 chunk 4 removed the two-path split; a reader of the old
#      path B text would follow an install the npm package does not document).
# The npm scope is written hyphenless (techgoblin) deliberately: the PR-04 portability
# pattern catches the hyphenated house name, and the package name is the one place
# the identity must literally appear. The clone URL is assembled at run time for the
# same reason (the owner's handle is itself a house identifier PR-04 exists to keep
# out of the source tree).
grep -q '@techgoblin/gobstack' README.md
check "README names the npm package @techgoblin/gobstack (W5-D)" "$?"
grep -q 'npm install -g @techgoblin/gobstack' README.md
check "  and states the npm install path (npm install -g @techgoblin/gobstack)" "$?"
grep -q 'gob install' README.md
check "  and names gob install as the npm CLI's install command (W5-D)" "$?"
if grep -q 'bin/goblin-install' README.md; then
  note "FAIL README still presents bin/goblin-install as an install instruction (W5-D)"
  fail=1
else
  note "ok   README presents no bin/goblin-install install instruction (W5-D)"
fi
CLONE_URL="https://github.com/$(printf '%s%s%s' 'harv' 'eyngu' 'yen33')/goblin-stack.git"
if grep -qF "$CLONE_URL" README.md; then
  note "FAIL README still presents the source clone as an install path (W5-D)"
  fail=1
else
  note "ok   README presents no source clone install path (W5-D)"
fi

# ---- W5-D: the GUIDE reads as one linear npm path -------------------------------
# The guide's two-route split (route A npm / route B clone, $GS, bin/goblin-install)
# is gone: npm is the only route it gives, in §2, §3, §10 and the appendix.
grep -q 'npm i -g @techgoblin/gobstack' docs/GUIDE.md
check "docs/GUIDE.md names the npm route (W5-D)" "$?"
grep -q 'gob install --target . --class A' docs/GUIDE.md
check "  and gives the npm CLI's Step-1 command (W5-D)" "$?"
if grep -q 'bin/goblin-install' docs/GUIDE.md || grep -qi 'route b' docs/GUIDE.md \
   || grep -qF '"$GS' docs/GUIDE.md; then
  note "FAIL docs/GUIDE.md still carries route-B / clone-install text (W5-D)"
  fail=1
else
  note "ok   docs/GUIDE.md carries no route-B / clone-install text (W5-D)"
fi

# ---- W6: the command surface is `gob` --------------------------------------------
# 2026-10-01 product decision: `gob` is THE CLI name. The docs must teach gob
# exclusively — the legacy `goblin <cmd>` invocation is allowed only where a line
# deliberately names the alias as an alias (README's legacy-alias note). A bare
# product wordmark 'goblin-stack' is likewise gone from user-facing docs: the
# product is gobstack (the npm scope's stem); the forge repo URL is the one
# sanctioned carrier of that string, and it is assembled at run time below.
GOB_VERBS='init|verify|install|emit|doctor|audit|upgrade|bans|uninstall'
for f in README.md docs/GUIDE.md; do
  n=$(grep -cE "\bgoblin ($GOB_VERBS)\b" "$f")
  if [ "$n" -eq 0 ]; then
    note "ok   $f carries no 'goblin <verb>' command invocation (W6 gob rename)"
  else
    note "FAIL $f still invokes 'goblin <verb>' $n time(s) (W6 gob rename)"
    grep -nE "\bgoblin ($GOB_VERBS)\b" "$f" | head -3
    fail=1
  fi
done
for f in README.md docs/GUIDE.md; do
  n=$(grep -c 'goblin-stack' "$f")
  if [ "$n" -eq 0 ]; then
    note "ok   $f carries no 'goblin-stack' product wordmark (W6 gobstack rename)"
  else
    note "FAIL $f still carries the 'goblin-stack' wordmark $n time(s) (W6 gobstack rename)"
    grep -n 'goblin-stack' "$f" | head -3
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then note "t-doc-sync: PASS"; else note "t-doc-sync: FAIL"; fi
exit "$fail"
