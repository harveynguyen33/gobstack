#!/usr/bin/env bash
# t-init.sh — W6: the first-run wizard (bin/goblin-init).
#
#   T1  non-interactive flags-only end to end on a fresh probe: gob init --class app
#       --branch main --email ... --gate 'bash tests/run-tests.sh' --emit hermes
#       --scope project --yes installs, patches the declared identity and the gate into
#       .goblin/goblin.yaml (read back through g_yaml_gates), emits hermes project-scope,
#       runs verify; a commit later the probe verifies GREEN (the measured fresh path)
#   T2  no TTY hang: every prompt site is guarded on [ -t 0 ]; a piped run with NO flags
#       at all still finishes (timeout-bounded) on defaults, exit 0
#   T3  the refusal contract: an existing HANDOFF.md is kept byte-identical, install's
#       exit-1 stops the wizard before any emit, no .goblin/ is written
#   T4  --dry-run prints the plan (class, emit platforms) and writes nothing (tree cmp)
#   T5  idempotent re-run: the second identical run is the installer's no-op, exit 0
#   T6  bad input: unknown --emit platform and a nonsense --class exit 2 naming the enum
#   T7  the dispatcher: `bin/goblin init` routes to goblin-init; `bin/goblin.js init`
#       reaches the same script; `gob init --help` exits 0
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
trap 'rm -rf "$WORK"' EXIT

INIT="bash $SRC/bin/goblin-init"
BARE_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export GOBLIN_EMISSIONS="$WORK/.goblin-stack/emissions.tsv"
export GOBLIN_PREIMAGES="$WORK/.goblin-stack/preimages"
mkdir -p "$WORK/home"

printf 'profiles:\n  coder:\n    model: model-code\n    provider: prov-code\n    effort: low\n' > "$WORK/models.yaml"
printf 'the referenced standard\n' > "$WORK/standard.md"

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

init_env() { # the wizard's environment: sandbox HOME, no host anchors, no tty on stdin
  # (bash is named HERE, not via $INIT: env does not word-split, and "bash <path>" as
  # one program name is a file-not-found every run — measured by this test's first draft)
  { env HOME="$WORK/home" \
        GOBLIN_MODELS="$WORK/models.yaml" \
        GOBLIN_PRACTICE="$WORK/standard.md" \
        PATH="$BARE_PATH" \
        timeout 120 bash "$SRC/bin/goblin-init" "$@"; } 2>&1
}

# ---- T1: flags-only end to end, then GREEN after the commit --------------------
new_repo t1
OUT=$(init_env --target "$REPO" --class app --branch main --email "runner@example.com" \
        --gate "bash tests/run-tests.sh" --emit hermes --scope project --yes \
        < /dev/null 2>&1); RC=$?
check "flags-only init exits 0" "$RC"
grep -qF "gob init [run] goblin-install" <<<"$OUT"
check "the run names the install engine call" "$?"
grep -qF "gob init [run] goblin-emit --platform hermes --scope project" <<<"$OUT"
check "the run names the emit engine call" "$?"
grep -qF "gob init [verify]" <<<"$OUT"
check "the run reaches the verify step" "$?"
grep -qF "owner_email: runner@example.com" "$REPO/.goblin/goblin.yaml"
check "the declared email landed in the config" "$?"
grep -qxF "branch: main" "$REPO/.goblin/goblin.yaml"
check "the declared branch landed in the config" "$?"
GATE_DECLARED=$(bash "$SRC/bin/goblin-lib.sh" --version >/dev/null 2>&1; \
  bash -c '. "$0" 2>/dev/null' /dev/null; \
  awk '/^gates:/{ing=1;next} ing && /^    cmd:/{sub(/^    cmd: */,"");print;exit}' "$REPO/.goblin/goblin.yaml")
[ "$GATE_DECLARED" = "bash tests/run-tests.sh" ]
check "the --gate command is the declared first gate (got '$GATE_DECLARED')" "$?"
[ -f "$REPO/.hermes/skills/goblin-mode/SKILL.md" ]
check "hermes project emission exists under the target" "$?"
[ -f "$REPO/CLAUDE.md" ] && { check "no claude context block without --emit claude" 1; } \
                         || { check "no claude context block without --emit claude" 0; }
# the wizard is a front end over install: the installer's own record must exist
[ -f "$REPO/.goblin/installed.json" ]
check "the install record exists (the wizard wrote nothing it did not route)" "$?"
# commit, then GREEN: the measured fresh path (43 passed, 0 failed — T1 emitted hermes, so the
# skills are present and hashed; the DEFAULT install's own green line is T2b below)
( cd "$REPO" && git add -A && git commit -q -m "chore: install gobstack via gob init" )
VOUT=$( cd "$REPO" && env PATH="$BARE_PATH" bash .goblin/bin/goblin-verify 2>&1 ); VRC=$?
check "verify exits 0 after the commit" "$VRC"
printf '%s' "$VOUT" | grep -qE '[0-9]+ passed, 0 failed'
check "verify reports 0 failed" "$?"
# W6 neutral-first: the wizard's install leg passes --skills no explicitly — the opt-in is the
# emit screen, and the record must say so.
grep -qF '"skills": "no"' "$REPO/.goblin/installed.json"
check "the install record carries the skills opt-out (the emit screen is the opt-in)" "$?"

# ---- T2b: the DEFAULT install creates NO .hermes — the neutral-first contract ------
new_repo t2b
OUT2B=$(init_env --target "$REPO" --class app --branch main --email "runner@example.com" \
        --gate "bash tests/run-tests.sh" --yes \
        < /dev/null 2>&1); RC2B=$?
check "a flags-only run with no --emit (the default install) exits 0" "$RC2B"
[ ! -e "$REPO/.hermes" ]
check "  and writes NO .hermes directory (skills are opt-in, W6 neutral-first)" "$?"
[ -f "$REPO/HANDOFF.md" ] && [ -f "$REPO/AGENTS.md" ] && [ -f "$REPO/.goblin/goblin.yaml" ] \
  && [ -x "$REPO/.goblin/bin/goblin-verify" ] && [ -f "$REPO/.goblin/installed.json" ] \
  && [ -f "$REPO/.gitignore" ]
check "  and the neutral harness is complete (HANDOFF, AGENTS, .goblin, .gitignore)" "$?"
grep -qF '"skills": "no"' "$REPO/.goblin/installed.json"
check "  and the record says skills=no" "$?"
( cd "$REPO" && git add -A && git commit -q -m "chore: install gobstack (neutral default)" )
VOUT2B=$( cd "$REPO" && env PATH="$BARE_PATH" bash .goblin/bin/goblin-verify 2>&1 ); VRC2B=$?
check "  and the neutral install verifies green (exit 0)" "$VRC2B"
printf '%s' "$VOUT2B" | grep -qE '^ *38 passed, 0 failed, 11 advisory, 33 skipped'
check "  at the measured neutral green line (38/0/11/33)" "$?"
# the emitted hermes context block (AGENTS.md's emitted twin) must NOT be here either
grep -q 'gob emit' "$REPO/AGENTS.md"
check "  and AGENTS.md points at the opt-in (gob emit --platform <p>)" "$?"

# ---- T2: no TTY hang — zero flags, piped stdin ----------------------------------
new_repo t2
OUT2=$(init_env --target "$REPO" < /dev/null 2>&1); RC2=$?
check "a zero-flag piped run finishes (no prompt hang), exit 0" "$RC2"
grep -qF "gob init [3/6] class: software" <<<"$OUT2"
check "the cascade names the defaulted class" "$?"
grep -qF "owner_email: runner@example.com" "$REPO/.goblin/goblin.yaml"
check "the git identity became the declared email" "$?"
# W6 neutral-first: a zero-flag run (piped stdin, no detected platforms in the stripped-PATH
# sandbox) pre-ticks NOTHING and installs NO skills — the neutral harness only. The guided
# emit screen (a tty run) is the opt-in; T8's pty run below drives it with Enters.
[ ! -e "$REPO/.hermes" ]
check "a zero-flag run emits no skills and writes no .hermes (neutral default)" "$?"

# ---- T3: the refusal contract — an existing HANDOFF.md is never taken -----------
new_repo t3
printf '# my own handoff, written before goblin ever saw this repo\n' > "$REPO/HANDOFF.md"
OWN_HANDOFF=$(sha256sum "$REPO/HANDOFF.md" | awk '{print $1}')
OUT3=$(init_env --target "$REPO" --class app --branch main --email "runner@example.com" \
        --gate "bash tests/run-tests.sh" --emit hermes --yes \
        < /dev/null 2>&1); RC3=$?
check "init exits 1 on the installer's refusal" "$([ "$RC3" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT3" | grep -q "HANDOFF.md"
check "the refusal names the path" "$?"
[ "$(sha256sum "$REPO/HANDOFF.md" | awk '{print $1}')" = "$OWN_HANDOFF" ]
check "the project's own HANDOFF.md is byte-identical" "$?"
printf '%s' "$OUT3" | grep -qF "gob init [verify]"
NOT_VERIFY=$?
check "the wizard stopped at the refusal — no verify ran" "$([ "$NOT_VERIFY" -ne 0 ] && echo 0 || echo 1)"

# ---- T4: --dry-run prints the plan and writes nothing ---------------------------
new_repo t4
BEFORE=$( cd "$REPO" && find . -type f | sort )
OUT4=$(init_env --target "$REPO" --class research --branch trunk --email "a@b.c" \
        --gate "make check" --emit hermes --dry-run \
        < /dev/null 2>&1); RC4=$?
check "dry-run exits 0" "$RC4"
printf '%s' "$OUT4" | grep -qF "class       research"
check "the plan names the class" "$?"
printf '%s' "$OUT4" | grep -qF "(hermes)"
check "the plan names the emit platform" "$?"
printf '%s' "$OUT4" | grep -qF "writes nothing"
check "the plan says it writes nothing" "$?"
AFTER=$( cd "$REPO" && find . -type f | sort )
[ "$BEFORE" = "$AFTER" ]
check "the tree is byte-list unchanged after --dry-run" "$?"

# ---- T5: idempotent re-run -------------------------------------------------------
OUT5=$(init_env --target "$WORK/t1" --class app --branch main --email "runner@example.com" \
        --gate "bash tests/run-tests.sh" --emit hermes --scope project --yes \
        < /dev/null 2>&1); RC5=$?
check "the identical re-run exits 0" "$RC5"
printf '%s' "$OUT5" | grep -qE "no-op: .* unchanged"
check "the re-run is the installer's no-op" "$?"

# ---- T6: bad input names the enum ------------------------------------------------
OUT6=$(init_env --target "$WORK/t1" --class app --emit nosuch --yes < /dev/null 2>&1); RC6=$?
check "unknown --emit platform exits 2" "$([ "$RC6" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT6" | grep -q "unknown platform 'nosuch'"
check "the refusal names the platform and the enum" "$?"
OUT7=$(init_env --target "$WORK/t1" --class zebra --yes < /dev/null 2>&1); RC7=$?
check "a nonsense class exits 2" "$([ "$RC7" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT7" | grep -q "software|service|game|research|fleet"
check "the refusal names the class enum" "$?"
printf '%s' "$OUT7" | grep -q "got 'zebra'"
check "  and names the input it refused (W6 review F1)" "$?"

# ---- T7: the dispatcher routes ----------------------------------------------------
OUT8=$( cd "$WORK" && env PATH="$BARE_PATH" bash "$SRC/bin/goblin" init --help 2>&1 ); RC8=$?
check "gob init --help exits 0 through the dispatcher" "$RC8"
printf '%s' "$OUT8" | grep -q -- "--class"
check "the usage names the class flag" "$?"
OUT9=$( cd "$WORK" && node "$SRC/bin/goblin.js" init --help 2>&1 ); RC9=$?
check "the npm shim routes init to goblin-init" "$RC9"
printf '%s' "$OUT9" | grep -q -- "--class"
check "the shim run reaches the wizard's usage" "$?"

# ---- T8: the tty path, under script(1) — the pty screen a pipe cannot see ------------
# The redraw only exists on a tty: run the wizard through `script -qec` so it owns a
# pty, feed it Enters (every prompt defaults), then assert on the TYPESCRIPT bytes:
#   * no literal '{C_' token — the multibyte-adjacent brace bug this file fixed twice
#   * no 'unbound variable' — a ${C_X} that lost its braces' dollar shows up here first
#   * the redraw frame actually carries ✔ collapsed rows and the accent ◆
# Piped assertions cannot see this: with stdout a pipe the wizard is its cascade self.
if command -v script >/dev/null 2>&1; then
  new_repo t8
  TS="$WORK/t8.pty.txt"
  printf '\n\n\n\n\n\n\n\n' | env HOME="$WORK/home" \
      GOBLIN_MODELS="$WORK/models.yaml" \
      GOBLIN_PRACTICE="$WORK/standard.md" \
      PATH="$BARE_PATH" \
      timeout 120 script -qec "bash $SRC/bin/goblin-init --target $REPO --yes" "$TS" >/dev/null 2>&1
  RC10=$?
  check "the wizard finishes under a pty (script -qec), exit 0" "$RC10"
  grep -qF "{C_" "$TS"
  check "the pty transcript carries zero literal {C_ tokens" "$([ $? -ne 0 ] && echo 0 || echo 1)"
  grep -qF "unbound variable" "$TS"
  check "the pty transcript names no unbound variable" "$([ $? -ne 0 ] && echo 0 || echo 1)"
  grep -qF "invalid number" "$TS"
  check "the pty transcript has no printf arg-mismatch (invalid number)" "$([ $? -ne 0 ] && echo 0 || echo 1)"
  grep -q "✔ 1. platforms" "$TS"
  check "the tty rail shows the answered platforms row collapsed with its value" "$?"
  grep -qE "◆.+2\. class" "$TS"
  check "the tty rail marks the current step with the accent diamond" "$?"
  grep -q "✔ 2. class" "$TS"
  check "the tty rail shows class answered on the next screen" "$?"
  grep -qE "$(printf '\033')\[[0-9]+A" "$TS"
  check "the redraw moves the cursor only on a tty (cursor-up present in the typescript)" "$?"
else
  note "skip T8: script(1) not available — the pty screen cannot be exercised here"
fi

# ---- T9: the source gate — bin/goblin-init carries zero unbraced {C_ -----------------
# The class of bug this guards: a C_ colour var adjacent to a multibyte glyph must be
# braced ${C_X}; an unbraced {C_ next to ✔/◆/○ prints the literal token on the screen.
# The positive control proves the pattern still bites before the gate proves the tree
# is clean (the MD-01 control precedent).
printf 'x="{C_BAD} a planted unbraced token"\n' > "$WORK/gate-probe.txt"
grep -qE '(^|[^$])\{C_' "$WORK/gate-probe.txt"
check "the {C_ gate pattern catches a planted violation (positive control)" "$?"
grep -qE '(^|[^$])\{C_' "$SRC/bin/goblin-init"
check "bin/goblin-init carries zero {C_ not preceded by a dollar" "$([ $? -ne 0 ] && echo 0 || echo 1)"

if [ "$fail" -eq 0 ]; then
  printf 't-init: ok\n'
else
  printf 't-init: FAIL\n'
fi
exit "$fail"
