#!/usr/bin/env bash
# t-install-feature-map-carry.sh — `feature_map:` is the PROJECT's answer, and a re-install
# must not blank it.
#
# `render_config` (bin/goblin-install) re-renders the gob:block from
# templates/agents-block.tmpl, which carries `feature_map:` with the literal empty value, and
# g_agents_write replaces the block wholesale — so a PLAIN re-install (no --upgrade) erased a
# declared map and FM-01/FM-02 fell back to SKIP, i.e. a re-install switched both gates off.
# The carry-forward below reads the previous block through the round-trip reader
# (g_agents_pairs), so a value containing ": " or a raw tab survives intact.
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

if [ "$fail" -eq 0 ]; then note "t-install-feature-map-carry: PASS"; else note "t-install-feature-map-carry: FAIL"; fi
exit "$fail"
