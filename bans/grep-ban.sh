#!/usr/bin/env bash
# grep-ban.sh — a grep-backed ban probe with a fail-closed exit contract.
#
#   usage: grep-ban.sh -e <pattern> [-e <pattern> ...] <dir|file> ...
#
# Exit: 0 the tree is clean | 1 the ban is violated (offending lines on stdout)
#       2 the check could not run (no pattern, no path, or grep itself failed).
# It never exits 0 on a tool error - a ban that silently passes when its tool is missing
# is worse than advisory (PR-03 / D6).
#
# It reads TEXT, with no AST and no comments blanked: a `: any` inside a string or a
# comment is reported. That limit is stated, not hidden - the AST-grade form needs a
# parser the no-npm contract (docs/CONTRACTS.md) does not allow (docs/LIMITS.md #27).

set -uo pipefail
pats=()
while [ $# -gt 0 ]; do
  case "$1" in
    -e) [ $# -ge 2 ] || { echo "grep-ban: -e needs a pattern" >&2; exit 2; }
        pats+=("${2:-}"); shift 2 ;;
    --) shift; break ;;
    -*) echo "grep-ban: unknown option $1" >&2; exit 2 ;;
    *) break ;;
  esac
done
[ "${#pats[@]}" -gt 0 ] || { echo "grep-ban: no pattern given" >&2; exit 2; }
[ "$#" -gt 0 ] || { echo "grep-ban: no path given" >&2; exit 2; }
# A declared glob that does not exist on disk is not an error: the engine already turns
# "no matching files" into a SKIP with a reason before it calls this. Silently dropping a
# missing path here is what stops one absent sibling (BN-03's `app` beside `src/components`)
# from failing the ban closed on a tree that is clean.
paths=()
for p in "$@"; do [ -e "$p" ] && paths+=("$p"); done
[ "${#paths[@]}" -gt 0 ] || exit 0
args=()
for p in "${pats[@]}"; do args+=(-e "$p"); done
out=$(grep -rnE "${args[@]}" \
        --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.mjs' \
        -- "${paths[@]}" 2>&1)
rc=$?
case "$rc" in
  1) exit 0 ;;                              # no match: clean
  0) printf '%s\n' "$out"; exit 1 ;;        # matches: the ban is violated
  *) printf '%s\n' "$out" >&2; exit 2 ;;    # grep could not run: fail closed
esac
