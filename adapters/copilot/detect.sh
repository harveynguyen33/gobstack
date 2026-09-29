#!/usr/bin/env bash
# adapters/copilot/detect.sh — the detection contract (W4A-SPEC §3).
# Prints the detected anchor on stdout; exits 0 present / 1 absent.
# Side-effect-free, offline, read-only. DETECTED iff ~/.copilot/ exists or `copilot` is on PATH.
set -u
[ -d "${HOME:-}/.copilot" ] && { printf '%s\n' "${HOME}/.copilot"; exit 0; }
if command -v copilot >/dev/null 2>&1; then printf '%s\n' "$(command -v copilot)"; exit 0; fi
exit 1
