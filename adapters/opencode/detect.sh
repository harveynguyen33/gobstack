#!/usr/bin/env bash
# adapters/opencode/detect.sh — the detection contract (W4A-SPEC §3).
# Prints the detected anchor on stdout; exits 0 present / 1 absent.
# Side-effect-free, offline, read-only. DETECTED iff ~/.config/opencode/ exists or the
# opencode CLI is on PATH (MEASURED live: the CLI at ~/.local/bin/opencode, 1.18.13).
set -u
[ -d "${HOME:-}/.config/opencode" ] && { printf '%s\n' "${HOME}/.config/opencode"; exit 0; }
if command -v opencode >/dev/null 2>&1; then printf '%s\n' "$(command -v opencode)"; exit 0; fi
exit 1
