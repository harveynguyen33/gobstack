#!/usr/bin/env bash
# t-version-sync.sh — the version hole (PLAN-V1 §4.4): VERSION is the one source,
# and until W2 nothing in tests/ read the five GOBLIN_*_VERSION constants in bin/
# (measured there: `grep -rn 'GOBLIN_.*_VERSION' tests/` -> empty). This file closes it.
#
#   V1  VERSION exists and matches ^[0-9]+\.[0-9]+\.[0-9]+$      (a malformed source of truth)
#   V2  package.json.version == VERSION, read via python3        (the package bumped alone)
#   V3  every ^GOBLIN_[A-Z_]*_VERSION="..." in bin/ == VERSION   (a constant drifts)
#   V4  the count of those constants is pinned at 5              (a 6th copy is added — the
#       load-bearing one: value equality cannot stop copy #6, only the count can)
#   V5  the GUIDE Version: stamp check still exists in t-doc-guide.sh — the AB4 matcher
#       lives, so a refactor cannot silently drop the one stamp assertion that predates
#       this file (its logic is asserted to EXIST here, not duplicated)
#   V6  goblin --version prints VERSION byte-for-byte through BOTH CLIs — the bash
#       dispatcher (W1) and the node shim (W2); a shim or constant bypassing the source
#       fails byte-for-byte
#
# Dependency contract: python3 for JSON (no jq), bash/awk/sed/grep only.

set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$SRC"

FAIL=0
check() { # check <label> <rc>
  if [ "$2" -eq 0 ]; then printf 'ok  %s\n' "$1"
  else printf 'FAIL %s\n' "$1"; FAIL=1; fi
}

VERSION=$(cat VERSION 2>/dev/null || true)

# ---- V1: the source of truth is well-formed (semver, prerelease allowed) --------------------
# V2's alpha ladder (0.6.0-alpha.1) put a prerelease suffix on VERSION itself, so the old
# ^[0-9]+\.[0-9]+\.[0-9]+$ core-only shape would have called the source of truth malformed.
# The shape is semver 2.0.0 now: core, optionally followed by -<prerelease> of dot-separated
# alphanumeric identifiers (the one ladder this repo has ever used: 0.4.4-beta.N on the
# package, 0.6.0-alpha.N on the engine).
if [ -n "$VERSION" ] && printf '%s' "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'; then
  check "V1 VERSION is well-formed ($VERSION)" 0
else
  check "V1 VERSION is well-formed (got: '${VERSION:-<empty>}')" 1
fi

# ---- V2: package.json.version equals VERSION as a FULL STRING ------------------------------
# The beta ladder (0.4.4-beta.1, commit 16333de) split the two numbers: VERSION stayed the
# engine's core while npm got the suffixed ladder, so V2 compared RELEASE CORES (%%-*). The
# alpha ladder (0.6.0-alpha.1) closes that gap: VERSION itself carries the prerelease, and a
# core-strip compare would accept 0.7.0-beta.9 in package.json against a 0.6.0 engine — the
# suffix is no longer the only thing that may differ, so the suffix is no longer ignored.
# The invariant is byte equality of the whole version strings, both ladders:
#   beta ladder:  VERSION=0.4.4      package.json=0.4.4-beta.8   -> FULL-STRING would REJECT
#   (that is why the ladder moved to alpha: one number, one suffix, zero core-strip)
#   alpha ladder: VERSION=0.6.0-alpha.1  package.json=0.6.0-alpha.1 -> full-string equal, GREEN
# A prerelease bump moves BOTH files together, always. python3 reads the JSON (no jq).
PKG_VER=$(python3 -c 'import json;print(json.load(open("package.json"))["version"])' 2>/dev/null || true)
check "V2 package.json.version equals VERSION byte-for-byte ($PKG_VER vs $VERSION)" \
  "$([ -n "$PKG_VER" ] && [ "$PKG_VER" = "$VERSION" ] && echo 0 || echo 1)"

# ---- V3: every bin version constant equals VERSION -----------------------------------------
# Match only the declaration shape, same one the plan pins:  ^GOBLIN_[A-Z_]*_VERSION="x.y.z"
DRIFT=$(grep -hE '^GOBLIN_[A-Z_]+_VERSION=' bin/goblin-install bin/goblin-verify bin/goblin-bans \
          bin/goblin-lib.sh bin/goblin-audit 2>/dev/null \
        | grep -v "^GOBLIN_[A-Z_]*_VERSION=\"$VERSION\"$")
if [ -z "$DRIFT" ]; then
  check "V3 every GOBLIN_*_VERSION constant in bin/ equals VERSION" 0
else
  printf '%s\n' "$DRIFT" | sed 's/^/    drifted: /'
  check "V3 every GOBLIN_*_VERSION constant in bin/ equals VERSION" 1
fi

# ---- V4: the count is pinned at 5 (the load-bearing assertion) ------------------------------
# A value comparison cannot stop another copy being added — even one that agrees today.
# Pinning the COUNT converts the next unread copy into a red run (the IN-03 move, applied
# to the version). The five, measured in PLAN-V1 §4.4's table:
#   bin/goblin-install  GOBLIN_INSTALL_VERSION
#   bin/goblin-verify   GOBLIN_VERIFY_VERSION
#   bin/goblin-bans     GOBLIN_BANS_VERSION
#   bin/goblin-lib.sh   GOBLIN_LIB_VERSION
#   bin/goblin-audit    GOBLIN_AUDIT_VERSION
EXPECTED_COUNT=5
COUNT=$(grep -hE '^GOBLIN_[A-Z_]+_VERSION=' bin/* 2>/dev/null | wc -l | tr -d ' ')
check "V4 the GOBLIN_*_VERSION constant count is pinned ($COUNT declared vs $EXPECTED_COUNT pinned)" \
  "$([ "$COUNT" -eq "$EXPECTED_COUNT" ] && echo 0 || echo 1)"

# ---- V5: the GUIDE stamp check still exists (assert AB4 lives, do not duplicate it) ---------
# t-doc-guide.sh's AB4 check is the assertion that docs/GUIDE.md's `Version:` stamp equals
# VERSION. This file asserts that MATCHER still exists, so a refactor of t-doc-guide.sh
# cannot drop it. The logic itself is NOT duplicated here.
if grep -q 'Version:.*stamp equals VERSION' tests/t-doc-guide.sh \
   && grep -q 'Version:.*' docs/GUIDE.md; then
  check "V5 the AB4 GUIDE stamp check still exists in t-doc-guide.sh" 0
else
  check "V5 the AB4 GUIDE stamp check still exists in t-doc-guide.sh" 1
fi

# ---- V6: goblin --version prints VERSION byte-for-byte, through BOTH CLIs -------------------
# The comparison is BYTE-level (cmp on files), not command substitution: $(...) strips
# trailing newlines, which would let a newline-count drift pass a check labelled
# byte-for-byte (round-2 review, LOW-1). Each CLI's stdout goes to a file untouched;
# the expectation is VERSION's own bytes copied verbatim, no re-formatting.
cp VERSION /tmp/v6-want
bash bin/goblin --version 2>/dev/null > /tmp/v6-bash.out
check "V6 bash bin/goblin --version prints VERSION byte-for-byte" \
  "$(cmp -s /tmp/v6-bash.out /tmp/v6-want && echo 0 || echo 1)"

node bin/goblin.js --version 2>/dev/null > /tmp/v6-node.out
check "V6 node bin/goblin.js --version prints VERSION byte-for-byte" \
  "$(cmp -s /tmp/v6-node.out /tmp/v6-want && echo 0 || echo 1)"
rm -f /tmp/v6-want /tmp/v6-bash.out /tmp/v6-node.out

if [ "$FAIL" -eq 0 ]; then
  printf 't-version-sync: all checks passed\n'
  exit 0
else
  printf 't-version-sync: FAILED\n'
  exit 1
fi
