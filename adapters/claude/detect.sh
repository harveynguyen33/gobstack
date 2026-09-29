#!/usr/bin/env bash
# adapters/claude/detect.sh — the detection contract (W4A-SPEC §3).
# Prints the detected anchor on stdout; exits 0 present / 1 absent.
# Side-effect-free, offline, read-only. DETECTED iff ~/.claude/ exists or `claude` is on PATH.
set -u
[ -d "${HOME:-}/.claude" ] && { printf '%s\n' "${HOME}/.claude"; exit 0; }
if command -v claude >/dev/null 2>&1; then printf '%s\n' "$(command -v claude)"; exit 0; fi
exit 1
