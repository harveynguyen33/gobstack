#!/usr/bin/env bash
# run-tests.sh — every source-scope rule (PR-01..PR-04) plus the four test scripts.
# Exits non-zero on any failure and prints one line per test.
#
#   bash tests/run-tests.sh
#
# PR-01  the installer never writes outside its target   -> t-install-idempotent.sh
# PR-02  a second install is a no-op                     -> t-install-idempotent.sh
# PR-03  every target-scope check goes RED under its own violation -> t-verify-red.sh
# PR-04  the repo is portable: no personal path in a reusable rule -> the PT-01 body below

set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$SRC"
FAIL=0
line() { printf '%-34s %s\n' "$1" "$2"; }

# ---- syntax ------------------------------------------------------------------
SYNTAX_OK=0
for f in bin/goblin-install bin/goblin-verify bin/goblin-model bin/goblin-lib.sh \
         tests/run-tests.sh tests/t-*.sh templates/checks/gate.sh.tmpl; do
  bash -n "$f" 2>/dev/null || { SYNTAX_OK=1; printf 'syntax error: %s\n' "$f"; }
done
if [ "$SYNTAX_OK" -eq 0 ]; then line "syntax (bash -n)" "ok"; else line "syntax (bash -n)" "FAIL"; FAIL=1; fi

# ---- the reader's own self-test ---------------------------------------------
if out=$(bash bin/goblin-lib.sh --self-test 2>&1); then line "goblin-lib --self-test" "ok ($out)"; else line "goblin-lib --self-test" "FAIL"; FAIL=1; fi

# ---- PR-04 / PT-01 over the SOURCE tree -------------------------------------
PT=$(for d in skills manifest bin templates presets; do
       [ -d "$d" ] || continue
       grep -rniE '(h[a]rvey|tech-g[o]blin|/h[o]me/[a-z]+|g[o]blin-ui|op[e]n-door|sup[r]eme|bb[t]ech|c[l]v)' "$d"
     done)
if [ -z "$PT" ]; then line "PR-04 portability (PT-01 body)" "ok (0 hits)"; else
  printf '%s\n' "$PT" | sed 's/^/    /'; line "PR-04 portability (PT-01 body)" "FAIL"; FAIL=1
fi

# ---- MD-01 over the source tree ---------------------------------------------
MD=$(for d in skills manifest bin templates presets; do
       [ -d "$d" ] || continue
       grep -rniE '(d[e]epseek|cl[a]ude|g[p]t-[0-9]|gr[o]k|g[e]mini|g[l]m-[0-9]|k[i]mi)[a-z0-9.:_-]*' "$d"
     done)
if [ -z "$MD" ]; then line "MD-01 no hardcoded model name" "ok (0 hits)"; else
  printf '%s\n' "$MD" | sed 's/^/    /'; line "MD-01 no hardcoded model name" "FAIL"; FAIL=1
fi

# ---- MD-01 positive control: the pattern must still catch a real model name --
if printf 'model: deepseek-v9-turbo\n' | grep -qE '(d[e]epseek|cl[a]ude|g[p]t-[0-9]|gr[o]k|g[e]mini|g[l]m-[0-9]|k[i]mi)[a-z0-9.:_-]*'; then
  line "MD-01 positive control" "ok (a real model name is caught)"
else
  line "MD-01 positive control" "FAIL (the pattern no longer catches anything)"; FAIL=1
fi

# ---- the manifest's own integrity -------------------------------------------
if awk -F'\t' 'NR>1 && $6=="" {n++} END{exit n>0}' manifest/enforcement.tsv; then
  line "IN-03 manifest self-check" "ok"
else
  line "IN-03 manifest self-check" "FAIL"; FAIL=1
fi

# ---- the four test scripts ---------------------------------------------------
for t in t-install-idempotent t-install-off-switch t-verify-green t-verify-red; do
  out=$(bash "tests/$t.sh" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then line "$t" "ok"
  else line "$t" "FAIL"; printf '%s\n' "$out" | sed 's/^/    /'; FAIL=1; fi
done

echo
if [ "$FAIL" -eq 0 ]; then echo "run-tests: PASS"; else echo "run-tests: FAIL"; fi
exit "$FAIL"
