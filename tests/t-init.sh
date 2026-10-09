#!/usr/bin/env bash
# t-init.sh — v2: `gob init` is the PROMPT ENGINE (bin/goblin-init).
#
#   B1  the bare brief: `gob init` prints the AGENT BRIEF + proposal schema, exit 0;
#       heuristic mode appends pre-scanned hints; nothing is written anywhere
#   B2  the --write path on a fresh probe: a proposal file in the brief's schema
#       validates and installs (the proposal's first gate replaces the default, proposal
#       keys merge over the installer's defaults), writes AGENTS.md
#       with the gob block, .gob/, HANDOFF.md — and NO .hermes (the neutral-first install)
#   B3  the validation refusals: no block, unknown key, no gate -> exit 2,
#       nothing written; a refusal names the input it refused
#   B4  --dry-run validates and writes nothing
#   B5  idempotent re-`--write`: the second identical write is the installer's no-op
#   B6  the shim: `goblin.js init --help` reaches the engine usage; `gob init` (bare)
#       prints the brief
#   B7  the post-install GREEN line: after the day-one commit the probe verifies at the
#       measured green line
#   B8  the source gates (moved here from the deleted t8 pty family, still relevant):
#       {C_ token, unbraced-colour-var-adjacent-to-multibyte, bare sed -i
#
# Every fixture lives in a mktemp sandbox with HOME pointed inside it — no test writes
# the real $HOME. The PATH is stripped to the system dirs so the host's own hermes
# binary cannot leak a DETECTED verdict into the sandbox. Run by tests/run-tests.sh.
#
# PIPEFAIL RULE (the t-doctor precedent): never pipe a possibly-failing producer into an
# assertion — capture first, assert on the captured bytes.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }
KEEP=0; [ "${GOB_TEST_KEEP:-}" = 1 ] && KEEP=1
trap '[ "$KEEP" -eq 1 ] || rm -rf "$WORK"' EXIT

INIT="bash $SRC/bin/goblin-init"
BARE_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
mkdir -p "$WORK/home"

new_repo() { # <tag> — a seeded git repo with a real, green gate script
  REPO="$WORK/$1"
  mkdir -p "$REPO/tests"
  ( cd "$REPO" && git init -q -b main && git config user.name "Test Runner" \
      && git config user.email "runner@example.com" \
      && printf '# probe\n' > README.md \
      && printf '#!/usr/bin/env bash\n# the probe gate: real, fast, green\nexit 0\n' > tests/run-tests.sh \
      && chmod +x tests/run-tests.sh \
      && git add -A && git commit -q -m "chore: seed" )
}

init_env() { # the engine's environment: sandbox HOME, no host anchors, no tty on stdin
  { env HOME="$WORK/home" PATH="$BARE_PATH" \
        timeout 120 bash "$SRC/bin/goblin-init" "$@"; } 2>&1
}

proposal() { # <file> [extra lines...] — a minimal valid proposal (with a feature map)
  local f="$1"; shift 1
  {
    printf '<!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->\n'
    printf 'gate_commit_cmd: bash tests/run-tests.sh\n'
    printf 'feature_map: features/README.md\n'
    [ $# -eq 0 ] || printf '%s\n' "$@"
    printf '<!-- gob:end -->\n'
    printf '\n## gob init summary\n\n- the probe: one real gate, a one-feature map\n'
    map_block
  } > "$f"
}

map_block() { # the `## feature-map` half every proposal now carries
  cat <<'MAPEOF'
## feature-map

### features/README.md

```md
# Features

- [readme](./readme.md) — the probe README
```

### features/readme.md

```md
---
feature: readme
entry_paths:
  - README.md
verified: never-driven (2024-01-01)
---
# readme

The probe repository's README.

## Sub-features

- the readme file

## How to get to it (user POV)

- open the repository root

## Driving it with bash

Preconditions: a checkout.
**Read.** Run `cat README.md`. The file prints.

## Gotchas

- nothing has been driven yet; the verified line says so.
```
MAPEOF
}

proposal_gate() { # <file> <gate-cmd> — a valid proposal with a chosen gate command
  local f="$1" gate="$2"
  {
    printf '<!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->\n'
    printf 'gate_commit_cmd: %s\n' "$gate"
    printf 'feature_map: features/README.md\n'
    printf '<!-- gob:end -->\n'
    printf '\n## gob init summary\n\n- the probe with a chosen gate\n'
    map_block
  } > "$f"
}

# ---- B1: the bare brief --------------------------------------------------------
new_repo b1
OUT=$(init_env --target "$REPO" < /dev/null); RC=$?
check "the bare brief exits 0" "$RC"
printf '%s' "$OUT" | grep -qF "AGENT BRIEF"
check "the brief names itself (AGENT BRIEF)" "$?"
printf '%s' "$OUT" | grep -qF "PROPOSAL SCHEMA"
check "the brief carries the proposal schema" "$?"
printf '%s' "$OUT" | grep -qF "gate_commit_cmd"
check "the schema names the gate key the reader parses" "$?"
B1_FILES=$( cd "$REPO" && find . -path ./.git -prune -o -type f -print | sort )
[ "$B1_FILES" = "./README.md"$'\n'"./tests/run-tests.sh" ]
check "a bare brief writes NOTHING into the target" "$?"

OUTH=$(init_env --target "$REPO" --heuristic < /dev/null); RCH=$?
check "--heuristic exits 0" "$RCH"
printf '%s' "$OUTH" | grep -qF "heuristic hints"
check "the heuristic fallback appends its hints section" "$?"
printf '%s' "$OUTH" | grep -qF "PROPOSAL SCHEMA"
check "the heuristic brief still carries the schema" "$?"

# ---- B2: the --write path --------------------------------------------------------
new_repo b2
P2="$WORK/proposal-b2.md"
proposal "$P2"
OUT2=$(init_env --target "$REPO" --write "$P2" --yes < /dev/null); RC2=$?
check "--write with a valid proposal exits 0" "$RC2"
printf '%s' "$OUT2" | grep -qF "gob init [run] goblin-install"
check "the run names the install engine call" "$?"
[ -f "$REPO/AGENTS.md" ] && [ -f "$REPO/HANDOFF.md" ] && [ -x "$REPO/.gob/bin/goblin-verify" ]
check "the harness landed (AGENTS.md, HANDOFF.md, .gob/bin/goblin-verify)" "$?"
GATE_DECLARED=$(awk '/^<!-- gob:begin/{ing=1;next} /^<!-- gob:end/{ing=0} ing && /^gate_commit_cmd:/{sub(/^gate_commit_cmd: */,"");print;exit}' "$REPO/AGENTS.md")
[ "$GATE_DECLARED" = "bash tests/run-tests.sh" ]
check "the proposal gate is the declared first gate (got '$GATE_DECLARED')" "$?"
[ ! -e "$REPO/.hermes" ]
check "a neutral proposal writes NO .hermes (neutral-first)" "$?"
grep -qF '"skills": "no"' "$REPO/.gob/installed.json"
check "the install record carries the skills opt-out" "$?"
# the proposal's keys merge over the installer defaults: the installer rendered its
# defaults, then --write merged the proposal's own keys over them.
grep -qxF "feature_map: features/README.md" "$REPO/AGENTS.md"
check "feature_map landed in the AGENTS.md gob block" "$?"
[ -f "$REPO/features/README.md" ] && [ -f "$REPO/features/readme.md" ]
check "the embedded feature map was materialised at features/ (index + readme.md)" "$?"
printf '%s' "$OUT2" | grep -qF "measured exit code: 0"
check "the declared gate was RUN and its exit code printed" "$?"

# ---- B2b: the gate is RUN, not guessed (P7) ----------------------------------------
# A command that CANNOT be run at all is not a gate: refuse, write nothing. A command that
# RUNS and exits non-zero is a legitimate day-one red: accept it and install.
new_repo b2b
# (a) a gate command that does not exist
P2B="$WORK/proposal-b2b-badgate.md"
proposal_gate "$P2B" "no-such-command-xyz-42"
OUT2B=$(init_env --target "$REPO" --write "$P2B" < /dev/null); RC2B=$?
check "a proposal whose gate command does not exist exits 2" "$([ "$RC2B" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT2B" | grep -qF "exit 127"
check "the refusal names the exit-127 not-found" "$?"
printf '%s' "$OUT2B" | grep -qF "no-such-command-xyz-42"
check "  and names the command it could not run" "$?"
[ ! -e "$REPO/AGENTS.md" ] && [ ! -e "$REPO/features" ]
check "  and it wrote NOTHING" "$?"

# (b) a gate that RUNS and exits 1: accepted, installed, and the measured code is printed
P2C="$WORK/proposal-b2c-redgate.md"
proposal_gate "$P2C" "bash tests/red.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$REPO/tests/red.sh"
chmod +x "$REPO/tests/red.sh"
OUT2C=$(init_env --target "$REPO" --write "$P2C" --yes < /dev/null); RC2C=$?
check "a gate that exits 1 is ACCEPTED (exit 0, installed)" "$([ "$RC2C" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT2C" | grep -qF "measured exit code: 1"
check "  and the measured exit code is printed (1)" "$?"
[ -x "$REPO/.gob/bin/goblin-verify" ] && [ -f "$REPO/features/README.md" ]
check "  and the harness + map were installed" "$?"

# (c) --dry-run must NOT execute the gate
P2D="$WORK/proposal-b2d-dry.md"
proposal_gate "$P2D" "bash tests/sideeffect.sh"
printf '#!/usr/bin/env bash\ntouch "$(dirname "$0")/RAN"\n' > "$REPO/tests/sideeffect.sh"
chmod +x "$REPO/tests/sideeffect.sh"
OUT2D=$(init_env --target "$REPO" --write "$P2D" --dry-run --yes < /dev/null); RC2D=$?
check "--dry-run on a gate that would run exits 0" "$([ "$RC2D" -eq 0 ] && echo 0 || echo 1)"
[ ! -e "$REPO/tests/RAN" ]
check "  and the gate was NOT executed (no side-effect file)" "$?"

# ---- B3: the validation refusals --------------------------------------------------
new_repo b3
P3="$WORK/proposal-b3-noblock.md"
printf 'class: software\ngate_commit_cmd: true\n' > "$P3"
OUT3=$(init_env --target "$REPO" --write "$P3" < /dev/null); RC3=$?
check "a proposal with no gob block exits 2" "$([ "$RC3" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT3" | grep -qF "carries no gob block"
check "the refusal names the missing block" "$?"

P3B="$WORK/proposal-b3-badkey.md"
proposal "$P3B" 'not_a_real_key: 42'
OUT3B=$(init_env --target "$REPO" --write "$P3B" < /dev/null); RC3B=$?
check "an unknown key exits 2" "$([ "$RC3B" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT3B" | grep -qF "not_a_real_key"
check "the refusal names the key it refused" "$?"

P3D="$WORK/proposal-b3-nogate.md"
{
  printf '<!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->\n'
  printf 'archive: false\n'
  printf '<!-- gob:end -->\n'
} > "$P3D"
OUT3D=$(init_env --target "$REPO" --write "$P3D" < /dev/null); RC3D=$?
check "a proposal with no gate exits 2" "$([ "$RC3D" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT3D" | grep -qF "declares no gate"
check "the refusal names the missing gate" "$?"
BEFORE3=$( cd "$REPO" && find . -path ./.git -prune -o -type f -print | sort )
check "every refusal wrote nothing (no AGENTS.md, no .gob/)" \
  "$([ ! -e "$REPO/AGENTS.md" ] && [ ! -e "$REPO/.gob" ] && echo 0 || echo 1)"

# ---- B3b: the installer's own refusal contract through --write --------------------
new_repo b3b
printf '# my own handoff, written before goblin ever saw this repo\n' > "$REPO/HANDOFF.md"
OWN_HANDOFF=$(sha256sum "$REPO/HANDOFF.md" | awk '{print $1}')
P3E="$WORK/proposal-b3e.md"
proposal "$P3E"
OUT3E=$(init_env --target "$REPO" --write "$P3E" --yes < /dev/null); RC3E=$?
check "init --write exits 1 on the installer HANDOFF refusal" "$([ "$RC3E" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT3E" | grep -qF "HANDOFF.md"
check "the refusal names the path" "$?"
[ "$(sha256sum "$REPO/HANDOFF.md" | awk '{print $1}')" = "$OWN_HANDOFF" ]
check "the project's own HANDOFF.md is byte-identical" "$?"

# ---- B3c: one proposal, one pass — the feature map is REQUIRED and validated --------
# (folded from the deleted t-map.sh: the map is no longer made by a standalone verb; it is
# validated inside `gob init --write`, in the same pass as the config block.)
new_repo b3c
# (a) no feature_map key at all
P3F="$WORK/proposal-b3f-nomap.md"
{
  printf '<!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->\n'
  printf 'gate_commit_cmd: bash tests/run-tests.sh\n'
  printf '<!-- gob:end -->\n\n## gob init summary\n\n- no map\n'
} > "$P3F"
OUT3F=$(init_env --target "$REPO" --write "$P3F" < /dev/null); RC3F=$?
check "a proposal with no feature_map exits 2" "$([ "$RC3F" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT3F" | grep -qF "declares no feature_map"
check "the refusal names feature_map as the missing key" "$?"
[ ! -e "$REPO/AGENTS.md" ] && [ ! -e "$REPO/.gob" ] && [ ! -e "$REPO/features" ]
check "  and it wrote NOTHING" "$?"

# (b) feature_map declared, but the `## feature-map` section is absent
P3G="$WORK/proposal-b3g-nosection.md"
{
  printf '<!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->\n'
  printf 'gate_commit_cmd: bash tests/run-tests.sh\nfeature_map: features/README.md\n'
  printf '<!-- gob:end -->\n'
} > "$P3G"
OUT3G=$(init_env --target "$REPO" --write "$P3G" < /dev/null); RC3G=$?
check "a proposal with feature_map but no feature-map section exits 2" "$([ "$RC3G" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT3G" | grep -qF "feature-map blocks"
check "the refusal names the missing section" "$?"
[ ! -e "$REPO/AGENTS.md" ] && [ ! -e "$REPO/features" ]
check "  and it wrote NOTHING" "$?"

# (c) a map whose entry path does not resolve (FM-02 at write time)
P3H="$WORK/proposal-b3h-badpath.md"
{
  printf '<!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->\n'
  printf 'gate_commit_cmd: bash tests/run-tests.sh\nfeature_map: features/README.md\n'
  printf '<!-- gob:end -->\n\n## gob init summary\n\n- a broken entry path\n\n## feature-map\n\n'
  printf '### features/README.md\n\n```md\n# Features\n\n- [ghost](./ghost.md) — a feature that does not resolve\n```\n\n'
  printf '### features/ghost.md\n\n```md\n---\nfeature: ghost\nentry_paths:\n  - does-not-exist.ts\nverified: never-driven (2024-01-01)\n---\n'
  printf '# ghost\n\nA feature whose entry path is not committed.\n\n## Sub-features\n\n- x\n\n## How to get to it (user POV)\n\n- x\n\n## Driving it with bash\n\nRun `true`.\n\n## Gotchas\n\n- x\n```\n'
} > "$P3H"
OUT3H=$(init_env --target "$REPO" --write "$P3H" < /dev/null); RC3H=$?
check "a map with an unresolvable entry path exits 2" "$([ "$RC3H" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT3H" | grep -qF "does-not-exist.ts"
check "the refusal names the entry path that does not resolve" "$?"
[ ! -e "$REPO/AGENTS.md" ] && [ ! -e "$REPO/features" ]
check "  and it wrote NOTHING" "$?"

# (d) an empty repo (no committed file to map) refuses with the named remedy
EMPTY="$WORK/b3c-empty"
mkdir -p "$EMPTY"
( cd "$EMPTY" && git init -q -b main && git config user.name "Test Runner" && git config user.email runner@example.com ) >/dev/null 2>&1
P3I="$WORK/proposal-b3i.md"
proposal "$P3I"
OUT3I=$(init_env --target "$EMPTY" --write "$P3I" < /dev/null); RC3I=$?
check "an empty repo (no committed file) exits 2" "$([ "$RC3I" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT3I" | grep -qF "commit at least one file, then run again"
check "the refusal names the remedy" "$?"
[ "$( cd "$EMPTY" && find . -path ./.git -prune -o -type f -print )" = "" ]
check "  and it invented no bootstrap feature" "$?"

# ---- B4: --dry-run validates and writes nothing ------------------------------------
new_repo b4
P4="$WORK/proposal-b4.md"
proposal "$P4"
BEFORE4=$( cd "$REPO" && find . -path ./.git -prune -o -type f -print | sort )
OUT4=$(init_env --target "$REPO" --write "$P4" --dry-run --yes < /dev/null); RC4=$?
check "--dry-run exits 0" "$RC4"
printf '%s' "$OUT4" | grep -qF "validated OK"
check "the plan names the validated proposal and the write set" "$?"
printf '%s' "$OUT4" | grep -qF "would write"
check "the plan says what it would write" "$?"
AFTER4=$( cd "$REPO" && find . -path ./.git -prune -o -type f -print | sort )
[ "$BEFORE4" = "$AFTER4" ]
check "the tree is byte-list unchanged after --dry-run" "$?"

# ---- B5: idempotent re-write --------------------------------------------------------
P5="$WORK/proposal-b5.md"
proposal "$P5"
init_env --target "$WORK/b2" --write "$P5" --yes < /dev/null >/dev/null 2>&1
OUT5=$(init_env --target "$WORK/b2" --write "$P5" --yes < /dev/null); RC5=$?
check "the identical re-write exits 0" "$RC5"
printf '%s' "$OUT5" | grep -qE "no-op: .* unchanged"
check "the re-write is the installer's no-op" "$?"

# ---- B6: the shim routes ---------------------------------------------------------------
OUT9=$( cd "$WORK" && env PATH="$BARE_PATH:$HOME/.local/bin" node "$SRC/bin/goblin.js" init --help 2>&1 ); RC9=$?
check "the npm shim routes init to goblin-init" "$RC9"
printf '%s' "$OUT9" | grep -qF "gob init"
check "the shim run reaches the engine's usage" "$?"

# ---- B7: the post-install GREEN line ----------------------------------------------------
new_repo b7
P7="$WORK/proposal-b7.md"
proposal "$P7"
init_env --target "$REPO" --write "$P7" --yes < /dev/null >/dev/null 2>&1
( cd "$REPO" && git add -A && git commit -q -m "chore: install gobstack via gob init --write" )
VOUT=$( cd "$REPO" && env PATH="$BARE_PATH" bash .gob/bin/goblin-verify 2>&1 ); VRC=$?
check "verify exits 0 after the commit" "$VRC"
printf '%s' "$VOUT" | grep -qE '[0-9]+ passed, 0 failed'
check "verify reports 0 failed" "$?"

# ---- B8: the source gates (from the deleted t8 pty family, still relevant) ----------
# The class of bug these guard is visible in the SOURCE; the pty was only where the
# symptoms showed. Each has a positive control proving the pattern still bites.
printf 'x="{C_BAD} a planted unbraced token"\n' > "$WORK/gate-probe.txt"
grep -qE '(^|[^$])\{C_' "$WORK/gate-probe.txt"
check "the {C_ gate pattern catches a planted violation (positive control)" "$?"
grep -qE '(^|[^$])\{C_' "$SRC/bin/goblin-init"
check "bin/goblin-init carries zero {C_ not preceded by a dollar" "$([ $? -ne 0 ] && echo 0 || echo 1)"
printf '$C_GREEN✔ ok\n' > "$WORK/mb-probe.txt"
grep -qP '\$C_[A-Z_]+[^\x00-\x7F]' "$WORK/mb-probe.txt"
check "the unbraced-colour-var pattern catches a planted violation (positive control)" "$?"
! grep -nP '\$C_[A-Z_]+[^\x00-\x7F]' "$SRC/bin/goblin-init"
check "no unbraced colour var adjacent to a multibyte glyph (T8c)" "$?"
BARE=$(for f in "$SRC"/bin/*; do
           [ -f "$f" ] || continue
           awk '
             /^g_sed_i\(\) \{/ { inhelper = 1 }
             inhelper && /^\}/ { inhelper = 0; next }
             inhelper { next }
             /sed -i/ && $0 !~ /^[[:space:]]*#/ { print FILENAME ":" FNR }
           ' "$f"
         done \
         | grep -c 'sed -i' | tr -d ' ')
check "no bare sed -i outside g_sed_i (T8d, found: $BARE)" "$([ "$BARE" -eq 0 ] && echo 0 || echo 1)"
grep -q 'g_sed_i()' "$SRC/bin/goblin-lib.sh"
check "the g_sed_i helper exists in goblin-lib (T8d)" "$?"

if [ "$fail" -eq 0 ]; then
  printf 't-init: ok\n'
else
  printf 't-init: FAIL\n'
fi
exit "$fail"
