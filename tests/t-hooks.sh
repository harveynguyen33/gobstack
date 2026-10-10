#!/usr/bin/env bash
# t-hooks.sh — the agent-hooks payload (v3 enhance layer). init --write writes a hooks
# snippet into an EXISTING .claude/ or .cursor/ directory ONLY (detection, never creation),
# records the snippet's sha256 next to .mcp.json's own preimage clause
# (.gob/manifest/hooks.tsv), and --uninstall removes a hook ONLY when it still hashes to
# the recorded value. The behavioural contract, every clause exercised on disk:
#
#   H1  write  -> the exact bytes exist at .claude/hooks.json / .cursor/hooks.json
#   H2         -> a vendor dir is NEVER created (no .claude/, no hooks, named out loud)
#   H3         -> the hash record exists and names the file(s) it covers
#   H4  second write -> idempotent (same bytes, named no-op, nothing duplicated)
#   H5  uninstall -> removes ONLY the hash-identical hook (and the record)
#   H6  uninstall vs a MODIFIED hook -> refuses: the file stays, the edit stays, named
#   H7  --with-mcp-config is the opt-in it is named as: default writes no .mcp.json,
#       the flag writes the generated registration, and a customized one is never touched
#
# Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

CLAUDE_BYTES='{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash .gob/bin/goblin-verify --brief || true"}]}]}}'
CURSOR_BYTES='{"hooks":{"sessionStart":[{"command":"bash .gob/bin/goblin-verify --brief || true"}]}}'
MCP_BYTES='{"mcpServers":{"gob":{"command":"npx","args":["-y","@techgoblin/gobstack","mcp"]}}}'

seed() { # seed <dir>
  mkdir -p "$1"
  ( cd "$1" && git init -q -b main && git config user.email t@t && git config user.name t \
    && printf '# t\n' > README.md && git add -A && git commit -qm seed ) >/dev/null 2>&1
}
# The proposal file: the minimal shape --write accepts (one gate + a resolvable map).
proposal() { # proposal <dir>
  cat > "$1/.gob-init-proposal.md" <<EOF
<!-- gob:begin (gobstack config) -->
gate_smoke_cmd: true
feature_map: features/README.md
source_root: .
<!-- gob:end -->

## gob init summary

- seeded

## feature-map

### features/README.md

\`\`\`md
# Features

- [seed](./seed.md) — seed
\`\`\`

### features/seed.md

\`\`\`md
---
feature: seed
entry_paths:
  - README.md
verified: never-driven (<2026-10-10>)
---
# seed

A seed feature.

## Sub-features

- none

## How to get to it (user POV)

- README.

## Driving it with harness

Preconditions: none.
**Run.** Run \`cat README.md\`. Shows the readme.

## Gotchas

- none
\`\`\`
EOF
}
write_install() { # write_install <dir> [extra args...]
  local d="$1"; shift
  proposal "$d"
  ( cd "$d" && bash "$SRC/bin/goblin-init" --write .gob-init-proposal.md --yes "$@" ) 2>&1
}

# ---- H1: write -> the exact bytes exist ---------------------------------------------
seed "$WORK/claude"; mkdir -p "$WORK/claude/.claude"
OUT1=$(write_install "$WORK/claude"); RC1=$?
check "H1a --write with an existing .claude/ exits 0 (got $RC1)" "$([ "$RC1" = 0 ] && echo 0 || echo 1)"
[ "$(cat "$WORK/claude/.claude/hooks.json")" = "$CLAUDE_BYTES" ]
check "H1b the exact bytes exist at .claude/hooks.json" "$?"
printf '%s' "$OUT1" | grep -q "wrote .claude/hooks.json"
check "H1c the write is named out loud" "$?"

# both vendors, one run
seed "$WORK/both"; mkdir -p "$WORK/both/.claude" "$WORK/both/.cursor"
write_install "$WORK/both" >/dev/null 2>&1
[ "$(cat "$WORK/both/.claude/hooks.json")" = "$CLAUDE_BYTES" ] && \
  [ "$(cat "$WORK/both/.cursor/hooks.json")" = "$CURSOR_BYTES" ]
check "H1d an existing .claude/ AND .cursor/ both get their shape" "$?"

# ---- H2: a vendor dir is never created ----------------------------------------------
seed "$WORK/none"
OUT2=$(write_install "$WORK/none"); RC2=$?
check "H2a --write with NO vendor dir exits 0 (got $RC2)" "$([ "$RC2" = 0 ] && echo 0 || echo 1)"
[ ! -e "$WORK/none/.claude" ] && [ ! -e "$WORK/none/.cursor" ]
check "H2b no .claude/ or .cursor/ was created" "$?"
[ ! -e "$WORK/none/.claude/hooks.json" ] && [ ! -e "$WORK/none/.cursor/hooks.json" ]
check "H2c no hook file anywhere" "$?"
printf '%s' "$OUT2" | grep -q "no .claude/ or .cursor/ directory"
check "H2d the absence is named out loud, not silent" "$?"

# ---- H3: the hash record --------------------------------------------------------------
[ -f "$WORK/claude/.gob/manifest/hooks.tsv" ]
check "H3a the hash record exists next to the mcp preimage clause" "$?"
awk -F'\t' 'NR>1 && $1=="claude" && $2==".claude/hooks.json" && $3!="" {ok=1} END{exit !ok}' \
  "$WORK/claude/.gob/manifest/hooks.tsv"
check "H3b the record names the vendor, the file, and a sha256" "$?"
REC_SHA=$(awk -F'\t' '$1=="claude" && $2==".claude/hooks.json" {print $3}' "$WORK/claude/.gob/manifest/hooks.tsv")
[ "$REC_SHA" = "$(sha256sum "$WORK/claude/.claude/hooks.json" | awk '{print $1}')" ]
check "H3c the recorded hash IS the file-on-disk's sha256" "$?"

# ---- H4: a second write is idempotent --------------------------------------------------
OUT3=$(write_install "$WORK/claude")
check "H4a the second --write exits 0" "$?"
[ "$(cat "$WORK/claude/.claude/hooks.json")" = "$CLAUDE_BYTES" ]
check "H4b the bytes are unchanged (idempotent)" "$?"
printf '%s' "$OUT3" | grep -q "already carries the generated hooks"
check "H4c the repeat is a named no-op" "$?"
[ "$(awk 'END{print NR}' "$WORK/claude/.gob/manifest/hooks.tsv")" = "2" ]
check "H4d the record still has exactly one data row" "$?"

# ---- H5: uninstall removes ONLY the hash-identical hook --------------------------------
# H5 first proves the positive removal on the H4 tree (record + identical file).
seed "$WORK/unin"; mkdir -p "$WORK/unin/.claude" "$WORK/unin/.cursor"
write_install "$WORK/unin" >/dev/null 2>&1
( cd "$WORK/unin" && bash "$SRC/bin/goblin-install" --target . --uninstall ) >"$WORK/unin.out" 2>&1
[ ! -e "$WORK/unin/.claude/hooks.json" ] && [ ! -e "$WORK/unin/.cursor/hooks.json" ]
check "H5a uninstall removes the hash-identical hooks" "$?"
[ ! -e "$WORK/unin/.gob/manifest/hooks.tsv" ]
check "H5b and the hook record goes with them" "$?"
grep -q "removed .claude/hooks.json" "$WORK/unin.out" && grep -q "removed .cursor/hooks.json" "$WORK/unin.out"
check "H5c the removals are named per vendor" "$?"

# ---- H6: uninstall REFUSES a modified hook ---------------------------------------------
seed "$WORK/mod"; mkdir -p "$WORK/mod/.claude"
write_install "$WORK/mod" >/dev/null 2>&1
printf '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo mine"}]}]}}' \
  > "$WORK/mod/.claude/hooks.json"
( cd "$WORK/mod" && bash "$SRC/bin/goblin-install" --target . --uninstall ) >"$WORK/mod.out" 2>&1; RC6=$?
check "H6a uninstall with a modified hook exits 0 (it is not a failure, it is a keep)" "$([ "$RC6" = 0 ] && echo 0 || echo 1)"
[ "$(cat "$WORK/mod/.claude/hooks.json")" = '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo mine"}]}]}}' ]
check "H6b the modified hook is untouched on disk" "$?"
grep -q "kept .claude/hooks.json (not the recorded bytes: a hook you customized stays)" "$WORK/mod.out"
check "H6c the keep is named with the reason" "$?"
grep -q "removed .gob/manifest/hooks.tsv" "$WORK/mod.out"
check "H6d the record still goes (it is goblin-stack's own file)" "$?"

# ---- H7: --with-mcp-config is a real opt-in --------------------------------------------
[ ! -e "$WORK/claude/.mcp.json" ] && [ ! -e "$WORK/none/.mcp.json" ]
check "H7a the default --write writes NO .mcp.json (the named removal)" "$?"
seed "$WORK/mcp"
OUT7=$(write_install "$WORK/mcp" --with-mcp-config)
[ "$(cat "$WORK/mcp/.mcp.json")" = "$MCP_BYTES" ]
check "H7b --with-mcp-config writes the generated registration" "$?"
OUT8=$(write_install "$WORK/mcp" --with-mcp-config)
printf '%s' "$OUT8" | grep -q "already carries the generated registration"
check "H7c a second run is the named no-op" "$?"
printf '{"mcpServers":{"gob":{"command":"node","args":["/team/own/gob.js"]}}}' > "$WORK/mcp/.mcp.json"
OUT9=$(write_install "$WORK/mcp" --with-mcp-config)
[ "$(cat "$WORK/mcp/.mcp.json")" = '{"mcpServers":{"gob":{"command":"node","args":["/team/own/gob.js"]}}}' ]
check "H7d a customized registration is never overwritten" "$?"
( cd "$WORK/mcp" && bash "$SRC/bin/goblin-install" --target . --uninstall ) >"$WORK/mcp.out" 2>&1
[ "$(cat "$WORK/mcp/.mcp.json")" = '{"mcpServers":{"gob":{"command":"node","args":["/team/own/gob.js"]}}}' ]
check "H7e uninstall keeps a customized registration too" "$?"

if [ "$fail" -eq 0 ]; then note "t-hooks: PASS"; else note "t-hooks: FAIL"; fi
exit "$fail"
