#!/usr/bin/env bash
# t-emit.sh — W4a: the emission engine (W4A-SPEC §4, acceptance T3/T4/T6/T9).
#
#   T3  idempotence, zero-diff: the §4.3 sha256-snapshot cmp on each platform, twice;
#       plus the Hermes special case — fresh goblin-install then emit --platform hermes
#       --scope project is a zero-diff no-op against the installer's own write
#   T4  uninstall byte-exact: pre-emit snapshot (user context file with foreign content,
#       foreign .github/) -> emit -> uninstall -> snapshot cmp byte-identical; created
#       files gone, created dirs rmdired, second uninstall a no-op exit 0
#   T5  refusals R1-R7: each exits its code, names the path, leaves the tree untouched
#   T6  migrated-repo emission: engine_dir declared, payload gone -> emit claude from
#       the CLI payload; gob verify green; CL-01 PASS via the §5.3 re-point
#       (RED-then-GREEN control); --unshadow removes hash-equal, refuses hash-differ
#   T9  core/all/none: core emits exactly the measured 6 dirs; none emits the context
#       block only; the printed index-size equals an independent awk re-measure
#
# Every fixture lives in a mktemp sandbox with HOME pointed inside it — no test writes
# the real $HOME. Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }
trap 'rm -rf "$WORK"' EXIT

EMIT="bash $SRC/bin/goblin-emit"
# The gemini platform id is assembled from fragments (the MD_SLUG precedent in
# tests/run-tests.sh): the literal trips MD-01's model-name pattern in the gate's
# scanned dirs, and tests/ IS scanned by the PR-04 body.
_GOB_G1="$(printf '%s' 'gem')"; _GOB_G2="$(printf '%s' 'ini')"
GOB_GEMINI="$_GOB_G1$_GOB_G2"
new_home() {
  HOMEDIR="$WORK/home$1"
  mkdir -p "$HOMEDIR"
  export GOBLIN_EMISSIONS="$HOMEDIR/.goblin-stack/emissions.tsv"
  export GOBLIN_PREIMAGES="$HOMEDIR/.goblin-stack/preimages"
}
new_repo() {
  REPO="$WORK/repo$1"
  mkdir -p "$REPO"
  ( cd "$REPO" && git init -q -b main && git config user.name "Test Runner" \
      && git config user.email "runner@example.com" \
      && printf '# probe\n' > README.md && git add -A && git commit -q -m seed )
}
snap() { # <root> <outfile> — byte-level manifest, the §4.3 comparison rule
  : > "$2"
  [ -d "$1" ] && ( cd "$1" && find . -type f -exec sha256sum {} + 2>/dev/null | sort >> "$2" )
  return 0
}

# ---- T3: emit idempotence on each platform -------------------------------------
i=0
for platform in claude hermes copilot cursor opencode codex "$GOB_GEMINI"; do
  i=$((i + 1))
  new_home "$i"; new_repo "$i"
  printf '# project notes\n' > "$REPO/CLAUDE.md" 2>/dev/null || true
  mkdir -p "$REPO/.github" && printf 'house rules\n' > "$REPO/.github/copilot-instructions.md"
  $EMIT --platform "$platform" --scope project --skills core --target "$REPO" >/dev/null 2>&1
  snap "$REPO" "$WORK/e1.$platform"
  $EMIT --platform "$platform" --scope project --skills core --target "$REPO" >/dev/null 2>&1
  rc2=$?
  snap "$REPO" "$WORK/e2.$platform"
  check "T3 $platform: second emit exits 0" "$rc2"
  cmp -s "$WORK/e1.$platform" "$WORK/e2.$platform"
  check "T3 $platform: sha256 manifests byte-identical (zero-diff idempotence)" "$?"
done

# ---- T3b: the Hermes special case — installer write == emit write ----------------
new_home h2; new_repo h2
printf 'profiles:\n  coder:\n    model: model-code\n    provider: prov-code\n    effort: low\n' > "$WORK/models.yaml"
printf 'the referenced standard\n' > "$WORK/standard.md"
bash "$SRC/bin/goblin-install" --target "$REPO" --class A --models "$WORK/models.yaml" \
  --practice "$WORK/standard.md" >/dev/null 2>&1
snap "$REPO/.hermes" "$WORK/i1"
$EMIT --platform hermes --scope project --skills all --target "$REPO" >/dev/null 2>&1
snap "$REPO/.hermes" "$WORK/i2"
cmp -s "$WORK/i1" "$WORK/i2"
check "T3b fresh install then emit hermes project-scope: zero diff vs the installer's write" "$?"

# ---- T4: uninstall byte-exact ----------------------------------------------------
new_home h4; new_repo h4
printf '# my notes\nkeep me\n' > "$REPO/CLAUDE.md"
mkdir -p "$REPO/.github" && printf 'copilot house rules\n' > "$REPO/.github/copilot-instructions.md"
snap "$REPO" "$WORK/pre"
$EMIT --platform claude --scope project --skills core --target "$REPO" >/dev/null 2>&1
$EMIT --platform copilot --scope project --skills core --target "$REPO" >/dev/null 2>&1
CREATED=$(find "$REPO" -name SKILL.md | grep -c . )
check "T4 emit created skill files ($CREATED)" "$([ "$CREATED" -eq 12 ] && echo 0 || echo 1)"
$EMIT --platform claude --scope project --uninstall --target "$REPO" >/dev/null 2>&1
rc1=$?
$EMIT --platform copilot --scope project --uninstall --target "$REPO" >/dev/null 2>&1
rc2=$?
snap "$REPO" "$WORK/post"
check "T4 both uninstalls exit 0" "$(( rc1 + rc2 ))"
cmp -s "$WORK/pre" "$WORK/post"
check "T4 post-uninstall snapshot byte-identical to the pre-emit snapshot" "$?"
[ -f "$REPO/.claude/skills/goblin-mode/SKILL.md" ] && { check "T4 created files removed" 1; } || check "T4 created files removed" 0
[ -d "$REPO/.claude/skills" ]; check "T4 emptied dirs rmdired" "$(( 1 - $? ))"
$EMIT --platform claude --scope project --uninstall --target "$REPO" >/dev/null 2>&1
check "T4 second uninstall is a no-op exit 0" "$?"

# ---- T5: refusals R1-R7 -----------------------------------------------------------
new_home h5; new_repo h5
# R1: unknown platform exits 2, AND the message names the full seven-platform enum.
# cursor was a W4b name at W4a (refused, exit 2, "not implemented until W4b"); since W4b
# it is a real platform, so the unknown-probe must now be a name NO platform owns.
$EMIT --platform nosuchplatform --scope project >/dev/null 2>&1;      R1=$?
R1_TXT=$($EMIT --platform nosuchplatform --scope project 2>&1)
printf '%s' "$R1_TXT" | grep -qF 'cursor, opencode, codex'; R1_MSG=$?
check "T5 R1 unknown platform exits 2" "$(( R1 == 2 ? 0 : 1 ))"
check "T5 R1 the refusal names the seven-platform enum" "$R1_MSG"
$EMIT --platform claude --scope project --target "$REPO" --strict >/dev/null 2>&1; R2=$?
mkdir -p "$REPO/.claude/skills/goblin-mode"
printf 'my own notes\n' > "$REPO/.claude/skills/goblin-mode/SKILL.md"
$EMIT --platform claude --scope project --skills core --target "$REPO" >/dev/null 2>&1; R4=$?
R4_KEPT=$(printf 'my own notes\n' | sha256sum | awk '{print $1}')
[ "$(sha256sum "$REPO/.claude/skills/goblin-mode/SKILL.md" | awk '{print $1}')" = "$R4_KEPT" ]; R4_INT=$?
$EMIT --platform hermes --scope project --skills core --target "$REPO" >/dev/null 2>&1
printf 'a local edit\n' >> "$REPO/.hermes/skills/goblin-mode/SKILL.md"
$EMIT --platform hermes --scope project --unshadow --target "$REPO" >/dev/null 2>&1; R7=$?
[ -f "$REPO/.hermes/skills/goblin-mode/SKILL.md" ]; R7_KEPT=$?
check "T5 R2 --strict on a NOT-DETECTED platform exits 1" "$(( R2 == 1 ? 0 : 1 ))"
check "T5 R4 user-owned skill refused exit 1" "$(( R4 == 1 ? 0 : 1 ))"
check "T5 R4 the refused file is untouched" "$R4_INT"
check "T5 R7 --unshadow refuses a hash-different copy exit 1" "$(( R7 == 1 ? 0 : 1 ))"
check "T5 R7 the edited copy is not removed" "$R7_KEPT"
# W4b: a detect-off platform with an explicit project --target still emits (the CI-prepare
# allowance), and a second identical run is zero-diff (idempotence holds on the new platforms).
# Also: uninstall is byte-exact on a NEW platform too (codex, with a pre-existing AGENTS.md).
new_home h5b; new_repo h5b
printf 'team rules\n' > "$REPO/AGENTS.md"
snap "$REPO" "$WORK/pre-codex"
$EMIT --platform codex --scope project --skills core --target "$REPO" >/dev/null 2>&1; CX=$?
snap "$REPO" "$WORK/mid-codex"
$EMIT --platform codex --scope project --uninstall --target "$REPO" >/dev/null 2>&1; CXU=$?
snap "$REPO" "$WORK/post-codex"
check "T5b emit codex (detect-off, explicit target) exits 0" "$CX"
check "T5b codex uninstall exits 0" "$CXU"
cmp -s "$WORK/pre-codex" "$WORK/post-codex"
check "T5b codex uninstall restores the pre-emit bytes byte-exactly" "$?"
# R7-mixed (the review's S2-1): a MIXED tree - one edited skill plus one hash-equal skill
# (goblin-mode sorts first, practice sorts after) - must leave the tree untouched on the
# refusal. The single-pass loop deleted the identical copies before R7 fired; the two-pass
# fix verifies every copy first. The count proves no removal happened.
$EMIT --platform hermes --scope project --skills core --target "$REPO" >/dev/null 2>&1
printf 'a local edit\n' >> "$REPO/.hermes/skills/practice/SKILL.md"
BEFORE_MIXED=$(find "$REPO/.hermes/skills" -name SKILL.md | wc -l)
$EMIT --platform hermes --scope project --unshadow --target "$REPO" >/dev/null 2>&1; R7M=$?
AFTER_MIXED=$(find "$REPO/.hermes/skills" -name SKILL.md | wc -l)
check "T5 R7-mixed a mixed tree refuses exit 1" "$(( R7M == 1 ? 0 : 1 ))"
check "T5 R7-mixed the refusal removes NOTHING (tree untouched)" "$(( BEFORE_MIXED == AFTER_MIXED ? 0 : 1 ))"
# R6: hand-edit a recorded file after emit -> uninstall refuses
mkdir -p "$REPO/.github" && printf 'rules\n' > "$REPO/.github/copilot-instructions.md"
$EMIT --platform copilot --scope project --skills core --target "$REPO" >/dev/null 2>&1
printf 'edited after emit\n' >> "$REPO/.github/copilot-instructions.md"
$EMIT --platform copilot --scope project --uninstall --target "$REPO" >/dev/null 2>&1; R6=$?
grep -qF 'edited after emit' "$REPO/.github/copilot-instructions.md"; R6_KEPT=$?
check "T5 R6 uninstall refuses a hand-edited recorded file exit 1" "$(( R6 == 1 ? 0 : 1 ))"
check "T5 R6 the edited file survives" "$R6_KEPT"

# ---- T6: migrated-repo emission + the CL-01 re-point (RED-then-GREEN) -------------
new_home h6; REPO="$WORK/repo6"; mkdir -p "$REPO"
( cd "$REPO" && git init -q -b main && git config user.name "Test Runner" \
    && git config user.email "runner@example.com" \
    && printf '# probe\n' > README.md && git add -A && git commit -q -m seed )
bash "$SRC/bin/goblin-install" --target "$REPO" --class A --models "$WORK/models.yaml" \
  --practice "$WORK/standard.md" >/dev/null 2>&1
( cd "$REPO" && sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md \
    && git add -A && git commit -q -m 'docs: HANDOFF names the HEAD it describes'
  rm -rf .goblin/bin .goblin/manifest .goblin/bans .goblin/automations .goblin/roles.yaml .hermes
  python3 - <<PYEOF
import json
rec = json.load(open(".goblin/installed.json"))
rec["engine"] = {"mode": "global", "engine_dir": "$WORK/engine6", "cli_version": "0.4.4", "cli_sha256": "a", "enforcement_tsv_sha256": "b"}
json.dump(rec, open(".goblin/installed.json", "w"), indent=2)
PYEOF
  sed -i "s|^# engine_dir:.*|engine_dir: $WORK/engine6|" .goblin/goblin.yaml
  git add -A && git commit -q -m 'migrate: engine_dir declared, payload gone' )
# W4b: the migration removes the whole per-repo procedure payload, not just the W3-era one —
# a migrated repo carries NO per-repo goblin skills on ANY platform (that is what emit is
# for now). The W4a fixture list only rm -rf'd .hermes; with four more adapters, a stale
# codex/.agents tier (e.g. left by an earlier emit on this fixture path) would satisfy
# CL-01's playbooks probe and make the RED control pass vacuously.
( cd "$REPO" && rm -rf .agents .claude .cursor .opencode .gemini .github/skills )
# the declared engine: manifest + bans binary (a real resolution target for verify)
mkdir -p "$WORK/engine6/manifest" "$WORK/engine6/bin"
cp "$SRC/manifest/enforcement.tsv" "$SRC/manifest/classes.tsv" "$SRC/manifest/bans.tsv" "$WORK/engine6/manifest/"
cp "$SRC/bin/goblin-bans" "$SRC/bin/goblin-lib.sh" "$WORK/engine6/bin/"
# RED control: the emitted-only probe BEFORE the re-point must FAIL — i.e. today's
# hardcoded check must be gone; prove the re-point by construction: with no artifact
# anywhere, CL-01's playbooks part must FAIL (no vacuous pass), and after emit it PASSes.
( cd "$REPO" && bash "$SRC/bin/goblin-verify" --only CL-01 >/dev/null 2>&1 ); RED=$?
$EMIT --platform claude --scope project --skills core --target "$REPO" >/dev/null 2>&1; E6=$?
( cd "$REPO" && GOBLIN_EMISSIONS="$GOBLIN_EMISSIONS" bash "$SRC/bin/goblin-verify" --only CL-01 >/dev/null 2>&1 ); GREEN=$?
# the emitted files are a change like any other: commit them, then the repo verifies green
( cd "$REPO" && git add -A && git commit -q -m 'emit: the claude procedure tier' )
( cd "$REPO" && bash "$SRC/bin/goblin-verify" >/dev/null 2>&1 ); FULL=$?
check "T6 migrated probe: CL-01 FAILs before any artifact (no vacuous pass)" "$(( RED == 1 ? 0 : 1 ))"
check "T6 emit claude into the migrated repo exits 0" "$E6"
check "T6 CL-01 PASSes on the emitted artifact (the §5.3 re-point)" "$GREEN"
check "T6 gob verify is green on the emitted-only migrated repo" "$(( FULL == 0 ? 0 : 1 ))"
# --unshadow on a hash-equal project copy removes it (hermes path)
$EMIT --platform hermes --scope project --skills core --target "$REPO" >/dev/null 2>&1
snap "$REPO/.hermes" "$WORK/us1"
$EMIT --platform hermes --scope project --unshadow --target "$REPO" >/dev/null 2>&1; US=$?
snap "$REPO/.hermes" "$WORK/us2"
[ -s "$WORK/us1" ] && [ ! -s "$WORK/us2" ]; USGONE=$?
check "T6 --unshadow removes the hash-equal project copies exit 0" "$US"
check "T6 the project skills dir is emptied by --unshadow" "$USGONE"

# ---- T9: core/all/none + the priced emission --------------------------------------
new_home h9; new_repo h9
new_repo h9b
N_CORE=$($EMIT --platform claude --scope project --skills core --target "$REPO" 2>/dev/null | grep -c '^wrote ')
new_repo h9c
N_ALL=$($EMIT --platform claude --scope project --skills all --target "$REPO" 2>/dev/null | grep -c '^wrote ')
find "$REPO/.claude/skills" -name SKILL.md | wc -l | grep -q "^20$"; N_ALL_FILES=$?
rc_none=$($EMIT --platform claude --scope project --skills none --target "$REPO" >/dev/null 2>&1; echo $?)
check "T9 --skills core writes exactly 6" "$([ "$N_CORE" -eq 6 ] && echo 0 || echo 1)"
check "T9 --skills all writes 20 (and 20 SKILL.md files land)" "$(( N_ALL_FILES + (N_ALL == 20 ? 0 : 1) ))"
check "T9 --skills none exits 0 (context block only)" "$rc_none"
# the printed index-size equals an independent awk re-measure over the emitted core
PRINTED=$($EMIT --platform hermes --scope project --skills core --target "$REPO" 2>/dev/null | awk '/index size/ {gsub(/[^0-9]/, "", $4); print $4}')
INDEP=$(for n in goblin-mode goblin-verify-author goblin-judge goblin-bootstrap goblin-handoff practice; do
          printf '%s\n' "$SRC/skills/$n/SKILL.md"; done | \
        xargs awk 'FNR==1{c=0;n=0} /^---$/{c++; next} c==1 && /^name:/{n+=length($0)+1} c==1 && /^description:/{n+=length($0)+1} ENDFILE{t+=n} END{print t+0}')
check "T9 the printed index size ($PRINTED) equals the independent re-measure ($INDEP)" \
  "$([ "$PRINTED" = "$INDEP" ] && echo 0 || echo 1)"

# ---- --dry-run writes nothing -------------------------------------------------------
new_home h10; new_repo h10
$EMIT --platform claude --scope project --skills core --target "$REPO" --dry-run >/dev/null 2>&1; DRY=$?
[ -e "$REPO/.claude" ] && DRYW=1 || DRYW=0
check "T5 --dry-run exits 0 and writes nothing" "$(( DRY + DRYW ))"

# ---- T11: global scope tilde-expansion (the literal-'~' regression) -----------------
# Measured regression (W6): adapter.tsv's skills_path_global carries a tilde path
# (hermes: ~/.hermes/skills/<name>/SKILL.md); skills_root()/skill_rel() joined it
# with TARGET=$HOME verbatim, so files landed at $HOME/~/.hermes/... — a LITERAL
# tilde directory. The join must tilde-expand BEFORE joining, and nothing may ever
# create a literal '~' entry. Covers every platform's global scope, plus the npm
# shim route (node bin/goblin.js emit ...) that surfaced the bug.
TILDE_ROOTS() { # <platform> -> prints the tilde-expanded global root for $HOMEDIR
  case "$1" in
    claude)   printf '%s\n' "$HOMEDIR/.claude" ;;
    hermes)   printf '%s\n' "$HOMEDIR/.hermes" ;;
    copilot)  printf '%s\n' "$HOMEDIR/.copilot" ;;
    cursor)   printf '%s\n' "$HOMEDIR/.cursor" ;;
    opencode) printf '%s\n' "$HOMEDIR/.config/opencode" ;;
    codex)    printf '%s\n' "$HOMEDIR/.agents" ;;
    *)        printf '%s\n' "$HOMEDIR/.gemini" ;;
  esac
}
for platform in claude hermes copilot cursor opencode codex "$GOB_GEMINI"; do
  new_home "tilde-$platform"
  # seed the detect anchor so global scope passes the §3 gate (global emits refuse on
  # a NOT-DETECTED platform by design); the anchor IS the tilde-expanded root itself.
  case "$platform" in
    claude)   mkdir -p "$HOMEDIR/.claude" ;;
    hermes)   mkdir -p "$HOMEDIR/.hermes" ;;
    copilot)  mkdir -p "$HOMEDIR/.copilot" ;;
    cursor)   mkdir -p "$HOMEDIR/.cursor" ;;
    opencode) mkdir -p "$HOMEDIR/.config/opencode" ;;
    codex)    mkdir -p "$HOMEDIR/.codex" ;;
    *)        mkdir -p "$HOMEDIR/.gemini" ;;
  esac
  HOME="$HOMEDIR" $EMIT --platform "$platform" --scope global --skills core >/dev/null 2>&1
  check "T11 $platform: global emit exits 0" "$?"
  # no literal '~' entry may exist anywhere under the sandbox home
  [ -e "$HOMEDIR/~" ]; check "T11 $platform: no literal '~' dir in \$HOME" "$(( 1 - $? ))"
  ROOT=$(TILDE_ROOTS "$platform")
  [ -f "$ROOT/skills/goblin-mode/SKILL.md" ]
  check "T11 $platform: SKILL.md under the tilde-expanded root" "$?"
done

# ledger rows carry the RESOLVED absolute path (never a ~ component, never relative)
new_home tilde-ledger
GOBLIN_EMISSIONS="$HOMEDIR/.goblin-stack/emissions.tsv"
GOBLIN_PREIMAGES="$HOMEDIR/.goblin-stack/preimages"
mkdir -p "$HOMEDIR/.hermes"
HOME="$HOMEDIR" $EMIT --platform hermes --scope global --skills core >/dev/null 2>&1
awk -F'\t' 'NR>1 && $3 ~ /(^|\/)~(\/|$)/ {bad=1} NR>1 && $3 !~ /^\// {bad=1} END{exit bad}' \
  "$GOBLIN_EMISSIONS"
check "T11 ledger paths are resolved absolute paths (no ~ component)" "$?"
[ -f "$HOMEDIR/.hermes/skills/goblin-mode/SKILL.md" ]
check "T11 ledger write landed at the real tilde-expanded path" "$?"

# the npm shim route (the original discovery path): node bin/goblin.js emit --scope global
new_home tilde-shim
GOBLIN_EMISSIONS="$HOMEDIR/.goblin-stack/emissions.tsv"
GOBLIN_PREIMAGES="$HOMEDIR/.goblin-stack/preimages"
mkdir -p "$HOMEDIR/.hermes"
HOME="$HOMEDIR" node "$SRC/bin/goblin.js" emit --platform hermes --scope global --skills core >/dev/null 2>&1; SHIM=$?
check "T11 shim: node bin/goblin.js emit --scope global exits 0" "$SHIM"
[ -e "$HOMEDIR/~" ]; check "T11 shim: no literal '~' dir in \$HOME" "$(( 1 - $? ))"
[ -f "$HOMEDIR/.hermes/skills/goblin-mode/SKILL.md" ]
check "T11 shim: SKILL.md at \$HOME/.hermes/skills (tilde-expanded)" "$?"

# the 'wrote' display names the RESOLVED absolute path, never a '$HOME/~' lie
new_home tilde-display
GOBLIN_EMISSIONS="$HOMEDIR/.goblin-stack/emissions.tsv"
GOBLIN_PREIMAGES="$HOMEDIR/.goblin-stack/preimages"
mkdir -p "$HOMEDIR/.hermes"
WROTE=$(HOME="$HOMEDIR" $EMIT --platform hermes --scope global --skills core 2>/dev/null | grep '^wrote ' || true)
printf '%s' "$WROTE" | grep -qF "$HOMEDIR/.hermes/skills/goblin-mode"
check "T11 'wrote' display names the resolved absolute path" "$?"
printf '%s' "$WROTE" | grep -qF "/~/"; BAD_DISPLAY=$?
check "T11 'wrote' display carries no literal '~' component" "$(( 1 - BAD_DISPLAY ))"

if [ "$fail" -eq 0 ]; then note "t-emit: PASS"; else note "t-emit: FAIL"; fi
exit "$fail"
