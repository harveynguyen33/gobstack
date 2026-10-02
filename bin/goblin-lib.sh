#!/usr/bin/env bash
# goblin-lib.sh — shared helpers for goblin-stack.
#
# Sourced by bin/goblin-install, bin/goblin-verify and bin/goblin-model.
# Dependencies: bash 4+, git, awk, sed, grep, sha256sum (or shasum).
# No npm, no jq, no yq, no network.
#
# The config format is a FLAT, LINE-ORIENTED YAML SUBSET. It is parsed here, never by a
# YAML library, so the same file parses identically on any machine:
#
#   key: value                 top-level scalar
#   key:                       block or list header
#     member: value            two-space-indented block member
#     - item                   two-space-indented list item
#   gates:
#     - name: typecheck        four-space-indented second member of a list entry
#       cmd: npx tsc --noEmit

GOBLIN_LIB_VERSION="0.4.4"

# ---------------------------------------------------------------- output -----
g_pass() { printf 'PASS  %-6s %s\n' "$1" "$2"; }
g_fail() { printf 'FAIL  %-6s %s\n' "$1" "$2"; }
g_adv()  { printf 'ADV   %-6s %s\n' "$1" "$2"; }
g_skip() { printf 'SKIP  %-6s %s\n' "$1" "$2"; }
g_info() { printf '%s\n' "$*"; }
g_err()  { printf 'error: %s\n' "$*" >&2; }

# ------------------------------------------------------------------ hash -----
g_sha256_file() {
  if [ -f "$1" ]; then
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$1" | awk '{print $1}'
    else
      shasum -a 256 "$1" | awk '{print $1}'
    fi
  else
    printf 'missing\n'
  fi
}

g_sha256_text() {
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | awk '{print $1}'
  else
    printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
  fi
}

# ------------------------------------------------------------------ paths ----
# g_abspath <path> — absolute path without requiring the file to exist.
g_abspath() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    "~"|"~/"*) printf '%s\n' "$HOME/${1#\~/}" ;;
    *) printf '%s\n' "$PWD/$1" ;;
  esac
}

# g_expand_tilde <path>
g_expand_tilde() {
  case "$1" in
    "~"|"~/"*) printf '%s\n' "$HOME/${1#\~/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# ------------------------------------------------------------------ yaml -----
# g_models_field <mapping-file> <profile> <field> — read one field of one profile out of a
# model mapping file. That file is two-level (a profile header, then its fields), so it is
# read with python3 — the same way the fleet's own tool reads it. Prints nothing if absent.
g_models_field() {
  python3 -c '
import re, sys
path, profile, field = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    lines = open(path, encoding="utf-8", errors="replace").read().split("\n")
except OSError:
    sys.exit(0)
start, base = None, 0
for i, ln in enumerate(lines):
    m = re.match(r"^(\s*)([A-Za-z_][\w.-]*):\s*$", ln)
    if m and m.group(2) == profile:
        start, base = i, len(m.group(1)); break
if start is not None:
    for ln in lines[start + 1:]:
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        if len(ln) - len(ln.lstrip()) <= base:
            break
        m = re.match(r"^\s*([A-Za-z_][\w.-]*):\s*(.*)$", ln)
        if m and m.group(1) == field:
            v = m.group(2).strip()
            print(v[1:-1] if len(v) > 1 and v[0] == v[-1] and v[0] in "\"\x27" else v)
            break
' "$1" "$2" "$3"
}

# g_unquote <value> — strip one layer of surrounding double quotes.
g_unquote() {
  local v="$1"
  v=${v%\"}; v=${v#\"}
  printf '%s' "$v"
}

# g_yaml_scalar <file> <key> — value of a top-level scalar key (empty if absent).
g_yaml_scalar() {
  sed -n "s/^$2:[[:space:]]*//p" "$1" | head -n 1
}

# g_yaml_block_scalar <file> <block> <key> — value of a 2-space-indented block member.
g_yaml_block_scalar() {
  awk -v b="$2" -v k="$3" '
    $0 ~ ("^" b ":[[:space:]]*$") { inb = 1; next }
    inb && /^[^ ]/ { inb = 0 }
    inb && $0 ~ ("^  " k ":") {
      v = $0; sub("^  " k ":[[:space:]]*", "", v); print v; exit
    }
  ' "$1"
}

# g_yaml_list <file> <key> — 2-space-indented list items under a top-level list key.
g_yaml_list() {
  awk -v k="$2" '
    $0 ~ ("^" k ":[[:space:]]*$") { inb = 1; next }
    inb && /^[^ ]/ { inb = 0 }
    inb && /^  - / { v = $0; sub(/^  - /, "", v); print v }
  ' "$1"
}

# g_yaml_gates <file> — one "name<TAB>cmd" line per declared gate.
g_yaml_gates() {
  awk '
    /^gates:[[:space:]]*$/ { inb = 1; next }
    inb && /^[^ ]/ { inb = 0 }
    inb && /^  - name:/ { n = $0; sub(/^  - name:[[:space:]]*/, "", n); name = n; next }
    inb && /^    cmd:/ { c = $0; sub(/^    cmd:[[:space:]]*/, "", c);
      if (name != "") { print name "\t" c; name = "" } }
  ' "$1"
}

# g_yaml_gate_names <file> — one declared gate NAME per line, whether or not a `cmd:` follows it.
# g_yaml_gates prints a name only when a `cmd:` LINE follows it, so a gate whose `cmd:` was
# deleted, blanked or re-indented vanishes from it in silence. This reader keeps the name
# visible, which is what lets GT-01 FAIL on the disappearance instead of reporting the
# survivors (G8-3).
g_yaml_gate_names() {
  awk '
    /^gates:[[:space:]]*$/ { inb = 1; next }
    inb && /^[^ ]/ { inb = 0 }
    inb && /^  - name:/ { n = $0; sub(/^  - name:[[:space:]]*/, "", n); print n }
  ' "$1"
}

# g_yaml_gates_all <file> — one "name<TAB>cmd" line per DECLARED gate, including a gate whose
# `cmd:` is missing or blank (the value is printed empty). g_yaml_gates emits only name+cmd
# PAIRS, which is right for running a gate (GT-02) and wrong for counting declarations
# (GT-01): a gate could lose its `cmd:` and the row still printed the survivors (G8-3).
g_yaml_gates_all() {
  awk '
    function flush() { if (name != "") { print name "\t"; name = "" } }
    /^gates:[[:space:]]*$/ { inb = 1; next }
    inb && /^[^ ]/ { flush(); inb = 0 }
    inb && /^  - name:/ { flush(); n = $0; sub(/^  - name:[[:space:]]*/, "", n); name = n; next }
    inb && /^    cmd:/ { c = $0; sub(/^    cmd:[[:space:]]*/, "", c); print name "\t" c; name = "" }
    END { if (inb) flush() }
  ' "$1"
}

# g_yaml_disabled <file> — inline list of disabled parts, one per line.
g_yaml_disabled() {
  local v
  v=$(g_yaml_scalar "$1" disabled)
  case "$v" in
    ""|"[]") return 0 ;;
  esac
  v=${v#[}; v=${v%]}
  printf '%s\n' "$v" | tr ',' '\n' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$' || true
}

# g_part_disabled <config> <part>
g_part_disabled() {
  g_yaml_disabled "$1" | grep -qx "$2"
}

# ------------------------------------------------------------- class data ----
# g_class_need <classes.tsv> <class> <part> -> R | O | -
g_class_need() {
  awk -F'\t' -v c="$2" -v p="$3" '
    NR > 1 && $1 == c && $2 == p { print $3; found = 1; exit }
    END { if (!found) print "-" }
  ' "$1"
}

# ---------------------------------------------------------------- json -------
# installed.json is emitted by goblin-install in a fixed, line-oriented shape so it can
# be read without a JSON library. g_json_object <installed.json> <object-name> -> "key<TAB>value".
g_json_object() {
  awk -v name="$2" '
    index($0, "\"" name "\"") && /:[[:space:]]*\{/ { inf = 1; next }
    inf && /^[[:space:]]*\}/ { inf = 0 }
    inf && /"/ {
      line = $0
      sub(/^[[:space:]]*"/, "", line)
      p = line; sub(/".*/, "", p)
      h = line; sub(/^[^"]*"[[:space:]]*:[[:space:]]*"/, "", h); sub(/".*/, "", h)
      if (p != "") print p "\t" h
    }
  ' "$1"
}

g_installed_files() { g_json_object "$1" files; }

g_installed_scalar() {
  sed -n "s/^[[:space:]]*\"$2\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",]*\)\"\{0,1\},\{0,1\}$/\1/p" "$1" | head -n 1
}

# g_installed_scalar_options <file> <key> — the value of one key inside the "options" object
# of an install record (e.g. skills). The installer writes options on ONE line
# (`"options": {"skills": "yes", ...}`), so the awk reads that line's shape directly; a
# multi-line variant is read the same way the other installed_* readers read their block.
g_installed_scalar_options() {
  awk -v k="$2" '
    /^[[:space:]]*"options"[[:space:]]*:[[:space:]]*\{/ && index($0, "\"" k "\"") {
      # single-line form: pull the value out between the key and the next , or }
      line = $0
      sub(/^[^{]*\{/, "", line)          # everything up to and including the opening brace
      n = split(line, pair, ",")
      for (i = 1; i <= n; i++) {
        p = pair[i]
        sub(/^[[:space:]]*/, "", p); sub(/[[:space:]]*$/, "", p)
        key = p; sub(/[[:space:]]*:.*/, "", key); gsub(/"/, "", key)
        if (key == k) {
          v = p; sub(/^[^:]*:[[:space:]]*/, "", v); gsub(/"/, "", v); sub(/\}[[:space:]]*$/, "", v)
          print v; exit
        }
      }
      exit
    }
    /^[[:space:]]*"options"[[:space:]]*:[[:space:]]*\{/ { inf = 1; next }
    inf && /^[[:space:]]*\}/ { inf = 0 }
    inf && index($0, "\"" k "\"") {
      v = $0; sub(/^[^:]*:[[:space:]]*/, "", v); sub(/,?[[:space:]]*$/, "", v); gsub(/"/, "", v)
      print v; exit
    }
  ' "$1"
}

# ------------------------------------------------------------- self-test -----
# Proves the parser actually parses. Every assertion is a real comparison against a
# value written to a temp file in this function — blank the awk in g_yaml_scalar and
# this exits non-zero (that is the RED control for the reader itself).
g_self_test() {
  local tmp rc=0
  tmp=$(mktemp -d 2>/dev/null || mktemp -d -t goblin) || { g_err "mktemp failed"; return 2; }
  cat > "$tmp/g.yaml" <<'YAML'
class: B
branch: master
archive: false
disabled: [spec, tokens]
gates:
  - name: typecheck
    cmd: npx tsc --noEmit
ratchet:
  name: hex
  ceiling: 160
runtime_data:
  - .goblin/state.json
YAML

  local got
  got=$(g_yaml_scalar "$tmp/g.yaml" class)
  [ "$got" = "B" ] || { g_err "scalar: expected B, got '$got'"; rc=1; }
  got=$(g_yaml_scalar "$tmp/g.yaml" branch)
  [ "$got" = "master" ] || { g_err "scalar: expected master, got '$got'"; rc=1; }
  got=$(g_yaml_scalar "$tmp/g.yaml" nosuchkey)
  [ -z "$got" ] || { g_err "scalar: absent key should be empty, got '$got'"; rc=1; }
  got=$(g_yaml_block_scalar "$tmp/g.yaml" ratchet ceiling)
  [ "$got" = "160" ] || { g_err "block scalar: expected 160, got '$got'"; rc=1; }
  got=$(g_yaml_block_scalar "$tmp/g.yaml" ratchet name)
  [ "$got" = "hex" ] || { g_err "block scalar: expected hex, got '$got'"; rc=1; }
  got=$(g_yaml_gates "$tmp/g.yaml" | tr '\t' ':')
  [ "$got" = "typecheck:npx tsc --noEmit" ] || { g_err "gates: got '$got'"; rc=1; }
  # The gates-all readers exist for the one case the pair reader hides: a gate whose `cmd:` LINE
  # is missing (deleted or re-indented). g_yaml_gates drops it; g_yaml_gates_all keeps it with an
  # empty cmd and g_yaml_gate_names still names it. Blank either awk and this exits non-zero -
  # that is this self-test's own RED control for the G8-3 fix (the disappearance GT-01 must FAIL).
  printf 'gates:\n  - name: typecheck\n    cmd: npx tsc --noEmit\n  - name: reindented\n  cmd: false\n' > "$tmp/g2.yaml"
  got=$(g_yaml_gates "$tmp/g2.yaml" | wc -l | tr -d '[:space:]')
  [ "$got" = "1" ] || { g_err "gates: a cmd-less gate should vanish from the pair reader, got $got line(s)"; rc=1; }
  got=$(g_yaml_gates_all "$tmp/g2.yaml" | wc -l | tr -d '[:space:]')
  [ "$got" = "2" ] || { g_err "gates-all: expected 2 declared gates, got $got"; rc=1; }
  got=$(g_yaml_gates_all "$tmp/g2.yaml" | awk -F'\t' '$1 == "reindented" && $2 == ""' | wc -l | tr -d '[:space:]')
  [ "$got" = "1" ] || { g_err "gates-all: the cmd-less gate was not reported with an empty cmd"; rc=1; }
  got=$(g_yaml_gate_names "$tmp/g2.yaml" | tr '\n' ',')
  [ "$got" = "typecheck,reindented," ] || { g_err "gate-names: got '$got'"; rc=1; }
  got=$(g_yaml_list "$tmp/g.yaml" runtime_data | tr '\n' ',')
  [ "$got" = ".goblin/state.json," ] || { g_err "list: got '$got'"; rc=1; }
  got=$(g_yaml_disabled "$tmp/g.yaml" | tr '\n' ',')
  [ "$got" = "spec,tokens," ] || { g_err "disabled: got '$got'"; rc=1; }

  rm -rf "$tmp"
  if [ "$rc" -eq 0 ]; then
    printf 'OK\n'
  else
    printf 'SELF-TEST FAILED\n' >&2
  fi
  return "$rc"
}

# Allow `bash bin/goblin-lib.sh --self-test` and `source bin/goblin-lib.sh`.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  case "${1:-}" in
    --self-test) g_self_test ;;
    --version)   printf '%s\n' "$GOBLIN_LIB_VERSION" ;;
    *)           printf 'usage: goblin-lib.sh --self-test\n' >&2; exit 2 ;;
  esac
  exit $?
fi
