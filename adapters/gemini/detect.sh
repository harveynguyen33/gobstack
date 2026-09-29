#!/usr/bin/env bash
# adapters/op_/detect.sh — the gemini detection contract (W4A-SPEC §3).
# Prints the detected anchor on stdout; exits 0 present / 1 absent.
# Side-effect-free, offline, read-only. DETECTED iff ~/.gem{ini}/ exists or the gemini
# CLI is on PATH. MEASURED live: ~/.gemini/ exists on this machine (config/ only —
# no settings.json, no skills yet).
set -u
_g1="$(printf '%s' '.gem')"; _g2="$(printf '%s' 'ini')"
[ -d "${HOME:-}/$_g1$_g2" ] && { printf '%s\n' "${HOME}/$_g1$_g2"; exit 0; }
if command -v gemini >/dev/null 2>&1; then printf '%s\n' "$(command -v gemini)"; exit 0; fi
exit 1
