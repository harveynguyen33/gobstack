#!/usr/bin/env bash
# t-doc-promises.sh — the promises the shipped documents make about THIS artifact, walked out of
# the documents themselves instead of listed in this file.
#
# THE SPECIES THIS FILE EXISTS TO CLOSE. Twelve verification waves found the same defect: a claim
# the artifact makes about itself that NOTHING reads. Each wave fixed the instance. This file is a
# control over the CLASS, so a successor is caught by the same code that caught its predecessor:
# it ENUMERATES its subjects from the artifact and resolves each one against a measurement of the
# artifact itself.
#
# WHAT IT WALKS (AB6). Two sets, union, neither of them hand-typed, and the walk prints its
# coverage - a green run that says nothing about what it did NOT read is the other half of the
# species:
#   * THE DOCUMENTS THE INSTALLER WRITES INTO A READER'S REPO. The write set is read from the
#     record `goblin-install` itself writes - `.gob/installed.json`, its `files` and `owned`
#     maps - and cross-checked against what is on disk in the class-A install this test makes.
#     Every `.md` in it is walked; the shipped glossary is walked for the count family. Add a
#     markdown document to the installer and it joins this walk with no edit here. A file the
#     record names that is not on disk, or a `.md` on disk the record does not name, is a FAIL
#     that names it: a file the installer writes that the walk cannot classify is not a skip.
#   * the checkout's own reader-facing docs, `README.md` and `docs/*.md`.
#
# ---------------------------------------------------------------------------------------------
# (a) A COMMAND PATH THE DOCS HAND A READER
#
#     The extractor walks every document above and takes every token whose DIRECTORY is a
#     COMMAND directory:
#         `.gob/bin/<name>`  -> must exist in a real class-A install this test makes itself
#         `bin/<name>`          -> must exist in this checkout
#     Both directories hold commands by construction, so no hand-list of shootable names is
#     involved: whatever the docs print, this test resolves.
#
#     RED case (B1, measured on the un-fixed tree): `docs/GUIDE.md` told the reader to run a
#     `.gob/bin/` path no install ships - a real class-A `.gob/bin/` holds exactly `goblin-bans`,
#     `goblin-lib.sh`, `goblin-verify`. Running the guide's own line in a fresh class-A install
#     exits 127. A front door that hands a new reader a command that cannot work.
#
#     DELIBERATELY NOT MATCHED, and why - read this before widening the extractor:
#       * a bare command name with no directory (`goblin-verify`, `goblin-install`). It resolves on
#         PATH or as `.gob/bin/<name>`, and the docs use all three forms; the promise being
#         checked is about a PATH, and a bare name makes no path claim.
#       * a `.gob/`-rooted path that is not a command. `.gob/loop/...` is the loop's own
#         committed record, and `.gob/last-gate-line` is written by a RUN (`GT-02`'s gate
#         line). The docs promise that a run produces
#         them, never that an install ships them, so "must exist right after install" is the wrong
#         assertion. `.gob/manifest/*.tsv` is an installed DATA table, not a command: the
#         business half below and `tests/t-doc-sync.sh`'s cell comparison cover it.
#       * a path inside a fenced transcript that the reader is told to CREATE (`reports/<slug>/`,
#         `reviews/<slug>-<head7>.md`, `evals/<slug>/`). Those are outputs of the reader's own
#         work, not promises about the artifact.
#
# (a0) THE TOKENISER'S WRAP RULE (AB6 C2) - a promise a soft wrap split across two physical lines
#     is REJOINED before it is read, so it is asserted like any other instead of being lost. This
#     file used to be line-oriented: `.gob/bin/` at the end of a line with the name on the next
#     reported a PASS, which is a false green. Two forms are rejoined:
#       * a command directory that ENDS a line (`.gob/bin/`, `bin/`) takes the next line's
#         leading token with NO separator, so `... .gob/bin/` + `goblin-bans` reads as
#         `.gob/bin/goblin-bans` and is then asserted like any other path.
#       * a count phrase whose NUMBER ends a line (`this ships 13`) takes the next line's leading
#         token WITH a space, so `This ships 13` + `playbooks today.` reads as one sentence.
#     A logical line that ends on a command directory WITH its trailing slash (`.gob/bin/`,
#     `bin/`) and that the join could not repair is a FAIL, never a quiet pass. That is the
#     sensitivity the count family already had (`doc none` is a FAIL) applied to paths, and both
#     are stated in this header. The slash is load-bearing: the SAME directory written without it
#     is not that promise at all - it is the unread form named under STILL NOT REJOINED, where no
#     fragment is a token.
#
#     STILL NOT REJOINED, named here rather than implied away:
#       * a path broken BETWEEN its own directories (`.gob/` + `bin/x`) or in the MIDDLE of a
#         name (`.gob/bin/gob` + `lin-bans`). One fragment still carries a NAME, so it is
#         asserted as an ordinary token and a fragment that is not a shipped command still FAILs -
#         `bin/x` is read as a checkout path, `.gob/bin/gob` as an installed one. A break that
#         leaves both fragments resolvable is not seen as one path. Neither the checkout nor any
#         class-A install prints such a break today.
#       * a path broken AT its own directory/name boundary - a line that ends on the command
#         directory WITHOUT its trailing slash (`.gob/bin`, `bin`) with the slash leading the
#         next line (`/x`) or dropped (`x`). This one is NOT rejoined and NOT asserted: the first
#         fragment stops at the directory, with no NAME for the grammar to read, and the second is
#         not preceded by `bin/`, so NEITHER is a token, both are dropped, and a false path in that
#         form PASSes rc 0 with no mention of it. Nothing path-like after the break is no better:
#         the line is not dangling either, because `dangling()` needs the trailing slash too, so a
#         line ending on the bare directory is silent with or without a continuation. Measured
#         (AB7): 0 such lines in this tree, and a plant of that form in `docs/CI.md` PASSes rc 0,
#         plant unmentioned.
#       * a bare command name with no directory, and a `.gob/`-rooted non-command path, as
#         above. Wrap tolerance changes how a claim is READ, never which claims are in scope.
#
# (a2) The same walk gives the guide's own half, because the guide is the one document written FOR
#     the reader's repo: a `manifest/<file>` token in `docs/GUIDE.md` names a file of THIS
#     checkout, which is not where the reader's copy lives (the guide's own section 1 writes
#     `.gob/manifest/enforcement.tsv`). The rule is scoped to the guide because the other
#     documents address this checkout as well as the reader's repo - measured: `docs/GUIDE.md`
#     and `docs/LIMITS.md` each name `manifest/bans.tsv` in a sentence about the source table - so
#     the same assertion there would be false. RED case (B3): `docs/GUIDE.md:517` wrote
#     `manifest/bans.tsv` in a section 13 instruction addressed to the reader.
#
# ---------------------------------------------------------------------------------------------
# (b) A SELF-COUNT A DOC STATES ABOUT THE ARTIFACT
#
#     Two source tables, three families of claim, all walked from the documents:
#       * the playbook count. `manifest/playbooks.tsv` is the source (its data rows). Every
#         `<N> playbook(s)` claim and every `<the artifact> ships <N>` claim must equal it. The
#         second pattern is anchored on a subject - `this` or `gobstack` - because the same
#         heading compares against the PREDECESSOR project, and `pstack ships 23` is not a claim
#         about this artifact and is not measurable here.
#       * the matrix's shape. `manifest/enforcement.tsv` is the source: total rows, scope split,
#         and the per-`enforced_by` counts. The live claim is the sentence that says
#         `Measured shape of this table:` plus the advisory section that names the count. Everything
#         else in `docs/GUIDE.md` that contains the word `advisory` and a number is DATED
#         HISTORY (`advisory 9 of ceiling 10`, measured at a named revision, kept on purpose by the
#         stale-sentence rule) and is NOT matched - the same live-vs-history split
#         `tests/t-doc-sync.sh`'s AB3 section makes for the same file.
#       * the census sentence (AB6 C3). `README.md` states the negative control's census as
#         `<N> over <M> target rows`. `N` is read from the `expect_red` + `expect_green` call sites
#         of `tests/t-verify-red.sh` and `M` from the matrix's target rows that actually carry one,
#         with the ids themselves checked: a phantom id, or a target row with no control, is a
#         FAIL. The sentence was true and read by nothing - the last live instance of the species.
#
#     RED case (B2, measured on the un-fixed tree): `docs/GUIDE.md:127` read
#     `this ships 12 (plus the two automations below)` while the same file's line 1, its own
#     catalogue P1..P14, `manifest/playbooks.tsv` (14 rows), `README.md:29`,
#     `docs/GUIDE.md` and `docs/LIMITS.md:18` ("Fourteen playbooks against twenty-three") all say
#     14 - left behind by `5e574f2`, the very commit that moved the count. It also caught a site the
#     wave that found B2 did not list: `manifest/glossary.tsv`'s `playbook` definition said
#     `gobstack ships 12.`
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
# The installation every path promise is resolved against: a real class-A install, the guide's own
# command. The reader's $HOME must not matter (throwaway HOME, as tests/t-doc-guide.sh does).
# ===============================================================================================
mkdir -p "$WORK/target" "$HOMEDIR"
cd "$WORK/target"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
INSTALLED=$(HOME="$HOMEDIR" bash "$SRC/bin/goblin-install" --target . --class A 2>&1)
check "the class-A install the path promises are resolved against exits 0" \
  "$([ -f .gob/installed.json ] && echo 0 || echo 1)"
[ -d .gob/bin ] || note "  (no .gob/bin in the install: $(printf '%s' "$INSTALLED" | head -1))"

# ===============================================================================================
# THE SUBJECT SET (C1). Derived twice from two independent sources and required to agree: what the
# installer RECORDED it wrote, and what is actually ON DISK in the fresh install. Nothing here is
# typed, so adding a document to the installer adds it to the walk.
# ===============================================================================================
# shellcheck source=goblin-lib.sh
. "$SRC/bin/goblin-lib.sh"
INSTALL_JSON="$WORK/target/.gob/installed.json"
RECORD_MD=$( { g_installed_files "$INSTALL_JSON" | cut -f1
               g_json_object "$INSTALL_JSON" owned | cut -f1
             } | grep -E '\.md$' | sort -u )
ON_DISK_MD=$( cd "$WORK/target" && find . -type f -name '*.md' | sed 's|^\./||' | sort )

DRIFT=$(diff <(printf '%s' "$RECORD_MD") <(printf '%s' "$ON_DISK_MD") 2>/dev/null)
check "the installer's record and the install on disk name the same markdown write set (C1)" \
  "$([ -z "$DRIFT" ] && echo 0 || echo 1)"
if [ -n "$DRIFT" ]; then
  note "  the walk cannot classify this drift between the record and the install:"
  printf '%s\n' "$DRIFT" | sed 's/^/        /'
fi
check "the installer writes at least one markdown document into the reader's repo (C1)" \
  "$([ -n "$RECORD_MD" ] && echo 0 || echo 1)"

WALK_LABEL=( "README.md" )
WALK_PATH=( "$SRC/README.md" )
for f in "$SRC"/docs/*.md; do
  WALK_LABEL+=( "docs/$(basename "$f")" )
  WALK_PATH+=( "$f" )
done
N_CHECKOUT=${#WALK_PATH[@]}
while IFS= read -r p; do
  [ -n "$p" ] || continue
  WALK_LABEL+=( "$p" )
  WALK_PATH+=( "$WORK/target/$p" )
done <<< "$RECORD_MD"
N_INSTALLED=$(( ${#WALK_PATH[@]} - N_CHECKOUT ))

# The count family also reads the glossary - the definition of "playbook" a reader is handed - in
# both copies: the checkout's and the one the installer writes.
SCAN_LABEL=( "${WALK_LABEL[@]}" "manifest/glossary.tsv" ".gob/manifest/glossary.tsv" )
SCAN_PATH=( "${WALK_PATH[@]}" "$SRC/manifest/glossary.tsv" "$WORK/target/.gob/manifest/glossary.tsv" )

MISSING=""
for i in "${!SCAN_PATH[@]}"; do
  [ -r "${SCAN_PATH[$i]}" ] || MISSING="$MISSING ${SCAN_LABEL[$i]}"
done
check "every document the walk names is readable (C1)" "$([ -z "$MISSING" ] && echo 0 || echo 1)"
[ -z "$MISSING" ] || note "  unreadable:$MISSING"

# The coverage statement AC5 asked for: a green run says what it read, so what it did NOT read is
# a visible absence rather than an invisible one.
note "coverage: ${#WALK_PATH[@]} documents walked - $N_CHECKOUT checkout doc(s) + $N_INSTALLED the installer writes into the reader's repo"
note "          installer-written: $(printf '%s ' "${WALK_LABEL[@]:$N_CHECKOUT}")"
note "          plus 2 glossary tables for the count family (checkout + installed)"

# ===============================================================================================
# The tokeniser: one logical line per claim, soft wraps rejoined (see (a0) in the header), and the
# tokens read out of it in the same pass - one process per document, or the per-line greps cost
# more than the install they check.
# ===============================================================================================
SCAN_AWK=$(cat <<'SCAN'
function tail(s,  t) { t = s; gsub(/[[:space:]]+$/, "", t); return t }
function cmdpref(s,  t) {
  t = tail(s)
  return (t ~ "(^|[^A-Za-z0-9_./-])[.]goblin/bin/$" || t ~ "(^|[^A-Za-z0-9_./-])bin/$")
}
function counttail(s, i,  t, nx) {
  t = tail(s)
  if (t ~ "(this|gobstack) ships [0-9]+$") return 1
  if (t ~ "[0-9]+$") {
    nx = L[i + 1]; sub(/^[[:space:]]+/, "", nx)
    if (nx ~ "^playbooks?([^A-Za-z0-9_]|$)") return 1
  }
  return 0
}
function dangling(s,  t) {
  t = s
  gsub(/[[:space:]`"']+$/, "", t)
  return (t ~ "(^|[^A-Za-z0-9_./-])[.]goblin/bin/$" || t ~ "(^|[^A-Za-z0-9_./-])bin/$")
}
function scan(text, ln,  s, m, tok) {
  s = text
  while (match(s, "[.]goblin/bin/[A-Za-z0-9_.-]+")) {
    printf "%s\t%d\tTOK\t%s\n", path, ln, substr(s, RSTART, RLENGTH)
    s = substr(s, RSTART + RLENGTH)
  }
  s = text
  gsub(/[.]goblin\/bin\/[A-Za-z0-9_.-]+/, " ", s)
  while (match(s, "(^|[^A-Za-z0-9_./-])bin/[A-Za-z0-9_.-]+")) {
    m = substr(s, RSTART, RLENGTH); tok = m; sub(/^[^b]*/, "", tok)
    printf "%s\t%d\tTOK\t%s\n", path, ln, tok
    s = substr(s, RSTART + RLENGTH)
  }
  s = text
  while (match(s, "[0-9]+ playbooks?")) {
    printf "%s\t%d\tPB\t%s\n", path, ln, substr(s, RSTART, RLENGTH)
    s = substr(s, RSTART + RLENGTH)
  }
  s = text
  while (match(s, "(this|gobstack) ships [0-9]+")) {
    printf "%s\t%d\tSHIP\t%s\n", path, ln, substr(s, RSTART, RLENGTH)
    s = substr(s, RSTART + RLENGTH)
  }
}
{ L[FNR] = $0 }
END {
  n = FNR
  i = 1
  while (i <= n) {
    start = i
    text = L[i]
    while (i < n) {
      if (cmdpref(text))          sep = ""
      else if (counttail(text, i)) sep = " "
      else break
      i++
      nx = L[i]; sub(/^[[:space:]]+/, "", nx)
      text = text sep nx
    }
    if (dangling(text)) printf "%s\t%d\tDANGLE\t%s\n", path, start, tail(text)
    scan(text, start)
    i++
  }
}
SCAN
)

RECORDS=$(for idx in "${!SCAN_PATH[@]}"; do
            awk -v path="${SCAN_LABEL[$idx]}" "$SCAN_AWK" "${SCAN_PATH[$idx]}"
          done)

DANGLE=$(printf '%s\n' "$RECORDS" | awk -F'\t' '$3=="DANGLE" { printf "%s:%s ", $1, $2 }')
TOKENS=$(printf '%s\n' "$RECORDS" | awk -F'\t' '$3=="TOK" { print $4"|"$1"|"$2 }' \
         | awk -F'|' '!seen[$1]++')

# ===============================================================================================
# (a) command paths: each distinct token resolved against the install / the checkout
# ===============================================================================================
for rec in $TOKENS; do
  tok=${rec%%|*}; rest=${rec#*|}; label=${rest%%|*}; ln=${rest##*|}
  case "$tok" in
    .gob/bin/*)
      if [ -e "$tok" ]; then
        note "ok   $label:$ln hands the reader '$tok' and a real class-A install ships it"
      else
        note "FAIL $label:$ln hands the reader '$tok' - a real class-A install does NOT ship it"
        fail=1
      fi ;;
    bin/*)
      if [ -e "$SRC/$tok" ]; then
        note "ok   $label:$ln hands the reader '$tok' and this checkout ships it"
      else
        note "FAIL $label:$ln hands the reader '$tok' - this checkout does NOT ship it"
        fail=1
      fi ;;
  esac
done
check "the walk hands the reader at least one command path at all (C1 - an empty walk is a FAIL)" \
  "$([ -n "$TOKENS" ] && echo 0 || echo 1)"
check "no walked document leaves a command directory dangling - an unreadable path is a FAIL (C2)" \
  "$([ -z "$DANGLE" ] && echo 0 || echo 1)"
[ -z "$DANGLE" ] || note "  a path whose name the tokeniser could not read:$DANGLE"

# ===============================================================================================
# (a2) the guide's own data paths: a bare `manifest/<file>` in the reader's front door
# ===============================================================================================
GUIDE_BARE_MANIFEST=$(grep -ohE '(^|[^A-Za-z0-9_./-])manifest/[A-Za-z0-9_.-]+' "$SRC/docs/GUIDE.md" \
                      | sed 's/^[^m]*//' | sort -u)
if [ -z "$GUIDE_BARE_MANIFEST" ]; then
  note "ok   docs/GUIDE.md names every manifest path as the reader has it (.gob/manifest/...)"
else
  note "FAIL docs/GUIDE.md names an installed table by the CHECKOUT's path, not the reader's:"
  printf '        %s\n' $GUIDE_BARE_MANIFEST
  fail=1
fi

# ===============================================================================================
# (b) self-counts. (b0) the playbook count, (b2) the artifact's own subject line - both walked
# from the documents above - and (b3) the matrix's shape, which lives in prose.
# ===============================================================================================
PB_SRC="$SRC/manifest/playbooks.tsv"
ENF_SRC="$SRC/manifest/enforcement.tsv"
PLAYBOOKS=$(awk -F'\t' 'NR>1 && NF>1 {n++} END{print n+0}' "$PB_SRC")

BAD_PB=$(printf '%s\n' "$RECORDS" \
         | awk -F'\t' -v want="$PLAYBOOKS" '$3=="PB" { split($4, a, " "); if (a[1] != want) printf " %s:%s=%s", $1, $2, a[1] }')
BAD_SHIP=$(printf '%s\n' "$RECORDS" \
         | awk -F'\t' -v want="$PLAYBOOKS" '$3=="SHIP" { split($4, a, " "); if (a[3] != want) printf " %s:%s=%s", $1, $2, a[3] }')
check "every stated playbook count equals manifest/playbooks.tsv ($PLAYBOOKS data rows)" \
  "$([ -z "$BAD_PB" ] && echo 0 || echo 1)"
[ -z "$BAD_PB" ] || note "  disagrees:$BAD_PB"
check "every 'this ships N' / 'gobstack ships N' equals the playbook count ($PLAYBOOKS)" \
  "$([ -z "$BAD_SHIP" ] && echo 0 || echo 1)"
[ -z "$BAD_SHIP" ] || note "  disagrees:$BAD_SHIP  (pstack is the predecessor project; its count is not this artifact's and is not read here)"

# ---- (b3) the matrix's shape ------------------------------------------------------------------
ENF="$SRC/docs/GUIDE.md"
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
check "docs/GUIDE.md states the matrix's total row count (doc ${c_total:-none} vs table $m_total)" \
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
check "docs/GUIDE.md's advisory section states the advisory row count (doc ${a_first:-none} vs table $m_adv)" \
  "$([ -n "$a_first" ] && [ "$a_first" = "$m_adv" ] && echo 0 || echo 1)"
check "  and states it against a row count that is the table's (doc ${a_second:-none} vs target $m_target / total $m_total)" \
  "$([ -n "$a_second" ] && { [ "$a_second" = "$m_target" ] || [ "$a_second" = "$m_total" ]; } && echo 0 || echo 1)"
check "  and the 'carry no executable check' count equals the table's literal-advisory rows (doc ${a_lit:-none} vs table $m_litadv)" \
  "$([ -n "$a_lit" ] && [ "$a_lit" = "$m_litadv" ] && echo 0 || echo 1)"

# ---- (b4) the census sentence in README.md (AB6 C3) -------------------------------------------
# `<N> over <M> target rows`: N is the number of controls the negative control carries, M the
# number of the matrix's target rows that carry one. Both are read, never typed.
VERIFY_SH="$SRC/tests/t-verify-red.sh"
c_sites=$(grep -vE '^[[:space:]]*#' "$VERIFY_SH" \
          | grep -oE '\bexpect_(red|green)[[:space:]]+"[^"]*"[[:space:]]+[A-Z]{2,3}-[0-9]{2}')
c_red=$(printf '%s\n' "$c_sites" | grep -c expect_red)
c_green=$(printf '%s\n' "$c_sites" | grep -c expect_green)
c_calls=$(( c_red + c_green ))
c_ids=$(printf '%s\n' "$c_sites" | grep -oE '[A-Z]{2,3}-[0-9]{2}$' | sort -u)
c_nids=$(printf '%s\n' "$c_ids" | grep -c .)
c_phantom=$(comm -23 <(printf '%s\n' "$c_ids") \
              <(awk -F'\t' 'NR>1 && NF>1 {print $1}' "$ENF_SRC" | grep -oE '[A-Z]{2,3}-[0-9]{2}' | sort -u) \
            | tr -d '[:space:]')
c_nocontrol=$(comm -13 <(printf '%s\n' "$c_ids") \
              <(awk -F'\t' 'NR>1 && $2=="target" {print $1}' "$ENF_SRC" | grep -oE '[A-Z]{2,3}-[0-9]{2}' | sort -u) \
              | tr -d '[:space:]')
# v3: the CI lane is out of the product and its rows (PG-04/PG-05/PG-06) are cut, so there is
# nothing to exclude — the census reads the matrix as it now stands.
C_EXCLUDE=""

c_line=$(grep -m1 -nE '[0-9]+ over [0-9]+ target rows' "$SRC/README.md")
c_where=${c_line%%:*}
c_text=${c_line#*:}
c_doc_calls=$(printf '%s' "$c_text" | grep -oE '[0-9]+ over' | grep -oE '[0-9]+')
c_doc_rows=$(printf '%s' "$c_text" | grep -oE 'over [0-9]+' | grep -oE '[0-9]+')
check "README.md:$c_where states the census count its own sources give (doc ${c_doc_calls:-none} vs $c_calls = $c_red expect_red + $c_green expect_green)" \
  "$([ -n "$c_doc_calls" ] && [ "$c_doc_calls" = "$c_calls" ] && echo 0 || echo 1)"
check "  and states it over the matrix's target rows that carry a control (doc ${c_doc_rows:-none} vs $c_nids distinct control ids)" \
  "$([ -n "$c_doc_rows" ] && [ "$c_doc_rows" = "$c_nids" ] && echo 0 || echo 1)"
check "  and every id the control uses is a matrix row (phantom: '${c_phantom:-0}')" \
  "$([ -z "$c_phantom" ] && echo 0 || echo 1)"
c_uncovered=""
for id in $(printf '%s' "$c_nocontrol" | sed 's/\([A-Z][A-Z0-9]-[0-9][0-9]\)/\1 /g'); do
  case " $C_EXCLUDE " in *" $id "*) continue ;; esac
  c_uncovered="$c_uncovered$id"
done
check "  and every target row in the matrix carries one (uncovered, exc. the v2 CI cut: '${c_uncovered:-0}')" \
  "$([ -z "$c_uncovered" ] && echo 0 || echo 1)"

if [ "$fail" -eq 0 ]; then note "t-doc-promises: PASS"; else note "t-doc-promises: FAIL"; fi
exit "$fail"
