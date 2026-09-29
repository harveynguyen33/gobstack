#!/usr/bin/env bash
# adapters/codex/detect.sh — the detection contract (W4A-SPEC §3).
# Prints the detected anchor on stdout; exits 0 present / 1 absent.
# Side-effect-free, offline, read-only. DETECTED iff ~/.codex/ exists or the codex CLI
# is on PATH.
set -u
[ -d "${HOME:-}/.codex" ] && { printf '%s\n' "${HOME}/.codex"; exit 0; }
if command -v codex >/dev/null 2>&1; then printf '%s\n' "$(command -v codex)"; exit 0; fi
exit 1
