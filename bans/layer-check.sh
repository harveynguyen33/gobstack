#!/usr/bin/env bash
# layer-check.sh — BN-05's detect. The boundary ban Dune actually mechanises.
#
# Reads the config's `layers:` list, each item "<from> <to>", and fails when a file under
# <from> imports across into <to>. The import test is a text probe for an import path that
# names <to>'s last path segment - so it catches `from '../main/db'` in a renderer, and it
# does NOT resolve module aliases or dynamic imports. Stated, not hidden (docs/LIMITS.md #27).
#
# Exit: 0 clean | 1 a crossing import (lines on stdout) | 2 could not run | 3 no layers declared.

set -uo pipefail
SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SELF_DIR/../.." && pwd)          # .goblin/bans/ -> repo root
CONFIG="$ROOT/.goblin/goblin.yaml"
[ -f "$CONFIG" ] || { echo "layer-check: no $CONFIG" >&2; exit 2; }

layers=$(awk '
  $0 ~ /^layers:[[:space:]]*$/ { inb = 1; next }
  inb && /^[^ ]/ { inb = 0 }
  inb && /^  - / { v = $0; sub(/^  - /, "", v); print v }
' "$CONFIG")
[ -n "$layers" ] || { echo "no layers declared in $CONFIG - declare a from/to pair to turn BN-05 on"; exit 3; }

bad=""
while read -r from to; do
  [ -n "$from" ] && [ -n "$to" ] || continue
  [ -d "$ROOT/$from" ] || continue
  seg=${to##*/}
  hits=$(cd "$ROOT" && grep -rnE "from[[:space:]]+['\"][^'\"]*${seg}/" \
           --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' "$from" 2>/dev/null || true)
  [ -n "$hits" ] && bad="$bad$hits"$'\n'
done <<EOF
$layers
EOF

if [ -n "$bad" ]; then printf '%s' "$bad"; exit 1; fi
exit 0
