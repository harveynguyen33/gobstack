#!/usr/bin/env bash
# t-install-off-switch.sh — the part switches are real, not labels.
#   --archive -> no checks/, no HANDOFF, no SPEC, no reviews/, verify exits 0
#   the same shape without --archive -> the missing HANDOFF fails HP-01
# Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }


mkfix() {
  mkdir -p "$1" && cd "$1"
  git init -q -b main
  git config user.name "Test Runner"
  git config user.email "runner@example.com"
  printf '# %s\n' "$(basename "$1")" > README.md
  git add -A && git commit -q -m "chore: seed"
}

# ---- class D + --archive -----------------------------------------------------
mkfix "$WORK/archived"
bash "$SRC/bin/goblin-install" --target "$WORK/archived" --archive >/dev/null 2>&1
check "archive install exits 0" "$?"
check "no checks/ directory" "$([ ! -d checks ] && echo 0 || echo 1)"
check "no HANDOFF.md" "$([ ! -f HANDOFF.md ] && echo 0 || echo 1)"
check "no *-SPEC.md" "$(ls ./*-SPEC.md >/dev/null 2>&1 && echo 1 || echo 0)"
check "no reviews/ directory" "$([ ! -d reviews ] && echo 0 || echo 1)"
check "no .gob/tokens.yaml" "$([ ! -f .gob/tokens.yaml ] && echo 0 || echo 1)"
git add -A && git commit -q -m "chore: install (archive)"
VERIFY_OUT=$(bash .gob/bin/goblin-verify 2>&1); VERIFY_RC=$?
note "verify exit=$VERIFY_RC"
printf '%s' "$VERIFY_OUT" | grep -q 'SKIP  HP-01'
check "HP-01 is skipped for an archive project" "$?"
printf '%s' "$VERIFY_OUT" | grep -q 'SKIP  GT-01'
check "GT-01 is skipped for an archive project" "$?"
check "archive verify exits 0 without a HANDOFF" "$VERIFY_RC"
printf '%s' "$VERIFY_OUT" | grep -q 'archive: true'
check "the summary says why the rows were skipped" "$?"

# ---- the same shape, no --archive: the switch is what made it pass -----------
mkfix "$WORK/notarchived"
bash "$SRC/bin/goblin-install" --target "$WORK/notarchived" >/dev/null 2>&1
git add -A && git commit -q -m "chore: install"
rm -f HANDOFF.md && git add -A && git commit -q -m "test: remove the HANDOFF"
A_OUT=$(bash .gob/bin/goblin-verify 2>&1); A_RC=$?
note "no --archive, no HANDOFF: verify exit=$A_RC"
printf '%s' "$A_OUT" | grep -q 'FAIL  HP-01'
check "the install fails HP-01 when the HANDOFF is gone" "$?"
check "and the run is not green" "$([ "$A_RC" -eq 1 ] && echo 0 || echo 1)"

# ---- the skills part + the core tier (GAP-2) ---------------------------------------------
# Before GAP-2 a default (--skills no) install recorded `disabled: [skills]`, so SK-01/SK-02/
# SK-04 SKIPPED on every fresh repo — the product disabled its own rows. Now the five-skill core
# procedure tier is vendored under .gob/skills/ and the part is NOT disabled, so those rows RUN.
# An explicit --opt-out skills is the only thing that turns them off, and it is a real switch.
# (v3: the part was named `playbooks`, for the manifest that indexed the cut skills — the rail
# follows its list.)
mkfix "$WORK/noskills"
bash "$SRC/bin/goblin-install" --target "$WORK/noskills" --skills no \
  >/dev/null 2>&1
check "--skills no installs" "$?"
git add -A && git commit -q -m "chore: install (--skills no)"
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"
NS_OUT=$(bash .gob/bin/goblin-verify 2>&1); NS_RC=$?
note "--skills no: verify exit=$NS_RC, $(printf '%s' "$NS_OUT" | grep -E '^ *[0-9]+ passed')"
check "a --skills no install verifies green" "$NS_RC"
printf '%s' "$NS_OUT" | grep -qE '^PASS  SK-01'
check "  and the core skill rows RUN, not skip (GAP-2)" "$?"
[ -f .gob/skills/goblin-handoff/SKILL.md ]
check "  because the five-skill core tier is vendored under .gob/skills/" "$?"
[ ! -e .hermes ]
check "  and no Hermes project tier was installed (it is still opt-in)" "$?"
# V3-3 + GAP-2/3 + FIX 1: the count with the core tier on and bans self-selected. The number is
# measured, not copied — see the note line above. It moved 14/0/0/13 -> 17/0/0/10 when the three
# skill rows stopped skipping, then 21/0/0/6 when the electron bans started running via their
# globs, then 17/0/0/10 again under FIX 1: the electron bans are `dep:electron` NOW, so on this
# no-package.json fixture they report NOT APPLICABLE instead of running vacuously off the shipped
# checks/*.mjs. (The 21/0/0/6 shape was the false green FIX 1 removed.)
printf '%s' "$NS_OUT" | grep -q '17 passed, 0 failed, 0 advisory, 10 skipped'
check "  and the numbers are pinned (V3-3 + GAP-2/3 + FIX 1: core tier + predicate bans, 17/0/0/10)" "$?"

# ---- the part switch is still real: an explicit --opt-out skills turns the rows off ------------
mkfix "$WORK/optout"
bash "$SRC/bin/goblin-install" --target "$WORK/optout" --opt-out skills >/dev/null 2>&1
check "--opt-out skills installs" "$?"
git add -A && git commit -q -m "chore: install (--opt-out skills)"
sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"
OO_OUT=$(bash .gob/bin/goblin-verify 2>&1); OO_RC=$?
check "the --opt-out install verifies green" "$OO_RC"
printf '%s' "$OO_OUT" | grep -q 'SKIP  SK-01  .*opt-out: skills'
check "  and the skill rows are opt-out, not absent (the switch is real)" "$?"
printf '%s' "$OO_OUT" | grep -q 'SKIP  SK-02'
check "  and SK-02 is opt-out rather than FAIL" "$?"
printf '%s' "$OO_OUT" | grep -q '14 passed, 0 failed, 0 advisory, 13 skipped'
check "  and the opt-out numbers are pinned (14/0/0/13: the three skill rows skip again)" "$?"

# ---- W6 migration safety: an upgrade must not strip previously-installed skills ---------------
# The pre-W6 default was --skills yes, so every existing install carries .hermes/skills recorded
# in installed.json. The new default is no. The idempotence contract (created/updated/unchanged)
# holds only if a re-install that OMITS the flag reads the record's choice: skills stay until
# --uninstall removes exactly what the record lists.
mkfix "$WORK/migrate"
bash "$SRC/bin/goblin-install" --target "$WORK/migrate" --skills yes \
  >/dev/null 2>&1
check "migration fixture: --skills yes installs" "$?"
S_BEFORE=$(find .hermes/skills -name SKILL.md | sort)
REC_BEFORE=$(sha256sum .gob/installed.json | awk '{print $1}')
git add -A && git commit -q -m "chore: install (--skills yes, the pre-W6 shape)"
# the upgrade: the NEW default (no flag), same class — must keep every skill
UP_OUT=$(bash "$SRC/bin/goblin-install" --target "$WORK/migrate" --upgrade \
  2>&1); UP_RC=$?
check "upgrade with the new default exits 0" "$UP_RC"
S_AFTER=$(find .hermes/skills -name SKILL.md 2>/dev/null | sort)
[ "$S_BEFORE" = "$S_AFTER" ] && [ -n "$S_AFTER" ]
check "  and every previously-installed skill survives byte-identical (same list)" "$?"
grep -q '"skills": "yes"' .gob/installed.json
check "  and the record still says skills=yes (the choice was read, not reset)" "$?"
printf '%s' "$UP_OUT" | grep -q 'agent skills installed - they are kept'
check "  and the run says so out loud (not a silent state change)" "$?"
git add -A && git commit -q -m "chore: upgrade (default flag, skills kept)"
# a plain SECOND install (no upgrade, no flag) keeps them too
bash "$SRC/bin/goblin-install" --target "$WORK/migrate" \
  >/dev/null 2>&1
[ "$(find .hermes/skills -name SKILL.md 2>/dev/null | sort)" = "$S_AFTER" ]
check "a plain re-install (no flag) keeps the skills too" "$?"
# explicit --skills no is still a real switch: the skills go, the record follows
bash "$SRC/bin/goblin-install" --target "$WORK/migrate" --skills no \
  >/dev/null 2>&1
check "an explicit --skills no re-install exits 0" "$?"
[ ! -e .hermes ]
check "  and the explicit opt-out removes .hermes (no dead tree)" "$?"
grep -q '"skills": "no"' .gob/installed.json
check "  and the record follows the explicit choice" "$?"
git add -A && git commit -q -m "chore: explicit skills opt-out"
# rebuild the skills, then --uninstall removes everything recorded (the F2-7 contract)
bash "$SRC/bin/goblin-install" --target "$WORK/migrate" --skills yes \
  >/dev/null 2>&1
N_BEFORE_UN=$(find .hermes/skills -name SKILL.md | wc -l | tr -d ' ')
[ "$N_BEFORE_UN" -gt 0 ]
check "fixture rebuilt: $N_BEFORE_UN skills installed before the uninstall" "$?"
UN_OUT=$(bash "$SRC/bin/goblin-install" --target "$WORK/migrate" --uninstall 2>&1); UN_RC=$?
check "uninstall exits 0" "$([ "$UN_RC" -eq 0 ] && echo 0 || echo 1)"
[ ! -e .hermes ]
check "  and .hermes is gone (every recorded skill removed)" "$?"
printf '%s' "$UN_OUT" | grep -qE 'removed [0-9]+ file\(s\)'
check "  and the summary counts what it removed" "$?"

if [ "$fail" -eq 0 ]; then note "t-install-off-switch: PASS"; else note "t-install-off-switch: FAIL"; fi
exit "$fail"
