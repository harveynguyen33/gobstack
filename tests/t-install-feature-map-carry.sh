#!/usr/bin/env bash
# t-install-feature-map-carry.sh — a re-install must never ERASE a declaration.
#
# `render_config` (bin/goblin-install) re-renders the gob:block from
# templates/agents-block.tmpl on EVERY install, and for a set of keys it draws the value from a
# HARDCODED LITERAL (`FEATURE_MAP ""`, `VERIFY_DOCTOR ""`, `REFERENCE_MANIFEST ""`,
# `QUARANTINE_ROOT ""`, `SOURCE_ROOT "."`, `MAX_DIRTY "0"`, `BANS_EXEMPT ""` — CARRY_KEYS in
# the installer is that whole enumeration). g_agents_write then replaces the block wholesale, so
# a PLAIN re-install wrote the literal over the project's answer and every gate reading such a
# key fell back to SKIP: a re-install switched a check off by deleting its subject. This file
# covers the feature_map case end to end, then each of the other keys, then the two honest
# edges — a fresh install keeps today's defaults, a blanked value stays blank — and finally the
# negative control (the same tree with the carry switched off, measured 4 in -> 0 out).
#
# The carry reads the previous block through the round-trip reader (g_agents_pairs), so a value
# containing ": " or a raw tab survives intact.
# House fixture: tests/t-install-idempotent.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

# ---- a fixture ---------------------------------------------------------------
mkdir -p "$WORK/target"
printf 'the referenced standard\n' > "$WORK/standard.md"
cd "$WORK/target"
git init -q -b main
git config user.name "Test Runner"
git config user.email "runner@example.com"
printf '# target\n' > README.md
git add -A && git commit -q -m "chore: seed"

INSTALL="bash $SRC/bin/goblin-install --target $WORK/target --practice $WORK/standard.md"

OUT=$($INSTALL 2>&1); RC=$?
check "first install exits 0" "$RC"
check "a fresh install still ships an EMPTY feature_map (the honest day-one state)" \
  "$(grep -qx 'feature_map:' AGENTS.md && echo 0 || echo 1)"

# ---- the project declares its map, then re-installs ---------------------------
sed -i 's|^feature_map:.*$|feature_map: features/README.md|' AGENTS.md
check "the declaration is planted in the block" \
  "$(grep -qxF 'feature_map: features/README.md' AGENTS.md && echo 0 || echo 1)"
SNAP=$(sha256sum AGENTS.md | awk '{print $1}')

OUT2=$($INSTALL 2>&1); RC2=$?
check "the re-install exits 0" "$RC2"
check "a plain re-install KEEPS the declared feature_map (FM-01/02 do not self-disable)" \
  "$(grep -qxF 'feature_map: features/README.md' AGENTS.md && echo 0 || echo 1)"
check "the re-installed AGENTS.md is byte-identical to the planted one" \
  "$([ "$(sha256sum AGENTS.md | awk '{print $1}')" = "$SNAP" ] && echo 0 || echo 1)"
check "the key appears exactly once (the carry replaces, never appends a duplicate)" \
  "$([ "$(grep -c '^feature_map:' AGENTS.md)" -eq 1 ] && echo 0 || echo 1)"

# ---- stable over a third install (no drift, no duplication) -------------------
OUT3=$($INSTALL 2>&1); RC3=$?
check "a third install exits 0" "$RC3"
check "the value survives a third install and the block is still byte-identical" \
  "$([ "$(sha256sum AGENTS.md | awk '{print $1}')" = "$SNAP" ] && echo 0 || echo 1)"

# ---- the round-trip reader: ": " and a raw tab inside the value survive --------
# A sed-based substitution straight into the block would keep these too, but a keys+read
# loop through g_agents_read rebuilds the value and loses a tab's place; the carry reads
# through g_agents_pairs (bin/goblin-lib.sh) for exactly this reason.
ODD="features/a : b$(printf '\t')c.md"
sed -i "s|^feature_map:.*\$|feature_map: $ODD|" AGENTS.md
check "an awkward value (' : ' and a raw tab) is planted" \
  "$(grep -qxF "feature_map: $ODD" AGENTS.md && echo 0 || echo 1)"
ODD_SNAP=$(sha256sum AGENTS.md | awk '{print $1}')
$INSTALL >/dev/null 2>&1
check "the awkward value survives the re-install verbatim" \
  "$(grep -qxF "feature_map: $ODD" AGENTS.md && echo 0 || echo 1)"
check "the awkward value's block is byte-identical (no tab mangling)" \
  "$([ "$(sha256sum AGENTS.md | awk '{print $1}')" = "$ODD_SNAP" ] && echo 0 || echo 1)"

# ---- the delete direction: a blanked map is not resurrected --------------------
sed -i 's|^feature_map:.*$|feature_map:|' AGENTS.md
$INSTALL >/dev/null 2>&1
check "a blanked feature_map stays blank (the carry never resurrects a value)" \
  "$(grep -qx 'feature_map:' AGENTS.md && echo 0 || echo 1)"

# ---- the REST of the render-call's literal keys (INSTALL-CARRY) ----------------
# `render_config` (bin/goblin-install) draws these keys from a HARDCODED LITERAL in the same
# render call: `VERIFY_DOCTOR ""`, `REFERENCE_MANIFEST ""`, `QUARANTINE_ROOT ""`, plus
# `SOURCE_ROOT "."`, `MAX_DIRTY "0"` and `BANS_EXEMPT ""`. Every one is read by a gate
# (VA-01 / RC-01 / FM-02 / CM-03 / goblin-bans' exemptions), so writing the literal over a
# project's declaration switches that gate off exactly the way feature_map's was switched off.
# The feature_map cases above already prove the mechanism; these are the ENUMERATION — the
# whole render-call was read, so this is every literal-drawn key in it, not a sample.
OTHER_KEYS="verify_doctor reference_manifest quarantine_root source_root max_dirty bans_exempt"
oval() {
  case "$1" in
    feature_map)        printf 'features/README.md' ;;
    verify_doctor)      printf 'bash scripts/doctor.sh --fast' ;;
    reference_manifest) printf 'assets/reference-manifest.json' ;;
    quarantine_root)    printf '.quarantine' ;;
    source_root)        printf 'src' ;;
    max_dirty)          printf '3' ;;
    bans_exempt)        printf '[- BN-01 vendor/]' ;;
  esac
}
for k in $OTHER_KEYS; do
  sed -i "s|^$k:.*\$|$k: $(oval "$k")|" AGENTS.md
done
printf '      before:\n'
for k in $OTHER_KEYS; do printf '        %s: %s\n' "$k" "$(sed -n "s|^$k: ||p" AGENTS.md | head -n 1)"; done
n=0; for k in $OTHER_KEYS; do grep -qxF "$k: $(oval "$k")" AGENTS.md && n=$((n + 1)); done
check "the 6 other literal keys are planted ($n/6)" "$([ "$n" -eq 6 ] && echo 0 || echo 1)"
SNAP2=$(sha256sum AGENTS.md | awk '{print $1}')

$INSTALL >/dev/null 2>&1
printf '      after:\n'
for k in $OTHER_KEYS; do printf '        %s: %s\n' "$k" "$(sed -n "s|^$k: ||p" AGENTS.md | head -n 1)"; done
n=0; for k in $OTHER_KEYS; do grep -qxF "$k: $(oval "$k")" AGENTS.md && n=$((n + 1)); done
check "all 6 survive the re-install byte-identically (measured $n/6)" \
  "$([ "$n" -eq 6 ] && echo 0 || echo 1)"
check "AGENTS.md is byte-identical after carrying 6 more keys" \
  "$([ "$(sha256sum AGENTS.md | awk '{print $1}')" = "$SNAP2" ] && echo 0 || echo 1)"
n=0; for k in $OTHER_KEYS; do [ "$(grep -c "^$k:" AGENTS.md)" -eq 1 ] && n=$((n + 1)); done
check "each carried key appears exactly once ($n/6 — replace, never append)" \
  "$([ "$n" -eq 6 ] && echo 0 || echo 1)"

# ---- the delete direction, for every one of them ------------------------------
# The carry reads what is THERE. A value the project blanked carries nothing, so a key whose
# default is EMPTY stays blank: the installer must never resurrect a declaration it cannot see.
# (source_root: "." and max_dirty: "0" are the two whose default is a REAL value — a blank
# there re-renders today's default, which is the same thing a fresh install writes.)
BLANKABLE="verify_doctor reference_manifest quarantine_root"
for k in $BLANKABLE; do sed -i "s|^$k:.*\$|$k:|" AGENTS.md; done
sed -i 's|^source_root:.*$|source_root:|; s|^max_dirty:.*$|max_dirty:|' AGENTS.md
$INSTALL >/dev/null 2>&1
n=0; for k in $BLANKABLE; do grep -qxF "$k:" AGENTS.md && n=$((n + 1)); done
check "the 3 empty-default keys stay blank when the project blanked them ($n/3)" \
  "$([ "$n" -eq 3 ] && echo 0 || echo 1)"
check "a blanked source_root:/max_dirty: re-renders today's default (., 0 — not a carry)" \
  "$(grep -qx 'source_root: \.' AGENTS.md && grep -qx 'max_dirty: 0' AGENTS.md && echo 0 || echo 1)"

# ---- a fresh install still renders today's defaults ---------------------------
# With no previous block the carry does nothing, so the block a fresh install renders must be
# byte-identical to the one the PRE-CHANGE renderer renders into an empty repo. That copy is
# also the negative control below: this tree with the carry call switched off — the renderer
# this card was measured on. It is a copy of the shipped dirs, never the repo.
fixture() { # fixture <dir>
  mkdir -p "$1"
  printf '# target\n' > "$1/README.md"
  ( cd "$1" \
    && git init -q -b main \
    && git config user.name "Test Runner" \
    && git config user.email "runner@example.com" \
    && git add -A && git commit -q -m "chore: seed" )
}
block() { sed -n '/^<!-- gob:begin/,/^<!-- gob:end/p' "$1"; }
PRE="$WORK/pre"
mkdir -p "$PRE"
cp -a "$SRC/bin" "$SRC/templates" "$SRC/manifest" "$SRC/bans" "$SRC/skills" "$SRC/VERSION" "$PRE/"
CARRY_CALLS=$(grep -c '^[[:space:]]*carry_forward$' "$PRE/bin/goblin-install" 2>/dev/null || true)
check "the pre-change copy has exactly one carry_forward call to switch off" \
  "$([ "${CARRY_CALLS:-0}" -eq 1 ] && echo 0 || echo 1)"
sed -i 's/^\([[:space:]]*\)carry_forward$/\1: # negative control: the carry is OFF/' \
  "$PRE/bin/goblin-install"
check "the negative control really switched it off (no active call left)" \
  "$([ "$(grep -c '^[[:space:]]*carry_forward$' "$PRE/bin/goblin-install")" -eq 0 ] && echo 0 || echo 1)"

fixture "$WORK/fresh"
fixture "$WORK/today"
bash "$SRC/bin/goblin-install" --target "$WORK/fresh" >/dev/null 2>&1
bash "$PRE/bin/goblin-install" --target "$WORK/today" >/dev/null 2>&1
block "$WORK/fresh/AGENTS.md" > "$WORK/fresh.block"
block "$WORK/today/AGENTS.md" > "$WORK/today.block"
check "a fresh install renders the SAME block as the pre-change renderer (no invented default)" \
  "$(diff -q "$WORK/fresh.block" "$WORK/today.block" >/dev/null && echo 0 || echo 1)"
n=0
for k in feature_map verify_doctor reference_manifest quarantine_root; do
  grep -qx "$k:" "$WORK/fresh.block" && n=$((n + 1))
done
check "a fresh install still ships the 4 gates EMPTY ($n/4 — the honest day-one state)" \
  "$([ "$n" -eq 4 ] && echo 0 || echo 1)"
check "a fresh install still ships source_root: . (today's literal default)" \
  "$(grep -qx 'source_root: \.' "$WORK/fresh.block" && echo 0 || echo 1)"

# ---- the negative control: the same test on the pre-change renderer -----------
# D: if this harness cannot fail, it proves nothing. Plant the card's 4 keys, re-install with
# the carry switched off, and measure 4 in -> 0 out.
fixture "$WORK/neg"
AG_NEG="$WORK/neg/AGENTS.md"
bash "$PRE/bin/goblin-install" --target "$WORK/neg" >/dev/null 2>&1
for k in feature_map verify_doctor reference_manifest quarantine_root; do
  sed -i "s|^$k:.*\$|$k: $(oval "$k")|" "$AG_NEG"
done
BEFORE_NEG=$(grep -cE '^(feature_map|verify_doctor|reference_manifest|quarantine_root): .+' "$AG_NEG")
check "the 4 declarations are planted before the control's re-install (4 in)" \
  "$([ "$BEFORE_NEG" -eq 4 ] && echo 0 || echo 1)"
bash "$PRE/bin/goblin-install" --target "$WORK/neg" >/dev/null 2>&1
AFTER_NEG=$(grep -cE '^(feature_map|verify_doctor|reference_manifest|quarantine_root): .+' "$AG_NEG")
check "NEGATIVE CONTROL: the same re-install erases them — 4 in -> $AFTER_NEG out" \
  "$([ "$AFTER_NEG" -eq 0 ] && echo 0 || echo 1)"

# ---- AC1: the render does NOT decide what a re-install keeps -------------------
# ratchet.ceiling (the render re-measures it), a gate_<name>_cmd key the render does not
# emit at all (it would be DELETED — a declared gate vanishing), and the comment lines
# that record why the ceiling is what it is: a plain re-install must keep all three, in
# place, and be idempotent — the second re-install diffs empty against the first.
mkfix_ac1() {
  mkdir -p "$1" && cd "$1"
  git init -q -b main
  git config user.name "Test Runner"
  git config user.email "runner@example.com"
  printf '# %s\n' "$(basename "$1")" > README.md
  git add -A && git commit -q -m "chore: seed"
}
bcom() { sed -n '/^<!-- gob:begin/,/^<!-- gob:end -->/p' "$1" | grep -c '^# '; }  # comment lines IN the block
mkfix_ac1 "$WORK/ac1"
AG1="$WORK/ac1/AGENTS.md"
bash "$SRC/bin/goblin-install" --target "$WORK/ac1" >/dev/null 2>&1
sed -i 's|^ratchet.ceiling:.*$|ratchet.ceiling: 1105500|' "$AG1"
sed -i '/^ratchet.ceiling:/i gate_tsc_build_cmd: npx tsc --noEmit \&\& npx vite build' "$AG1"
sed -i '/^ratchet.ceiling:/i # ceiling pinned by hand 2026-11-26: the 0.7.1 bundle is 1.05 MB' "$AG1"
sed -i '/^ratchet.ceiling:/i # measured 1105500 bytes; do not re-measure' "$AG1"
sed -i '/^ratchet.ceiling:/i # raised past this needs a ROUND spec, not an install' "$AG1"
check "the ceiling, the gate and 3 comment lines are planted" \
  "$(grep -qx 'ratchet.ceiling: 1105500' "$AG1" \
     && grep -qxF 'gate_tsc_build_cmd: npx tsc --noEmit && npx vite build' "$AG1" \
     && [ "$(bcom "$AG1")" -eq 3 ] && echo 0 || echo 1)"
bash "$SRC/bin/goblin-install" --target "$WORK/ac1" >/dev/null 2>&1
check "AC1 plain re-install keeps the declared ceiling (not the re-measured one)" \
  "$(grep -qx 'ratchet.ceiling: 1105500' "$AG1" && echo 0 || echo 1)"
check "AC1 keeps the gate key the render does not emit (the gate cannot vanish)" \
  "$(grep -qxF 'gate_tsc_build_cmd: npx tsc --noEmit && npx vite build' "$AG1" && echo 0 || echo 1)"
check "AC1 keeps the ratchet comment block (3 lines, in place)" \
  "$([ "$(bcom "$AG1")" -eq 3 ] \
     && grep -qxF '# ceiling pinned by hand 2026-11-26: the 0.7.1 bundle is 1.05 MB' "$AG1" \
     && echo 0 || echo 1)"
check "AC1 keeps each key exactly once (replace, never append)" \
  "$([ "$(grep -c '^ratchet.ceiling:' "$AG1")" -eq 1 ] \
     && [ "$(grep -c '^gate_tsc_build_cmd:' "$AG1")" -eq 1 ] && echo 0 || echo 1)"
AC1_SNAP=$(sha256sum "$AG1" | awk '{print $1}')
bash "$SRC/bin/goblin-install" --target "$WORK/ac1" --upgrade >/dev/null 2>&1
check "AC1 idempotent: the second re-install (--upgrade, same path) leaves AGENTS.md byte-identical" \
  "$([ "$(sha256sum "$AG1" | awk '{print $1}')" = "$AC1_SNAP" ] && echo 0 || echo 1)"

# ---- AC2: a flag is a decision; the absence of a flag is not --------------------
bash "$SRC/bin/goblin-install" --target "$WORK/ac1" --gate 'echo gated' tsc_build >/dev/null 2>&1
check "AC2 an explicit --gate rewrites the key it names" \
  "$(grep -qxF 'gate_tsc_build_cmd: echo gated' "$AG1" && echo 0 || echo 1)"
check "AC2 the flag leaves the ceiling alone" \
  "$(grep -qx 'ratchet.ceiling: 1105500' "$AG1" && echo 0 || echo 1)"
check "AC2 the flag leaves the comment block alone" \
  "$([ "$(bcom "$AG1")" -eq 3 ] && echo 0 || echo 1)"
bash "$SRC/bin/goblin-install" --target "$WORK/ac1" >/dev/null 2>&1
check "AC2 and the flagged value itself is then carried by the next plain re-install" \
  "$(grep -qxF 'gate_tsc_build_cmd: echo gated' "$AG1" && echo 0 || echo 1)"

# ---- AC4 for a key the render does NOT emit ------------------------------------
# A blanked gate_tsc_build_cmd: the render has no line for it, so the re-inserted line
# must be the BLANK one — never resurrected with an invented value.
sed -i 's|^gate_tsc_build_cmd:.*$|gate_tsc_build_cmd:|' "$AG1"
bash "$SRC/bin/goblin-install" --target "$WORK/ac1" >/dev/null 2>&1
check "AC4 a blanked non-emitted key stays blank (re-inserted, not invented)" \
  "$(grep -qx 'gate_tsc_build_cmd:' "$AG1" && echo 0 || echo 1)"

# ---- --opt-out: disabled: must always render as a flat, deduped [a,b] ------------
# The renderer writes `disabled: [{{DISABLED}}]` — a flat list. The opt-out re-record then
# re-wraps the PREVIOUS value, and its bracket strip (${cur#[]}) matches nothing, so the
# brackets survived: a fresh install with --opt-out mcp measured `disabled: [[mcp],mcp]` on
# 0.7.1 AND on the carry build, and the carry then preserved the malformed value (sticky).
# The re-record strips the brackets before re-wrapping. Every shape below is measured.
fixture "$WORK/opt1"
AG_OPT="$WORK/opt1/AGENTS.md"
bash "$SRC/bin/goblin-install" --target "$WORK/opt1" --opt-out mcp >/dev/null 2>&1
check "OPT AC1 a fresh install --opt-out mcp renders disabled: [mcp] (flat, not nested)" \
  "$(grep -qxF 'disabled: [mcp]' "$AG_OPT" && ! grep -qF '[[' "$AG_OPT" && echo 0 || echo 1)"
bash "$SRC/bin/goblin-install" --target "$WORK/opt1" --opt-out mcp >/dev/null 2>&1
check "OPT AC2 a second --opt-out mcp is idempotent (still one disabled: [mcp])" \
  "$([ "$(grep -cxF 'disabled: [mcp]' "$AG_OPT")" -eq 1 ] && echo 0 || echo 1)"
bash "$SRC/bin/goblin-install" --target "$WORK/opt1" --opt-out skills >/dev/null 2>&1
check "OPT AC2 adding --opt-out skills gives disabled: [mcp,skills] (deduped, sorted)" \
  "$(grep -qxF 'disabled: [mcp,skills]' "$AG_OPT" && echo 0 || echo 1)"
OPT_SNAP=$(sha256sum "$AG_OPT" | awk '{print $1}')
bash "$SRC/bin/goblin-install" --target "$WORK/opt1" >/dev/null 2>&1
check "OPT AC3 a plain re-install keeps the opt-out byte-for-byte" \
  "$([ "$(sha256sum "$AG_OPT" | awk '{print $1}')" = "$OPT_SNAP" ] && echo 0 || echo 1)"
check "OPT AC4 two opt-outs survive the re-install as [mcp,skills] (no nesting)" \
  "$(grep -qxF 'disabled: [mcp,skills]' "$AG_OPT" && echo 0 || echo 1)"
fixture "$WORK/opt2"
AG_OPT2="$WORK/opt2/AGENTS.md"
bash "$SRC/bin/goblin-install" --target "$WORK/opt2" >/dev/null 2>&1
check "OPT AC5 the un-flagged render is disabled: []" \
  "$(grep -qxF 'disabled: []' "$AG_OPT2" && echo 0 || echo 1)"
bash "$SRC/bin/goblin-install" --target "$WORK/opt2" --opt-out mcp >/dev/null 2>&1
check "OPT AC5 an opt-out over an existing disabled: [] yields disabled: [mcp]" \
  "$(grep -qxF 'disabled: [mcp]' "$AG_OPT2" && echo 0 || echo 1)"
bash "$SRC/bin/goblin-install" --target "$WORK/opt2" >/dev/null 2>&1
check "OPT AC5 and a plain re-install keeps that [mcp]" \
  "$(grep -qxF 'disabled: [mcp]' "$AG_OPT2" && echo 0 || echo 1)"

# ---- RED control: the 0.7.1 renderer, verbatim -----------------------------------
# The render bug is PRE-EXISTING (it shipped in 0.7.1; the carry only made it sticky). The
# assertions above must fail on 0.7.1's installer or they prove nothing: run the same fresh
# --opt-out against the v0.7.1 TAG and require the measured malformation.
# PINNED TO THE TAG, NOT origin/main: this control used to archive origin/main, and when the
# 0.7.2 fix reached origin/main the "old" tree started carrying the fix, so both assertions
# turned red against a correct installer (measured 2026-11-27 on 10bb36d). A red control whose
# premise drifts with the branch proves nothing in either direction. The tag cannot drift.
PRE071="$WORK/pre071"; mkdir -p "$PRE071"
git -C "$SRC" archive v0.7.1 | tar -x -C "$PRE071"
fixture "$WORK/opt-red"
AG_OPTRED="$WORK/opt-red/AGENTS.md"
bash "$PRE071/bin/goblin-install" --target "$WORK/opt-red" --opt-out mcp >/dev/null 2>&1
RED_VAL=$(sed -n 's/^disabled: //p' "$AG_OPTRED" | head -1)
check "OPT RED CONTROL (0.7.1): fresh --opt-out mcp renders the malformed value (got: ${RED_VAL:-none})" \
  "$(grep -qxF 'disabled: [[mcp],mcp]' "$AG_OPTRED" && echo 0 || echo 1)"
bash "$PRE071/bin/goblin-install" --target "$WORK/opt-red" >/dev/null 2>&1
check "OPT RED CONTROL (0.7.1): a plain re-install does NOT keep the opt-out (carry drops it)" \
  "$(grep -qxF 'disabled: []' "$AG_OPTRED" && echo 0 || echo 1)"

# ---- the negative control: the same tree with the carry switched off ------------
# D: if this harness cannot fail, it proves nothing. The control is the PRE copy (this
# tree's dirs with the carry call commented out) — for the AC1 keys it is exactly the
# 0.7.1 behaviour: ceiling re-measured, non-emitted gate deleted, comments deleted.
mkfix_ac1 "$WORK/neg-ac1"
AG_NEG1="$WORK/neg-ac1/AGENTS.md"
bash "$PRE/bin/goblin-install" --target "$WORK/neg-ac1" >/dev/null 2>&1
sed -i 's|^ratchet.ceiling:.*$|ratchet.ceiling: 1105500|' "$AG_NEG1"
sed -i '/^ratchet.ceiling:/i gate_tsc_build_cmd: npx tsc --noEmit \&\& npx vite build' "$AG_NEG1"
sed -i '/^ratchet.ceiling:/i # ceiling pinned by hand 2026-11-26: the 0.7.1 bundle is 1.05 MB' "$AG_NEG1"
N_CEIL=$(grep -qx 'ratchet.ceiling: 1105500' "$AG_NEG1" && echo 1 || echo 0)
N_GATE=$(grep -c '^gate_tsc_build_cmd:' "$AG_NEG1")
N_COM=$(bcom "$AG_NEG1")
check "the control fixture is planted (ceiling=$N_CEIL gate=$N_GATE comments=$N_COM)" \
  "$([ "$N_CEIL" -eq 1 ] && [ "$N_GATE" -eq 1 ] && [ "$N_COM" -eq 1 ] && echo 0 || echo 1)"
bash "$PRE/bin/goblin-install" --target "$WORK/neg-ac1" >/dev/null 2>&1
NEG_GONE=$(( N_CEIL + N_GATE + N_COM ))
NEG_KEPT=$(( $(grep -qx 'ratchet.ceiling: 1105500' "$AG_NEG1" && echo 1 || echo 0) \
           + $(grep -c '^gate_tsc_build_cmd:' "$AG_NEG1") \
           + $(bcom "$AG_NEG1") ))
check "NEGATIVE CONTROL (carry off): $NEG_GONE in -> $NEG_KEPT out — the bug this card fixes" \
  "$([ "$NEG_KEPT" -eq 0 ] && echo 0 || echo 1)"

if [ "$fail" -eq 0 ]; then note "t-install-feature-map-carry: PASS"; else note "t-install-feature-map-carry: FAIL"; fi
exit "$fail"
