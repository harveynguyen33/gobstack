#!/usr/bin/env bash
# adapters/copilot/verify.sh — the DRIFT oracle (W4A-SPEC §7). Re-emits the context block
# to a scratch buffer and cmps against the on-disk block; checks every emitted skill is
# byte-identical to the source payload. No engine invocation, no network. Exit 0 clean,
# 1 drift (names the path), 2 cannot run. Env: GOBLIN_DOCTOR_TARGET (default $PWD).
set -uo pipefail
SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SRC=$(cd "$SELF_DIR/../.." && pwd)
TARGET="${GOBLIN_DOCTOR_TARGET:-$PWD}"
VERSION=$(cat "$SRC/VERSION" 2>/dev/null || printf 'unknown')
CF="$TARGET/.github/copilot-instructions.md"
SKROOT="$TARGET/.github/skills"
bad=0

if [ -f "$CF" ] && grep -qF '<!-- goblin-stack:begin' "$CF"; then
  EXPECT=$(awk -v b="<!-- goblin-stack:begin" -v e="<!-- goblin-stack:end" '
    index($0,b){inb=1; print; next} inb{print} index($0,e){exit}' "$CF")
  WANT=$(printf '<!-- goblin-stack:begin v%s -->\n' "$VERSION")
  WANT="$WANT
goblin-stack procedure skills are emitted for this repository (goblin-stack v$VERSION).
Core: goblin-mode (start here), goblin-bootstrap, goblin-handoff, goblin-judge,
goblin-verify-author, practice. Invoke a skill by name when the task matches its
description; the full procedure lives in each SKILL.md.
<!-- goblin-stack:end -->"
  if [ "$EXPECT" != "$WANT" ]; then
    printf 'context block in %s does not match v%s (stale marker VERSION or edited block)\n' "$CF" "$VERSION"
    bad=1
  fi
fi

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
[ "$bad" -eq 0 ] && printf 'verified: copilot emission matches v%s byte-for-byte\n' "$VERSION"
exit "$bad"
