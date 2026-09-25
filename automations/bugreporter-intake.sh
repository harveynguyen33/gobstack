#!/usr/bin/env bash
# bugreporter-intake.sh — A-01's intake validator (the gate in front of `goblin-bugreporter`, P13).
#
#   bash bugreporter-intake.sh <slug> [--reports <dir>] [--cards]
#
# A report is a FILE WITH A SCHEMA, not prose in a card body: prose invites the agent to fill
# the gaps by guessing, and a guess at intake poisons everything downstream. This script does
# the schema check with line-oriented shell, computes the content-only dedup key, and prints
# the exact card command.
#
# Exit codes: 0 the report passed intake | 1 REFUSED (the gap is named) | 2 could not run.
#
# The report is UNTRUSTED INPUT, so nothing reads it into a shell: the card is created by
# exec'ing an argv array (`run_card`), and the form printed for an operator (`card_cmd`) quotes
# every value that came out of the report. There is no `eval` on any path. A `symptom:` carrying
# a backtick, `$(...)` or a quote is text, in the card title and on the printed line alike.
#
# An under-specified report is filed, not dropped and not guessed: the refusal command carries
# NO --assignee, so the dispatcher buckets the card `skipped_unassigned` and it is structurally
# un-spawnable, while remaining visible on the board to a human.
set -uo pipefail

SLUG=""
REPORTS="reports"
CARDS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --reports) REPORTS="${2:-}"; shift 2 ;;
    --cards)   CARDS=1; shift ;;
    -h|--help) sed -n '2,/^set -/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)
      printf 'bugreporter-intake: unknown option: %s\n' "$1" >&2; exit 2 ;;
    *) SLUG="$1"; shift ;;
  esac
done

[ -n "$SLUG" ] || { printf 'bugreporter-intake: usage: bugreporter-intake.sh <slug> [--reports <dir>]\n' >&2; exit 2; }
REPORT="$REPORTS/$SLUG/report.yaml"
[ -f "$REPORT" ] || { printf 'bugreporter-intake: no report at %s\n' "$REPORT" >&2; exit 2; }

field() { sed -n "s/^$1:[[:space:]]*//p" "$REPORT" | head -n 1; }
# present <key> — the key exists AND carries something: an inline value, or at least one
# indented item under it (repro_steps is a block list, so a bare `field` read is empty for a
# perfectly good report - that false refusal was measured and is why this helper exists).
present() {
  grep -q "^$1:" "$REPORT" || return 1
  [ -n "$(field "$1")" ] && return 0
  awk -v k="$1" '
    $0 ~ ("^" k ":[[:space:]]*$") { inb = 1; next }
    inb && /^[^[:space:]]/ { inb = 0 }
    inb && /^[[:space:]]+[^[:space:]]/ { f = 1 }
    END { exit !f }
  ' "$REPORT"
}
sha12() {
  if command -v sha256sum >/dev/null 2>&1; then printf '%s' "$1" | sha256sum | cut -c1-12
  else printf '%s' "$1" | shasum -a 256 | cut -c1-12; fi
}
# normalised = lowercased, whitespace collapsed, trimmed. The dedup key is a function of THIS
# and nothing else: no date, no run id, no counter - or it dedups nothing.
normalise() { printf '%s' "$1" | tr 'A-Z' 'a-z' | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//'; }

REPO=$(field repo)
SYMPTOM=$(field symptom)
REVISION=$(field revision)
KEY=$(field dedup_key)

MISSING=""
for k in repo symptom expected observed repro_steps revision; do
  present "$k" || MISSING="$MISSING $k"
done

WANT_KEY="bug:${REPO}:$(sha12 "$(normalise "$SYMPTOM")")"

TITLE="bug: ${SYMPTOM}"

# shq <word> — the word quoted for a shell, so the printed form can be pasted without executing
# anything the report says. Single quotes make backticks and `$( )` text; an embedded single
# quote is written as the four-character `'\''` (close, escaped quote, reopen).
shq() { local s="$1"; s=${s//\'/\'\\\'\'}; printf "'%s'" "$s"; }

# card_cmd <title-suffix> <idempotency-key> <max-runtime> <max-retries> [assignee-args...]
# The card command as it is PRINTED for an operator. Every value that came out of the report is
# shell-quoted; flags and numbers are printed literally, so the line stays greppable. The printed
# form is what skills/goblin-bugreporter/SKILL.md step 1 tells the operator to run, so it must be
# paste-safe: the report is the untrusted input this gate exists to validate (G8-1).
card_cmd() {
  local title="$TITLE$1" key="$2" rt="$3" rr="$4"; shift 4
  local a
  printf 'hermes kanban create %s' "$(shq "$title")"
  for a in "$@"; do printf ' %s' "$a"; done
  printf ' --idempotency-key %s --body-file %s --max-runtime %s --max-retries %s\n' \
    "$(shq "$key")" "$(shq "$REPORT")" "$rt" "$rr"
}

# run_card <title-suffix> <idempotency-key> <max-runtime> <max-retries> [assignee-args...]
# The same card as an ARGV ARRAY: no `eval`, no command string, so the title reaches the board as
# ONE argument whatever it contains. Never build a shell command out of file content (G8-1).
run_card() {
  local title="$TITLE$1" key="$2" rt="$3" rr="$4"; shift 4
  hermes kanban create "$title" "$@" --idempotency-key "$key" --body-file "$REPORT" \
    --max-runtime "$rt" --max-retries "$rr"
}

if [ -n "$MISSING" ]; then
  printf 'bugreporter-intake: REFUSED - %s carries no value for:%s\n' "$REPORT" "$MISSING"
  printf '# the card is created WITHOUT --assignee, so no agent can be spawned on it\n'
  card_cmd " (incomplete intake)" "${KEY:-incomplete:$SLUG}" 600 0
  exit 1
fi

if [ -n "$KEY" ] && [ "$KEY" != "$WANT_KEY" ]; then
  printf 'bugreporter-intake: REFUSED - the recorded dedup_key is not the content key\n'
  printf '  recorded   %s\n  recomputed %s\n' "$KEY" "$WANT_KEY"
  printf '  a key derived from a date, a run id or a counter dedups nothing\n'
  card_cmd " (bad key)" "$WANT_KEY" 600 0
  exit 1
fi

# The false-positive guard: a reproduction must name a revision that exists. A report with an
# unverifiable `revision:` is a refusal, not a card.
if [ -d "$REPO" ]; then
  if ! ( cd "$REPO" && git rev-parse --verify --quiet "$REVISION^{commit}" >/dev/null 2>&1 ); then
    printf 'bugreporter-intake: REFUSED - revision "%s" does not resolve in %s\n' "$REVISION" "$REPO"
    card_cmd " (unresolvable revision)" "$WANT_KEY" 600 0
    exit 1
  fi
else
  printf '# note: %s is not a local directory - the revision gate is unexercised here\n' "$REPO" >&2
fi

if [ "$CARDS" -eq 0 ]; then
  card_cmd "" "$WANT_KEY" 1800 1 --assignee researcher --skill goblin-bugreporter
  exit 0
fi
if ! command -v hermes >/dev/null 2>&1; then
  printf 'bugreporter-intake: hermes is not on PATH - the command is printed, no card was created\n' >&2
  card_cmd "" "$WANT_KEY" 1800 1 --assignee researcher --skill goblin-bugreporter
  exit 0
fi
run_card "" "$WANT_KEY" 1800 1 --assignee researcher --skill goblin-bugreporter >/dev/null 2>&1 \
  || { printf 'bugreporter-intake: the card was NOT created\n' >&2; exit 1; }
printf 'bugreporter-intake: card created with key %s\n' "$WANT_KEY"
exit 0
