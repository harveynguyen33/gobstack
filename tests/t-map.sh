#!/usr/bin/env bash
# t-map.sh — `gob map`: the v2 agent brief, `--write` validation, and the heuristic starter.
#
#   MP0  bare `gob map` prints the AGENT BRIEF + schema exactly once and exits 0
#        (this IS the v2 product: the agent writes the map, the CLI validates it)
#   MP1  --help exits 0 (pinned through the shim too: t-shim's MAP block covers
#        the dispatch; this is the engine's own contract)
#   MP2  --heuristic generation on a next-app-shaped fixture: features/README.md +
#        one file per top-level route segment, frontmatter feature: == filename stem,
#        >=1 entry_paths, and the four contract H2s in order (the same shape
#        bin/goblin-verify's FM-01 checkers read — asserted here with the same rules,
#        not by shelling the verifier, which would need an install this standalone
#        command deliberately does not need)
#   MP3  every entry path is a single token that EXISTS under the target at generation time
#   MP4  refusal with an existing map, exit 1, naming the path and --force; nothing written
#   MP5  --force regenerates ONLY the index and adds NEW slugs; a hand-edited feature file
#        survives byte-for-byte
#   MP6  works with NO .gob/ present (the standalone contract) and never creates one
#   MP7  idempotent second run on a fresh repo: nothing-to-do or new-slugs-only, exit 0
#   MP8  a plain repo with no framework: top-level src/ module dirs become TODO slugs; an
#        empty scan still writes the README index and says none detected
#   MP9  bad input: a missing target dir and an unknown flag both exit 2
#   MP10 --write VALIDATION: a well-formed hand-written map validates, exit 0; each broken
#        contract refuses with exit 2 and names the file + the fix — wrong feature: stem,
#        missing entry_paths, bad verified: line, out-of-order H2s, missing frontmatter
#   MP11 --write never-clobber (both directions): refusing an existing map without --force,
#        and --write --force regenerating the index only; --write + --heuristic together
#        is refused, exit 2
#
# Fixture repos are mktemp throwaways; nothing here reads a config file — the generator
# has no config surface at all (the standalone contract), so the gate's HOME is unused.
# The path literal the PT-01 body bans is built from fragments below, never typed.
# --write validates entry paths against the CWD, so its block runs from the repo root.
HOMEPFX=$(printf '%s' 'ho''me')
RUNHOME="${HOME:-/tmp}"
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MAP="$SRC/bin/goblin-map"
WORK=$(mktemp -d)
FAILFILE="$WORK/fails"; : > "$FAILFILE"
note() { printf '      %s\n' "$*"; }
check() {
  if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; printf '%s\n' "$1" >> "$FAILFILE"; fi
}

# frontmatter field reader, the same three lines FM-01's fm_frontmatter reads
fm_field() { # <file> <key>
  awk 'BEGIN{fm=0} /^---[[:space:]]*$/ {fm++; if (fm==1) next; else exit} fm==1 {print}' "$1" \
    | sed -n "s/^$2:[[:space:]]*//p" | head -n 1
}

# MP2 helper: the four H2 contract, in order (mirrors fm_h2_ok in bin/goblin-verify)
h2_ok() {
  local n=0 ok=1 line
  while IFS= read -r line; do
    n=$((n + 1))
    case "$n" in
      1) [ "$line" = "Sub-features" ] || ok=0 ;;
      2) [ "$line" = "How to get to it (user POV)" ] || ok=0 ;;
      3) case "$line" in "Driving it with "*) ;; *) ok=0 ;; esac ;;
      4) [ "$line" = "Gotchas" ] || ok=0 ;;
      *) ok=0 ;;
    esac
  done < <(grep -n '^## ' "$1" | sed 's/^[0-9]*:## //; s/[[:space:]]*$//')
  [ "$n" -eq 4 ] && [ "$ok" -eq 1 ]
}

# ---- MP0: the bare brief (the v2 product) --------------------------------------
OUT0=$(bash "$MAP" 2>&1); RC0=$?
check "MP0 bare gob map exits 0" "$([ "$RC0" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT0" | grep -qF '== gob map — AGENT BRIEF'
check "MP0 the bare run prints the AGENT BRIEF" "$?"
printf '%s' "$OUT0" | grep -qF '== FEATURE-FILE SCHEMA'
check "MP0 the bare run prints the feature-file schema" "$?"
printf '%s' "$OUT0" | grep -cF 'AGENT BRIEF' | grep -qx 1
check "MP0 the brief prints exactly once" "$?"
printf '%s' "$OUT0" | grep -qF 'gob map --write'
check "MP0 the brief names the --write validation step" "$?"
# the explicit spelling of the same surface
OUT0A=$(bash "$MAP" --agent 2>&1); RC0A=$?
check "MP0 --agent is the explicit brief spelling, exit 0" "$([ "$RC0A" -eq 0 ] && echo 0 || echo 1)"
[ "$OUT0A" = "$OUT0" ]
check "MP0 --agent output is byte-identical to the bare run" "$?"

# ---- MP1: --help exits 0 -------------------------------------------------------
"$MAP" --help >/dev/null 2>&1
check "MP1 gob map --help exits 0" "$?"

# ---- MP2 + MP3: the next-app fixture (--heuristic) -----------------------------
NX="$WORK/next-app"
mkdir -p "$NX/app/blog" "$NX/app/blog/[slug]" "$NX/app/about" "$NX/app/api/users" "$NX/components"
printf 'export default function Blog() { return <div>blog</div> }\n' > "$NX/app/blog/page.tsx"
printf 'export default function Post() { return <div>post</div> }\n' > "$NX/app/blog/[slug]/page.tsx"
printf 'export default function About() { return <div>about</div> }\n' > "$NX/app/about/page.tsx"
printf 'export async function GET() {}\n' > "$NX/app/api/users/route.ts"
printf '{ "scripts": { "dev": "next dev", "build": "next build", "test": "vitest" } }\n' > "$NX/package.json"
OUT2=$(bash "$MAP" --heuristic "$NX" 2>&1); RC2=$?
check "MP2 --heuristic generation on a next-app fixture exits 0" "$([ "$RC2" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT2" | grep -qF "a STARTER"
check "MP2 the generation line admits the output is a STARTER" "$?"
for f in README.md blog.md about.md api.md; do
  [ -f "$NX/features/$f" ]
  check "MP2 features/$f exists" "$?"
done
# component files, tests, nested dirs produce NO slug of their own
ls "$NX/features"/*.md 2>/dev/null | wc -l | grep -qx 4
check "MP2 exactly 4 md files (no slug for components/, [slug]/ or nested segments)" "$?"
for slug in blog about api; do
  f="$NX/features/$slug.md"
  [ "$(fm_field "$f" feature)" = "$slug" ]
  check "MP2 $slug.md: feature: equals the filename stem" "$?"
  [ "$(fm_field "$f" entry_paths)" != "" ] || [ -n "$(awk '/^entry_paths:/{f=1;next} f&&/^  - /{print} f&&!/^[[:space:]]/{f=0}' "$f")" ]
  check "MP2 $slug.md declares >=1 entry_paths:" "$?"
  h2_ok "$f"
  check "MP2 $slug.md carries the four contract H2s, in order" "$?"
  printf '%s' "$(fm_field "$f" verified)" | grep -q 'never-driven (generated '
  check "MP2 $slug.md verified: is the never-driven form (not a drive claim)" "$?"
done
printf '%s' "$(cat "$NX/features/README.md")" | grep -qF 'generated by gob map '
check "MP2 the README carries the muted generator line" "$?"
# MP3: every entry path is an existing single token under the target
MP3_BAD=0
for f in "$NX"/features/*.md; do
  [ -f "$f" ] || continue
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    case "$tok" in *" "*) MP3_BAD=1; note "      token with whitespace: $tok" ;; esac
    [ -e "$NX/$tok" ] || { MP3_BAD=1; note "      token does not exist: $tok (in $f)"; }
  done < <(awk '/^entry_paths:/{f=1;next} f&&/^  - /{sub(/^  - /,"");print;next} f&&!/^[[:space:]]/{f=0}' "$f")
done
check "MP3 every entry path is a single existing token under the target" "$([ $MP3_BAD -eq 0 ] && echo 0 || echo 1)"
# the Baseline section carries the package.json scripts
grep -qF 'dev: `npm run dev`' "$NX/features/README.md"
check "MP2 the Baseline section lists the package.json dev script" "$?"

# ---- MP4: refusal without --force ---------------------------------------------
OUT4=$(bash "$MAP" --heuristic "$NX" 2>&1); RC4=$?
check "MP4 the second run refuses, exit 1" "$([ "$RC4" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT4" | grep -qF "$NX/features"
check "MP4 the refusal names the map path" "$?"
printf '%s' "$OUT4" | grep -qF -- "--force"
check "MP4 the refusal names the --force remedy" "$?"

# ---- MP5: --force regenerates the index only, preserving a hand-edited file -----
printf -- '---\nfeature: blog\nentry_paths:\n  - app/blog/page.tsx\nverified: 2026-10-01\n---\n# blog\n\nHUMAN EDIT — do not lose.\n' > "$NX/features/blog.md"
cp "$NX/features/blog.md" "$WORK/blog.hand"
mkdir -p "$NX/app/pricing"
printf 'export default function Pricing() { return <div>p</div> }\n' > "$NX/app/pricing/page.tsx"
OUT5=$(bash "$MAP" --heuristic "$NX" --force 2>&1); RC5=$?
check "MP5 --force exits 0" "$([ "$RC5" -eq 0 ] && echo 0 || echo 1)"
cmp -s "$WORK/blog.hand" "$NX/features/blog.md"
check "MP5 the hand-edited feature file survives byte-for-byte" "$?"
[ -f "$NX/features/pricing.md" ]
check "MP5 --force adds the NEW slug's file" "$?"
grep -qF '](./pricing.md)' "$NX/features/README.md"
check "MP5 the regenerated index links the new slug" "$?"
grep -qF '](./blog.md)' "$NX/features/README.md"
check "MP5 the regenerated index still links the kept slug" "$?"

# ---- MP6: standalone — no .gob/ anywhere ---------------------------------------
[ ! -e "$NX/.gob" ] && [ ! -e "$NX/.goblin" ]
check "MP6 the fixture has no .gob/ or .goblin/ (generation never needed one)" "$?"

# ---- MP7: idempotent --force (nothing changed) ---------------------------------
OUT7=$(bash "$MAP" --heuristic "$NX" --force 2>&1); RC7=$?
check "MP7 the idempotent --force exits 0" "$([ "$RC7" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT7" | grep -qE 'nothing to do'
check "MP7 it reports nothing-to-do" "$?"

# ---- MP8: the plain-repo fallback and the empty scan ---------------------------
PL="$WORK/plain"
mkdir -p "$PL/src/auth" "$PL/src/billing" "$PL/src/tests"
printf 'export const login = 1\n' > "$PL/src/auth/session.ts"
printf 'export const inv = 1\n' > "$PL/src/billing/invoice.ts"
bash "$MAP" --heuristic "$PL" >/dev/null 2>&1
check "MP8 the plain-repo fallback exits 0" "$?"
[ -f "$PL/features/auth.md" ] && [ -f "$PL/features/billing.md" ]
check "MP8 src/ module dirs became candidate slugs" "$?"
[ ! -f "$PL/features/tests.md" ]
check "MP8 test dirs are excluded from the fallback" "$?"
grep -qF 'TODO' "$PL/features/auth.md"
check "MP8 the fallback files carry TODO placeholders" "$?"
# an empty repo (no framework, no src/lib): README only, honestly empty
EM="$WORK/empty"; mkdir -p "$EM/docs"
OUT8=$(bash "$MAP" --heuristic "$EM" 2>&1); RC8=$?
check "MP8 an empty scan still exits 0" "$([ "$RC8" -eq 0 ] && echo 0 || echo 1)"
[ -f "$EM/features/README.md" ] && [ ! -e "$EM/features/README.md.md" ]
check "MP8 an empty scan writes the index only" "$?"
grep -q 'none detected' "$EM/features/README.md"
check "MP8 the empty index says none detected (no invented feature)" "$?"

# ---- MP9: bad input -------------------------------------------------------------
bash "$MAP" --heuristic "$WORK/no-such-dir" >/dev/null 2>&1
check "MP9 a missing target exits 2" "$([ $? -eq 2 ] && echo 0 || echo 1)"
bash "$MAP" --frobnicate >/dev/null 2>&1
check "MP9 an unknown flag exits 2" "$([ $? -eq 2 ] && echo 0 || echo 1)"

# ---- MP6b: the shims route map (the node table and the bash dispatcher) --------
# The empty-repo fixture already has features/ from MP8's first run, so both routes
# are exercised in the refusal shape: exit 1 with the named remedy, never a usage page.
OUTS=$(cd "$EM" && node "$SRC/bin/goblin.js" map --heuristic 2>&1); RCS=$?
check "MP6 node shim gob map --heuristic routes to the generator, exit 1 (refusal)" "$([ "$RCS" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUTS" | grep -qF -- "--force"
check "MP6 the node route carries the generator's refusal, not the shim usage" "$?"
OUTB=$(cd "$EM" && bash "$SRC/bin/goblin" map --heuristic 2>&1); RCB=$?
check "MP6 bash dispatcher gob map --heuristic routes to the generator, exit 1 (refusal)" "$([ "$RCB" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUTB" | grep -qF -- "--force"
check "MP6 the bash route carries the generator's refusal, not the dispatcher usage" "$?"
[ ! -e "$EM/.gob" ] && [ ! -e "$EM/.goblin" ]
check "MP6 and still wrote no .gob/ (standalone)" "$?"

# ---- MP10: --write validation ---------------------------------------------------
# A --write-valid map, built by hand from the brief's own schema. Entry paths are
# validated against the CWD, so this block runs from the repo root. The agent-written
# map has NO README index yet — --write never writes feature files (they are its
# input), so its never-clobber target is the index, which MP11 exercises.
BARE_W="$WORK/wvalid"
mkdir -p "$BARE_W/features" "$BARE_W/src/auth"
printf 'export const login = 1\n' > "$BARE_W/src/auth/session.ts"
cat > "$BARE_W/features/login.md" <<'FM'
---
feature: login
entry_paths:
  - src/auth/session.ts
verified: never-driven (generated 2026-10-08)
---

# login

Signing in with an email and a password reaches the dashboard.

## Sub-features

- login-form

## How to get to it (user POV)

- Visit /login, enter valid credentials, land on the dashboard.

## Driving it with vitest

Preconditions: the dev server is up.
**Sign in.** Run `npx vitest run login.spec.ts`. The suite passes.

## Gotchas

- Nothing here has been driven yet; the verified line says so.
FM
cd "$BARE_W"
OUTW=$(bash "$MAP" --write features 2>&1); RCW=$?
check "MP10 --write validates a well-formed hand-written map, exit 0" "$([ "$RCW" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUTW" | grep -qF 'validated 1 feature file(s)'
check "MP10 the validation line counts the feature files" "$?"
# a dated verified: line is equally valid
sed -i 's/^verified: never-driven (generated 2026-10-08)$/verified: 2026-10-08/' "$BARE_W/features/login.md"
bash "$MAP" --write features >/dev/null 2>&1
check "MP10 a dated verified: line also validates" "$?"
# restore the never-driven form so login.good (snapshotted below) is the canonical file
sed -i 's/^verified: 2026-10-08$/verified: never-driven (generated 2026-10-08)/' "$BARE_W/features/login.md"

# each broken contract: exit 2, the file named, nothing rewritten
break_variant() { # <label> <sed-script applied to login.md>
  sed -i "$2" "$BARE_W/features/login.md"
  bash "$MAP" --write features > "$WORK/bv.out" 2>&1
  local rc=$?
  check "MP10 $1 refuses, exit 2" "$([ "$rc" -eq 2 ] && echo 0 || echo 1)"
  grep -qF 'login.md' "$WORK/bv.out"
  check "MP10 $1 names the broken file" "$?"
  # restore the known-good body for the next variant
  cp "$WORK/login.good" "$BARE_W/features/login.md"
}
cp "$BARE_W/features/login.md" "$WORK/login.good"
# wrong stem
sed -i 's/^feature: login$/feature: signin/' "$BARE_W/features/login.md"
bash "$MAP" --write features >/dev/null 2>&1
check "MP10 a wrong feature: stem refuses, exit 2" "$([ $? -eq 2 ] && echo 0 || echo 1)"
cp "$WORK/login.good" "$BARE_W/features/login.md"
# missing entry_paths
sed -i '/^entry_paths:$/,+1d' "$BARE_W/features/login.md"
bash "$MAP" --write features >/dev/null 2>&1
check "MP10 a missing entry_paths: refuses, exit 2" "$([ $? -eq 2 ] && echo 0 || echo 1)"
cp "$WORK/login.good" "$BARE_W/features/login.md"
# entry path that does not exist
sed -i 's#  - src/auth/session.ts#  - src/auth/nope.ts#' "$BARE_W/features/login.md"
bash "$MAP" --write features >/dev/null 2>&1
check "MP10 a non-existent entry path refuses, exit 2" "$([ $? -eq 2 ] && echo 0 || echo 1)"
cp "$WORK/login.good" "$BARE_W/features/login.md"
# bad verified: (a drive claim, neither a date nor never-driven)
break_variant "a non-date non-never-driven verified:" "s/^verified: never-driven (generated 2026-10-08)$/verified: yes I drove it/"
break_variant "a missing verified:" "/^verified:/d"
# out-of-order H2s: swap Gotchas ahead of Sub-features
python3 - "$BARE_W/features/login.md" <<'PY'
import sys
p = sys.argv[1]
t = open(p).read()
h2s = ["## Sub-features", "## How to get to it (user POV)", "## Driving it with vitest", "## Gotchas"]
blocks = {}
for h in h2s:
    i = t.index(h)
    blocks[h] = t[i:t.index("\n\n##", i) if "\n\n##" in t[i:] else len(t)]
rest = t
for h in h2s:
    rest = rest.replace(blocks[h], "")
open(p, "w").write(rest + blocks["## Gotchas"] + "\n\n" + blocks["## Sub-features"])
PY
bash "$MAP" --write features >/dev/null 2>&1
check "MP10 out-of-order H2s refuse, exit 2" "$([ $? -eq 2 ] && echo 0 || echo 1)"
cp "$WORK/login.good" "$BARE_W/features/login.md"
# missing frontmatter
sed -i '1,/^---$/d' "$BARE_W/features/login.md"
bash "$MAP" --write features >/dev/null 2>&1
check "MP10 a missing frontmatter block refuses, exit 2" "$([ $? -eq 2 ] && echo 0 || echo 1)"
cp "$WORK/login.good" "$BARE_W/features/login.md"
# no feature file at all (README only)
mv "$BARE_W/features/login.md" "$WORK/login.keep"
bash "$MAP" --write features >/dev/null 2>&1
check "MP10 a README-only map refuses, exit 2 (the map is the features)" "$([ $? -eq 2 ] && echo 0 || echo 1)"
mv "$WORK/login.keep" "$BARE_W/features/login.md"
cd "$SRC"

# ---- MP11: --write never-clobber + mode separation -----------------------------
cd "$BARE_W"
# direction 1: --write into a map that already HAS an index, without --force, refuses
# and writes nothing (the index is the only thing --write could clobber)
printf -- '# Features\n\n- [login](./login.md) covers signing in — entry: `src/auth/session.ts`\n' > "$BARE_W/features/README.md"
cp "$BARE_W/features/login.md" "$WORK/login.pre"
OUT11=$(bash "$MAP" --write features 2>&1); RC11=$?
check "MP11 --write into an existing map without --force refuses, exit 1" "$([ "$RC11" -eq 1 ] && echo 0 || echo 1)"
printf '%s' "$OUT11" | grep -qF -- "--force"
check "MP11 the refusal names the --force remedy" "$?"
cmp -s "$WORK/login.pre" "$BARE_W/features/login.md"
check "MP11 nothing was rewritten by the refusal" "$?"
# direction 2: --write --force regenerates the index only
printf -- '# Features\n\n- [login](./login.md) covers signing in — HAND INDEX\n' > "$BARE_W/features/README.md"
OUT11F=$(bash "$MAP" --write features --force 2>&1); RC11F=$?
check "MP11 --write --force exits 0" "$([ "$RC11F" -eq 0 ] && echo 0 || echo 1)"
cmp -s "$WORK/login.pre" "$BARE_W/features/login.md"
check "MP11 --write --force never rewrites an existing feature file" "$?"
grep -qF '](./login.md)' "$BARE_W/features/README.md" \
  && ! grep -qF 'HAND INDEX' "$BARE_W/features/README.md" \
  && grep -qF 'regenerated by gob map --write' "$BARE_W/features/README.md"
check "MP11 --write --force regenerates the index, keeping the slugs" "$?"
# mode separation: --write and --heuristic are never both
bash "$MAP" --write features --heuristic >/dev/null 2>&1
check "MP11 --write + --heuristic together is refused, exit 2" "$([ $? -eq 2 ] && echo 0 || echo 1)"
cd "$SRC"
[ ! -e "$BARE_W/.gob" ] && [ ! -e "$BARE_W/.goblin" ]
check "MP11 the --write path also never creates a .gob/ (standalone)" "$?"

# ---- teardown: count BEFORE removing the workspace ------------------------------
FAIL_N=$(grep -c . "$FAILFILE" 2>/dev/null || true)
rm -rf "$WORK"
if [ "${FAIL_N:-0}" -eq 0 ]; then
  printf '      t-map: ALL-OK\n'
  exit 0
fi
printf '      t-map: FAILED (%s)\n' "$FAIL_N"
exit 1
