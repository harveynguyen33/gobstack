#!/usr/bin/env bash
# adapters/hermes/verify.sh — the DRIFT oracle (W4A-SPEC §7). Hermes emits no context
# block (the bootstrap is the project's AGENTS.md); the oracle checks every emitted
# project skill is byte-identical to the source payload. No engine run, no network.
# Exit 0 clean, 1 drift (names the path), 2 cannot run. Env: GOBLIN_DOCTOR_TARGET.
set -uo pipefail
SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SRC=$(cd "$SELF_DIR/../.." && pwd)
TARGET="${GOBLIN_DOCTOR_TARGET:-$PWD}"
SKROOT="$TARGET/.hermes/skills"
bad=0

if [ -d "$SKROOT" ]; then
  for d in "$SKROOT"/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    case "$name" in goblin-*|practice) ;; *) continue ;; esac
    f="$d/SKILL.md"; sf="$SRC/skills/$name/SKILL.md"
    if [ ! -f "$f" ]; then continue; fi
    if [ ! -f "$sf" ] || ! cmp -s "$f" "$sf"; then
      printf 'emitted skill drifted: %s\n' "${f#"$TARGET"/}"
      bad=1
    fi
  done
fi
[ "$bad" -eq 0 ] && printf 'verified: hermes emission matches the source payload byte-for-byte\n'
exit "$bad"
