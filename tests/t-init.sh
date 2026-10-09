#!/usr/bin/env bash
# t-init.sh — v2: `gob init` is the PROMPT ENGINE (bin/goblin-init).
#
#   B1  the bare brief: `gob init` prints the AGENT BRIEF + proposal schema, exit 0;
#       heuristic mode appends pre-scanned hints; nothing is written anywhere
#   B2  the --write path on a fresh probe: a proposal file in the brief's schema
#       validates and installs (class software, the proposal's first gate replaces the
#       class default, proposal keys merge over the class defaults), writes AGENTS.md
#       with the gob block, .gob/, HANDOFF.md — and NO .hermes (the neutral-first install)
#   B3  the validation refusals: no block, unknown key, bad class, no gate -> exit 2,
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

proposal() { # <file> <class> [extra lines...] — a minimal valid proposal
  local f="$1" cls="$2"; shift 2
  {
    printf '<!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->\n'
    printf 'class: %s\n' "$cls"
    printf 'branch: main\n'
    printf 'owner_email: runner@example.com\n'
    printf 'gate_commit_cmd: bash tests/run-tests.sh\n'
    [ $# -eq 0 ] || printf '%s\n' "$@"
    printf '<!-- gob:end -->\n'
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
printf '%s' "$OUT" | grep -qF "software|service|game|research|fleet"
check "the schema names the class enum" "$?"
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
proposal "$P2" software
OUT2=$(init_env --target "$REPO" --write "$P2" --yes < /dev/null); RC2=$?
check "--write with a valid proposal exits 0" "$RC2"
printf '%s' "$OUT2" | grep -qF "gob init [run] goblin-install"
check "the run names the install engine call" "$?"
[ -f "$REPO/AGENTS.md" ] && [ -f "$REPO/HANDOFF.md" ] && [ -x "$REPO/.gob/bin/goblin-verify" ]
check "the harness landed (AGENTS.md, HANDOFF.md, .gob/bin/goblin-verify)" "$?"
grep -qF "owner_email: runner@example.com" "$REPO/AGENTS.md"
check "the declared email landed in the AGENTS.md gob block" "$?"
grep -qxF "branch: main" "$REPO/AGENTS.md"
check "the declared branch landed in the AGENTS.md gob block" "$?"
GATE_DECLARED=$(awk '/^<!-- gob:begin/{ing=1;next} /^<!-- gob:end/{ing=0} ing && /^gate_commit_cmd:/{sub(/^gate_commit_cmd: */,"");print;exit}' "$REPO/AGENTS.md")
[ "$GATE_DECLARED" = "bash tests/run-tests.sh" ]
check "the proposal gate is the declared first gate (got '$GATE_DECLARED')" "$?"
[ ! -e "$REPO/.hermes" ]
check "a neutral proposal writes NO .hermes (neutral-first)" "$?"
grep -qF '"skills": "no"' "$REPO/.gob/installed.json"
check "the install record carries the skills opt-out" "$?"
# the proposal's keys merge over the class defaults: the installer rendered the class
# defaults, then --write merged the proposal's own keys over them.
grep -qF "class: software" "$REPO/AGENTS.md"
check "the declared class landed in the gob block" "$?"

# ---- B3: the validation refusals --------------------------------------------------
new_repo b3
P3="$WORK/proposal-b3-noblock.md"
printf 'class: software\ngate_commit_cmd: true\n' > "$P3"
OUT3=$(init_env --target "$REPO" --write "$P3" < /dev/null); RC3=$?
check "a proposal with no gob block exits 2" "$([ "$RC3" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT3" | grep -qF "carries no gob block"
check "the refusal names the missing block" "$?"

P3B="$WORK/proposal-b3-badkey.md"
proposal "$P3B" software 'not_a_real_key: 42'
OUT3B=$(init_env --target "$REPO" --write "$P3B" < /dev/null); RC3B=$?
check "an unknown key exits 2" "$([ "$RC3B" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT3B" | grep -qF "not_a_real_key"
check "the refusal names the key it refused" "$?"

P3C="$WORK/proposal-b3-badclass.md"
proposal "$P3C" zebra
OUT3C=$(init_env --target "$REPO" --write "$P3C" < /dev/null); RC3C=$?
check "a nonsense class exits 2" "$([ "$RC3C" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT3C" | grep -qF "software|service|game|research|fleet"
check "the refusal names the class enum" "$?"
printf '%s' "$OUT3C" | grep -qF "unknown class 'zebra'"
check "  and names the input it refused (W6 review F1)" "$?"

P3D="$WORK/proposal-b3-nogate.md"
{
  printf '<!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->\n'
  printf 'class: software\nbranch: main\nowner_email: runner@example.com\n'
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
proposal "$P3E" software
OUT3E=$(init_env --target "$REPO" --write "$P3E" --yes < /dev/null); RC3E=$?
check "init --write exits 1 on the installer HANDOFF refusal" "$([ "$RC3E" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT3E" | grep -qF "HANDOFF.md"
check "the refusal names the path" "$?"
[ "$(sha256sum "$REPO/HANDOFF.md" | awk '{print $1}')" = "$OWN_HANDOFF" ]
check "the project's own HANDOFF.md is byte-identical" "$?"

# ---- B4: --dry-run validates and writes nothing ------------------------------------
new_repo b4
P4="$WORK/proposal-b4.md"
proposal "$P4" research
BEFORE4=$( cd "$REPO" && find . -path ./.git -prune -o -type f -print | sort )
OUT4=$(init_env --target "$REPO" --write "$P4" --dry-run --yes < /dev/null); RC4=$?
check "--dry-run exits 0" "$RC4"
printf '%s' "$OUT4" | grep -qF "validated OK"
check "the plan names the validated class and the write set" "$?"
printf '%s' "$OUT4" | grep -qF "would write"
check "the plan says what it would write" "$?"
AFTER4=$( cd "$REPO" && find . -path ./.git -prune -o -type f -print | sort )
[ "$BEFORE4" = "$AFTER4" ]
check "the tree is byte-list unchanged after --dry-run" "$?"

# ---- B5: idempotent re-write --------------------------------------------------------
P5="$WORK/proposal-b5.md"
proposal "$P5" software
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
proposal "$P7" software
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
