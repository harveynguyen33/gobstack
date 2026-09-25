#!/usr/bin/env bash
# t-doc-promises.sh — the promises the shipped documents make about THIS artifact, walked out of
# the documents themselves instead of listed in this file.
#
# THE SPECIES THIS FILE EXISTS TO CLOSE. Twelve verification waves found the same defect: a claim
# the artifact makes about itself that NOTHING reads. Each wave fixed the instance. This file is a
# control over the CLASS, so a successor is caught by the same code that caught its predecessor:
# it ENUMERATES its subjects from the artifact (the docs are walked, not hand-listed against) and
# resolves each one against a measurement of the artifact itself.
#
# ---------------------------------------------------------------------------------------------
# (a) A COMMAND PATH THE DOCS HAND A READER
#
#     The extractor walks `README.md` and `docs/*.md` and takes every token whose DIRECTORY is a
#     COMMAND directory:
#         `.goblin/bin/<name>`  -> must exist in a real class-A install this test makes itself
#         `bin/<name>`          -> must exist in this checkout
#     Both directories hold commands by construction, so no hand-list of shootable names is
#     involved: whatever the docs print, this test resolves.
#
#     RED case (B1, measured on the un-fixed tree): `docs/GUIDE.md:447` told the reader to run
#     `.goblin/bin/goblin-model <role>`. No install ships that path - a real class-A `.goblin/bin/`
#     holds exactly `goblin-audit`, `goblin-bans`, `goblin-lib.sh`, `goblin-verify` - and the tree
#     asserts the opposite elsewhere: `docs/ROLES.md:49` says in bold that `bin/goblin-model` is
#     checkout-only and `tests/t-uninstall.sh:36` asserts the install does not carry it. Running
#     the guide's own line in a fresh class-A install exits 127. A front door that hands a new
#     reader a command that cannot work.
#
#     DELIBERATELY NOT MATCHED, and why - read this before widening the extractor:
#       * a bare command name with no directory (`goblin-verify`, `goblin-install`). It resolves on
#         PATH or as `.goblin/bin/<name>`, and the docs use all three forms; the promise being
#         checked is about a PATH, and a bare name makes no path claim.
#       * a `.goblin/`-rooted path that is not a command. `.goblin/loop/...` is the loop's own
#         committed record, and `.goblin/last-gate-line` / `.goblin/audit.tsv` are written by a
#         RUN (`GT-02`'s gate line, `goblin-audit`'s output). The docs promise that a run produces
#         them, never that an install ships them, so "must exist right after install" is the wrong
#         assertion. `.goblin/manifest/*.tsv` is an installed DATA table, not a command: the
#         business half below and `tests/t-doc-sync.sh`'s cell comparison cover it.
#       * a path inside a fenced transcript that the reader is told to CREATE (`reports/<slug>/`,
#         `reviews/<slug>-<head7>.md`, `evals/<slug>/`). Those are outputs of the reader's own
#         work, not promises about the artifact.
#
# (a2) The same walk gives the guide's own half, because the guide is the one document written FOR
#     the reader's repo: a `manifest/<file>` token in `docs/GUIDE.md` names a file of THIS
#     checkout, which is not where the reader's copy lives (the guide's own section 1 writes
#     `.goblin/manifest/enforcement.tsv`). The rule is scoped to the guide because the other
#     documents address this checkout as well as the reader's repo - measured: `docs/ENFORCEMENT.md`
#     and `docs/LIMITS.md` each name `manifest/bans.tsv` in a sentence about the source table - so
#     the same assertion there would be false. RED case (B3): `docs/GUIDE.md:517` wrote
#     `manifest/bans.tsv` in a section 13 instruction addressed to the reader.
#
# ---------------------------------------------------------------------------------------------
# (b) A SELF-COUNT A DOC STATES ABOUT THE ARTIFACT
#
#     Two source tables, two families of claim, both walked from the documents:
#       * the playbook count. `manifest/playbooks.tsv` is the source (its data rows). Every
#         `<N> playbook(s)` claim and every `<the artifact> ships <N>` claim must equal it. The
#         second pattern is anchored on a subject - `this` or `goblin-stack` - because the same
#         heading compares against the PREDECESSOR project, and `pstack ships 23` is not a claim
#         about this artifact and is not measurable here.
#       * the matrix's shape. `manifest/enforcement.tsv` is the source: total rows, scope split,
#         and the per-`enforced_by` counts. The live claim is the sentence that says
#         `Measured shape of this table:` plus the advisory section that names the count. Everything
#         else in `docs/ENFORCEMENT.md` that contains the word `advisory` and a number is DATED
#         HISTORY (`advisory 9 of ceiling 10`, measured at a named revision, kept on purpose by the
#         stale-sentence rule) and is NOT matched - the same live-vs-history split
#         `tests/t-doc-sync.sh`'s AB3 section makes for the same file.
#
#     RED case (B2, measured on the un-fixed tree): `docs/FLOWS.md:127` read
#     `this ships 12 (plus the two automations below)` while the same file's line 1, its own
#     catalogue P1..P14, `manifest/playbooks.tsv` (14 rows), `README.md:29`,
#     `docs/GUIDE.md` and `docs/LIMITS.md:18` ("Fourteen playbooks against twenty-three") all say
#     14 - left behind by `5e574f2`, the very commit that moved the count. It also caught a site the
#     wave that found B2 did not list: `manifest/glossary.tsv`'s `playbook` definition said
#     `goblin-stack ships 12.`
#
# Run by tests/run-tests.sh. Outside the census by construction: the census parses the `expect_*`
# call sites of `tests/t-verify-red.sh`, and this file adds none.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
HOMEDIR="$WORK/home"
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

# ===============================================================================================
# The installation the path half is measured against: a real class-A install, the guide's own
# command. The reader's $HOME must not matter (throwaway HOME, as tests/t-doc-guide.sh does).
# ===============================================================================================
mkdir -p "$WORK/target" "$HOMEDIR"
cd "$WORK/target"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
INSTALLED=$(HOME="$HOMEDIR" bash "$SRC/bin/goblin-install" --target . --class A 2>&1)
check "the class-A install the path promises are resolved against exits 0" \
  "$([ -f .goblin/installed.json ] && echo 0 || echo 1)"
[ -d .goblin/bin ] || note "  (no .goblin/bin in the install: $(printf '%s' "$INSTALLED" | head -1))"

DOCS=$(ls "$SRC/README.md" "$SRC"/docs/*.md)

# ===============================================================================================
# (a) command paths: enumerate from the docs, resolve against the install / the checkout
# ===============================================================================================
GOBLIN_BIN=$(grep -rhoE '\.goblin/bin/[A-Za-z0-9_.-]+' $DOCS | sort -u)
# The checkout-rooted form must be taken from text with the `.goblin/bin/...` occurrences removed
# first, or every `.goblin/bin/x` would also yield a spurious `bin/x`.
BARE_BIN=$(grep -rhE '' $DOCS | sed -E 's|\.goblin/bin/[A-Za-z0-9_.-]+| |g' \
           | grep -ohE '(^|[^A-Za-z0-9_./-])bin/[A-Za-z0-9_.-]+' | sed 's/^[^b]*//' | sort -u)

# site_of <token> — the first `file:line` in the docs that prints it, so a FAIL names where the
# reader meets the promise and not only the token.
site_of() {
  grep -rnE "(^|[^A-Za-z0-9_./-])$1([^A-Za-z0-9_.-]|$)" $DOCS 2>/dev/null | head -1 | sed "s|$SRC/||; s|:.*:.*||"
}
site_line() {
  grep -rnE "(^|[^A-Za-z0-9_./-])$1([^A-Za-z0-9_.-]|$)" $DOCS 2>/dev/null | head -1 | cut -d: -f2
}

for p in $GOBLIN_BIN; do
  if [ -e "$p" ]; then
    note "ok   the docs hand the reader '$p' and a real class-A install ships it"
  else
    note "FAIL $(site_of "$p"):$(site_line "$p") hands the reader '$p' - a real class-A install does NOT ship it"
    fail=1
  fi
done
for p in $BARE_BIN; do
  check "the docs hand the reader '$p' and this checkout ships it" \
    "$([ -e "$SRC/$p" ] && echo 0 || echo 1)"
done

# ===============================================================================================
# (a2) the guide's own data paths: a bare `manifest/<file>` in the reader's front door
# ===============================================================================================
GUIDE_BARE_MANIFEST=$(grep -ohE '(^|[^A-Za-z0-9_./-])manifest/[A-Za-z0-9_.-]+' "$SRC/docs/GUIDE.md" \
                      | sed 's/^[^m]*//' | sort -u)
if [ -z "$GUIDE_BARE_MANIFEST" ]; then
  note "ok   docs/GUIDE.md names every manifest path as the reader has it (.goblin/manifest/...)"
else
  note "FAIL docs/GUIDE.md names an installed table by the CHECKOUT's path, not the reader's:"
  printf '        %s\n' $GUIDE_BARE_MANIFEST
  fail=1
fi

# ===============================================================================================
# (b) self-counts
# ===============================================================================================
PB_SRC="$SRC/manifest/playbooks.tsv"
ENF_SRC="$SRC/manifest/enforcement.tsv"
PLAYBOOKS=$(awk -F'\t' 'NR>1 && NF>1 {n++} END{print n+0}' "$PB_SRC")

# The documents walked for a count claim: every doc, plus the shipped glossary, which defines
# "playbook" for a reader and carried the same stale number as the flow catalogue.
COUNT_DOCS=$(ls "$SRC/README.md" "$SRC"/docs/*.md "$SRC"/manifest/glossary.tsv)

# ---- (b1) the playbook count -------------------------------------------------------------------
BAD_PB=""
for f in $COUNT_DOCS; do
  while IFS=: read -r ln token; do
    [ -z "${token:-}" ] && continue
    n=$(printf '%s' "$token" | grep -oE '^[0-9]+')
    [ "$n" = "$PLAYBOOKS" ] || BAD_PB="$BAD_PB ${f#"$SRC"/}:$ln=$n"
  done < <(grep -noE '[0-9]+ playbooks?' "$f")
done
check "every stated playbook count equals manifest/playbooks.tsv ($PLAYBOOKS data rows)" \
  "$([ -z "$BAD_PB" ] && echo 0 || echo 1)"
[ -z "$BAD_PB" ] || note "  disagrees:$BAD_PB"

# ---- (b2) the artifact's own subject line, `this ships N` / `goblin-stack ships N` ---------------
BAD_SHIP=""
for f in $COUNT_DOCS; do
  while IFS=: read -r ln token; do
    [ -z "${token:-}" ] && continue
    n=$(printf '%s' "$token" | grep -oE '[0-9]+$')
    [ "$n" = "$PLAYBOOKS" ] || BAD_SHIP="$BAD_SHIP ${f#"$SRC"/}:$ln=$n"
  done < <(grep -noE '(this|goblin-stack) ships [0-9]+' "$f")
done
check "every 'this ships N' / 'goblin-stack ships N' equals the playbook count ($PLAYBOOKS)" \
  "$([ -z "$BAD_SHIP" ] && echo 0 || echo 1)"
[ -z "$BAD_SHIP" ] || note "  disagrees:$BAD_SHIP  (pstack is the predecessor project; its count is not this artifact's and is not read here)"

# ---- (b3) the matrix's shape ------------------------------------------------------------------
ENF="$SRC/docs/ENFORCEMENT.md"
m_total=$(awk -F'\t' 'NR>1 && NF>1 {n++} END{print n+0}' "$ENF_SRC")
m_target=$(awk -F'\t' 'NR>1 && $2=="target" {n++} END{print n+0}' "$ENF_SRC")
m_source=$(awk -F'\t' 'NR>1 && $2=="source" {n++} END{print n+0}' "$ENF_SRC")
m_adv=$(awk -F'\t' 'NR>1 && $4=="advisory" {n++} END{print n+0}' "$ENF_SRC")
m_litadv=$(awk -F'\t' 'NR>1 && $4=="advisory" && $6=="advisory" {n++} END{print n+0}' "$ENF_SRC")

# The live claim: the sentence that states the table's measured shape, and nothing else in the
# file (the `advisory 9 of ceiling 10` lines around it are dated history and are not read).
SHAPE=$(grep -m1 'Measured shape of this table' "$ENF")
c_total=$(printf '%s' "$SHAPE" | grep -oE '[0-9]+ rows' | head -1 | awk '{print $1}')
c_target=$(printf '%s' "$SHAPE" | grep -oE '[0-9]+ target' | head -1 | awk '{print $1}')
c_source=$(printf '%s' "$SHAPE" | grep -oE '[0-9]+ source' | head -1 | awk '{print $1}')
check "docs/ENFORCEMENT.md states the matrix's total row count (doc ${c_total:-none} vs table $m_total)" \
  "$([ -n "$c_total" ] && [ "$c_total" = "$m_total" ] && echo 0 || echo 1)"
check "  and its scope split (target ${c_target:-none}/$m_target, source ${c_source:-none}/$m_source)" \
  "$([ -n "$c_target" ] && [ -n "$c_source" ] && [ "$c_target" = "$m_target" ] && [ "$c_source" = "$m_source" ] && echo 0 || echo 1)"
for k in advisory gate lint script test; do
  doc_n=$(printf '%s' "$SHAPE" | grep -oE "$k [0-9]+" | head -1 | awk '{print $2}')
  tbl_n=$(awk -F'\t' -v k="$k" 'NR>1 && $4==k {n++} END{print n+0}' "$ENF_SRC")
  check "  and the $k count (doc ${doc_n:-none} vs table $tbl_n)" \
    "$([ -n "$doc_n" ] && [ "$doc_n" = "$tbl_n" ] && echo 0 || echo 1)"
done

# The advisory section, which names the count a second time in prose.
ADVBLOCK=$(awk '/rows are labelled/{c=2} c>0{print;c--}' "$ENF")
a_first=$(printf '%s' "$ADVBLOCK" | grep -oE '[0-9]+ of the [0-9]+ rows' | head -1 | awk '{print $1}')
a_second=$(printf '%s' "$ADVBLOCK" | grep -oE '[0-9]+ of the [0-9]+ rows' | head -1 | awk '{print $4}')
a_lit=$(printf '%s' "$ADVBLOCK" | grep -oE '[0-9]+ of them carry no executable check' | head -1 | awk '{print $1}')
check "docs/ENFORCEMENT.md's advisory section states the advisory row count (doc ${a_first:-none} vs table $m_adv)" \
  "$([ -n "$a_first" ] && [ "$a_first" = "$m_adv" ] && echo 0 || echo 1)"
check "  and states it against a row count that is the table's (doc ${a_second:-none} vs target $m_target / total $m_total)" \
  "$([ -n "$a_second" ] && { [ "$a_second" = "$m_target" ] || [ "$a_second" = "$m_total" ]; } && echo 0 || echo 1)"
check "  and the 'carry no executable check' count equals the table's literal-advisory rows (doc ${a_lit:-none} vs table $m_litadv)" \
  "$([ -n "$a_lit" ] && [ "$a_lit" = "$m_litadv" ] && echo 0 || echo 1)"

if [ "$fail" -eq 0 ]; then note "t-doc-promises: PASS"; else note "t-doc-promises: FAIL"; fi
exit "$fail"
