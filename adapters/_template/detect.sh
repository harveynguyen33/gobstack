#!/usr/bin/env bash
# adapters/_template/detect.sh — the W4b detection stub (W4A-SPEC §1).
#
# W4b copies this directory and fills in the anchors. A template that silently
# exited 0 would make an unbuilt adapter look installed, so it refuses with 2
# and names the workstream — the same posture as the W1 doctor/emit placeholders.
printf 'detect: template adapter - not implemented until W4b (copy adapters/_template and fill in the anchors)\n' >&2
exit 2
