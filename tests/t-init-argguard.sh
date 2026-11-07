#!/usr/bin/env bash
# t-init-argguard.sh — INIT-WRITE-HANG: `gob init --write` with a missing or bad
# proposal path must fail FAST and LOUD (exit 2, usage naming <proposal-path>),
# never hang. Found on the published 0.6.0: `gob init --write` with no path
# spins the flag loop forever (shift 2 with $#=1 fails silently, $1 is never
# consumed) — rc 124, zero bytes on both streams.
#
#   A1  --write with NO positional: exit 2, stderr names <proposal-path>,
#       under timeout 10 (the hang detector), nothing installed
#   A2  --write with a path that does not exist: same contract
#   A3  --write with a path that is a directory: same contract
#   A4  --write with a file that has no gob block: exit 2 (B3's refusal,
#       restated here for the arg family), nothing installed
#   A5  the documented path still works right next to the guards: a full
#       --write <proposal> on a seeded repo exits 0 and writes the map
#
# Every fixture lives in a mktemp sandbox with HOME pointed inside it. Run by
# tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }
KEEP=0; [ "${GOB_TEST_KEEP:-}" = 1 ] && KEEP=1
trap '[ "$KEEP" -eq 1 ] || rm -rf "$WORK"' EXIT

BARE_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
mkdir -p "$WORK/home"
REPO="$WORK/repo"
mkdir -p "$REPO/tests"
( cd "$REPO" && git init -q -b main && git config user.name "Test Runner" \
    && git config user.email "runner@example.com" \
    && printf '# probe\n' > README.md \
    && printf '#!/usr/bin/env bash\nexit 0\n' > tests/run-tests.sh \
    && chmod +x tests/run-tests.sh \
    && git add -A && git commit -q -m "chore: seed" )

# run <timeout-s> <args...> — capture the exit code, stdout and stderr apart.
run() {
  local t="$1"; shift
  OUT=$(cd "$REPO" && env HOME="$WORK/home" PATH="$BARE_PATH" \
      timeout "$t" bash "$SRC/bin/goblin-init" "$@" 2>"$WORK/err"); RC=$?
  ERR=$(cat "$WORK/err")
}

nothing_installed() { # no gob artifact landed in the probe repo
  [ ! -e "$REPO/AGENTS.md" ] && [ ! -d "$REPO/.gob" ] && [ ! -e "$REPO/HANDOFF.md" ] \
    && [ ! -d "$REPO/features" ]
}

# --- A1 the hang: --write with no path (timeout 10 is the detector) -----------
run 10 --write
[ "$RC" -eq 2 ];                                      check "A1 no-path exits 2 (got $RC)" $?
printf '%s' "$ERR$OUT" | grep -q '<proposal-path>';   check "A1 output names <proposal-path>" $?
nothing_installed;                                    check "A1 nothing installed" $?

# --- A2 a path that does not exist --------------------------------------------
run 10 --write "$REPO/no-such-proposal.md"
[ "$RC" -eq 2 ];                                      check "A2 missing-file exits 2 (got $RC)" $?
printf '%s' "$ERR$OUT" | grep -q '<proposal-path>';   check "A2 output names <proposal-path>" $?
nothing_installed;                                    check "A2 nothing installed" $?

# --- A3 a path that is a directory ---------------------------------------------
mkdir -p "$REPO/a-dir"
run 10 --write "$REPO/a-dir"
[ "$RC" -eq 2 ];                                      check "A3 directory exits 2 (got $RC)" $?
nothing_installed;                                    check "A3 nothing installed" $?

# --- A4 a file with no gob block ------------------------------------------------
printf 'no config block here\n' > "$REPO/plain.md"
run 10 --write "$REPO/plain.md"
[ "$RC" -eq 2 ];                                      check "A4 no-gob-block exits 2 (got $RC)" $?
nothing_installed;                                    check "A4 nothing installed" $?

# --- A5 the documented path still works ----------------------------------------
{
  printf '<!-- gob:begin (gobstack config — edit in place; the parser reads only this block) -->\n'
  printf 'gate_commit_cmd: bash tests/run-tests.sh\n'
  printf 'feature_map: features/README.md\n'
  printf '<!-- gob:end -->\n'
  printf '\n## gob init summary\n\n- the probe: one real gate, a one-feature map\n'
  printf '## feature-map\n\n### features/README.md\n\n```md\n# Features\n\n- [readme](./readme.md) — the probe README\n```\n'
  printf '\n### features/readme.md\n\n```md\n---\nfeature: readme\nentry_paths:\n  - README.md\nverified: never-driven (2024-01-01)\n---\n# readme\n\nThe README.\n\n## Sub-features\n\n- the readme file\n\n## How to get to it (user POV)\n\n- open the root\n\n## Driving it with bash\n\nPreconditions: a checkout.\n**Read.** Run `cat README.md`. The file prints.\n\n## Gotchas\n\n- none.\n```\n'
} > "$REPO/proposal.md"
run 60 --write "$REPO/proposal.md"
[ "$RC" -eq 0 ];                                      check "A5 documented path exits 0 (got $RC)" $?
[ -f "$REPO/features/README.md" ];                   check "A5 feature map written" $?

[ "$fail" -eq 0 ] && echo "t-init-argguard: PASS" || echo "t-init-argguard: FAIL"
exit "$fail"
