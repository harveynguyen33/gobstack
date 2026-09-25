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
#         install verifies 42 passed, 0 failed, 9 advisory, 11 skipped, exit 0. The claim was
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
# shipped skills do not discuss a verify run and are not required to.
GREEN_CLAIM=""
for f in README.md docs/CONTRACTS.md docs/ADOPTION.md skills/goblin-bootstrap/SKILL.md; do
  norm_text "$f" | grep -q '42 passed, 0 failed, 9 advisory, 11 skipped' || GREEN_CLAIM="$GREEN_CLAIM $f"
done
[ -z "$GREEN_CLAIM" ] || note "does not state the measured green path:$GREEN_CLAIM"
check "README, CONTRACTS, ADOPTION and the shipped bootstrap skill state the measured green path" \
  "$([ -z "$GREEN_CLAIM" ] && echo 0 || echo 1)"

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

if [ "$fail" -eq 0 ]; then note "t-doc-sync: PASS"; else note "t-doc-sync: FAIL"; fi
exit "$fail"
