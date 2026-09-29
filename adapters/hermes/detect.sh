#!/usr/bin/env bash
# adapters/hermes/detect.sh — the detection contract (W4A-SPEC §3).
# Prints the detected anchor on stdout; exits 0 present / 1 absent.
# Side-effect-free, offline, read-only. DETECTED iff ~/.hermes/ exists or `hermes` is on PATH.
set -u
[ -d "${HOME:-}/.hermes" ] && { printf '%s\n' "${HOME}/.hermes"; exit 0; }
if command -v hermes >/dev/null 2>&1; then printf '%s\n' "$(command -v hermes)"; exit 0; fi
exit 1
