#!/usr/bin/env bash
# adapters/cursor/detect.sh — the detection contract (W4A-SPEC §3).
# Prints the detected anchor on stdout; exits 0 present / 1 absent.
# Side-effect-free, offline, read-only. DETECTED iff ~/.cursor/ exists or the cursor
# CLI is on PATH.
set -u
[ -d "${HOME:-}/.cursor" ] && { printf '%s\n' "${HOME}/.cursor"; exit 0; }
if command -v cursor >/dev/null 2>&1; then printf '%s\n' "$(command -v cursor)"; exit 0; fi
if command -v cursor-agent >/dev/null 2>&1; then printf '%s\n' "$(command -v cursor-agent)"; exit 0; fi
exit 1
