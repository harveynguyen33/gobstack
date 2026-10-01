#!/usr/bin/env bash
# t-init.sh — W6: the first-run wizard (bin/goblin-init).
#
#   T1  non-interactive flags-only end to end on a fresh probe: goblin init --class app
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
#       reaches the same script; `goblin init --help` exits 0
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
# commit, then GREEN: the measured fresh path (43 passed, 0 failed)
( cd "$REPO" && git add -A && git commit -q -m "chore: install goblin-stack via gob init" )
VOUT=$( cd "$REPO" && env PATH="$BARE_PATH" bash .goblin/bin/goblin-verify 2>&1 ); VRC=$?
check "verify exits 0 after the commit" "$VRC"
printf '%s' "$VOUT" | grep -qE '[0-9]+ passed, 0 failed'
check "verify reports 0 failed" "$?"

# ---- T2: no TTY hang — zero flags, piped stdin ----------------------------------
new_repo t2
OUT2=$(init_env --target "$REPO" < /dev/null 2>&1); RC2=$?
check "a zero-flag piped run finishes (no prompt hang), exit 0" "$RC2"
grep -qF "gob init [3/6] class: A" <<<"$OUT2"
check "the cascade names the defaulted class" "$?"
grep -qF "owner_email: runner@example.com" "$REPO/.goblin/goblin.yaml"
check "the git identity became the declared email" "$?"
[ -f "$REPO/.hermes/skills/goblin-mode/SKILL.md" ]
check "the detected-platform default emitted hermes" "$?"

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
printf '%s' "$OUT4" | grep -qF "class       D"
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
printf '%s' "$OUT7" | grep -q "app|service|game|research|agent|desktop"
check "the refusal names the class enum" "$?"

# ---- T7: the dispatcher routes ----------------------------------------------------
OUT8=$( cd "$WORK" && env PATH="$BARE_PATH" bash "$SRC/bin/goblin" init --help 2>&1 ); RC8=$?
check "goblin init --help exits 0 through the dispatcher" "$RC8"
printf '%s' "$OUT8" | grep -q -- "--class"
check "the usage names the class flag" "$?"
OUT9=$( cd "$WORK" && node "$SRC/bin/goblin.js" init --help 2>&1 ); RC9=$?
check "the npm shim routes init to goblin-init" "$RC9"
printf '%s' "$OUT9" | grep -q -- "--class"
check "the shim run reaches the wizard's usage" "$?"

if [ "$fail" -eq 0 ]; then
  printf 't-init: ok\n'
else
  printf 't-init: FAIL\n'
fi
exit "$fail"
