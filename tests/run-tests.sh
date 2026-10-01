#!/usr/bin/env bash
# run-tests.sh — every source-scope rule (PR-01..PR-05) plus the test scripts.
# Exits non-zero on any failure and prints one line per test.
#
#   bash tests/run-tests.sh
#
# PR-01  the installer never writes outside its target   -> t-install-idempotent.sh
# PR-02  a second install is a no-op                     -> t-install-idempotent.sh
# PR-03  every target-scope check goes RED under its own violation -> t-verify-red.sh
# PR-04  the repo is portable: no personal path in a reusable rule -> the PT-01 body below
# PR-05  the automation producer is silent when there is nothing to report -> t-automation-silent.sh
#
# (This line listed PR-01..PR-04 until Z1-8 while the matrix carried five source rows and the
# suite below did run t-automation-silent.sh - off by one in the conservative direction, in the
# file that pins counts. The fifth row is PR-05, enforcement.tsv:84.)
#
# The installer's own contract (a refusal exits 1, a file it did not create is never
# overwritten) is t-install-refusal.sh. The verifier's refusal to read an enclosing repo
# (F2-1) is t-verify-nested.sh; `--uninstall`'s directory cleanup (F2-7) is t-uninstall.sh;
# the documents that claim to render the matrix (F2-3, F2-4, F2-8, F2-9) are
# t-doc-sync.sh; the promises the documents make about this artifact - the command paths they hand
# a reader and the self-counts they state about it, each enumerated from the docs themselves - are
# t-doc-promises.sh; and the practice pin's explicit re-pin path (F4-followup) is
# t-practice-repin.sh. Z1-3's "a rendered install carries no unsubstituted {{...}} token"
# is t-render-tokens.sh.

set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$SRC"
FAIL=0
line() { printf '%-34s %s\n' "$1" "$2"; }

# ---- syntax ------------------------------------------------------------------
SYNTAX_OK=0
for f in bin/goblin-install bin/goblin-verify bin/goblin-model bin/goblin-lib.sh \
         bin/goblin-emit bin/goblin-doctor bin/goblin-init \
         adapters/claude/detect.sh adapters/hermes/detect.sh adapters/copilot/detect.sh \
         adapters/cursor/detect.sh adapters/opencode/detect.sh adapters/codex/detect.sh \
         adapters/gemini/detect.sh \
         adapters/claude/verify.sh adapters/hermes/verify.sh adapters/copilot/verify.sh \
         adapters/cursor/verify.sh adapters/opencode/verify.sh adapters/codex/verify.sh \
         adapters/gemini/verify.sh \
         tests/run-tests.sh tests/t-*.sh templates/checks/gate.sh.tmpl; do
  bash -n "$f" 2>/dev/null || { SYNTAX_OK=1; printf 'syntax error: %s\n' "$f"; }
done
if [ "$SYNTAX_OK" -eq 0 ]; then line "syntax (bash -n)" "ok"; else line "syntax (bash -n)" "FAIL"; FAIL=1; fi

# ---- the reader's own self-test ---------------------------------------------
if out=$(bash bin/goblin-lib.sh --self-test 2>&1); then line "goblin-lib --self-test" "ok ($out)"; else line "goblin-lib --self-test" "FAIL"; FAIL=1; fi

# ---- PR-04 / PT-01 over the SOURCE tree -------------------------------------
# PT-01's own directory list is the set an INSTALL writes (skills manifest bin templates presets
# .goblin .hermes). This body is the same rule over the SOURCE tree, which also owns tests/ — the
# directory the negative control lives in, and where a tenant string sat until F2-5 (1 repo-wide
# hit at f23b371, 0 at b100b44, and PT-01 could not see it). tests/ is deliberately NOT added to
# PT-01 itself: a target's own tests are its code, and a project may legitimately name its own
# paths there.
PT=$(for d in skills manifest bin templates presets automations tests; do
       [ -d "$d" ] || continue
       grep -rniE '(h[a]rvey|tech-g[o]blin|/h[o]me/[a-z]+|g[o]blin-ui|op[e]n-door|sup[r]eme|bb[t]ech|c[l]v)' "$d"
     done)
if [ -z "$PT" ]; then line "PR-04 portability (PT-01 body)" "ok (0 hits)"; else
  printf '%s\n' "$PT" | sed 's/^/    /'; line "PR-04 portability (PT-01 body)" "FAIL"; FAIL=1
fi

# ---- MD-01 over the source tree ---------------------------------------------
MD=$(for d in skills manifest bin templates presets automations; do
       [ -d "$d" ] || continue
       grep -rniE '(d[e]epseek|cl[a]ude|g[p]t-[0-9]|gr[o]k|g[e]mini|g[l]m-[0-9]|k[i]mi)[a-z0-9.:_-]*' "$d"
     done)
if [ -z "$MD" ]; then line "MD-01 no hardcoded model name" "ok (0 hits)"; else
  printf '%s\n' "$MD" | sed 's/^/    /'; line "MD-01 no hardcoded model name" "FAIL"; FAIL=1
fi

# ---- MD-01 positive control: the pattern must still catch a real model name --
# The slug is ASSEMBLED at run time, never written literally: a literal model name in this file
# was one of the two repo-wide MD-01 hits G8-10 measured (the other is the control in
# tests/t-verify-red.sh). Same fix F2-5 gave the tenant string - the control must not be the leak
# its own rule exists to catch.
MD_SLUG="$(printf '%s%s' 'deep' 'seek-v9-turbo')"
if printf 'model: %s\n' "$MD_SLUG" | grep -qE '(d[e]epseek|cl[a]ude|g[p]t-[0-9]|gr[o]k|g[e]mini|g[l]m-[0-9]|k[i]mi)[a-z0-9.:_-]*'; then
  line "MD-01 positive control" "ok (a real model name is caught)"
else
  line "MD-01 positive control" "FAIL (the pattern no longer catches anything)"; FAIL=1
fi

# ---- the manifest's own integrity -------------------------------------------
# IN-03's body, run over the SOURCE manifest (the installed copy is the same file). It carries
# the same three clauses as the row's own check cell: a row with no check must be labelled
# advisory, and `enforced_by` must stay inside the closed enum (Z1-5).
if awk -F'\t' 'NR>1 && ($6=="" || ($6=="advisory" && $4!="advisory") || $4 !~ /^(script|lint|gate|advisory|test)$/) {n++} END{exit n>0}' manifest/enforcement.tsv; then
  line "IN-03 manifest self-check" "ok"
else
  line "IN-03 manifest self-check" "FAIL"; FAIL=1
fi

# ---- the test scripts --------------------------------------------------------
for t in t-install-idempotent t-install-off-switch t-install-refusal t-verify-green t-verify-red \
         t-verify-nested t-engine-dir t-upgrade t-uninstall t-doc-sync t-doc-promises t-practice-repin t-automation-silent \
         t-audit t-render-tokens t-gt03-freshness t-doc-guide t-doc-replay t-version-sync \
         t-emit t-doctor t-init t-banner-stderr; do
  out=$(bash "tests/$t.sh" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then line "$t" "ok"
  else line "$t" "FAIL"; printf '%s\n' "$out" | sed 's/^/    /'; FAIL=1; fi
done

echo
if [ "$FAIL" -eq 0 ]; then echo "run-tests: PASS"; else echo "run-tests: FAIL"; fi
exit "$FAIL"
