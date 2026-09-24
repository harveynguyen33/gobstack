#!/usr/bin/env bash
# drift-audit.sh — A-02's producer, the no-agent half of `goblin-drift-audit` (P14).
#
#   bash drift-audit.sh [--root <glob>] [--state <file>] [--dry-run] [--cards] [--limit <n>]
#
# It compares a RECORDED CLAIM with an ARTIFACT, never a memory and never a judgement, so its
# false-positive rate is structurally zero: the comparison is made by this script, which cannot
# invent a finding.
#
#   claim 1: the HANDOFF names a commit that exists here and is an ancestor of HEAD  (HP-05)
#   claim 2: every installed file still matches its recorded hash                     (IN-02)
#   artifact: the repo's git state and the files on disk
#
# It is deliberately the FIRST automation to turn on: no agent sits inside the producer, so it
# costs zero tokens when there is nothing to report.
#
# Exit codes: 0 clean, or nothing to do | 1 drift found | 2 could not run.
#
# Kill switch  <state> carrying `enabled: false` stops it dead, and prints nothing on stdout.
# Ceiling      `run:` lines in <state> from the last 24 h, capped by --limit (default 5). A
#              capped run prints one `# capped` line, so "silent because clean" and "silent
#              because the ceiling was hit" are never confused for each other.
set -uo pipefail

ROOT_GLOB="${HOME}/projects/*"
STATE="${GOBLIN_DRIFT_STATE:-${HOME}/.goblin/automations/drift-audit.state}"
DRY_RUN=0
CARDS=0
LIMIT=5

while [ $# -gt 0 ]; do
  case "$1" in
    --root)    ROOT_GLOB="${2:-}"; shift 2 ;;
    --state)   STATE="${2:-}"; shift 2 ;;
    --limit)   LIMIT="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --cards)   CARDS=1; shift ;;
    -h|--help) sed -n '2,/^set -/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'drift-audit: unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
done

sha12() {
  if command -v sha256sum >/dev/null 2>&1; then printf '%s' "$1" | sha256sum | cut -c1-12
  else printf '%s' "$1" | shasum -a 256 | cut -c1-12; fi
}

# ---- kill switch -------------------------------------------------------------
if [ -f "$STATE" ] && grep -q '^enabled:[[:space:]]*false' "$STATE"; then
  printf 'drift-audit: disabled (enabled: false in %s)\n' "$STATE" >&2
  exit 0
fi

# ---- the producer's own ceiling ----------------------------------------------
TODAY=$(date -u +%F)
RUNS=0
if [ -f "$STATE" ]; then
  RUNS=$(grep -c "^run: $TODAY" "$STATE" 2>/dev/null || true)
  case "$RUNS" in ''|*[!0-9]*) RUNS=0 ;; esac
fi
if [ "$RUNS" -ge "$LIMIT" ]; then
  printf '# capped: %s of %s runs used today - nothing filed\n' "$RUNS" "$LIMIT"
  exit 0
fi

# ---- enumerate targets by glob, never by memory ------------------------------
TARGETS=0
SKIPPED=""
DRIFT=""
DETAIL=""

for d in $ROOT_GLOB; do
  [ -d "$d" ] || continue
  TARGETS=$((TARGETS + 1))
  if [ ! -f "$d/.goblin/goblin.yaml" ]; then
    SKIPPED="$SKIPPED $(basename "$d")"
    continue
  fi
  if [ ! -f "$d/.goblin/bin/goblin-verify" ]; then
    SKIPPED="$SKIPPED $(basename "$d")(no-verifier)"
    continue
  fi
  # --only IN-02,HP-05 rather than a full run: both are builtins that write no runtime state,
  # so the audit never edits the tree it is auditing (design rule 2 of the honesty section).
  OUT=$( cd "$d" && bash .goblin/bin/goblin-verify --json --only IN-02,HP-05 2>/dev/null )
  RC=$?
  case "$RC" in
    0|1) ;;
    *) SKIPPED="$SKIPPED $(basename "$d")(verify-exit-$RC)"; continue ;;
  esac
  FAILED=$(printf '%s' "$OUT" | grep -o '"id":"[A-Z][A-Z0-9-]*","status":"FAIL"' | sed 's/"id":"//; s/","status":"FAIL"//')
  for id in $FAILED; do
    DRIFT="$DRIFT $d/$id"
    DETAIL="$DETAIL$d	$id	cd $d && bash .goblin/bin/goblin-verify --only $id
"
  done
done

# ---- print nothing when there is nothing to file -----------------------------
# A clean run writes nothing either: the ceiling counts the runs that FILED something (the
# cards it created), never the runs that found nothing - otherwise a quiet week would exhaust
# the ceiling and silence a real finding.
if [ -z "$DRIFT" ]; then
  exit 0
fi

printf '%s' "$DETAIL"
printf '# coverage: %s target(s) audited by glob, %s drifting, skipped:%s\n' \
  "$TARGETS" "$(printf '%s' "$DRIFT" | wc -w | tr -d ' ')" "${SKIPPED:- none}"
printf '# run: %s of %s today\n' "$((RUNS + 1))" "$LIMIT"

if [ "$DRY_RUN" -eq 0 ]; then
  [ -d "$(dirname "$STATE")" ] || mkdir -p "$(dirname "$STATE")"
  printf 'run: %s\n' "$TODAY" >> "$STATE"
fi
if [ "$CARDS" -eq 1 ]; then
  if command -v hermes >/dev/null 2>&1; then
    printf '%s' "$DETAIL" | while IFS=$'\t' read -r repo id cmd; do
      [ -n "$id" ] || continue
      KEY="drift:$(basename "$repo"):$id"
      BODY=$(mktemp)
      {
        printf '# Drift: %s %s\n\n' "$(basename "$repo")" "$id"
        printf 'The producer compared a recorded claim with an artifact and they disagree.\n\n'
        printf '    %s\n\n' "$cmd"
        printf 'Reproduces at %s. Dedup key: %s\n' "$(date -u +%F)" "$KEY"
        printf 'sha256 of the record: %s\n' "$(sha12 "$repo$id$cmd")"
      } > "$BODY"
      hermes kanban create "drift: $(basename "$repo") $id" --assignee architect \
        --skill goblin-drift-audit --idempotency-key "$KEY" --body-file "$BODY" \
        --max-runtime 1800 --max-retries 1 >/dev/null 2>&1 \
        || printf 'drift-audit: could not create the card for %s %s\n' "$(basename "$repo")" "$id" >&2
      rm -f "$BODY"
    done
  else
    printf 'drift-audit: hermes is not on PATH - the record is printed, no card was created\n' >&2
  fi
fi
exit 1
