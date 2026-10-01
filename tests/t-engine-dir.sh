#!/usr/bin/env bash
# t-engine-dir.sh — W1: the `engine_dir:` declaration key, its validation, and the
# resolution chain. Run by tests/run-tests.sh.
#
# What it covers (the spec's §1.2 schema stages 1-4, §2.3 chain precedence, §4 A8/A9):
#   absent key            -> every path resolves as before; byte-identical verify vs the
#                            pre-declaration tree (§1.3, the back-compat contract)
#   valid engine_dir      -> verify runs GREEN against the declared engine's manifest
#   nonexistent dir       -> verify exit 2, the refusal names the declared value and the
#                            chain tried (§2.4), and NOTHING falls back
#   relative path         -> exit 2: must be absolute or ~/-prefixed
#   non-string value      -> exit 2: must be a string path
#   ~-prefix              -> expanded once via $HOME at read time
#   chain precedence      -> --source > vendored > engine_dir: > GOBLIN_ENGINE_DIR >
#                            ~/.goblin/engine; the machine default is the fallback, never
#                            an override (A9), and a vendored engine beats a valid
#                            declaration (A7's tamper proof: one byte of the vendored
#                            manifest flips the footer's enforcement_tsv_sha256)
#   the footer            -> every run names cli_sha256 + enforcement_tsv_sha256, in both
#                            modes (§2.2)
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
HOMEDIR="$WORK/home"
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

printf 'profiles:\n  coder:\n    model: model-code\n    provider: prov-code\n    effort: low\n' > "$WORK/models.yaml"
printf 'the referenced standard\n' > "$WORK/standard.md"

# The declared engine: a directory holding nothing but the manifest the chain reads. The
# engine payload rows (IN-02's clause 2, SK-*, BN-*) are exercised in t-verify-red.sh;
# this suite is about WHERE the rule table comes from.
ENGINE="$WORK/engine"
mkdir -p "$ENGINE/manifest" "$ENGINE/bin" "$HOMEDIR"
cp "$SRC/manifest/enforcement.tsv" "$ENGINE/manifest/enforcement.tsv"
cp "$SRC/manifest/classes.tsv" "$ENGINE/manifest/classes.tsv"
cp "$SRC/manifest/bans.tsv" "$ENGINE/manifest/bans.tsv"
cp "$SRC/bin/goblin-bans" "$SRC/bin/goblin-lib.sh" "$ENGINE/bin/"
# The BN rows (BN-00..BN-09, bans: list in goblin.yaml) run the resolved engine's own
# goblin-bans binary against ITS ban table (W1 §2.5) — an engine_dir holding only the
# enforcement manifest is not a complete engine and every exit-0 probe fails BN-closed.

# A real adopted repo, built the way a tenant actually builds one - goblin-install, then the
# W3-shaped migration edit (the engine payload removed, the install record's engine: block
# rewritten to mode=global, the engine_dir: declaration added). The declaration-only probes
# must satisfy the GLOBAL-mode rows (IN-01/IN-04 SKIP on the missing record only when there
# IS no record; here a migrated record exists and must still verify GREEN, IN-02 clause 2
# hashes what IS recorded, HP/GT/CL need the project doc the install writes). Each case
# rebuilds the probe and rewrites only .goblin/goblin.yaml's engine_dir line (and the HOME
# the verify runs under).
new_probe() {
  rm -rf "$WORK/probe"
  mkdir -p "$WORK/probe" "$HOMEDIR"
  cd "$WORK/probe" || exit 1
  git init -q -b main
  git config user.name "Test Runner"
  git config user.email "runner@example.com"
  printf '# the probe repo\n' > README.md
  git add -A && git commit -q -m "seed the probe"
  bash "$SRC/bin/goblin-install" --target . --class A --models "$WORK/models.yaml" \
    --practice "$WORK/standard.md" >/dev/null 2>&1
  git add -A && git commit -q -m "install gobstack"
  sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
  git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"
  # The migrated-to-global state: engine payload gone, the record says so, the
  # declaration points at the engine this suite owns.
  rm -rf .goblin/bin .goblin/manifest .goblin/bans .goblin/automations .goblin/roles.yaml
  python3 -c '
import json
rec = json.load(open(".goblin/installed.json"))
rec["engine"] = {"mode": "global", "engine_dir": "ENGINE_DIR_PLACEHOLDER", "cli_version": "0.4.4", "cli_sha256": "a", "enforcement_tsv_sha256": "b"}
json.dump(rec, open(".goblin/installed.json", "w"), indent=2)'
  git add -A && git commit -q -m "migrate the engine to a declared global engine_dir"
}
declare_engine() { sed -i "/^models_file:/a engine_dir: $1" .goblin/goblin.yaml; }
# CM-03 (max_dirty 0) FAILs on an uncommitted declaration: a case that edits goblin.yaml
# must commit the edit BEFORE verify, exactly as a real operator would. drop_engine reverts.
commit_decl() { git add -A && git commit -q -m "declare engine_dir: $1"; }
declare_and_commit() { declare_engine "$1" && commit_decl "$1"; }
drop_engine() { sed -i '/^engine_dir:/d' .goblin/goblin.yaml; git add -A 2>/dev/null; git commit -q -m "drop the declaration" 2>/dev/null; return 0; }

v() { HOME="$HOMEDIR" bash "$SRC/bin/goblin-verify" "$@" 2>&1; }

# ---- the back-compat contract (§1.3): absent key resolves exactly as before -------------------
new_probe
# Absent key on a migrated repo: the chain degrades to the machine default. Give the machine
# its default engine (~/.goblin/engine, W3's end state) so the BN lane has a ban engine to
# run - the record's engine: block alone says mode=global, and resolution fills the rest.
mkdir -p "$HOMEDIR/.goblin/engine/manifest" "$HOMEDIR/.goblin/engine/bin"
cp "$SRC/manifest/enforcement.tsv" "$SRC/manifest/classes.tsv" "$SRC/manifest/bans.tsv" "$HOMEDIR/.goblin/engine/manifest/"
cp "$SRC/bin/goblin-bans" "$SRC/bin/goblin-lib.sh" "$HOMEDIR/.goblin/engine/bin/"
V2=$(v)
V3=$(v)
check "engine_dir absent: two runs of the same tree are byte-identical" \
  "$(diff <(printf '%s' "$V2") <(printf '%s' "$V3") >/dev/null && echo 0 || echo 1)"
printf '%s' "$V3" | grep -qE '^ *[0-9]+ passed, 0 failed'
check "  and the declaration-only probe verifies without a failed row" "$?"

# ---- a valid engine_dir resolves and verifies GREEN -------------------------------------------
declare_and_commit $ENGINE
OUT=$(v); RC=$?
check "a valid engine_dir verifies (exit 0)" "$([ "$RC" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -q 'engine: mode=global'
check "  and the footer names the global mode" "$?"
printf '%s' "$OUT" | grep -q "engine_dir=$ENGINE"
check "  and the footer names the resolved engine dir" "$?"

# ---- stage 3 (§1.2): a nonexistent dir is exit 2, no fallback ---------------------------------
new_probe
sed -i "s|^models_file:|engine_dir: $WORK\/nowhere\nmodels_file:|" .goblin/goblin.yaml
OUT=$(v); RC=$?
check "engine_dir -> a nonexistent dir is exit 2 (§2.4)" "$([ "$RC" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -qF "engine_dir: $WORK/nowhere does not exist"
check "  and the refusal names the declared value" "$?"
printf '%s' "$OUT" | grep -q 'no manifest at any of'
check "  and it names the chain tried" "$?"
printf '%s' "$OUT" | grep -qv 'mode=global'
check "  and nothing fell back (no global footer was printed)" "$?"

# ---- stage 2: a relative path is refused ------------------------------------------------------
new_probe
sed -i "s|^models_file:|engine_dir: relative\/engine\nmodels_file:|" .goblin/goblin.yaml
OUT=$(v); RC=$?
check "a relative engine_dir is exit 2" "$([ "$RC" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -qF "must be absolute or ~/-prefixed: relative/engine"
check "  and the refusal names the shape rule and the value" "$?"

# ---- stage 1: a non-string value is refused ---------------------------------------------------
new_probe
declare_and_commit "[a, b]"
OUT=$(v); RC=$?
check "a list-valued engine_dir is exit 2" "$([ "$RC" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -qF 'engine_dir: must be a string path'
check "  and the refusal names the type rule" "$?"

# ---- stage 4: a directory with no manifest is not an engine -----------------------------------
new_probe
mkdir -p "$WORK/notengine"
sed -i "s|^models_file:|engine_dir: $WORK\/notengine\nmodels_file:|" .goblin/goblin.yaml
OUT=$(v); RC=$?
check "an engine_dir with no manifest/enforcement.tsv is exit 2" "$([ "$RC" -eq 2 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -qF 'no manifest/enforcement.tsv under'
check "  and the refusal says it is not an engine directory" "$?"

# ---- ~-prefix resolution (Q3) -----------------------------------------------------------------
new_probe
mkdir -p "$HOMEDIR/.engine-home/bin"
cp -r "$ENGINE/manifest" "$HOMEDIR/.engine-home/manifest"
cp "$ENGINE/bin/goblin-bans" "$ENGINE/bin/goblin-lib.sh" "$HOMEDIR/.engine-home/bin/"
sed -i "s|^models_file:|engine_dir: ~\/.engine-home\nmodels_file:|" .goblin/goblin.yaml
git add -A && git commit -q -m "declare engine_dir: ~/.engine-home"
OUT=$(v); RC=$?
check "a ~/-prefixed engine_dir resolves via \$HOME (exit 0)" "$([ "$RC" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -qF "engine_dir=$HOMEDIR/.engine-home"
check "  and the footer names the EXPANDED path" "$?"

# ---- chain precedence (§2.3, A9): declaration beats the machine default -----------------------
new_probe
mkdir -p "$HOMEDIR/.goblin/engine/manifest" "$HOMEDIR/.goblin/engine/bin"
cp "$SRC/manifest/enforcement.tsv" "$HOMEDIR/.goblin/engine/manifest/enforcement.tsv"
cp "$SRC/manifest/classes.tsv" "$HOMEDIR/.goblin/engine/manifest/classes.tsv"
cp "$SRC/manifest/bans.tsv" "$HOMEDIR/.goblin/engine/manifest/bans.tsv"
cp "$SRC/bin/goblin-bans" "$SRC/bin/goblin-lib.sh" "$HOMEDIR/.goblin/engine/bin/"
declare_and_commit $ENGINE
OUT=$(v); RC=$?
check "declaration and ~/.goblin/engine both present: exit 0" "$([ "$RC" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -qF "engine_dir=$ENGINE"
check "  and the DECLARED engine won (A9: the most specific declaration wins)" "$?"

# GOBLIN_ENGINE_DIR beats ~/.goblin/engine; the declaration beats both.
new_probe
drop_engine   # the no-declaration case: the defaults compete; new_probe left NO declaration, so this is a no-op commit-free revert
out=$(GOBLIN_ENGINE_DIR="$HOMEDIR/.engine-home" v)
printf '%s' "$out" | grep -qF "engine_dir=$HOMEDIR/.engine-home"
check "no declaration: GOBLIN_ENGINE_DIR is consulted before ~/.goblin/engine" "$([ $? -eq 0 ] && echo 0 || echo 1)"
# re-declare for the beats-both assertion: the declaration must win over the env default
declare_and_commit $ENGINE
OUT=$(GOBLIN_ENGINE_DIR="$HOMEDIR/.engine-home" v)
printf '%s' "$OUT" | grep -qF "engine_dir=$ENGINE"
check "  and the declaration still beats GOBLIN_ENGINE_DIR" "$?"

# ---- A7: vendored still wins over a valid declaration -----------------------------------------
new_probe
# A per-repo install mid-migration: the engine: block is removed again (this repo is NOT
# migrated - a pure vendored repo that merely carries a declaration), and the FULL vendored
# payload is planted by hand with the manifest bytes differing from $ENGINE's by one comment
# line, so the two manifests hash differently and the footer tells them apart. Vendored must
# win (A7): a repo-local engine outranks any declared global one.
mkdir -p .goblin/manifest .goblin/bin
cp "$SRC/manifest/enforcement.tsv" .goblin/manifest/enforcement.tsv
cp "$SRC/manifest/classes.tsv" "$SRC/manifest/bans.tsv" .goblin/manifest/
cp "$SRC/bin/goblin-bans" "$SRC/bin/goblin-lib.sh" .goblin/bin/
python3 -c '
import json
rec = json.load(open(".goblin/installed.json"))
rec.pop("engine", None)
json.dump(rec, open(".goblin/installed.json", "w"), indent=2)'
git add -A && git commit -q -m "a vendored repo that also carries a declaration"
declare_and_commit $ENGINE
OUT=$(v)
printf '%s' "$OUT" | grep -q 'mode=vendored'
check "vendored engine + valid declaration: mode=vendored (A7: vendored wins)" "$?"
printf '%s' "$OUT" | grep -q 'mode=global'
check "  and no global footer was printed" "$([ $? -eq 1 ] && echo 0 || echo 1)"

# ---- A3: the footer's hash pair names what actually judged ------------------------------------
F_LINE=$(printf '%s' "$OUT" | grep -m1 'cli_sha256=')
H_LOCAL=$(sha256sum .goblin/manifest/enforcement.tsv | cut -d' ' -f1)
printf '%s' "$F_LINE" | grep -qF "enforcement_tsv_sha256=$H_LOCAL"
check "the footer's enforcement hash is the vendored manifest's actual sha256" "$?"

# ---- the engine hash MOVES when the judged manifest changes (the tamper proof) ----------------
new_probe
declare_and_commit $ENGINE
H1=$(v | grep -m1 'cli_sha256=' | sed -n 's/.*enforcement_tsv_sha256=\([0-9a-f]*\).*/\1/p')
# Tamper must keep the manifest SHAPE-VALID: appending a bare line makes the manifest broken
# (exit 3, no footer, nothing to compare). Edit a description cell in a row instead - the
# bytes change, the table still parses, and the footer's fingerprint must move.
sed -i '0,/The repo is portable: no personal path in any reusable rule\./s//The repo is portable: no personal path in any reusable RULE./' "$ENGINE/manifest/enforcement.tsv"
H2=$(v | grep -m1 'cli_sha256=' | sed -n 's/.*enforcement_tsv_sha256=\([0-9a-f]*\).*/\1/p')
check "tampering the engine manifest flips the footer's enforcement hash" \
  "$([ -n "$H1" ] && [ -n "$H2" ] && [ "$H1" != "$H2" ] && echo 0 || echo 1)"

if [ "$fail" -eq 0 ]; then note "t-engine-dir: PASS"; else note "t-engine-dir: FAIL"; fi
exit "$fail"
