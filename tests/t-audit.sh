#!/usr/bin/env bash
# t-audit.sh — the SC-07 producer, end to end and OFFLINE.
#
# SC-07 reads a RECORD and never the network (docs/RISKS.md K4), and `.goblin/bin/goblin-audit` is
# the one tool in the toolchain that is allowed to touch the network — when a human runs it and
# means to. This test replaces the declared command with a canned npm-audit JSON, so the whole
# path is exercised with nothing but `cat`, and proves four things the row alone cannot:
#
#   * the parse pairs a package with its advisory id and url (the via block is buffered, not
#     guessed at from field order);
#   * an unwaived high advisory is RED, a dated waiver makes it GREEN, and BOTH an old record and
#     an old waiver go RED on their own age;
#   * unparseable output is REFUSED with exit 5 and NO record written — an empty record would
#     read to SC-07 as "clean", which is the fabricated pass this design exists to prevent;
#   * a class that declares no audit command exits 3 with a reason instead of writing anything.
#   * the exit-5 contract is on --help itself (UX minor polish: the review measured a --help
#     that stopped at 4, so the refusal code was undocumented on the surface a user meets).
#
# Run by tests/run-tests.sh.
set -uo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
fail=0
note() { printf '      %s\n' "$*"; }
check() { if [ "$2" -eq 0 ]; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

printf 'profiles:\n  coder:\n    model: m\n    provider: p\n    effort: low\n' > "$WORK/models.yaml"
TODAY=$(date -u +%F)

# A canned npm-audit v2 report: one high (with a via advisory carrying its id and url) and one
# low (which SC-07 must ignore). Field order matches npm's own serialisation.
cat > "$WORK/audit.json" <<'JSON'
{
  "auditReportVersion": 2,
  "vulnerabilities": {
    "lodash": {
      "name": "lodash",
      "severity": "high",
      "isDirect": false,
      "via": [
        {
          "source": 1091,
          "name": "lodash",
          "dependency": "lodash",
          "title": "Prototype Pollution in lodash",
          "url": "https://github.com/advisories/GHSA-jf85-cpcp-j695",
          "severity": "high",
          "range": "<4.17.12"
        }
      ],
      "range": "<4.17.12"
    },
    "tiny": {
      "name": "tiny",
      "severity": "low"
    }
  }
}
JSON
printf '#!/usr/bin/env bash\ncat %s\n' "$WORK/audit.json" > "$WORK/fake-audit.sh"

mkfixture() { # <dir> <class>
  mkdir -p "$1"
  cd "$1" || exit 2
  git init -q -b main
  git config user.name "Test Runner"
  git config user.email "runner@example.com"
  printf '# target\n' > README.md
  git add -A && git commit -q -m "chore: seed"
  bash "$SRC/bin/goblin-install" --target "$1" --class "$2" --models "$WORK/models.yaml" >/dev/null 2>&1
  git add -A && git commit -q -m "chore: install gobstack"
  sed -i "s/^- HEAD when this file was written: .*/- HEAD when this file was written: \`$(git rev-parse --short HEAD)\`/" HANDOFF.md
  git add -A && git commit -q -m "docs: HANDOFF names the HEAD it describes"
}

# ---- class A, with the declared command pointed at the canned report --------------------------
mkfixture "$WORK/a" A
sed -i "s|^  audit_cmd: .*|  audit_cmd: bash $WORK/fake-audit.sh|" .goblin/goblin.yaml
check "the fixture declares the canned audit command" \
  "$(grep -q "^  audit_cmd: bash $WORK/fake-audit.sh" .goblin/goblin.yaml && echo 0 || echo 1)"

OUT=$(bash .goblin/bin/goblin-audit --print 2>&1); RC=$?
check "goblin-audit exits 0 on a parseable report" "$RC"
printf '%s' "$OUT" | grep -q "^measured $TODAY"
check "  and the record carries today's measured date" "$?"
printf '%s' "$OUT" | grep -q "lodash	high	1091	https://github.com/advisories/GHSA-jf85-cpcp-j695"
check "  and pairs the package with the advisory id + url from the via block" "$?"
printf '%s' "$OUT" | grep -q '^tiny'
check "  and drops the low advisory" "$([ "$?" -eq 1 ] && echo 0 || echo 1)"

OUT=$(bash .goblin/bin/goblin-verify --only SC-07 2>&1); RC=$?
printf '%s' "$OUT" | grep -q 'unwaived high advisory: lodash'
check "an unwaived high advisory is RED" "$([ "$RC" -eq 1 ] && echo 0 || echo 1)"

printf 'lodash\thigh\t*\t%s\tno fixed release; the vulnerable path is the dev server only\n' "$TODAY" \
  > .goblin/audit-waiver.tsv
OUT=$(bash .goblin/bin/goblin-verify --only SC-07 2>&1); RC=$?
printf '%s' "$OUT" | grep -q '1 high|critical line(s), 1 matched waiver(s), 0 unwaived'
check "a dated waiver makes it GREEN, and the debt is printed" "$([ "$RC" -eq 0 ] && echo 0 || echo 1)"

sed -i "s/^measured .*/measured 2020-01-01/" .goblin/audit.tsv
OUT=$(bash .goblin/bin/goblin-verify --only SC-07 2>&1); RC=$?
printf '%s' "$OUT" | grep -q 'the audit record is .* days old'
check "an old RECORD is RED on its own age" "$([ "$RC" -eq 1 ] && echo 0 || echo 1)"

sed -i "s/^measured .*/measured $TODAY/" .goblin/audit.tsv
printf 'lodash\thigh\t*\t2020-01-01\tstale decision\n' > .goblin/audit-waiver.tsv
OUT=$(bash .goblin/bin/goblin-verify --only SC-07 2>&1); RC=$?
printf '%s' "$OUT" | grep -q 'the waiver for lodash is .* days old'
check "an old WAIVER is RED on its own age" "$([ "$RC" -eq 1 ] && echo 0 || echo 1)"

# ---- the refusal: an unparseable report must not become an empty, passing record --------------
printf '#!/usr/bin/env bash\necho "not an audit report at all"\n' > "$WORK/broken-audit.sh"
rm -f .goblin/audit.tsv
sed -i "s|^  audit_cmd: .*|  audit_cmd: bash $WORK/broken-audit.sh|" .goblin/goblin.yaml
OUT=$(bash .goblin/bin/goblin-audit 2>&1); RC=$?
check "unparseable output exits 5" "$([ "$RC" -eq 5 ] && echo 0 || echo 1)"
check "  and REFUSES to write a record" "$([ ! -f .goblin/audit.tsv ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -q 'REFUSING to write a record'
check "  and says why, on the way out" "$?"
bash .goblin/bin/goblin-audit --help 2>&1 | grep -q '^  5  '
check "  and exit 5 is on --help (the refusal code is documented where the user meets it)" "$?"

sed -i "s|^  audit_cmd: .*|  audit_cmd: bash $WORK/fake-audit.sh|" .goblin/goblin.yaml
OUT=$(bash .goblin/bin/goblin-audit 2>&1); RC=$?
check "a clean rerun writes the record again" "$([ "$RC" -eq 0 ] && [ -f .goblin/audit.tsv ] && echo 0 || echo 1)"

# ---- class D declares no audit command --------------------------------------------------------
mkfixture "$WORK/d" D
OUT=$(bash .goblin/bin/goblin-audit 2>&1); RC=$?
check "a class with no audit command exits 3" "$([ "$RC" -eq 3 ] && echo 0 || echo 1)"
check "  and writes no record" "$([ ! -f .goblin/audit.tsv ] && echo 0 || echo 1)"
OUT=$(bash .goblin/bin/goblin-verify --only SC-07 2>&1); RC=$?
check "  and SC-07 SKIPs with that reason rather than failing" "$([ "$RC" -eq 0 ] && echo 0 || echo 1)"
printf '%s' "$OUT" | grep -q 'SKIP  SC-07'
check "    (the row reports the skip)" "$?"

if [ "$fail" -eq 0 ]; then note "t-audit: PASS"; else note "t-audit: FAIL"; fi
exit "$fail"
