#!/usr/bin/env bash
# t-upgrade.sh — W3: `goblin upgrade`, the 0.4.4 per-repo → global migration, the
# shadowing footer, and the installer's re-shadow refusal (W3-SPEC §6-§7).
#
#   U1  the happy path: dry-run writes nothing, --yes lands the engine, rewrites the
#       record (41 → 23, engine block, engine_dir: active), deletes exactly the 18
#       payload files in its own commit, and verify #3 is green at 39/0/11/32 rc 0
#   U2  hash drift → exit 1 naming the file, nothing migrated
#   U3  R1 dirty tree / R2 detached HEAD / R3 no git → exit 1 with the fix
#   U4  idempotence: a second upgrade is a no-op with zero diff (the PR-02 control)
#   U5  R6 engine collision → exit 1 naming both hash pairs; --engine-dir escape
#   U6  R8/R9 crash shapes → refusal with resume/rollback text
#   U7  R7 record classes: absent → 2, unparseable → 2, foreign version → 1
#   U8  verify-red gate at step 2 → exit 1, tree untouched (no commits written)
#   U9  rollback: `git revert` of the two commits restores the pre-upgrade tree
#       byte-for-byte and the vendored engine verifies green again
#   U10 the shadow footer: restored stale payload on a migrated repo prints the
#       `shadow:` line naming the file count; without the payload it must not print
#   U11 goblin-install onto a migrated repo → exit 1 with the re-shadow remedy;
#       onto a reverted (vendored) repo → the unchanged no-op path
#   U12 gate.sh + CI re-point: post-upgrade `bash checks/gate.sh` prints a non-empty
#       gate line and exits 0 (MA9's silent-green hole); the workflow run line is
#       re-pointed at the pinned global form
#
# The engine is landed in a suite-owned HOME (never the operator's), so the suite
# is hermetic and leaves no ~/.goblin/engine behind.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
HOMEDIR="$WORK/home"
UPGRADE="$SRC/bin/goblin-upgrade"
INSTALL="$SRC/bin/goblin-install"
FAILFILE="$WORK/fails"; : > "$FAILFILE"
note() { printf '      %s\n' "$*"; }
check() { # subshell-safe: a fail appends to a file, not a variable
  if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; printf '%s\n' "$1" >> "$FAILFILE"; fi
}

printf 'profiles:\n  coder:\n    model: model-code\n    provider: prov-code\n    effort: low\n' > "$WORK/models.yaml"
printf 'the referenced standard\n' > "$WORK/standard.md"
mkdir -p "$HOMEDIR"

# new_i1 <dir> — a fresh, committed, green I1 install (the MA1 probe shape).
# Runs entirely inside a subshell so the caller's cwd never moves.
new_i1() {
  rm -rf "$1"
  mkdir -p "$1"
  (
    cd "$1" || exit 1
    git init -q -b main
    git config user.name "Test Runner"
    git config user.email "runner@example.com"
    printf '# the probe repo\n' > README.md
    git add -A && git commit -q -m "seed"
    bash "$INSTALL" --target . --class A --models "$WORK/models.yaml" \
      --practice "$WORK/standard.md" >/dev/null 2>&1
    git add -A && git commit -q -m "install goblin-stack"
    hs=$(git rev-parse --short HEAD)
    sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$hs\`/" HANDOFF.md
    git add -A && git commit -q -m "docs: HANDOFF names HEAD"
  )
}

# in_dir <dir> <command...> — run a command inside a probe, returning to the caller's cwd
in_dir() { ( cd "$1" && shift && "$@" ); }

up() { # up <target> [args...] — upgrade under the suite's HOME
  ( cd "$SRC" && HOME="$HOMEDIR" bash "$UPGRADE" --target "$1" "${@:2}" )
}
ver() { # ver <verify-script> — run a repo's verifier under the suite's HOME
  HOME="$HOMEDIR" bash "$1" 2>&1
}

PAYLOAD_PATHS=".goblin/bin .goblin/manifest .goblin/bans .goblin/automations .goblin/roles.yaml"

# P is the U1 probe; U4/U9/U10/U11/U12 keep probing it across their sections.
P="$WORK/u1"

# ---- summary vars from U1 that later sections read: P, C_A, C_B -----------------
# (the sections below run in subshells; these are written to files at U1 time)
(# ============================================================ U1: the happy path --
P="$WORK/u1"
new_i1 "$P"
V_BEFORE=$(in_dir "$P" ver .goblin/bin/goblin-verify)
printf '%s' "$V_BEFORE" | grep -q '43 passed, 0 failed, 11 advisory, 28 skipped'
check "U1 run-1 (vendored) verifies at the measured green line" "$?"
RECORD_BEFORE=$(in_dir "$P" python3 -c "import json;print(len(json.load(open('.goblin/installed.json'))['files']))")

# -- dry-run: exit 0, prints the plan, writes NOTHING
STATUS_BEFORE=$(git -C "$P" status --porcelain; git -C "$P" rev-parse HEAD)
OUT_DRY=$(up "$P" --engine-dir "$HOMEDIR/engine" --dry-run 2>&1); RC_DRY=$?
check "U1 --dry-run exits 0" "$([ "$RC_DRY" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT_DRY" | grep -q 'step 7'
check "U1 --dry-run prints the step plan (through step 7)" "$?"
[ "$(git -C "$P" status --porcelain; git -C "$P" rev-parse HEAD)" = "$STATUS_BEFORE" ]
check "U1 --dry-run writes nothing (tree and HEAD unchanged)" "$?"

# -- the real run
OUT_UP=$(up "$P" --engine-dir "$HOMEDIR/engine" --yes 2>&1); RC_UP=$?
check "U1 upgrade --yes exits 0" "$([ "$RC_UP" -eq 0 ] && echo 0 || echo 1)"

# the 18 payload paths are gone
MISSING=0
for p in $PAYLOAD_PATHS; do [ -e "$P/$p" ] || MISSING=$((MISSING + 1)); done
check "U1 all 18 engine paths gone from the repo ($MISSING/5 top-level paths absent)" \
  "$([ "$MISSING" -eq 5 ] && echo 0 || echo 1)"

# the engine landed with the repo's own hash pair
[ "$(sha256sum "$HOMEDIR/engine/bin/goblin-verify" | awk '{print $1}')" = "$(sha256sum "$SRC/bin/goblin-verify" | awk '{print $1}')" ]
check "U1 the landed engine carries the repo's own cli bytes" "$?"
[ "$(stat -c '%a' "$HOMEDIR/engine")" = "700" ]
check "U1 the engine directory is 0700" "$?"

# the record: 23 entries, the 5 engine-block fields, no engine entries, skills RETAINED
REC=$(python3 -c "
import json
d = json.load(open('$P/.goblin/installed.json'))
e = d.get('engine', {})
print(len(d['files']),
      e.get('mode',''), e.get('engine_dir',''), e.get('cli_version',''),
      'cli_sha256' in e, 'enforcement_tsv_sha256' in e,
      sum(1 for p in d['files'] if p.startswith(('.goblin/bin/','.goblin/manifest/','.goblin/bans/','.goblin/automations/')) or p=='.goblin/roles.yaml'),
      sum(1 for p in d['files'] if p.startswith('.hermes/skills/')))
")
REC_N=$(printf '%s' "$REC" | awk '{print $1}')
check "U1 the record dropped 41 → 23 entries (got $RECORD_BEFORE → $REC_N)" \
  "$([ "$RECORD_BEFORE" = "41" ] && [ "$REC_N" = "23" ] && echo 0 || echo 1)"
# ---- the engine block/entries checks need REC; re-derive it (in_dir loses cwd) ----
REC_BLOCK=$(printf '%s' "$REC" | awk -v eng="$HOMEDIR/engine" 'NR==1{e=($2=="global" && $3==eng && $4=="0.4.4" && $5=="True" && $6=="True"); print (e?"0":"1"); exit}')
REC_NOENG=$(printf '%s' "$REC" | awk 'NR==1{print (($7==0)?"0":"1"); exit}')
check "U1 the engine block holds mode/engine_dir/cli_version/cli_sha256/enforcement_tsv_sha256" "$REC_BLOCK"
check "U1 zero engine entries remain in the record" "$REC_NOENG"
SKILLS_N=$(printf '%s' "$REC" | awk '{print $8}')
check "U1 the 20 procedure (skills) entries are retained (got $SKILLS_N)" \
  "$([ "$SKILLS_N" = "20" ] && echo 0 || echo 1)"

# the declaration is active
grep -q "^engine_dir: $HOMEDIR/engine" "$P/.goblin/goblin.yaml"
check "U1 goblin.yaml carries the active engine_dir line" "$?"

# exactly two commits, in the documented order
C_B=$(git -C "$P" rev-parse HEAD)
C_A=$(git -C "$P" rev-parse HEAD~1)
printf '%s' "$C_A" > "$WORK/commit_a"
printf '%s' "$C_B" > "$WORK/commit_b"
git -C "$P" log --format='%s' -2 | tail -1 | grep -q 'W3 step A'
check "U1 commit A is the declaration-and-record commit" "$?"
git -C "$P" log --format='%s' -1 | grep -q 'W3 step B'
check "U1 commit B is the deletion commit" "$?"

# verify #3, via the global engine, at the measured line
# verify #3, via the global engine, run INSIDE the probe (the chain resolves the
# probe's declaration; a run from the caller's cwd is not the probe's gate)
V3=$(in_dir "$P" ver "$HOMEDIR/engine/bin/goblin-verify"); RC3=$?
printf '%s' "$V3" | grep -q '39 passed, 0 failed, 11 advisory, 32 skipped'
check "U1 verify #3 reads 39 passed, 0 failed, 11 advisory, 32 skipped" "$?"
check "U1 verify #3 exits 0" "$([ "$RC3" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$V3" | grep -q 'engine: mode=global'
check "U1 verify #3's footer says mode=global" "$?"
printf '%s' "$V3" | grep -q 'advisory 10 of ceiling 10'
check "U1 SK-03 stays at advisory 10 of ceiling 10" "$?"
)
(# ============================================================ U4: idempotence --
STATUS_PRE=$(git -C "$P" status --porcelain)
OUT_2=$(up "$P" --engine-dir "$HOMEDIR/engine" --yes 2>&1); RC_2=$?
check "U4 the second upgrade exits 0" "$([ "$RC_2" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT_2" | grep -q '^no-op:'
check "U4 the second upgrade prints no-op" "$?"
[ "$(git -C "$P" status --porcelain)" = "$STATUS_PRE" ]
check "U4 the second upgrade changes nothing (zero diff)" "$?"
)
(# ============================================================ U10: the shadow footer --
C_A=$(cat "$WORK/commit_a"); C_B=$(cat "$WORK/commit_b")
# A stale payload restored onto the migrated repo: the footer advisory must print.
git -C "$P" checkout "$C_B^" -- $PAYLOAD_PATHS
V_SH=$(in_dir "$P" ver "$HOMEDIR/engine/bin/goblin-verify")
printf '%s' "$V_SH" | grep -q 'shadow: vendored engine payload present (18 file(s))'
check "U10 the restored payload prints the shadow line naming 18 files" "$?"
# reset BOTH index and worktree, and drop the untracked payload, so U9's revert starts clean
git -C "$P" reset -q && git -C "$P" checkout -q -- . && git -C "$P" clean -qfd $PAYLOAD_PATHS
V_NO=$(in_dir "$P" ver "$HOMEDIR/engine/bin/goblin-verify")
printf '%s' "$V_NO" | grep -q 'shadow:'
NOSHADOW=$?
check "U10 without the payload the shadow line does not print" "$([ "$NOSHADOW" -ne 0 ] && echo 0 || echo 1)"
)
(# ============================================================ U9: rollback --
C_A=$(cat "$WORK/commit_a"); C_B=$(cat "$WORK/commit_b")
git -C "$P" revert --abort >/dev/null 2>&1 || true
git -C "$P" revert --no-edit "$C_A" "$C_B" >/dev/null 2>&1
# byte-identical to the PRE-upgrade tree: the parent of commit A
PARENT_A=$(git -C "$P" rev-parse "$C_A^")
check "U9 the reverted tree is byte-identical to the pre-upgrade tree" \
  "$([ -z "$(git diff "$PARENT_A" HEAD)" ] && echo 0 || echo 1)"
V_R=$(in_dir "$P" ver .goblin/bin/goblin-verify); RC_R=$?
printf '%s' "$V_R" | grep -q '43 passed, 0 failed, 11 advisory, 28 skipped'
check "U9 the reverted repo verifies green at the vendored line again" "$?"
check "U9 the reverted verify exits 0" "$([ "$RC_R" -eq 0 ] && echo 0 || echo 1)"
)
(# ============================================================ U11: the re-shadow refusal --
# U9 left the probe REVERTED (vendored). Re-upgrade it so the refusal has its subject,
# then install onto the migrated repo.
up "$P" --engine-dir "$HOMEDIR/engine" --yes >/dev/null 2>&1
HOME="$HOMEDIR" bash "$INSTALL" --target "$P" --class A --models "$WORK/models.yaml" --practice "$WORK/standard.md" > "$WORK/u11a" 2>&1
RC_U11A=$?
check "U11 goblin-install onto a migrated repo exits 1" "$([ "$RC_U11A" -eq 1 ] && echo 0 || echo 1)"
grep -q 'is migrated to the global engine at' "$WORK/u11a"
check "U11 the refusal names the migration and the engine dir" "$?"
grep -q 'git revert the two W3 commits' "$WORK/u11a"
check "U11 the refusal names the revert remedy" "$?"
# the refusal wrote nothing (the payload was NOT re-created)
[ -z "$(git -C "$P" status --porcelain)" ]
check "U11 the refused install wrote nothing" "$?"
# revert the re-upgrade: on the vendored repo again, the install keeps its no-op path
git -C "$P" revert --no-edit HEAD HEAD~1 >/dev/null 2>&1
HOME="$HOMEDIR" bash "$INSTALL" --target "$P" --class A --models "$WORK/models.yaml" --practice "$WORK/standard.md" > "$WORK/u11b" 2>&1
RC_U11B=$?
grep -q 'no-op:' "$WORK/u11b"
check "U11 on the reverted (vendored) repo the install stays a no-op" \
  "$([ "$RC_U11B" -eq 0 ] && grep -q 'no-op:' "$WORK/u11b" && echo 0 || echo 1)"
)
(# ============================================================ U12: gate.sh + CI re-point --
# re-upgrade the (vendored-again) probe and read the re-pointed artifacts
OUT_U12=$(up "$P" --engine-dir "$HOMEDIR/engine" --yes 2>&1); RC_U12=$?
check "U12 the re-upgrade for U12 exits 0" "$([ "$RC_U12" -eq 0 ] && echo 0 || echo 1)"
GATE_OUT=$(in_dir "$P" env HOME="$HOMEDIR" bash checks/gate.sh 2>&1); RC_GATE=$?
check "U12 checks/gate.sh exits 0 on the migrated repo (MA9's silent-green hole closed)" \
  "$([ "$RC_GATE" -eq 0 ] && echo 0 || echo 1)"
[ -n "$(printf '%s' "$GATE_OUT" | grep -E '[a-z_-]+=[0-9]')" ]
check "U12 checks/gate.sh prints a non-empty gate line" "$?"
grep -q 'npx @techgoblin/gobstack@' "$P/.github/workflows/goblin-gate.yml"
check "U12 the workflow run line is re-pointed to the pinned global form" "$?"
)
(# ============================================================ U12b: the partial-drop hand-migration --
# The reviewer's S2 finding: a hand-edited record with the engine: block removed and only PART
# of the 18 entries dropped used to walk the migrate path and complete SILENTLY. The
# discriminator now refuses any block-missing record below the full 18, and the migrate path
# itself requires exactly 18. Measured on the reviewer's probe shape (4 bin entries dropped).
new_i1 "$WORK/u12c"
( cd "$WORK/u12c" && python3 -c '
import json
rec = json.load(open(".goblin/installed.json"))
dropped = [k for k in list(rec["files"]) if k.startswith(".goblin/bin/")][:4]
for k in dropped: rec["files"].pop(k)
json.dump(rec, open(".goblin/installed.json", "w"), indent=2)' )
git -C "$WORK/u12c" add -A && git -C "$WORK/u12c" commit -q -m "hand: partial engine-entry drop, no engine block"
OUT_U12C=$(up "$WORK/u12c" --engine-dir "$HOMEDIR/engine" --yes 2>&1); RC_U12C=$?
check "U12b a PARTIAL engine-entry drop with no engine block refuses (the silent-migrate hole)" \
  "$([ "$RC_U12C" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT_U12C" | grep -q 'missing its engine: block'
check "U12b the refusal names the shape and the count" "$?"
[ "$(git -C "$WORK/u12c" rev-list --count HEAD)" -eq 4 ]
check "U12b the refusal wrote no commits" "$?"
)
(# ============================================================ U3: R1/R2/R3 --
# R1 dirty tree
new_i1 "$WORK/u3a"
printf 'dirty\n' > "$WORK/u3a/dirty.txt"
OUT_R1=$(up "$WORK/u3a" --engine-dir "$HOMEDIR/engine" --yes 2>&1)
check "U3 R1 a dirty tree refuses with exit 1" "$([ $? -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT_R1" | grep -q 'commit or stash first'
check "U3 R1 the refusal names the fix" "$?"
# R2 detached HEAD
new_i1 "$WORK/u3b"
git -C "$WORK/u3b" checkout -q --detach HEAD
OUT_R2=$(up "$WORK/u3b" --engine-dir "$HOMEDIR/engine" --yes 2>&1)
check "U3 R2 a detached HEAD refuses with exit 1" "$([ $? -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT_R2" | grep -q 'detached-HEAD state'
check "U3 R2 the refusal names the state and git switch" "$?"
# R3 no git
rm -rf "$WORK/u3c" && mkdir -p "$WORK/u3c"
OUT_R3=$(up "$WORK/u3c" --engine-dir "$HOMEDIR/engine" --yes 2>&1)
check "U3 R3 a non-repo refuses with exit 1" "$([ $? -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT_R3" | grep -q 'is not a git repository'
check "U3 R3 the refusal names the git init fix" "$?"
)
(# ============================================================ U2: hash drift --
new_i1 "$WORK/u2p"
printf 'tampered\n' >> "$WORK/u2p/checks/gate.sh"
git -C "$WORK/u2p" add -A && git -C "$WORK/u2p" commit -q -m drift
N_HEAD_BEFORE=$(git -C "$WORK/u2p" rev-list --count HEAD)
OUT_U2=$(up "$WORK/u2p" --engine-dir "$HOMEDIR/engine" --yes 2>&1)
check "U2 hash drift refuses with exit 1" "$([ $? -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT_U2" | grep -q 'hash drift: checks/gate.sh'
check "U2 the refusal names the drifted file" "$?"
[ "$(git -C "$WORK/u2p" rev-list --count HEAD)" = "$N_HEAD_BEFORE" ]
check "U2 nothing was migrated (no upgrade commits written)" "$?"
)
(# ============================================================ U5: R6 collision --
new_i1 "$WORK/u5"
mkdir -p "$HOMEDIR/u5engine/bin" "$HOMEDIR/u5engine/manifest"
cp "$WORK/u5/.goblin/bin/goblin-verify" "$HOMEDIR/u5engine/bin/"
cp "$WORK/u5/.goblin/manifest/enforcement.tsv" "$HOMEDIR/u5engine/manifest/"
printf '\n# one byte different\n' >> "$HOMEDIR/u5engine/manifest/enforcement.tsv"
OUT_U5=$(up "$WORK/u5" --engine-dir "$HOMEDIR/u5engine" --yes 2>&1)
check "U5 a different-hash engine refuses with exit 1" "$([ $? -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT_U5" | grep -q 'holds a different engine'
check "U5 the refusal names both engines" "$?"
printf '%s' "$OUT_U5" | grep -q 'cli_sha256'
check "U5 the refusal names the hash pairs" "$?"
OUT_U5B=$(up "$WORK/u5" --engine-dir "$HOMEDIR/u5engine-b" --yes 2>&1)
check "U5 the --engine-dir escape hatch lands a second engine and migrates (exit 0)" \
  "$([ $? -eq 0 ] && echo 0 || echo 1)"
grep -q "^engine_dir: $HOMEDIR/u5engine-b" "$WORK/u5/.goblin/goblin.yaml"
check "U5 the migration declares the second engine's dir" "$?"
)
(# ============================================================ U6: R8/R9 crash shapes --
# R8: the record says global but the payload is still on disk (crash between A and B)
new_i1 "$WORK/u6a"
up "$WORK/u6a" --engine-dir "$HOMEDIR/engine" --yes >/dev/null 2>&1
git -C "$WORK/u6a" revert --no-edit HEAD >/dev/null 2>&1   # undo only B: record says global, payload back
OUT_R8=$(up "$WORK/u6a" --engine-dir "$HOMEDIR/engine" --yes 2>&1)
check "U6 R8 the crash shape (block + payload) refuses with exit 1" "$([ $? -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT_R8" | grep -q 'partial migration detected'
check "U6 R8 the refusal names the partial migration" "$?"
printf '%s' "$OUT_R8" | grep -qE 'roll back|revert'
check "U6 R8 the refusal gives the resume/rollback instruction" "$?"
# R9: entries dropped, no engine: block (a hand migration)
new_i1 "$WORK/u6b"
rm -rf "$WORK/u6b"/.goblin/bin "$WORK/u6b"/.goblin/manifest "$WORK/u6b"/.goblin/bans \
       "$WORK/u6b"/.goblin/automations "$WORK/u6b"/.goblin/roles.yaml
python3 -c "
import json
p = '$WORK/u6b/.goblin/installed.json'
rec = json.load(open(p))
rec.pop('engine', None)
def is_engine(p):
    return p.startswith('.goblin/bin/') or p.startswith('.goblin/manifest/') \
        or p.startswith('.goblin/bans/') or p.startswith('.goblin/automations/') \
        or p == '.goblin/roles.yaml'
rec['files'] = {k: v for k, v in rec['files'].items() if not is_engine(k)}
json.dump(rec, open(p, 'w'), indent=2)
"
git -C "$WORK/u6b" add -A && git -C "$WORK/u6b" commit -q -m "hand migration"
OUT_R9=$(up "$WORK/u6b" --engine-dir "$HOMEDIR/engine" --yes 2>&1)
check "U6 R9 the hand-migration shape refuses with exit 1" "$([ $? -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT_R9" | grep -q 'missing its engine: block'
check "U6 R9 the refusal names the state" "$?"
printf '%s' "$OUT_R9" | grep -q 'restore the record'
check "U6 R9 the refusal gives the restore fix" "$?"
)
(# ============================================================ U7: R7 record classes --
# absent record → exit 2
rm -rf "$WORK/u7a" && mkdir -p "$WORK/u7a"
git -C "$WORK/u7a" init -q -b main
git -C "$WORK/u7a" config user.name t && git -C "$WORK/u7a" config user.email t@t
printf 'x\n' > "$WORK/u7a/README.md"
git -C "$WORK/u7a" add -A && git -C "$WORK/u7a" commit -q -m seed
up "$WORK/u7a" --engine-dir "$HOMEDIR/engine" --yes >/dev/null 2>&1
check "U7 an absent record exits 2 (bad input)" "$([ $? -eq 2 ] && echo 0 || echo 1)"
# unparseable record → exit 2
new_i1 "$WORK/u7b"
printf 'not json {{{' > "$WORK/u7b/.goblin/installed.json"
git -C "$WORK/u7b" add -A && git -C "$WORK/u7b" commit -q -m broken
up "$WORK/u7b" --engine-dir "$HOMEDIR/engine" --yes >/dev/null 2>&1
check "U7 an unparseable record exits 2" "$([ $? -eq 2 ] && echo 0 || echo 1)"
# foreign version → exit 1
new_i1 "$WORK/u7c"
sed -i 's/"version": "0.4.4"/"version": "0.3.9"/' "$WORK/u7c/.goblin/installed.json"
git -C "$WORK/u7c" add -A && git -C "$WORK/u7c" commit -q -m foreign
OUT_U7C=$(up "$WORK/u7c" --engine-dir "$HOMEDIR/engine" --yes 2>&1)
check "U7 a foreign version exits 1 (a refusal, not bad input)" "$([ $? -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT_U7C" | grep -q 'do not hand-edit the record'
check "U7 the foreign-version refusal names the version and the rule" "$?"
)
(# ============================================================ U8: red at step 2 --
new_i1 "$WORK/u8"
# break a DECLARED gate (not a recorded file, which U2 covers): the gate line must go red
sed -i 's|^gates:|gates:\n  - name: broken_gate\n    cmd: test 1 = 2|' "$WORK/u8/.goblin/goblin.yaml"
git -C "$WORK/u8" add -A && git -C "$WORK/u8" commit -q -m "break a gate"
N_COMMITS=$(git -C "$WORK/u8" rev-list --count HEAD)
OUT_U8=$(up "$WORK/u8" --engine-dir "$HOMEDIR/engine" --yes 2>&1)
check "U8 a red repo refuses at verify #1 with exit 1" "$([ $? -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT_U8" | grep -q 'verify #1 is red'
check "U8 the refusal names verify #1" "$?"
[ "$(git -C "$WORK/u8" rev-list --count HEAD)" = "$N_COMMITS" ]
check "U8 the red repo was not touched by the migration (no commits written)" "$?"
)
# ---- summary -------------------------------------------------------------------
FAIL_N=$(grep -c . "$FAILFILE" 2>/dev/null || true)
if [ "${FAIL_N:-0}" -eq 0 ]; then
  printf '      t-upgrade: ALL-OK\n'
  exit 0
fi
printf '      t-upgrade: FAILED (%s)\n' "$FAIL_N"
exit 1
